#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2023.1 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Fri Nov 10 14:43:02 CET 2023
# SW Build 3865809 on Sun May  7 15:04:56 MDT 2023
#
# IP Build 3864474 on Sun May  7 20:36:21 MDT 2023
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# simulate design
echo "xsim sha256_core_tb_behav -key {Behavioral:sim_1:Functional:sha256_core_tb} -tclbatch sha256_core_tb.tcl -view /home/markus/uni/ESD3_project/code/sha256_vivado_cmod/passwd_expander_hash_tb_behav.wcfg -log simulate.log"
xsim sha256_core_tb_behav -key {Behavioral:sim_1:Functional:sha256_core_tb} -tclbatch sha256_core_tb.tcl -view /home/markus/uni/ESD3_project/code/sha256_vivado_cmod/passwd_expander_hash_tb_behav.wcfg -log simulate.log
