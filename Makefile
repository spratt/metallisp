.SUFFIXES: .mtl .asm .bin
.PHONY: all clean

%.asm: %.mtl
	racket metal.rkt < $< > $@

%.bin: %.asm
	nasm -f bin $< -o $@

SRC=boot-hello.mtl
ASM=$(SRC:%.mtl=%.asm)
BIN=$(ASM:%.asm=%.bin)

all: ${BIN}

run-qemu: ${BIN}
	qemu-system-x86_64 -drive format=raw,file=${BIN}

run-bochs: ${BIN}
	echo 6 | bochs

clean: 
	rm -f ${ASM} bochsout.txt
