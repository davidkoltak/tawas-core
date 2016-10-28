
TESTCASE ?= default

DESIGN_VERILOG  = ../rtl/tawas_regfile.v ../rtl/tawas_ls.v ../rtl/tawas_axi.v
DESIGN_VERILOG += ../rtl/tawas_au.v ../rtl/tawas_fetch.v ../rtl/tawas.v

MAX_CLOCKS = 500
TESTBENCH_VERILOG = ../testbench/irom.v ../testbench/dram.v ../testbench/axi_ram.v ../testbench/testbench.v
TESTBENCH_VERILOG += ../testbench/spartan/rtl/axi2spartan.v ../testbench/spartan/rtl/spartan2ram.v
TESTBENCH_DATA = ./irom.hex ./dram.hex

TOPLEVEL = testbench.v

results.vcd: testbench.vvp irom.hex dram.hex
	vvp testbench.vvp

waves: results.vcd
	gtkwave results.vcd &

testbench.vvp: $(DESIGN_VERILOG) $(TESTBENCH_VERILOG) $(TESTBENCH_DATA)
	iverilog $(DESIGN_VERILOG) $(TESTBENCH_VERILOG) -DMAX_CLOCKS=$(MAX_CLOCKS) -o testbench.vvp

irom.hex dram.hex: ../testbench/testcase/$(TESTCASE).as
	../src/tas ../testbench/testcase/$(TESTCASE).as

clean:
	rm -rf testbench.vvp irom.hex dram.hex results.vcd


