all: day2

day2: day2.o
	gcc -g -no-pie day2.o -o day2 -nostartfiles

day2.o: day2.s
	nasm -felf64 day2.s -o day2.o

clean:
	rm -f day2.o day2
