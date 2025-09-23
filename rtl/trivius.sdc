# SDC kept trivial, the fitter created auto-clocks seem OK, both system and
# audio clocks are derived from same master (27MHz) so treated as synchronous.

# 27MHz xtal input
create_clock -name clk_27 -period 37.037 [get_ports {i_clk}]

# TODO : BCLK is directly driving FFs so should be created as a clock.
#create_clock -name bclk -period 666.667 [get_nets {it/bclk_r}]

