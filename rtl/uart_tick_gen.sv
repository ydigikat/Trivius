//-------------------------------------------------------------------------------------------
// Jason Wilden 2025
//-------------------------------------------------------------------------------------------
`default_nettype none

module uart_tick_gen(                             // Generates the oversampling tick for UART
  input var logic i_clk,                          // System clock (48MHz)
  input var logic i_reset_n,                      // Sync reset signal
  input var logic[10:0] i_div,                    // Clock divider
  output logic o_tick                             // Oversampling tick (should be 16 x baudrate)
);

logic [10:0] r_ps, r_ns;                          // State registers


always_ff @(posedge i_clk) begin                  // Drive state registers
  if(!i_reset_n) begin
    r_ps <= 0;                                    // Hold during reset
  end else begin
    r_ps <= r_ns;                                 
  end
end

assign r_ns = (r_ps == i_div) ?                   // Next state logic, increment counter or
  0 : 11'(r_ps + 1);                              // reset to 0 if at maximum.


// Output
assign o_tick = (r_ps == 1);                      // Output a tick each time counter cycles

endmodule