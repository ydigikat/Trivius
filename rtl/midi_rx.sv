//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`default_nettype none

module midi_rx (
    input var logic     i_clk_aud,
    input var logic     i_aud_rst_n,
    input var logic     i_rx,
    output logic        o_ready,
    output logic[7:0]   o_data_byte
);

  // 48000000/(31250 * 16) -1 = 95
  // localparam unsigned MidiTickDiv = 95;

  // 1500000/(31250 * 16) -1 = 2;
  localparam unsigned MidiTickDiv = 2;

  //---------------------------------------------------------------------------
  // States
  //---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state_t;

  //---------------------------------------------------------------------------
  // State registers
  //---------------------------------------------------------------------------
  state_t state, state_n;
  logic [2:0] tick_count, tick_count_n;
  logic [3:0] sample_count, sample_count_n;
  logic [2:0] bit_count, bit_count_n;
  logic [7:0] data_byte, data_byte_n;

  always_ff @(posedge i_clk_aud) begin
    if (!i_aud_rst_n) begin
      state <= IDLE;
      sample_count <= 0;
      bit_count <= 0;
      data_byte <= 0;
      tick_count <= 0;
    end else begin
      state <= state_n;
      sample_count <= sample_count_n;
      bit_count <= bit_count_n;
      data_byte <= data_byte_n;
      tick_count <= tick_count_n;
    end
  end

  //---------------------------------------------------------------------------
  // Next state logic
  //---------------------------------------------------------------------------

  logic tick;

  always_comb begin
    state_n = state;
    o_ready = 0;
    sample_count_n = sample_count;
    bit_count_n = bit_count;
    data_byte_n = data_byte;

    // Sampling tick generator
    tick_count_n = (tick_count == MidiTickDiv) ? 0 : tick_count + 1'b1;
    tick = (tick_count == 1);

    unique case (state)
      IDLE:
      if (~i_rx) begin
        state_n = START;
        sample_count_n = 0;
      end
      START:
      if (tick) begin
        if (sample_count == 7) begin
          state_n = DATA;
          sample_count_n = 0;
          bit_count_n = 0;
        end else begin
          sample_count_n = sample_count + 1'b1;
        end
      end
      DATA:
      if (tick) begin
        if (sample_count == 15) begin
          sample_count_n = 0;
          data_byte_n = {i_rx, data_byte[7:1]};
          if (bit_count == 7) begin
            state_n = STOP;
          end else begin
            bit_count_n = bit_count + 1'b1;
          end
        end else begin
          sample_count_n = sample_count + 1'b1;
        end
      end
      STOP:
      if (tick) begin
        if (sample_count == 15) begin
          state_n = IDLE;
          o_ready = 1'b1;
        end else begin
          sample_count_n = sample_count + 1'b1;
        end
      end
      default: state_n = state;

    endcase
  end

  //---------------------------------------------------------------------------
  // Output logic (supress active sense messages (0xFE))
  //---------------------------------------------------------------------------
  assign o_data_byte = data_byte == 'hFE ? 0 : data_byte;

endmodule

