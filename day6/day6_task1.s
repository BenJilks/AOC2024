%define MAX_GRID_SIZE 1024

section .text
global _start

extern fopen
extern fclose
extern getline
extern printf
extern puts
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
    cmp al, '#'
    je .object
    cmp al, '^'
    je .guard
    jmp .next

.object:
    mov rax, qword [grid_ptr]
    mov byte [rax], 1
    jmp .next

.guard:
    mov rax, qword [length]
    mov qword [g_guard_x], rax
    mov rax, qword [g_height]
    mov qword [g_guard_y], rax
    jmp .next

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

count_total_visited:
    mov rax, 0 ; x
    mov rbx, 0 ; y
    mov r8, 0 ; total visited
.loop_start:
    cmp rbx, qword [g_height]
    jge .loop_end

    xor rcx, rcx

    mov rdx, rbx
    imul rdx, MAX_GRID_SIZE
    add rdx, rax
    mov cl, [g_visited+rdx]
    add r8, rcx

    inc rax
    cmp rax, qword [g_width]
    jl .loop_start

    mov rax, 0
    inc rbx
    jmp .loop_start
.loop_end:

    mov rax, r8
    ret

; return 1 if hit edge, 0 if hit wall
walk_until_wall_or_edge:
.loop_start:
    mov rax, qword [g_guard_x] ; next x
    add rax, qword [g_guard_dx]
    mov rbx, qword [g_guard_y] ; next y
    add rbx, qword [g_guard_dy]

    cmp rax, 0
    jl .hit_edge
    cmp rax, [g_width]
    jg .hit_edge
    cmp rbx, 0
    jl .hit_edge
    cmp rbx, [g_height]
    jg .hit_edge

    mov rdx, rbx
    imul rdx, MAX_GRID_SIZE
    add rdx, rax
    mov cl, byte [g_grid+rdx] ; cell at x,y

    cmp cl, 1
    je .hit_wall

    mov byte [g_visited+rdx], 1
    mov qword [g_guard_x], rax
    mov qword [g_guard_y], rbx
    jmp .loop_start

.hit_edge:
    mov rax, 1
    ret

.hit_wall:
    mov rax, 0
    ret

rotate_right:
    mov rax, qword [g_guard_dy]
    imul rax, -1
    mov rbx, qword [g_guard_dx]

    mov qword [g_guard_dx], rax
    mov qword [g_guard_dy], rbx
    ret

task1:
    ; set intial cell visited
    mov rdx, qword [g_guard_y]
    imul rdx, MAX_GRID_SIZE
    add rdx, qword [g_guard_x]
    mov byte [g_visited+rdx], 1

.loop_start:
    call walk_until_wall_or_edge
    cmp rax, 1
    je .loop_end

    call rotate_right
    jmp .loop_start
.loop_end:

    call count_total_visited
    ret

_start:
    ; Read input and sort lists
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

g_width: dq 0
g_height: dq 0
g_grid: times MAX_GRID_SIZE*MAX_GRID_SIZE db 0
g_visited: times MAX_GRID_SIZE*MAX_GRID_SIZE db 0

g_guard_x: dq 0
g_guard_y: dq 0
g_guard_dx: dq 0
g_guard_dy: dq -1

task1_result_str:
    db "task1 = %d", 10, 0

