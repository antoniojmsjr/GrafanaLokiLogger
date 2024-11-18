{******************************************************************************}
{                                                                              }
{           GrafanaLokiLogger.pas                                   }
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
unit GrafanaLokiLogger;

interface

uses
  GrafanaLokiLogger.Interfaces, GrafanaLokiLogger.Core, GrafanaLokiLogger.Types,
  GrafanaLokiLogger.Classes;

type
  TGrafanaLokiLoggerLevel = GrafanaLokiLogger.Types.TGrafanaLokiLoggerLevel;
  EGrafanaLokiLogger = GrafanaLokiLogger.Classes.EGrafanaLokiLogger;

  TGrafanaLokiLogger = class(GrafanaLokiLogger.Core.TGrafanaLokiLogger)
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    class function Build: IGrafanaLokiLogger;
  end;

implementation

{$REGION 'TGrafanaLokiLogger'}
class function TGrafanaLokiLogger.Build: IGrafanaLokiLogger;
begin
  Result := Self.Create;
end;
{$ENDREGION}

end.
