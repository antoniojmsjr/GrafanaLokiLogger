{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.HTTP.Lazarus.Buildinfo.pas                       }
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
unit GrafanaLokiLogger.HTTP.Lazarus.Buildinfo;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Classes, Generics.Collections, FPHTTPClient, openssl, opensslsockets,
  GrafanaLokiLogger.Classes, GrafanaLokiLogger.Interfaces;

type

  { THTTPRequestBuildinfo }

  THTTPRequestBuildinfo = class(THTTPRequestCustom)
  private
    { private declarations }
    FFPHTTPClient: TFPHTTPClient;
    FBuildinfo: IGrafanaLokiLoggerBuildinfo;
    procedure SetHeaders;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create;  override;
    destructor Destroy; override;
    procedure Execute; override;
    property Buildinfo: IGrafanaLokiLoggerBuildinfo read FBuildinfo;
  end;

  { THTTPResponseBuildinfo }

  THTTPResponseBuildinfo = class(THTTPResponseBuildinfoCustom)
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
  SysUtils, ssockets, GrafanaLokiLogger.Types, GrafanaLokiLogger.Core.Buildinfo;

{$I GrafanaLokiLogger.inc}

{$REGION 'THTTPRequestBuildinfo'}
constructor THTTPRequestBuildinfo.Create;
begin
  inherited Create;

  FFPHTTPClient := TFPHTTPClient.Create(nil);
  FFPHTTPClient.AllowRedirect := False;
  FFPHTTPClient.RequestHeaders.Clear;
  FFPHTTPClient.ResponseHeaders.Clear;
end;

destructor THTTPRequestBuildinfo.Destroy;
begin
  FFPHTTPClient.Free;
  inherited Destroy;
end;

procedure THTTPRequestBuildinfo.Execute;
var
  lHTTPResponse: THTTPResponseBuildinfo;
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
  FFPHTTPClient.AddHeader('User-Agent', Format('GrafanaLokiLogger v%s', [GrafanaLokiLoggerVersion]));
  SetHeaders;

  // REQUEST
  try
    lContent := FFPHTTPClient.Get(Self.URL);
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
  lHTTPResponse := THTTPResponseBuildinfo.Create(FFPHTTPClient, lContent, Self.URL);
  try
    lHTTPResponse.Process;
    FBuildinfo := lHTTPResponse.Buildinfo;
  finally
    lHTTPResponse.Free;
  end;
end;

procedure THTTPRequestBuildinfo.SetHeaders;
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

{$REGION 'THTTPResponseBuildinfo'}
constructor THTTPResponseBuildinfo.Create(const pFPHTTPClient: TFPHTTPClient; const pContent: string; const pURL: string);
begin
  FFPHTTPClient := pFPHTTPClient;
  FContent := pContent;
  FURL := pURL;
end;

procedure THTTPResponseBuildinfo.Process;
begin
  if not Assigned(FFPHTTPClient) then
    Exit;

  FStatusCode := FFPHTTPClient.ResponseStatusCode;
  FStatusText := FFPHTTPClient.ResponseStatusText;

  case FStatusCode of
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
