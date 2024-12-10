all: day6_task1 day6_task2

day6_task1: day6_task1.o
	gcc -g -no-pie day6_task1.o -o day6_task1 -nostartfiles

day6_task1.o: day6_task1.s
	nasm -felf64 day6_task1.s -o day6_task1.o

day6_task2: day6_task2.o
	gcc -g -no-pie day6_task2.o -o day6_task2 -nostartfiles

day6_task2.o: day6_task2.s
	nasm -felf64 day6_task2.s -o day6_task2.o

clean:
	rm -f day6_task1.o day6_task1 day6_task2.o day6_task2
