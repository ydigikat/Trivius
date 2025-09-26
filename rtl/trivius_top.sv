//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module trivius_top (
    input var logic     i_clk,
    input var logic     i_midi_rx,
    output logic        o_aud_bclk,
    output logic        o_aud_lrclk,
    output logic        o_aud_sda,
    output logic[15:0]   o_dio
);
  // 16x31250==500000, 48MHz/500KHz = 96 (0..95)
  localparam unsigned MidiDiv = 95;

  //------------------------------------------------------------------------------
  // Clock and reset generation
  //------------------------------------------------------------------------------
  logic clk, clk_aud;
  logic rst_n, aud_rst_n;

  clock_gen cg (
      .i_clk      (i_clk),
      .o_clk      (clk),
      .o_rst_n    (rst_n),
      .o_clk_aud  (clk_aud),
      .o_aud_rst_n(aud_rst_n)
  );

  //------------------------------------------------------------------------------
  // Audio processor
  //------------------------------------------------------------------------------
  logic [31:0] sample;

  test_tone tt (
      .i_clk       (clk),
      .i_fcw       (16'd615),
      .i_sample_req(sample_req),
      .o_sample    (sample)
  );


  //------------------------------------------------------------------------------
  // I2S peripheral
  //------------------------------------------------------------------------------
  logic aud_lrclk, aud_sda, sample_req;

  i2s_tx it (
      .i_clk(clk),
      .i_rst_n(rst_n),
      .o_req(sample_req),
      .i_sample(sample),

      .i_clk_aud  (clk_aud),
      .i_aud_rst_n(aud_rst_n),
      .o_aud_lrclk(aud_lrclk),
      .o_aud_sda  (aud_sda)
  );

  assign o_aud_bclk  = clk_aud;
  assign o_aud_sda   = aud_sda;
  assign o_aud_lrclk = aud_lrclk;

  //------------------------------------------------------------------------------
  // MIDI processing
  //------------------------------------------------------------------------------
  logic midi_ready;
  logic [7:0] midi_byte;

  midi_rx rx (
      .i_clk_aud    (clk_aud),
      .i_aud_rst_n  (aud_rst_n),
      .i_rx         (i_midi_rx),
      .o_ready      (midi_ready),
      .o_data_byte  (midi_byte)
  );


  //------------------------------------------------------------------------------
  // DEBUG probes
  //------------------------------------------------------------------------------
  assign o_dio[0] = i_midi_rx;  // MIDI serial in
  assign o_dio[1] = (midi_byte == 'h90);  // Note on
  assign o_dio[2] = (midi_byte == 'h80);  // Note off
  assign o_dio[3] = midi_ready;
  assign o_dio[15:8] = midi_byte;


endmodule
