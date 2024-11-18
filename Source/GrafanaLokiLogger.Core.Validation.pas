unit GrafanaLokiLogger.Core.Validation;

interface

uses
  GrafanaLokiLogger.Interfaces;

type
  TGrafanaLokiLoggerValidator = class
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    procedure Validate(pSettings: IGrafanaLokiLoggerSettings; pLabels: IGrafanaLokiLoggerLabels; pLogs: IGrafanaLokiLoggerLogs);
  end;

implementation

uses
  GrafanaLokiLogger.Core.Labels, GrafanaLokiLogger.Core.Logs,
  GrafanaLokiLogger.Core.Settings;

{$REGION 'TGrafanaLokiLoggerValidator'}
procedure TGrafanaLokiLoggerValidator.Validate(pSettings: IGrafanaLokiLoggerSettings; pLabels: IGrafanaLokiLoggerLabels; pLogs: IGrafanaLokiLoggerLogs);
begin
  pSettings.Validate;
  pLabels.Validate;
  pLogs.Validate;
end;
{$ENDREGION}

end.
