{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Parse.Delphi.pas                                 }
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
unit GrafanaLokiLogger.Core.Parse;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
  Classes, fpjson,
  {$ELSE}
  System.Classes, System.JSON,
  {$ENDIF}
  GrafanaLokiLogger.Interfaces, GrafanaLokiLogger.Classes;

type
  TParseStreams = class(TParseStreamsCustom)
  private
    { private declarations }
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
  {$IF DEFINED(FPC)}
  SysUtils, Generics.Collections, DateUtils,
  {$ELSE}
  System.SysUtils, System.Generics.Collections, System.DateUtils,
  {$ENDIF}
  GrafanaLokiLogger.Utils, GrafanaLokiLogger.Types;

{ TParseStreams }

function TParseStreams.GetUNIXEpoch(const pDateTime: TDateTime): string;
var
  lUNIXEpoch: Int64;
begin
  TThread.Sleep(5);
  lUNIXEpoch := UNIXTimestamp(pDateTime);
  Result := IntToStr(lUNIXEpoch);
  Result := Result.PadRight(19, '0'); // According to API
end;

function TParseStreams.ParseLabels(pGrafanaLokiLoggerLabels: IGrafanaLokiLoggerLabels): TJSONObject;
begin
  {$IF DEFINED(FPC)}
  Result := GetJSON(pGrafanaLokiLoggerLabels.Parse) as TJSONObject;
  {$ELSE}
  Result := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(pGrafanaLokiLoggerLabels.Parse), 0) as TJSONObject;
  {$ENDIF}
end;

function TParseStreams.ParseLogs(pGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs): TJSONArray;
var
  lLines: TArray<TPair<TGrafanaLokiLoggerLevel, IGrafanaLokiLoggerLog>>;
  lLine: TPair<TGrafanaLokiLoggerLevel, IGrafanaLokiLoggerLog>;
  lTime: TDateTime;
  lTimeISO8601: string;
  lUNIXEpoch: string;
  lLevel: TGrafanaLokiLoggerLevel;
  lLogValues: string;
  lText: string;
  lValues: TJSONArray;
begin
  Result := TJSONArray.Create;

  lLines := pGrafanaLokiLoggerLogs.Lines;
  for lLine in lLines do
  begin
    lTime := Now();
    lUNIXEpoch := GetUNIXEpoch(lTime);
    lTimeISO8601 := DateToISO8601(lTime, False);

    lLevel := lLine.Key;
    lLogValues := lLine.Value.Parse;

    lText := Format('time=%s level=%s%s', [lTimeISO8601, lLevel.AsString, lLogValues]);

    lValues := TJSONArray.Create;

    {$IF DEFINED(FPC)}
    lValues.Add(TJSONString.Create(lUNIXEpoch)); // 1º unix epoch in nanoseconds
    lValues.Add(TJSONString.Create(lText)); // 2º text

    Result.Add(lValues);
    {$ELSE}
    lValues.AddElement(TJSONString.Create(lUNIXEpoch)); // 1º unix epoch in nanoseconds
    lValues.AddElement(TJSONString.Create(lText)); // 2º text

    Result.AddElement(lValues);
    {$ENDIF}
  end;
end;

function TParseStreams.Parse(pGrafanaLokiLoggerLabels: IGrafanaLokiLoggerLabels; pGrafanaLokiLoggerLogs: IGrafanaLokiLoggerLogs): string;
var
  lStreams: TJSONObject;
  lStreamsItems: TJSONObject;
begin
  lStreams := TJSONObject.Create;
  try
    lStreamsItems := TJSONObject.Create;

    // PARSE: LABELS
    try
      {$IF DEFINED(FPC)}
      lStreamsItems.Add('stream', ParseLabels(pGrafanaLokiLoggerLabels));
      {$ELSE}
      lStreamsItems.AddPair(TJSONPair.Create('stream', ParseLabels(pGrafanaLokiLoggerLabels)));
      {$ENDIF}
    except
      on E: Exception do
      begin
        lStreamsItems.Free;
        raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
          .Title('Parse fail')
          .Msg(E.Message)
          .Hint('Failed to parse label values.');
      end;
    end;

    // PARSE: LOGs
    try
      {$IF DEFINED(FPC)}
      lStreamsItems.Add('values', ParseLogs(pGrafanaLokiLoggerLogs));
      {$ELSE}
      lStreamsItems.AddPair(TJSONPair.Create('values', ParseLogs(pGrafanaLokiLoggerLogs)));
      {$ENDIF}
    except
      on E: Exception do
      begin
        lStreamsItems.Free;
        raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.Validation)
          .Title('Parse fail. Logs')
          .Msg(E.Message)
          .Hint('Failed to parse log values.');
      end;
    end;

    {$IF DEFINED(FPC)}
    lStreams.Add('streams', TJSONArray.Create([lStreamsItems]));
    Result := lStreams.AsJSON;
    {$ELSE}
    lStreams.AddPair('streams', TJSONArray.Create(lStreamsItems));
    Result := lStreams.ToString;
    {$ENDIF}
  finally
    lStreams.Free;
  end;
end;

end.
