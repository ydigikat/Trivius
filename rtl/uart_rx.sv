//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`default_nettype none

module uart_rx #(
    parameter unsigned DATA_WIDTH=8,
    parameter unsigned SB_TICK=16,
    parameter unsigned DIV=95
) (
    input var logic     i_clk,
    input var logic     i_rst_n,
    input var logic     i_rx,
    output logic        o_ready,
    output logic[7:0]   o_data_byte
);

  //---------------------------------------------------------------------------
  // Tick generator
  //---------------------------------------------------------------------------
  logic tick;

  uart_tick_gen tg (
      .i_clk(i_clk),
      .i_rst_n(i_rst_n),
      .i_div(11'(DIV)),
      .o_tick(tick)
  );

  //---------------------------------------------------------------------------
  // States
  //---------------------------------------------------------------------------
  typedef enum {
    IDLE,
    START,
    DATA,
    STOP
  } state_t;

  //---------------------------------------------------------------------------
  // State registers
  //---------------------------------------------------------------------------
  state_t state, state_n;
  logic ready, ready_n;
  logic [3:0] tick_count, tick_count_n;
  logic [2:0] bit_count, bit_count_n;
  logic [7:0] data_byte, data_byte_n;

  always_ff @(posedge i_clk) begin
    if (~i_rst_n) begin
      state <= IDLE;
      tick_count <= 4'b0;
      bit_count <= 3'b0;
      data_byte <= 8'b0;
      ready <= 1'b0;
    end else begin
      state <= state_n;
      tick_count <= tick_count_n;
      bit_count <= bit_count_n;
      data_byte <= data_byte_n;
      ready <= ready_n;
    end
  end

  //---------------------------------------------------------------------------
  // Next state logic
  //---------------------------------------------------------------------------
  always_comb begin
    state_n = state;
    ready_n = ready;
    tick_count_n = tick_count;
    bit_count_n = bit_count;
    data_byte_n = data_byte;

    unique case (state)
      IDLE:
      if (~i_rx) begin
        state_n = START;
        tick_count_n = 0;
      end
      START:
      if (tick) begin
        if (tick_count == 7) begin
          state_n = DATA;
          tick_count_n = 0;
          bit_count_n = 0;
        end else begin
          tick_count_n = 4'(tick_count + 4'd1);
        end
      end
      DATA:
      if (tick) begin
        if (tick_count == 15) begin
          tick_count_n = 0;
          data_byte_n  = 8'({i_rx, data_byte[7:1]});
          if (bit_count == 3'(DATA_WIDTH - 1)) begin
            state_n = STOP;
          end else begin
            bit_count_n = 3'(bit_count + 3'd1);
          end
        end else begin
          tick_count_n = 4'(tick_count + 3'd1);
        end
      end
      STOP:
      if (tick) begin
        if (tick_count == 4'(SB_TICK - 1)) begin
          state_n = IDLE;
          ready_n = 1'b1;
        end else begin
          tick_count_n = 4'(tick_count + 4'd1);
        end
      end
      default:
        state_n = state;
    endcase
  end

  //---------------------------------------------------------------------------
  // Output logic
  //---------------------------------------------------------------------------
  assign o_data_byte = data_byte;
  assign o_ready = ready;

endmodule

