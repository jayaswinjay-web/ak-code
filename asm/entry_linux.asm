; ============================================================================
; AK CODE Bootstrap Compiler — Linux ELF Entry Point
; Reads source file path from argv[1], loads it, calls lexer/parser/codegen,
; writes output binary.
; ============================================================================

%include "macros.inc"

default rel

section .data
    ; Default filenames
    default_input   db "test.ak", 0
    default_output  db "a.out", 0

    ; Error messages
    err_no_file     db "ERROR: No input file specified. Usage: akc <source.ak> [-o output]", 10, 0
    err_cant_open   db "ERROR: Cannot open input file: ", 0
    err_cant_read   db "ERROR: Cannot read input file", 10, 0
    err_cant_write  db "ERROR: Cannot write output file", 10, 0
    err_no_memory   db "ERROR: Not enough memory for source file", 10, 0
    err_compile     db "ERROR: Compilation failed", 10, 0

    ; Status messages
    msg_compiling       db "Compiling ", 0
    msg_writing         db "Writing output to ", 0
    msg_done            db "Done. Compilation successful.", 10, 0
    msg_docs_generating db "Generating documentation for project at ", 0

    ; Temp buffers
    src_path        times 4096 db 0
    out_path        times 4096 db 0
    src_buffer      dq 0
    src_size        dq 0

section .text
    global _start

; ============================================================================
; _start — entry point
; Stack layout at entry:
;   [rsp]     = argc
;   [rsp+8]   = argv[0]
;   [rsp+16]  = argv[1]
;   ...
; ============================================================================
_start:
    ; Save argc and argv
    pop     rcx                         ; argc
    mov     r12, rcx                    ; r12 = argc
    mov     r13, rsp                    ; r13 = argv ptr

    ; Default paths
    lea     r14, [default_input]
    lea     r15, [default_output]

    ; Parse arguments
    cmp     r12, 1
    jle     .no_args

    mov     rdi, [r13 + 8]              ; argv[1]
    lea     r14, [src_path]
    call    ak_strcpy
    mov     r14, rdi                    ; restore source path

    ; Check for "docs" command
    mov     rdi, r14                    ; r14 = argv[1] (see ak_strcpy convention above)
    lea     rsi, [.flag_docs]
    call    ak_strcmp
    test    rax, rax
    jnz     .not_docs

    ; "docs" command: akc docs [path]
    lea     r14, [.default_docs_path]
    cmp     r12, 2
    jle     .have_docs_path
    mov     rdi, [r13 + 16]             ; argv[2]
    lea     r14, [src_path]
    call    ak_strcpy
    mov     r14, rdi

.have_docs_path:
    lea     ARG1, [msg_docs_generating]
    mov     ARG2, 0
    call    ak_print_str
    mov     ARG1, r14
    call    ak_print_str
    call    ak_print_newline

    mov     ARG1, r14
    call    ak_docs_generate

    xor     ARG1, ARG1
    call    ak_exit

.not_docs:
    ; Check for -o flag
    cmp     r12, 3
    jl      .have_input
    mov     rdi, [r13 + 16]             ; argv[2]
    lea     rsi, [.flag_o]
    call    ak_strcmp
    test    rax, rax
    jnz     .have_input
    mov     rdi, [r13 + 24]             ; argv[3]
    lea     r15, [out_path]
    call    ak_strcpy
    mov     r15, rdi

.have_input:
    ; Print compile message
    lea     ARG1, [msg_compiling]
    mov     ARG2, 10
    call    ak_print_str
    mov     ARG1, r14
    call    ak_print_str
    call    ak_print_newline

    ; Open source file
    mov     ARG1, r14
    xor     ARG2, ARG2                  ; O_RDONLY = 0
    call    ak_open
    cmp     rax, -1
    je      .open_failed
    mov     r12, rax                    ; r12 = fd

    ; Get file size
    mov     ARG1, r12
    xor     ARG2, ARG2                  ; SEEK_SET
    xor     ARG3, ARG3
    call    ak_lseek
    mov     r14, rax                    ; r14 = file size

    ; Seek back to start
    mov     ARG1, r12
    xor     ARG2, ARG2
    xor     ARG3, ARG2
    call    ak_lseek

    ; Allocate buffer for source
    mov     ARG1, r14
    add     ARG1, 1                     ; +1 for null terminator
    call    ak_malloc
    test    rax, rax
    jz      .alloc_failed
    mov     rbx, rax                    ; rbx = buffer

    ; Read source file
    mov     ARG1, r12
    mov     ARG2, rbx
    mov     ARG3, r14
    call    ak_read
    cmp     rax, 0
    jl      .read_failed

    ; Null-terminate
    mov     byte [rbx + r14], 0

    ; Close source file
    mov     ARG1, r12
    call    ak_close

    ; Store source buffer and size
    mov     [src_buffer], rbx
    mov     [src_size], r14

    ; ====================================================================
    ; Step 1: Lex the source
    ; ====================================================================
    mov     ARG1, rbx                   ; source text
    mov     ARG2, r14                   ; source length
    call    ak_lex
    test    rax, rax
    jz      .compile_failed
    mov     r12, rax                    ; r12 = token array

    ; ====================================================================
    ; Step 2: Parse tokens into AST
    ; ====================================================================
    mov     ARG1, r12                   ; tokens
    call    ak_parse
    test    rax, rax
    jz      .compile_failed
    mov     r13, rax                    ; r13 = AST root

    ; ====================================================================
    ; Step 3: Generate code from AST
    ; ====================================================================
    mov     ARG1, r13                   ; AST root
    call    ak_codegen
    test    rax, rax
    jz      .compile_failed
    mov     r14, rax                    ; r14 = code buffer

    ; ====================================================================
    ; Step 4: Write output binary
    ; ====================================================================
    lea     ARG1, [msg_writing]
    mov     ARG2, 17
    call    ak_print_str
    mov     ARG1, r15
    call    ak_print_str
    call    ak_print_newline

    mov     ARG1, r15
    mov     ARG2, 0x441                 ; O_WRONLY | O_CREAT | O_TRUNC
    mov     r10, 0x1B4                  ; mode = 0644
    call    ak_open
    cmp     rax, -1
    je      .write_failed
    mov     r15, rax                    ; r15 = out_fd

    ; Buffer format from codegen: [code_size(u64), data_size(u64), code, data]
    mov     rbx, [r14]                  ; code_size
    mov     rcx, [r14 + 8]             ; data_size

    ; Wrap code+data in ELF format via linker_glue
    ; ak_build_elf(code_buf, code_size, data_buf, data_size) -> ELF binary with size header
    mov     ARG1, r14
    add     ARG1, 16                   ; code starts at offset 16
    mov     ARG2, rbx                  ; code_size
    mov     ARG3, r14
    add     ARG3, 16
    add     ARG3, rbx                  ; data starts after code
    mov     ARG4, rcx                  ; data_size
    call    ak_build_elf
    test    rax, rax
    jz      .write_failed
    mov     r14, rax                   ; r14 = ELF buffer (first 8 bytes = total size)

    ; Write the ELF binary
    mov     ARG1, r15
    mov     ARG2, r14
    add     ARG2, 8                    ; skip size header
    mov     ARG3, [r14]                ; total ELF size
    call    ak_write

    ; Close output file
    mov     ARG1, r15
    call    ak_close

    ; Print success
    lea     ARG1, [msg_done]
    mov     ARG2, 28
    call    ak_print_str

    ; Exit success
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
    mov     ARG2, 24
    call    ak_print_str
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
    mov     ARG2, 34
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

.flag_o db "-o", 0
.flag_docs db "docs", 0
.default_docs_path db ".", 0

; ============================================================================
; System call wrappers (Linux)
; ============================================================================
; ak_open(path, flags, mode) -> fd
ak_open:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2
    mov     rbx, r10
    mov     rax, 2                      ; sys_open
    mov     ARG1, r12
    mov     ARG2, r13
    mov     ARG3, rbx
    syscall
    pop     r13
    pop     r12
    pop     rbx
    ret

; ak_read(fd, buf, count) -> bytes read
ak_read:
    mov     rax, 0                      ; sys_read
    syscall
    ret

; ak_write(fd, buf, count) -> bytes written
ak_write:
    mov     rax, 1                      ; sys_write
    syscall
    ret

; ak_close(fd)
ak_close:
    mov     rax, 3                      ; sys_close
    syscall
    ret

; ak_lseek(fd, offset, whence) -> position
ak_lseek:
    mov     rax, 8                      ; sys_lseek
    syscall
    ret

; ak_strcpy(dst, src) — copy null-terminated string
ak_strcpy:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2
.loop:
    mov     al, [r13]
    mov     [r12], al
    test    al, al
    jz      .done
    inc     r12
    inc     r13
    jmp     .loop
.done:
    pop     r13
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
extern ak_build_elf
extern ak_docs_generate
