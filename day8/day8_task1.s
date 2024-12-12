%define MAX_GRID_SIZE 1024

section .text
global _start

extern fopen
extern fclose
extern getline
extern printf
extern free
extern exit

parse_line:
    %push parse_line_context
    %stacksize flat64
    %assign %$localsize 0
    %local line_ptr:qword, \
           grid_ptr:qword, \
           length:qword

    enter %$localsize, 0
    mov qword [line_ptr], rdi
    mov qword [length], 0

    ; grid_ptr = g_grid + g_height*MAX_GRID_SIZE
    mov rax, qword [g_height]
    imul rax, MAX_GRID_SIZE
    add rax, g_grid
    mov qword [grid_ptr], rax

.loop_start:
    mov rbx, qword [line_ptr]
    mov al, byte [rbx]

    cmp al, 10
    je .loop_end
    cmp al, '.'
    je .next

    mov rbx, qword [grid_ptr]
    mov byte [rbx], al
    movsx ebx, al
    mov byte [g_frequencies_seen+ebx], 1

.next:
    inc qword [line_ptr]
    inc qword [grid_ptr]
    inc qword [length]
    jmp .loop_start

.loop_end:

    ; We're assuming all lines have the same length
    mov rax, qword [length]
    mov qword [g_width], rax
    inc qword [g_height]
    leave
    ret

    %pop

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

are_pairs_equal:
    ; rdi = node_a_x
    ; rsi = node_a_y
    ; rdx = node_b_x
    ; rcx = node_b_y
    cmp rdi, rdx
    jne .no
    cmp rsi, rcx
    jne .no
; yes
    mov rax, 1
    ret
.no:
    mov rax, 0
    ret

mark_antinode:
    ; rdi = x
    ; rsi = y

    cmp rdi, 0
    jl .skip
    cmp rdi, qword [g_width]
    jge .skip
    cmp rsi, 0
    jl .skip
    cmp rsi, qword [g_height]
    jge .skip

    mov rax, rsi
    imul rax, MAX_GRID_SIZE
    add rax, rdi
    cmp byte [g_antinode_grid+rax], 0
    jne .skip

    mov byte [g_antinode_grid+rax], '#'
    inc dword [g_total_unique_antinodes]
.skip:
    ret

compute_antinodes_for_pair:
    %push compute_antinodes_for_pair_context
    %stacksize flat64
    %assign %$localsize 0
    %local node_a_x:qword, \
           node_a_y:qword, \
           node_b_x:qword, \
           node_b_y:qword, \
           frequency:byte, \
           abs_diff_x:qword, \
           abs_diff_y:qword

    ; rdi = node_a_x
    ; rsi = node_a_y
    ; rdx = node_b_x
    ; rcx = node_b_y
    ; r8b = frequency
    enter %$localsize, 0
    mov qword [node_a_x], rdi
    mov qword [node_a_y], rsi
    mov qword [node_b_x], rdx
    mov qword [node_b_y], rcx
    mov byte [frequency], r8b

    ; antinode_a_x = node_a_x + (node_a_x - node_b_x);
    ; antinode_a_y = node_a_y + (node_a_y - node_b_y);
    mov rdi, qword [node_a_x]
    sub rdi, qword [node_b_x]
    add rdi, qword [node_a_x]
    mov rsi, qword [node_a_y]
    sub rsi, qword [node_b_y]
    add rsi, qword [node_a_y]
    call mark_antinode

    ; antinode_b_x = node_b_x + (node_b_x - node_a_x);
    ; antinode_b_y = node_b_y + (node_b_y - node_a_y);
    mov rdi, qword [node_b_x]
    sub rdi, qword [node_a_x]
    add rdi, qword [node_b_x]
    mov rsi, qword [node_b_y]
    sub rsi, qword [node_a_y]
    add rsi, qword [node_b_y]
    call mark_antinode

    leave
    ret

    %pop

find_antinodes_for_node:
    %push find_antinodes_for_node_context
    %stacksize flat64
    %assign %$localsize 0
    %local frequency:byte, \
           node_a_x:qword, \
           node_a_y:qword, \
           node_b_x:qword, \
           node_b_y:qword

    ; dil = frequency
    ; rsi = x
    ; rdx = y
    enter %$localsize, 0
    mov byte [frequency], dil
    mov qword [node_a_x], rsi
    mov qword [node_a_y], rdx

    mov qword [node_b_y], 0
.y_loop_start:
    mov rax, qword [node_b_y]
    cmp rax, qword [g_height]
    jge .y_loop_end

    mov qword [node_b_x], 0
.x_loop_start:
    mov rax, qword [node_b_x]
    cmp rax, qword [g_width]
    jge .x_loop_end

    ; Skip if not frequency
    mov rbx, qword [node_b_y]
    imul rbx, MAX_GRID_SIZE
    add rbx, qword [node_b_x]
    mov al, byte [g_grid+rbx]
    cmp al, byte [frequency]
    jne .next

    ; Skip if not unique towers
    mov rdi, qword [node_a_x]
    mov rsi, qword [node_a_y]
    mov rdx, qword [node_b_x]
    mov rcx, qword [node_b_y]
    call are_pairs_equal
    cmp rax, 1
    je .next

    ; first 4 arguments are already set
    mov r8b, byte [frequency]
    call compute_antinodes_for_pair

.next:
    inc qword [node_b_x]
    jmp .x_loop_start
.x_loop_end:

    inc qword [node_b_y]
    jmp .y_loop_start
.y_loop_end:

    leave
    ret

    %pop

find_antinodes_for_frequency:
    %push find_antinodes_for_frequency_context
    %stacksize flat64
    %assign %$localsize 0
    %local frequency:byte, \
           x:qword, \
           y:qword

    ; dil = frequency
    enter %$localsize, 0
    mov byte [frequency], dil

    mov qword [y], 0
.y_loop_start:
    mov rax, qword [y]
    cmp rax, qword [g_height]
    jge .y_loop_end

    mov qword [x], 0
.x_loop_start:
    mov rax, qword [x]
    cmp rax, qword [g_width]
    jge .x_loop_end

    ; Skip if not frequency
    mov rbx, qword [y]
    imul rbx, MAX_GRID_SIZE
    add rbx, qword [x]
    mov al, byte [g_grid+rbx]
    cmp al, byte [frequency]
    jne .next

    mov dil, byte [frequency]
    mov rsi, qword [x]
    mov rdx, qword [y]
    call find_antinodes_for_node

.next:
    inc qword [x]
    jmp .x_loop_start
.x_loop_end:

    inc qword [y]
    jmp .y_loop_start
.y_loop_end:

    leave
    ret

    %pop

task1:
    %push task1_context
    %stacksize flat64
    %assign %$localsize 0
    %local i:dword

    enter %$localsize, 0

    mov dword [i], 0
.loop_start:
    cmp dword [i], 128
    jge .loop_end
    mov eax, dword [i]
    cmp byte [g_frequencies_seen+eax], 1
    jne .next

    mov dil, byte [i]
    call find_antinodes_for_frequency

.next:
    inc dword [i]
    jmp .loop_start
.loop_end:

    mov eax, dword [g_total_unique_antinodes]
    leave
    ret

    %pop

_start:
    ; Read input
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

g_width:
    dq 0
g_height:
    dq 0
g_grid:
    times MAX_GRID_SIZE*MAX_GRID_SIZE db 0
g_antinode_grid:
    times MAX_GRID_SIZE*MAX_GRID_SIZE db 0

g_frequencies_seen:
    times 128 db 0
g_total_unique_antinodes:
    dd 0

task1_result_str:
    db "task1 = %d", 10, 0
