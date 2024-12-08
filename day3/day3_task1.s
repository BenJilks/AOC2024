%define BUFFER_SIZE 1024

%define STATE_M             0
%define STATE_U             1
%define STATE_L             2
%define STATE_OPEN_PAREN    3
%define STATE_FIRST_NUMBER  4
%define STATE_SECOND_NUMBER 5

section .text
global _start

extern fopen
extern fread
extern fclose
extern printf
extern puts
extern exit

process_byte:
    ; dil = byte
    enter 0, 0

    mov rax, [state]
    mov ebx, [.jump_table+rax*4]
    jmp rbx

.state_m:
    cmp dil, 'm'
    jne .invalid
    mov dword [first_number], 0
    mov dword [second_number], 0
    mov qword [state], STATE_U
    jmp .valid

.state_u:
    cmp dil, 'u'
    jne .invalid
    mov qword [state], STATE_L
    jmp .valid

.state_l:
    cmp dil, 'l'
    jne .invalid
    mov qword [state], STATE_OPEN_PAREN
    jmp .valid

.state_open_paren:
    cmp dil, '('
    jne .invalid
    mov qword [state], STATE_FIRST_NUMBER
    jmp .valid

.state_first_number:
    cmp dil, '0'
    jl .state_first_number_comma
    cmp dil, '9'
    jg .state_first_number_comma

    sub dil, '0'
    mov eax, dword [first_number]
    imul eax, 10
    movzx edi, dil
    add eax, edi
    mov dword [first_number], eax
    jmp .valid
.state_first_number_comma:
    cmp dil, ','
    jne .invalid

    mov qword [state], STATE_SECOND_NUMBER
    jmp .valid

.state_second_number:
    cmp dil, '0'
    jl .state_second_number_close_paren
    cmp dil, '9'
    jg .state_second_number_close_paren

    sub dil, '0'
    mov eax, dword [second_number]
    imul eax, 10
    movzx edi, dil
    add eax, edi
    mov dword [second_number], eax
    jmp .valid
.state_second_number_close_paren:
    cmp dil, ')'
    jne .invalid

    mov rdi, mul_str
    mov rsi, [first_number]
    mov rdx, [second_number]
    mov eax, 0
    call printf

    mov eax, [first_number]
    mov ebx, [second_number]
    imul eax, ebx
    add [total_result], eax

    mov qword [state], STATE_M
    jmp .valid

.invalid:
    mov qword [state], STATE_M
    leave
    ret

.valid:
    leave
    ret

.jump_table:
    dd .state_m, \
       .state_u, \
       .state_l, \
       .state_open_paren, \
       .state_first_number, \
       .state_second_number

read_input:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local file:qword, \
           bytes_read:qword, \
           i:qword

    enter %$localsize, 0

    ; Open file
    mov rdi, input_file_path
    mov rsi, open_args
    call fopen
    ; TODO: Error checking
    mov [file], rax

.loop_start:
    ; Read buffer
    lea rdi, buffer
    lea rsi, 1
    mov rdx, BUFFER_SIZE
    mov rcx, [file]
    call fread

    ; Exit loop if at end of file
    cmp rax, 0
    jle .loop_end

    mov qword [bytes_read], rax
    mov qword [i], 0
.inner_loop_start:
    mov rax, [i]
    cmp rax, [bytes_read]
    jge .inner_loop_end

    mov dil, byte [buffer+rax]
    call process_byte

    inc qword [i]
    jmp .inner_loop_start
.inner_loop_end:

    jmp .loop_start
.loop_end:

    ; Clean up
    mov rdi, [file]
    call fclose

    leave
    ret

    %pop

_start:
    ; Do task1 and print result
    call read_input
    mov rdi, task1_result_str
    mov esi, [total_result]
    mov eax, 0
    call printf

    xor rdi, rdi
    call exit

section .data
input_file_path:
    db "input.txt", 0
open_args:
    db "r", 0

buffer:
    times BUFFER_SIZE dd 0
state:
    dq 0
first_number:
    dd 0
second_number:
    dd 0
total_result:
    dd 0

task1_result_str:
    db    "task1 = %d", 10, 0
mul_str:
    db    "mul(%d, %d)", 10, 0
