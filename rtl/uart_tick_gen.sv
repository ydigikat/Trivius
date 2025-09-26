//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`default_nettype none

module uart_tick_gen (
    input var logic       i_clk,
    input var logic       i_rst_n,
    input var logic[10:0] i_div,
    output logic          o_tick
);

  //---------------------------------------------------------------------------
  // State registers
  //---------------------------------------------------------------------------
  logic [10:0] tick_cnt, tick_cnt_n;

  always_ff @(posedge i_clk) begin
    if (!i_rst_n) begin
      tick_cnt <= 11'b0;
    end else begin
      tick_cnt <= tick_cnt_n;
    end
  end

  //---------------------------------------------------------------------------
  // Next state logic
  //---------------------------------------------------------------------------
  assign tick_cnt_n = (tick_cnt == i_div) ? 0 : 11'(tick_cnt + 11'd1);


  //---------------------------------------------------------------------------
  // Output logic
  //---------------------------------------------------------------------------
  assign o_tick = (tick_cnt == 1);

endmodule
