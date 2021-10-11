unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, ExtCtrls, BASS, Math, CommonTypes, StdCtrls, ComCtrls,
  osc_vis;

type
  TMainForm = class(TForm)
    PanFX: TPanel;
    sbtChorus: TSpeedButton;
    sbtCompressor: TSpeedButton;
    sbtDistortion: TSpeedButton;
    sbtEcho: TSpeedButton;
    sbtFlanger: TSpeedButton;
    sbtGargle: TSpeedButton;
    sbtI3dL2Reverb: TSpeedButton;
    sbtEqualiser: TSpeedButton;
    sbtReverb: TSpeedButton;
    TimerDEC: TTimer;
    PanSynth: TPanel;
    sbtSynthKey1: TSpeedButton;
    sbtSynthKey3: TSpeedButton;
    sbtSynthKey6: TSpeedButton;
    sbtSynthKey5: TSpeedButton;
    sbtSynthKey18: TSpeedButton;
    sbtSynthKey20: TSpeedButton;
    sbtSynthKey17: TSpeedButton;
    sbtSynthKey15: TSpeedButton;
    sbtSynthKey8: TSpeedButton;
    sbtSynthKey10: TSpeedButton;
    sbtSynthKey12: TSpeedButton;
    sbtSynthKey13: TSpeedButton;
    sbtSynthKey2: TSpeedButton;
    sbtSynthKey4: TSpeedButton;
    sbtSynthKey7: TSpeedButton;
    sbtSynthKey9: TSpeedButton;
    sbtSynthKey11: TSpeedButton;
    sbtSynthKey14: TSpeedButton;
    sbtSynthKey16: TSpeedButton;
    sbtSynthKey19: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LabOctave: TLabel;
    TimerRender: TTimer;
    PaintFrame: TPaintBox;
    LabFadeOUT: TLabel;
    BitBtnSettings: TBitBtn;
    Bevel1: TBevel;
    Bevel2: TBevel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TimerDECTimer(Sender: TObject);
    procedure sbt_FX_ButtonsClick(Sender: TObject);
    procedure sbtSynthKeyClick(Sender: TObject);

    procedure TimerRenderTimer(Sender: TObject);
  private

    procedure InitBASS;
    procedure InitSinTable;
    procedure InitStream;
    procedure InitSynth;
    procedure FreeBASS;
    procedure FreeStream;

    procedure InitBASSBuffer;
    procedure ShowOctave;
    procedure ShowFadeOUT;

  public
    procedure Init;
    procedure Quit;
    procedure Get_FxButtons(index : integer);
    procedure Release_SynthKey(index : integer);
  end;

const
  FILENAME_LOG = 'log.txt';

  fxname  : array[0..8] of String = (
    'CHORUS',     'COMPRESSOR', 'DISTORTION',
    'ECHO',       'FLANGER',    'GARGLE',
    'I3DL2REVERB','PARAMEQ',    'REVERB');

  PI		= 3.14159265358979323846;
  TABLESIZE	= 2048;
  KEYS		= 20;
  MAX_FADEOUT	= 400000;
  MIN_FADEOUT = 10;
  INI_FADEOUT = 4000;

  SIZE_MIN_SETTING = 2;
  SIZE_MAX_SETTING = 150;

  INC_PROGRESS_BAR = 100;

  MIN_OCTAVE = 2.0;
  MAX_OCTAVE = 25.0;
  INI_OCTAVE = 2.0;

var
  MainForm: TMainForm;
  Stream    : HSTREAM;
  BufLen : DWORD;
  J         : HFX;

  fx        : array[0..8] of HFX = (0, 0, 0, 0, 0, 0, 0, 0, 0);	// effect handles
  SineTable	: array[0..TABLESIZE - 1] of Integer;	// sine table

  aVol		: array[0..KEYS - 1] of Integer = (	// keys' volume & pos
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  aPos		: array[0..KEYS - 1] of Integer = (
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  isKeyDown : array [0..KEYS -1 ] of boolean;
  Octave : real = INI_OCTAVE;
  MAXVOL : integer = INI_FADEOUT;
  Shape : integer;
implementation

uses uConstanteBASS;
{$R *.dfm}
// display error messages
procedure Error(Text : String);
begin
  BASS_Free;
  ExitProcess(0);
end;

//---------------------------------------------------------

function IntPower(const Base : Extended; const Exponent : Integer) : Extended;
asm
        mov     ecx, eax
        cdq
        fld1                      { Result := 1 }
        xor     eax, edx
        sub     eax, edx          { eax := Abs(Exponent) }
        jz      @@3
        fld     Base
        jmp     @@2
@@1:    fmul    ST, ST            { X := Base * Base }
@@2:    shr     eax,1
        jnc     @@1
        fmul    ST(1),ST          { Result := Result * X }
        jnz     @@1
        fstp    st                { pop X from FPU stack }
        cmp     ecx, 0
        jge     @@3
        fld1
        fdivrp                    { Result := 1 / Result }
@@3:
        fwait
end;

//---------------------------------------------------------

function Power(const Base, Exponent : Extended) : Extended;
begin
  if Exponent = 0.0 then
    Result := 1.0               { n**0 = 1 }
  else if (Base = 0.0) and (Exponent > 0.0) then
    Result := 0.0               { 0**n = 0, n > 0 }
  else if (Frac(Exponent) = 0.0) and (Abs(Exponent) <= MaxInt) then
    Result := IntPower(Base, Integer(Trunc(Exponent)))
  else
    Result := Exp(Exponent * Ln(Base))
end;

//---------------------------------------------------------

// pris tous fait de l'exemple
function WriteStream(Handle : HSTREAM; Buffer : Pointer; Len : DWORD; User : Pointer) : DWORD; stdcall;
type
  BufArray = array[0..0] of SmallInt;
var
  I, J, K : Integer;
  f       : Single;
  Buf     : ^BufArray absolute Buffer;
begin
  FillChar(Buffer^, Len, 0);
  for I := 0 to KEYS - 1 do
  begin
    if aVol[I] = 0 then
      Continue;
    f := Power(2.0, (I + 3) / 12.0) * TABLESIZE * 440.0 / 44100.0;
    for K := 0 to (Len div 4 - 1) do
    begin
      if aVol[I] = 0 then
	Continue;
      inc(aPos[I]);
      J := Round(SineTable[Round(aPos[I] * f) and pred(TABLESIZE)] * aVol[I] / MAXVOL);
      inc(J, Buf[K * 2]);
      if J > 32767 then
	J := 32767
      else if J < -32768 then
	J := -32768;
      // left and right channels are the same
      Buf[K * 2 + 1] := J;
      Buf[K * 2]     := J;
      if aVol[I] < MAXVOL then dec(aVol[I]);
    end;
  end;
  Result := Len;
end;
//---------------------------------------------------------


procedure TMainForm.ShowOctave;
begin
  LabOctave.Caption := Format('Octave [*,/]'+#13+#10+': %f',[Octave / 2]);
end;

procedure TMainForm.ShowFadeOUT;
begin
  LabFadeOUT.Caption := Format('Fade out [PageUp,PageDown,End]'+#13+#10+' : %f ms',[MAXVOL/TimerDEC.Interval]);
end;

procedure TMainForm.Get_FxButtons(index: Integer);
var
  x : integer;
begin
  for x := 0 to ComponentCount - 1 do
    if Components[x] is TSpeedButton then
      if (Components[x] as TSpeedButton).Tag = index - 112 then begin
        (Components[x] as TSpeedButton).Down := not (Components[x] as TSpeedButton).Down;
        (Components[x] as TSpeedButton).Click;
      end;
end;

procedure TMainForm.Release_SynthKey(index: Integer);
var
  x : integer;
begin
  isKeyDown[index] := false;
  for x := 0 to ComponentCount - 1 do
    if Components[x] is TSpeedButton then
      if (Components[x] as TSpeedButton).Name = 'sbtSynthKey'+ IntToStr(index+1) then begin
        (Components[x] as TSpeedButton).Down :=false;
      end;
end;

procedure TMainForm.InitBASS;
begin
  if HIWORD(BASS_GetVersion) <> BASSVERSION then Exit;
  BASS_SetConfig(BASS_CONFIG_UPDATEPERIOD, 10);
  if not BASS_Init(-1, 44100, BASS_DEVICE_LATENCY, 0, NIL) then
    Error('Can''t initialize device');
end;

procedure TMainForm.InitSinTable;
var
  I : integer;
  a,aMax,aMax1,aMin,aMin1,aMin2 : extended;
begin
  // customisation % à l'exemple dans le zip pr les != formes d'ondes
  // fait à l'arrache !
  for I := 0 to TABLESIZE - 1 do begin  // build sine table
    a := sin(Octave * PI * I / TABLESIZE);
    case Shape of
      0 :
       begin
        aMax := 1;
        aMax1 := 1;
        aMin := -1;
        aMin1 := -1;
        aMin2 := a;
      end;
      1 :
      begin
        aMax := 0.5;
        aMax1 := 1;
        aMin := -0.5;
        aMin1 := -1;
        aMin2 := a;
      end;
      2 :
      begin
        aMax := 0.2;
        aMax1 := 1;
        aMin := -10;
        aMin1 := -1;
        aMin2 := -1;
      end;
    end;

    if a >= aMax then
      a := aMax1
    else begin
      if a <= aMin then
        a := aMin1
      else
        a:=aMin2;
    end;
    SineTable[I] :=Round((a * 7000.0));
  end;
end;

procedure TMainForm.InitBASSBuffer;
var
  info      : BASS_INFO;
begin
  BASS_GetInfo(info);
  BASS_SetConfig(BASS_CONFIG_BUFFER, 10 + info.minbuf);
  BufLen := BASS_GetConfig(BASS_CONFIG_BUFFER);
end;


procedure TMainForm.InitStream;
var
  info : BASS_INFO;
begin
  Stream := BASS_StreamCreate(44100, 2, 0, @WriteStream, NIL);
  BASS_ChannelPlay(Stream, False);
end;

procedure TMainForm.InitSynth;
var
  BitmapNoir : TBitmap;
  BitmapBlanc : TBitmap;
begin
  BitmapNoir := TBitmap.Create;
  BitmapNoir.LoadFromFile('Noire.bmp');

  BitmapBlanc := TBitmap.Create;
  BitmapBlanc.LoadFromFile('Blanche.bmp');

  sbtSynthKey2.Glyph := BitmapNoir;
  sbtSynthKey4.Glyph := BitmapNoir;
  sbtSynthKey7.Glyph := BitmapNoir;
  sbtSynthKey9.Glyph := BitmapNoir;
  sbtSynthKey11.Glyph := BitmapNoir;
  sbtSynthKey14.Glyph := BitmapNoir;
  sbtSynthKey16.Glyph := BitmapNoir;
  sbtSynthKey19.Glyph := BitmapNoir;

  sbtSynthKey1.Glyph := BitmapBlanc;
  sbtSynthKey3.Glyph := BitmapBlanc;
  sbtSynthKey5.Glyph := BitmapBlanc;
  sbtSynthKey6.Glyph := BitmapBlanc;
  sbtSynthKey8.Glyph := BitmapBlanc;
  sbtSynthKey10.Glyph := BitmapBlanc;
  sbtSynthKey12.Glyph := BitmapBlanc;
  sbtSynthKey13.Glyph := BitmapBlanc;
  sbtSynthKey15.Glyph := BitmapBlanc;
  sbtSynthKey17.Glyph := BitmapBlanc;
  sbtSynthKey18.Glyph := BitmapBlanc;
  sbtSynthKey20.Glyph := BitmapBlanc;


  BitmapNoir.Free;
  BitmapBlanc.Free;
end;


procedure TMainForm.FreeBASS;
begin
  BASS_Free;
end;

procedure TMainForm.FreeStream;
begin
  BASS_StreamFree(Stream);
end;

procedure TMainForm.Init;
var
  x : integer;
begin
  InitBASS;
  InitSinTable;
  InitBASSBuffer;
  InitStream;
  InitSynth;
  DoubleBuffered := true;
  PanSynth.DoubleBuffered := True;
  for x := 0 to 20- 1 do
    isKeyDown[x] := false;

  TimerDEC.Enabled := true;
  KeyPreview := True;
  ShowOctave;
  ShowFadeOUT;
  Left := Screen.WorkAreaWidth div 2 - Width div 2;
  Top := Screen.WorkAreaHeight div 2 - Height div 2;

end;

procedure TmainForm.Quit;
begin
  FreeStream;
  FreeBASS;
end;

procedure TMainForm.sbtSynthKeyClick(Sender: TObject);
var
  I,x : integer;

begin
  I := TSpeedButton(Sender).Tag - 500;
  if aVol[1] = MAXVOL then
  aPos[I] := 0;
  aVol[I] := MAXVOL;
  isKeyDown[I] := true;     

  for x := 0 to ComponentCount - 1 do
    if Components[x] is TSpeedButton then
      if (Components[x] as TSpeedButton).Name = 'sbtSynthKey'+ IntToStr(I+1) then begin
        (Components[x] as TSpeedButton).Down :=true;
      end;
end;

procedure TMainForm.sbt_FX_ButtonsClick(Sender: TObject);
var
  I : integer;
begin
  I := TSpeedButton(Sender).Tag ;
  if fx[I] > 0 then
	  begin
	    BASS_ChannelRemoveFX(Stream, fx[I]);
	    fx[I] := 0;
	  end
	  else
	  begin
	    J := BASS_ChannelSetFX(Stream, BASS_FX_DX8_CHORUS + I, 0);
	    if J > 0 then
	    begin
	      fx[I] := J;
	    end;  
	  end;
end;



procedure TMainForm.TimerDECTimer(Sender: TObject);
var
  x : integer;
begin
  for x := 0 to 20 - 1 do begin
    if aVol[x] > 0 then begin
      if isKeyDown[x] = false then dec(aVol[x]);
    end;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Shape := 0;
  Init;
  OcilloScope := TOcilloScope.Create(PaintFrame.Width, PaintFrame.Height);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Quit;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

  if key = VK_ESCAPE then  close;

  if (Key = 33) then begin
    if(MAXVOL < MAX_FADEOUT) then MAXVOL:=MAXVOL + 100;
    ShowFadeOUT;
  end;

  if (Key = 34) then begin
    if(MAXVOL > MIN_FADEOUT) then MAXVOL:=MAXVOL - 100;
    ShowFadeOUT;
  end;

  if (Key = 35) then begin
    MAXVOL := INI_FADEOUT;
    ShowFadeOUT;
  end;

  if Key in [112..120] then begin
    Get_FxButtons(Key);
  end;

  if key = 106 then begin
    if(Octave < MAX_OCTAVE) then begin
      Octave:=Octave+2.0;
      InitSinTable;
      ShowOctave;
    end;
  end;

  if key = 111 then begin
    if(Octave >= MIN_OCTAVE) then begin
      Octave:=Octave-2.0;
      InitSinTable;
      ShowOctave;
    end;
  end;

  if Key = VK_ADD then begin
    BASS_StreamFree(Stream);
    BASS_SetConfig(BASS_CONFIG_BUFFER, BufLen + 1);
  end;
  if Key = VK_SUBTRACT  then begin
    BASS_StreamFree(Stream);
    BASS_SetConfig(BASS_CONFIG_BUFFER, BufLen - 1);
  end;


  if (Key = 81) and (aVol[0]<>MAXVOL) then SbtSynthKey1.Click;
  if (Key = 90) and (aVol[1]<>MAXVOL) then SbtSynthKey2.Click;
  if (Key = 83) and (aVol[2]<>MAXVOL) then SbtSynthKey3.Click;
  if (Key = 69) and (aVol[3]<>MAXVOL) then SbtSynthKey4.Click;
  if (Key = 68) and (aVol[4]<>MAXVOL) then SbtSynthKey5.Click;
  if (Key = 70) and (aVol[5]<>MAXVOL) then SbtSynthKey6.Click;
  if (Key = 84) and (aVol[6]<>MAXVOL) then SbtSynthKey7.Click;
  if (Key = 71) and (aVol[7]<>MAXVOL) then SbtSynthKey8.Click;
  if (Key = 89) and (aVol[8]<>MAXVOL) then SbtSynthKey9.Click;
  if (Key = 72) and (aVol[9]<>MAXVOL) then SbtSynthKey10.Click;
  if (Key = 85) and (aVol[10]<>MAXVOL) then SbtSynthKey11.Click;
  if (Key = 74) and (aVol[11]<>MAXVOL) then SbtSynthKey12.Click;
  if (Key = 75) and (aVol[12]<>MAXVOL) then SbtSynthKey13.Click;
  if (Key = 79) and (aVol[13]<>MAXVOL) then SbtSynthKey14.Click;
  if (Key = 76) and (aVol[14]<>MAXVOL) then SbtSynthKey15.Click;
  if (Key = 80) and (aVol[15]<>MAXVOL) then SbtSynthKey16.Click;
  if (Key = 77) and (aVol[16]<>MAXVOL) then SbtSynthKey17.Click;

  if ((Key = 192) and (aVol[17]<>MAXVOL)) then SbtSynthKey18.Click;
  if ((Key = 186) and (aVol[18]<>MAXVOL)) then SbtSynthKey19.Click;
  if ((Key = 220) and (aVol[19]<>MAXVOL)) then SbtSynthKey20.Click;


  if Key = 49 then begin Shape := 0; InitSinTable; end;
  if Key = 50 then begin Shape := 1; InitSinTable; end;
   if Key = 51 then begin Shape := 2; InitSinTable; end;
end;


procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I : integer;
begin

  if (Key = 81) then Release_SynthKey(0);
  if (Key = 90) then Release_SynthKey(1);
  if (Key = 83) then Release_SynthKey(2);
  if (Key = 69) then Release_SynthKey(3);
  if (Key = 68) then Release_SynthKey(4);
  if (Key = 70) then Release_SynthKey(5);
  if (Key = 84) then Release_SynthKey(6);
  if (Key = 71) then Release_SynthKey(7);
  if (Key = 89) then Release_SynthKey(8);
  if (Key = 72) then Release_SynthKey(9);
  if (Key = 85) then Release_SynthKey(10);
  if (Key = 74) then Release_SynthKey(11);
  if (Key = 75) then Release_SynthKey(12);
  if (Key = 79) then Release_SynthKey(13);
  if (Key = 76) then Release_SynthKey(14);
  if (Key = 80) then Release_SynthKey(15);
  if (Key = 77) then Release_SynthKey(16);

  if (Key = 192) then Release_SynthKey(17);
  if (Key = 186) then Release_SynthKey(18);
  if (Key = 220) then Release_SynthKey(19);

  if(Key in [VK_ADD..VK_SUBTRACT]) then begin
    BufLen := BASS_GetConfig(BASS_CONFIG_BUFFER);
	  Stream := BASS_StreamCreate(44100, 2, 0, @WriteStream, NIL);
	  // set effects on the new stream
	  for I := 0 to 8 do
	    if fx[I] > 0 then
	      fx[I] := BASS_ChannelSetFX(Stream, BASS_FX_DX8_CHORUS + I, 0);
	  BASS_ChannelPlay(Stream, False);
  end;
end;

procedure TMainForm.TimerRenderTimer(Sender: TObject);
var
  WaveData  : TWaveData;
begin
  if BASS_ChannelIsActive(Stream) <> BASS_ACTIVE_PLAYING then Exit;
  BASS_ChannelGetData(Stream, @WaveData, 2048);
  OcilloScope.Draw (PaintFrame.Canvas.Handle, WaveData, 0, 40);
end;

end.
