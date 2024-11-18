{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Utils.pas                                        }
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
unit GrafanaLokiLogger.Utils;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}Classes;{$ELSE}System.Classes;{$ENDIF}

function UnixTimestamp(const pDateTime: TDateTime): Int64;
function AuthBasicToBase64(const pUser: string; const pPassword: string): string;
function Compression(const pContent: string): TStream; overload;
function Compression(const pContent: TStream): TStream; overload;

implementation

uses
  {$IF DEFINED(FPC)}
  DateUtils, SysUtils, base64, zstream,
  {$ELSE}
  System.DateUtils, System.SysUtils, System.NetEncoding, System.ZLib,
  {$ENDIF}
  GrafanaLokiLogger.Types;

function UnixTimestamp(const pDateTime: TDateTime): Int64;
var
  lDate: TDateTime;
begin
  {$IF DEFINED(FPC)}
  lDate := LocalTimeToUniversal(pDateTime);
  {$ELSE}
  lDate := TTimeZone.Local.ToUniversalTime(pDateTime);
  {$ENDIF}
  Result := MilliSecondsBetween(UnixDateDelta, lDate);
  if (lDate < UnixDateDelta) then
     Result := -Result;
end;

function AuthBasicToBase64(const pUser: string; const pPassword: string): string;
var
  {$IF NOT DEFINED(FPC)}
  lBase64Encoding: TBase64Encoding;
  {$ENDIF}
  lText: string;
begin
  if ((pUser = EmptyStr) or (pPassword = EmptyStr)) then
    Exit(EmptyStr);

  lText := Format('%s:%s', [pUser, pPassword]);

  {$IF DEFINED(FPC)}
  Result := EncodeStringBase64(lText);
  {$ELSE}
  lBase64Encoding := TBase64Encoding.Create(0);
  try
    Result := lBase64Encoding.Encode(lText);
  finally
    lBase64Encoding.Free;
  end;
  {$ENDIF}
end;

function Compression(const pContent: string): TStream; overload;
var
  lContent: TStringStream;
begin
  if (Trim(pContent) = EmptyStr) then
    Exit(nil);

  lContent := TStringStream.Create(pContent, TEncoding.UTF8);
  try
    Result := Compression(lContent);
  finally
    lContent.Free;
  end;
end;

function Compression(const pContent: TStream): TStream;
var
  lZStream: {$IF DEFINED(FPC)}TCompressionStream{$ELSE}TZCompressionStream{$ENDIF};
begin
  if ((pContent = nil) or (pContent.Size = 0)) then
    Exit(nil);

  Result := TMemoryStream.Create;

  {$IF DEFINED(FPC)}
  lZStream := TCompressionStream.Create(Tcompressionlevel.clmax, Result, True);
  {$ELSE}
  lZStream := TZCompressionStream.Create(Result, TZCompressionLevel.zcMax, TGrafanaLokiLoggerCompression.Gzip.WindowsBits);
  {$ENDIF}

  try
    pContent.Position := 0;
    lZStream.CopyFrom(pContent, 0);
  finally
    lZStream.Free;
  end;

  Result.Position := 0;
end;

end.
