unit Main;

{$MODE Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Spin, Buttons, Menus, Stat, RTTICtrls, GrafanaLokiLogger,
  GrafanaLokiLogger.Types;

type

  { TPushLog }
  TTPushLogLogEvent = procedure(const Message: String) of Object;
  TTPushLogExecuteEvent = procedure of Object;

  TPushLog = class(TThread)
  strict private
    FAmount: Integer;
    FCompression: Boolean;
    FLabelApp: string;
    FLabelCustom: string;
    FLabelID: string;
    FLevel: TGrafanaLokiLoggerLevel;
    FOnLog: TTPushLogLogEvent;
    FTimeout: Integer;
    FURL: string;
    FAuthUser: string;
    FAuthPassword: string;
    FMessage: string;
    procedure SetAmount(AValue: Integer);
    procedure SetCompression(AValue: Boolean);
    procedure SetLabelApp(AValue: string);
    procedure SetLabelCustom(AValue: string);
    procedure SetLabelID(AValue: string);
    procedure SetLevel(AValue: TGrafanaLokiLoggerLevel);
    procedure SetOnLog(AValue: TTPushLogLogEvent);
    procedure SetTimeout(AValue: Integer);
    procedure SetURL(AValue: string);
    procedure DoLog;
  public
    constructor Create; reintroduce;
    procedure Execute; override;
    procedure Authentication(const pUser: string; const pPassword: string);
    property URL: string read FURL write SetURL;
    property Timeout: Integer read FTimeout write SetTimeout;
    property Compression: Boolean read FCompression write SetCompression;
    property LabelApp: string read FLabelApp write SetLabelApp;
    property LabelID: string read FLabelID write SetLabelID;
    property LabelCustom: string read FLabelCustom write SetLabelCustom;
    property Level: TGrafanaLokiLoggerLevel read FLevel write SetLevel;
    property Amount: Integer read FAmount write SetAmount;
    property OnLog: TTPushLogLogEvent read FOnLog write SetOnLog;
  end;

  { TfrmMain }

  TfrmMain = class(TForm)
    btnPushLogs: TBitBtn;
    bvlPush: TBevel;
    bvlTotal: TBevel;
    ckbSettingsCompression: TCheckBox;
    edtLabelApp: TEdit;
    edtLabelCustom: TEdit;
    edtLabelID: TEdit;
    edtSettingsBasicAuthPassword: TEdit;
    edtSettingsBasicAuthUser: TEdit;
    edtSettingsTimeout: TSpinEdit;
    edtSettingsURL: TEdit;
    frmStatTrace: TfrmStat;
    frmStatDebug: TfrmStat;
    frmStatInfo: TfrmStat;
    frmStatWarning: TfrmStat;
    frmStatError: TfrmStat;
    frmStatCritical: TfrmStat;
    frmStatUnknown: TfrmStat;
    gbxLabels: TGroupBox;
    gbxSettings: TGroupBox;
    gbxSettingsBasicAuth: TGroupBox;
    gbxLogs: TGroupBox;
    gbxErrors: TGroupBox;
    imgLogo: TImage;
    lblTotal: TLabel;
    lblHeaderGrafanaLabsSite: TStaticText;
    lblHeaderAppName: TLabel;
    lblHeaderGrafanaLabs: TLabel;
    lblLabelApp: TLabel;
    lblLabelCustom: TLabel;
    lblLabelID: TLabel;
    lblSettingsBasicAuthPassword: TLabel;
    lblSettingsBasicAuthUser: TLabel;
    lblSettingsTimeout: TLabel;
    lblSettingsURL: TLabel;
    mmoErrors: TMemo;
    pnlTotal: TPanel;
    pnlClient: TPanel;
    pnlHeaderApp: TPanel;
    pnlHeaderInfo: TPanel;
    pnlOptions: TPanel;
    pnlHeader: TPanel;
    lblHeaderAppGithub: TStaticText;
    PopupMenu1: TPopupMenu;
    procedure btnPushLogsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AmountChange(Sender: TObject);
    procedure LinkMouseEnter(Sender: TObject);
    procedure LinkMouseLeave(Sender: TObject);
    procedure LinkMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    function GetAmount: Integer;
    procedure SetTotal(const pValue: Integer);
    function PushLog(const pLevel: TGrafanaLokiLoggerLevel; const pAmount: Integer): TPushLog;
    procedure PushLogExecute;
    procedure PushLogExecuteTerminate(Sender: TObject);
    procedure LogError(const pMessage: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

uses
  LCLIntf, LCLType, fpjson, Generics.Collections;

{$R *.lfm}

{ TPushLog }

constructor TPushLog.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
end;

procedure TPushLog.SetCompression(AValue: Boolean);
begin
  FCompression:=AValue;
end;

procedure TPushLog.SetAmount(AValue: Integer);
begin
  FAmount:=AValue;
end;

procedure TPushLog.SetLabelApp(AValue: string);
begin
  FLabelApp:=AValue;
end;

procedure TPushLog.SetLabelCustom(AValue: string);
begin
  FLabelCustom:=AValue;
end;

procedure TPushLog.SetLabelID(AValue: string);
begin
  FLabelID:=AValue;
end;

procedure TPushLog.SetLevel(AValue: TGrafanaLokiLoggerLevel);
begin
  FLevel:=AValue;
end;

procedure TPushLog.SetOnLog(AValue: TTPushLogLogEvent);
begin
  FOnLog:=AValue;
end;

procedure TPushLog.SetTimeout(AValue: Integer);
begin
  FTimeout:=AValue;
end;

procedure TPushLog.SetURL(AValue: string);
begin
  FURL:=AValue;
end;

procedure TPushLog.DoLog;
begin
  if Assigned(FOnLog) then
     FOnLog(FMessage);
end;

procedure TPushLog.Execute;
var
  lJSONObj: TJSONObject;
  I: Integer;
begin
  for I := 1 to FAmount do
  begin
    TThread.Sleep(5);

    lJSONObj := TJSONObject.Create;
    lJSONObj.Add('Lib', 'GrafanaLokiLogger');
    lJSONObj.Add('Version', TGrafanaLokiLogger.Build.Version);

    try
      TGrafanaLokiLogger.Build
        .Settings
          .Reset
          .URL(FURL)
          .Timeout(FTimeout)
          .Compression(FCompression)
          .Authentication
            .Basic(FAuthUser, FAuthPassword)
        .&End
        .Labels
          .&Label('app', FLabelApp)
          .&Label('id', FLabelID)
          .&Label('custom', FLabelCustom)
        .&End
        .Logs
          .Lines(FLevel)
            .Log('field_1', 'value_1')
            .Log('field_2', 'value_2')
            .Log('record', Format('%d', [I]))
            .Log('Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry''s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.')
            .Log(lJSONObj)
          .&End
        .&End
        .Push;
    except
      on E: Exception do
      begin
        if E is EGrafanaLokiLogger then
          FMessage := Format('Level: %s - Error: %s - %s', [FLevel.AsString, EGrafanaLokiLogger(E).ToString, E.QualifiedClassName])
        else
          FMessage := Format('Level: %s - Error: %s - %s', [FLevel.AsString, E.Message, E.QualifiedClassName]);
        Synchronize(DoLog);
      end;
    end;
  end;
end;

procedure TPushLog.Authentication(const pUser: string; const pPassword: string);
begin
  FAuthUser := pUser;
  FAuthPassword := pPassword;
end;

{ TfrmMain }

procedure TfrmMain.LinkMouseEnter(Sender: TObject);
begin
  TLabel(Sender).Cursor := crHandPoint;
  TLabel(Sender).Font.Color := clBlue;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Self.Caption := Format('GrafanaLokiLogger v%s', [TGrafanaLokiLogger.Build.Version]);
  SetTotal(GetAmount);
end;

procedure TfrmMain.btnPushLogsClick(Sender: TObject);
begin
  if (Trim(edtSettingsURL.Text) = EmptyStr) then
  begin
    edtSettingsURL.SetFocus;
    Application.MessageBox(PChar('URL is empty.' + sLineBreak + 'URL is required.'), 'A T T E N T I O N', MB_OK + MB_ICONWARNING);
    Exit;
  end;

  mmoErrors.Clear;

  pnlOptions.Enabled := False;
  gbxLogs.Enabled := False;
  btnPushLogs.Caption := 'Wait a moment!';
  btnPushLogs.Font.Style := [fsBold];
  btnPushLogs.Font.Size := 12;

  ExecuteInThread(PushLogExecute, PushLogExecuteTerminate);
end;

procedure TfrmMain.AmountChange(Sender: TObject);
begin
  SetTotal(GetAmount);
end;

procedure TfrmMain.LinkMouseLeave(Sender: TObject);
begin
  TLabel(Sender).Cursor := crDefault;
  TLabel(Sender).Font.Color := clDefault;
end;

procedure TfrmMain.LinkMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  OpenURL(TLabel(Sender).Caption);
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

function TfrmMain.PushLog(const pLevel: TGrafanaLokiLoggerLevel; const pAmount: Integer): TPushLog;
begin
  Result := TPushLog.Create;

  Result.Authentication(edtSettingsBasicAuthUser.Text, edtSettingsBasicAuthPassword.Text);
  Result.URL := edtSettingsURL.Text;
  Result.Timeout := edtSettingsTimeout.Value;
  Result.Compression := ckbSettingsCompression.Checked;
  Result.LabelApp := edtLabelApp.Text;
  Result.LabelID := edtLabelID.Text;
  Result.LabelCustom := edtLabelCustom.Text;
  Result.Level := pLevel;
  Result.Amount:= pAmount;
  Result.OnLog := LogError;
end;

procedure TfrmMain.PushLogExecute;
var
  lThreads: TObjectList<TPushLog>;
  lPushLog: TPushLog;
begin
  lThreads := TObjectList<TPushLog>.Create;
  try
    lThreads.Add(PushLog(TGrafanaLokiLoggerLevel.Unknown, frmStatUnknown.edtAmount.Value));
    lThreads.Add(PushLog(TGrafanaLokiLoggerLevel.Critical, frmStatCritical.edtAmount.Value));
    lThreads.Add(PushLog(TGrafanaLokiLoggerLevel.Error, frmStatError.edtAmount.Value));
    lThreads.Add(PushLog(TGrafanaLokiLoggerLevel.Warning, frmStatWarning.edtAmount.Value));
    lThreads.Add(PushLog(TGrafanaLokiLoggerLevel.Info, frmStatInfo.edtAmount.Value));
    lThreads.Add(PushLog(TGrafanaLokiLoggerLevel.Debug, frmStatDebug.edtAmount.Value));
    lThreads.Add(PushLog(TGrafanaLokiLoggerLevel.Trace, frmStatTrace.edtAmount.Value));

    for lPushLog in lThreads do
      lPushLog.Start;

    for lPushLog in lThreads do
        lPushLog.WaitFor;
  finally
    lThreads.Free;
  end;
end;

procedure TfrmMain.PushLogExecuteTerminate(Sender: TObject);
begin
  pnlOptions.Enabled := True;
  gbxLogs.Enabled := True;
  btnPushLogs.Caption := 'Push Logs';
  btnPushLogs.Font.Style := [fsBold];
  btnPushLogs.Font.Size := 0;
end;

procedure TfrmMain.LogError(const pMessage: string);
begin
  mmoErrors.Lines.Add(pMessage);
  mmoErrors.Lines.Add(StringOfChar('-', 290));
end;

end.
