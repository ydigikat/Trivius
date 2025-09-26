//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module clock_gen (
    input var logic i_clk,
    output logic o_clk,
    output logic o_rst_n,
    output logic o_clk_aud,
    output logic o_aud_rst_n
);
  rPLL #(
      .FCLKIN("27"),
      .DYN_IDIV_SEL("false"),
      .IDIV_SEL(8),
      .DYN_FBDIV_SEL("false"),
      .FBDIV_SEL(15),
      .DYN_ODIV_SEL("false"),
      .ODIV_SEL(16),
      .PSDA_SEL("0000"),
      .DYN_DA_EN("true"),
      .DUTYDA_SEL("1000"),
      .CLKOUT_FT_DIR(1),
      .CLKOUTP_FT_DIR(1),
      .CLKOUT_DLY_STEP(0),
      .CLKOUTP_DLY_STEP(0),
      .CLKFB_SEL("internal"),
      .CLKOUT_BYPASS("false"),
      .CLKOUTP_BYPASS("false"),
      .CLKOUTD_BYPASS("false"),
      .DYN_SDIV_SEL(32),
      .CLKOUTD_SRC("CLKOUT"),
      .CLKOUTD3_SRC("CLKOUT"),
      .DEVICE("GW1NR-9C")
  ) u_pll (
      .CLKIN(i_clk),
      .CLKOUT(clk),
      .CLKOUTD(clk_aud),
      .LOCK(pll_locked),

      // Unused
      .CLKOUTP(),
      .CLKOUTD3(),
      .RESET(1'b0),
      .RESET_P(1'b0),
      .CLKFB(1'b0),
      .FBDSEL({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
      .IDSEL({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
      .ODSEL({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
      .PSDA({1'b0, 1'b0, 1'b0, 1'b0}),
      .DUTYDA({1'b0, 1'b0, 1'b0, 1'b0}),
      .FDLY({1'b0, 1'b0, 1'b0, 1'b0})
  );

  logic clk, clk_aud, pll_locked;


  // State registers
  logic [3:0] rst, rst_n, aud_rst, aud_rst_n;

  always_ff @(posedge clk) rst <= rst_n;
  always_ff @(posedge clk_aud) aud_rst <= aud_rst_n;

  // Next state logic
  always_comb begin
    rst_n = 4'b0;
    aud_rst_n = 4'b0;

    if (pll_locked) begin
      rst_n = {rst[2:0], 1'b1};
      aud_rst_n = {aud_rst[2:0], 1'b1};
    end
  end

  // Output logic
  assign o_clk = clk;
  assign o_rst_n = rst[3];

  assign o_clk_aud = clk_aud;
  assign o_aud_rst_n = aud_rst[3];



endmodule
