//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module test_tone (
    input var logic i_clk,
    input var logic[15:0] i_fcw,
    input var logic i_sample_req,
    output logic [31:0] o_sample

);

  logic [15:0] acc;
  logic [31:0] sample;

  always_ff @(posedge i_clk) begin
    if (i_sample_req) begin
      acc <= acc + i_fcw;
      sample <= {acc, acc};
    end
  end

  assign o_sample = sample;

endmodule

`default_nettype wire

