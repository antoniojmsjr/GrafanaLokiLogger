unit Stat;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Spin;

type

  { TfrmStat }

  TfrmStat = class(TFrame)
    bvlAmount: TBevel;
    bvlStat: TBevel;
    edtAmount: TSpinEdit;
    lblAmount: TLabel;
    pnlAmount: TPanel;
    pnlContainer: TPanel;
    pnlStat: TPanel;
  private

  public

  end;

implementation

{$R *.lfm}

end.

