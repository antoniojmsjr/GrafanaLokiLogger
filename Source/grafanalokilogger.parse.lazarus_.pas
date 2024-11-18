{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Parse.Lazarus.pas                                 }
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
unit GrafanaLokiLogger.Parse.Lazarus;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Classes, fpjson, GrafanaLokiLogger.Interfaces, GrafanaLokiLogger.Classes;

type
  TParseStreams = class(TParseStreamsCustom)
  private
    { private declarations }
    procedure GetLogsItems(pGrafanaLokiLoggerLog: IGrafanaLokiLoggerLog; out pFields: string; out pText: string; out pJSONObject: TJSONObject);
    function GetUNIXEpoch(const pDateTime: TDateTime): string;
    function ParseLabels(pGrafanaLokiLoggerLabels: IGrafanaLokiLoggerLabels): TJSONObject;
    function ParseLogs(pGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs): TJSONArray;
  protected
    { protected declarations }
  public
    { public declarations }
    function Parse(pGrafanaLokiLoggerLabels: IGrafanaLokiLoggerLabels; pGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs): string; override;
  end;

implementation

uses
  SysUtils, Generics.Collections, DateUtils, GrafanaLokiLogger.Utils,
  GrafanaLokiLogger.Types, GrafanaLokiLogger.Core.Labels, GrafanaLokiLogger.Core.Logs;

{ TParseStreams }

procedure TParseStreams.GetLogsItems(pGrafanaLokiLoggerLog: IGrafanaLokiLoggerLog; out pFields: string; out pText: string; out pJSONObject: TJSONObject);
var
  lGrafanaLokiLoggerLog: TGrafanaLokiLoggerLog;
  lField: TPair<string, string>;
  lFields: TStringValues;
  lFieldsValues: TStringBuilder;
begin
  pFields := EmptyStr;
  pText := EmptyStr;
  pJSONObject := nil;

  lGrafanaLokiLoggerLog := TGrafanaLokiLoggerLog(pGrafanaLokiLoggerLog);
  if not Assigned(lGrafanaLokiLoggerLog) then
    Exit;

  if (lGrafanaLokiLoggerLog.Text <> EmptyStr) then
    pText := Format('%s%s', [#32, lGrafanaLokiLoggerLog.Text]);
  if Assigned(lGrafanaLokiLoggerLog.JSONObject) then
    pJSONObject := TJSONObject(lGrafanaLokiLoggerLog.JSONObject.Clone);
  lFields := lGrafanaLokiLoggerLog.Fields;

  lFieldsValues := TStringBuilder.Create;
  try
    for lField in lFields do
      lFieldsValues.Append(#32).AppendFormat('%s=%s', [lField.Key, lField.Value]);

    pFields := lFieldsValues.ToString;
  finally
    lFieldsValues.Free;
  end;
end;

function TParseStreams.GetUNIXEpoch(const pDateTime: TDateTime): string;
var
  lUNIXEpoch: Int64;
begin
  lUNIXEpoch := UNIXTimestamp(pDateTime);
  Result := IntToStr(lUNIXEpoch);
  Result := Result.PadRight(19, '0'); // According to API
end;

function TParseStreams.ParseLabels(pGrafanaLokiLoggerLabels: IGrafanaLokiLoggerLabels): TJSONObject;
var
  lLabel: TPair<string, string>;
  lLabels: TStringValues;
begin
  Result := TJSONObject.Create;

  lLabels := TGrafanaLokiLoggerLabels(pGrafanaLokiLoggerLabels).Labels;
  for lLabel in lLabels do
    Result.Add(lLabel.Key, lLabel.Value);
end;

function TParseStreams.ParseLogs(pGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs): TJSONArray;
var
  lLine: TPair<TDateTime, TGrafanaLokiLoggerLogsItems>;
  lLines: TLinesValues;
  lUNIXEpoch: string;
  lLevel: string;
  lValues: TJSONArray;
  lFields: string;
  lText: string;
  lJSONObject: TJSONObject;
  lFieldsValues: string;
begin
  Result := TJSONArray.Create;

  lLines := TGrafanaLokiLoggerLogs(pGrafanaLokiLoggerLogs).Values;
  for lLine in lLines do
  begin
    GetLogsItems(lLine.Value.GrafanaLokiLoggerLog, lFields, lText, lJSONObject);

    lUNIXEpoch := GetUNIXEpoch(lLine.Key);
    lLevel := lLine.Value.Level.AsString;
    lFieldsValues := Format('level=%s%s%s', [lLevel, lFields, lText]);

    lValues := TJSONArray.Create;

    lValues.Add(TJSONString.Create(lUNIXEpoch)); // 1º unix epoch in nanoseconds
    lValues.Add(TJSONString.Create(lFieldsValues)); // 2º free text
    if Assigned(lJSONObject) then
      lValues.Add(lJSONObject); // 3º JSONObject

    Result.Add(lValues);
  end;
end;

function TParseStreams.Parse(pGrafanaLokiLoggerLabels: IGrafanaLokiLoggerLabels; pGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs): string;
var
  lStreams: TJSONObject;
  lStreamsItems: TJSONObject;
begin
  lStreams := TJSONObject.Create;
  try
    try
      lStreamsItems := TJSONObject.Create;
      lStreamsItems.Add('stream', ParseLabels(pGrafanaLokiLoggerLabels));
      lStreamsItems.Add('values', ParseLogs(pGrafanaLokiLoggerLogs));

      lStreams.Add('streams', TJSONArray.Create([lStreamsItems]));

      Result := lStreams.ToString;
    except
      on E: Exception do
        raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
          .Title('Parse fail')
          .Msg(E.Message)
          .Hint('Check the error message.');
    end;
  finally
    lStreams.Free;
  end;
end;

end.
