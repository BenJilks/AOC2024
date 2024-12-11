all: day7_task1 day7_task2

day7_task1: day7_task1.o
	gcc -g -no-pie day7_task1.o -o day7_task1 -nostartfiles

day7_task1.o: day7_task1.s
	nasm -felf64 day7_task1.s -o day7_task1.o

day7_task2: day7_task2.o
	gcc -g -no-pie day7_task2.o -o day7_task2 -nostartfiles

day7_task2.o: day7_task2.s
	nasm -felf64 day7_task2.s -o day7_task2.o

clean:
	rm -f day7_task1.o day7_task1 day7_task2.o day7_task2
