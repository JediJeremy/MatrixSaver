unit Unit3;

interface
uses
	Windows, Forms, SysUtils, inifiles;

type
	TConfig = class(TObject)
	protected
		ini: TIniFile;
	public
		fadespeed: Double;
		framedelay: Integer;
		procedure save;
		constructor Create;
	end;

implementation

{ TConfig }

constructor TConfig.Create;
begin
	inherited Create;
	ini:=TIniFile.Create(ExtractFilePath(Application.Exename)+'matrixsaver.ini');
	fadespeed:=ini.ReadFloat('Properties','fadespeed',0.96);
	framedelay:=ini.ReadInteger('Properties','framedelay',25);
end;

procedure TConfig.save;
begin
	ini.WriteString('Properties','fadespeed',FloatToStrF(fadespeed,ffFixed,7,3));
	ini.WriteInteger('Properties','framedelay',framedelay);
end;


end.
 