unit GrafanaLokiLogger.Core.Validation;

interface

uses
  GrafanaLokiLogger.Interfaces;

type
  TGrafanaLokiLoggerValidatorPush = class
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    procedure Validate(pSettings: IGrafanaLokiLoggerSettings; pLabels: IGrafanaLokiLoggerLabels; pLogs: IGrafanaLokiLoggerLogs);
  end;

  TGrafanaLokiLoggerValidatorBuildinfo = class
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    procedure Validate(pSettings: IGrafanaLokiLoggerSettings);
  end;

implementation

uses
  GrafanaLokiLogger.Core.Labels, GrafanaLokiLogger.Core.Logs,
  GrafanaLokiLogger.Core.Settings;

{$REGION 'TGrafanaLokiLoggerValidatorPush'}
procedure TGrafanaLokiLoggerValidatorPush.Validate(pSettings: IGrafanaLokiLoggerSettings; pLabels: IGrafanaLokiLoggerLabels; pLogs: IGrafanaLokiLoggerLogs);
begin
  pSettings.Validate;
  pLabels.Validate;
  pLogs.Validate;
end;
{$ENDREGION}

{$REGION 'TGrafanaLokiLoggerValidatorPush'}
procedure TGrafanaLokiLoggerValidatorBuildinfo.Validate(pSettings: IGrafanaLokiLoggerSettings);
begin
  pSettings.Validate;
end;
{$ENDREGION}

end.
