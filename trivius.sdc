# 27MHz xtal input
create_clock -name clk_27 -period 37.037 [get_ports {i_clk}]

# PLL output 48MHz
#create_clock -name clk_48 -period 20.083 [get_ports {clk48}]
#create_clock -name clk_6  -period 166.666 [get_ports {clk6}]