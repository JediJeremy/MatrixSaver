unit Unit1;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Forms,
	ExtCtrls, Controls, inifiles, dialogs;

type
	TGlyph = class(TObject)
	protected
		Pixels: Array [0..15,0..15] of Byte;
		FWidth: Integer;
		FHeight: Integer;
		procedure SmudgePixel(x,y,xi,yi: Integer; amount: Single);
		procedure SmudgeGlyph;
	public
		procedure Paint(canvas: TCanvas; x,y: Integer; bright: Integer; first: Boolean);
		constructor Create; overload; virtual;
		constructor Create(data: String); overload; virtual;
		constructor Create(bitmap: TBitmap); overload; virtual;
	end;

	TCharacter = class(TObject)
	public
		next: TCharacter;
		prev: TCharacter;
		left: TCharacter;
		right: TCharacter;
		x,y: Integer;
		glyph: Integer;
		intensity: Single;
		spawn: Boolean;
		procedure refresh(Image: TPaintBox);
		constructor create(x,y: Integer);
	end;

	TColumn = class(TObject)
	public
		next: TColumn;
		list: TCharacter;
		count: Integer;
		procedure refresh(Image: TPaintBox);
		constructor create(x,y,yinc,count: Integer; left: TColumn);
	end;

	TCursor = class;

	TCursorSet = class(TObject)
	public
		cursors: TList;
		columns: TColumn;
		columncount: Integer;
		minimum: Integer;
		function  newCursor(col: TColumn; chr: TCharacter): TCursor;
		function  newRandomCursor: TCursor;
		procedure deadCursor(cursor: TCursor);
		procedure update;
		constructor Create(columns: TColumn);
		destructor Destroy; override;
	end;

	TCursor = class(TObject)
	public
		parent: TCursorSet;
		character: TCharacter;
		column: TColumn;
		remaining: Integer;
		procedure Update;
		constructor Create(parent: TCursorSet; col: TColumn; chr: TCharacter);
	end;

	TForm1 = class(TForm)
		image: TPaintBox;
		procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
		procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
		procedure FormKeyPress(Sender: TObject; var Key: Char);
	private
		{ Private declarations }
	public
		columns: TColumn;
		stop: Boolean;
		events: Integer;
		{ Public declarations }
		procedure ScreenSave;
		procedure LoadGlyphs;
		procedure Initialize;
		procedure Refresh(image: TPaintBox);
	end;

var
	Form1: TForm1;

implementation
uses unit3;
{$R *.DFM}

var config: TConfig;

var glyphs: TImage;
		glyphlist: TList;
		glyphcount: Integer;
		glyphframes: Integer;
		cursorset: TCursorSet;

procedure TForm1.ScreenSave;
begin
	config:=TConfig.Create;
	Events:=0;
	Show; Application.ProcessMessages;
	ShowCursor(false);
	Initialize;
	stop:=False;
	while not stop do begin
		Refresh(Image);
		cursorset.update;
		if config.framedelay>0 then Sleep(config.framedelay);
		Application.ProcessMessages;
	end;
	ShowCursor(true);
	Close;
end;

procedure TForm1.LoadGlyphs;
var bmp: TPicture;
		path: String;
		i,j,k: Integer;
		r: TSearchRec;
		more: Boolean;
begin
	// get a path to the glyphs
	path:=ExtractFilePath(Application.ExeName)+'glyphs\';
	// create a list
	glyphlist:=TList.Create;
	// add a set of glyphs
	bmp:=TPicture.Create;
	more:=FindFirst(path+'*.bmp',0,r)=0;
	while more do begin
		bmp.LoadFromFile(path+r.name);	glyphlist.Add(TGlyph.Create(bmp.Bitmap));
		more:=FindNext(r)=0;
	end;
	FindClose(r);
	glyphcount:=glyphlist.count;
	glyphframes:=32;
	// build the glyphs bitmap
	glyphs:=TImage.Create(nil);
	glyphs.Width:=16*glyphframes;
	glyphs.Height:=16*glyphcount;
	for i:=0 to glyphcount-1 do begin
		for j:=0 to glyphframes-1 do begin
			k:=j*6;
			TGlyph(glyphlist[i]).Paint(glyphs.canvas,j*16,i*16,k,j=31);
		end;
	end;
end;

procedure TForm1.Initialize;
var i,j: Integer;
		col,next: TColumn;
		size: TSize;
		im: TImage;
		ch: char;
begin
	// load the glyphs
	LoadGlyphs;
	// build the columns
	col:=nil;
	for i:=1 to Image.width div 24 do begin
		next:=TColumn.Create(i*24,0,16,Image.height div 16-1,col);
		if col=nil then columns:=next else col.next:=next;
		col:=next;
	end;
	// build the cursors
	cursorset:=TCursorSet.Create(columns);
	cursorset.minimum:=cursorset.columncount;
	for i:=1 to cursorset.minimum do begin
		cursorset.newRandomCursor;
	end;
	// clear the canvas
	image.canvas.brush.color:=clBlack;
	image.canvas.brush.style:=bsSolid;
	image.canvas.FillRect(Rect(0,0,image.width,image.height));
end;

procedure TForm1.Refresh(image: TPaintBox);
var col: TColumn;
begin
	col:=columns;
	while col<>nil do begin
		col.refresh(image);
		col:=col.next;
	end;
	// image.BringToFront;
end;

{ TCharacter }

constructor TCharacter.create(x,y: Integer);
begin
	inherited Create;
	self.x:=x;
	self.y:=y;
	glyph:=Random(GlyphCount);
	Intensity:=0.0;
	spawn:=(Random(100)=42);
end;

procedure TCharacter.refresh(Image: TPaintBox);
var col: TColor;
		frame: Integer;
		srect: TRect;
		drect: TRect;
begin
	frame:=Trunc((glyphframes-1)*intensity);
	srect:=rect(frame*16,glyph*16,frame*16+15,glyph*16+15);
	drect:=rect(x,y,x+15,y+15);
	image.canvas.CopyRect(drect,glyphs.canvas,srect);
	intensity:=intensity*config.fadespeed;
end;

{ TColumn }

constructor TColumn.create(x, y, yinc, count: Integer; left: TColumn);
var c,next,lc: TCharacter;
		i: Integer;
begin
	inherited Create;
	self.count:=count;
	if left<>nil then lc:=left.list else lc:=nil;
	// create the characters
	c:=nil;
	for i:=0 to count-1 do begin
		next:=TCharacter.Create(x,y+yinc*i);
		next.prev:=c;
		if lc<>nil then begin
			next.left:=lc;
			lc.right:=next;
			lc:=lc.next;
		end;
		if c=nil then list:=next else c.next:=next;
		c:=next;
	end;
end;


procedure TColumn.refresh(Image: TPaintBox);
var c,cursor: TCharacter;
begin
	// repaint the characters
	c:=list;
	while c<>nil do begin
		c.refresh(image);
		c:=c.next;
	end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	stop:=true;
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
begin
	Inc(events);
	If events>3 then Stop:=True;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
	Stop:=True;
end;

{ TGlyph }

constructor TGlyph.Create;
begin
	inherited;
	FWidth:=16;
	FHeight:=16;
end;

constructor TGlyph.Create(data: String);
begin
	Create;
	// copy the string data into the pixel array
end;

constructor TGlyph.Create(bitmap: TBitmap);
var i,j,k: Integer;
		c: Longint;
		b: Byte;
begin
	Create;
	// now, copy the bitmap pixel data into the pixel array
	if (bitmap.Width=16) and (bitmap.height=16) then begin
		for i:=0 to 15 do begin
			for j:=0 to 15 do begin
				c:=bitmap.Canvas.Pixels[j,i];
				b:=c and $FF;
				Pixels[j,i]:=b;
			end;
		end;
	end;
	// and smudge the glyph
	SmudgeGlyph;
end;


// paint this glyph onto a canvas, with the appropriate animation attributes
// :time = Integer value from 0..255.
procedure TGlyph.Paint(canvas: TCanvas; x, y, bright: Integer; first: Boolean);
var i,j,k: Integer;
		c: Longint;
		b: Byte;
begin
	if first then begin
		// paint with green background
		for i:=0 to 15 do begin
			for j:=0 to 15 do begin
				b:=Pixels[j,i];
				b:=b*3 div 4;
				c:=(bright*b and $00FF00)+$404040;
				canvas.Pixels[x+j,y+i]:=c;
			end;
		end;
	end else begin
		// paint with black background
		for i:=0 to 15 do begin
			for j:=0 to 15 do begin
				b:=Pixels[j,i];
				c:=bright*b and $00FF00;
				canvas.Pixels[x+j,y+i]:=c;
			end;
		end;
	end;
end;


procedure TGlyph.SmudgeGlyph;
var x,y,xi,yi,i: Integer;
		correct: Boolean;
begin
	// do a number of pixels
	For i:=0 to FWidth*FHeight do begin
		// choose a random pixel
		x:=Random(FWidth);
		y:=Random(FHeight);
		// choose a random direction
		correct:=false;
		while not correct do begin
			xi:=Random(3)-1;
			yi:=Random(3)-1;
			correct:=(xi<>0)or(yi<>0);
		end;
		// do the pixel
		SmudgePixel(x,y,xi,yi,0.3);
	end;
end;

procedure TGlyph.SmudgePixel(x, y, xi, yi: Integer; amount: Single);
var continue: Boolean;
		c1,c2,c3: Integer;
begin
	// we're going to smudge a single pixel by a single direction,
	// by transferring some of the 'color' between the two pixels.
	// we want to maintain the overall colour balance.
	continue:=true;
	continue:=continue and (x+xi>=0) and (x+xi<FWidth);
	continue:=continue and (y+yi>=0) and (y+yi<FHeight);
	if continue then begin
		c1:=Pixels[x,y];
		c2:=Pixels[x+xi,y+yi];
		c3:=Trunc((c1-c2)*amount);
		c1:=c1-c3;
		c2:=c2+c3;
		Pixels[x,y]:=c1;
		Pixels[x+xi,y+yi]:=c2;
	end;
end;

{ TCursorSet }

constructor TCursorSet.Create(columns: TColumn);
var this: TColumn;
begin
	inherited Create;
	self.cursors:=TList.Create;
	self.columns:=columns;
	self.columncount:=0;
	// count the columns
	this:=columns;
	while this<>nil do begin
		inc(columncount);
		this:=this.next;
	end;
end;

procedure TCursorSet.deadCursor(cursor: TCursor);
var i: Integer;
begin
	// get rid of this cursor.
	i:=cursors.indexof(cursor);
	if i>=0 then begin
		cursors.Delete(i);
	end else begin
		// huh? A cursor we didn't create???
	end;
	cursor.Free;
	// Possibly create another one.
	while cursors.count<minimum do newRandomCursor;
end;

destructor TCursorSet.Destroy;
begin
	while cursors.count>0 do begin TObject(cursors[0]).Free; cursors.delete(0); end;
	cursors.Free;
	inherited;
end;

function TCursorSet.newCursor(col: TColumn; chr: TCharacter): TCursor;
begin
	result:=TCursor.Create(self,col,chr);
	cursors.Add(result);
end;

function TCursorSet.newRandomCursor: TCursor;
var i: Integer;
		col: TColumn;
		chr: TCharacter;
begin
	// pick a random column
	i:=Random(columncount); col:=columns;
	while i>0 do begin dec(i); col:=col.next;	end;
	// pick the first character
	chr:=col.list;
	// create a new cursor
	result:=newCursor(col,chr);
end;

procedure TCursorSet.update;
var i: Integer;
		cursor: TCursor;
begin
	i:=0;
	while i<cursors.count do begin
		cursor:=TCursor(cursors[i]);
		cursor.update;
		inc(i);
	end;
end;

{ TCursor }

constructor TCursor.Create(parent: TCursorSet; col: TColumn; chr: TCharacter);
begin
	inherited Create;
	self.parent:=parent;
	self.column:=col;
	self.character:=chr;
	self.remaining:=random(col.count);
end;

procedure TCursor.Update;
var new: TCursor;
begin
	if (remaining>0) and (character<>nil) then begin
		// check if the character has a spawn bit
		if character.spawn then begin
			if character.right<>nil then begin
				new:=parent.newCursor(column,character.right);
				new.remaining:=remaining;
			end;
		end;
		// decrement our run counter
		dec(remaining);
		if random(5)>2 then character.glyph:=Random(GlyphCount);
		character.intensity:=1;
		character:=character.next;
	end else begin
		// we're dead.
		parent.deadCursor(self);
	end;
end;

end.
