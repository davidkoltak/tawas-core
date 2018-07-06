
TOOLS_PATH = ../../../../ip/tawas/tools/

SIM_DEFS = -DMAX_CLOCKS=60000 -DSIM

SRC = uart_test.ta lib/test.ta lib/rcn_dma.ta lib/string.ta lib/uart.ta
INC = -Iinclude/

all: irom.hex dram.hex

irom.hex dram.hex: $(SRC:.ta=.to)
	${TOOLS_PATH}tln -Iirom.hex -Ddram.hex $^

%.to: %.ta
	${TOOLS_PATH}tas ${INC} ${SIM_DEFS} $^

clean:
	rm -f *.to ./lib/*.to *.hex

