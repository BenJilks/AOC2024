%define PAGE_COUNT 100
%define MAX_DEPENDENCY_COUNT 100
%define MAX_LINE_COUNT 100

section .text
global _start

extern fopen
extern fclose
extern getline
extern printf
extern puts
extern memset
extern qsort
extern free
extern exit

parse_dependency:
    %push parse_dependency_context
    %stacksize flat64
    %assign %$localsize 0
    %local line:qword, \
           x:dword, \
           y:dword, \
           page:qword, \
           page_count:qword

    enter %$localsize, 0
    mov [line], rdi

    mov rax, [line]
    xor rbx, rbx
    xor rcx, rcx

    mov bl, byte [rax+0]
    sub bl, '0'
    imul ebx, 10
    mov cl, byte [rax+1]
    sub cl, '0'
    add bl, cl
    mov dword [x], ebx

    mov bl, byte [rax+3]
    sub bl, '0'
    imul ebx, 10
    mov cl, byte [rax+4]
    sub cl, '0'
    add bl, cl
    mov dword [y], ebx

    ; y is dependent on x
    mov eax, dword [y]
    imul eax, MAX_DEPENDENCY_COUNT*4
    lea rbx, [page_dependencies+eax]
    mov [page], rbx

    ; find the next empty slot
.loop_start:
    mov rbx, qword [page]
    mov eax, dword [rbx]
    cmp eax, 0
    je .loop_end
    add qword [page], 4
    jmp .loop_start
.loop_end:

    ; add x to y's dependency list
    mov eax, [x]
    mov rbx, [page]
    mov dword [rbx], eax

    leave
    ret

    %pop

parse_line:
    ; rdi = line

    mov r8, current_line
.loop_start:
    mov al, byte [rdi]
    cmp al, 0
    je .loop_end

    mov al, byte [rdi]
    sub al, '0'
    imul eax, 10
    mov bl, byte[rdi+1]
    sub bl, '0'
    add al, bl
    mov dword [r8], eax

    add rdi, 3
    add r8, 4
    jmp .loop_start
.loop_end:

    mov dword [r8], 0
    ret

is_in_current_line:
    ; edi = needle
    mov rax, current_line
.loop_start:
    mov ebx, dword [rax]
    cmp ebx, 0
    je .not_found

    cmp ebx, edi
    je .found

    add rax, 4
    jmp .loop_start
.found:
    mov rax, 1
    ret
.not_found:
    mov rax, 0
    ret

; ret's 1 if all seen, 0 if not
check_has_seen_dependencies:
    %push check_has_seen_dependencies_context
    %stacksize flat64
    %assign %$localsize 0
    %local page_number:dword, \
           page_ptr:qword, \
           current:dword

    ; edi = page number
    enter %$localsize, 0
    mov dword [page_number], edi

    mov ebx, [page_number]
    imul ebx, MAX_DEPENDENCY_COUNT*4
    lea rax, [page_dependencies+ebx]
    mov qword [page_ptr], rax

.loop_start:
    mov rbx, [page_ptr]
    mov eax, dword [rbx]
    cmp eax, 0
    je .all_seen

    mov dword [current], eax

    ; ignore if not in current line
    mov edi, eax
    call is_in_current_line
    cmp rax, 0
    je .continue

    mov eax, dword [current]
    cmp byte [seen_flags+eax], 0
    je .not_seen

    mov edi, dword [current]
    call check_has_seen_dependencies
    cmp rax, 0
    je .not_seen

.continue:
    add qword [page_ptr], 4
    jmp .loop_start

.not_seen:
    mov rax, 0
    leave
    ret

.all_seen:
    mov rax, 1
    leave
    ret

    %pop

find_middle_page_number:
    mov eax, 0; line length
    mov rbx, current_line; line ptr

.loop_start:
    cmp dword [rbx], 0
    je .loop_end
    inc eax
    add rbx, 4
    jmp .loop_start
.loop_end:

    shr eax, 1
    mov ebx, dword [current_line+eax*4]
    mov eax, ebx
    ret

count_dependency_occurrences:
    ; edi = page number

    mov ebx, edi
    imul ebx, MAX_DEPENDENCY_COUNT*4
    lea rax, [page_dependencies+ebx]
.loop_start:
    mov ebx, dword [rax]
    cmp ebx, 0
    je .loop_end

    add byte [seen_flags+ebx], 1

    add rax, 4
    jmp .loop_start
.loop_end:

    ret

compair_func:
    ; rdi = page number a ptr
    ; rsi = page number b ptr
    push rbx

    mov eax, dword [rsi]
    mov bl, byte [seen_flags+eax]
    mov eax, dword [rdi]
    sub bl, byte [seen_flags+eax]

    xor rax, rax
    movsx rax, bl

    pop rbx
    ret

reorder_line:
    %push check_line_context
    %stacksize flat64
    %assign %$localsize 0
    %local line_ptr:qword, \
           line_length:qword

    enter %$localsize, 0

    ; memset(seen_flags, 0, PAGE_COUNT)
    mov rdi, seen_flags
    mov rsi, 0
    mov rdx, PAGE_COUNT
    call memset

    mov qword [line_ptr], current_line
    mov qword [line_length], 0
.loop_start:
    mov rbx, qword [line_ptr]
    mov eax, dword [rbx]
    cmp eax, 0
    je .loop_end

    mov edi, eax
    call count_dependency_occurrences

    inc qword [line_length]
    add qword [line_ptr], 4
    jmp .loop_start
.loop_end:

    mov rdi, current_line
    mov rsi, qword [line_length]
    mov rdx, 4
    mov rcx, compair_func
    call qsort

    leave
    ret

    %pop

check_line:
    %push check_line_context
    %stacksize flat64
    %assign %$localsize 0
    %local i:qword, \
           current:dword

    ; rdi = line
    enter %$localsize, 0

    call parse_line

    ; memset(seen_flags, 0, PAGE_COUNT)
    mov rdi, seen_flags
    mov rsi, 0
    mov rdx, PAGE_COUNT
    call memset

    mov qword [i], 0
.loop_start:
    mov rbx, [i]
    mov eax, dword [current_line+rbx*4]
    cmp eax, 0
    je .valid

    mov dword [current], eax

    mov edi, dword [current]
    call check_has_seen_dependencies
    cmp rax, 0
    je .invalid

    mov eax, dword [current]
    mov byte [seen_flags+eax], 1

    inc qword [i]
    jmp .loop_start

.invalid:
    call reorder_line
    call find_middle_page_number
    add dword [total_result], eax

    leave
    ret

.valid:
    leave
    ret

    %pop

read_input:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local file:qword, \
           line:qword, \
           length:qword, \
           mode:byte

    enter %$localsize, 0
    mov byte [mode], 0

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

    cmp rax, 1
    je .switch_mode

    mov al, byte [mode]
    cmp al, 1
    je .handle_second_mode

    mov rdi, [line]
    call parse_dependency

    jmp .loop_start

.switch_mode:
    mov byte [mode], 1
    jmp .loop_start

.handle_second_mode:
    mov rdi, [line]
    call check_line
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

_start:
    ; Read input
    call read_input

    ; Print result
    mov rdi, task2_result_str
    mov esi, dword [total_result]
    mov eax, 0
    call printf

    xor rdi, rdi
    call exit

section .data
input_file_path:
    db "input.txt", 0
open_args:
    db "r", 0

page_dependencies:
    times PAGE_COUNT*MAX_DEPENDENCY_COUNT*4 dw 0
current_line:
    times MAX_LINE_COUNT*4 dw 0
seen_flags:
    times PAGE_COUNT db 0

total_result:
    dd 0

task2_result_str:
    db    "task2 = %d", 10, 0
