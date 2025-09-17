//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module uart_tick_gen(               // Generates the oversampling tick for UART
  input var logic i_clk,            // System clock (48MHz)
  input var logic i_reset_n,        // Sync reset signal
  input var logic[10:0] i_div,      // Clock divider
  output logic o_tick               // Oversampling tick (should be 16 x baudrate)
);

logic [10:0] r_ps, r_ns;            // present/next state registers

// Registers
always_ff @(posedge i_clk) begin
  if(!i_reset_n) begin
    r_ps <= 0;
  end else begin
    r_ps <= r_ns; 
  end
end

// Next state logic
assign r_ns = (r_ps == i_div) ? 0 : 11'(r_ps + 1);


// Output
assign o_tick = (r_ps == 1);

endmodule