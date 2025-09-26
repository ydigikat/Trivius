//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module i2s_tx (
    input var logic       i_clk,
    input var logic       i_rst_n,
    output logic          o_req,

    input var logic       i_clk_aud,
    input var logic       i_aud_rst_n,

    output logic          o_aud_lrclk,
    output logic          o_aud_sda,
    input var logic[31:0] i_sample
);

  logic req, req_n;
  logic lrclk, lrclk_n;
  logic sda, sda_n;
  logic [4:0] bit_cnt, bit_cnt_n;
  logic [31:0] sample, sample_n;

  //------------------------------------------------------------------------------
  // State registers
  //------------------------------------------------------------------------------
  always_ff @(negedge i_clk_aud) begin
    if (~i_aud_rst_n) begin
      bit_cnt <= 'd1;
      req <= 0;
      lrclk <= 0;
      sample <= 0;
      sda <= 0;
    end else begin
      bit_cnt <= bit_cnt_n;
      req <= req_n;
      lrclk <= lrclk_n;
      sample <= sample_n;
      sda <= sda_n;
    end
  end

  //------------------------------------------------------------------------------
  // Next state logic
  //------------------------------------------------------------------------------
  always_comb begin
    sample_n = sample;
    lrclk_n  = lrclk;
    req_n = req;

    // Bit count from 1-16
    if (bit_cnt == 16) bit_cnt_n = 5'd1;
    else bit_cnt_n = bit_cnt + 5'd1;

    // LRCLK and next sample request handling
    if (bit_cnt == 15) begin
      req_n   = (lrclk == 1);
      lrclk_n = ~lrclk;

      if (lrclk) begin
        lrclk_n  = ~lrclk;
        sample_n = i_sample;
      end
    end

    // Serialise sample data out
    sda_n = (~lrclk) ? sample[31-bit_cnt] : sample[15-bit_cnt];
  end

  //------------------------------------------------------------------------------
  // Generate a single cycle pulse in system clock domain
  //------------------------------------------------------------------------------
  logic req_q1, req_q2, req_q3;
  logic req_pulse;

  always_ff @(posedge i_clk) begin
    if (~i_rst_n) begin
      req_q1 <= 1'b0;
      req_q2 <= 1'b0;
      req_q3 <= 1'b0;
    end else begin
      req_q1 <= req;
      req_q2 <= req_q1;
      req_q3 <= req_q2;
    end
  end
  assign req_pulse = req_q2 & ~req_q3;


  //------------------------------------------------------------------------------
  // Output logic
  //------------------------------------------------------------------------------
  assign o_aud_lrclk = lrclk;
  assign o_aud_sda = sda;
  assign o_req = req_pulse;


endmodule
