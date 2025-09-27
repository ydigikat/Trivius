//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
// This is more or less a direct migration of my C based MIDI parser so
// probably a little unwieldy.
//-----------------------------------------------------------------------------
`default_nettype none
`include "types.svh"

module midi_parser (
    input var logic       i_clk_aud,
    input var logic       i_aud_rst_n,

    // MIDI RX data in
    input var logic       i_byte_valid,
    input var midi_byte_t i_midi_byte,

    // Channel (0x17 = OMNI)
    input var logic[4:0]  i_channel,

    // Message output (1,2 or 3 bytes)
    output logic          o_msg_valid,
    output logic[1:0]     o_msg_len,
    output midi_byte_t    o_msg[3],

    // Realtime message output (1 byte)
    output logic          o_rt_msg_valid,
    output midi_byte_t    o_rt_msg
);



  //-----------------------------------------------------------------------------
  // Byte classification
  //-----------------------------------------------------------------------------
  function automatic is_status_byte(input midi_byte_t byte_in);
    return (byte_in[7] == 1'b1);
  endfunction

  function automatic is_real_time(input midi_byte_t byte_in);
    return (byte_in[7:3] == 5'b11111);
  endfunction

  function automatic is_single_byte_msg(input midi_byte_t byte_in);
    return (byte_in[7:2] == 6'b111101);
  endfunction

  function automatic is_our_channel(input midi_byte_t byte_in, input logic [4:0] channel);
    if (channel != MidiOmni && (byte_in & 4'hF) != (channel[3:0] - 1)) return 1'b0;
  endfunction

  //-----------------------------------------------------------------------------
  // State Registers
  //-----------------------------------------------------------------------------
  midi_byte_t running_status, running_status_n;
  logic third_byte_expected, third_byte_expected_n;
  logic sysex_active, sysex_active_n;
  midi_byte_t msg_data[3], msg_data_n[3];
  logic [1:0] msg_len, msg_len_n;
  logic msg_valid, msg_valid_n;
  logic rt_msg_valid, rt_msg_valid_n;
  midi_byte_t rt_msg_data, rt_msg_data_n;

  always_ff @(posedge i_clk_aud) begin
    if (i_aud_rst_n) begin
      running_status <= MidiStatusInvalid;
      third_byte_expected <= 0;
      sysex_active <= 0;
      msg_data <= '{3{midi_byte_t'(0)}};
      msg_len <= 0;
      msg_valid <= 0;
      rt_msg_valid <= 0;
      rt_msg_data <= 0;
    end else begin
      running_status <= running_status_n;
      third_byte_expected <= third_byte_expected_n;
      sysex_active <= sysex_active_n;
      msg_data <= msg_data_n;
      msg_len <= msg_len_n;
      msg_valid <= msg_valid_n;
      rt_msg_valid <= rt_msg_valid_n;
      rt_msg_data <= rt_msg_data_n;
    end
  end

  //-----------------------------------------------------------------------------
  // Next state logic
  //-----------------------------------------------------------------------------
  always_comb begin
    running_status_n = running_status;
    third_byte_expected_n = third_byte_expected;
    sysex_active_n = sysex_active;
    msg_data_n = msg_data;
    msg_len_n = msg_len;
    msg_valid_n = 1'b0;
    rt_msg_valid_n = 1'b0;
    rt_msg_data_n = rt_msg_data;

    if (i_byte_valid) begin
      // Deal with OOB RT message first, they don't impact parser state
      if (is_status_byte(i_midi_byte) && is_real_time(i_midi_byte)) begin
        rt_msg_valid_n = 1'b1;
        rt_msg_data_n  = i_midi_byte;
      end else begin
        // Drain sysex messages - we don't use these but need to go past them.
        if (sysex_active) begin
          if (i_midi_byte == MidiStatusSysExEnd) begin
            sysex_active_n = 1'b0;
          end
          // Don't process any incoming MIDI bytes during sysex.
        end else begin
          // Process the status byte
          if (is_status_byte(i_midi_byte)) begin
            running_status_n = i_midi_byte;
            third_byte_expected_n = 1'b0;

            if (i_midi_byte == MidiStatusSysExStart) begin
              sysex_active_n = 1'b1;
            end else if (is_single_byte_msg(i_midi_byte)) begin
              // Single byte message
              msg_data_n[0] = i_midi_byte;
              msg_len_n = 2'd1;
              msg_valid_n = 1'b1;
            end else begin
              // Multi byte message handling
              if (!is_our_channel(i_midi_byte, i_channel)) begin
                // Do nothing, not for us
              end else if (third_byte_expected) begin
                // This is the 3rd byte of a 3-byte message - store it.
                third_byte_expected_n = 0;
                msg_data_n[2] = i_midi_byte;
                msg_len_n = 2'b11;
                msg_valid_n = 1'b1;
              end else if (running_status != MidiStatusInvalid) begin
                // First data byte of message - message type
                case (running_status & 8'hF0)
                  MidiStatusNoteOn,
                  MidiStatusNoteOff,
                  MidiStatusControlChange,
                  MidiStatusPitchBend,
                  MidiStatusPolyPressure: begin
                    // These are 3 byte messages
                    third_byte_expected_n = 1'b1;
                    msg_data_n[0] = running_status;
                    msg_data_n[1] = i_midi_byte;
                    // We got 2 bytes so far.
                    msg_len_n = 2'b10;
                  end

                  MidiStatusProgramChange, MidiStatusChannelPressure: begin
                    // 2 byte message - we're done (valid)
                    third_byte_expected_n = 1'b0;
                    msg_data_n[0] = running_status;
                    msg_data_n[1] = i_midi_byte;
                    msg_len_n = 2'b10;
                    msg_valid_n = 1'b1;
                  end

                  default: begin
                    // System messages
                    case (running_status)
                      MidiStatusSongPos: begin
                        third_byte_expected_n = 1'b1;
                        msg_data_n[0] = running_status;
                        msg_data_n[1] = i_midi_byte;
                        msg_len_n = 2'b10;
                        running_status_n = MidiStatusInvalid;
                      end
                      MidiStatusSongSelect, MidiStatusTimingClock: begin
                        msg_data_n[0] = running_status;
                        msg_data_n[1] = i_midi_byte;
                        msg_len_n = 2'b10;  // 2 bytes
                        msg_valid_n = 1'b1;
                        running_status_n = MidiStatusInvalid;
                      end
                      default: begin
                        running_status_n = MidiStatusInvalid;
                      end
                    endcase
                  end
                endcase
              end
            end
          end
        end
      end
    end
  end

  //-----------------------------------------------------------------------------
  // Output Logic
  //-----------------------------------------------------------------------------
  assign o_msg_valid = msg_valid;
  assign o_msg_len = msg_len;
  assign o_msg[0] = msg_data[0];
  assign o_msg[1] = msg_data[1];
  assign o_msg[2] = msg_data[2];
  assign o_rt_msg_valid = rt_msg_valid;
  assign o_rt_msg = rt_msg_data;

endmodule

`default_nettype wire
