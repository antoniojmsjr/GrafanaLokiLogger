{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Core.Buildinfo.pas                               }
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
unit GrafanaLokiLogger.Core.Buildinfo;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
  Classes, SysUtils, fpjson, DateUtils,
  {$ELSE}
  System.Classes, System.SysUtils, System.DateUtils, System.JSON,
  {$ENDIF}
  GrafanaLokiLogger.Interfaces;

type

  { TGrafanaLokiLoggerBuildinfo }

  TGrafanaLokiLoggerBuildinfo = class(TInterfacedObject, IGrafanaLokiLoggerBuildinfo)
  private
    { private declarations }
    FVersion: string;
    FRevision: string;
    FBranch: string;
    FBuildUser: string;
    FBuildDate: TDateTime;
    FGoVersion: string;
    function Version: string;
    function Revision: string;
    function Branch: string;
    function BuildUser: string;
    function BuildDate: TDateTime;
    function GoVersion: string;
    procedure Parse(const pJSON: string);
    {$IF DEFINED(FPC)}
    procedure ParseLazarus(const pBuildinfo: TJSONObject);
    {$ELSE}
    procedure ParseDelphi(const pBuildinfo: TJSONObject);
    {$ENDIF}
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(const pJSON: string); reintroduce; virtual;
    function ToString: string; override;
  end;

implementation

{$REGION 'TGrafanaLokiLoggerBuildinfo'}
constructor TGrafanaLokiLoggerBuildinfo.Create(const pJSON: string);
begin
  Parse(pJSON);
end;

function TGrafanaLokiLoggerBuildinfo.Branch: string;
begin
  Result := FBranch;
end;

function TGrafanaLokiLoggerBuildinfo.BuildDate: TDateTime;
begin
  Result := FBuildDate;
end;

function TGrafanaLokiLoggerBuildinfo.BuildUser: string;
begin
  Result := FBuildUser;
end;

function TGrafanaLokiLoggerBuildinfo.GoVersion: string;
begin
  Result := FGoVersion;
end;

function TGrafanaLokiLoggerBuildinfo.Revision: string;
begin
  Result := FRevision;
end;

function TGrafanaLokiLoggerBuildinfo.ToString: string;
var
  lResult: TStringBuilder;
begin
  Result := EmptyStr;

  lResult := TStringBuilder.Create;
  try
    lResult.AppendFormat('Version: %s', [Self.Version]).AppendLine;
    lResult.AppendFormat('Revision: %s', [Self.Revision]).AppendLine;
    lResult.AppendFormat('Branch: %s', [Self.Branch]).AppendLine;
    lResult.AppendFormat('BuildUser: %s', [Self.BuildUser]).AppendLine;
    lResult.AppendFormat('BuildDate: %s', [DateTimeToStr(Self.BuildDate)]);

    Result := lResult.ToString;
  finally
    lResult.Free;
  end;
end;

function TGrafanaLokiLoggerBuildinfo.Version: string;
begin
  Result := FVersion;
end;

procedure TGrafanaLokiLoggerBuildinfo.Parse(const pJSON: string);
var
  lBuildinfo: TJSONObject;
begin
  lBuildinfo := nil;
  try
    {$IF DEFINED(FPC)}
    lBuildinfo := GetJSON(pJSON) as TJSONObject;
    ParseLazarus(lBuildinfo);
    {$ELSE}
    lBuildinfo := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(pJSON), 0) as TJSONObject;
    ParseDelphi(lBuildinfo);
    {$ENDIF}
  finally
    lBuildinfo.Free;
  end;
end;

{$IF DEFINED(FPC)}
procedure TGrafanaLokiLoggerBuildinfo.ParseLazarus(const pBuildinfo: TJSONObject);
var
  lValue: TJSONString;
begin
  if pBuildinfo.Find('version', lValue) then
    FVersion := lValue.AsString;
  if pBuildinfo.Find('revision', lValue) then
    FRevision := lValue.AsString;
  if pBuildinfo.Find('branch', lValue) then
    FBranch := lValue.AsString;
  if pBuildinfo.Find('buildUser', lValue) then
    FBuildUser := lValue.AsString;
  if pBuildinfo.Find('buildDate', lValue) then
    FBuildDate := ISO8601ToDate(lValue.AsString);
  if pBuildinfo.Find('goVersion', lValue) then
    FGoVersion := lValue.AsString;
end;
{$ENDIF}

{$IF NOT DEFINED(FPC)}
procedure TGrafanaLokiLoggerBuildinfo.ParseDelphi(const pBuildinfo: TJSONObject);
var
  lValue: string;
begin
  if pBuildinfo.TryGetValue<string>('version', lValue) then
    FVersion := lValue;
  if pBuildinfo.TryGetValue<string>('revision', lValue) then
    FRevision := lValue;
  if pBuildinfo.TryGetValue<string>('branch', lValue) then
    FBranch := lValue;
  if pBuildinfo.TryGetValue<string>('buildUser', lValue) then
    FBuildUser := lValue;
  if pBuildinfo.TryGetValue<string>('buildDate', lValue) then
    FBuildDate := ISO8601ToDate(lValue);
  if pBuildinfo.TryGetValue<string>('goVersion', lValue) then
    FGoVersion := lValue;
end;
{$ENDIF}

{$ENDREGION}

end.
