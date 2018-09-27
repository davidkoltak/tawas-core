#!/bin/bash

iverilog -stestbench -o sim.vvp sgmii_testbench.v ../rtl/sgmii_*.v && vvp sim.vvp
