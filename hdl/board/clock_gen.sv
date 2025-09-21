//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module clock_gen(                               // Clock generator (PLL) 
    input var logic i_clk,                      // Xtal 27MHz
    output logic o_sys_clk,o_aud_clk,           // Clocks 48MHz, 6MHz
    output logic o_sys_reset_n, o_aud_reset_n   // Sync resets
);


logic clk48, clk6;
logic pll_locked;                               // Indicates PLL stable

rPLL #(                                         // Gowin PLL primitive
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
    .DYN_SDIV_SEL(8),
    .CLKOUTD_SRC("CLKOUT"),
    .CLKOUTD3_SRC("CLKOUT"),
    .DEVICE("GW1NR-9C")
) u_pll (
    .CLKIN(i_clk),
    .CLKOUT(clk48),    
    .CLKOUTD(clk6),    
    .LOCK(pll_locked),

    // Unused
    .CLKOUTP(),    
    .CLKOUTD3(),
    .RESET(1'b0),
    .RESET_P(1'b0),    
    .CLKFB(1'b0),
    .FBDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
    .IDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
    .ODSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
    .PSDA({1'b0,1'b0,1'b0,1'b0}),
    .DUTYDA({1'b0,1'b0,1'b0,1'b0}),
    .FDLY({1'b0,1'b0,1'b0,1'b0})    
);


logic [3:0] reset48_r = 4'b0000;            // Sync reset_n 48Mhz clock domain
always @(posedge clk48) begin
    if (!pll_locked)
        reset48_r <= 4'b0000;               // Hold reset low while PLL is not stable
    else
        reset48_r <= {reset48_r[2:0], 1'b1};// Wait 4 cycles after lock
end


logic [3:0] reset6_r = 4'b0000;             // Sync reset_n 6MHz clock domain
always @(posedge clk6) begin
    if (!pll_locked)
        reset6_r <= 4'b0000;                // Hold reset low while PLL is not stable
    else
        reset6_r <= {reset6_r[2:0], 1'b1};  // Wait 4 cycles after lock
end


assign o_sys_clk = clk48;                   // Outputs
assign o_aud_clk = clk6;
assign o_sys_reset_n = reset48_r[3];
assign o_aud_reset_n = reset6_r[3];


endmodule