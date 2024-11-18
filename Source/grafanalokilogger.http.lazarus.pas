{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.HTTP.Lazarus.pas                                 }
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
unit GrafanaLokiLogger.HTTP.Lazarus;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Classes, Generics.Collections, FPHTTPClient, openssl, opensslsockets,
  GrafanaLokiLogger.Classes;

type
  THTTPRequest = class(THTTPRequestCustom)
  private
    { private declarations }
    FFPHTTPClient: TFPHTTPClient;
    procedure SetHeaders;
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
    FStatusCode: Integer;
    FContent: string;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(const pContent: string; const pStatusCode: Integer; const pURL: string; const pBody: string);
    procedure Process; override;
  end;

implementation

uses
  SysUtils, ssockets, GrafanaLokiLogger.Consts, GrafanaLokiLogger.Types;

{$REGION 'THTTPRequest'}
constructor THTTPRequest.Create;
begin
  inherited Create;

  FFPHTTPClient := TFPHTTPClient.Create(nil);
  FFPHTTPClient.AllowRedirect := False;
  FFPHTTPClient.RequestHeaders.Clear;
  FFPHTTPClient.ResponseHeaders.Clear;
end;

destructor THTTPRequest.Destroy;
begin
  FFPHTTPClient.Free;
  inherited Destroy;
end;

procedure THTTPRequest.Execute;
var
  lHTTPResponse: THTTPResponse;
  lExceptionKind: TGrafanaLokiLoggerException;
  lContent: string;
  lURL: string;
begin
  // PARAMS
  FFPHTTPClient.ConnectTimeout := Timeout;
  FFPHTTPClient.IOTimeout := Timeout;

  if ((Proxy.Server <> EmptyStr) and (Proxy.Port > 0)) then
  begin
    FFPHTTPClient.Proxy.Host := Proxy.Server;
    FFPHTTPClient.Proxy.Port := Proxy.Port;
    FFPHTTPClient.Proxy.Password := Proxy.Password;
    FFPHTTPClient.Proxy.UserName := Proxy.User;
  end;

  if not URL.EndsWith('/') then
    lURL := Format('%s/', [URL]);

  lURL := Format('%s%s', [lURL, C_LOKI_API_ENDPOINT_PUSH]);
  FFPHTTPClient.AddHeader('Accept', '*/*');
  FFPHTTPClient.AddHeader('Content-Type', 'application/json');
  FFPHTTPClient.AddHeader('User-Agent', 'GrafanaLokiLogger');
  SetHeaders;

  // REQUEST
  try
    Body.Position := 0;
    FFPHTTPClient.RequestBody := Body;
    lContent := FFPHTTPClient.Post(lURL);
  except
    on E: Exception do
    begin
      lExceptionKind := TGrafanaLokiLoggerException.RequestInvalid;
      if (E is ESocketError) then
        lExceptionKind := TGrafanaLokiLoggerException.RequestHttp;

      raise EGrafanaLokiLogger.Build(lExceptionKind)
        .Title('Request Execute fail')
        .Msg(E.Message)
        .Hint('Check the error message.')
        .Detail(GetDetail(E));
    end;
  end;

  // VALIDATION
  lHTTPResponse := THTTPResponse.Create(lContent, FFPHTTPClient.ResponseStatusCode, lURL, Self.BodyJSON);
  try
    lHTTPResponse.Process;
  finally
    lHTTPResponse.Free;
  end;
end;

procedure THTTPRequest.SetHeaders;
var
  lHeader: TPair<string, string>;
begin
  FFPHTTPClient.AddHeader('x-library-engine', 'Lazarus');

  for lHeader in Headers.Values do
    FFPHTTPClient.AddHeader(lHeader.Key, lHeader.Value);

  if KeepAlive then
    FFPHTTPClient.AddHeader('Connection', 'keep-alive')
  else
    FFPHTTPClient.AddHeader('Connection', 'close');
end;
{$ENDREGION}

{$REGION 'THTTPResponse'}
constructor THTTPResponse.Create(const pContent: string; const pStatusCode: Integer; const pURL: string; const pBody: string);
begin
  inherited Create(pURL, pBody);
  FStatusCode := pStatusCode;
  FContent := pContent
end;

procedure THTTPResponse.Process;
begin
  if (Trim(FContent) = EmptyStr) then
    Exit;

  if (FStatusCode = 400) then
    RequestInvalid(FContent);
end;
{$ENDREGION}

end.

