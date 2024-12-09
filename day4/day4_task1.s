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

get_positive_amount:
    ; rdi = a
    mov rax, rdi
    cmp rax, 0
    jle .none
    ret
.none:
    mov rax, 0
    ret

get_negative_amount:
    ; rdi = a
    mov rax, rdi
    cmp rax, 0
    jge .none
    imul rax, -1
    ret
.none:
    mov rax, 0
    ret

check_cell:
    %push task1_context
    %stacksize flat64
    %assign %$localsize 0
    %local x:qword, \
           y:qword, \
           dx:qword, \
           dy:qword, \
           word_ptr:qword

    enter %$localsize, 0

    mov [x], rdi
    mov [y], rsi
    mov [dx], rdx
    mov [dy], rcx

    mov qword [word_ptr], search_word
.loop_start:
    mov rbx, [word_ptr]
    mov al, byte [rbx]
    cmp al, 0
    je .valid

    mov rbx, [y]
    imul rbx, MAX_LINE_LENGTH
    lea rcx, [lines+rbx]
    add rcx, [x]
    mov bl, byte [rcx]
    cmp bl, al
    jne .invalid

    ; x = x + dx
    mov rax, [x]
    add rax, [dx]
    mov [x], rax

    ; y = y + dy
    mov rax, [y]
    add rax, [dy]
    mov [y], rax

    inc qword [word_ptr]
    jmp .loop_start

.valid:
    inc qword [total_found]

.invalid:
    leave
    ret

    %pop

check_direction:
    %push task1_context
    %stacksize flat64
    %assign %$localsize 0
    %local dx:qword, \
           dy:qword, \
           start_x:qword, \
           x:qword, \
           y:qword, \
           end_offset_x:qword, \
           end_offset_y:qword, \
           line:qword, \
           line_length:qword

    ; rdi = dx
    ; rsi = dy
    enter %$localsize, 0

    mov [dx], rdi
    mov [dy], rsi

    ; compute start x and y
    mov rdi, [dx]
    call get_negative_amount
    imul rax, 3
    mov [start_x], rax
    mov rdi, [dy]
    call get_negative_amount
    imul rax, 3
    mov [y], rax

    ; compute x and y end offset
    mov rdi, [dx]
    call get_positive_amount
    imul rax, WORD_LENGTH
    mov [end_offset_x], rax
    mov rdi, [dy]
    call get_positive_amount
    imul rax, WORD_LENGTH
    mov [end_offset_y], rax

.y_loop_start:
    mov rax, [y]
    add rax, [end_offset_y]
    cmp rax, [line_count]
    jg .y_loop_end

    mov rax, [y]
    imul eax, MAX_LINE_LENGTH
    lea rbx, [lines+rax]
    mov [line], rbx

    mov rdi, [line]
    call strlen
    mov [line_length], rax

    mov rax, [start_x]
    mov [x], rax
.x_loop_start:
    mov rax, [x]
    add rax, [end_offset_x]
    cmp rax, [line_length]
    jg .x_loop_end

    mov rdi, [x]
    mov rsi, [y]
    mov rdx, [dx]
    mov rcx, [dy]
    call check_cell

    inc qword [x]
    jmp .x_loop_start
.x_loop_end:

    inc qword [y]
    jmp .y_loop_start
.y_loop_end:

    leave
    ret

task1:
    mov rdi, 1
    mov rsi, 0
    call check_direction

    mov rdi, -1
    mov rsi, 0
    call check_direction

    mov rdi, 0
    mov rsi, 1
    call check_direction

    mov rdi, 0
    mov rsi, -1
    call check_direction

    mov rdi, 1
    mov rsi, 1
    call check_direction

    mov rdi, 1
    mov rsi, -1
    call check_direction

    mov rdi, -1
    mov rsi, 1
    call check_direction

    mov rdi, -1
    mov rsi, -1
    call check_direction

    mov eax, dword [total_found]
    ret

_start:
    call read_input

    ; Do task1 and print result
    call task1
    mov rdi, task1_result_str
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

search_word:
    db "XMAS", 0
total_found:
    dq 0

task1_result_str:
    db "task1 = %d", 10, 0

