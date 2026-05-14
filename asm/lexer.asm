; ============================================================================
; AK CODE Lexer — Tokeniser in x86-64 assembly
; Recognises all AK CODE syntax tokens including multi-word keywords.
; Produces an array of token structs:
;   { type: u32, start: ptr, length: u32, line: u32, col: u32 }
; ============================================================================

%include "macros.inc"

default rel

; Token type constants
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
TOK_NEWLINE    equ 29
TOK_INDENT     equ 30
TOK_DEDENT     equ 31
TOK_EOF        equ 32
TOK_COMMENT    equ 33

; Token struct offsets
TK_TYPE  equ 0   ; u32 (4 bytes)
TK_PAD   equ 4   ; padding
TK_START equ 8   ; ptr (8 bytes)
TK_LEN   equ 16  ; u32 (4 bytes)
TK_LINE  equ 20  ; u32 (4 bytes)
TK_COL   equ 24  ; u32 (4 bytes)
TK_SIZE  equ 28  ; total struct size (aligned)

; Lexer state struct offsets
LEX_SOURCE       equ 0   ; ptr
LEX_LENGTH       equ 8   ; u64 (source length)
LEX_POS          equ 16  ; u64
LEX_LINE         equ 24  ; u32
LEX_COL          equ 28  ; u32
LEX_TOKENS       equ 32  ; ptr to token array
LEX_COUNT        equ 40  ; u32
LEX_CAP          equ 44  ; u32
LEX_INDENT_STACK equ 48  ; ptr to indent level stack
LEX_INDENT_DEPTH equ 56  ; u32
LEX_INDENT_CAP   equ 60  ; u32
LEX_SIZE         equ 64

section .data
    ; Keyword strings
    kw_let       db "let", 0
    kw_always    db "always", 0
    kw_show      db "show", 0
    kw_ask       db "ask", 0
    kw_and       db "and", 0
    kw_or        db "or", 0
    kw_store     db "store", 0
    kw_in        db "in", 0
    kw_if        db "if", 0
    kw_else      db "else", 0
    kw_end       db "end", 0
    kw_repeat    db "repeat", 0
    kw_while     db "while", 0
    kw_for       db "for", 0
    kw_each      db "each", 0
    kw_count     db "count", 0
    kw_from      db "from", 0
    kw_to        db "to", 0
    kw_down      db "down", 0
    kw_define    db "define", 0
    kw_taking    db "taking", 0
    kw_give      db "give", 0
    kw_back      db "back", 0
    kw_make      db "make", 0
    kw_kind      db "kind", 0
    kw_called    db "called", 0
    kw_has       db "has", 0
    kw_when      db "when", 0
    kw_created   db "created", 0
    kw_behaviour db "behaviour", 0
    kw_new       db "new", 0
    kw_with      db "with", 0
    kw_try       db "try", 0
    kw_catch     db "catch", 0
    kw_any       db "any", 0
    kw_error     db "error", 0
    kw_finally   db "finally", 0
    kw_bring     db "bring", 0
    kw_match     db "match", 0
    kw_it        db "it", 0
    kw_is        db "is", 0
    kw_otherwise db "otherwise", 0
    kw_of        db "of", 0
    kw_type      db "type", 0
    kw_true      db "true", 0
    kw_false     db "false", 0
    kw_empty     db "empty", 0
    kw_plus      db "plus", 0
    kw_minus     db "minus", 0
    kw_times     db "times", 0
    kw_divided   db "divided", 0
    kw_by        db "by", 0
    kw_mod       db "mod", 0
    kw_power     db "power", 0
    kw_not       db "not", 0
    kw_greater   db "greater", 0
    kw_less      db "less", 0
    kw_than      db "than", 0
    kw_between   db "between", 0
    kw_contains  db "contains", 0
    kw_starts    db "starts", 0
    kw_ends      db "ends", 0
    kw_list      db "list", 0
    kw_map       db "map", 0
    kw_size      db "size", 0
    kw_first     db "first", 0
    kw_last      db "last", 0
    kw_item      db "item", 0
    kw_add       db "add", 0
    kw_remove    db "remove", 0
    kw_get       db "get", 0
    kw_set       db "set", 0
    kw_do        db "do", 0
    kw_background db "background", 0
    kw_wait      db "wait", 0
    kw_all       db "all", 0
    kw_extends   db "extends", 0
    kw_parent    db "parent", 0
    kw_server    db "server", 0
    kw_port      db "port", 0
    kw_visits    db "visits", 0
    kw_sends     db "sends", 0
    kw_posts     db "posts", 0
    kw_page      db "page", 0
    kw_data      db "data", 0
    kw_listening db "listening", 0
    kw_connect   db "connect", 0
    kw_database  db "database", 0
    kw_table     db "table", 0
    kw_column    db "column", 0
    kw_unique    db "unique", 0
    kw_required  db "required", 0
    kw_default   db "default", 0
    kw_now       db "now", 0
    kw_train     db "train", 0
    kw_model     db "model", 0
    kw_layer     db "layer", 0
    kw_input     db "input", 0
    kw_output    db "output", 0
    kw_dense     db "dense", 0
    kw_dropout   db "dropout", 0
    kw_activation db "activation", 0
    kw_predict   db "predict", 0
    kw_on        db "on", 0
    kw_using     db "using", 0
    kw_labels    db "labels", 0
    kw_rounds    db "rounds", 0
    kw_batch     db "batch", 0
    kw_optimizer db "optimizer", 0
    kw_learning  db "learning", 0
    kw_rate      db "rate", 0
    kw_plot      db "plot", 0
    kw_chart     db "chart", 0
    kw_scatter   db "scatter", 0
    kw_bar       db "bar", 0
    kw_diagram   db "diagram", 0
    kw_formula   db "formula", 0
    kw_simplify  db "simplify", 0
    kw_equation  db "equation", 0
    kw_solve     db "solve", 0
    kw_for_x     db "x", 0
    kw_squared   db "squared", 0
    kw_differentiate db "differentiate", 0
    kw_integrate db "integrate", 0
    kw_respect   db "respect", 0
    kw_mean      db "mean", 0
    kw_median    db "median", 0
    kw_deviation db "deviation", 0
    kw_standard  db "standard", 0
    kw_protocol  db "protocol", 0
    kw_as        db "as", 0
    kw_maybe     db "maybe", 0
    kw_exists    db "exists", 0
    kw_text      db "text", 0
    kw_number_t  db "number", 0
    kw_decimal_t db "decimal", 0
    kw_boolean_t db "boolean", 0
    kw_holding   db "holding", 0
    kw_transform db "transform", 0
    kw_keep      db "keep", 0
    kw_where     db "where", 0
    kw_manual    db "manual", 0
    kw_memory    db "memory", 0
    kw_mode      db "mode", 0
    kw_allocate  db "allocate", 0
    kw_bytes     db "bytes", 0
    kw_suite     db "suite", 0
    kw_test      db "test", 0
    kw_expect    db "expect", 0
    kw_run       db "run", 0
    kw_results   db "results", 0
    kw_module    db "module", 0
    kw_project   db "project", 0
    kw_version   db "version", 0
    kw_author    db "author", 0
    kw_needs     db "needs", 0
    kw_publish   db "publish", 0
    kw_registry  db "registry", 0
    kw_received  db "received", 0
    kw_message   db "message", 0
    kw_middle    db "middle", 0
    kw_name      db "name", 0
    kw_requires   db "requires", 0
    kw_interface  db "interface", 0
    kw_implements db "implements", 0
    kw_async      db "async", 0
    kw_await      db "await", 0
    kw_button     db "button", 0
    kw_clicked    db "clicked", 0
    kw_root       db "root", 0
    kw_square     db "square", 0
    kw_send       db "send", 0
    kw_go         db "go", 0
    kw_create     db "create", 0
    kw_find       db "find", 0
    kw_update     db "update", 0
    kw_values     db "values", 0
    kw_the        db "the", 0

    ; Multi-word keyword maps (first word -> struct with continuation + token)
    ; Each entry: first_word_ptr, continuation_word_ptr_or_zero, token_type
    multi_kw_table:
        dq kw_divided, kw_by, TOK_DIVIDE
        dq kw_greater, kw_than, TOK_GREATER
        dq kw_less, kw_than, TOK_LESS
        dq kw_power, 0, TOK_POWER   ; "power" alone maps to power but "to the power of" needs more
        dq kw_starts, kw_with, 0    ; "starts with" -> will be handled differently
        dq kw_ends, kw_with, 0
        dq kw_give, kw_back, 16     ; special: give back -> return statement
        dq kw_for, kw_each, 12      ; special: for each -> for_each loop
        dq kw_bring, kw_in, 30      ; bring in -> import
        dq kw_count, kw_from, 13    ; count from -> numeric loop
        dq kw_down, kw_to, 0        ; down to -> part of count from x down to y
        dq kw_parent, kw_created, 0 ; parent created -> super call
        dq kw_to, kw_the, 0         ; "to the power of"
        dq kw_the, kw_power, 0
        dq kw_wait, kw_for, 0       ; wait for -> async await
        dq kw_standard, kw_deviation, 0
        dq kw_test, kw_suite, 0
        dq 0, 0, 0                  ; sentinel

section .text
    global ak_lex

; ============================================================================
; ak_lex(source, length) -> token array ptr
; ARG1 = source pointer, ARG2 = source length
; Returns pointer to lexer state with tokens and indentation processed
; ============================================================================
ak_lex:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 40

    mov     r12, ARG1                   ; source pointer
    mov     r13, ARG2                   ; source length

    ; Allocate lexer state
    mov     ARG1, LEX_SIZE
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r14, rax                    ; r14 = lexer state

    ; Init lexer state
    mov     [r14 + LEX_SOURCE], r12
    mov     [r14 + LEX_LENGTH], r13
    mov     qword [r14 + LEX_POS], 0
    mov     dword [r14 + LEX_LINE], 1
    mov     dword [r14 + LEX_COL], 1

    ; Allocate token array (initial capacity 1024)
    mov     ARG1, 1024 * TK_SIZE
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     [r14 + LEX_TOKENS], rax
    mov     dword [r14 + LEX_COUNT], 0
    mov     dword [r14 + LEX_CAP], 1024

    ; Allocate indent stack (initial capacity 64)
    mov     ARG1, 64 * 4                ; 64 u32 entries
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     [r14 + LEX_INDENT_STACK], rax
    mov     dword [r14 + LEX_INDENT_DEPTH], 0
    mov     dword [r14 + LEX_INDENT_CAP], 64
    ; Push indent level 0 as base
    mov     dword [rax], 0
    mov     dword [r14 + LEX_INDENT_DEPTH], 1

    ; Main tokenisation loop
.tokenize_loop:
    mov     ARG1, r14
    call    next_token
    test    rax, rax
    jz      .eof
    mov     rax, [r14 + LEX_TOKENS]
    mov     ecx, [r14 + LEX_COUNT]
    imul    rcx, TK_SIZE
    mov     eax, [rax + rcx + TK_TYPE - TK_SIZE]
    cmp     eax, TOK_EOF
    jne     .tokenize_loop
    jmp     .done

.eof:
    ; Emit DEDENT tokens to close all open indent levels
    mov     ARG1, r14
    call    emit_all_dedents
    ; Add EOF token
    mov     ARG1, r14
    mov     ARG2, TOK_EOF
    xor     ARG3, ARG3
    xor     r8, r8
    call    add_token

.done:
    mov     rax, r14
    add     rsp, 40
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.fail:
    xor     rax, rax
    add     rsp, 40
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; emit_all_dedents(lexer) — emit DEDENT tokens for all open indent levels
; ============================================================================
emit_all_dedents:
    push    r12
    mov     r12, ARG1
.loop:
    mov     eax, [r12 + LEX_INDENT_DEPTH]
    cmp     eax, 1
    jle     .done
    mov     ARG1, r12
    mov     ARG2, TOK_DEDENT
    xor     ARG3, ARG3
    xor     r8, r8
    call    add_token
    dec     dword [r12 + LEX_INDENT_DEPTH]
    jmp     .loop
.done:
    pop     r12
    ret

; ============================================================================
; next_token(lexer) — read and add the next token
; ARG1 = lexer state pointer
; Returns non-zero if token added, 0 on EOF
; ============================================================================
next_token:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r14, ARG1



.next_char:
    mov     ARG1, r14
    call    peek_char
    cmp     al, -1
    je      .eof

    ; Check for newline
    cmp     al, 10
    je      .handle_newline
    cmp     al, 13
    je      .handle_newline

    ; Check for space/indent
    cmp     al, 32
    je      .handle_space
    cmp     al, 9                      ; tab
    je      .handle_tab

    ; Check for comment
    cmp     al, '#'
    je      .handle_comment

    ; Check for quote
    cmp     al, '"'
    je      .handle_string

    ; Check for digit
    cmp     al, '0'
    jb      .check_symbol
    cmp     al, '9'
    jbe     .handle_number

.check_symbol:
    cmp     al, ','
    je      .handle_comma
    cmp     al, '.'
    je      .handle_dot
    cmp     al, '('
    je      .handle_lparen
    cmp     al, ')'
    je      .handle_rparen
    cmp     al, '['
    je      .handle_lbracket
    cmp     al, ']'
    je      .handle_rbracket
    cmp     al, '='
    je      .handle_equals

    ; Check for letter or underscore
    cmp     al, 'A'
    jb      .unknown_char
    cmp     al, 'Z'
    jbe     .handle_word
    cmp     al, '_'
    je      .handle_word
    cmp     al, 'a'
    jb      .unknown_char
    cmp     al, 'z'
    jbe     .handle_word

.unknown_char:
    mov     ARG1, r14
    call    current_line
    mov     r13, rax
    mov     ARG1, r14
    call    current_col
    mov     rbx, rax
    mov     ARG1, r14
    call    advance
    jmp     .next_char

.handle_space:
    mov     ARG1, r14
    call    advance
    jmp     .next_char

.handle_tab:
    mov     ARG1, r14
    call    advance
    add     dword [r14 + LEX_COL], 3
    jmp     .next_char

.handle_newline:
    ; Skip the actual newline character(s)
    mov     ARG1, r14
    call    advance

    ; Consume all consecutive newlines
.next_nl:
    mov     ARG1, r14
    call    peek_char
    cmp     al, 10
    je      .skip_nl
    cmp     al, 13
    jne     .done_nl
.skip_nl:
    mov     ARG1, r14
    call    advance
    jmp     .next_nl
.done_nl:
    ; Check if we're at EOF after newlines
    cmp     al, -1
    je      .eof

    ; Count indentation of the next line
    ; Save current position to restore after counting
    mov     r15, [r14 + LEX_POS]
    mov     r12d, [r14 + LEX_COL]
    mov     r13d, [r14 + LEX_LINE]

    mov     ARG1, r14
    call    count_indent
    mov     rbx, rax                    ; rbx = indent level

    ; Restore position (count_indent advanced past the spaces)
    mov     [r14 + LEX_POS], r15
    mov     [r14 + LEX_COL], r12d
    mov     [r14 + LEX_LINE], r13d

    ; Emit NEWLINE token
    mov     ARG1, r14
    mov     ARG2, TOK_NEWLINE
    xor     ARG3, ARG3
    xor     r8, r8
    call    add_token

    ; Now handle indentation
    ; Get current indent level from top of stack
    mov     rax, [r14 + LEX_INDENT_STACK]
    mov     ecx, [r14 + LEX_INDENT_DEPTH]
    dec     ecx
    mov     eax, [rax + rcx * 4]       ; eax = current indent level

    cmp     ebx, eax
    je      .indent_same
    jg      .indent_in
    jl      .indent_out

.indent_same:
    jmp     .next_char

.indent_in:
    ; Push new indent level
    push    rbx
    mov     ARG1, r14
    pop     ARG2                       ; new level
    call    push_indent_level

    mov     ARG1, r14
    mov     ARG2, TOK_INDENT
    xor     ARG3, ARG3
    xor     r8, r8
    call    add_token
    jmp     .next_char

.indent_out:
    ; Pop indent levels until we match
    ; But we must not pop the base level (depth > 1)
.indent_out_loop:
    mov     eax, [r14 + LEX_INDENT_DEPTH]
    cmp     eax, 1
    jle     .indent_done

    mov     rax, [r14 + LEX_INDENT_STACK]
    mov     ecx, [r14 + LEX_INDENT_DEPTH]
    dec     ecx
    mov     eax, [rax + rcx * 4]

    cmp     ebx, eax
    je      .indent_done

    mov     ARG1, r14
    mov     ARG2, TOK_DEDENT
    xor     ARG3, ARG3
    xor     r8, r8
    call    add_token

    dec     dword [r14 + LEX_INDENT_DEPTH]
    jmp     .indent_out_loop

.indent_done:
    jmp     .next_char

.handle_comment:
    mov     ARG1, r14
    call    advance
.skip_comment:
    mov     ARG1, r14
    call    peek_char
    cmp     al, 10
    je      .end_comment
    cmp     al, 13
    je      .end_comment
    cmp     al, -1
    je      .end_comment
    mov     ARG1, r14
    call    advance
    jmp     .skip_comment
.end_comment:
    jmp     .next_char

.handle_string:
    mov     ARG1, r14
    call    start_token
    mov     r13, rax

    mov     ARG1, r14
    call    advance

.string_loop:
    mov     ARG1, r14
    call    peek_char
    cmp     al, -1
    je      .unterminated_string
    cmp     al, '"'
    je      .end_string
    cmp     al, 10
    je      .unterminated_string
    cmp     al, '\'
    je      .escape_char
    mov     ARG1, r14
    call    advance
    jmp     .string_loop

.escape_char:
    mov     ARG1, r14
    call    advance
    mov     ARG1, r14
    call    advance
    jmp     .string_loop

.end_string:
    mov     ARG1, r14
    call    advance

    mov     rcx, r13
    mov     ARG1, r14
    call    position
    sub     rax, r13
    add     rax, [r14 + LEX_SOURCE]
    sub     rax, 2

    mov     ARG1, r14
    mov     ARG2, TOK_STRING
    mov     ARG3, r13
    inc     ARG3
    mov     r8, rax
    call    add_token
    jmp     .next_char

.unterminated_string:
    lea     ARG1, [msg_unterminated]
    mov     ARG2, r14
    call    current_line
    mov     r13, rax
    mov     ARG2, r13
    mov     ARG3, r14
    call    current_col
    call    ak_error
    jmp     .end_string

.handle_number:
    mov     ARG1, r14
    call    start_token
    mov     r13, rax
    xor     r15, r15

.number_loop:
    mov     ARG1, r14
    call    peek_char
    cmp     al, '0'
    jb      .check_decimal
    cmp     al, '9'
    ja      .check_decimal
    mov     ARG1, r14
    call    advance
    jmp     .number_loop

.check_decimal:
    cmp     al, '.'
    jne     .end_number
    mov     ARG1, r14
    call    peek_next_char
    cmp     al, '0'
    jb      .end_number
    cmp     al, '9'
    ja      .end_number
    mov     r15, 1
    mov     ARG1, r14
    call    advance

.decimal_loop:
    mov     ARG1, r14
    call    peek_char
    cmp     al, '0'
    jb      .end_number
    cmp     al, '9'
    ja      .end_number
    mov     ARG1, r14
    call    advance
    jmp     .decimal_loop

.end_number:
    mov     ARG1, r14
    call    position
    sub     rax, r13
    add     rax, [r14 + LEX_SOURCE]
    mov     r8, rax

    mov     ARG1, r14
    test    r15, r15
    jnz     .is_decimal
    mov     ARG2, TOK_NUMBER
    jmp     .add_number_token
.is_decimal:
    mov     ARG2, TOK_DECIMAL
.add_number_token:
    mov     ARG3, r13
    call    add_token
    jmp     .next_char

.handle_word:
    mov     ARG1, r14
    call    start_token
    mov     r13, rax

    mov     ARG1, r14
    call    read_word
    mov     r15, rax

    mov     ARG1, r14
    mov     ARG2, r13
    mov     ARG3, r15
    call    extract_word_token

    mov     ARG1, r14
    mov     ARG2, r13
    mov     ARG3, r15
    call    check_multi_keyword
    cmp     rax, -1
    je      .not_multi
    cmp     rax, 0
    je      .check_single_kw
    mov     ARG2, rax
    mov     ARG1, r14
    mov     ARG3, r13
    mov     r8, r15
    call    add_token
    jmp     .next_char

.not_multi:
.check_single_kw:
    mov     ARG1, r13
    mov     ARG2, r15
    call    classify_word
    cmp     rax, 0
    je      .is_identifier

    cmp     rax, TOK_BOOL
    je      .add_word_token
    cmp     rax, TOK_EMPTY
    je      .add_word_token
    cmp     rax, TOK_IS
    je      .add_word_token
    cmp     rax, TOK_AND
    je      .add_word_token
    cmp     rax, TOK_OR
    je      .add_word_token
    cmp     rax, TOK_NOT
    je      .add_word_token
    cmp     rax, TOK_KEYWORD
    jne     .try_op_token

    jmp     .add_word_token

.try_op_token:
    cmp     rax, TOK_PLUS_WORD
    je      .add_word_token
    cmp     rax, TOK_MINUS_WORD
    je      .add_word_token
    cmp     rax, TOK_TIMES_WORD
    je      .add_word_token
    cmp     rax, TOK_DIVIDE
    je      .add_word_token
    cmp     rax, TOK_MOD
    je      .add_word_token
    cmp     rax, TOK_POWER
    je      .add_word_token
    cmp     rax, TOK_GREATER
    je      .add_word_token
    cmp     rax, TOK_LESS
    je      .add_word_token
    cmp     rax, TOK_BETWEEN
    je      .add_word_token
    cmp     rax, TOK_CONTAINS
    je      .add_word_token

    jmp     .is_identifier

.add_word_token:
    mov     ARG1, r14
    mov     ARG2, rax
    mov     ARG3, r13
    mov     r8, r15
    call    add_token
    jmp     .next_char

.is_identifier:
    mov     ARG1, r14
    mov     ARG2, TOK_IDENTIFIER
    mov     ARG3, r13
    mov     r8, r15
    call    add_token
    jmp     .next_char

.handle_comma:
    mov     ARG1, r14
    mov     ARG2, TOK_COMMA
    call    add_single_char_token
    jmp     .next_char

.handle_dot:
    mov     ARG1, r14
    mov     ARG2, TOK_DOT
    call    add_single_char_token
    jmp     .next_char

.handle_lparen:
    mov     ARG1, r14
    mov     ARG2, TOK_LPAREN
    call    add_single_char_token
    jmp     .next_char

.handle_rparen:
    mov     ARG1, r14
    mov     ARG2, TOK_RPAREN
    call    add_single_char_token
    jmp     .next_char

.handle_lbracket:
    mov     ARG1, r14
    mov     ARG2, TOK_LBRACKET
    call    add_single_char_token
    jmp     .next_char

.handle_rbracket:
    mov     ARG1, r14
    mov     ARG2, TOK_RBRACKET
    call    add_single_char_token
    jmp     .next_char

.handle_equals:
    mov     ARG1, r14
    mov     ARG2, TOK_EQUALS
    call    add_single_char_token
    jmp     .next_char

.eof:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.msg_unknown db "Unknown character", 0

; ============================================================================
; Helper: peek_char(lexer) -> char in al, or -1 if eof
; ============================================================================
peek_char:
    push    rbx
    mov     rbx, ARG1
    mov     rax, [rbx + LEX_POS]
    mov     rcx, [rbx + LEX_LENGTH]
    cmp     rax, rcx
    jae     .eof
    mov     rax, [rbx + LEX_SOURCE]
    add     rax, [rbx + LEX_POS]
    movzx   eax, byte [rax]
    pop     rbx
    ret
.eof:
    mov     al, -1
    pop     rbx
    ret

; ============================================================================
; peek_next_char(lexer) -> char in al, or -1
; ============================================================================
peek_next_char:
    push    rbx
    push    r12
    mov     r12, ARG1
    mov     rax, [r12 + LEX_POS]
    inc     rax
    mov     rcx, [r12 + LEX_LENGTH]
    cmp     rax, rcx
    jae     .eof
    mov     rax, [r12 + LEX_SOURCE]
    add     rax, [r12 + LEX_POS]
    inc     rax
    movzx   eax, byte [rax]
    pop     r12
    pop     rbx
    ret
.eof:
    mov     al, -1
    pop     r12
    pop     rbx
    ret

; ============================================================================
; advance(lexer) — move position forward by 1, handle line/col tracking
; ============================================================================
advance:
    push    rbx
    push    r12
    mov     r12, ARG1
    mov     rax, [r12 + LEX_SOURCE]
    mov     rbx, [r12 + LEX_POS]
    add     rax, rbx
    movzx   eax, byte [rax]
    cmp     al, 10
    je      .newline
    cmp     al, 13
    je      .newline
    ; Regular character — just increment
    inc     qword [r12 + LEX_POS]
    inc     dword [r12 + LEX_COL]
    pop     r12
    pop     rbx
    ret
.newline:
    inc     qword [r12 + LEX_POS]
    inc     dword [r12 + LEX_LINE]
    mov     dword [r12 + LEX_COL], 1
    ; If CRLF, skip the LF too
    mov     rax, [r12 + LEX_SOURCE]
    mov     rbx, [r12 + LEX_POS]
    add     rax, rbx
    movzx   eax, byte [rax]
    cmp     al, 10
    jne     .newline_done
    inc     qword [r12 + LEX_POS]
.newline_done:
    pop     r12
    pop     rbx
    ret

; ============================================================================
; position(lexer) -> current position in rax
; ============================================================================
position:
    mov     rax, [ARG1 + LEX_POS]
    ret

; ============================================================================
; start_token(lexer) -> current position (for token start tracking)
; ============================================================================
start_token:
    mov     rax, [ARG1 + LEX_POS]
    add     rax, [ARG1 + LEX_SOURCE]
    ret

; ============================================================================
; current_line(lexer) -> line number
; ============================================================================
current_line:
    mov     eax, [ARG1 + LEX_LINE]
    ret

; ============================================================================
; current_col(lexer) -> column number
; ============================================================================
current_col:
    mov     eax, [ARG1 + LEX_COL]
    ret

; ============================================================================
; read_word(lexer) — read alphanumeric+underscore word
; Returns length in rax
; ============================================================================
read_word:
    push    rbx
    push    r12
    mov     r12, ARG1
    xor     rbx, rbx
.loop:
    mov     ARG1, r12
    call    peek_char
    cmp     al, 'A'
    jb      .check_lower
    cmp     al, 'Z'
    jbe     .good
.check_lower:
    cmp     al, 'a'
    jb      .check_digit
    cmp     al, 'z'
    jbe     .good
.check_digit:
    cmp     al, '0'
    jb      .done
    cmp     al, '9'
    jbe     .good
    cmp     al, '_'
    je      .good
    jmp     .done
.good:
    mov     ARG1, r12
    call    advance
    inc     rbx
    jmp     .loop
.done:
    mov     rax, rbx
    pop     r12
    pop     rbx
    ret

; ============================================================================
; count_indent(lexer) — count leading spaces on current line
; Returns indent level in rax
; ============================================================================
count_indent:
    push    rbx
    push    r12
    mov     r12, ARG1
    xor     rbx, rbx
.loop:
    mov     ARG1, r12
    call    peek_char
    cmp     al, 32
    jne     .check_tab
    inc     rbx
    mov     ARG1, r12
    call    advance
    jmp     .loop
.check_tab:
    cmp     al, 9
    jne     .done
    add     rbx, 4
    mov     ARG1, r12
    call    advance
    jmp     .loop
.done:
    mov     rax, rbx
    pop     r12
    pop     rbx
    ret

; ============================================================================
; push_indent_level(lexer, level) — push a new indent level onto the stack
; ============================================================================
push_indent_level:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2

    mov     eax, [r12 + LEX_INDENT_DEPTH]
    mov     ebx, [r12 + LEX_INDENT_CAP]
    cmp     eax, ebx
    jl      .have_space

    ; Grow indent stack
    add     ebx, ebx
    mov     [r12 + LEX_INDENT_CAP], ebx
    mov     ARG1, [r12 + LEX_INDENT_STACK]
    mov     edx, eax
    shl     edx, 2                      ; multiply by 4
    mov     r8d, ebx
    shl     r8d, 2                      ; multiply by 4
    call    ak_realloc
    mov     [r12 + LEX_INDENT_STACK], rax

.have_space:
    mov     rax, [r12 + LEX_INDENT_STACK]
    mov     ecx, [r12 + LEX_INDENT_DEPTH]
    mov     [rax + rcx * 4], r13d
    inc     dword [r12 + LEX_INDENT_DEPTH]

    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; classify_word(word, length) -> token type or 0 if identifier
; ARG1 = word pointer, ARG2 = length
; ============================================================================
classify_word:
    push    rbx
    push    r12
    push    r13
    push    r14
    mov     r12, ARG1
    mov     r13, ARG2
    xor     r14, r14

    lea     rbx, [kw_let]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_always
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_always:
    lea     rbx, [kw_always]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_show
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_show:
    lea     rbx, [kw_show]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_ask
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_ask:
    lea     rbx, [kw_ask]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_if
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_if:
    lea     rbx, [kw_if]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_else
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_else:
    lea     rbx, [kw_else]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_end
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_end:
    lea     rbx, [kw_end]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_repeat
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_repeat:
    lea     rbx, [kw_repeat]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_while
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_while:
    lea     rbx, [kw_while]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_for
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_for:
    lea     rbx, [kw_for]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_define
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_define:
    lea     rbx, [kw_define]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_make
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_make:
    lea     rbx, [kw_make]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_kind
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_kind:
    lea     rbx, [kw_kind]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_new
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_new:
    lea     rbx, [kw_new]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_try
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_try:
    lea     rbx, [kw_try]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_catch
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_catch:
    lea     rbx, [kw_catch]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_clicked
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_clicked:
    lea     rbx, [kw_clicked]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_match
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_match:
    lea     rbx, [kw_match]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_true
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_true:
    lea     rbx, [kw_true]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_false
    mov     r14, TOK_BOOL
    jmp     .done

.try_false:
    lea     rbx, [kw_false]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_empty
    mov     r14, TOK_BOOL
    jmp     .done

.try_empty:
    lea     rbx, [kw_empty]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_is
    mov     r14, TOK_EMPTY
    jmp     .done

.try_is:
    lea     rbx, [kw_is]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_plus
    mov     r14, TOK_IS
    jmp     .done

.try_plus:
    lea     rbx, [kw_plus]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_minus
    mov     r14, TOK_PLUS_WORD
    jmp     .done

.try_minus:
    lea     rbx, [kw_minus]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_times
    mov     r14, TOK_MINUS_WORD
    jmp     .done

.try_times:
    lea     rbx, [kw_times]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_mod
    mov     r14, TOK_TIMES_WORD
    jmp     .done

.try_mod:
    lea     rbx, [kw_mod]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_and
    mov     r14, TOK_MOD
    jmp     .done

.try_and:
    lea     rbx, [kw_and]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_or
    mov     r14, TOK_AND
    jmp     .done

.try_or:
    lea     rbx, [kw_or]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_not
    mov     r14, TOK_OR
    jmp     .done

.try_not:
    lea     rbx, [kw_not]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_between
    mov     r14, TOK_NOT
    jmp     .done

.try_between:
    lea     rbx, [kw_between]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_contains
    mov     r14, TOK_BETWEEN
    jmp     .done

.try_contains:
    lea     rbx, [kw_contains]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_list
    mov     r14, TOK_CONTAINS
    jmp     .done

.try_list:
    lea     rbx, [kw_list]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_map
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_map:
    lea     rbx, [kw_map]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_of
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_of:
    lea     rbx, [kw_of]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_type
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_type:
    lea     rbx, [kw_type]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_in
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_in:
    lea     rbx, [kw_in]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_taking
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_taking:
    lea     rbx, [kw_taking]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_behaviour
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_behaviour:
    lea     rbx, [kw_behaviour]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_when
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_when:
    lea     rbx, [kw_when]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_created
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_created:
    lea     rbx, [kw_created]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_bring
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_bring:
    lea     rbx, [kw_bring]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_button
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_button:
    lea     rbx, [kw_button]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_plot
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_plot:
    lea     rbx, [kw_plot]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_solve
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_solve:
    lea     rbx, [kw_solve]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_square
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_square:
    lea     rbx, [kw_square]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_has
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_has:
    lea     rbx, [kw_has]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_count
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_count:
    lea     rbx, [kw_count]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_do
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_do:
    lea     rbx, [kw_do]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_wait
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_wait:
    lea     rbx, [kw_wait]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_text
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_text:
    lea     rbx, [kw_text]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_number_t
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_number_t:
    lea     rbx, [kw_number_t]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_module
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_module:
    lea     rbx, [kw_module]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_test
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_test:
    lea     rbx, [kw_test]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_expect
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_expect:
    lea     rbx, [kw_expect]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_root
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_root:
    lea     rbx, [kw_root]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_run
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_run:
    lea     rbx, [kw_run]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_database
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_database:
    lea     rbx, [kw_database]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_server
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_server:
    lea     rbx, [kw_server]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_model
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_model:
    lea     rbx, [kw_model]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_otherwise
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_otherwise:
    lea     rbx, [kw_otherwise]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_times_word
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_times_word:
    lea     rbx, [kw_times]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .no_match
    mov     r14, TOK_TIMES_WORD
    jmp     .done

.try_protocol:
    lea     rbx, [kw_protocol]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_requires
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_requires:
    lea     rbx, [kw_requires]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_interface
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_interface:
    lea     rbx, [kw_interface]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_implements
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_implements:
    lea     rbx, [kw_implements]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_async
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_async:
    lea     rbx, [kw_async]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_await
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_await:
    lea     rbx, [kw_await]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_manual_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_manual_kw:
    lea     rbx, [kw_manual]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_memory_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_memory_kw:
    lea     rbx, [kw_memory]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_mode_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_mode_kw:
    lea     rbx, [kw_mode]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_results
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_results:
    lea     rbx, [kw_results]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_from_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_from_kw:
    lea     rbx, [kw_from]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_to_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_to_kw:
    lea     rbx, [kw_to]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_the_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_the_kw:
    lea     rbx, [kw_the]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_called_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_called_kw:
    lea     rbx, [kw_called]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_with_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_with_kw:
    lea     rbx, [kw_with]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_page_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_page_kw:
    lea     rbx, [kw_page]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_table_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_table_kw:
    lea     rbx, [kw_table]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_where_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_where_kw:
    lea     rbx, [kw_where]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_set_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_set_kw:
    lea     rbx, [kw_set]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_column_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_column_kw:
    lea     rbx, [kw_column]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_unique_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_unique_kw:
    lea     rbx, [kw_unique]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_required_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_required_kw:
    lea     rbx, [kw_required]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_default_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_default_kw:
    lea     rbx, [kw_default]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_add_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_add_kw:
    lea     rbx, [kw_add]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_remove_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_remove_kw:
    lea     rbx, [kw_remove]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_connect_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_connect_kw:
    lea     rbx, [kw_connect]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_input_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_input_kw:
    lea     rbx, [kw_input]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_all_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_all_kw:
    lea     rbx, [kw_all]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_first_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_first_kw:
    lea     rbx, [kw_first]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_send_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_send_kw:
    lea     rbx, [kw_send]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_go_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_go_kw:
    lea     rbx, [kw_go]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_create_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_create_kw:
    lea     rbx, [kw_create]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_find_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_find_kw:
    lea     rbx, [kw_find]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_update_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_update_kw:
    lea     rbx, [kw_update]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .try_values_kw
    mov     r14, TOK_KEYWORD
    jmp     .done

.try_values_kw:
    lea     rbx, [kw_values]
    mov     ARG1, r12
    mov     ARG2, r13
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .no_match
    mov     r14, TOK_KEYWORD
    jmp     .done

.no_match:
    xor     r14, r14

.done:
    mov     rax, r14
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; word_matches(word, word_len, keyword) -> non-zero if match
; ARG1 = word ptr, ARG2 = word length, r8 = keyword ptr
; ============================================================================
word_matches:
    push    rbx
    push    r12
    push    r13
    push    r14
    mov     r12, ARG1
    mov     r13, ARG2
    mov     r14, r8
    xor     rbx, rbx
.loop:
    mov     al, [r14 + rbx]
    test    al, al
    jz      .check_len
    cmp     rbx, r13
    jae     .no_match_real
    cmp     al, [r12 + rbx]
    jne     .no_match_real
    inc     rbx
    jmp     .loop
.check_len:
    cmp     rbx, r13
    jne     .no_match_real
    mov     rax, 1
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.no_match_real:
    xor     rax, rax
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; check_multi_keyword(lexer, word_start, word_len)
; Checks if current word + following words form a multi-word keyword
; Returns token type if matched, -1 if not multi, 0 if simple keyword
; If matched, advances lexer position past all consumed words
; ============================================================================
check_multi_keyword:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1
    mov     r13, ARG2
    mov     r14, ARG3

    ; Save position for rollback
    mov     r15, [r12 + LEX_POS]

    ; Check "divided by"
    lea     rbx, [kw_divided]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .check_greater
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 'b'
    jne     .rollback
    cmp     byte [rdi+1], 'y'
    jne     .rollback
    mov     rax, TOK_DIVIDE
    jmp     .matched

.check_greater:
    lea     rbx, [kw_greater]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .check_less
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .not_multi
    cmp     rax, 4
    jne     .not_multi_rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 't'
    jne     .not_multi_rollback
    cmp     byte [rdi+1], 'h'
    jne     .not_multi_rollback
    cmp     byte [rdi+2], 'a'
    jne     .not_multi_rollback
    cmp     byte [rdi+3], 'n'
    jne     .not_multi_rollback
    mov     rax, TOK_GREATER
    jmp     .matched

.check_less:
    lea     rbx, [kw_less]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .check_give_back
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .not_multi
    cmp     rax, 4
    jne     .not_multi_rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 't'
    jne     .not_multi_rollback
    cmp     byte [rdi+1], 'h'
    jne     .not_multi_rollback
    cmp     byte [rdi+2], 'a'
    jne     .not_multi_rollback
    cmp     byte [rdi+3], 'n'
    jne     .not_multi_rollback
    mov     rax, TOK_LESS
    jmp     .matched

.check_give_back:
    lea     rbx, [kw_give]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .check_for_each
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .not_multi
    cmp     rax, 4
    jne     .not_multi_rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 'b'
    jne     .not_multi_rollback
    cmp     byte [rdi+1], 'a'
    jne     .not_multi_rollback
    cmp     byte [rdi+2], 'c'
    jne     .not_multi_rollback
    cmp     byte [rdi+3], 'k'
    jne     .not_multi_rollback
    mov     rax, TOK_KEYWORD
    jmp     .matched

.check_for_each:
    lea     rbx, [kw_for]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .check_bring_in
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .not_multi
    cmp     rax, 4
    jne     .not_multi_rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 'e'
    jne     .not_multi_rollback
    cmp     byte [rdi+1], 'a'
    jne     .not_multi_rollback
    cmp     byte [rdi+2], 'c'
    jne     .not_multi_rollback
    cmp     byte [rdi+3], 'h'
    jne     .not_multi_rollback
    mov     rax, TOK_KEYWORD
    jmp     .matched

.check_bring_in:
    lea     rbx, [kw_bring]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .check_starts_with
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .not_multi
    cmp     rax, 2
    jne     .not_multi_rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 'i'
    jne     .not_multi_rollback
    cmp     byte [rdi+1], 'n'
    jne     .not_multi_rollback
    mov     rax, TOK_KEYWORD
    jmp     .matched

.check_starts_with:
    lea     rbx, [kw_starts]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .check_ends_with
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .not_multi
    cmp     rax, 4
    jne     .not_multi_rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 'w'
    jne     .not_multi_rollback
    cmp     byte [rdi+1], 'i'
    jne     .not_multi_rollback
    cmp     byte [rdi+2], 't'
    jne     .not_multi_rollback
    cmp     byte [rdi+3], 'h'
    jne     .not_multi_rollback
    mov     rax, 0
    jmp     .matched

.check_ends_with:
    lea     rbx, [kw_ends]
    mov     ARG1, r13
    mov     ARG2, r14
    mov     r8, rbx
    call    word_matches
    test    rax, rax
    jz      .not_multi
    mov     ARG1, r12
    call    read_word
    test    rax, rax
    jz      .not_multi
    cmp     rax, 4
    jne     .not_multi_rollback
    mov     rdi, [r12 + LEX_SOURCE]
    mov     rsi, [r12 + LEX_POS]
    sub     rsi, rax
    add     rdi, rsi
    cmp     byte [rdi], 'w'
    jne     .not_multi_rollback
    cmp     byte [rdi+1], 'i'
    jne     .not_multi_rollback
    cmp     byte [rdi+2], 't'
    jne     .not_multi_rollback
    cmp     byte [rdi+3], 'h'
    jne     .not_multi_rollback
    mov     rax, 0
    jmp     .matched

.not_multi_rollback:
    mov     [r12 + LEX_POS], r15
.not_multi:
    mov     rax, -1
    jmp     .done_multi

.matched:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.rollback:
    mov     [r12 + LEX_POS], r15
    mov     rax, -1

.done_multi:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; extract_word_token(lexer, start, length) — extract word into temp buffer
; Needed for multi-word keyword matching
; ============================================================================
extract_word_token:
    ret

; ============================================================================
; add_token(lexer, type, start, length) — append a token to the array
; ARG1 = lexer, ARG2 = type, ARG3 = start ptr, ARG4 (r8) = length
; ============================================================================
add_token:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, ARG1                   ; lexer
    mov     r13, ARG2                   ; type
    mov     r14, ARG3                   ; start
    mov     r15, r8                     ; length

    mov     eax, [r12 + LEX_COUNT]
    mov     ebx, [r12 + LEX_CAP]
    cmp     eax, ebx
    jl      .have_space

    ; Grow token array: double capacity
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx                        ; save old count for realloc

    mov     ecx, ebx
    add     ecx, ecx                    ; double capacity
    mov     [r12 + LEX_CAP], ecx

    ; Realloc: ak_realloc(old_ptr, old_size, new_size)
    mov     ARG1, [r12 + LEX_TOKENS]
    mov     edx, ebx
    imul    edx, TK_SIZE                ; old size in bytes
    mov     r8d, ecx
    imul    r8d, TK_SIZE                ; new size in bytes
    call    ak_realloc
    mov     [r12 + LEX_TOKENS], rax

    pop     rbx
    pop     r15
    pop     r14
    pop     r13
    pop     r12

.have_space:
    mov     rbx, [r12 + LEX_TOKENS]
    mov     eax, [r12 + LEX_COUNT]
    imul    rax, TK_SIZE
    add     rbx, rax

    mov     [rbx + TK_TYPE], r13d
    mov     [rbx + TK_START], r14
    mov     [rbx + TK_LEN], r15d
    mov     eax, [r12 + LEX_LINE]
    mov     [rbx + TK_LINE], eax
    mov     eax, [r12 + LEX_COL]
    mov     [rbx + TK_COL], eax

    inc     dword [r12 + LEX_COUNT]

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; add_single_char_token(lexer, type) — add a 1-char token at current pos
; ============================================================================
add_single_char_token:
    push    rbx
    push    r12
    mov     r12, ARG1
    mov     rbx, ARG2

    mov     rax, [r12 + LEX_SOURCE]
    add     rax, [r12 + LEX_POS]
    mov     ARG1, r12
    mov     ARG2, rbx
    mov     ARG3, rax
    mov     r8, 1
    call    add_token

    mov     ARG1, r12
    call    advance

    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_realloc(ptr, old_size, new_size) — resize a memory block
; Simple implementation: allocate new, copy, free old
; ============================================================================
ak_realloc:
    push    rbx
    push    r12
    push    r13
    push    r14
    mov     r12, ARG1                   ; old ptr
    mov     r13, ARG2                   ; old size
    mov     r14, ARG3                   ; new size

    mov     ARG1, r14
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     rbx, rax

    mov     ARG1, rbx
    mov     ARG2, r12
    mov     ARG3, r13
    call    ak_memcpy

    mov     ARG1, r12
    call    ak_free

    mov     rax, rbx
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; Error messages
; ============================================================================
msg_unterminated db "Unterminated string literal", 0

; ============================================================================
; External references
; ============================================================================
extern ak_malloc
extern ak_free
extern ak_memcpy
extern ak_print_str
extern ak_print_newline
extern ak_print_num
extern ak_error
extern ak_exit
extern ak_strcmp
extern ak_strlen
