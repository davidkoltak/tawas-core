
TOOLS_PATH = ../../../../ip/tawas/tools/

FW_DEFS = 

SRC = default.ta lib/test.ta lib/string.ta
INC = -Iinclude/

all: irom.hex dram.hex

irom.hex dram.hex: $(SRC:.ta=.to)
	${TOOLS_PATH}tln -Iirom.hex -Ddram.hex $^

%.to: %.ta
	${TOOLS_PATH}tas ${INC} ${FW_DEFS} $^

clean:
	rm -f *.to ./lib/*.to *.hex
