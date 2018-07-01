unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TForm4 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

uses Unit1,Unit2,Unit3;

{$R *.DFM}

procedure TForm4.FormCreate(Sender: TObject);
var	config: TConfig;
begin
	config:=TConfig.Create;
	//Form2:=TForm2.Create(Application);
	//Form2.config:=config;
	//Form2.Show;
end;

end.
 