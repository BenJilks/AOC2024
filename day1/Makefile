all: day1

link day1: day1.o
	gcc -g -no-pie day1.o -o day1 -nostartfiles

assemble day1.o: day1.s
	nasm -felf64 day1.s -o day1.o

clean:
	rm -f day1.o day1
