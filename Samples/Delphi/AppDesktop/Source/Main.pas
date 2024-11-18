unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Samples.Spin, Stat, Vcl.Buttons, Vcl.Imaging.pngimage, GrafanaLokiLogger;

type
  TfrmMain = class(TForm)
    pnlClient: TPanel;
    gbxLogs: TGroupBox;
    pnlLogs: TGridPanel;
    pnlLogUnknownContainer: TPanel;
    frmStatUnknown: TfrmStat;
    pnlLogCriticalContainer: TPanel;
    frmStatCritical: TfrmStat;
    pnlLogErrorContainer: TPanel;
    frmStatError: TfrmStat;
    pnlLogWarningContainer: TPanel;
    frmStatWarning: TfrmStat;
    pnlLogInfoContainer: TPanel;
    frmStatInfo: TfrmStat;
    pnlLogDebugContainer: TPanel;
    frmStatDebug: TfrmStat;
    pnlLogTraceContainer: TPanel;
    frmStatTrace: TfrmStat;
    pnlLogTotalContainer: TPanel;
    lblTotal: TLabel;
    pnlTotal: TPanel;
    pnlLogPushContainer: TPanel;
    bvlPushDivision: TBevel;
    btnPushLogs: TBitBtn;
    gbxErrors: TGroupBox;
    mmoErros: TMemo;
    pnlHeader: TGridPanel;
    pnlHeaderOptions: TPanel;
    gbxSettings: TGroupBox;
    lblSettingsURL: TLabel;
    lblSettingsTimeout: TLabel;
    edtSettingsURL: TEdit;
    edtSettingsTimeout: TSpinEdit;
    ckbSettingsCompression: TCheckBox;
    gbxLabels: TGroupBox;
    lblLabelApp: TLabel;
    lblLabelID: TLabel;
    lblLabelCustom: TLabel;
    edtLabelApp: TEdit;
    edtLabelID: TEdit;
    edtLabelCustom: TEdit;
    pnlHeaderInfo: TPanel;
    imgLogo: TImage;
    pnlHeaderApp: TPanel;
    lblHeaderAppGithub: TLinkLabel;
    lblHeaderAppName: TLinkLabel;
    lblHeaderGrafanaLabs: TLinkLabel;
    lblHeaderGrafanaLabsSite: TLinkLabel;
    gbxSettingsBasicAuth: TGroupBox;
    lblSettingsBasicAuthUser: TLabel;
    edtSettingsBasicAuthUser: TEdit;
    lblSettingsBasicAuthPassword: TLabel;
    edtSettingsBasicAuthPassword: TEdit;
    procedure AmountChange(Sender: TObject);
    procedure btnPushLogsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lblHeaderAppGithubLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure lblHeaderGrafanaLabsSiteLinkClick(Sender: TObject;
      const Link: string; LinkType: TSysLinkType);
  private
    { Private declarations }
    procedure SetTotal(const pValue: Integer);
    function GetAmount: Integer;
    procedure PushLog(const pLevel: TGrafanaLokiLoggerLevel; const pRecord: Integer);
    procedure LogError(const pMessage: string);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.JSON, System.Threading, Winapi.ShellAPI, GrafanaLokiLogger.Types;

{$R *.dfm}
{$I GrafanaLokiLogger.inc}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetTotal(GetAmount);

  Self.Caption := Format('GrafanaLokiLogger v%s', [GrafanaLokiLoggerVersion]);
  lblHeaderAppName.Caption := Format('GrafanaLokiLogger v%s', [GrafanaLokiLoggerVersion]);
  lblHeaderAppGithub.Caption :=
    '<a href="https://github.com/antoniojmsjr/GrafanaLokiLogger">https://github.com/antoniojmsjr/GrafanaLokiLogger</a>';
  lblHeaderGrafanaLabsSite.Caption :=
    '<a href="https://grafana.com">https://grafana.com</a>';
end;

procedure TfrmMain.AmountChange(Sender: TObject);
begin
  SetTotal(GetAmount);
end;

procedure TfrmMain.btnPushLogsClick(Sender: TObject);
begin
  if (Trim(edtSettingsURL.Text) = EmptyStr) then
  begin
    edtSettingsURL.SetFocus;
    Application.MessageBox(PWideChar('URL is empty.' + sLineBreak + 'URL is required.'), 'A T T E N T I O N', MB_OK + MB_ICONWARNING);
    Exit;
  end;

  mmoErros.Clear;

  TTask.Run(procedure
  var
    lTasks: array of ITask;
  begin
    TThread.Synchronize(nil, procedure
    begin
      pnlHeader.Enabled := False;
      pnlLogs.Enabled := False;
      btnPushLogs.Caption := 'Wait a moment!';
      btnPushLogs.Font.Style := [fsBold];
      btnPushLogs.Font.Size := 12;
    end);

    Setlength (lTasks, 7);

    // Unknown
    lTasks[0] := TTask.Create(procedure
    var
      lAmountUnknown: Integer;
      I: Integer;
    begin
      lAmountUnknown := frmStatUnknown.edtAmount.Value;
      for I := 1 to lAmountUnknown do
        PushLog(TGrafanaLokiLoggerLevel.Unknown, I);
    end);
    lTasks[0].Start;

    // Critical
    lTasks[1] := TTask.Create(procedure
    var
      lAmountCritical: Integer;
      I: Integer;
    begin
      lAmountCritical := frmStatCritical.edtAmount.Value;
      for I := 1 to lAmountCritical do
        PushLog(TGrafanaLokiLoggerLevel.Critical, I);
    end);
    lTasks[1].Start;

    // Error
    lTasks[2] := TTask.Create(procedure
    var
      lAmountError: Integer;
      I: Integer;
    begin
      lAmountError := frmStatError.edtAmount.Value;
      for I := 1 to lAmountError do
        PushLog(TGrafanaLokiLoggerLevel.Error, I);
    end);
    lTasks[2].Start;

    // Warning
    lTasks[3] := TTask.Create(procedure
    var
      lAmountWarning: Integer;
      I: Integer;
    begin
      lAmountWarning := frmStatWarning.edtAmount.Value;
      for I := 1 to lAmountWarning do
        PushLog(TGrafanaLokiLoggerLevel.Warning, I);
    end);
    lTasks[3].Start;

    // Info
    lTasks[4] := TTask.Create(procedure
    var
      lAmountInfo: Integer;
      I: Integer;
    begin
      lAmountInfo := frmStatInfo.edtAmount.Value;
      for I := 1 to lAmountInfo do
        PushLog(TGrafanaLokiLoggerLevel.Info, I);
    end);
    lTasks[4].Start;

    // Debug
    lTasks[5] := TTask.Create(procedure
    var
      lAmountDebug: Integer;
      I: Integer;
    begin
      lAmountDebug := frmStatDebug.edtAmount.Value;
      for I := 1 to lAmountDebug do
        PushLog(TGrafanaLokiLoggerLevel.Debug, I);
    end);
    lTasks[5].Start;

    // Trace
    lTasks[6] := TTask.Create(procedure
    var
      lAmountTrace: Integer;
      I: Integer;
    begin
      lAmountTrace := frmStatTrace.edtAmount.Value;
      for I := 1 to lAmountTrace do
        PushLog(TGrafanaLokiLoggerLevel.Trace, I);
    end);
    lTasks[6].Start;

    // Wait
    TTask.WaitForAll(lTasks);

    TThread.Synchronize(nil, procedure
    begin
      pnlHeader.Enabled := True;
      pnlLogs.Enabled := True;
      btnPushLogs.Caption := 'Push Logs';
      btnPushLogs.Font.Style := [];
      btnPushLogs.Font.Size := 8;
    end);

  end);
end;

procedure TfrmMain.SetTotal(const pValue: Integer);
begin
  pnlTotal.Caption := Format('%.4d', [pValue]);
end;

function TfrmMain.GetAmount: Integer;
begin
  Result := frmStatUnknown.edtAmount.Value +
            frmStatCritical.edtAmount.Value +
            frmStatError.edtAmount.Value +
            frmStatWarning.edtAmount.Value +
            frmStatInfo.edtAmount.Value +
            frmStatDebug.edtAmount.Value +
            frmStatTrace.edtAmount.Value;
end;

procedure TfrmMain.lblHeaderAppGithubLinkClick(Sender: TObject;
  const Link: string; LinkType: TSysLinkType);
begin
  ShellExecute(0, nil, PChar(Link), nil, nil, 1);
end;

procedure TfrmMain.lblHeaderGrafanaLabsSiteLinkClick(Sender: TObject;
  const Link: string; LinkType: TSysLinkType);
begin
  ShellExecute(0, nil, PChar(Link), nil, nil, 1);
end;

procedure TfrmMain.LogError(const pMessage: string);
begin
  TThread.Synchronize(nil, procedure
  begin
    mmoErros.Lines.Add(pMessage);
    mmoErros.Lines.Add(StringOfChar('-', 500));
  end);
end;

procedure TfrmMain.PushLog(const pLevel: TGrafanaLokiLoggerLevel; const pRecord: Integer);
var
  lJSONObj: TJSONObject;
begin
  lJSONObj := TJSONObject.Create;
  lJSONObj.AddPair(TJSONPair.Create('Lib', 'GrafanaLokiLogger'));
  lJSONObj.AddPair(TJSONPair.Create('Version', TGrafanaLokiLogger.Build.Version));

  try
    TGrafanaLokiLogger.Build
      .Settings
        .Reset
        .URL(edtSettingsURL.Text)
        .Timeout(edtSettingsTimeout.Value)
        .Compression(ckbSettingsCompression.Checked)
        .Authentication
          .Basic(edtSettingsBasicAuthUser.Text, edtSettingsBasicAuthPassword.Text)
      .&End
      .Labels
        .&Label('app', edtLabelApp.Text)
        .&Label('id', edtLabelID.Text)
        .&Label('custom', edtLabelCustom.Text)
      .&End
      .Logs
        .Lines(pLevel)
          .Log('field_1', 'value_1')
          .Log('field_2', 'value_2')
          .Log('record', Format('%d', [pRecord]))
          .Log('Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry''s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.')
          .Log(lJSONObj)
        .&End
      .&End
      .Push;
  except
    on E: Exception do
    begin
      if E is EGrafanaLokiLogger then
        LogError(Format('Level: %s - Error: %s - %s', [pLevel.AsString, EGrafanaLokiLogger(E).ToString, E.QualifiedClassName]))
      else
        LogError(Format('Level: %s - Error: %s - %s', [pLevel.AsString, E.Message, E.QualifiedClassName]));
    end;
  end;
  TThread.Sleep(10);
end;

end.
