unit Stat;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Samples.Spin;

type
  TfrmStat = class(TFrame)
    bvlDivision: TBevel;
    pnlClient: TPanel;
    pnlStat: TPanel;
    lblLevel: TLabel;
    bvlDivisionStat: TBevel;
    lblAmount: TLabel;
    edtAmount: TSpinEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
