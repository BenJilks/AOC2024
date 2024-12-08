all: day3_task1 day3_task2

day3_task1: day3_task1.o
	gcc -g -no-pie day3_task1.o -o day3_task1 -nostartfiles

day3_task1.o: day3_task1.s
	nasm -felf64 day3_task1.s -o day3_task1.o

day3_task2: day3_task2.o
	gcc -g -no-pie day3_task2.o -o day3_task2 -nostartfiles

day3_task2.o: day3_task2.s
	nasm -felf64 day3_task2.s -o day3_task2.o

clean:
	rm -f day3_task1.o day3_task1 day3_task2.o day3_task2
