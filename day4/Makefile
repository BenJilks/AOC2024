all: day4_task1 day4_task2

day4_task2: day4_task2.o
	gcc -g -no-pie day4_task2.o -o day4_task2 -nostartfiles

day4_task2.o: day4_task2.s
	nasm -felf64 day4_task2.s -o day4_task2.o

day4_task1: day4_task1.o
	gcc -g -no-pie day4_task1.o -o day4_task1 -nostartfiles

day4_task1.o: day4_task1.s
	nasm -felf64 day4_task1.s -o day4_task1.o

clean:
	rm -f day4_task1.o day4_task1 day4_task2.o day4_task2
