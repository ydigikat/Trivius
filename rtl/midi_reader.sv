//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`default_nettype none
`include "types.svh"

module midi_reader (
    input var logic i_clk_aud,
    input var logic i_aud_rst_n,

    // MIDI serial line in
    input var logic    i_midi_rx,

    // Channel (17 = OMNI)
    input  var logic [4:0]  i_channel,

    // Validated/parsed message output
    output logic        o_msg_valid,
    output logic [1:0]  o_msg_len,
    output logic [7:0]  o_msg [3],

    // Buffer state
    output logic        o_buffer_empty,
    output logic        o_buffer_full
);

  // MIDI RX signals
  logic       midi_valid;
  midi_byte_t midi_byte;

  // MIDI receiver
  midi_rx rx (
      .i_clk_aud  (i_clk_aud),
      .i_aud_rst_n(i_aud_rst_n),
      .i_rx       (i_midi_rx),
      .o_valid    (midi_valid),
      .o_midi_byte(midi_byte)
  );

  // Buffer interface
  midi_byte_t buffer_read_data;
  logic       buffer_read_en;
  logic       buffer_data_valid;

  // MIDI buffer
  ring_buffer rb (
      .i_clk(i_clk_aud),
      .i_rst_n(i_aud_rst_n),
      .i_write_en(midi_valid),
      .i_write_data(midi_byte),
      .i_read_en(buffer_read_en),
      .o_read_data(buffer_read_data),
      .o_empty(o_buffer_empty),
      .o_full(o_buffer_full)
  );

  // Buffer read control
  assign buffer_read_en = !o_buffer_empty;

  // Delay read enable to create valid signal
  always_ff @(posedge i_clk_aud) begin
    if (!i_aud_rst_n) begin
      buffer_data_valid <= 1'b0;
    end else begin
      buffer_data_valid <= buffer_read_en;
    end
  end

  // MIDI parser
    midi_parser mp (
        .i_clk_aud(i_clk_aud),
        .i_aud_rst_n(i_aud_rst_n),
        .i_byte_valid(buffer_data_valid),
        .i_midi_byte(buffer_read_data),
        .i_channel(i_channel),
        .o_msg_valid(o_msg_valid),
        .o_msg_len(o_msg_len),
        .o_msg(o_msg),
        // RT messages not used.
        .o_rt_msg_valid(),
        .o_rt_msg()
    );

endmodule

`default_nettype wire
