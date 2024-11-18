{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Interfaces.pas                                   }
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
unit GrafanaLokiLogger.Interfaces;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
  SysUtils, Generics.Collections, fpjson,
  {$ELSE}
  System.SysUtils, System.Generics.Collections, System.JSON,
  {$ENDIF}
  GrafanaLokiLogger.Types;

type
  IGrafanaLokiLoggerSettings = interface;
  IGrafanaLokiLoggerLabels = interface;
  IGrafanaLokiLoggerLogs = interface;

  IGrafanaLokiLogger = interface
    function GetSettings: IGrafanaLokiLoggerSettings;
    function GetLabels: IGrafanaLokiLoggerLabels;
    function GetLogs: IGrafanaLokiLoggerLogs;
    function GetVersion: string;
    procedure Push;

    property Settings: IGrafanaLokiLoggerSettings read GetSettings;
    property Labels: IGrafanaLokiLoggerLabels read GetLabels;
    property Logs: IGrafanaLokiLoggerLogs read GetLogs;
    property Version: string read GetVersion;
  end;

  IGrafanaLokiLoggerSettingsProxy = interface
    ['{6EFB1FEA-D8DA-4905-9DE0-45395D20A97F}']
    function Clear: IGrafanaLokiLoggerSettingsProxy;
    function Server(const Value: string): IGrafanaLokiLoggerSettingsProxy; overload;
    function Server: string; overload;
    function Port(const Value: Integer): IGrafanaLokiLoggerSettingsProxy; overload;
    function Port: Integer; overload;
    function User(const Value: string): IGrafanaLokiLoggerSettingsProxy; overload;
    function User: string; overload;
    function Password(const Value: string): IGrafanaLokiLoggerSettingsProxy; overload;
    function Password: string; overload;
    function &End: IGrafanaLokiLoggerSettings;
  end;

  IGrafanaLokiLoggerSettingsAuth = interface
    ['{C118CF22-5690-4639-AB80-1D3D4A151B2C}']
    function Clear: IGrafanaLokiLoggerSettingsAuth;
    function Basic(const User: string; const Password: string): IGrafanaLokiLoggerSettings; overload;
    function Basic: string; overload;
    function Bearer(const Token: string): IGrafanaLokiLoggerSettings; overload;
    function Bearer: string; overload;
  end;

  IGrafanaLokiLoggerSettings = interface
    ['{350BB1F6-A674-490C-9341-B2B14B327B29}']
    function Reset: IGrafanaLokiLoggerSettings;
    function URL(const Value: string): IGrafanaLokiLoggerSettings; overload;
    function URL: string; overload;
    function Timeout(const Milliseconds: Integer): IGrafanaLokiLoggerSettings; overload;
    function Timeout: Integer; overload;
    function Proxy: IGrafanaLokiLoggerSettingsProxy;
    function Keepalive(const Value: Boolean): IGrafanaLokiLoggerSettings; overload;
    function Keepalive: Boolean; overload;
    function Compression(const Value: Boolean): IGrafanaLokiLoggerSettings; overload;
    function Compression: Boolean; overload;
    function Authentication: IGrafanaLokiLoggerSettingsAuth;
    function MultitenantID(const Value: string): IGrafanaLokiLoggerSettings; overload;
    function MultitenantID: string; overload;
    procedure Validate;
    function &End: IGrafanaLokiLogger;
  end;

  IGrafanaLokiLoggerLabels = interface
    ['{788A8CB3-8F0A-42D4-A3A1-B995921B9730}']
    function Clear: IGrafanaLokiLoggerLabels;
    function &Label(const Name: string; const Value: string): IGrafanaLokiLoggerLabels;
    function Parse: string;
    procedure Validate;
    function &End: IGrafanaLokiLogger;
  end;

  IGrafanaLokiLoggerLog = interface
    ['{CCDB921C-BD25-4D3C-9F0B-61D863411D1C}']
    function Log(const Text: string): IGrafanaLokiLoggerLog; overload;
    function Log(const JSONObject: TJSONObject; const OwnsObject: Boolean = True): IGrafanaLokiLoggerLog; overload;
    function Log(const Field: string; const Value: string): IGrafanaLokiLoggerLog; overload;
    function IsEmpty: Boolean;
    function Parse: string;
    function &End: IGrafanaLokiLoggerLogs;
  end;

  IGrafanaLokiLoggerLogs = interface
    ['{19FBDB56-79FB-4CAB-98D2-C86F75145B3A}']
    function Clear: IGrafanaLokiLoggerLogs;
    function Lines(const Level: TGrafanaLokiLoggerLevel): IGrafanaLokiLoggerLog; overload;
    function Lines: TArray<TPair<TGrafanaLokiLoggerLevel, IGrafanaLokiLoggerLog>>; overload;
    procedure Validate;
    function &End: IGrafanaLokiLogger;
  end;

implementation

end.
