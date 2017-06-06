
TOOLS_PATH = ../../../../ip/tawas/tools/

SRC = default.ta lib/string.ta lib/tests.ta

all: irom.hex dram.hex

irom.hex dram.hex: $(SRC:.ta=.to)
	${TOOLS_PATH}tln -Iirom.hex -Ddram.hex $^

%.to: %.ta
	${TOOLS_PATH}tas $^

clean:
	rm *.to ./lib/*.to *.hex
