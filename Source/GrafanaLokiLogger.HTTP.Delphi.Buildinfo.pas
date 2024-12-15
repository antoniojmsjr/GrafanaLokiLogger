{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.HTTP.Delphi.Buildinfo.pas                        }
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
unit GrafanaLokiLogger.HTTP.Delphi.Buildinfo;

interface

uses
  System.Net.URLClient, System.Classes, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.Generics.Collections, GrafanaLokiLogger.Classes,
  GrafanaLokiLogger.Interfaces;

type
  THTTPRequestBuildinfo = class(THTTPRequestCustom)
  strict private
    { private declarations }
    FHttpRequest: TNetHTTPRequest;
    FHttpClient: TNetHTTPClient;
    FBuildinfo: IGrafanaLokiLoggerBuildinfo;
    function GetHeaders: TNetHeaders;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create;  override;
    destructor Destroy; override;
    procedure Execute; override;
    property Buildinfo: IGrafanaLokiLoggerBuildinfo read FBuildinfo;
  end;

  THTTPResponseBuildinfo = class(THTTPResponseBuildinfoCustom)
  private
    { private declarations }
    FHTTPResponse: IHTTPResponse;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(pHTTPResponse: IHTTPResponse; const pURL: string); reintroduce;
    procedure Process; override;
  end;

implementation

uses
  System.SysUtils, GrafanaLokiLogger.Consts, GrafanaLokiLogger.Types,
  GrafanaLokiLogger.Core.Buildinfo;

{$I GrafanaLokiLogger.inc}

{$REGION 'THTTPRequestBuildinfo'}
constructor THTTPRequestBuildinfo.Create;
begin
  inherited Create;

  FHttpRequest := TNetHTTPRequest.Create(nil);
  FHttpClient := TNetHTTPClient.Create(FHttpRequest);
  FHttpRequest.Client := FHttpClient;

  FHttpClient.HandleRedirects := False;
  {$IF COMPILERVERSION >= 32.0}
  FHttpClient.SecureProtocols := [];
  FHttpClient.SecureProtocols := [THTTPSecureProtocol.TLS1,
                                  THTTPSecureProtocol.TLS11,
                                  THTTPSecureProtocol.TLS12];
  {$ENDIF}
end;

destructor THTTPRequestBuildinfo.Destroy;
begin
  FHttpRequest.Free;
  inherited Destroy;
end;

procedure THTTPRequestBuildinfo.Execute;
var
  lResponse: IHTTPResponse;
  lHeaders: TNetHeaders;
  lExceptionKind: TGrafanaLokiLoggerException;
  lHTTPResponse: THTTPResponseBuildinfo;
begin
  // PARAMS
  {$IF COMPILERVERSION >= 31.0}
  FHttpRequest.ConnectionTimeout := Timeout;
  FHttpRequest.ResponseTimeout := Timeout;
  {$ENDIF}
  if ((Proxy.Server <> EmptyStr) and (Proxy.Port > 0)) then
    FHttpRequest.Client.ProxySettings :=
      TProxySettings.Create(Proxy.Server,
                            Proxy.Port,
                            Proxy.User,
                            Proxy.Password,
                            EmptyStr);

  FHttpRequest.URL := Self.URL;
  FHttpRequest.MethodString := 'GET';
  FHttpRequest.Client.Accept := '*/*';
  FHttpRequest.Client.UserAgent := Format('GrafanaLokiLogger v%s', [GrafanaLokiLoggerVersion]);
  lHeaders := GetHeaders;

  // REQUEST
  try
    lResponse := FHttpRequest.Execute(lHeaders);
  except
    on E: Exception do
    begin
      lExceptionKind := TGrafanaLokiLoggerException.RequestInvalid;
      if (E is ENetHTTPClientException) then
        lExceptionKind := TGrafanaLokiLoggerException.RequestHttp;

      raise EGrafanaLokiLogger.Build(lExceptionKind)
        .Title('Request fail')
        .Msg(E.Message)
        .Hint('Check the error message.')
        .Detail(GetDetail(E));
    end;
  end;

  // VALIDATION
  lHTTPResponse := THTTPResponseBuildinfo.Create(lResponse, Self.URL);
  try
    lHTTPResponse.Process;
    FBuildinfo := lHTTPResponse.Buildinfo;
  finally
    lHTTPResponse.Free;
  end;
end;

function THTTPRequestBuildinfo.GetHeaders: TNetHeaders;
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

{$REGION 'THTTPResponseBuildinfo'}
constructor THTTPResponseBuildinfo.Create(pHTTPResponse: IHTTPResponse; const pURL: string);
begin
  FHTTPResponse := pHTTPResponse;
  FURL := pURL;
end;

procedure THTTPResponseBuildinfo.Process;
begin
  if not Assigned(FHTTPResponse) then
    Exit;

  FStatusCode := FHTTPResponse.StatusCode;
  FStatusText := FHTTPResponse.StatusText;
  FContent := FHTTPResponse.ContentAsString(TEncoding.UTF8);

  case FHTTPResponse.StatusCode of
    200:
    begin
      if (Trim(FContent) = EmptyStr) then
        raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.RequestInvalid)
          .Title('Response processing')
          .Msg('Response is empty.')
          .Hint('Check the error message.')
          .Detail(EmptyStr);

      FBuildinfo := TGrafanaLokiLoggerBuildinfo.Create(FContent);
    end;
    404:
    begin
      raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.RequestInvalid)
        .Title('Request fail')
        .Msg('Server does not support this request.')
        .Hint('Check the error message.')
        .Detail(EmptyStr);
    end;
  else
  begin
    inherited;
  end;
  end;
end;
{$ENDREGION}

end.
