.SUFFIXES: .mtl .asm .bin
.PHONY: all clean

%.asm: %.mtl
	racket metal.rkt < $< > $@

%.bin: %.asm
	nasm -f bin $< -o $@

SRC=boot-hello.mtl
ASMS=$(SRC:%.mtl=%.asm)
BINS=$(ASMS:%.asm=%.bin)

all: ${BINS}

run-bochs: ${BINS}
	echo 6 | bochs

clean: 
	rm -f ${ASMS} bochsout.txt
