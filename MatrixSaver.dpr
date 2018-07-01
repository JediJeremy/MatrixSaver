program MatrixSaver;

uses
  Forms, Sysutils,
	Unit1 in 'Unit1.pas' {Form1},
	Unit2 in 'Unit2.pas' {Form2},
	Unit3 in 'Unit3.pas',
	Unit4 in 'Unit4.pas' {Form4};

{$R *.RES}
begin
	Application.Initialize;
	if hPrevInst = 0 then begin
		if lowercase(paramstr(1))='/s' then begin
			Application.CreateForm(TForm1, Form1);
			Form1.ScreenSave;
		end;
		if (paramcount=0) or (lowercase(copy(paramstr(1),1,2))='/c') then begin
			Application.CreateForm(TForm2, Form2);
		end;
	end;
	Application.Run;
end.
