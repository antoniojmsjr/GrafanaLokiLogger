{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Core.Settings.pas                                }
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
unit GrafanaLokiLogger.Core.Settings;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  GrafanaLokiLogger.Interfaces;

type
  TGrafanaLokiLoggerSettingsProxy = class(TInterfacedObject, IGrafanaLokiLoggerSettingsProxy)
  strict private
    { private declarations }
    {$IF DEFINED(FPC)}
    FGrafanaLokiLoggerSettings: IGrafanaLokiLoggerSettings;
    {$ELSE}
    [Weak] FGrafanaLokiLoggerSettings: IGrafanaLokiLoggerSettings;
    {$ENDIF}
    FServer: string;
    FPort: Integer;
    FUser: string;
    FPassword: string;
    function Clear: IGrafanaLokiLoggerSettingsProxy;
    function Server(const pValue: string): IGrafanaLokiLoggerSettingsProxy; overload;
    function Server: string; overload;
    function Port(const pValue: Integer): IGrafanaLokiLoggerSettingsProxy; overload;
    function Port: Integer; overload;
    function User(const pValue: string): IGrafanaLokiLoggerSettingsProxy; overload;
    function User: string; overload;
    function Password(const pValue: string): IGrafanaLokiLoggerSettingsProxy; overload;
    function Password: string; overload;
    function &End: IGrafanaLokiLoggerSettings;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(pParent: IGrafanaLokiLoggerSettings);
  end;

  TGrafanaLokiLoggerSettingsAuth = class(TInterfacedObject, IGrafanaLokiLoggerSettingsAuth)
  private
    { private declarations }
    {$IF DEFINED(FPC)}
    FGrafanaLokiLoggerSettings: IGrafanaLokiLoggerSettings;
    {$ELSE}
    [Weak] FGrafanaLokiLoggerSettings: IGrafanaLokiLoggerSettings;
    {$ENDIF}
    FBasicBase64: string;
    FBearer: string;
    function Clear: IGrafanaLokiLoggerSettingsAuth;
    function Basic(const pUser: string; const pPassword: string): IGrafanaLokiLoggerSettings; overload;
    function Basic: string; overload;
    function Bearer(const pToken: string): IGrafanaLokiLoggerSettings; overload;
    function Bearer: string; overload;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(pParent: IGrafanaLokiLoggerSettings);
  end;

  TGrafanaLokiLoggerSettings = class(TInterfacedObject, IGrafanaLokiLoggerSettings)
  strict private
    { private declarations }
    {$IF DEFINED(FPC)}
    FGrafanaLokiLogger: IGrafanaLokiLogger;
    {$ELSE}
    [weak] FGrafanaLokiLogger: IGrafanaLokiLogger;
    {$ENDIF}
    FProxy: IGrafanaLokiLoggerSettingsProxy;
    FAuthentication: IGrafanaLokiLoggerSettingsAuth;
    FURL: string;
    FTimeout: Integer;
    FKeepalive: Boolean;
    FCompression: Boolean;
    FMultitenantID: string;
    procedure CheckURLIsEmpty(const pURL: string);
    function Reset: IGrafanaLokiLoggerSettings;
    function URL(const pValue: string): IGrafanaLokiLoggerSettings; overload;
    function URL: string; overload;
    function Timeout(const pMilliseconds: Integer): IGrafanaLokiLoggerSettings; overload;
    function Timeout: Integer; overload;
    function Proxy: IGrafanaLokiLoggerSettingsProxy;
    function Keepalive(const pValue: Boolean): IGrafanaLokiLoggerSettings; overload;
    function Keepalive: Boolean; overload;
    function Compression(const pValue: Boolean): IGrafanaLokiLoggerSettings; overload;
    function Compression: Boolean; overload;
    function Authentication: IGrafanaLokiLoggerSettingsAuth;
    function MultitenantID(const pValue: string): IGrafanaLokiLoggerSettings; overload;
    function MultitenantID: string; overload;
    procedure Validate;
    function &End: IGrafanaLokiLogger;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(pParent: IGrafanaLokiLogger);
  end;

implementation

uses
  {$IF DEFINED(FPC)}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  GrafanaLokiLogger.Classes, GrafanaLokiLogger.Types, GrafanaLokiLogger.Utils;

{$REGION 'TGrafanaLokiLoggerSettingsProxy'}
constructor TGrafanaLokiLoggerSettingsProxy.Create(pParent: IGrafanaLokiLoggerSettings);
begin
  FGrafanaLokiLoggerSettings := pParent;
end;

function TGrafanaLokiLoggerSettingsProxy.&End: IGrafanaLokiLoggerSettings;
begin
  Result := FGrafanaLokiLoggerSettings;
end;

function TGrafanaLokiLoggerSettingsProxy.Clear: IGrafanaLokiLoggerSettingsProxy;
begin
  FServer := EmptyStr;
  FPort := 0;
  FUser := EmptyStr;
  FPassword := EmptyStr;
end;

function TGrafanaLokiLoggerSettingsProxy.Password(const pValue: string): IGrafanaLokiLoggerSettingsProxy;
begin
  Result := Self;
  FPassword := pValue;
end;

function TGrafanaLokiLoggerSettingsProxy.Password: string;
begin
  Result := FPassword;
end;

function TGrafanaLokiLoggerSettingsProxy.Port: Integer;
begin
  Result := FPort;
end;

function TGrafanaLokiLoggerSettingsProxy.Port(const pValue: Integer): IGrafanaLokiLoggerSettingsProxy;
begin
  Result := Self;
  FPort := pValue;
end;

function TGrafanaLokiLoggerSettingsProxy.Server: string;
begin
  Result := FServer;
end;

function TGrafanaLokiLoggerSettingsProxy.Server(const pValue: string): IGrafanaLokiLoggerSettingsProxy;
begin
  Result := Self;
  FServer := pValue;
end;

function TGrafanaLokiLoggerSettingsProxy.User(const pValue: string): IGrafanaLokiLoggerSettingsProxy;
begin
  Result := Self;
  FUser := pValue;
end;

function TGrafanaLokiLoggerSettingsProxy.User: string;
begin
  Result := FUser;
end;
{$ENDREGION}

{$REGION 'TGrafanaLokiLoggerSettingsAuth'}
constructor TGrafanaLokiLoggerSettingsAuth.Create(pParent: IGrafanaLokiLoggerSettings);
begin
  FGrafanaLokiLoggerSettings := pParent;
end;

function TGrafanaLokiLoggerSettingsAuth.Clear: IGrafanaLokiLoggerSettingsAuth;
begin
  Result := Self;
  FBasicBase64 := EmptyStr;
  FBearer := EmptyStr;
end;

function TGrafanaLokiLoggerSettingsAuth.Basic(const pUser: string; const pPassword: string): IGrafanaLokiLoggerSettings;
begin
  Result := FGrafanaLokiLoggerSettings;
  FBasicBase64 := AuthBasicToBase64(Trim(pUser), Trim(pPassword));
end;

function TGrafanaLokiLoggerSettingsAuth.Basic: string;
begin
  Result := FBasicBase64;
end;

function TGrafanaLokiLoggerSettingsAuth.Bearer(const pToken: string): IGrafanaLokiLoggerSettings;
begin
  Result := FGrafanaLokiLoggerSettings;
  FBearer := pToken;
end;

function TGrafanaLokiLoggerSettingsAuth.Bearer: string;
begin
  Result := FBearer;
end;
{$ENDREGION}

{$REGION 'TGrafanaLokiLoggerSettings'}
constructor TGrafanaLokiLoggerSettings.Create(pParent: IGrafanaLokiLogger);
begin
  FGrafanaLokiLogger := pParent;
  FProxy := TGrafanaLokiLoggerSettingsProxy.Create(Self);
  FAuthentication := TGrafanaLokiLoggerSettingsAuth.Create(Self);

  Reset;
end;

function TGrafanaLokiLoggerSettings.&End: IGrafanaLokiLogger;
begin
  Result := FGrafanaLokiLogger;
end;

function TGrafanaLokiLoggerSettings.Reset: IGrafanaLokiLoggerSettings;
begin
  Result := Self;

  FURL := EmptyStr;
  FTimeout := 15000; // 15s
  FKeepalive := False;
  FCompression := False;
  FMultitenantID := EmptyStr;
  FProxy.Clear;
  FAuthentication.Clear;
end;

function TGrafanaLokiLoggerSettings.Compression(const pValue: Boolean): IGrafanaLokiLoggerSettings;
begin
  Result := Self;
  FCompression := pValue;
end;

function TGrafanaLokiLoggerSettings.Authentication: IGrafanaLokiLoggerSettingsAuth;
begin
  Result := FAuthentication;
end;

procedure TGrafanaLokiLoggerSettings.CheckURLIsEmpty(const pURL: string);
begin
  if (Trim(pURL) <> EmptyStr) then
    Exit;

  raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
    .Title('Settings Loki Validation')
    .Msg('URL is empty.')
    .Hint('URL is required.');
end;

function TGrafanaLokiLoggerSettings.Compression: Boolean;
begin
  Result := FCompression;
end;

function TGrafanaLokiLoggerSettings.Keepalive(const pValue: Boolean): IGrafanaLokiLoggerSettings;
begin
  Result := Self;
  FKeepalive := pValue;
end;

function TGrafanaLokiLoggerSettings.Keepalive: Boolean;
begin
  Result := FKeepalive;
end;

function TGrafanaLokiLoggerSettings.MultitenantID(const pValue: string): IGrafanaLokiLoggerSettings;
begin
  Result := Self;
  FMultitenantID := Trim(pValue);
end;

function TGrafanaLokiLoggerSettings.MultitenantID: string;
begin
  Result := FMultitenantID;
end;

function TGrafanaLokiLoggerSettings.Proxy: IGrafanaLokiLoggerSettingsProxy;
begin
  Result := FProxy;
end;

function TGrafanaLokiLoggerSettings.Timeout: Integer;
begin
  Result := FTimeout;
end;

function TGrafanaLokiLoggerSettings.Timeout(const pMilliseconds: Integer): IGrafanaLokiLoggerSettings;
begin
  Result := Self;
  FTimeout := pMilliseconds;
end;

function TGrafanaLokiLoggerSettings.URL(const pValue: string): IGrafanaLokiLoggerSettings;
begin
  Result := Self;
  FURL := Trim(pValue);
end;

function TGrafanaLokiLoggerSettings.URL: string;
begin
  Result := FURL;
end;

procedure TGrafanaLokiLoggerSettings.Validate;
begin
  CheckURLIsEmpty(FURL);
end;
{$ENDREGION}

end.
