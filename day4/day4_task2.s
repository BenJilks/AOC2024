%define MAX_LINE_LENGTH 1024
%define MAX_LINE_COUNT 1024
%define WORD_LENGTH 4

section .text
global _start

extern fopen
extern fclose
extern getline
extern memcpy
extern strlen
extern printf
extern puts
extern free
extern exit

read_input:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local file:qword, \
           line:qword, \
           length:qword, \
           read:qword

    enter %$localsize, 0

    ; Open file
    mov rdi, input_file_path
    mov rsi, open_args
    call fopen
    ; TODO: Error checking
    mov [file], rax

.loop_start:
    ; Read line
    lea rdi, [line]
    lea rsi, [length]
    mov rdx, [file]
    call getline
    mov [read], rax

    ; Exit loop if at end of file
    cmp rax, 0
    jl .loop_end

    ; memcpy(lines+line_count*MAX_LINE_LENGTH, line, length)
    mov rax, qword [line_count]
    imul rax, MAX_LINE_LENGTH
    lea rdi, [lines+rax]
    mov rsi, [line]
    mov rdx, [read]
    sub rdx, 1
    call memcpy

    inc qword [line_count]
    jmp .loop_start
.loop_end:

    ; Clean up
    mov rdi, [file]
    call fclose
    mov rdi, [line]
    call free

    leave
    ret

    %pop

check_cell:
    %push task1_context
    %stacksize flat64
    %assign %$localsize 0
    %local pattern:qword, \
           x:qword, \
           y:qword, \
           x_offset:qword, \
           index:qword, \
           word_ptr:qword

    enter %$localsize, 0

    mov [pattern], rdi
    mov [x], rsi
    mov [y], rdx

    mov qword [index], 0
.y_loop_start:
    cmp qword [index], 9
    jge .y_loop_end

    mov qword [x_offset], 0
.x_loop_start:
    cmp qword [x_offset], 3
    jge .x_loop_end

    mov rbx, [pattern]
    add rbx, [index]
    mov al, byte [rbx]
    cmp al, '.'
    je .ignore

    mov rbx, [y]
    imul rbx, MAX_LINE_LENGTH
    lea rcx, [lines+rbx]
    add rcx, [x]
    add rcx, [x_offset]
    mov bl, byte [rcx]

    cmp al, bl
    jne .invalid
    
.ignore:
    inc rax
    inc qword [x_offset]
    inc qword [index]
    jmp .x_loop_start
.x_loop_end:

    inc qword [y]
    jmp .y_loop_start
.y_loop_end:

    ; valid
    inc qword [total_found]

.invalid:
    leave
    ret

    %pop

check_pattern:
    %push task1_context
    %stacksize flat64
    %assign %$localsize 0
    %local pattern:qword, \
           x:qword, \
           y:qword, \
           line:qword, \
           line_length:qword

    ; rdi = pattern
    enter %$localsize, 0

    mov qword [pattern], rdi
    mov qword [y], 0
.y_loop_start:
    mov rax, [y]
    add rax, 2
    cmp rax, [line_count]
    jg .y_loop_end

    mov rax, [y]
    imul eax, MAX_LINE_LENGTH
    lea rbx, [lines+rax]
    mov [line], rbx

    mov rdi, [line]
    call strlen
    mov [line_length], rax

    mov qword [x], 0
.x_loop_start:
    mov rax, [x]
    add rax, 2
    cmp rax, [line_length]
    jg .x_loop_end

    mov rdi, [pattern]
    mov rsi, [x]
    mov rdx, [y]
    call check_cell

    inc qword [x]
    jmp .x_loop_start
.x_loop_end:

    inc qword [y]
    jmp .y_loop_start
.y_loop_end:

    leave
    ret

task2:
    mov rdi, pattern1
    call check_pattern

    mov rdi, pattern2
    call check_pattern

    mov rdi, pattern3
    call check_pattern

    mov rdi, pattern4
    call check_pattern

    mov eax, dword [total_found]
    ret

_start:
    call read_input

    ; Do task2 and print result
    call task2
    mov rdi, task2_result_str
    mov esi, eax
    mov eax, 0
    call printf

    xor rdi, rdi
    call exit

section .data
input_file_path:
    db "input.txt", 0
open_args:
    db "r", 0

line_count:
    dq 0
lines:
    times MAX_LINE_COUNT*MAX_LINE_LENGTH db 0

pattern1:
    db "M.S", \
       ".A.", \
       "M.S", 0
pattern2:
    db "S.S", \
       ".A.", \
       "M.M", 0
pattern3:
    db "S.M", \
       ".A.", \
       "S.M", 0
pattern4:
    db "M.M", \
       ".A.", \
       "S.S", 0
total_found:
    dq 0

task2_result_str:
    db "task2 = %d", 10, 0

