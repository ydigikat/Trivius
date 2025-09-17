//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module trivius_top(
    input var logic i_clk,                          // Hardware clock - 27MHz
    input var logic i_rx,                           // MIDI Rx serial line
    output logic o_bclk, o_lrclk, o_sda,            // I2S TX clocks and data
    output logic[7:0] o_dio                         // Logic probe pins
);

// Constants
localparam MIDI_DIV = 95;                           // MIDI tick divider, 16x31250==500000, 48MHz/500KHz = 96

// Internal signals
logic sys_clk,aud_clk;                              // Outputs from PLL 
logic sys_reset_n, aud_reset_n;                     // Synchronous resets for PLL clocks
logic bclk, ws, sda, req;                           // Internal wires for I2S
logic midi_data_ready;                              // Signal incoming RX data


// Registers
logic [15:0] left;                                  // Left output sample
logic [15:0] right;                                 // Right output sample
logic [7:0] midi_data;                              // Incoming MIDI byte


clock_gen cg                                        // == Clock generator ==
(
    .i_clk(i_clk),                                  
    .o_sys_clk(sys_clk),                            // 48MHz clock
    .o_sys_reset_n(sys_reset_n),                    // Sync reset
    .o_aud_clk(aud_clk),                            // 6Mhz clock
    .o_aud_reset_n(aud_reset_n)                     // Sync reset
);

i2s_tx it                                           // == I2S TX master (Philips standard) ==
(
    .i_aud_clk(aud_clk),                            // Audio clock (6MHz)
    .i_aud_reset_n(aud_reset_n),                    // Sync reset
    .i_left(left),                                  // Left sample in 
    .i_right(right),                                // Right sample in 
    .o_bclk(bclk),                                  // Bclk out (clock enable, counter generated)
    .o_ws(ws),                                      // Word select out
    .o_sda(sda),                                    // Serial data out
    .o_req(req)                                     // Sample request signal
);

test_tone tt                                        // == Trivial saw tooth generator ==
(
.i_clk(aud_clk),                                    // Audio clock in (6MHz)
.i_fcw(16'd615),                                    // Frequency control word
.i_sample_req(req),                                 // Sample request signal
.o_sample({left,right})                             // Generated sample (mono)
);

uart_rx #(.DIV(MIDI_DIV)) midi_rx                   // == MIDI RX UART ==
(               
  .i_clk(i_clk),                                    // System clock (48Mhz)
  .i_reset_n(sys_reset_n),                          // Sync reset
  .i_rx(i_rx),                                      // Serial RX line
  .o_ready(midi_data_ready),                        // Signals MIDI data is ready
  .o_data(midi_data)                                // MIDI data byte
);
                                                    // == Outputs ==
assign o_bclk = bclk;                               // Bitclock out
assign o_sda = sda;                                 // Serial data out
assign o_lrclk = ws;                                // Word select out

assign o_dio = midi_data;                           // Debug output MIDI byte

endmodule