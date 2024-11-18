program AppDesktop;

uses
  Vcl.Forms,
  Stat in 'Source\Stat.pas' {frmStat: TFrame},
  Main in 'Source\Main.pas' {frmMain};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
