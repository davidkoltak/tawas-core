
TOOLS_PATH = ../../../../ip/tawas/tools/

SIM_DEFS = -DMAX_CLOCKS=4000 -DSIM

SRC = string_test.ta lib/string.ta lib/test.ta
INC = -Iinclude/

all: irom.hex dram.hex

irom.hex dram.hex: $(SRC:.ta=.to)
	${TOOLS_PATH}tln -Iirom.hex -Ddram.hex $^

%.to: %.ta
	${TOOLS_PATH}tas ${INC} ${SIM_DEFS} $^

clean:
	rm *.to ./lib/*.to *.hex
