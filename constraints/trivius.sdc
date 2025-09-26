
# 27MHz xtal input
create_clock -name clk_27 -period 37.037 [get_ports {i_clk}]

# Note: CLKOUT (48MHz) and CLKOUTD (1.5MHz) from the PLL are synchronous and
# automatically constrained by the Gowin tools.  No need to create a gnerated
# clock constraint for these.
