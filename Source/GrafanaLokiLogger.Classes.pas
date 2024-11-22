{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Classes.pas                                      }
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
unit GrafanaLokiLogger.Classes;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
  Classes, SysUtils, Generics.Collections, Generics.Defaults,
  {$ELSE}
  System.Generics.Collections, System.SysUtils, System.Classes, System.Generics.Defaults,
  {$ENDIF}
  GrafanaLokiLogger.Types, GrafanaLokiLogger.Interfaces;

type
  THTTPHeaders = class
  strict private
    { private declarations }
    FHeaders: TDictionary<string, string>;
    function GetValues: TStringValues;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create;
    destructor Destroy; override;
    procedure Add(const pField: string; const pValue: string);
    property Values: TStringValues read GetValues;
  end;

  THTTPProxy = class
  strict private
    { private declarations }
    FPort: Integer;
    FPassword: string;
    FUser: string;
    FServer: string;
    procedure SetPassword(const Value: string);
    procedure SetPort(const Value: Integer);
    procedure SetServer(const Value: string);
    procedure SetUser(const Value: string);
  protected
    { protected declarations }
  public
    { public declarations }
    property Server: string read FServer write SetServer;
    property Port: Integer read FPort write SetPort;
    property User: string read FUser write SetUser;
    property Password: string read FPassword write SetPassword;
  end;

  THTTPRequestCustom = class abstract
  strict private
    { private declarations }
    FURL: string;
    FHeaders: THTTPHeaders;
    FProxy: THTTPProxy;
    FBody: TStringStream;
    FTimeout: Integer;
    FKeepalive: Boolean;
    FCompression: Boolean;
    FBodyJSON: string;
    procedure SetURL(const Value: string);
    procedure SetTimeout(const Value: Integer);
    procedure SetKeepalive(const Value: Boolean);
    procedure SetCompression(const Value: Boolean);
    procedure SetBodyJSON(const Value: string);
  protected
    { protected declarations }
    function GetDetail(const pException: Exception): string; overload; virtual;
    function GetDetail: string; overload; virtual;
  public
    { public declarations }
    constructor Create; virtual;
    destructor Destroy; override;
    property URL: string read FURL write SetURL;
    property Timeout: Integer read FTimeout write SetTimeout;
    property Keepalive: Boolean read FKeepalive write SetKeepalive;
    property Compression: Boolean read FCompression write SetCompression;
    property Proxy: THTTPProxy read FProxy;
    property Headers: THTTPHeaders read FHeaders;
    property Body: TStringStream read FBody;
    property BodyJSON: string read FBodyJSON write SetBodyJSON;
    procedure Execute; virtual; abstract;
  end;

  THTTPResponseCustom = class abstract
  private
    { private declarations }
    FURL: string;
    FBody: string;
  protected
    { protected declarations }
    function GetDetail: string; overload; virtual;
    procedure RequestInvalid(const pContent: string);
  public
    { public declarations }
    constructor Create(const pURL: string; const pBody: string); reintroduce;
    procedure Process; virtual; abstract;
  end;

  TParseStreamsCustom = class abstract
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    function Parse(pGrafanaLokiLoggerLabels: IGrafanaLokiLoggerLabels; pGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs): string; virtual; abstract;
  end;

  EGrafanaLokiLogger = class(Exception)
  private
    { private declarations }
    FTitle: string;
    FHint: string;
    FDetail: string;
    FType: TGrafanaLokiLoggerException;
    constructor Create(ExceptionKind: TGrafanaLokiLoggerException); reintroduce;
  protected
    { protected declarations }
  public
    { Public declarations }
    function &Type: TGrafanaLokiLoggerException;
    function Title: string; overload;
    function Title(const Value: string): EGrafanaLokiLogger; overload;
    function Title(const Format: string; const Values: array of const): EGrafanaLokiLogger; overload;
    function Msg: string; overload;
    function Msg(const Value: string): EGrafanaLokiLogger; overload;
    function Msg(const Format: string; const Values: array of const): EGrafanaLokiLogger; overload;
    function Hint: string; overload;
    function Hint(const Value: string): EGrafanaLokiLogger; overload;
    function Hint(const Format: string; const Values: array of const): EGrafanaLokiLogger; overload;
    function Detail: string; overload;
    function Detail(const Value: string): EGrafanaLokiLogger; overload;
    function Detail(const Format: string; const Values: array of const): EGrafanaLokiLogger; overload;
    function ToString: string; override;
    class function Build(const ExceptionKind: TGrafanaLokiLoggerException): EGrafanaLokiLogger;
  end;

implementation

{$REGION 'THTTPHeaders'}
constructor THTTPHeaders.Create;
begin
  {$IF DEFINED(FPC)}
  FHeaders := TDictionary<string, string>.Create(256);
  {$ELSE}
  FHeaders := TDictionary<string, string>.Create(256, TIStringComparer.Ordinal); // CASE INSENSITIVE
  {$ENDIF}
end;

destructor THTTPHeaders.Destroy;
begin
  FHeaders.Free;
  inherited Destroy;
end;

function THTTPHeaders.GetValues: TStringValues;
begin
  Result := FHeaders.ToArray;
end;

procedure THTTPHeaders.Add(const pField, pValue: string);
begin
  FHeaders.AddOrSetValue(pField, pValue);
end;
{$ENDREGION}

{$REGION 'THTTPProxy'}
procedure THTTPProxy.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

procedure THTTPProxy.SetPort(const Value: Integer);
begin
  FPort := Value;
end;

procedure THTTPProxy.SetServer(const Value: string);
begin
  FServer := Value;
end;

procedure THTTPProxy.SetUser(const Value: string);
begin
  FUser := Value;
end;
{$ENDREGION}

{$REGION 'THTTPRequestCustom'}
constructor THTTPRequestCustom.Create;
begin
  FHeaders := THTTPHeaders.Create;
  FProxy := THTTPProxy.Create;
  FBody := TStringStream.Create(EmptyStr, TEncoding.UTF8);
end;

destructor THTTPRequestCustom.Destroy;
begin
  FHeaders.Free;
  FProxy.Free;
  FBody.Free;
  inherited Destroy;
end;

function THTTPRequestCustom.GetDetail: string;
var
  lResult: TStringBuilder;
  lJSON: string;
begin
  Result := EmptyStr;

  lJSON := 'Empty';
  if (Trim(FBodyJSON) <> EmptyStr) then
    lJSON := FBodyJSON;

  lResult := TStringBuilder.Create;
  try
    lResult.AppendFormat('URL: %s', [FURL]).AppendLine;
    //lResult.AppendFormat('JSON: %s', [lJSON]);
    Result := lResult.ToString;
  finally
    lResult.Free;
  end;
end;

function THTTPRequestCustom.GetDetail(const pException: Exception): string;
var
  lResult: TStringBuilder;
begin
  Result := EmptyStr;

  lResult := TStringBuilder.Create;
  try
    lResult.AppendFormat('Class Exception: %s', [pException.ClassName]).AppendLine;
    lResult.Append(GetDetail);

    Result := lResult.ToString;
  finally
    lResult.Free;
  end;
end;

procedure THTTPRequestCustom.SetBodyJSON(const Value: string);
begin
  FBodyJSON := Value;
end;

procedure THTTPRequestCustom.SetCompression(const Value: Boolean);
begin
  FCompression := Value;
end;

procedure THTTPRequestCustom.SetKeepalive(const Value: Boolean);
begin
  FKeepalive := Value;
end;

procedure THTTPRequestCustom.SetTimeout(const Value: Integer);
begin
  FTimeout := Value;
end;

procedure THTTPRequestCustom.SetURL(const Value: string);
begin
  FURL := Value;
end;
{$ENDREGION}

{$REGION 'THTTPResponseCustom'}
constructor THTTPResponseCustom.Create(const pURL: string; const pBody: string);
begin
  FURL := pURL;
  FBody := pBody;
end;

function THTTPResponseCustom.GetDetail: string;
var
  lResult: TStringBuilder;
  lJSON: string;
begin
  Result := EmptyStr;

  lJSON := 'Empty';
  if (Trim(FBody) <> EmptyStr) then
    lJSON := FBody;

  lResult := TStringBuilder.Create;
  try
    lResult.AppendFormat('URL: %s', [FURL]).AppendLine;
    lResult.AppendFormat('JSON: %s', [FBody]);
    Result := lResult.ToString;
  finally
    lResult.Free;
  end;
end;

procedure THTTPResponseCustom.RequestInvalid(const pContent: string);
var
  lHint: string;
begin
  if (Trim(pContent) = EmptyStr) then
    Exit;

  if (Pos('EOF', pContent) > 0) then
  begin
    lHint := 'It is necessary to inform the "Body" in the request.';

    raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.RequestInvalid)
      .Title('Request Execute fail')
      .Msg(pContent)
      .Hint(lHint)
      .Detail(GetDetail);
  end
  else
    raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.RequestInvalid)
      .Title('Request Execute fail')
      .Msg(pContent)
      .Hint('Check the error message.')
      .Detail(GetDetail);
end;

{$ENDREGION}

{$REGION 'EGrafanaLokiLogger'}
constructor EGrafanaLokiLogger.Create(ExceptionKind: TGrafanaLokiLoggerException);
begin
  inherited Create(EmptyStr);
  FType := ExceptionKind;
end;

class function EGrafanaLokiLogger.Build(const ExceptionKind: TGrafanaLokiLoggerException): EGrafanaLokiLogger;
begin
  Result := Create(ExceptionKind);
end;

function EGrafanaLokiLogger.Detail: string;
begin
  Result := FDetail;
end;

function EGrafanaLokiLogger.Detail(const Value: string): EGrafanaLokiLogger;
begin
  Result := Self;
  FDetail := Trim(Value);
end;

function EGrafanaLokiLogger.Detail(const Format: string; const Values: array of const): EGrafanaLokiLogger;
begin
  Result := Self;
  {$IF DEFINED(FPC)}
  FDetail := SysUtils.Format(Format, Values, FormatSettings);
  {$ELSE}
  FDetail := System.SysUtils.Format(Format, Values, FormatSettings);
  {$ENDIF}
end;

function EGrafanaLokiLogger.Hint(const Format: string; const Values: array of const): EGrafanaLokiLogger;
begin
  Result := Self;
  {$IF DEFINED(FPC)}
  FHint := SysUtils.Format(Format, Values, FormatSettings);
  {$ELSE}
  FHint := System.SysUtils.Format(Format, Values, FormatSettings);
  {$ENDIF}
end;

function EGrafanaLokiLogger.&Type: TGrafanaLokiLoggerException;
begin
  Result := FType;
end;

function EGrafanaLokiLogger.Hint(const Value: string): EGrafanaLokiLogger;
begin
  Result := Self;
  FHint := Trim(Value);
end;

function EGrafanaLokiLogger.Hint: string;
begin
  Result := FHint;
end;

function EGrafanaLokiLogger.Msg: string;
begin
  Result := Self.Message;
end;

function EGrafanaLokiLogger.Msg(const Format: string; const Values: array of const): EGrafanaLokiLogger;
begin
  Result := Self;
  {$IF DEFINED(FPC)}
  Self.Message := SysUtils.Format(Format, Values, FormatSettings);
  {$ELSE}
  Self.Message := System.SysUtils.Format(Format, Values, FormatSettings);
  {$ENDIF}
end;

function EGrafanaLokiLogger.Msg(const Value: string): EGrafanaLokiLogger;
begin
  Result := Self;
  Self.Message := Trim(Value);
end;

function EGrafanaLokiLogger.Title: string;
begin
  Result := FTitle;
end;

function EGrafanaLokiLogger.Title(const Format: string; const Values: array of const): EGrafanaLokiLogger;
begin
  Result := Self;
  {$IF DEFINED(FPC)}
  FTitle := SysUtils.Format(Format, Values, FormatSettings);
  {$ELSE}
  FTitle := System.SysUtils.Format(Format, Values, FormatSettings);
  {$ENDIF}
end;

function EGrafanaLokiLogger.Title(const Value: string): EGrafanaLokiLogger;
begin
  Result := Self;
  FTitle := Trim(Value);
end;

function EGrafanaLokiLogger.ToString: string;
var
  lResult: TStringBuilder;
begin
  Result := EmptyStr;

  lResult := TStringBuilder.Create;
  try
    lResult.AppendFormat('Title: %s', [Self.Title]).AppendLine;
    lResult.AppendFormat('Type: %s', [Self.&Type.AsString]).AppendLine;
    lResult.AppendFormat('Message: %s', [Self.Message]).AppendLine;
    lResult.AppendFormat('Hint: %s', [Self.Hint]).AppendLine;
    lResult.AppendFormat('%s', [Self.Detail]);

    Result := lResult.ToString;
  finally
    lResult.Free;
  end;
end;
{$ENDREGION}

end.
