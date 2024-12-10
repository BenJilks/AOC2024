%define MAX_GRID_SIZE 1024

%define DIRECTION_UP    1
%define DIRECTION_RIGHT 2
%define DIRECTION_DOWN  4
%define DIRECTION_LEFT  8

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
    mov qword [g_guard_start_x], rax
    mov rax, qword [g_height]
    mov qword [g_guard_start_y], rax
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

mark_visited:
    mov rax, qword [g_guard_y]
    imul rax, MAX_GRID_SIZE
    add rax, qword [g_guard_x]

    mov bl, byte [g_guard_direction]
    or byte [g_visited+rax], bl
    ret

; return 0 if hit wall, 1 if hit edge, 2 if hit self
walk_until_wall_or_edge_or_self:
    %push walk_until_wall_or_edge_or_self_context
    %stacksize flat64
    %assign %$localsize 0
    %local next_x:qword, \
           next_y:qword, \
           index:qword

    enter %$localsize, 0

.loop_start:
    mov rax, qword [g_guard_x]
    add rax, qword [g_guard_dx]
    mov qword [next_x], rax
    mov rbx, qword [g_guard_y]
    add rbx, qword [g_guard_dy]
    mov qword [next_y], rbx

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
    mov qword [index], rdx

    mov cl, byte [g_grid+rdx] ; cell at x,y
    cmp cl, 1
    je .hit_wall

    mov cl, byte [g_visited+rdx]
    and cl, byte [g_guard_direction]
    cmp cl, 0
    jg .hit_self

    ; move guard to next position
    mov rax, qword [next_x]
    mov qword [g_guard_x], rax
    mov rax, qword [next_y]
    mov qword [g_guard_y], rax
    call mark_visited

    jmp .loop_start

.hit_wall:
    mov rax, 0
    leave
    ret
.hit_edge:
    mov rax, 1
    leave
    ret
.hit_self:
    mov rax, 2
    leave
    ret
    
    %pop

rotate_right:
    mov rax, qword [g_guard_dy]
    imul rax, -1
    mov rbx, qword [g_guard_dx]

    mov qword [g_guard_dx], rax
    mov qword [g_guard_dy], rbx

    shl byte [g_guard_direction], 1
    mov al, byte [g_guard_direction]
    cmp al, DIRECTION_LEFT
    jg .wrap_direction
    ret

.wrap_direction:
    mov byte [g_guard_direction], DIRECTION_UP
    ret

does_loop_forever:
    call mark_visited

.loop_start:
    call walk_until_wall_or_edge_or_self
    cmp rax, 1 ; hit edge
    je .did_halt
    cmp rax, 2 ; hit self
    je .loops_forever

    call rotate_right
    jmp .loop_start

.did_halt:
    mov rax, 0
    ret
.loops_forever:
    mov rax, 1
    ret

reset_visited_and_guard:
    mov rdi, g_visited
    mov rsi, 0
    mov rdx, MAX_GRID_SIZE*MAX_GRID_SIZE
    call memset

    mov rax, qword [g_guard_start_x]
    mov qword [g_guard_x], rax
    mov rax, qword [g_guard_start_y]
    mov qword [g_guard_y], rax

    mov qword [g_guard_dx], 0
    mov qword [g_guard_dy], -1
    mov byte [g_guard_direction], DIRECTION_UP

    mov rax, 0
    ret

is_position_guard_start:
    ; rdi = x
    ; rsi = y
    cmp rdi, qword [g_guard_start_x]
    jne .no
    cmp rsi, qword [g_guard_start_y]
    jne .no
    mov rax, 1
    ret
.no:
    mov rax, 0
    ret

task2:
    %push task2_context
    %stacksize flat64
    %assign %$localsize 0
    %local x:qword, \
           y:qword, \
           index:qword, \
           loops_forever_count:qword

    enter %$localsize, 0

    mov qword [x], 0
    mov qword [y], 0 ; y
    mov qword [loops_forever_count], 0
.loop_start:
    mov rax, qword [y]
    cmp rax, qword [g_height]
    jge .loop_end

    mov rdi, qword [x]
    mov rsi, qword [y]

    ; skip the guard start position
    mov rdi, qword [x]
    mov rsi, qword [y]
    call is_position_guard_start
    cmp rax, 1
    je .next

    ; skip cells with existing walls
    mov rbx, qword [y]
    imul rbx, MAX_GRID_SIZE
    add rbx, qword [x]
    mov al, byte [g_grid+rbx]
    cmp al, 1
    je .next

    mov qword [index], rbx
    mov byte [g_grid+rbx], 1 ; add temp wall

    call reset_visited_and_guard
    call does_loop_forever
    add qword [loops_forever_count], rax

    mov rbx, qword [index]
    mov byte [g_grid+rbx], 0 ; remove temp wall

.next:
    inc qword [x]
    mov rax, qword [x]
    cmp rax, qword [g_width]
    jl .loop_start

    mov qword [x], 0
    inc qword [y]
    jmp .loop_start
.loop_end:
    mov rax, qword [loops_forever_count]
    leave
    ret

    %pop

_start:
    ; Read input and sort lists
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

g_width: dq 0
g_height: dq 0
g_grid: times MAX_GRID_SIZE*MAX_GRID_SIZE db 0
g_visited: times MAX_GRID_SIZE*MAX_GRID_SIZE db 0

g_guard_start_x: dq 0
g_guard_start_y: dq 0
g_guard_x: dq 0
g_guard_y: dq 0
g_guard_dx: dq 0
g_guard_dy: dq -1
g_guard_direction: db DIRECTION_UP

task2_result_str:
    db "task2 = %d", 10, 0

