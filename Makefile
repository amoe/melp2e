CC = $(HOME)/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin/arm-cortex_a8-linux-gnueabihf-gcc

LIBS = -lsqlite3

%: %.c
	$(CC) -o $@ $(LIBS) $<
