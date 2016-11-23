
TESTCASE ?= default

DESIGN_VERILOG  = ../rtl/tawas_regfile.v ../rtl/tawas_ls.v ../rtl/tawas_raccoon.v
DESIGN_VERILOG += ../rtl/tawas_au.v ../rtl/tawas_fetch.v ../rtl/tawas.v

MAX_CLOCKS = 5000
TESTBENCH_VERILOG = ../testbench/irom.v ../testbench/dram.v ../testbench/axi_ram.v ../testbench/racc_ram.v
TESTBENCH_VERILOG += ../testbench/spartan/rtl/axi2spartan.v ../testbench/spartan/rtl/spartan2ram.v 
TESTBENCH_VERILOG += ../testbench/spartan/rtl/spartan_skid.v ../testbench/spartan/rtl/spartan_sync2.v
TESTBENCH_VERILOG += ../testbench/raccoon/rtl/raccoon2ram.v ../testbench/raccoon/rtl/raccoon2ram_w.v 
TESTBENCH_VERILOG += ../testbench/raccoon/rtl/raccoon2axi32.v ../testbench/raccoon/rtl/raccoon2axi64.v
TESTBENCH_VERILOG += ../testbench/raccoon/rtl/raccoon_delay.v ../testbench/raccoon/rtl/raccoon_event.v 
TESTBENCH_VERILOG += ../testbench/racc_subsys.v ../testbench/testbench.v
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


