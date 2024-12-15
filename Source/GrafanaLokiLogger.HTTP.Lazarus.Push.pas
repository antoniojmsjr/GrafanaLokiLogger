{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.HTTP.Lazarus.Push.pas                            }
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
unit GrafanaLokiLogger.HTTP.Lazarus.Push;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Classes, Generics.Collections, FPHTTPClient, openssl, opensslsockets,
  GrafanaLokiLogger.Classes;

type
  THTTPRequestPush = class(THTTPRequestCustom)
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

  THTTPResponsePush = class(THTTPResponsePushCustom)
  private
    { private declarations }
    FFPHTTPClient: TFPHTTPClient;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(const pFPHTTPClient: TFPHTTPClient; const pContent: string; const pURL: string); reintroduce;
    procedure Process; override;
  end;

implementation

uses
  SysUtils, ssockets, GrafanaLokiLogger.Consts, GrafanaLokiLogger.Types;

{$I GrafanaLokiLogger.inc}

{$REGION 'THTTPRequestPush'}
constructor THTTPRequestPush.Create;
begin
  inherited Create;

  FFPHTTPClient := TFPHTTPClient.Create(nil);
  FFPHTTPClient.AllowRedirect := False;
  FFPHTTPClient.RequestHeaders.Clear;
  FFPHTTPClient.ResponseHeaders.Clear;
end;

destructor THTTPRequestPush.Destroy;
begin
  FFPHTTPClient.Free;
  inherited Destroy;
end;

procedure THTTPRequestPush.Execute;
var
  lHTTPResponse: THTTPResponsePush;
  lExceptionKind: TGrafanaLokiLoggerException;
  lContent: string;
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

  FFPHTTPClient.AddHeader('Accept', '*/*');
  FFPHTTPClient.AddHeader('Content-Type', 'application/json');
  FFPHTTPClient.AddHeader('User-Agent', Format('GrafanaLokiLogger v%s', [GrafanaLokiLoggerVersion]));
  SetHeaders;

  // REQUEST
  try
    Body.Position := 0;
    FFPHTTPClient.RequestBody := Body;
    lContent := FFPHTTPClient.Post(Self.URL);
  except
    on E: Exception do
    begin
      lExceptionKind := TGrafanaLokiLoggerException.RequestInvalid;
      if (E is ESocketError) then
        lExceptionKind := TGrafanaLokiLoggerException.RequestHttp;

      if not (E is EHTTPClient) then
        raise EGrafanaLokiLogger.Build(lExceptionKind)
          .Title('Request fail')
          .Msg(E.Message)
          .Hint('Check the error message.')
          .Detail(GetDetail(E));
    end;
  end;

  // VALIDATION
  lHTTPResponse := THTTPResponsePush.Create(FFPHTTPClient, lContent, Self.URL);
  try
    lHTTPResponse.Process;
  finally
    lHTTPResponse.Free;
  end;
end;

procedure THTTPRequestPush.SetHeaders;
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

{$REGION 'THTTPResponsePush'}
constructor THTTPResponsePush.Create(const pFPHTTPClient: TFPHTTPClient; const pContent: string; const pURL: string);
begin
  FFPHTTPClient := pFPHTTPClient;
  FContent := pContent;
  FURL := pURL;
end;

procedure THTTPResponsePush.Process;
begin
  if not Assigned(FFPHTTPClient) then
    Exit;

  FStatusCode := FFPHTTPClient.ResponseStatusCode;
  FStatusText := FFPHTTPClient.ResponseStatusText;

  inherited;
end;
{$ENDREGION}

end.
