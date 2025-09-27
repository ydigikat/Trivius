//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`ifndef __TYPES_SVH__
`define __TYPES_SVH__

typedef logic[7:0] midi_byte_t;

typedef enum logic[4:0]
{
  MidiOmni=5'h17
} midi_ch_t;

typedef enum logic[7:0]
{
  MidiStatusNoteOff = 8'h80,
  MidiStatusNoteOn = 8'h90,
  MidiStatusPolyPressure = 8'hA0,
  MidiStatusControlChange = 8'hB0,
  MidiStatusProgramChange = 8'hC0,
  MidiStatusChannelPressure = 8'hD0,
  MidiStatusPitchBend = 8'hE0,
  MidiStatusSysExStart = 8'hF0,
  MidiStatusSysTimeCode = 8'hF1,
  MidiStatusSongPos = 8'hF2,
  MidiStatusSongSelect = 8'hF3,
  MidiStatusSysExEnd = 8'hF7,
  MidiStatusTimingClock = 8'hF8,
  MidiStatusStart = 8'hFA,
  MidiStatusContinue = 8'hFB,
  MidiStatusStop = 8'hFC,
  MidiStatusActiveSense = 8'hFE,
  MidiStatusReset = 8'hFF,
  MidiStatusInvalid = 8'h00
} midi_code_t;

`endif // __TYPES_SVH__
