all: day8_task1 day8_task2

day8_task1: day8_task1.o
	gcc -g -no-pie day8_task1.o -o day8_task1 -nostartfiles

day8_task1.o: day8_task1.s
	nasm -felf64 day8_task1.s -o day8_task1.o

day8_task2: day8_task2.o
	gcc -g -no-pie day8_task2.o -o day8_task2 -nostartfiles

day8_task2.o: day8_task2.s
	nasm -felf64 day8_task2.s -o day8_task2.o

clean:
	rm -f day8_task1.o day8_task1 day8_task2.o day8_task2
