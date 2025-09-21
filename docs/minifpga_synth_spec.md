# MiniFPGA Synthesizer Specification

## Overview
A minimal polyphonic synthesizer designed for the GW1NR-9 FPGA as a foundation for exploring FPGA-based audio synthesis. Prioritizes simplicity and learning over feature completeness.

## System Architecture

### TDM Processing Model
- **9 processing slots total**: 8 voice slots + 1 mixing slot
- **Slot timing**: 48MHz / (48kHz × 9 slots) = ~111 system clocks per slot
- **DSP resource sharing**: All 20 DSP blocks available to each slot during its time window
- **Processing sequence**: Voice[0] → Voice[1] → ... → Voice[7] → Mixer → repeat

### Voice Architecture
- **8 voices maximum** (polyphonic with voice stealing)
- **Voice stealing**: Oldest note priority
- **Signal chain per voice**: Oscillator → Envelope → Filter → Level

## Module Specifications

### Oscillator
- **Waveform**: Sawtooth only (fundamental subtractive synthesis wave)
- **Phase accumulator**: 24-bit resolution for pitch accuracy
- **Wavetable**: 1024-point sawtooth in BRAM (16-bit samples)
- **Interpolation**: Linear interpolation for fractional table reads
- **Pitch range**: C1 to C8 (88 MIDI keys)
- **Anti-aliasing**: None initially (accept aliasing as design trade-off)
- **DSP usage**: 3-4 blocks (phase increment, table lookup, interpolation)

### Envelope Generator
- **Type**: 4-state ADSR (Attack/Decay/Sustain/Release)
- **Parameter resolution**: 8-bit (256 discrete values per parameter)
- **Curve type**: Linear segments (no exponential curves initially)
- **Coefficient storage**: Lookup tables in BRAM
- **DSP usage**: 1-2 blocks (state machine, coefficient application)

### Filter
- **Type**: Single shared 2-pole resonant lowpass
- **Topology**: State variable (easy FPGA implementation)
- **Parameters**: 8-bit cutoff and resonance resolution
- **State storage**: Per-voice filter state in SRAM
- **DSP usage**: 3-4 blocks (state variable calculations)

### Mixer
- **Function**: Sum 8 voice outputs with final scaling
- **Processing**: Dedicated mixing slot in TDM sequence
- **DSP usage**: 4-5 blocks (8-input summer, scaling, limiting)

## Resource Allocation

### DSP Blocks (20 total, shared via TDM)
- **Per voice slot**: 8-11 blocks used, 9-12 blocks available
- **Mixing slot**: 4-5 blocks used, 15-16 blocks available
- **Headroom**: ~50% DSP capacity reserved for optimization/features

### Memory Layout
- **Voice parameters**: SRAM (fast TDM access)
  - Current note, velocity, envelope state
  - Filter state per voice
- **Global parameters**: SRAM (CC parameter values)
  - Filter cutoff, resonance
  - Envelope attack, release  
  - Master volume
- **Wavetables**: BRAM (1024 × 16-bit sawtooth)
- **Coefficient tables**: BRAM
  - Envelope timing coefficients (256 entries × 4 stages)
  - Filter coefficient tables
- **MIDI note-to-frequency**: BRAM lookup table (128 entries)

### Logic Resources
- **Estimated LUT4 usage**: 3-4K (within 8K limit)
- **TDM sequencer**: ~200 LUTs
- **Voice management**: ~500 LUTs per voice type
- **MIDI processing**: ~400 LUTs (note on/off + CC handling)
- **Parameter management**: ~100 LUTs

## Implementation Approach

### Lookup Table Strategy
- **All calculations via tables**: No runtime arithmetic
- **Python generation scripts**: Pre-compute all coefficients
- **Trade memory for speed**: Acceptable given BRAM availability

### TDM Implementation
- **Fixed slot duration**: 111 clocks regardless of actual processing time
- **Pipeline friendly**: Predictable timing for each processing stage
- **Parameter access**: Each voice reads global parameters during its slot
- **Expandable**: Easy to add slots for additional features

### Parameter Control Flow
- **MIDI CC reception**: Asynchronous to audio processing
- **Parameter update**: CC value → Global parameter store (outside TDM)
- **Parameter application**: Voice reads current global values during TDM slot
- **Coefficient lookup**: Parameter value → Coefficient table → DSP processing

### Voice Management
- **Note allocation**: Round-robin with age tracking
- **Voice stealing**: Immediate takeover of oldest voice
- **MIDI handling**: Note on/off with velocity

### Real-time Parameter Control
- **MIDI CC support**: Essential synthesizer parameters
- **Parameter scope**: Global (shared across all voices)
- **Core parameters**:
  - Filter cutoff (CC74) - 8-bit resolution
  - Filter resonance (CC71) - 8-bit resolution  
  - Envelope attack (CC73) - 8-bit resolution
  - Envelope release (CC72) - 8-bit resolution
  - Volume (CC7) - 8-bit resolution
- **Update mechanism**: MIDI CC → Parameter store → TDM voice reads
- **Storage**: Small SRAM block for current parameter values

## Design Trade-offs

### Accepted Limitations
- **Aliasing**: Single wavetable, no band-limiting initially
- **Linear envelopes**: Musical but not exponential
- **Shared filter**: One filter topology for all voices
- **No modulation**: LFO/modulation matrix excluded for simplicity

### Future Enhancement Paths
- **Dual oscillators**: Second oscillator with detuning (Minimoog-style)
- **LFO modulation**: Low-frequency oscillator for vibrato/tremolo
- **Multiple wavetables**: Octave-specific tables for anti-aliasing
- **Exponential envelopes**: Curved segments via lookup
- **Per-voice parameters**: Individual voice parameter control
- **Effects**: Chorus, reverb in additional TDM slots
- **Filter types**: High-pass, band-pass variants

### Evolution Roadmap: Polyphonic Minimoog
The architecture supports natural evolution toward a polyphonic Minimoog-style synthesizer:
- **Phase 1**: Current single-oscillator implementation
- **Phase 2**: Add second oscillator with pitch offset
- **Phase 3**: Add global LFO for modulation
- **Phase 4**: Expand modulation routing (filter mod, osc mod)
- **Phase 5**: Additional waveforms (triangle, square)

## Validation Approach
- **Cycle-accurate simulation**: Verify TDM timing
- **Resource utilization**: Confirm DSP/memory usage
- **Audio quality**: Basic functionality over perfection
- **MIDI compliance**: Standard note on/off, velocity response

## Success Criteria
1. **8-voice polyphony** with voice stealing
2. **Stable TDM operation** at 48kHz
3. **MIDI responsiveness** (note on/off, velocity, CC control)
4. **Real-time parameter control** (filter, envelope, volume)
5. **Recognizable sawtooth synthesis** with filtering
6. **Resource efficiency** within FPGA constraints

---

*This specification prioritizes learning FPGA audio synthesis techniques over feature completeness. The simple architecture provides a solid foundation for exploring more sophisticated approaches in future implementations.*