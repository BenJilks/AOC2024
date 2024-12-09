all: day5_task1 day5_task2

day5_task1: day5_task1.o
	gcc -g -no-pie day5_task1.o -o day5_task1 -nostartfiles

day5_task1.o: day5_task1.s
	nasm -felf64 day5_task1.s -o day5_task1.o

day5_task2: day5_task2.o
	gcc -g -no-pie day5_task2.o -o day5_task2 -nostartfiles

day5_task2.o: day5_task2.s
	nasm -felf64 day5_task2.s -o day5_task2.o

clean:
	rm -f day5_task1.o day5_task1 day5_task2.o day5_task2
