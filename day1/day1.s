%define MAX_LIST_LENGTH 1024

section .text
global _start

extern fopen
extern fclose
extern getline
extern sscanf
extern printf
extern puts
extern free
extern abs
extern qsort
extern exit

read_input:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local file:qword, \
           line:qword, \
           length:qword, \
           read:qword, \
           list_a_item:dword, \
           list_b_item:dword

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
    jl .loop_end

    ; Scan for line list items
    mov rdi, [line]
    mov rsi, line_pattern
    lea rdx, [list_a_item]
    lea rcx, [list_b_item]
    mov eax, 0
    call sscanf

    mov rax, [list_length]
    mov ebx, dword [list_a_item]
    mov dword [list_a+rax*4], ebx
    mov ebx, dword [list_b_item]
    mov dword [list_b+rax*4], ebx

    inc rax
    mov [list_length], rax

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

compair_func:
    enter 0, 0

    mov eax, dword [rdi]
    sub eax, dword [rsi]

    leave
    ret

sort_list:
    enter 0, 0

    ; rdi is array
    mov rsi, [list_length]
    mov rdx, 4
    mov rcx, compair_func
    call qsort

    leave
    ret

task1:
    %push task1_context
    %stacksize flat64
    %assign %$localsize 0
    %local i:qword, \
           list_a_smallest:dword, \
           list_b_smallest:dword, \
           total:dword \

    enter %$localsize, 0

    mov qword [i], 0
    mov dword [list_a_smallest], 0
    mov dword [list_b_smallest], 0
    mov dword [total], 0

.loop_start:
    mov rax, [i]
    cmp rax, [list_length]
    jge .loop_end

    mov ebx, dword [list_a+rax*4]
    mov dword [list_a_smallest], ebx
    mov ebx, dword [list_b+rax*4]
    mov dword [list_b_smallest], ebx

    ; compute the difference
    mov eax, dword [list_a_smallest]
    sub eax, dword [list_b_smallest]

    cdq               ; Sign-extend eax into edx
    xor eax, edx      ; eax = eax ^ edx
    sub eax, edx      ; eax = eax - edx (absolute value)

    ; sum the total
    add dword [total], eax

    inc qword [i]
    jmp .loop_start
.loop_end:

    ; return our total
    mov eax, dword [total]
    leave
    ret

    %pop

count_occurrences_in_list_b:
    enter 0, 0

    mov rax, 0 ; i
    mov ebx, 0 ; total
.loop_start:
    cmp rax, [list_length]
    jge .loop_end

    mov ecx, [list_b+rax*4]
    inc rax

    cmp ecx, edi
    jne .loop_start

    inc ebx

    jmp .loop_start
.loop_end:

    mov eax, ebx
    leave
    ret

task2:
    %push task2_context
    %stacksize flat64
    %assign %$localsize 0
    %local i:qword, \
           total:dword

    enter %$localsize, 0

    mov qword [i], 0
    mov dword [total], 0

.loop_start:
    mov rax, [i]
    cmp rax, [list_length]
    jge .loop_end

    mov edi, [list_a+rax*4]
    call count_occurrences_in_list_b
    imul eax, edi

    add dword [total], eax

    inc qword [i]
    jmp .loop_start
.loop_end:

    mov eax, dword [total]
    leave
    ret

    %pop

_start:
    ; Read input and sort lists
    call read_input
    mov rdi, list_a
    call sort_list
    mov rdi, list_b
    call sort_list

    ; Do task1 and print result
    call task1
    mov rdi, task1_result_str
    mov esi, eax
    mov eax, 0
    call printf

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
line_pattern:
    db "%d   %d", 10, 0

list_length:
    dq 0
list_a:
    times MAX_LIST_LENGTH*4 dw 0
list_b:
    times MAX_LIST_LENGTH*4 dw 0

task1_result_str:
    db    "task1 = %d", 10, 0
task2_result_str:
    db    "task2 = %d", 10, 0
