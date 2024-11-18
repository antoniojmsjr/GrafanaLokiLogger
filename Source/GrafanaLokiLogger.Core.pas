{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.Core.pas                                         }
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
unit GrafanaLokiLogger.Core;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}Classes,{$ELSE}System.Classes,{$ENDIF}
  GrafanaLokiLogger.Interfaces, GrafanaLokiLogger.Core.Settings,
  GrafanaLokiLogger.Core.Labels, GrafanaLokiLogger.Core.Logs;

type
  TGrafanaLokiLogger = class(TInterfacedObject, IGrafanaLokiLogger)
  strict private
    { private declarations }
    FSettings: IGrafanaLokiLoggerSettings;
    FLabels: IGrafanaLokiLoggerLabels;
    FLogs: IGrafanaLokiLoggerLogs;
    function GetSettings: IGrafanaLokiLoggerSettings;
    function GetLabels: IGrafanaLokiLoggerLabels;
    function GetLogs: IGrafanaLokiLoggerLogs;
    function GetVersion: string;
    function GetPayload(const pJSON: string): TStream;
    procedure Push;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create;
  end;

implementation

uses
  {$IF DEFINED(FPC)}
  SysUtils, GrafanaLokiLogger.HTTP.Lazarus,
  {$ELSE}
  System.SysUtils, GrafanaLokiLogger.HTTP.Delphi,
  {$ENDIF}
  GrafanaLokiLogger.Core.Validation, GrafanaLokiLogger.Core.Parse,
  GrafanaLokiLogger.Types, GrafanaLokiLogger.Utils, GrafanaLokiLogger.Classes;

{$I GrafanaLokiLogger.inc}

{ TGrafanaLokiLogger }

constructor TGrafanaLokiLogger.Create;
begin
  FSettings := TGrafanaLokiLoggerSettings.Create(Self);
  FLabels := TGrafanaLokiLoggerLabels.Create(Self);
  FLogs := TGrafanaLokiLoggerLogs.Create(Self);
end;

function TGrafanaLokiLogger.GetLabels: IGrafanaLokiLoggerLabels;
begin
  Result := FLabels;
end;

function TGrafanaLokiLogger.GetLogs: IGrafanaLokiLoggerLogs;
begin
  Result := FLogs;
end;

function TGrafanaLokiLogger.GetSettings: IGrafanaLokiLoggerSettings;
begin
  Result := FSettings;
end;

function TGrafanaLokiLogger.GetVersion: string;
begin
  Result := GrafanaLokiLoggerVersion;
end;

function TGrafanaLokiLogger.GetPayload(const pJSON: string): TStream;
begin
  case (Self.FSettings.Compression) of
    True:
    begin
      try
        Result := Compression(pJSON);
      except
        on E: Exception do
        begin
          raise EGrafanaLokiLogger.Build(TGrafanaLokiLoggerException.RequestInvalid)
            .Title('Request Execute fail')
            .Msg(E.Message)
            .Hint('Check the error message.');
        end;
      end;
    end;
    False:
    begin
      Result := TStringStream.Create(pJSON, TEncoding.UTF8);
    end;
  end;
end;

procedure TGrafanaLokiLogger.Push;
var
  lBody: TStream;
  lParseStreams: TParseStreams;
  lParseStreamsJSON: string;
  lHTTPRequest: THTTPRequest;
  lValidator: TGrafanaLokiLoggerValidator;
begin

  // VALIDATION
  lValidator := TGrafanaLokiLoggerValidator.Create;
  try
    lValidator.Validate(Self.FSettings, Self.FLabels, Self.FLogs);
  finally
    lValidator.Free;
  end;

  // PARSE
  lParseStreams := TParseStreams.Create;
  try
    lParseStreamsJSON := lParseStreams.Parse(Self.FLabels, Self.FLogs);
  finally
    lParseStreams.Free;
  end;

  // REQUEST
  lBody := nil;
  try
    lBody := GetPayload(lParseStreamsJSON);

    lHTTPRequest := THTTPRequest.Create;
    try
      lHTTPRequest.URL := Self.FSettings.URL;
      lHTTPRequest.Timeout := Self.FSettings.Timeout;
      lHTTPRequest.Keepalive := Self.FSettings.Keepalive;
      lHTTPRequest.Compression := Self.FSettings.Compression;
      lHTTPRequest.Proxy.Server := Self.FSettings.Proxy.Server;
      lHTTPRequest.Proxy.Port := Self.FSettings.Proxy.Port;
      lHTTPRequest.Proxy.User := Self.FSettings.Proxy.User;
      lHTTPRequest.Proxy.Password := Self.FSettings.Proxy.Password;

      // https://grafana.com/docs/loki/latest/operations/multi-tenancy/
      if (Self.FSettings.MultitenantID <> EmptyStr) then
        lHTTPRequest.Headers.Add('X-Scope-OrgID', Self.FSettings.MultitenantID);

      if (Self.FSettings.Authentication.Basic <> EmptyStr) then
        lHTTPRequest.Headers.Add('Authorization', Format('Basic %s', [Self.FSettings.Authentication.Basic]));

      if (Self.FSettings.Authentication.Bearer <> EmptyStr) then
        lHTTPRequest.Headers.Add('Authorization', Format('Bearer %s', [Self.FSettings.Authentication.Bearer]));

      if (Self.FSettings.Compression) then
        {$IF DEFINED(FPC)}
        lHTTPRequest.Headers.Add('Content-Encoding', TGrafanaLokiLoggerCompression.Deflate.AsString);
        {$ELSE}
        lHTTPRequest.Headers.Add('Content-Encoding', TGrafanaLokiLoggerCompression.Gzip.AsString);
        {$ENDIF}

      lBody.Position := 0;
      lHTTPRequest.Body.CopyFrom(lBody, 0);
      lHTTPRequest.BodyJSON := lParseStreamsJSON;

      lHTTPRequest.Execute;
    finally
      lHTTPRequest.Free;
    end;
  finally
    lBody.Free;
  end;
end;

end.
