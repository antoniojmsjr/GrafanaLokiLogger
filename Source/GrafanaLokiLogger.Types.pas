{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Types.pas                                        }
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
unit GrafanaLokiLogger.Types;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
  {$MODESWITCH TypeHelpers}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
  SysUtils, Generics.Collections;
  {$ELSE}
  System.SysUtils, System.Classes, System.Generics.Collections;
  {$ENDIF}

type
  TStringValues = TArray<TPair<string, string>>;

  {$SCOPEDENUMS ON}
  TGrafanaLokiLoggerLevel = (Unknown, Critical, Error, Warning, Info, Debug, Trace);

  TGrafanaLokiLoggerException = (Unknown,
                                 Others,
                                 Validation,
                                 PayloadInvalid,
                                 RequestHttp,
                                 RequestInvalid);

  TGrafanaLokiLoggerCompression = (Unknown, Deflate, Gzip);
  {$SCOPEDENUMS OFF}

  TGrafanaLokiLoggerLevelHelper = record helper for TGrafanaLokiLoggerLevel
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    function AsString: string;
    function AsInteger: Integer;
  end;

  TGrafanaLokiLoggerExceptionHelper = record helper for TGrafanaLokiLoggerException
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    function AsString: string;
    function AsInteger: Integer;
  end;

  TGrafanaLokiLoggerCompressionHelper = record helper for TGrafanaLokiLoggerCompression
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    function AsString: string;
    function AsInteger: Integer;
    function WindowsBits: Integer;
  end;

implementation

{$REGION 'TGrafanaLokiLoggerLevelHelper'}
function TGrafanaLokiLoggerLevelHelper.AsInteger: Integer;
begin
  Result := Ord(Self);
end;

function TGrafanaLokiLoggerLevelHelper.AsString: string;
begin
  case Self of
    TGrafanaLokiLoggerLevel.Unknown: Result := 'unknown';
    TGrafanaLokiLoggerLevel.Critical: Result := 'critical';
    TGrafanaLokiLoggerLevel.Error: Result := 'error';
    TGrafanaLokiLoggerLevel.Warning: Result := 'warning';
    TGrafanaLokiLoggerLevel.Info: Result := 'info';
    TGrafanaLokiLoggerLevel.Debug: Result := 'debug';
    TGrafanaLokiLoggerLevel.Trace: Result := 'trace';
  end;
end;
{$ENDREGION}

{$REGION 'TGrafanaLokiLoggerExceptionHelper'}
function TGrafanaLokiLoggerExceptionHelper.AsInteger: Integer;
begin
  Result := Ord(Self);
end;

function TGrafanaLokiLoggerExceptionHelper.AsString: string;
begin
  case Self of
    TGrafanaLokiLoggerException.Unknown: Result := 'Unknown';
    TGrafanaLokiLoggerException.Others: Result := 'Others';
    TGrafanaLokiLoggerException.Validation: Result := 'Validation';
    TGrafanaLokiLoggerException.PayloadInvalid: Result := 'PayloadInvalid';
    TGrafanaLokiLoggerException.RequestHttp: Result := 'RequestHttp';
    TGrafanaLokiLoggerException.RequestInvalid: Result := 'RequestInvalid';
  end;
end;
{$ENDREGION}

{$REGION 'TGrafanaLokiLoggerCompressionHelper'}
function TGrafanaLokiLoggerCompressionHelper.AsInteger: Integer;
begin
  Result := Ord(Self);
end;

function TGrafanaLokiLoggerCompressionHelper.AsString: string;
begin
  case Self of
    TGrafanaLokiLoggerCompression.Unknown: Result := 'Unknown';
    TGrafanaLokiLoggerCompression.Gzip: Result := 'gzip';
    TGrafanaLokiLoggerCompression.Deflate: Result := 'deflate';
  end;
end;

function TGrafanaLokiLoggerCompressionHelper.WindowsBits: Integer;
begin
  case Self of
    TGrafanaLokiLoggerCompression.Gzip: Result := 31;
    TGrafanaLokiLoggerCompression.Deflate: Result := 15;
  else
    Result := 0;
  end;
end;
{$ENDREGION}

end.
