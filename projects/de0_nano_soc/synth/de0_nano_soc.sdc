
create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]

create_clock -period "50.0 MHz" [get_ports FPGA_CLK2_50]

create_clock -period "50.0 MHz" [get_ports FPGA_CLK3_50]

derive_pll_clocks

derive_clock_uncertainty
