unit Unit2;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Unit3,
  StdCtrls, ComCtrls, ExtCtrls;

type
	TForm2 = class(TForm)
		Label1: TLabel;
		Label2: TLabel;
		Label3: TLabel;
		Label4: TLabel;
		Label5: TLabel;
		Label6: TLabel;
		Shape1: TShape;
		Label7: TLabel;
		Button1: TButton;
		Button2: TButton;
		FadeBar: TTrackBar;
		FadeEdit: TEdit;
		Button3: TButton;
    Label8: TLabel;
    DelayBar: TTrackBar;
    DelayEdit: TEdit;
    Label9: TLabel;
		procedure FadeBarChange(Sender: TObject);
		procedure Button1Click(Sender: TObject);
		procedure Button2Click(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure Button3Click(Sender: TObject);
    procedure DelayBarChange(Sender: TObject);
	private
		{ Private declarations }
	public
		{ Public declarations }
		config: TConfig;
	end;

var
	Form2: TForm2;

implementation
uses unit1;
{$R *.DFM}

procedure TForm2.FadeBarChange(Sender: TObject);
var f: Single;
begin
	f:=(80.0+FadeBar.Position) / 100;
	config.fadespeed:=f;
	fadeedit.Text:=FloatToStrF(config.fadespeed,ffFixed,7,2);
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
	config.save;
	application.Terminate;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
	application.Terminate;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
	config:=TConfig.Create;
	fadeedit.Text:=FloatToStrF(config.fadespeed,ffFixed,7,2);
	fadebar.position:=Trunc(config.fadespeed*100-80);
	delayedit.Text:=IntToStr(config.framedelay);
	delaybar.position:=config.framedelay div 5;
end;

procedure TForm2.Button3Click(Sender: TObject);
var form: TForm1;
begin
	config.Save;
	Application.CreateForm(TForm1, Form1);
	Form1.ScreenSave;
end;

procedure TForm2.DelayBarChange(Sender: TObject);
var i: Integer;
begin
	i:=DelayBar.Position*5;
	config.framedelay:=i;
	delayedit.Text:=IntToStr(config.framedelay);
end;

end.
