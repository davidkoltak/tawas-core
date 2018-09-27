#!/bin/bash

iverilog -stestbench -o sim.vvp sgmii_*.v
vvp sim.vvp
