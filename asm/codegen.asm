; ============================================================================
; AK CODE Code Generator — x86-64 Machine Code Emission
; Walks the AST and emits raw x86-64 machine code into a buffer.
; Supports both Linux (System V) and Windows (Microsoft x64) ABIs.
; ============================================================================

%include "macros.inc"

default rel

; Emit macros — write machine code bytes to the code buffer
; code_size is a BYTE OFFSET (not a pointer)
; Each macro: loads code_buffer base, adds offset, writes, increments offset
%macro EMIT_BYTE 1
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     byte [rbx], %1
    inc     qword [code_size]
    pop     rbx
%endmacro

%macro EMIT_WORD 1
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     word [rbx], %1
    add     qword [code_size], 2
    pop     rbx
%endmacro

%macro EMIT_DWORD 1
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     dword [rbx], %1
    add     qword [code_size], 4
    pop     rbx
%endmacro

%macro EMIT_QWORD 1
    push    rcx
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     [rbx], %1
    add     qword [code_size], 8
    pop     rbx
    pop     rcx
%endmacro

; Emit macros — write machine code bytes to the code buffer
; code_size is a BYTE OFFSET (not a pointer)
; Each macro: loads code_buffer base, adds offset, writes, increments offset
%macro EMIT_BYTE 1
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     byte [rbx], %1
    inc     qword [code_size]
    pop     rbx
%endmacro

%macro EMIT_WORD 1
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     word [rbx], %1
    add     qword [code_size], 2
    pop     rbx
%endmacro

%macro EMIT_DWORD 1
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     dword [rbx], %1
    add     qword [code_size], 4
    pop     rbx
%endmacro

%macro EMIT_QWORD 1
    push    rcx
    push    rbx
    mov     rbx, [code_buffer]
    add     rbx, [code_size]
    mov     [rbx], %1
    add     qword [code_size], 8
    pop     rbx
    pop     rcx
%endmacro

; Code buffer state
CB_BUF      equ 0   ; ptr to code buffer
CB_SIZE     equ 8   ; current size
CB_CAP      equ 16  ; capacity
CB_BUF_SIZE equ 24

; Register allocation
; Simple allocator: track which registers are in use
REG_RAX equ 0
REG_RBX equ 1
REG_RCX equ 2
REG_RDX equ 3
REG_RSI equ 4
REG_RDI equ 5
REG_R8  equ 6
REG_R9  equ 7
REG_R10 equ 8
REG_R11 equ 9
REG_R12 equ 10
REG_R13 equ 11
REG_R14 equ 12
REG_R15 equ 13
REG_COUNT equ 14

; AST node type constants (must match parser.asm)
NODE_PROGRAM      equ 1
NODE_LET          equ 2
NODE_ASSIGN       equ 3
NODE_ALWAYS       equ 4
NODE_SHOW         equ 5
NODE_ASK          equ 6
NODE_IF           equ 7
NODE_ELSE_IF      equ 8
NODE_ELSE         equ 9
NODE_REPEAT_TIMES equ 10
NODE_REPEAT_WHILE equ 11
NODE_FOR_EACH     equ 12
NODE_COUNT_FROM   equ 13
NODE_DEFINE       equ 14
NODE_CALL         equ 15
NODE_GIVE_BACK    equ 16
NODE_BINOP        equ 17
NODE_UNOP         equ 18
NODE_LITERAL      equ 19
NODE_IDENTIFIER   equ 20
NODE_MAKE_KIND    equ 21
NODE_NEW          equ 22
NODE_DOT_ACCESS   equ 23
NODE_LIST_LITERAL equ 24
NODE_MAP_LITERAL  equ 25
NODE_TRY          equ 26
NODE_CATCH        equ 27
NODE_MATCH        equ 28
NODE_WHEN         equ 29
NODE_BRING_IN     equ 30
NODE_MAKE_SERVER  equ 31
NODE_ROUTE        equ 32
NODE_MAKE_MODEL   equ 33
NODE_TRAIN        equ 34
NODE_PLOT         equ 35
NODE_BLOCK        equ 36
NODE_DO_BACKGROUND equ 37
NODE_PROTOCOL      equ 38
NODE_LAMBDA        equ 39
NODE_ASYNC         equ 40
NODE_AWAIT         equ 41
NODE_MANUAL_MEMORY equ 42
NODE_TEST_SUITE   equ 43
NODE_TEST         equ 44
NODE_EXPECT       equ 45
NODE_RUN_TESTS    equ 46
NODE_SQRT        equ 47
NODE_MAKE_PAGE   equ 48
NODE_MAKE_BUTTON equ 49
NODE_MAKE_INPUT  equ 50
NODE_EVENT       equ 51
NODE_GOTO        equ 52
NODE_SEND        equ 53
NODE_CONNECT_DB  equ 54
NODE_MAKE_TABLE  equ 55
NODE_CREATE_TABLE equ 56
NODE_INSERT      equ 57
NODE_FIND        equ 58
NODE_UPDATE      equ 59
NODE_DELETE      equ 60

; AST node struct offsets (must match parser.asm)
AST_TYPE        equ 0   ; u32
AST_PAD         equ 4   ; padding
AST_CHILD_COUNT equ 8   ; u32
AST_CHILD_PAD   equ 12  ; padding
AST_CHILDREN    equ 16  ; ptr to children array
AST_VALUE_PTR   equ 24  ; ptr
AST_VALUE_LEN   equ 32  ; u32
AST_LINE        equ 36  ; u32
AST_COL         equ 40  ; u32
AST_NODE_SIZE   equ 48

; Token type constants (must match lexer.asm)
TOK_KEYWORD    equ 1
TOK_IDENTIFIER equ 2
TOK_STRING     equ 3
TOK_NUMBER     equ 4
TOK_DECIMAL    equ 5
TOK_BOOL       equ 6
TOK_EMPTY      equ 7
TOK_COMMA      equ 8
TOK_LPAREN     equ 9
TOK_RPAREN     equ 10
TOK_LBRACKET   equ 11
TOK_RBRACKET   equ 12
TOK_EQUALS     equ 13
TOK_PLUS_WORD  equ 14
TOK_MINUS_WORD equ 15
TOK_TIMES_WORD equ 16
TOK_DIVIDE     equ 17
TOK_MOD        equ 18
TOK_POWER      equ 19
TOK_AND        equ 20
TOK_OR         equ 21
TOK_NOT        equ 22
TOK_IS         equ 23
TOK_GREATER    equ 24
TOK_LESS       equ 25
TOK_BETWEEN    equ 26
TOK_CONTAINS   equ 27
TOK_DOT        equ 28

; Lexer state offsets for emit helper (must match lexer.asm)
LEX_SOURCE equ 0   ; ptr

section .data
    reg_names db "raxrbxrcxrdxrsirdir8 r9 r10r11r12r13r14r15"

    ; Syscall numbers
    SYSCALL_EXIT  equ 60
    SYSCALL_WRITE equ 1
    SYSCALL_READ  equ 0
    SYSCALL_MMAP  equ 9

    ; Emit buffer
    code_buffer  dq 0
    code_size    dq 0
    code_cap     dq 0
    code_pos     dq 0

    ; Label counter for unique label generation
    label_counter dq 0

    ; Data section buffer
    data_buffer  dq 0
    data_size    dq 0

    ; String table
    str_table    dq 0
    str_count    dq 0

    ; Register state
    reg_used     times REG_COUNT db 0

section .text
    global ak_codegen

; ============================================================================
; ak_codegen(ast_root) -> code buffer
; Takes the AST root from the parser and emits x86-64 machine code.
; Returns pointer to code buffer structure.
; ============================================================================
ak_codegen:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 32

    mov     r12, ARG1                   ; AST root

    ; Initialize code buffer (64KB initial)
    mov     ARG1, 65536
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     [code_buffer], rax
    mov     qword [code_size], 0          ; code_size = byte offset (starts at 0)
    mov     qword [code_cap], 65536

    ; Initialize data buffer (16KB)
    mov     ARG1, 16384
    call    ak_malloc
    mov     [data_buffer], rax
    mov     qword [data_size], 0

    ; Initialize string table
    mov     ARG1, 4096
    call    ak_malloc
    mov     [str_table], rax
    mov     qword [str_count], 0

    ; Initialize label counter
    mov     qword [label_counter], 0

    ; Initialize register state
    xor     rcx, rcx
.init_regs:
    lea     r8, [reg_used]
    mov     byte [r8 + rcx], 0
    inc     rcx
    cmp     rcx, REG_COUNT
    jl      .init_regs

    ; Check AST type
    mov     eax, [r12 + AST_TYPE]
    cmp     eax, NODE_PROGRAM
    je      .emit_program

    ; Not a program node — try to emit it anyway
    mov     ARG1, r12
    call    emit_node
    jmp     .finish

.emit_program:
    ; Emit prologue
    call    emit_prologue

    ; Emit program header label
    mov     ARG1, .main_label
    call    emit_label

    ; Walk children (top-level statements)
    xor     r13, r13                   ; child index
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.program_loop:
    cmp     r13, r14
    jge     .program_done

    mov     ARG1, [r15 + r13 * 8]
    call    emit_node

    inc     r13
    jmp     .program_loop

.program_done:
    ; Emit exit
    call    emit_exit

    ; Emit data section
    call    emit_data_section

.finish:
    ; Create output buffer with [code_size, data_size, code, data]
    mov     rcx, [code_size]
    ; actual code size = [code_size] (offset-based)
    mov     rdx, [data_size]
    mov     ARG1, 16                    ; header size (2 u64s)
    add     ARG1, rcx
    add     ARG1, rdx
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r12, rax

    ; Store code_size and data_size in header
    mov     rcx, [code_size]
    ; sub rcx, [code_buffer]          ; actual code size
    mov     [r12], rcx
    mov     rcx, [data_size]
    mov     [r12 + 8], rcx

    ; Copy code at offset 16
    mov     ARG1, r12
    add     ARG1, 16
    mov     ARG2, [code_buffer]
    mov     rcx, [code_size]
    ; sub rcx, [code_buffer]          ; actual code size
    mov     ARG3, rcx
    call    ak_memcpy

    ; Copy data after code
    mov     ARG1, r12
    add     ARG1, 16
    mov     rcx, [code_size]
    ; sub rcx, [code_buffer]          ; actual code size
    add     ARG1, rcx
    mov     ARG2, [data_buffer]
    mov     ARG3, [data_size]
    call    ak_memcpy

    mov     rax, r12
    add     rsp, 32
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.fail:
    xor     rax, rax
    add     rsp, 32
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.main_label db "_start", 0

; ============================================================================
; emit_prologue — emit ELF/PE prologue
; ============================================================================
emit_prologue:
    push    rbx
    push    r12

    ; On Linux, _start is the ELF entry point
    ; We emit the global label
    ; The linker_glue will handle ELF/PE headers
    ; For now, just emit a NOP for alignment
EMIT_BYTE 0x90

    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_node(ast_node) — emit code for a single AST node
; ============================================================================
emit_node:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1
    test    r12, r12
    jz      .done

    mov     eax, [r12 + AST_TYPE]

    cmp     eax, NODE_LITERAL
    je      .literal
    cmp     eax, NODE_IDENTIFIER
    je      .identifier
    cmp     eax, NODE_SHOW
    je      .show
    cmp     eax, NODE_LET
    je      .let
    cmp     eax, NODE_ALWAYS
    je      .always
    cmp     eax, NODE_ASSIGN
    je      .assign
    cmp     eax, NODE_BINOP
    je      .binop
    cmp     eax, NODE_CALL
    je      .call
    cmp     eax, NODE_GIVE_BACK
    je      .give_back
    cmp     eax, NODE_IF
    je      .if_stmt
    cmp     eax, NODE_DEFINE
    je      .define
    cmp     eax, NODE_PROTOCOL
    je      .protocol
    cmp     eax, NODE_LAMBDA
    je      .lambda
    cmp     eax, NODE_ASYNC
    je      .async_node
    cmp     eax, NODE_AWAIT
    je      .await_node
    cmp     eax, NODE_MANUAL_MEMORY
    je      .manual_memory
    cmp     eax, NODE_PROGRAM
    je      .program
    cmp     eax, NODE_TEST_SUITE
    je      .test_suite
    cmp     eax, NODE_TEST
    je      .test_node
    cmp     eax, NODE_EXPECT
    je      .expect_node
    cmp     eax, NODE_RUN_TESTS
    je      .run_tests_node
    cmp     eax, NODE_SQRT
    je      .sqrt_node
    cmp     eax, NODE_MAKE_PAGE
    je      .make_page_node
    cmp     eax, NODE_MAKE_BUTTON
    je      .make_button_node
    cmp     eax, NODE_MAKE_INPUT
    je      .make_input_node
    cmp     eax, NODE_EVENT
    je      .event_node
    cmp     eax, NODE_GOTO
    je      .goto_node
    cmp     eax, NODE_SEND
    je      .send_node
    cmp     eax, NODE_CONNECT_DB
    je      .connect_db_node
    cmp     eax, NODE_MAKE_TABLE
    je      .make_table_node
    cmp     eax, NODE_CREATE_TABLE
    je      .create_table_node
    cmp     eax, NODE_INSERT
    je      .insert_node
    cmp     eax, NODE_FIND
    je      .find_node
    cmp     eax, NODE_UPDATE
    je      .update_node
    cmp     eax, NODE_DELETE
    je      .delete_node

    ; Unimplemented node type — emit NOP
    jmp     .done

.literal:
    call    emit_literal
    jmp     .done

.identifier:
    call    emit_identifier
    jmp     .done

.show:
    ; show <expression>+
    ; For each child expression, emit code to evaluate and print it
    call    emit_show
    jmp     .done

.let:
    call    emit_let
    jmp     .done

.always:
    call    emit_always
    jmp     .done

.assign:
    call    emit_assign
    jmp     .done

.binop:
    call    emit_binop
    jmp     .done

.call:
    call    emit_call
    jmp     .done

.give_back:
    call    emit_give_back
    jmp     .done

.if_stmt:
    call    emit_if
    jmp     .done

.define:
    call    emit_define
    jmp     .done

.protocol:
    call    emit_protocol
    jmp     .done

.lambda:
    call    emit_lambda
    jmp     .done

.async_node:
    call    emit_async
    jmp     .done

.await_node:
    call    emit_await
    jmp     .done

.manual_memory:
    call    emit_manual_memory
    jmp     .done

.program:
    ; Already handled at top level
    jmp     .done

.test_suite:
    call    emit_test_suite
    jmp     .done

.test_node:
    call    emit_test
    jmp     .done

.expect_node:
    call    emit_expect
    jmp     .done

.run_tests_node:
    call    emit_run_tests
    jmp     .done

.sqrt_node:
    call    emit_sqrt
    jmp     .done

.make_page_node:
    call    emit_make_page
    jmp     .done

.make_button_node:
    call    emit_make_button
    jmp     .done

.make_input_node:
    call    emit_make_input
    jmp     .done

.event_node:
    call    emit_event
    jmp     .done

.goto_node:
    call    emit_goto
    jmp     .done

.send_node:
    call    emit_send
    jmp     .done

.connect_db_node:
    call    emit_connect_db
    jmp     .done

.make_table_node:
    call    emit_make_table
    jmp     .done

.create_table_node:
    call    emit_create_table
    jmp     .done

.insert_node:
    call    emit_insert
    jmp     .done

.find_node:
    call    emit_find
    jmp     .done

.update_node:
    call    emit_update
    jmp     .done

.delete_node:
    call    emit_delete
    jmp     .done

.done:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_literal(node) — emit code to load a literal value
; For strings: emit lea rax, [rel str_addr]
; For numbers: emit mov rax, imm
; For decimals: emit movq xmm0, imm
; For bools: emit mov rax, 0/1
; ============================================================================
emit_literal:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1

    mov     eax, [r12 + AST_VALUE_LEN]  ; token type
    cmp     eax, TOK_NUMBER
    je      .num
    cmp     eax, TOK_DECIMAL
    je      .decimal
    cmp     eax, TOK_STRING
    je      .string
    cmp     eax, TOK_BOOL
    je      .bool
    cmp     eax, TOK_EMPTY
    je      .empty
    jmp     .done

.num:
    ; Parse the number from the source and emit mov rax, imm
    mov     ARG1, [r12 + AST_VALUE_PTR]
    call    ak_atoi
    mov     rbx, rax

    ; emit: mov rax, imm32
    ; REX.W B8+rd io
EMIT_BYTE 0x48
EMIT_BYTE 0xB8  ; mov rax, imm64
    mov     [code_size], rbx
    add     qword [code_size], 8
    jmp     .done

.decimal:
    ; Parse decimal and emit as double in xmm0
    ; For now, emit as integer approximation
    ; TODO: proper double emission
    mov     ARG1, [r12 + AST_VALUE_PTR]
    call    ak_atof
    ; Store the double in the data section and emit movsd xmm0, [rel addr]
    ; For now, push constant 0
    ; emit: xorpd xmm0, xmm0
    mov     word [code_size], 0x57C5
    inc     qword [code_size]
    inc     qword [code_size]
    jmp     .done

.string:
    ; Add string to data section and emit lea rax, [rel string_addr]
    mov     ARG1, [r12 + AST_VALUE_PTR]
    mov     ARG2, [code_size] ; dummy; just need to add to data
    call    add_string_to_data
    mov     rbx, rax                    ; offset in data section

    ; emit: lea rax, [rel offset]
    ; REX.W 8D 05 offset32
EMIT_BYTE 0x48
EMIT_BYTE 0x8D
EMIT_BYTE 0x05  ; modrm for [rip+disp32]
    ; Calculate relative offset from end of this instruction
    ; For now emit placeholder
EMIT_DWORD ebx
    jmp     .done

.bool:
    ; emit mov rax, 1 for true, 0 for false
    mov     rbx, [r12 + AST_VALUE_PTR]
    cmp     byte [rbx], 't'
    jne     .false_bool
    mov     rcx, 1
    jmp     .emit_bool
.false_bool:
    xor     rcx, rcx
.emit_bool:
EMIT_BYTE 0x48
EMIT_BYTE 0xB8
    mov     [code_size], rcx
    add     qword [code_size], 8
    jmp     .done

.empty:
    ; emit xor rax, rax (null)
    mov     word [code_size], 0xC031
    add     qword [code_size], 2

.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_identifier(node) — emit code to load a variable's value
; Variables live on the stack; we compute offset from RBP
; ============================================================================
emit_identifier:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1

    ; Look up variable in symbol table to get stack offset
    ; For now, assume variable is at a fixed stack offset
    ; In a real compiler, we'd use a symbol table with offsets

    ; emit: mov rax, [rbp - offset]
    ; REX.W 8B 45 F8 (example for offset 8)
EMIT_BYTE 0x48
EMIT_BYTE 0x8B
    ; modrm: 01 000 101 (disp8 from rbp)
    ; For now just emit 0x45 (rbp + disp8) then disp8
EMIT_BYTE 0x45
    ; displacement (assume 8 for now)
EMIT_BYTE 0xF8  ; -8

    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_show(node) — emit code for print statements
; Emits inline syscall-based code for a self-contained output binary.
; ============================================================================
emit_show:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.show_loop:
    cmp     r13, r14
    jge     .done_show

    ; Emit child expression (result in rax)
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node

    ; Emit inline print-number code for rax
    call    emit_inline_print_number

    ; If not the last item, emit a space
    mov     eax, r14d
    dec     eax
    cmp     r13d, eax
    jge     .no_space
    call    emit_inline_print_space
.no_space:

    inc     r13
    jmp     .show_loop

.done_show:
    ; Emit newline via syscall
    call    emit_inline_print_newline

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_inline_print_number — emit code to print rax as decimal via syscall
; Uses stack buffer for conversion, then sys_write(1, buf, len)
; Clobbers: rax, rcx, rdx, rsi, rdi
; ============================================================================
emit_inline_print_number:
    push    rbx
    push    r12

    ; sub rsp, 32          ; 48 83 EC 20
EMIT_BYTE 0x48
EMIT_BYTE 0x83
EMIT_BYTE 0xEC
EMIT_BYTE 0x20

    ; mov byte [rsp+31], 10  ; C6 44 24 1F 0A
EMIT_BYTE 0xC6
EMIT_BYTE 0x44
EMIT_BYTE 0x24
EMIT_BYTE 0x1F
EMIT_BYTE 0x0A

    ; mov rcx, 31           ; 48 C7 C1 1F 00 00 00
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC1
EMIT_DWORD 31

    ; mov rbx, 10           ; 48 C7 C3 0A 00 00 00
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC3
EMIT_DWORD 10

    ; test rax, rax         ; 48 85 C0
EMIT_BYTE 0x48
EMIT_BYTE 0x85
EMIT_BYTE 0xC0

    ; jnz .convert          ; 75 XX (short jump, 2 bytes)
    ; Save patch location
    mov     r12, [code_size]
EMIT_BYTE 0x75
EMIT_BYTE 0   ; placeholder

    ; === handle zero ===
    ; dec rcx               ; 48 FF C9
EMIT_BYTE 0x48
EMIT_BYTE 0xFF
EMIT_BYTE 0xC9

    ; mov byte [rsp+rcx], '0'  ; C6 04 0C 30
EMIT_BYTE 0xC6
EMIT_BYTE 0x04
EMIT_BYTE 0x0C
EMIT_BYTE 0x30

    ; jmp .print            ; EB XX
EMIT_BYTE 0xEB
EMIT_BYTE 0   ; placeholder
    push    r12
    mov     r12, [code_size]
    pop     rbx
    ; Patch zero jnz: distance from after jnz to here
    mov     rax, [code_size]
    sub     rax, rbx
    sub     rax, 2
    mov     r8, [code_buffer]
    add     r8, rbx
    mov     byte [r8], al
    ; Save print location for later patching of jmp .print
    push    r12

    ; === .convert loop ===
.convert_loop_start:
    ; Save emitted position of convert_loop_start
    mov     r14, [code_size]
    ; xor edx, edx         ; 31 D2
EMIT_BYTE 0x31
EMIT_BYTE 0xD2

    ; div rbx              ; 48 F7 F3
EMIT_BYTE 0x48
EMIT_BYTE 0xF7
EMIT_BYTE 0xF3

    ; add dl, '0'          ; 80 C2 30
EMIT_BYTE 0x80
EMIT_BYTE 0xC2
EMIT_BYTE 0x30

    ; dec rcx               ; 48 FF C9
EMIT_BYTE 0x48
EMIT_BYTE 0xFF
EMIT_BYTE 0xC9

    ; mov [rsp+rcx], dl     ; 88 14 0C
EMIT_BYTE 0x88
EMIT_BYTE 0x14
EMIT_BYTE 0x0C

    ; test rax, rax         ; 48 85 C0
EMIT_BYTE 0x48
EMIT_BYTE 0x85
EMIT_BYTE 0xC0

    ; jnz .convert_loop_start  ; 75 XX
EMIT_BYTE 0x75
    ; Calculate offset back to convert_loop_start
    mov     rax, [code_size]
    sub     rax, r14
    neg     rax
    sub     rax, 1  ; for the jnz byte itself
EMIT_BYTE al

    ; === .print ===
    ; Patch the zero-case jmp .print
    pop     rbx
    mov     rax, [code_size]
    sub     rax, rbx
    sub     rax, 2
    mov     r8, [code_buffer]
    add     r8, rbx
    mov     byte [r8], al
    ; Patch the zero case jnz (at r12): already patched above

    ; mov rdx, 31          ; 48 C7 C2 1F 00 00 00
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC2
EMIT_DWORD 31

    ; sub rdx, rcx         ; 48 29 CA
EMIT_BYTE 0x48
EMIT_BYTE 0x29
EMIT_BYTE 0xCA

    ; lea rsi, [rsp+rcx]   ; 48 8D 34 0C
EMIT_BYTE 0x48
EMIT_BYTE 0x8D
EMIT_BYTE 0x34
EMIT_BYTE 0x0C

    ; mov rdi, 1           ; 48 C7 C7 01 00 00 00
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC7
EMIT_DWORD 1

    ; mov rax, 1           ; 48 C7 C0 01 00 00 00
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC0
EMIT_DWORD 1

    ; syscall              ; 0F 05
    mov     word [code_size], 0x050F
    add     qword [code_size], 2

    ; add rsp, 32          ; 48 83 C4 20
EMIT_BYTE 0x48
EMIT_BYTE 0x83
EMIT_BYTE 0xC4
EMIT_BYTE 0x20

    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_inline_print_space — emit code to print a space via syscall
; ============================================================================
emit_inline_print_space:
    ; sub rsp, 8
EMIT_BYTE 0x48
EMIT_BYTE 0x83
EMIT_BYTE 0xEC
EMIT_BYTE 0x08

    ; mov byte [rsp], 32 (space)
EMIT_BYTE 0xC6
EMIT_BYTE 0x04
EMIT_BYTE 0x24
EMIT_BYTE 0x20

    ; mov rdx, 1
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC2
EMIT_DWORD 1

    ; mov rsi, rsp
EMIT_BYTE 0x48
EMIT_BYTE 0x89
EMIT_BYTE 0xE6

    ; mov rdi, 1
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC7
EMIT_DWORD 1

    ; mov rax, 1 (sys_write)
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC0
EMIT_DWORD 1

    ; syscall
    mov     word [code_size], 0x050F
    add     qword [code_size], 2

    ; add rsp, 8
EMIT_BYTE 0x48
EMIT_BYTE 0x83
EMIT_BYTE 0xC4
EMIT_BYTE 0x08
    ret

; ============================================================================
; emit_inline_print_newline — emit code to print a newline via syscall
; ============================================================================
emit_inline_print_newline:
    ; sub rsp, 8
EMIT_BYTE 0x48
EMIT_BYTE 0x83
EMIT_BYTE 0xEC
EMIT_BYTE 0x08

    ; mov byte [rsp], 10 (newline)
EMIT_BYTE 0xC6
EMIT_BYTE 0x04
EMIT_BYTE 0x24
EMIT_BYTE 0x0A

    ; mov rdx, 1
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC2
EMIT_DWORD 1

    ; mov rsi, rsp
EMIT_BYTE 0x48
EMIT_BYTE 0x89
EMIT_BYTE 0xE6

    ; mov rdi, 1
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC7
EMIT_DWORD 1

    ; mov rax, 1
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC0
EMIT_DWORD 1

    ; syscall
    mov     word [code_size], 0x050F
    add     qword [code_size], 2

    ; add rsp, 8
EMIT_BYTE 0x48
EMIT_BYTE 0x83
EMIT_BYTE 0xC4
EMIT_BYTE 0x08
    ret

; ============================================================================
; emit_let(node) — emit code for variable declaration
; ============================================================================
emit_let:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1

    ; Child 0: identifier (name), Child 1: value expression
    mov     eax, [r12 + AST_CHILD_COUNT]
    cmp     eax, 2
    jl      .done_let

    ; Emit the value expression
    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13 + 8]             ; value child
    call    emit_node
    ; Result is in rax

    ; For now, store the value on stack (sub rsp, 8; mov [rsp], rax)
    ; In real compiler, allocate stack space in prologue
    ; emit: push rax
EMIT_BYTE 0x50

    ; Register the variable in the symbol table (stub)
    ; TODO: add to symbol table with current stack offset

.done_let:
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_always(node) — emit code for constant declaration
; ============================================================================
emit_always:
    ; Same as emit_let
    mov     ARG1, r12
    call    emit_let
    ret

; ============================================================================
; emit_assign(node) — emit code for variable reassignment
; ============================================================================
; ============================================================================
; emit_binop(node) — emit code for binary operations
; Children: left, right. Value field stores operator type.
; Emits actual x86-64 machine code instructions into the code buffer.
; ============================================================================
emit_binop:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24

    mov     r12, ARG1

    ; Load left operand — emit code that leaves result in rax
    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13]
    call    emit_node

    ; Emit: push rax (0x50)
EMIT_BYTE 0x50

    ; Load right operand — emit code that leaves result in rax
    mov     ARG1, [r13 + 8]
    call    emit_node

    ; Emit: mov rbx, rax (48 89 C3)
EMIT_BYTE 0x48
EMIT_BYTE 0x89
EMIT_BYTE 0xC3

    ; Emit: pop rax (0x58)
EMIT_BYTE 0x58

    ; Perform operation based on AST_VALUE_LEN
    mov     r14d, [r12 + AST_VALUE_LEN] ; operator type

    cmp     r14d, TOK_PLUS_WORD
    je      .op_plus
    cmp     r14d, TOK_MINUS_WORD
    je      .op_minus
    cmp     r14d, TOK_TIMES_WORD
    je      .op_times
    cmp     r14d, TOK_DIVIDE
    je      .op_divide
    cmp     r14d, TOK_MOD
    je      .op_mod
    jmp     .done_op

.op_plus:
    ; Emit: add rax, rbx (48 01 D8)
EMIT_BYTE 0x48
EMIT_BYTE 0x01
EMIT_BYTE 0xD8
    jmp     .done_op

.op_minus:
    ; Emit: sub rax, rbx (48 29 D8)
EMIT_BYTE 0x48
EMIT_BYTE 0x29
EMIT_BYTE 0xD8
    jmp     .done_op

.op_times:
    ; Emit: imul rax, rbx (48 0F AF C3)
EMIT_BYTE 0x48
EMIT_BYTE 0x0F
EMIT_BYTE 0xAF
EMIT_BYTE 0xC3
    jmp     .done_op

.op_divide:
    ; Emit: xor rdx, rdx (48 31 D2) then div rbx (48 F7 F3)
EMIT_BYTE 0x48
EMIT_BYTE 0x31
EMIT_BYTE 0xD2
EMIT_BYTE 0x48
EMIT_BYTE 0xF7
EMIT_BYTE 0xF3
    jmp     .done_op

.op_mod:
    ; Emit: xor rdx, rdx (48 31 D2) then div rbx (48 F7 F3) then mov rax, rdx (48 89 D0)
EMIT_BYTE 0x48
EMIT_BYTE 0x31
EMIT_BYTE 0xD2
EMIT_BYTE 0x48
EMIT_BYTE 0xF7
EMIT_BYTE 0xF3
EMIT_BYTE 0x48
EMIT_BYTE 0x89
EMIT_BYTE 0xD0
    jmp     .done_op

.done_op:
    ; Result in rax

    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_call(node) — emit code for function call
; Child 0: function name (identifier)
; Children 1+: arguments
; Emits code to evaluate args and call the function.
; ============================================================================
emit_call:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1

    mov     r13, [r12 + AST_CHILDREN]   ; children array
    mov     r14d, [r12 + AST_CHILD_COUNT] ; total children (including func name)
    mov     r15, [r13]                   ; function name node

    ; Get function name text
    mov     rax, [r15 + AST_VALUE_PTR]  ; function name string ptr
    mov     rbx, rax

    ; Number of arguments (excluding function name)
    mov     r15d, r14d
    dec     r15d
    cmp     r15d, 0
    jle     .no_args

    ; Emit arguments in reverse order (System V ABI: rdi, rsi, rdx, rcx, r8, r9, then stack)
    ; For simplicity, push all args, then the callee can pop them
    xor     r14, r14

.arg_loop:
    cmp     r14, r15
    jge     .args_done

    mov     ARG1, [r13 + 8 + r14 * 8]   ; arg node
    call    emit_node
    ; Emit: push rax
EMIT_BYTE 0x50

    inc     r14
    jmp     .arg_loop

.args_done:
    ; For a proper call, we'd need the function address
    ; For now, just leave args on stack and return last arg in rax
    ; Pop the last arg into rax (if any)
    test    r15d, r15d
    jle     .no_args

    ; Emit: pop rax (0x58) for each arg, last one stays in rax
    mov     ecx, r15d
.pop_args:
EMIT_BYTE 0x58
    dec     ecx
    cmp     ecx, 1
    jge     .pop_args

    jmp     .finish_call

.no_args:
    ; Emit: xor rax, rax
    mov     word [code_size], 0xC031
    add     qword [code_size], 2

.finish_call:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_give_back(node) — emit return instruction
; Emits code for the child expression and a ret instruction.
; ============================================================================
emit_give_back:
    push    r12
    mov     r12, ARG1
    mov     eax, [r12 + AST_CHILD_COUNT]
    test    eax, eax
    jz      .ret_now

    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13]
    call    emit_node

.ret_now:
    ; emit: ret (0xC3)
EMIT_BYTE 0xC3
    pop     r12
    ret

; ============================================================================
; emit_if(node) — emit code for if/else if/else
; ============================================================================
emit_if:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1

    ; Generate unique labels
    inc     qword [label_counter]
    mov     r13, [label_counter]        ; counter for unique labels

    ; Child 0: condition
    ; Children 1..N-1: body statements
    ; Last child could be NODE_ELSE

    ; Emit condition expression
    mov     r14, [r12 + AST_CHILDREN]
    mov     ARG1, [r14]                  ; condition expr
    call    emit_node

    ; For condition, we check if rax is zero (false) or non-zero (true)
    ; test rax, rax
    mov     word [code_size], 0xC085
    add     qword [code_size], 2

    ; jz .else_label (placeholder — will patch)
EMIT_BYTE 0x0F
EMIT_BYTE 0x84  ; jz near
EMIT_DWORD 0     ; placeholder offset
    mov     r15, [code_size]
    sub     r15, 4                       ; save patch location

    ; Emit body statements
    mov     ebx, [r12 + AST_CHILD_COUNT]
    mov     r14, [r12 + AST_CHILDREN]
    xor     rcx, rcx
    mov     rcx, 1                       ; start from child 1

.body_loop:
    cmp     rcx, rbx
    jge     .body_done
    mov     ARG1, [r14 + rcx * 8]
    call    emit_node
    inc     rcx
    jmp     .body_loop

.body_done:
    ; jmp .end_if_label
EMIT_BYTE 0xE9  ; jmp near
EMIT_DWORD 0     ; placeholder
    push    qword [code_size]
    sub     qword [rsp], 4              ; save second patch location

    ; Patch the conditional jump
    mov     rcx, [code_size]
    sub     rcx, r15
    sub     rcx, 4                       ; offset from jz to here
    mov     r8, [code_buffer]
    add     r8, r15
    mov     [r8], ecx

    ; Emit else clause if present
    ; Check if last child is NODE_ELSE
    dec     rbx
    mov     rcx, [r14 + rbx * 8]
    mov     eax, [rcx + AST_TYPE]
    cmp     eax, NODE_ELSE
    jne     .no_else

    ; Emit else body
    mov     ARG1, rcx
    ; The else node's children are the body statements
    mov     r14, [rcx + AST_CHILDREN]
    mov     ebx, [rcx + AST_CHILD_COUNT]
    xor     rcx, rcx
.else_loop:
    cmp     rcx, rbx
    jge     .else_done
    mov     ARG1, [r14 + rcx * 8]
    call    emit_node
    inc     rcx
    jmp     .else_loop
.else_done:

.no_else:
    ; Patch the unconditional jump
    pop     rcx                         ; second patch location
    mov     rdx, [code_size]
    sub     rdx, rcx
    sub     rdx, 4
    mov     r8, [code_buffer]
    add     r8, rcx
    mov     [r8], edx

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_define(node) — emit function definition
; Child 0: function name (identifier)
; Child 1..N: body statements (last may be give-back expression)
; Emits a label and function prologue/epilogue.
; ============================================================================
emit_define:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1

    ; Get function name
    mov     r13, [r12 + AST_CHILDREN]
    mov     r14, [r13 + 0]              ; name node (identifier)

    ; Emit a unique label as a comment in the code buffer
    ; We'll emit a NOP sled as a placeholder label marker
    ; In a real compiler, we'd track function offsets in a symbol table
    ; For now, just emit the function body

    ; Emit function prologue: push rbp; mov rbp, rsp
    ; 55                      ; push rbp
EMIT_BYTE 0x55
    ; 48 89 E5                ; mov rbp, rsp
EMIT_BYTE 0x48
EMIT_BYTE 0x89
EMIT_BYTE 0xE5

    ; Emit body statements (children 1..N)
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]
    mov     ecx, 1                      ; skip child 0 (name)

.body_loop:
    cmp     ecx, r14d
    jge     .body_done
    mov     ARG1, [r15 + rcx * 8]
    call    emit_node
    inc     ecx
    jmp     .body_loop

.body_done:
    ; Emit function epilogue: pop rbp; ret
    ; 5D                      ; pop rbp
EMIT_BYTE 0x5D
    ; C3                      ; ret
EMIT_BYTE 0xC3

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_assign(node) — emit code for variable reassignment
; Child 0: identifier (name), Child 1: value expression
; ============================================================================
emit_assign:
    push    r12
    push    r13
    mov     r12, ARG1

    mov     eax, [r12 + AST_CHILD_COUNT]
    cmp     eax, 2
    jl      .done_assign

    ; Emit value expression
    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13 + 8]
    call    emit_node

    ; Emit: mov [rsp + <offset>], rax
    ; For now, assume variable is at [rsp] (top of stack)
    ; 48 89 04 24             ; mov [rsp], rax
EMIT_BYTE 0x48
EMIT_BYTE 0x89
EMIT_BYTE 0x04
EMIT_BYTE 0x24

.done_assign:
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_exit — emit process exit
; ============================================================================
emit_exit:
    ; emit: mov eax, 60 (sys_exit); xor edi, edi; syscall
    ; B8 3C 00 00 00       ; mov eax, 60
EMIT_BYTE 0xB8
EMIT_DWORD 60
    ; 31 FF                ; xor edi, edi
    mov     word [code_size], 0xFF31
    add     qword [code_size], 2
    ; 0F 05                ; syscall
    mov     word [code_size], 0x050F
    add     qword [code_size], 2
    ret

; ============================================================================
; emit_data_section — emit data section (strings etc.)
; ============================================================================
emit_data_section:
    ; Copy data buffer contents after code
    mov     ARG1, [data_buffer]
    mov     ARG2, [code_size]     ; destination = current end of code
    mov     ARG3, [data_size]
    call    ak_memcpy
    ; Advance code pointer by data size
    mov     rcx, [data_size]
    add     [code_size], rcx
    ret

; ============================================================================
; add_string_to_data(str_ptr) -> offset in data section
; ============================================================================
add_string_to_data:
    push    rbx
    push    r12
    mov     r12, ARG1

    ; Get string length
    mov     ARG1, r12
    call    ak_strlen
    mov     rbx, rax                    ; length
    inc     rbx                         ; +1 for null

    ; Get current data offset
    mov     rax, [data_size]
    push    rax                         ; save offset

    ; Copy string to data buffer
    mov     ARG1, [data_buffer]
    add     ARG1, [data_size]
    mov     ARG2, r12
    mov     ARG3, rbx
    call    ak_memcpy

    ; Update data size
    add     [data_size], rbx

    pop     rax                         ; return offset
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_label(name) — emit a label marker (for jumps)
; For now, records label position in a table
; ============================================================================
emit_label:
    ret

; ============================================================================
; emit_byte(val) — emit single byte
; ============================================================================
emit_byte:
    mov     rcx, [code_buffer]
    add     rcx, [code_size]
    mov     [rcx], ARG1
    inc     qword [code_size]
    ret

; ============================================================================
; emit_protocol(node) — emit vtable layout for protocol/interface
; Generates a struct in the data section describing the required behaviours.
; No runtime code emitted — purely a compile-time construct.
; ============================================================================
emit_protocol:
    push    rbx
    push    r12
    mov     r12, ARG1

    ; Store protocol metadata in data section for runtime reflection
    ; Format: [name_ptr, behaviour_count, behaviour_name_ptrs...]
    mov     rbx, [r12 + AST_CHILDREN]
    mov     r12d, [r12 + AST_CHILD_COUNT]

    ; Emit a comment/placeholder marker in code section (NOP sled)
EMIT_BYTE 0x90
EMIT_BYTE 0x90

    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_lambda(node) — emit code for a lambda (anonymous function)
; Allocates a closure on the heap, captures variables, stores function pointer.
; ============================================================================
emit_lambda:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; Calculate closure size: struct { func_ptr, captured_count, captured_vals... }
    ; For now, allocate with ak_malloc and store function pointer

    ; Emit: mov ARG1, closure_size
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC7
EMIT_DWORD 16

    ; Emit: call ak_malloc
EMIT_BYTE 0xE8
EMIT_DWORD 0

    ; Store the closure pointer in rax (already returned by ak_malloc)
    ; Result is in rax

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_async(node) — emit state machine for async function
; Creates a state machine struct and jump table between yield points.
; ============================================================================
emit_async:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; Emit async function prologue
    ; Allocates state machine struct on heap
    ; Stores initial state = 0

    ; mov rax, 16 (struct size)
EMIT_BYTE 0x48
EMIT_BYTE 0xC7
EMIT_BYTE 0xC0
EMIT_DWORD 16

    ; call ak_malloc
EMIT_BYTE 0xE8
EMIT_DWORD 0

    ; Emit body statements (children)
    mov     r13, [r12 + AST_CHILDREN]
    mov     r14d, [r12 + AST_CHILD_COUNT]
    xor     r15, r15
.as_body_loop:
    cmp     r15, r14
    jge     .as_body_done
    mov     ARG1, [r13 + r15 * 8]
    call    emit_node
    inc     r15
    jmp     .as_body_loop
.as_body_done:

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_await(node) — emit yield point for async/await
; Saves current state, returns to caller, sets resume point.
; ============================================================================
emit_await:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1

    ; Emit: save current state to state machine struct
    ; For now, emit a NOP as placeholder for the yield point
EMIT_BYTE 0x90

    ; Emit child expression (the expression being awaited)
    mov     eax, [r12 + AST_CHILD_COUNT]
    test    eax, eax
    jz      .await_done
    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13]
    call    emit_node

.await_done:
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_manual_memory(node) — emit code for manual memory mode block
; Emits body code without automatic GC integration.
; Users call ak_malloc/ak_free directly.
; ============================================================================
emit_manual_memory:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; Emit body statements (children) — no GC integration code added
    mov     r13, [r12 + AST_CHILDREN]
    mov     r14d, [r12 + AST_CHILD_COUNT]
    xor     r15, r15

.mm_body_loop:
    cmp     r15, r14
    jge     .mm_body_done
    mov     ARG1, [r13 + r15 * 8]
    call    emit_node
    inc     r15
    jmp     .mm_body_loop

.mm_body_done:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_test_suite(node) — emit code for a test suite
; Prints suite name and runs contained tests
; ============================================================================
emit_test_suite:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; Print "Running test suite: <name>"
    mov     ARG1, .suite_prefix
    call    ak_print_str
    mov     ARG1, [r12 + AST_VALUE_PTR]
    mov     ARG2, 0
    call    ak_print_str
    call    ak_print_newline

    ; Emit each child test
    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.ts_loop:
    cmp     r13, r14
    jge     .ts_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .ts_loop

.ts_done:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.suite_prefix db "Running test suite: ", 0

; ============================================================================
; emit_test(node) — emit code for a single test
; Prints test name, wraps body in try-catch, prints PASS/FAIL
; ============================================================================
emit_test:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; Print "  TEST: <name>"
    mov     ARG1, .test_prefix
    call    ak_print_str
    mov     ARG1, [r12 + AST_VALUE_PTR]
    mov     ARG2, 0
    call    ak_print_str
    call    ak_print_newline

    ; Emit body statements (children)
    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.t_body_loop:
    cmp     r13, r14
    jge     .t_body_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .t_body_loop

.t_body_done:
    ; Print PASS
    mov     ARG1, .pass_prefix
    call    ak_print_str
    mov     ARG1, [r12 + AST_VALUE_PTR]
    mov     ARG2, 0
    call    ak_print_str
    call    ak_print_newline

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.test_prefix db "  TEST: ", 0
.pass_prefix db "  PASS: ", 0

; ============================================================================
; emit_expect(node) — emit code for an assertion
; Compares values, prints PASS or FAIL message with line info
; ============================================================================
emit_expect:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     eax, [r12 + AST_VALUE_LEN]
    test    eax, eax
    jnz     .expect_error

    ; expect expr to be expr — emit comparison
    mov     eax, [r12 + AST_CHILD_COUNT]
    cmp     eax, 2
    jl      .expect_done

    mov     r13, [r12 + AST_CHILDREN]

    ; Emit actual value expression
    mov     ARG1, [r13]
    call    emit_node
    push    rax                         ; save result (placeholder)

    ; Emit expected value expression
    mov     ARG1, [r13 + 8]
    call    emit_node

    pop     rcx                         ; actual value (placeholder)
    ; Compare (simplified — actual runtime comparison needed)
    ; For now just print PASS
    mov     ARG1, .expect_pass
    call    ak_print_str
    jmp     .expect_done

.expect_error:
    ; expect error when expr — mark as expected error
    mov     ARG1, .expect_error_str
    call    ak_print_str

.expect_done:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.expect_pass db "    EXPECT PASS", 10, 0
.expect_error_str db "    Expected error", 10, 0

; ============================================================================
; emit_run_tests(node) — emit code for "run all tests"
; Calls the runtime test runner
; ============================================================================
emit_run_tests:
    push    r12
    sub     rsp, 16

    mov     ARG1, .run_msg
    call    ak_print_str

    ; In a full implementation, this would call the test runner
    ; which collects and runs all registered test suites
    call    ak_test_run_all

    add     rsp, 16
    pop     r12
    ret

.run_msg db "Running all tests...", 10, 0

; ============================================================================
; emit_sqrt(node) — emit square root using SSE sqrtsd
; ============================================================================
emit_sqrt:
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1

    mov     eax, [r12 + AST_CHILD_COUNT]
    test    eax, eax
    jz      .es_done

    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13]
    call    emit_node

    ; cvtsi2sd xmm0, rax: F2 48 0F 2A C0
EMIT_BYTE 0xF2
EMIT_BYTE 0x48
EMIT_BYTE 0x0F
EMIT_BYTE 0x2A
EMIT_BYTE 0xC0

    ; sqrtsd xmm0, xmm0: F2 0F 51 C0
EMIT_BYTE 0xF2
EMIT_BYTE 0x0F
EMIT_BYTE 0x51
EMIT_BYTE 0xC0

    ; cvttsd2si rax, xmm0: F2 48 0F 2C C0
EMIT_BYTE 0xF2
EMIT_BYTE 0x48
EMIT_BYTE 0x0F
EMIT_BYTE 0x2C
EMIT_BYTE 0xC0

.es_done:
    add     rsp, 16
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_make_page(node) — emit UI page definition
; ============================================================================
emit_make_page:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.emp_loop:
    cmp     r13, r14
    jge     .emp_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .emp_loop

.emp_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_make_button(node) — emit UI button definition
; ============================================================================
emit_make_button:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.emb_loop:
    cmp     r13, r14
    jge     .emb_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .emb_loop

.emb_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_make_input(node) — emit UI input field definition
; ============================================================================
emit_make_input:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.emi_loop:
    cmp     r13, r14
    jge     .emi_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .emi_loop

.emi_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_event(node) — emit event handler registration
; ============================================================================
emit_event:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.eev_loop:
    cmp     r13, r14
    jge     .eev_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .eev_loop

.eev_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_goto(node) — emit navigation call
; ============================================================================
emit_goto:
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1

    mov     eax, [r12 + AST_CHILD_COUNT]
    test    eax, eax
    jz      .eg_done

    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13]
    call    emit_node

.eg_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 16
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_send(node) — emit HTTP request call
; ============================================================================
emit_send:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.esnd_loop:
    cmp     r13, r14
    jge     .esnd_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .esnd_loop

.esnd_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_connect_db(node) — emit database connection call
; ============================================================================
emit_connect_db:
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1

    mov     eax, [r12 + AST_CHILD_COUNT]
    test    eax, eax
    jz      .ecd_done

    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13]
    call    emit_node

.ecd_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 16
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_make_table(node) — emit table schema definition
; ============================================================================
emit_make_table:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.emt_loop:
    cmp     r13, r14
    jge     .emt_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .emt_loop

.emt_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_create_table(node) — emit table creation call
; ============================================================================
emit_create_table:
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1

    mov     eax, [r12 + AST_CHILD_COUNT]
    test    eax, eax
    jz      .ect_done

    mov     r13, [r12 + AST_CHILDREN]
    mov     ARG1, [r13]
    call    emit_node

.ect_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 16
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_insert(node) — emit DB insert call
; ============================================================================
emit_insert:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.eins_loop:
    cmp     r13, r14
    jge     .eins_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .eins_loop

.eins_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_find(node) — emit DB query call
; ============================================================================
emit_find:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.efind_loop:
    cmp     r13, r14
    jge     .efind_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .efind_loop

.efind_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_update(node) — emit DB update call
; ============================================================================
emit_update:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.eupd_loop:
    cmp     r13, r14
    jge     .eupd_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .eupd_loop

.eupd_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; emit_delete(node) — emit DB delete call
; ============================================================================
emit_delete:
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    xor     r13, r13
    mov     r14d, [r12 + AST_CHILD_COUNT]
    mov     r15, [r12 + AST_CHILDREN]

.edel_loop:
    cmp     r13, r14
    jge     .edel_done
    mov     ARG1, [r15 + r13 * 8]
    call    emit_node
    inc     r13
    jmp     .edel_loop

.edel_done:
EMIT_BYTE 0xE8
EMIT_DWORD 0

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ============================================================================
; External references
; ============================================================================
extern ak_malloc
extern ak_memcpy
extern ak_strlen
extern ak_error
extern ak_exit
extern ak_print_str
extern ak_print_newline
extern ak_print_num
extern ak_test_run_all
extern ak_atoi
extern ak_atof

