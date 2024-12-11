%define MAX_EQUATION_COUNT 1024
%define MAX_EQUATION_LENGTH 512

%define OPERATION_ADD   0
%define OPERATION_MUL   1
%define OPERATION_COUNT 2

section .text
global _start

extern fopen
extern fclose
extern getline
extern printf
extern puts
extern memset
extern free
extern exit

parse_next_digit:
    ; rdi = number ptr
    ; sil = ASCII digit
    mov rax, qword [rdi]
    imul rax, 10
    sub sil, '0'
    movsx rbx, sil
    add rax, rbx
    mov qword [rdi], rax
    ret

parse_line:
    %push parse_line_context
    %stacksize flat64
    %assign %$localsize 0
    %local line_ptr:qword, \
           equation_ptr:qword, \
           operand:qword

    ; rdi = line
    enter %$localsize, 0
    mov qword [line_ptr], rdi
    mov qword [operand], 0

    mov rax, qword [equation_count]
    imul rax, MAX_EQUATION_LENGTH*8
    add rax, equations
    mov qword [equation_ptr], rax

.result_loop_start:
    mov rbx, qword [line_ptr]
    mov al, byte [rbx]
    cmp al, ':'
    je .result_loop_end

    lea rdi, [operand]
    mov sil, al
    call parse_next_digit

    inc qword [line_ptr]
    jmp .result_loop_start
.result_loop_end:

    mov rax, qword [operand]
    mov rbx, qword [equation_ptr]
    mov qword [rbx], rax
    add qword [equation_ptr], 8
    mov qword [operand], 0

    ; skip ': '
    add qword [line_ptr], 2

.operand_loop_start:
    mov rbx, qword [line_ptr]
    mov al, byte [rbx]
    cmp al, 10 ; new line
    je .operand_loop_end
    cmp al, 32 ; space
    je .operand_next

    lea rdi, [operand]
    mov sil, al
    call parse_next_digit

    inc qword [line_ptr]
    jmp .operand_loop_start

.operand_next:
    mov rax, qword [operand]
    mov rbx, qword [equation_ptr]
    mov qword [rbx], rax
    add qword [equation_ptr], 8
    mov qword [operand], 0

    inc qword [line_ptr]
    jmp .operand_loop_start
.operand_loop_end:

    mov rax, qword [operand]
    mov rbx, qword [equation_ptr]
    mov qword [rbx], rax
    add qword [equation_ptr], 8
    mov qword [operand], 0

    inc qword [equation_count]

    leave
    ret

read_input:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local file:qword, \
           line:qword, \
           length:qword

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

    ; Exit loop if at end of file
    cmp rax, 0
    jle .loop_end

    mov rdi, [line]
    call parse_line

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

count_operands:
    ; rdi = equation
    mov rax, 0 ; count
.loop_start:
    mov rbx, qword [rdi]
    cmp rbx, 0
    je .loop_end
    inc rax
    add rdi, 8
    jmp .loop_start
.loop_end:
    dec rax
    ret

next_operations_permutation:
    ; rdi = operand count

    mov rax, operations
.loop_start:
    mov rbx, rax
    sub rbx, operations
    add rbx, 1
    cmp rbx, rdi
    jge .done

    inc byte [rax]
    mov bl, byte [rax]
    cmp bl, OPERATION_COUNT
    jl .more_left

    mov byte [rax], 0
    inc rax
    jmp .loop_start
.more_left:
    mov rax, 0
    ret
.done:
    mov rax, 1
    ret

compute_equation:
    ; rdi = equation
    ; rsi = length
    mov rax, [rdi+8] ; total
    mov rbx, 0 ; i

    add rdi, 16
    sub rsi, 1
.loop_start:
    cmp rbx, rsi
    jge .loop_end

    mov cl, byte [operations+rbx]
    cmp cl, OPERATION_ADD
    je .add

; mul
    imul rax, qword [rdi]
    jmp .next

.add:
    add rax, qword [rdi]
    jmp .next
    
.next:
    inc rbx
    add rdi, 8
    jmp .loop_start
.loop_end:

    ret

validate_equation:
    %push validate_equation_context
    %stacksize flat64
    %assign %$localsize 0
    %local equation:qword, \
           equation_length:qword

    ; rdi = equation
    enter %$localsize, 0
    mov qword [equation], rdi

    mov rdi, operations
    mov rsi, 0
    mov rdx, MAX_EQUATION_LENGTH
    call memset

    mov rdi, qword [equation]
    call count_operands
    mov qword [equation_length], rax

.loop_start:
    mov rdi, qword [equation]
    mov rsi, qword [equation_length]
    call compute_equation
    mov rbx, qword [equation]
    cmp rax, qword [rbx]
    je .valid

    mov rdi, qword [equation_length]
    call next_operations_permutation
    cmp rax, 1
    je .invalid

    jmp .loop_start

.valid:
    mov rdi, qword [equation]

    mov rax, 1
    leave
    ret

.invalid:
    mov rax, 0
    leave
    ret

    %pop

task1:
    %push taskq_context
    %stacksize flat64
    %assign %$localsize 0
    %local total_valid:qword, \
           equation_ptr:qword

    enter %$localsize, 0
    mov qword [total_valid], 0
    mov qword [equation_ptr], equations

.loop_start:
    mov rbx, qword [equation_ptr]
    mov rax, qword [rbx]
    cmp rax, 0
    je .loop_end

    mov rdi, qword [equation_ptr]
    call validate_equation
    cmp rax, 0
    je .next

    mov rbx, qword [equation_ptr]
    mov rax, qword [rbx]
    add qword [total_valid], rax

.next:
    add qword [equation_ptr], MAX_EQUATION_LENGTH*8
    jmp .loop_start
.loop_end:

    mov rax, qword [total_valid]
    leave
    ret

_start:
    call read_input

    ; Do task1 and print result
    call task1
    mov rdi, task1_result_str
    mov rsi, rax
    mov eax, 0
    call printf

    xor rdi, rdi
    call exit

section .data
input_file_path:
    db "input.txt", 0
open_args:
    db "r", 0

equation_count:
    dq 0
equations:
    times MAX_EQUATION_COUNT*MAX_EQUATION_LENGTH*8 db 0
operations:
    times MAX_EQUATION_LENGTH db 0

task1_result_str:
    db    "task1 = %lu", 10, 0

