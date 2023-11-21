## Generated SDC file "cyclone_v_sha256.out.sdc"

## Copyright (C) 2023  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 22.1std.2 Build 922 07/20/2023 SC Lite Edition"

## DATE    "Tue Nov 21 10:10:17 2023"

##
## DEVICE  "5CEBA4F23C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk50} -period 20.000 -waveform { 0.000 10.000 } [get_ports { clk50 }]
derive_pll_clocks

#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {addr_bus[0]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {addr_bus[1]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {com_clk}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[0]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[1]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[2]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[3]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[4]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[5]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[6]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[7]}]
set_input_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {r_nw}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[0]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[1]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[2]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[3]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[4]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[5]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[6]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {data_bus[7]}]
set_output_delay -add_delay -max -clock [get_clocks {clk50}]  10.000 [get_ports {blink}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

