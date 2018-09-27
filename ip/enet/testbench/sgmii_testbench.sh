#!/bin/bash

iverilog -stestbench -o sim.vvp ../rtl/sgmii_*.v && vvp sim.vvp
