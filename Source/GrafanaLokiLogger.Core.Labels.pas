{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Core.Labels.pas                                  }
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
unit GrafanaLokiLogger.Core.Labels;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}Generics.Collections,{$ELSE}System.Generics.Collections,{$ENDIF}
  GrafanaLokiLogger.Interfaces, GrafanaLokiLogger.Types;

type
  TGrafanaLokiLoggerLabels = class(TInterfacedObject, IGrafanaLokiLoggerLabels)
  strict private
    { private declarations }
    {$IF DEFINED(FPC)}
    FGrafanaLokiLogger: IGrafanaLokiLogger;
    {$ELSE}
    [Weak] FGrafanaLokiLogger: IGrafanaLokiLogger;
    {$ENDIF}
    FLabels: TDictionary<string, string>;
    procedure CheckLabelsIsEmpty;
    procedure CheckLabelIsEmpty(const pLabel: string);
    procedure CheckLabelIsNameReservedForInternalUse(const pLabel: string);
    procedure CheckLabelRegex(const pLabel: string);
    function Clear: IGrafanaLokiLoggerLabels;
    function &Label(const pName: string; const pValue: string): IGrafanaLokiLoggerLabels;
    function Parse: string;
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
  SysUtils, RegExpr, Generics.Defaults, fpjson,
  {$ELSE}
  System.SysUtils, System.RegularExpressions, System.Generics.Defaults, System.JSON,
  {$ENDIF}
  GrafanaLokiLogger.Classes;

{$REGION 'TGrafanaLokiLoggerLabels'}
constructor TGrafanaLokiLoggerLabels.Create(pParent: IGrafanaLokiLogger);
begin
  FGrafanaLokiLogger := pParent;
  {$IF DEFINED(FPC)}
  FLabels := TDictionary<string, string>.Create(256);
  {$ELSE}
  FLabels := TDictionary<string, string>.Create(256, TIStringComparer.Ordinal); // CASE INSENSITIVE
  {$ENDIF}
end;

destructor TGrafanaLokiLoggerLabels.Destroy;
begin
  FLabels.Free;
  inherited Destroy;
end;

function TGrafanaLokiLoggerLabels.Clear: IGrafanaLokiLoggerLabels;
begin
  Result := Self;
  FLabels.Clear;
end;

function TGrafanaLokiLoggerLabels.&End: IGrafanaLokiLogger;
begin
  Result := FGrafanaLokiLogger;
end;

function TGrafanaLokiLoggerLabels.&Label(const pName: string; const pValue: string): IGrafanaLokiLoggerLabels;
begin
  Result := Self;
  FLabels.AddOrSetValue(Trim(pName), Trim(pValue));
end;

function TGrafanaLokiLoggerLabels.Parse: string;
var
  lLabel: TPair<string, string>;
  lLabelValues: TJSONObject;
begin
  lLabelValues := TJSONObject.Create;
  try
    for lLabel in FLabels do
      {$IF DEFINED(FPC)}
      lLabelValues.Add(lLabel.Key, lLabel.Value);
      {$ELSE}
      lLabelValues.AddPair(TJSONPair.Create(lLabel.Key, lLabel.Value));
      {$ENDIF}

    Result := {$IF DEFINED(FPC)}lLabelValues.AsJSON{$ELSE}lLabelValues.ToString{$ENDIF};
  finally
    lLabelValues.Free;
  end;
end;

procedure TGrafanaLokiLoggerLabels.CheckLabelIsEmpty(const pLabel: string);
begin
  if (Trim(pLabel) <> EmptyStr) then
    Exit;

  raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
    .Title('Label Validation')
    .Msg('Label name is empty.')
    .Hint('Label name is required.');
end;

procedure TGrafanaLokiLoggerLabels.CheckLabelIsNameReservedForInternalUse(const pLabel: string);
begin
  if pLabel.StartsWith('__') then
    raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
      .Title('Label Validation')
      .Msg('Label names beginning with __ are reserved for internal use.')
      .Hint('https://grafana.com/docs/loki/latest/get-started/labels');
end;

procedure TGrafanaLokiLoggerLabels.CheckLabelRegex(const pLabel: string);
var
  {$IF DEFINED(FPC)}
  lRegex: TRegExpr;
  {$ELSE}
  lRegex: TRegEx;
  {$ENDIF}
begin
  // https://grafana.com/docs/loki/latest/get-started/labels/
  {$IF DEFINED(FPC)}
  lRegex := TRegExpr.Create('^[a-zA-Z_][a-zA-Z0-9_]*$');
  {$ELSE}
  lRegex := TRegEx.Create('^[a-zA-Z_][a-zA-Z0-9_]*$');
  {$ENDIF}

  if not {$IF DEFINED(FPC)}lRegex.Exec(pLabel){$ELSE}lRegex.IsMatch(pLabel){$ENDIF} then
    raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
      .Title('Label Validation')
      .Msg('Invalid label name.')
      .Hint('Labels may contain ASCII letters, numbers, as well as underscores. They must match the regex [a-zA-Z_][a-zA-Z0-9_]*.')
      .Detail('https://grafana.com/docs/loki/latest/get-started/labels');
end;

procedure TGrafanaLokiLoggerLabels.CheckLabelsIsEmpty;
begin
  if (FLabels.Count = 0) then
    raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
      .Title('Label Validation')
      .Msg('It is required to specify the labels.')
      .Hint('It is necessary to specify at least one label.');
end;

procedure TGrafanaLokiLoggerLabels.Validate;
var
  lLabel: TPair<string, string>;
begin
  CheckLabelsIsEmpty;

  for lLabel in FLabels do
  begin
    CheckLabelIsEmpty(lLabel.Key);
    CheckLabelIsNameReservedForInternalUse(lLabel.Key);
    CheckLabelRegex(lLabel.Key);
  end;
end;
{$ENDREGION}

end.
