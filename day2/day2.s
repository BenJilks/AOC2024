%define MAX_REPORT_COUNT 1024
%define MAX_REPORT_LENGTH 64

section .text
global _start

extern fopen
extern fclose
extern getline
extern printf
extern memcpy
extern free
extern exit

parse_report:
    ; rdi = report line
    ; rsi = report output
    enter 0, 0

    mov eax, 0 ; current

.loop_start:
    mov ebx, 0
    mov bl, byte [rdi]
    cmp bl, 0
    je .loop_end
    inc rdi
    
    cmp bl, 0x20 ; space
    je .handle_space

    cmp bl, 0x0A ; new line
    je .loop_end

    imul eax, 10
    sub bl, 0x30 ; zero
    add eax, ebx
    jmp .loop_start

.handle_space:
    ; add to current end of report
    mov dword [rsi], eax
    add rsi, 4

    ; reset current
    mov eax, 0

    jmp .loop_start
.loop_end:

    ; add last current end of report
    mov dword [rsi], eax

    leave
    ret

read_input:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local file:qword, \
           line:qword, \
           length:qword, \
           read:qword, \
           current_report:qword \

    enter %$localsize, 0

    mov qword [current_report], reports

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

    ; Parse the report line
    mov rdi, [line]
    mov rsi, [current_report]
    call parse_report

    ; Increment the report pointer
    add qword [current_report], MAX_REPORT_LENGTH*4
    inc qword [reports_count]

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

is_report_safe_increasing:
    ; rdi = report
    enter 0, 0

    mov eax, dword [rdi] ; last
    add rdi, 4

.loop_start:
    mov ebx, dword [rdi] ; current
    cmp ebx, 0
    je .safe

    ; did decrease
    cmp ebx, eax
    jle .unsafe

    ; increased by more then 3 
    mov ecx, ebx
    sub ecx, eax
    cmp ecx, 3
    jg .unsafe

    ; set last to current
    mov eax, ebx

    add rdi, 4
    jmp .loop_start

.safe:
    mov rax, 1
    leave
    ret

.unsafe:
    mov rax, 0
    leave
    ret

is_report_safe_decreasing:
    ; rdi = report
    enter 0, 0

    mov eax, dword [rdi] ; last
    add rdi, 4

.loop_start:
    mov ebx, dword [rdi] ; current
    cmp ebx, 0
    je .safe

    ; did increase
    cmp ebx, eax
    jge .unsafe

    ; decreased by more then 3 
    mov ecx, eax
    sub ecx, ebx
    cmp ecx, 3
    jg .unsafe

    ; set last to current
    mov eax, ebx

    add rdi, 4
    jmp .loop_start

.safe:
    mov rax, 1
    leave
    ret

.unsafe:
    mov rax, 0
    leave
    ret

is_report_safe:
    ; rdi = report
    enter 0, 0

    mov eax, dword [rdi]
    mov ebx, dword [rdi+4]

    cmp eax, ebx
    jl .increasing

    call is_report_safe_decreasing
    leave
    ret

.increasing:
    call is_report_safe_increasing
    leave
    ret

task1:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local i:qword, \
           total:qword

    enter %$localsize, 0

    mov qword [i], 0
    mov qword [total], 0
.loop_start:
    mov rax, [i]
    cmp rax, [reports_count]
    jge .loop_end

    imul rax, MAX_REPORT_LENGTH*4
    lea rdi, [reports+rax] ; current report
    call is_report_safe
    add qword [total], rax

    inc qword [i]
    jmp .loop_start
.loop_end:

    mov rax, qword [total]
    leave
    ret

compute_report_length:
    ; rdi = report
    enter 0, 0

    mov rax, 0; length
.loop_start:
    mov ebx, dword [rdi]
    cmp ebx, 0
    je .loop_end

    add rdi, 4
    inc rax
    jmp .loop_start

.loop_end:
    leave
    ret

remove_index_from_temp_report:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local index:qword, \
           report_length:qword

    ; rdi = index
    ; rsi = report length
    enter %$localsize, 0

    ; memcpy(report+index, report+index+1, report_length-index);
    imul rdi, 4
    mov [index], rdi
    imul rsi, 4
    mov [report_length], rsi

    mov rdi, temp_report
    add rdi, [index]

    mov rsi, temp_report
    add rsi, [index]
    add rsi, 4

    mov rdx, [report_length]
    sub rdx, [index]

    call memcpy

    ; report[report_length - 1] = 0;
    mov rax, [report_length]
    sub rax, 4
    mov dword [temp_report+rax], 0

    leave
    ret

    %pop

task2:
    %push read_input_context
    %stacksize flat64
    %assign %$localsize 0
    %local i:qword, \
           j:qword, \
           report:qword, \
           report_length:qword, \
           total:qword

    enter %$localsize, 0

    mov qword [i], 0
    mov qword [total], 0
.loop_start:
    mov rax, [i]
    cmp rax, [reports_count]
    jge .loop_end
    inc qword [i]

    ; copy current report into 
    imul rax, MAX_REPORT_LENGTH*4
    lea rbx, [reports+rax]
    mov [report], rbx

    ; compute the report length
    mov rdi, [report]
    call compute_report_length
    mov [report_length], rax

    mov qword [j], 0
.inner_loop_start:
    mov rax, [j]
    cmp rax, [report_length]
    jge .unsafe

    ; copy current report into temp
    mov rdi, temp_report
    mov rsi, [report]
    mov rdx, MAX_REPORT_LENGTH*4
    call memcpy

    ; remove element at index `j`
    mov rdi, [j]
    mov rsi, [report_length]
    call remove_index_from_temp_report

    ; check if report is safe
    mov rdi, temp_report
    call is_report_safe
    cmp rax, 1
    je .safe

    inc qword [j]
    jmp .inner_loop_start
.unsafe:
    jmp .loop_start

.safe:
    inc qword [total]
    jmp .loop_start

.loop_end:
    mov rax, qword [total]
    leave
    ret

_start:
    ; Read input
    call read_input

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

reports_count:
    dq 0
reports:
    times MAX_REPORT_COUNT*MAX_REPORT_LENGTH*4 dw 0
temp_report:
    times MAX_REPORT_LENGTH*4 dw 0

task1_result_str:
    db    "task1 = %d", 10, 0
task2_result_str:
    db    "task2 = %d", 10, 0

