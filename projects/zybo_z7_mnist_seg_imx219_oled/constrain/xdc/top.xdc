


################################
# Timing
################################

# in_clk125
create_clock -period 8.000 -name in_clk125 -waveform {0.000 4.000} [get_ports in_clk125]

# 456MHz(912Mbps)
create_clock -period 2.1929 -name cam_clk_hs_p -waveform {0.000 1.09649} [get_ports cam_clk_hs_p]


# clk_fpga_0                        100MHz  10.000ns
# clk_fpga_1                        133MHz   7.500ns
# clk_out1_design_1_clk_wiz_0_0     100MHz  10.000ns
# clk_out2_design_1_clk_wiz_0_0     200MHz   5.000ns
# clk_out3_design_1_clk_wiz_0_0     250MHz   4.000ns
# clk_out4_design_1_clk_wiz_0_0     125MHz   8.000ns
# clk_out1_design_1_clk_wiz_1_0_1  62.5MHz  16.000ns
# clk_out2_design_1_clk_wiz_1_0_1 437.5MHz   2.285ns
# clk_out1_clk_wiz_vout              75MHz  13.333ns
# clk_out2_clk_wiz_vout             375MHz   2.666ns
# rxbyteclkhs                       114MHz   8.771ns

set_max_delay -datapath_only -from [get_clocks clk_fpga_0]                      -to [get_clocks clk_fpga_1]                       7.500
set_max_delay -datapath_only -from [get_clocks clk_fpga_0]                      -to [get_clocks clk_out1_clk_wiz_vout]           10.000
set_max_delay -datapath_only -from [get_clocks clk_fpga_0]                      -to [get_clocks clk_out1_design_1_clk_wiz_1_0_1] 10.000
set_max_delay -datapath_only -from [get_clocks clk_fpga_0]                      -to [get_clocks clk_out2_design_1_clk_wiz_0_0]    5.000

set_max_delay -datapath_only -from [get_clocks clk_fpga_1]                      -to [get_clocks clk_fpga_0]                       7.500
set_max_delay -datapath_only -from [get_clocks clk_fpga_1]                      -to [get_clocks clk_out1_clk_wiz_vout]            7.500
set_max_delay -datapath_only -from [get_clocks clk_fpga_1]                      -to [get_clocks clk_out2_design_1_clk_wiz_0_0]    5.000

set_max_delay -datapath_only -from [get_clocks clk_out1_clk_wiz_vout]           -to [get_clocks clk_fpga_0]                      10.000
set_max_delay -datapath_only -from [get_clocks clk_out1_clk_wiz_vout]           -to [get_clocks clk_fpga_1]                       7.500

set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0]   -to [get_clocks clk_out2_design_1_clk_wiz_0_0]    5.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0]   -to [get_clocks clk_out3_design_1_clk_wiz_0_0]    4.000

set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_1_0_1] -to [get_clocks clk_fpga_0]                      10.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_1_0_1] -to [get_clocks clk_out2_design_1_clk_wiz_0_0]    5.000

set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0]   -to [get_clocks clk_fpga_0]                       5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0]   -to [get_clocks clk_fpga_1]                       5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0]   -to [get_clocks clk_out1_design_1_clk_wiz_0_0]    5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0]   -to [get_clocks clk_out1_design_1_clk_wiz_1_0_1]  5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0]   -to [get_clocks clk_out3_design_1_clk_wiz_0_0]    4.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0]   -to [get_clocks rxbyteclkhs]                      5.000

set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0]   -to [get_clocks clk_out2_design_1_clk_wiz_0_0]    4.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0]   -to [get_clocks rxbyteclkhs]                      4.000

set_max_delay -datapath_only -from [get_clocks rxbyteclkhs]                     -to [get_clocks clk_out1_design_1_clk_wiz_0_0]    8.771
set_max_delay -datapath_only -from [get_clocks rxbyteclkhs]                     -to [get_clocks clk_out3_design_1_clk_wiz_0_0]    4.000



################################
# I/O
################################

# in_clk125
set_property PACKAGE_PIN K17 [get_ports in_clk125]
set_property IOSTANDARD LVCMOS33 [get_ports in_clk125]


# MIPI
set_property INTERNAL_VREF 0.6 [get_iobanks 35]

set_property PACKAGE_PIN H18 [get_ports cam_clk_hs_n]
set_property PACKAGE_PIN J18 [get_ports cam_clk_hs_p]
set_property PACKAGE_PIN M20 [get_ports {cam_data_hs_n[0]}]
set_property PACKAGE_PIN M19 [get_ports {cam_data_hs_p[0]}]
set_property PACKAGE_PIN L17 [get_ports {cam_data_hs_n[1]}]
set_property PACKAGE_PIN L16 [get_ports {cam_data_hs_p[1]}]
set_property PACKAGE_PIN H20 [get_ports cam_clk_lp_p]
set_property PACKAGE_PIN J19 [get_ports cam_clk_lp_n]
set_property PACKAGE_PIN L19 [get_ports {cam_data_lp_p[0]}]
set_property PACKAGE_PIN M18 [get_ports {cam_data_lp_n[0]}]
set_property PACKAGE_PIN J20 [get_ports {cam_data_lp_p[1]}]
set_property PACKAGE_PIN L20 [get_ports {cam_data_lp_n[1]}]
set_property PACKAGE_PIN G19 [get_ports cam_clk]
set_property PACKAGE_PIN G20 [get_ports cam_gpio]
set_property PACKAGE_PIN F20 [get_ports cam_scl]
set_property PACKAGE_PIN F19 [get_ports cam_sda]

set_property IOSTANDARD LVDS_25 [get_ports cam_clk_hs_p]
set_property IOSTANDARD LVDS_25 [get_ports cam_clk_hs_n]
set_property IOSTANDARD LVDS_25 [get_ports {cam_data_hs_p[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {cam_data_hs_n[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {cam_data_hs_p[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {cam_data_hs_n[1]}]
set_property IOSTANDARD HSUL_12 [get_ports cam_clk_lp_p]
set_property IOSTANDARD HSUL_12 [get_ports cam_clk_lp_n]
set_property IOSTANDARD HSUL_12 [get_ports {cam_data_lp_p[0]}]
set_property IOSTANDARD HSUL_12 [get_ports {cam_data_lp_n[0]}]
set_property IOSTANDARD HSUL_12 [get_ports {cam_data_lp_p[1]}]
set_property IOSTANDARD HSUL_12 [get_ports {cam_data_lp_n[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports cam_clk]
set_property IOSTANDARD LVCMOS33 [get_ports cam_gpio]
set_property IOSTANDARD LVCMOS33 [get_ports cam_scl]
set_property IOSTANDARD LVCMOS33 [get_ports cam_sda]


# HDMI TX
set_property PACKAGE_PIN H16 [get_ports hdmi_tx_clk_p]
set_property PACKAGE_PIN D19 [get_ports {hdmi_tx_data_p[0]}]
set_property PACKAGE_PIN C20 [get_ports {hdmi_tx_data_p[1]}]
set_property PACKAGE_PIN B19 [get_ports {hdmi_tx_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_tx_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_data_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_data_p[2]}]

# DIP-SW
set_property PACKAGE_PIN G15 [get_ports {dip_sw[0]}]
set_property PACKAGE_PIN P15 [get_ports {dip_sw[1]}]
set_property PACKAGE_PIN W13 [get_ports {dip_sw[2]}]
set_property PACKAGE_PIN T16 [get_ports {dip_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[3]}]


# PUSH-SW
set_property PACKAGE_PIN K18 [get_ports {push_sw[0]}]
set_property PACKAGE_PIN P16 [get_ports {push_sw[1]}]
set_property PACKAGE_PIN K19 [get_ports {push_sw[2]}]
set_property PACKAGE_PIN Y16 [get_ports {push_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[3]}]


# LED
set_property PACKAGE_PIN M14 [get_ports {led[0]}]
set_property PACKAGE_PIN M15 [get_ports {led[1]}]
set_property PACKAGE_PIN G14 [get_ports {led[2]}]
set_property PACKAGE_PIN D18 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]


# PMOD_A
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[0]}]
set_property PACKAGE_PIN N15 [get_ports {pmod_a[0]}]
set_property PACKAGE_PIN N16 [get_ports {pmod_a[4]}]
set_property PACKAGE_PIN L14 [get_ports {pmod_a[1]}]
set_property PACKAGE_PIN L15 [get_ports {pmod_a[5]}]
set_property PACKAGE_PIN K16 [get_ports {pmod_a[2]}]
set_property PACKAGE_PIN J16 [get_ports {pmod_a[6]}]
set_property PACKAGE_PIN K14 [get_ports {pmod_a[3]}]
set_property PACKAGE_PIN J14 [get_ports {pmod_a[7]}]

# PMOD_B
set_property PACKAGE_PIN V8  [get_ports {pmod_jb_p[1]}]
set_property PACKAGE_PIN U7  [get_ports {pmod_jb_p[2]}]
set_property PACKAGE_PIN Y7  [get_ports {pmod_jb_p[3]}]
set_property PACKAGE_PIN V6  [get_ports {pmod_jb_p[4]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_n[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_n[3]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_n[4]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_p[3]}]
set_property IOSTANDARD TMDS_33 [get_ports {pmod_jb_p[4]}]



