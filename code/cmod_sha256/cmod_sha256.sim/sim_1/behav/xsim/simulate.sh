#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2023.1 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Tue Sep 26 16:01:11 CEST 2023
# SW Build 3865809 on Sun May  7 15:04:56 MDT 2023
#
# IP Build 3864474 on Sun May  7 20:36:21 MDT 2023
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# simulate design
echo "xsim sha256_core_tb_behav -key {Behavioral:sim_1:Functional:sha256_core_tb} -tclbatch sha256_core_tb.tcl -view /home/markus/uni/ESD3_project/code/cmod_sha256/sha256_core_simulation.wcfg -log simulate.log"
xsim sha256_core_tb_behav -key {Behavioral:sim_1:Functional:sha256_core_tb} -tclbatch sha256_core_tb.tcl -view /home/markus/uni/ESD3_project/code/cmod_sha256/sha256_core_simulation.wcfg -log simulate.log

