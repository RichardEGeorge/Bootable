.PHONY: clean test

boot.img: boot.pre
	rm -f boot.img
	dd if=/dev/zero of=boot.img ibs=512 count=2880 conv=osync
	dd if=boot.pre of=boot.img ibs=512 obs=512 seek=0 conv=notrunc,sync

boot.pre: boot.bin loader2.bin 
	cat boot.bin loader2.bin > boot.pre

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

loader2.bin: loader2.o
	gobjcopy -O binary loader2.o loader2.bin

loader2.o: loader2.c
	gcc -c loader2.c -o loader2.o -ffreestanding -nostdlib -m32
	gcc -S loader2.c -o loader2.s -ffreestanding -nostdlib -m32


clean:
	rm -f boot.img loader2.bin loader2.o loader2.s boot.pre loader2.s

test: boot.img
	bochs -qf bochsrc


