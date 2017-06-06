
TOOLS_PATH = ../../../../ip/tawas/tools/

SRC = default.ta lib/string.ta lib/test.ta
DEF = -DSIM
INC = -Iinclude/

all: irom.hex dram.hex

irom.hex dram.hex: $(SRC:.ta=.to)
	${TOOLS_PATH}tln -Iirom.hex -Ddram.hex $^

%.to: %.ta
	${TOOLS_PATH}tas $(INC) $^

clean:
	rm *.to ./lib/*.to *.hex
