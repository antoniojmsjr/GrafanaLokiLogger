{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Core.Logs.pas                                    }
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
unit GrafanaLokiLogger.Core.Logs;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
  Generics.Collections, fpjson,
  {$ELSE}
  System.Generics.Collections, System.JSON,
  {$ENDIF}
  GrafanaLokiLogger.Interfaces, GrafanaLokiLogger.Types;

type
  TPairLog = TPair<TGrafanaLokiLoggerLevel, IGrafanaLokiLoggerLog>;

  TGrafanaLokiLoggerLog = class(TInterfacedObject, IGrafanaLokiLoggerLog)
  strict private
    { private declarations }
    {$IF DEFINED(FPC)}
    FGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs;
    {$ELSE}
    [Weak] FGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs;
    {$ENDIF}
    FText: string;
    FJSONObject: TJSONObject;
    FJSONObjectOwnsObject: Boolean;
    FFields: TDictionary<string, string>;
    function Log(const pText: string): IGrafanaLokiLoggerLog; overload;
    function Log(const pJSONObject: TJSONObject; const pOwnsObject: Boolean = True): IGrafanaLokiLoggerLog; overload;
    function Log(const pField: string; const pValue: string): IGrafanaLokiLoggerLog; overload;
    function IsEmpty: Boolean;
    function Parse: string;
    function &End: IGrafanaLokiLoggerLogs;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(pParent: IGrafanaLokiLoggerLogs);
    destructor Destroy; override;
  end;

  TGrafanaLokiLoggerLogs = class(TInterfacedObject, IGrafanaLokiLoggerLogs)
  strict private
    { private declarations }
    {$IF DEFINED(FPC)}
    FGrafanaLokiLogger: IGrafanaLokiLogger;
    {$ELSE}
    [Weak] FGrafanaLokiLogger: IGrafanaLokiLogger;
    {$ENDIF}
    FLogs: TList<TPairLog>;
    function Clear: IGrafanaLokiLoggerLogs;
    function Lines(const pLevel: TGrafanaLokiLoggerLevel): IGrafanaLokiLoggerLog; overload;
    function Lines: TArray<TPair<TGrafanaLokiLoggerLevel, IGrafanaLokiLoggerLog>>; overload;
    procedure Validate;
    function &End: IGrafanaLokiLogger;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(pParent: IGrafanaLokiLogger);
    destructor Destroy; override;
  end;

implementation

uses
  {$IF DEFINED(FPC)}
  Generics.Defaults, Windows, SysUtils,
  {$ELSE}
  System.Generics.Defaults, Winapi.Windows, System.SysUtils,
  {$ENDIF}
  GrafanaLokiLogger.Classes;

{$REGION 'TGrafanaLokiLoggerLog'}
constructor TGrafanaLokiLoggerLog.Create(pParent: IGrafanaLokiLoggerLogs);
begin
  FGrafanaLokiLoggerLogs := pParent;
  {$IF DEFINED(FPC)}
  FFields := TDictionary<string, string>.Create(256);
  {$ELSE}
  FFields := TDictionary<string, string>.Create(256, TIStringComparer.Ordinal); // CASE INSENSITIVE
  {$ENDIF}
end;

destructor TGrafanaLokiLoggerLog.Destroy;
begin
  FFields.Free;
  if (Assigned(FJSONObject) and (FJSONObjectOwnsObject)) then
    FreeAndNil(FJSONObject);
  inherited Destroy;
end;

function TGrafanaLokiLoggerLog.&End: IGrafanaLokiLoggerLogs;
begin
  Result := FGrafanaLokiLoggerLogs;
end;

function TGrafanaLokiLoggerLog.Log(const pText: string): IGrafanaLokiLoggerLog;
begin
  Result := Self;
  FText := Trim(pText);
end;

function TGrafanaLokiLoggerLog.Log(const pJSONObject: TJSONObject; const pOwnsObject: Boolean): IGrafanaLokiLoggerLog;
begin
  Result := Self;
  FJSONObject := pJSONObject;
  FJSONObjectOwnsObject := pOwnsObject;
end;

function TGrafanaLokiLoggerLog.Log(const pField: string; const pValue: string): IGrafanaLokiLoggerLog;
begin
  Result := Self;
  FFields.AddOrSetValue(Trim(pField), Trim(pValue));
end;

function TGrafanaLokiLoggerLog.Parse: string;
var
  lField: TPair<string, string>;
  lFieldValues: TStringBuilder;
  lFieldValue: string;
  lTextValue: string;
  lJSONValue: string;
begin
  // FIELDS
  lFieldValue := EmptyStr;
  lFieldValues := TStringBuilder.Create;
  try
    for lField in FFields do
      lFieldValues.Append(#32).AppendFormat('%s=%s', [lField.Key, lField.Value]);
    lFieldValue := lFieldValues.ToString;
  finally
    lFieldValues.Free;
  end;

  // TEXT
  if (FText <> EmptyStr) then
    lTextValue := Format('%s%s', [#32, FText]);

  // JSONObject
  if Assigned(FJSONObject) then
    lJSONValue := Format('%s%s', [#32, FJSONObject.ToString]);

  Result := Format('%s%s%s', [lFieldValue, lTextValue, lJSONValue]);
end;

function TGrafanaLokiLoggerLog.IsEmpty;
begin
  Result := ((FFields.Count = 0) and (FText = '') and (FJSONObject = nil));
end;
{$ENDREGION}

{$REGION 'TGrafanaLokiLoggerLogs'}
constructor TGrafanaLokiLoggerLogs.Create(pParent: IGrafanaLokiLogger);
begin
  FGrafanaLokiLogger := pParent;
  FLogs := TList<TPairLog>.Create;
end;

destructor TGrafanaLokiLoggerLogs.Destroy;
begin
  FLogs.Free;
  inherited Destroy;
end;

function TGrafanaLokiLoggerLogs.Clear: IGrafanaLokiLoggerLogs;
begin
  Result := Self;
  FLogs.Clear;
end;

function TGrafanaLokiLoggerLogs.&End: IGrafanaLokiLogger;
begin
  Result := FGrafanaLokiLogger;
end;

function TGrafanaLokiLoggerLogs.Lines: TArray<TPair<TGrafanaLokiLoggerLevel, IGrafanaLokiLoggerLog>>;
begin
  Result := FLogs.ToArray;
end;

procedure TGrafanaLokiLoggerLogs.Validate;
var
  lPairLog: TPairLog;
begin
  for lPairLog in FLogs do
    if not lPairLog.Value.IsEmpty then
      Exit;

  raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
    .Title('Logs Validation')
    .Msg('It is required to specify the logs.')
    .Hint('It is necessary to specify at least one log.');
end;

function TGrafanaLokiLoggerLogs.Lines(const pLevel: TGrafanaLokiLoggerLevel): IGrafanaLokiLoggerLog;
begin
  Result := TGrafanaLokiLoggerLog.Create(Self);
  FLogs.Add(TPairLog.Create(pLevel, Result));
end;
{$ENDREGION}

end.
