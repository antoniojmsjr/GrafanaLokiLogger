{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.HTTP.Delphi.pas                                  }
{                                                                              }
{           Copyright (C) Antônio José Medeiros Schneider Júnior               }
{                                                                              }
{           https://github.com/antoniojmsjr/GrafanaLokiLogger                  }
{                                                                              }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit GrafanaLokiLogger.HTTP.Delphi;

interface

uses
  System.Net.URLClient, System.Classes, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.Generics.Collections, GrafanaLokiLogger.Classes;

type
  THTTPRequest = class(THTTPRequestCustom)
  private
    { private declarations }
    FHttpRequest: TNetHTTPRequest;
    FHttpClient: TNetHTTPClient;
    function GetHeaders: TNetHeaders;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create;  override;
    destructor Destroy; override;
    procedure Execute; override;
  end;

  THTTPResponse = class(THTTPResponseCustom)
  private
    { private declarations }
    FHTTPResponse: IHTTPResponse;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(pHTTPResponse: IHTTPResponse; const pURL: string; const pBody: string);
    procedure Process; override;
  end;

implementation

uses
  System.SysUtils, GrafanaLokiLogger.Consts, GrafanaLokiLogger.Types;

{$I GrafanaLokiLogger.inc}

{$REGION 'THTTPRequest'}
constructor THTTPRequest.Create;
begin
  inherited Create;

  FHttpRequest := TNetHTTPRequest.Create(nil);
  FHttpClient := TNetHTTPClient.Create(FHttpRequest);
  FHttpRequest.Client := FHttpClient;

  FHttpClient.HandleRedirects := False;
  FHttpClient.SecureProtocols := [];
  FHttpClient.SecureProtocols := [THTTPSecureProtocol.TLS1,
                                  THTTPSecureProtocol.TLS11,
                                  THTTPSecureProtocol.TLS12];
end;

destructor THTTPRequest.Destroy;
begin
  FHttpRequest.Free;
  inherited Destroy;
end;

procedure THTTPRequest.Execute;
var
  lResponse: IHTTPResponse;
  lHeaders: TNetHeaders;
  lExceptionKind: TGrafanaLokiLoggerException;
  lHTTPResponse: THTTPResponse;
  lURL: string;
begin
  // PARAMS
  FHttpRequest.ConnectionTimeout := Timeout;
  FHttpRequest.ResponseTimeout := Timeout;

  if ((Proxy.Server <> EmptyStr) and (Proxy.Port > 0)) then
    FHttpRequest.Client.ProxySettings :=
      TProxySettings.Create(Proxy.Server,
                            Proxy.Port,
                            Proxy.User,
                            Proxy.Password,
                            EmptyStr);

  if not URL.EndsWith('/') then
    lURL := Format('%s/', [URL]);

  lURL := Format('%s%s', [lURL, C_LOKI_API_ENDPOINT_PUSH]);
  FHttpRequest.URL := lURL;
  FHttpRequest.MethodString := 'POST';
  FHttpRequest.Client.ContentType := 'application/json';
  FHttpRequest.Client.Accept := '*/*';
  FHttpRequest.Client.UserAgent := Format('GrafanaLokiLogger v%s', [GrafanaLokiLoggerVersion]);
  lHeaders := GetHeaders;

  // REQUEST
  try
    Body.Position := 0;
    FHttpRequest.SourceStream := Body;

    lResponse := FHttpRequest.Execute(lHeaders);
  except
    on E: Exception do
    begin
      lExceptionKind := TGrafanaLokiLoggerException.RequestInvalid;
      if (E is ENetHTTPClientException) then
        lExceptionKind := TGrafanaLokiLoggerException.RequestHttp;

      raise EGrafanaLokiLogger.Build(lExceptionKind)
        .Title('Request Execute fail')
        .Msg(E.Message)
        .Hint('Check the error message.')
        .Detail(GetDetail(E));
    end;
  end;

  // VALIDATION
  lHTTPResponse := THTTPResponse.Create(lResponse, lURL, Self.BodyJSON);
  try
    lHTTPResponse.Process;
  finally
    lHTTPResponse.Free;
  end;
end;

function THTTPRequest.GetHeaders: TNetHeaders;
var
  lHeader: TPair<string, string>;
begin
  Result := Result + [TNetHeader.Create('x-library-engine', 'Delphi')];

  for lHeader in Headers.Values do
    Result := Result + [TNetHeader.Create(lHeader.Key, lHeader.Value)];

  if KeepAlive then
    Result := Result + [TNetHeader.Create('Connection', 'keep-alive')]
  else
    Result := Result + [TNetHeader.Create('Connection', 'close')];
end;
{$ENDREGION}

{$REGION 'THTTPResponse'}
constructor THTTPResponse.Create(pHTTPResponse: IHTTPResponse; const pURL: string; const pBody: string);
begin
  inherited Create(pURL, pBody);
  FHTTPResponse := pHTTPResponse
end;

procedure THTTPResponse.Process;
var
  lContent: string;
begin
  if not Assigned(FHTTPResponse) then
    Exit;

  if (FHTTPResponse.StatusCode = 400) then
  begin
    lContent := FHTTPResponse.ContentAsString(TEncoding.UTF8);
    RequestInvalid(lContent);
  end;
end;
{$ENDREGION}

end.
