; ============================================================================
; AK CODE Bootstrap Compiler — Windows PE Entry Point
; Uses Windows API via import tables for all OS interactions.
; ============================================================================

%include "macros.inc"

default rel

section .data
    default_input   db "test.ak", 0
    default_output  db "a.exe", 0

    err_no_file     db "ERROR: No input file specified. Usage: akc <source.ak> [-o output]", 10, 0
    err_cant_open   db "ERROR: Cannot open input file: ", 0
    err_cant_read   db "ERROR: Cannot read input file", 10, 0
    err_cant_write  db "ERROR: Cannot write output file", 10, 0
    err_no_memory   db "ERROR: Not enough memory for source file", 10, 0
    err_compile     db "ERROR: Compilation failed", 10, 0

    msg_compiling   db "Compiling ", 0
    msg_writing     db "Writing output to ", 0
    msg_done        db "Done. Compilation successful.", 10, 0

    msg_lex_done    db "[lex_ok]", 10, 0
    msg_parse_done  db "[parse_ok]", 10, 0
    msg_codegen_done db "[codegen_ok]", 10, 0

    src_buffer      dq 0
    src_size        dq 0

section .text
    global WinMain

; ============================================================================
; WinMain — PE entry point (called by CRT)
; Parameters:
;   rcx = hInstance
;   rdx = hPrevInstance
;   r8  = lpCmdLine
;   r9  = nCmdShow
; ============================================================================
WinMain:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 48

    ; Get command line
    extern  GetCommandLineA
    call    GetCommandLineA
    mov     r12, rax                    ; r12 = command line string

    ; Parse command line
    ; Skip program name (handle quoted paths with spaces)
    mov     r13, r12
    cmp     byte [r13], 34              ; double quote?
    jne     .skip_prog
    inc     r13                         ; skip opening quote
.skip_quote:
    mov     al, [r13]
    test    al, al
    jz      .no_args                    ; unterminated quote
    cmp     al, 34                      ; closing quote?
    je      .found_endquote
    inc     r13
    jmp     .skip_quote
.found_endquote:
    inc     r13                         ; skip closing quote
.skip_prog:
    mov     al, [r13]
    cmp     al, 32
    je      .found_space
    test    al, al
    jz      .no_args
    inc     r13
    jmp     .skip_prog
.found_space:
    inc     r13

    ; Skip spaces
.skip_spaces:
    mov     al, [r13]
    cmp     al, 32
    jne     .have_input
    inc     r13
    jmp     .skip_spaces

.have_input:
    ; Check if there's an input file
    mov     al, [r13]
    test    al, al
    jz      .no_args

    ; r13 points to first argument (input file)
    lea     r14, [default_input]
    lea     r15, [default_output]

    ; Parse first argument (may be quoted)
    lea     r14, [r13]                  ; pointer to args
    cmp     byte [r14], 34              ; starts with '"'?
    jne     .no_quote
    inc     r14                         ; skip opening quote
    mov     rbx, r14
.scan_close_quote:
    mov     al, [rbx]
    test    al, al
    jz      .arg_done
    cmp     al, 34                      ; closing '"'?
    je      .found_close_quote
    inc     rbx
    jmp     .scan_close_quote
.found_close_quote:
    mov     byte [rbx], 0               ; null-terminate at closing quote
    lea     r12, [rbx + 1]             ; rest of command line
    jmp     .skip_to_arg
.no_quote:
    mov     rbx, r14
.scan_arg_end:
    mov     al, [rbx]
    test    al, al
    jz      .arg_done
    cmp     al, 32
    je      .found_arg_space
    cmp     al, 9
    je      .found_arg_space
    inc     rbx
    jmp     .scan_arg_end
.found_arg_space:
    mov     byte [rbx], 0               ; null-terminate at space
    lea     r12, [rbx + 1]             ; rest of command line
    jmp     .skip_to_arg
.arg_done:
    ; First arg extends to end of command line; no -o flag possible
    mov     r12, rbx                    ; rbx points to null terminator
    jmp     .have_first_arg
.skip_to_arg:
    ; Skip spaces in rest of command line (-o search will start from here)
.have_first_arg:

    ; Look for -o in rest of command line
    xor     rbx, rbx
    mov     ARG1, r12
    call    find_flag_o
    test    rax, rax
    jz      .have_paths
    mov     r15, rax

.have_paths:
    ; Print compile message
    lea     ARG1, [msg_compiling]
    mov     ARG2, 10
    call    ak_print_str
    xor     ARG2, ARG2
    mov     ARG1, r14
    call    ak_print_str
    call    ak_print_newline

    ; Open source file: CreateFileA
    extern  CreateFileA
    mov     rcx, r14                    ; lpFileName
    mov     rdx, 0x80000000             ; GENERIC_READ
    mov     r8, 1                       ; FILE_SHARE_READ
    xor     r9, r9                      ; lpSecurityAttributes
    mov     qword [rsp + 32], 3         ; OPEN_EXISTING
    mov     qword [rsp + 40], 0x80      ; FILE_ATTRIBUTE_NORMAL
    mov     qword [rsp + 48], 0         ; hTemplateFile
    call    CreateFileA
    cmp     rax, -1                     ; INVALID_HANDLE_VALUE
    je      .open_failed
    mov     r12, rax                    ; r12 = file handle

    ; Get file size: GetFileSize
    extern  GetFileSize
    mov     rcx, r12
    xor     rdx, rdx
    call    GetFileSize
    mov     r14, rax                    ; r14 = file size

    ; Allocate buffer
    mov     ARG1, r14
    add     ARG1, 1
    call    ak_malloc
    test    rax, rax
    jz      .alloc_failed
    mov     rbx, rax                    ; rbx = buffer

    ; Read file: ReadFile
    extern  ReadFile
    mov     rcx, r12                    ; hFile
    mov     rdx, rbx                    ; lpBuffer
    mov     r8, r14                     ; nNumberOfBytesToRead
    lea     r9, [rsp + 40]              ; lpNumberOfBytesRead
    mov     qword [rsp + 32], 0         ; lpOverlapped
    call    ReadFile
    test    rax, rax
    jz      .read_failed

    ; Null-terminate buffer
    mov     byte [rbx + r14], 0

    ; Close file: CloseHandle
    extern  CloseHandle
    mov     rcx, r12
    call    CloseHandle

    ; Store source
    mov     [src_buffer], rbx
    mov     [src_size], r14

    ; ====================================================================
    ; Step 1: Lex
    ; ====================================================================
    mov     ARG1, rbx
    mov     ARG2, r14
    call    ak_lex
    test    rax, rax
    jz      .compile_failed
    mov     r12, rax
    lea     ARG1, [msg_lex_done]
    mov     ARG2, 0
    call    ak_print_str

    ; ====================================================================
    ; Step 2: Parse
    ; ====================================================================
    mov     ARG1, r12
    call    ak_parse
    test    rax, rax
    jz      .compile_failed
    mov     r13, rax
    lea     ARG1, [msg_parse_done]
    mov     ARG2, 0
    call    ak_print_str

    ; XXX PARSE OK XXX

    ; ====================================================================
    ; Step 3: Codegen
    ; ====================================================================
    mov     ARG1, r13
    call    ak_codegen
    test    rax, rax
    jz      .compile_failed
    mov     r14, rax

    lea     ARG1, [msg_codegen_done]
    mov     ARG2, 0
    call    ak_print_str

    ; ====================================================================
    ; Step 4: Wrap code+data in PE format and write output
    ; ====================================================================
    lea     ARG1, [msg_writing]
    mov     ARG2, 18
    call    ak_print_str
    xor     ARG2, ARG2
    mov     ARG1, r15
    call    ak_print_str
    call    ak_print_newline

    ; Buffer format from codegen: [code_size(u64), data_size(u64), code, data]
    mov     rbx, [r14]                  ; code_size
    mov     rcx, [r14 + 8]              ; data_size

    ; Call ak_build_pe(code_buf, code_size, data_buf, data_size) -> PE binary
    mov     ARG1, r14
    add     ARG1, 16                    ; code starts at offset 16
    mov     ARG2, rbx                   ; code_size
    mov     ARG3, r14
    add     ARG3, 16
    add     ARG3, rbx                   ; data starts after code
    mov     ARG4, rcx                   ; data_size
    call    ak_build_pe
    test    rax, rax
    jz      .write_failed
    mov     r14, rax                    ; r14 = PE buffer (first 8 bytes = total size)

    ; Create output file: CreateFileA
    mov     rcx, r15                    ; lpFileName
    mov     rdx, 0x40000000             ; GENERIC_WRITE
    xor     r8, r8                      ; no share
    xor     r9, r9                      ; lpSecurityAttributes
    mov     qword [rsp + 32], 2         ; CREATE_ALWAYS
    mov     qword [rsp + 40], 0x80      ; FILE_ATTRIBUTE_NORMAL
    mov     qword [rsp + 48], 0         ; hTemplateFile
    call    CreateFileA
    cmp     rax, -1
    je      .write_failed
    mov     r15, rax

    ; Write PE binary
    mov     rcx, r15
    mov     rdx, r14
    add     rdx, 8                      ; skip size header
    mov     r8, [r14]                   ; total PE size
    lea     r9, [rsp + 40]              ; bytes written
    mov     qword [rsp + 32], 0
    call    WriteFile

    ; Close output
    mov     rcx, r15
    call    CloseHandle

    ; Print success
    lea     ARG1, [msg_done]
    mov     ARG2, 28
    call    ak_print_str

    ; Exit
    xor     ARG1, ARG1
    call    ak_exit

.no_args:
    lea     ARG1, [err_no_file]
    mov     ARG2, 66
    call    ak_print_str
    mov     ARG1, 1
    call    ak_exit

.open_failed:
    lea     ARG1, [err_cant_open]
    mov     ARG2, 31
    call    ak_print_str
    xor     ARG2, ARG2
    mov     ARG1, r14
    call    ak_print_str
    call    ak_print_newline
    mov     ARG1, 1
    call    ak_exit

.read_failed:
    lea     ARG1, [err_cant_read]
    mov     ARG2, 27
    call    ak_print_str
    mov     ARG1, 1
    call    ak_exit

.alloc_failed:
    lea     ARG1, [err_no_memory]
    mov     ARG2, 39
    call    ak_print_str
    mov     ARG1, 1
    call    ak_exit

.write_failed:
    lea     ARG1, [err_cant_write]
    mov     ARG2, 28
    call    ak_print_str
    mov     ARG1, 1
    call    ak_exit

.compile_failed:
    lea     ARG1, [err_compile]
    mov     ARG2, 23
    call    ak_print_str
    mov     ARG1, 1
    call    ak_exit

; ============================================================================
; find_flag_o — search command line for -o flag
; Takes ARG1 (rcx) = command line string
; Returns pointer to output path in rax, or 0 if not found
; ============================================================================
find_flag_o:
    push    rbx
    push    r12
    mov     r12, ARG1
.loop:
    mov     al, [r12]
    test    al, al
    jz      .not_found
    cmp     al, '-'
    jne     .next
    ; Check if next two chars are "o" and space
    cmp     byte [r12+1], 'o'
    jne     .next
    cmp     byte [r12+2], 32
    jne     .next_if_end
    ; Found -o, skip to next arg
    lea     r12, [r12+3]
    jmp     .skip_spaces2
.next_if_end:
    cmp     byte [r12+2], 0
    je      .not_found
.next:
    inc     r12
    jmp     .loop
.skip_spaces2:
    mov     al, [r12]
    test    al, al
    jz      .not_found
    cmp     al, 32
    jne     .found
    inc     r12
    jmp     .skip_spaces2
.found:
    mov     rax, r12
    pop     r12
    pop     rbx
    ret
.not_found:
    xor     rax, rax
    pop     r12
    pop     rbx
    ret

; ============================================================================
; External references to compiler stages
; ============================================================================
extern ak_lex
extern ak_parse
extern ak_codegen
extern ak_malloc
extern ak_print_str
extern ak_print_newline
extern ak_print_num
extern ak_exit
extern ak_strcmp
extern ak_strlen
extern WriteFile
extern ak_build_pe
