unit uConstanteBASS;

interface
uses
  Windows,SysUtils,Classes;

const


  // Minimum - Maximum valeur pour chaque type de config de chaque effet
  CHORUS_MIN_WET_DRY_MIX=0.0;
  CHORUS_INI_WET_DRY_MIX=50.0;
  CHORUS_MAX_WET_DRY_MIX = 100.0;

  CHORUS_MIN_DEPTH=0.0;
  CHORUS_INI_DEPTH=10.0;
  CHORUS_MAX_DEPTH=100.0;

  CHORUS_MIN_FEEDBACK=-99.0;
  CHORUS_INI_FEEDBACK=25.0;
  CHORUS_MAX_FEEDBACK=99.0;

  CHORUS_MIN_FREQUENCY=0.0;
  CHORUS_INI_FREQUENCY=1.1;
  CHORUS_MAX_FREQUENCY=10.0;

  CHORUS_MIN_DELAY=0.0;
  CHORUS_INI_DELAY=16.0;
  CHORUS_MAX_DELAY=20.0;

  CHORUS_MIN_WAVE_FORM = 0;
  CHORUS_INI_WAVE_FORM = 1;
  CHORUS_MAX_WAVE_FORM = 1;
  // pour retrouver le nom des WaveForms , il faut appeler la fonction GetNameChorusWaveForms ( AWaveForms : DWORD) : STRING ;
  CHORUS_MIN_PHASE = 0;
  CHORUS_INI_PHASE = 3;
  CHORUS_MAX_PHASE = 5;
  // pour retrouver le nom des phases , il faut appeler la fonction GetNameChorusPhase ( APhase : DWORD) : STRING ;

  EQUALISEUR_MIN_CENTER = 80.0;
  EQUALISEUR_MAX_CENTER = 16000.0;

  EQUALISEUR_MIN_BANDWITH = 1.0;
  EQUALISEUR_INI_BANDWITH = 12.0;
  EQUALISEUR_MAX_BANDWITH = 36.0;

  EQUALISEUR_MIN_GAIN = -15.0;
  EQUALISEUR_INI_GAIN = -0.0;
  EQUALISEUR_MAX_GAIN =  15.0;

  DISTORTION_MIN_GAIN=-60.0;
  DISTORTION_INI_GAIN=-18.0;
  DISTORTION_MAX_GAIN=0.0;

  DISTORTION_MIN_EDGE=0.0;
  DISTORTION_INI_EDGE=15.0;
  DISTORTION_MAX_EDGE=100.0;

  DISTORTION_MIN_POST_EQ_CENTER_FREQUENCY=100.0;
  DISTORTION_INI_POST_EQ_CENTER_FREQUENCY=2400.0;
  DISTORTION_MAX_POST_EQ_CENTER_FREQUENCY=8000.0;

  DISTORTION_MIN_POST_EQ_BANDWITH=100.0;
  DISTORTION_INI_POST_EQ_BANDWITH=2400.0;
  DISTORTION_MAX_POST_EQ_BANDWITH=8000.0;

  DISTORTION_MIN_PRE_LOWPASS_CUT_OFF=100.0;
  DISTORTION_INI_PRE_LOWPASS_CUT_OFF=8000.0;
  DISTORTION_MAX_PRE_LOWPASS_CUT_OFF=8000.0;

  ECHO_MIN_WET_DRY_MIX = 0.0;
  ECHO_INI_WET_DRY_MIX = 50.0;
  ECHO_MAX_WET_DRY_MIX = 100.0;

  ECHO_MIN_FEEDBACK = 0.0;
  ECHO_INI_FEEDBACK = 50.0;
  ECHO_MAX_FEEDBACK = 100.0;

  ECHO_MIN_LEFT_DELAY = 1.0;
  ECHO_INI_LEFT_DELAY = 500.0;
  ECHO_MAX_LEFT_DELAY = 2000.0;

  ECHO_MIN_RIGHT_DELAY = 1.0;
  ECHO_INI_RIGHT_DELAY = 500.0;
  ECHO_MAX_RIGHT_DELAY = 2000.0;

  COMPRESSOR_MIN_GAIN=-60.0;
  COMPRESSOR_INI_GAIN=0.0;
  COMPRESSOR_MAX_GAIN=60.0;

  COMPRESSOR_MIN_ATTACK = 0.01;
  COMPRESSOR_INI_ATTACK =10.0;
  COMPRESSOR_MAX_ATTACK =500.0;

  COMPRESSOR_MIN_RELEASE = 50.0;
  COMPRESSOR_INI_RELEASE =200.0;
  COMPRESSOR_MAX_RELEASE =3000.0;

  COMPRESSOR_MIN_THRESOLD =50.0;
  COMPRESSOR_INI_THRESOLD =200.0;
  COMPRESSOR_MAX_THRESOLD =3000.0;

  COMPRESSOR_MIN_RATIO =1.0;
  COMPRESSOR_INI_RATIO =3.0;
  COMPRESSOR_MAX_RATIO =100.0;

  COMPRESSOR_MIN_PREDELAY =0.0;
  COMPRESSOR_INI_PREDELAY =4.0;
  COMPRESSOR_MAX_PREDELAY =4.0;

  FLANGER_MIN_WET_DRY_MIX=0.0;
  FLANGER_INI_WET_DRY_MIX=50.0;
  FLANGER_MAX_WET_DRY_MIX = 100.0;

  FLANGER_MIN_DEPTH=0.0;
  FLANGER_INI_DEPTH=100.0;
  FLANGER_MAX_DEPTH=100.0;

  FLANGER_MIN_FEEDBACK=-99.0;
  FLANGER_INI_FEEDBACK=-50.0;
  FLANGER_MAX_FEEDBACK=99.0;

  FLANGER_MIN_FREQUENCY=0.0;
  FLANGER_INI_FREQUENCY=0.25;
  FLANGER_MAX_FREQUENCY=10.0;

  FLANGER_MIN_DELAY=0.0;
  FLANGER_INI_DELAY=2.0;
  FLANGER_MAX_DELAY=4.0;

  FLANGER_MIN_WAVE_FORM = 0;
  FLANGER_INI_WAVE_FORM = 1;
  FLANGER_MAX_WAVE_FORM = 1;
  // pour retrouver le nom des WaveForms , il faut appeler la fonction GetNameFlangerWaveForms ( AWaveForms : DWORD) : STRING ;
  FLANGER_MIN_PHASE = 0;
  FLANGER_INI_PHASE = 3;
  FLANGER_MAX_PHASE = 5;
  // pour retrouver le nom des phases , il faut appeler la fonction GetNameFlangerPhase ( APhase : DWORD) : STRING ;

  GARGLE_MIN_DW_RATE_HZ=1;
  GARGLE_INI_DW_RATE_HZ=20;
  GARGLE_MAX_DW_RATE_HZ=1000;

  REVERB_MIN_GAIN = -96.0;
  REVERB_INI_GAIN = 0.0;
  REVERB_MAX_GAIN = 0.0;

  REVERB_MIN_MIX = -96.0;
  REVERB_INI_MIX = 0.0;
  REVERB_MAX_MIX = 0.0;

  REVERB_MIN_TIME = 0.001;
  REVERB_INI_TIME = 1000;
  REVERB_MAX_TIME = 3000;

  REVERB_MIN_FREQ_RATIO = 0.001;
  REVERB_INI_FREQ_RATIO = 0.001;
  REVERB_MAX_FREQ_RATIO = 0.999;

  function GetNameChorusWaveForms( AWaveForms : DWORD) : String ;
  function GetNameChorusPhase (APhase : DWORD):String;
  function GetNameFlangerWaveForms( AWaveForms : DWORD) : String ;
  function GetNameFlangerPhase (APhase : DWORD):String;

implementation

function GetNameChorusWaveForms( AWaveForms : DWORD) : String ;
begin
  case AWaveForms of
    0 : result := 'Triangle';
    1 : result := 'Sine';
    else
      result := '';
  end;
end;
function GetNameChorusPhase(APhase : DWORD):String;
begin
  case APhase of
    0 : result := 'BASS_DX8_PHASE_NEG_180';
    1 :  result := 'BASS_DX8_PHASE_NEG_90';
    2 :    result := 'BASS_DX8_PHASE_ZERO';
    3:       result := 'BASS_DX8_PHASE_90';
    4 :     result := 'BASS_DX8_PHASE_180';
    else
      result := '';
  end;
end;

function GetNameFlangerWaveForms( AWaveForms : DWORD) : String ;
begin
  case AWaveForms of
    0 : result := 'Triangle';
    1 : result := 'Sine';
    else
      result := '';
  end;
end;

function GetNameFlangerPhase(APhase : DWORD):String;
begin
  case APhase of
    0 : result := 'BASS_DX8_PHASE_NEG_180';
    1  : result := 'BASS_DX8_PHASE_NEG_90';
    2    : result := 'BASS_DX8_PHASE_ZERO';
    3      : result := 'BASS_DX8_PHASE_90';
    4     : result := 'BASS_DX8_PHASE_180';
    else
      result := '';
  end;
end;

end.

