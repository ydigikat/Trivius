# MiniFPGA Synthesizer Development Plan

## Overview
Phased development approach for implementing the MiniFPGA synthesizer on the GW1NR-9 FPGA. Each phase builds incrementally and provides testable functionality.

---

## Phase 1: Foundation & Basic Oscillator
**Goal**: Establish TDM infrastructure and basic single-voice sawtooth generation

### Deliverables
- TDM sequencer with 9 slots (8 voice + 1 mixer)
- Single voice sawtooth oscillator with phase accumulator
- Basic wavetable lookup with linear interpolation
- MIDI note-to-frequency conversion
- Single voice audio output (no polyphony yet)

### Key Learning
- FPGA DSP block usage for phase accumulators
- BRAM configuration for wavetables
- TDM timing and slot management
- Basic audio pipeline architecture

### Implementation Tasks
1. **TDM Sequencer**: 9-slot time-division multiplexer
2. **Wavetable Generation**: Python script for 1024-point sawtooth
3. **Phase Accumulator**: 24-bit accumulator using DSP blocks
4. **Table Lookup**: BRAM interface with interpolation
5. **Audio Output**: Basic DAC interface integration

### Test Criteria
- Stable 48kHz audio output
- Correct pitch tracking across MIDI range
- Clean sawtooth waveform (scope verification)
- TDM timing meets slot duration requirements

### Estimated Effort
**2-3 weeks** (assuming FPGA development environment setup)

---

## Phase 2: Polyphony & Voice Management
**Goal**: Implement 8-voice polyphony with voice stealing

### Deliverables
- 8 independent voice slots in TDM
- Voice allocation and stealing algorithm
- MIDI note tracking per voice
- Basic voice mixing in dedicated slot

### Key Learning
- Multi-voice state management in FPGA
- Voice stealing algorithms
- SRAM usage for voice parameters
- Audio mixing and scaling

### Implementation Tasks
1. **Voice State Management**: SRAM-based voice parameter storage
2. **Voice Allocation**: Round-robin with age tracking
3. **Voice Stealing**: Oldest voice priority algorithm
4. **TDM Voice Processing**: Extend TDM to handle 8 voices
5. **Mixer Slot**: Sum 8 voice outputs with scaling

### Test Criteria
- 8-note polyphonic chords play correctly
- Voice stealing works smoothly (no glitches)
- Even voice allocation across all 8 voices
- No audio dropouts or timing issues

### Estimated Effort
**2-3 weeks**

---

## Phase 3: Envelope & Basic Filtering
**Goal**: Add ADSR envelope and simple lowpass filter

### Deliverables
- 4-state ADSR envelope generator
- Linear segment envelope curves
- Basic 2-pole lowpass filter (fixed parameters)
- Envelope coefficient lookup tables

### Key Learning
- State machine implementation in FPGA
- Filter topologies for FPGA implementation
- Coefficient table generation and usage
- Per-voice state management for envelopes/filters

### Implementation Tasks
1. **Envelope Tables**: Python scripts for linear ADSR coefficients
2. **Envelope State Machine**: 4-state ADSR with transitions
3. **Filter Implementation**: State variable 2-pole lowpass
4. **Voice Integration**: Add envelope and filter to voice processing
5. **Filter State Management**: Per-voice filter state in SRAM

### Test Criteria
- Clean envelope attack/decay/sustain/release
- Filter cutoff affects timbre appropriately
- No zipper noise or discontinuities
- Envelope properly resets on new notes

### Estimated Effort
**3-4 weeks** (filter implementation complexity)

---

## Phase 4: MIDI Control & Parameter Management
**Goal**: Real-time parameter control via MIDI CC messages

### Deliverables
- MIDI CC parsing and routing
- Global parameter storage system
- Real-time filter cutoff/resonance control
- Real-time envelope attack/release control
- Master volume control

### Key Learning
- MIDI protocol implementation
- Real-time parameter update mechanisms
- Parameter to coefficient mapping
- Smooth parameter transitions

### Implementation Tasks
1. **MIDI CC Handler**: Parse and route CC74, CC71, CC73, CC72, CC7
2. **Parameter Store**: Global parameter storage in SRAM
3. **Coefficient Mapping**: Parameter value to coefficient lookup
4. **Parameter Application**: TDM voices read current global parameters
5. **Smooth Updates**: Avoid parameter change artifacts

### Test Criteria
- All 5 core parameters respond to MIDI CC
- Parameter changes are smooth (no clicks/pops)
- Real-time performance is maintained
- Parameter ranges feel musical and useful

### Estimated Effort
**2-3 weeks**

---

## Phase 5: Optimization & Polish
**Goal**: Performance optimization and audio quality improvements

### Deliverables
- Resource utilization optimization
- Audio quality improvements
- Parameter range refinement
- Documentation and testing

### Key Learning
- FPGA optimization techniques
- Audio quality assessment
- Resource utilization analysis
- Design validation methods

### Implementation Tasks
1. **Resource Analysis**: Optimize DSP and LUT usage
2. **Timing Optimization**: Ensure stable TDM operation
3. **Audio Quality**: Minimize noise and artifacts
4. **Parameter Tuning**: Refine ranges for musical usefulness
5. **Comprehensive Testing**: Edge cases and stress testing

### Test Criteria
- Resource usage within FPGA constraints
- No timing violations or instability
- Musical parameter ranges
- Comprehensive test coverage

### Estimated Effort
**2 weeks**

---

## Future Phases (Post-Core Implementation)

### Phase 6: Dual Oscillator (Minimoog Evolution)
- Add second oscillator per voice
- Oscillator detuning and mixing
- Expanded wavetable support

### Phase 7: LFO & Modulation
- Global LFO generation
- Filter cutoff modulation
- Oscillator pitch modulation

### Phase 8: Enhanced Audio Quality
- Anti-aliasing improvements
- Exponential envelope curves
- Additional filter types

---

## Risk Mitigation

### Technical Risks
- **TDM timing violations**: Use conservative clock margins, thorough simulation
- **Resource constraints**: Monitor usage continuously, optimize early
- **Audio artifacts**: Test audio quality at each phase

### Development Risks
- **FPGA learning curve**: Start with simple implementations, iterate
- **Debug complexity**: Implement comprehensive test points and logging
- **Integration issues**: Test each phase thoroughly before proceeding

---

## Success Metrics

### Phase Completion Criteria
Each phase must meet all test criteria before proceeding to the next phase.

### Overall Project Success
- Functional 8-voice polyphonic synthesizer
- Real-time MIDI control responsiveness
- Professional audio quality output
- Stable operation within FPGA resource constraints
- Clear path for future enhancements

### Learning Objectives
- Practical FPGA audio synthesis experience
- TDM architecture implementation
- Real-time audio processing constraints
- Foundation for advanced synthesis projects

---

**Total Estimated Development Time: 11-15 weeks**

*This timeline assumes part-time development with FPGA learning curve. Experienced FPGA developers could reduce timeline by 30-40%.*