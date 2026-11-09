# 100 MHz target clock for timing analysis (both cores use the same constraint)
create_clock -period 10.000 -name clk [get_ports clk]
