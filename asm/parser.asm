; ============================================================================
; AK CODE Parser — Recursive-Descent AST Builder
; Walks the token stream from the lexer and produces an Abstract Syntax Tree.
; ============================================================================

%include "macros.inc"

default rel

; AST node type constants
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
NODE_SQRT         equ 47
NODE_MAKE_PAGE    equ 48
NODE_MAKE_BUTTON  equ 49
NODE_MAKE_INPUT   equ 50
NODE_EVENT        equ 51
NODE_GOTO         equ 52
NODE_SEND         equ 53
NODE_CONNECT_DB   equ 54
NODE_MAKE_TABLE   equ 55
NODE_CREATE_TABLE equ 56
NODE_INSERT       equ 57
NODE_FIND         equ 58
NODE_UPDATE       equ 59
NODE_DELETE       equ 60

; AST node struct offsets
AST_TYPE        equ 0   ; u32
AST_PAD         equ 4   ; padding
AST_CHILD_COUNT equ 8   ; u32
AST_CHILD_PAD   equ 12  ; padding
AST_CHILDREN    equ 16  ; ptr to children array (ptr*)
AST_VALUE_PTR   equ 24  ; ptr
AST_VALUE_LEN   equ 32  ; u32
AST_LINE        equ 36  ; u32
AST_COL         equ 40  ; u32
AST_NODE_SIZE   equ 48

; Parser state offsets
PS_TOKENS    equ 0  ; ptr
PS_COUNT     equ 8  ; u32
PS_POS       equ 12 ; u32
PS_AST       equ 16 ; ptr to root
PS_SYMBOLS   equ 24 ; ptr to symbol table

; Lexer state offsets (must match lexer.asm)
LEX_SOURCE       equ 0   ; ptr
LEX_LENGTH       equ 8   ; u64
LEX_POS          equ 16  ; u64
LEX_LINE         equ 24  ; u32
LEX_COL          equ 28  ; u32
LEX_TOKENS       equ 32  ; ptr
LEX_COUNT        equ 40  ; u32
LEX_CAP          equ 44  ; u32
LEX_INDENT_STACK equ 48  ; ptr
LEX_INDENT_DEPTH equ 56  ; u32
LEX_INDENT_CAP   equ 60  ; u32

; Token struct offsets (must match lexer.asm)
TK_TYPE  equ 0   ; u32
TK_PAD   equ 4   ; padding
TK_START equ 8   ; ptr
TK_LEN   equ 16  ; u32
TK_LINE  equ 20  ; u32
TK_COL   equ 24  ; u32
TK_SIZE  equ 28  ; total struct size

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
TOK_NEWLINE    equ 29
TOK_INDENT     equ 30
TOK_DEDENT     equ 31
TOK_EOF        equ 32
TOK_COMMENT    equ 33

section .data
    err_expected_token   db "Expected a different token here. Got '", 0
    err_unexpected_eof   db "Unexpected end of file in this construct.", 0
    err_expected_expr    db "Expected an expression here.", 0
    err_unknown_stmt     db "Unknown statement type.", 0
    err_missing_end      db "Missing 'end' keyword for this block.", 0
    err_missing_name     db "Expected a name here.", 0

section .text
    global ak_parse

; ============================================================================
; ak_parse(tokens) -> AST root node
; Tokens is a lexer state containing the token array and count
; ============================================================================
ak_parse:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 48

    mov     r12, ARG1                   ; token state (lexer)

    ; Allocate parser state
    mov     ARG1, 64
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax                    ; r13 = parser state

    ; Init parser state
    mov     [r13 + PS_TOKENS], r12
    mov     eax, [r12 + LEX_COUNT]
    mov     [r13 + PS_COUNT], eax
    mov     dword [r13 + PS_POS], 0

    ; Allocate program node
    mov     ARG1, AST_NODE_SIZE + 8 * 256
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r14, rax                    ; r14 = program node

    mov     dword [r14 + AST_TYPE], NODE_PROGRAM
    mov     dword [r13 + AST_CHILD_COUNT], 0
    mov     qword [r14 + AST_CHILDREN], 0
    mov     qword [r14 + AST_VALUE_PTR], 0
    mov     dword [r14 + AST_VALUE_LEN], 0

    ; Set up children array pointer
    lea     rax, [r14 + AST_NODE_SIZE]
    mov     [r14 + AST_CHILDREN], rax

    xor     r15, r15                   ; child count

.parse_loop:
    mov     ARG1, r13
    call    peek_token_type
    cmp     eax, TOK_EOF
    je      .done
    cmp     eax, TOK_NEWLINE
    je      .consume_nl

    ; Parse one statement
    mov     ARG1, r13
    call    parse_statement
    test    rax, rax
    jz      .consume_skip
    ; Add child to program
    mov     rcx, [r14 + AST_CHILDREN]
    mov     [rcx + r15 * 8], rax
    inc     r15
    mov     [r14 + AST_CHILD_COUNT], r15d

.consume_skip:
    jmp     .parse_loop

.consume_nl:
    mov     ARG1, r13
    call    consume_token
    jmp     .parse_loop

.done:
    mov     rax, r14
    add     rsp, 48
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.fail:
    xor     rax, rax
    add     rsp, 48
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_statement(parser) -> AST node or 0
; Dispatches based on the current token
; ============================================================================
parse_statement:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 32

    mov     r12, ARG1

    mov     ARG1, r12
    call    peek_token_type
    mov     r13d, eax

    ; Dispatch based on keyword
    cmp     r13d, TOK_KEYWORD
    jne     .check_identifier

    ; It's a keyword — determine which one
    mov     ARG1, r12
    call    peek_token_text
    mov     r14, rax                    ; token text pointer

    ; Check keyword by first few characters
    test    r14, r14
    jz      .try_expression
    mov     al, [r14]
    cmp     al, 'l'
    je      .check_let
    cmp     al, 'a'
    je      .check_always_ask
    cmp     al, 's'
    je      .check_show
    cmp     al, 'i'
    je      .check_i_keywords
    cmp     al, 'e'
    je      .check_else_end
    cmp     al, 'r'
    je      .check_repeat
    cmp     al, 'f'
    je      .check_for
    cmp     al, 'c'
    je      .check_c_keywords
    cmp     al, 'd'
    je      .check_define_do
    cmp     al, 'm'
    je      .check_make_match
    cmp     al, 'n'
    je      .check_new
    cmp     al, 't'
    je      .check_try_train
    cmp     al, 'b'
    je      .check_b_keywords
    cmp     al, 'w'
    je      .check_wait_when
    cmp     al, 'p'
    je      .check_p_keywords
    cmp     al, 'g'
    je      .check_g_keywords
    cmp     al, 'u'
    je      .check_u_keywords
    cmp     al, 'v'
    je      .check_visualize
    jmp     .try_expression

.check_let:
    ; Could be "let"
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_let
    jmp     .done_stmt

.check_always_ask:
    cmp     byte [r14+1], 'l'           ; "always"
    je      .check_always
    cmp     byte [r14+1], 's'           ; "ask" or "async"
    je      .check_ask_async
    cmp     byte [r14+1], 'w'           ; "await"
    je      .check_await_stmt
    cmp     byte [r14+1], 'd'           ; "add"
    je      .check_add
    jmp     .try_expression

.check_add:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_insert
    jmp     .done_stmt

.check_ask_async:
    cmp     byte [r14+2], 'k'           ; "ask"
    je      .check_ask
    cmp     byte [r14+2], 'y'           ; "async"
    je      .check_async_stmt
    jmp     .try_expression

.check_always:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_always
    jmp     .done_stmt

.check_ask:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_ask
    jmp     .done_stmt

.check_async_stmt:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_async_stmt
    jmp     .done_stmt

.check_await_stmt:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_await_stmt
    jmp     .done_stmt

.check_show:
    cmp     byte [r14+1], 'h'           ; "show"
    je      .do_show
    cmp     byte [r14+1], 'e'           ; "send"
    je      .check_send
    jmp     .try_expression             ; "square" handled as expression

.do_show:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_show
    jmp     .done_stmt

.check_send:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_send
    jmp     .done_stmt

.check_i_keywords:
    cmp     byte [r14+1], 'f'           ; "if"
    je      .check_if
    cmp     byte [r14+1], 'n'           ; "in"
    je      .check_in_manual
    jmp     .try_expression

.check_if:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_if
    jmp     .done_stmt

.check_in_manual:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_manual_memory
    jmp     .done_stmt

.check_else_end:
    cmp     byte [r14+2], 'p'           ; "expect"
    je      .check_expect_stmt
    ; These are handled by block parsers; at top level they're errors
    xor     rax, rax
    jmp     .done_stmt

.check_expect_stmt:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expect
    jmp     .done_stmt

.check_repeat:
    cmp     byte [r14+1], 'u'           ; "run"
    je      .check_run
    cmp     byte [r14+1], 'e'
    jne     .try_expression
    cmp     byte [r14+2], 'p'           ; "repeat"
    je      .do_repeat
    cmp     byte [r14+2], 'm'           ; "remove"
    je      .check_remove
    jmp     .try_expression

.do_repeat:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_repeat
    jmp     .done_stmt

.check_remove:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_delete
    jmp     .done_stmt

.check_run:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_run_tests
    jmp     .done_stmt

.check_for:
    cmp     byte [r14+1], 'o'           ; "for"
    je      .do_for
    cmp     byte [r14+1], 'i'           ; "find"
    je      .check_find
    jmp     .try_expression

.do_for:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_for
    jmp     .done_stmt

.check_find:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_find
    jmp     .done_stmt

.check_c_keywords:
    cmp     byte [r14+1], 'o'
    je      .check_co_words
    cmp     byte [r14+1], 'r'           ; "create"
    je      .check_create
    jmp     .try_expression

.check_co_words:
    cmp     byte [r14+2], 'u'           ; "count"
    je      .do_count
    cmp     byte [r14+2], 'n'           ; "connect"
    je      .check_connect
    jmp     .try_expression

.do_count:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_count_from
    jmp     .done_stmt

.check_connect:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_connect_db
    jmp     .done_stmt

.check_create:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_create_table
    jmp     .done_stmt

.check_define_do:
    cmp     byte [r14+1], 'e'
    je      .check_define
    cmp     byte [r14+1], 'o'
    je      .check_do
    jmp     .try_expression

.check_define:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_define
    jmp     .done_stmt

.check_do:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_do_in_background
    jmp     .done_stmt

.check_make_match:
    cmp     byte [r14+1], 'a'           ; "make"
    je      .check_make
    cmp     byte [r14+1], 'a'           ; "match"
    jmp     .check_match

    ; Actually "make" and "match" both have 'a' as second letter
    ; "make" -> 'k' as third, "match" -> 't' as third
    cmp     byte [r14+2], 'k'
    je      .check_make
    cmp     byte [r14+2], 't'
    je      .check_match

.check_make:
    mov     ARG1, r12
    call    consume_token               ; consume "make"
    ; Check next keyword to determine type
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .try_expression
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'k'                     ; "kind"
    je      .do_make_kind
    cmp     al, 'p'                     ; "page"
    je      .do_make_page
    cmp     al, 'b'                     ; "button"
    je      .do_make_button
    cmp     al, 'i'                     ; "input"
    je      .do_make_input
    cmp     al, 't'                     ; "table"
    je      .do_make_table
    jmp     .try_expression

.do_make_kind:
    mov     ARG1, r12
    call    parse_make_kind
    jmp     .done_stmt

.do_make_page:
    mov     ARG1, r12
    call    parse_make_page
    jmp     .done_stmt

.do_make_button:
    mov     ARG1, r12
    call    parse_make_button
    jmp     .done_stmt

.do_make_input:
    mov     ARG1, r12
    call    parse_make_input
    jmp     .done_stmt

.do_make_table:
    mov     ARG1, r12
    call    parse_make_table
    jmp     .done_stmt

.check_match:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_match
    jmp     .done_stmt

.check_new:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_new
    jmp     .done_stmt

.check_try_train:
    cmp     byte [r14+2], 'y'           ; "try"
    je      .check_try
    cmp     byte [r14+2], 's'           ; "test"
    je      .check_test_like
    cmp     byte [r14+2], 'a'           ; "train"
    je      .check_train
    jmp     .try_expression

.check_test_like:
    mov     ARG1, r12
    call    consume_token               ; consume "test"
    ; Check if next token is "suite"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .test_is_individual
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 's'
    jne     .test_is_individual
    mov     ARG1, r12
    call    consume_token               ; consume "suite"
    mov     ARG1, r12
    call    parse_test_suite
    jmp     .done_stmt
.test_is_individual:
    mov     ARG1, r12
    call    parse_test
    jmp     .done_stmt

.check_try:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_try
    jmp     .done_stmt

.check_train:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_train
    jmp     .done_stmt

.check_b_keywords:
    cmp     byte [r14+1], 'r'           ; "bring"
    je      .check_bring
    cmp     byte [r14+1], 'e'           ; "behaviour"
    je      .check_behaviour_lambda
    jmp     .try_expression

.check_bring:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_bring_in
    jmp     .done_stmt

.check_behaviour_lambda:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_lambda
    jmp     .done_stmt

.check_wait_when:
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax+1]
    cmp     al, 'a'                     ; "wait"
    je      .check_wait
    cmp     al, 'h'                     ; "when"
    je      .check_when
    jmp     .try_expression

.check_wait:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_wait
    jmp     .done_stmt

.check_when:
    ; Save position and peek ahead to distinguish "when name is clicked" from route
    mov     r15d, [r12 + PS_POS]        ; save position (at "when")
    mov     ARG1, r12
    call    consume_token               ; consume "when"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .when_is_route
    ; Check token after identifier
    mov     r14d, [r12 + PS_POS]        ; position at identifier
    inc     dword [r12 + PS_POS]        ; skip identifier
    mov     ARG1, r12
    call    peek_token_type
    mov     ebx, eax
    mov     [r12 + PS_POS], r14d        ; restore to identifier
    mov     [r12 + PS_POS], r15d        ; restore to "when"
    cmp     ebx, TOK_IS
    je      .when_is_clicked

.when_is_route:
    mov     [r12 + PS_POS], r15d        ; restore to "when"
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_when_block
    jmp     .done_stmt

.when_is_clicked:
    ; position restored to "when" already
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_when_clicked
    jmp     .done_stmt

.check_p_keywords:
    cmp     byte [r14+1], 'l'           ; "plot"
    je      .check_plot
    cmp     byte [r14+1], 'r'           ; "protocol"
    je      .check_protocol
    jmp     .try_expression

.check_plot:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_plot
    jmp     .done_stmt

.check_protocol:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_protocol_def
    jmp     .done_stmt

.check_g_keywords:
    cmp     byte [r14+1], 'i'           ; "give"
    je      .do_give_back
    cmp     byte [r14+1], 'o'           ; "go"
    je      .check_go
    jmp     .try_expression

.do_give_back:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_give_back
    jmp     .done_stmt

.check_go:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_goto
    jmp     .done_stmt

.check_u_keywords:
    cmp     byte [r14+1], 'p'           ; "update"
    je      .do_update
    jmp     .try_expression

.do_update:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_update
    jmp     .done_stmt

.check_visualize:
    xor     rax, rax                    ; not yet implemented
    jmp     .done_stmt

.check_identifier:
    ; It's not a keyword statement — try as expression statement (function call, etc.)
.try_expression:
    mov     ARG1, r12
    call    parse_expression
    jmp     .done_stmt

.done_stmt:
    add     rsp, 32
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_let(parser) -> NODE_LET
; let <name> = <expression>
; ============================================================================
parse_let:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24

    mov     r12, ARG1

    ; Allocate node
    mov     ARG1, AST_NODE_SIZE + 16   ; 2 children (name, value)
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_LET
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    mov     qword [r13 + AST_VALUE_PTR], 0
    mov     dword [r13 + AST_VALUE_LEN], 0

    ; Expect identifier (variable name)
    mov     ARG1, r12
    call    consume_token
    cmp     eax, TOK_IDENTIFIER
    jne     .expected_name

    ; Create identifier node for the name
    mov     ARG1, r12
    mov     ARG2, r13
    call    add_child_from_last_token
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect '='
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EQUALS
    jne     .expected_equals
    mov     ARG1, r12
    call    consume_token

    ; Parse the value expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .expected_expr

    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx + 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.expected_name:
    lea     ARG1, [err_missing_name]
    call    parser_error
    xor     rax, rax
    jmp     .exit
.expected_equals:
    lea     ARG1, [err_expected_token]
    call    parser_error
    xor     rax, rax
    jmp     .exit
.expected_expr:
    lea     ARG1, [err_expected_expr]
    call    parser_error
    xor     rax, rax

.exit:
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_show(parser) -> NODE_SHOW
; show <expression>+
; ============================================================================
parse_show:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 16  ; up to 16 items
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_SHOW
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    xor     r14, r14

.parse_args:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_NEWLINE
    je      .done
    cmp     eax, TOK_EOF
    je      .done
    cmp     eax, TOK_KEYWORD            ; next statement
    je      .done

    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .done

    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx + r14 * 8], rax
    inc     r14
    mov     [r13 + AST_CHILD_COUNT], r14d
    jmp     .parse_args

.done:
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_if(parser) -> NODE_IF
; if <condition> <body> [else if <condition> <body>] [else <body>] end
; ============================================================================
parse_if:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_IF
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Parse condition
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .expected_cond

    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    mov     dword [r13 + AST_CHILD_COUNT], 1

    ; Parse body statements until else/else if/end
    call    parse_block_body
    ; Returns count of body nodes appended

    ; Check for else/else if
.check_else:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .check_end

    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'e'
    jne     .check_end

    ; Could be "else" or "end"
    cmp     byte [rax+1], 'l'           ; "else"
    je      .parse_else
    cmp     byte [rax+1], 'n'           ; "end"
    je      .end_if

.check_end:
    cmp     eax, TOK_EOF
    jne     .check_else
    jmp     .missing_end

.parse_else:
    mov     ARG1, r12
    call    consume_token

    ; Check if it's "else if"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .plain_else
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'i'
    jne     .plain_else
    cmp     byte [rax+1], 'f'
    jne     .plain_else

    ; It's "else if"
    ; Create an else_if node
    mov     ARG1, AST_NODE_SIZE + 8 * 4
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_ELSE_IF
    mov     dword [r14 + AST_CHILD_COUNT], 0
    lea     rax, [r14 + AST_NODE_SIZE]
    mov     [r14 + AST_CHILDREN], rax

    mov     ARG1, r12
    call    consume_token             ; consume "if"

    ; Parse else-if condition
    mov     ARG1, r12
    call    parse_expression
    mov     rcx, [r14 + AST_CHILDREN]
    mov     [rcx], rax
    mov     dword [r14 + AST_CHILD_COUNT], 1

    ; Parse else-if body
    call    parse_block_body

    ; Add as child of if node
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    jmp     .check_else

.plain_else:
    ; It's just "else"
    mov     ARG1, AST_NODE_SIZE + 8 * 4
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_ELSE
    mov     dword [r14 + AST_CHILD_COUNT], 0
    lea     rax, [r14 + AST_NODE_SIZE]
    mov     [r14 + AST_CHILDREN], rax

    ; Parse else body
    call    parse_block_body

    ; Add as child of if node
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Fall through to check end

.end_if:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    je      .check_end_kw
    jmp     .missing_end

.check_end_kw:
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .missing_end
    cmp     byte [rax+1], 'n'
    jne     .missing_end
    cmp     byte [rax+2], 'd'
    jne     .missing_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.missing_end:
    lea     ARG1, [err_missing_end]
    call    parser_error
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.expected_cond:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_give_back(parser) -> NODE_GIVE_BACK
; give back <expression>
; ============================================================================
parse_give_back:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 24

    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_GIVE_BACK
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Parse optional return value
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_NEWLINE
    je      .done
    cmp     eax, TOK_EOF
    je      .done
    cmp     eax, TOK_KEYWORD
    je      .done

    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .done

    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    mov     dword [r13 + AST_CHILD_COUNT], 1

.done:
    mov     rax, r13
    add     rsp, 24
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    add     rsp, 24
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_expression(parser) -> AST node
; Handles: identifiers, strings, numbers, decimals, bools, empty,
;          binops (plus, minus, times, divided by, mod, to the power of),
;          comparisons (is, greater than, less than, etc.),
;          function calls, dot access, list/map literals
; ============================================================================
parse_expression:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 40

    mov     r12, ARG1

    mov     ARG1, r12
    call    peek_token_type
    mov     r13d, eax
    mov     r14, rax

    ; Dispatch based on token type
    cmp     r13d, TOK_STRING
    je      .parse_string
    cmp     r13d, TOK_NUMBER
    je      .parse_number
    cmp     r13d, TOK_DECIMAL
    je      .parse_decimal
    cmp     r13d, TOK_BOOL
    je      .parse_bool
    cmp     r13d, TOK_EMPTY
    je      .parse_empty
    cmp     r13d, TOK_IDENTIFIER
    je      .parse_ident_or_call
    cmp     r13d, TOK_KEYWORD
    je      .parse_keyword_expr
    cmp     r13d, TOK_LPAREN
    je      .parse_paren
    cmp     r13d, TOK_LBRACKET
    je      .parse_list
    cmp     r13d, TOK_NOT
    je      .parse_not

    ; Not an expression
    xor     rax, rax
    jmp     .done_expr

.parse_string:
    mov     ARG1, r12
    call    make_literal_node
    jmp     .done_expr

.parse_number:
    mov     ARG1, r12
    call    make_literal_node
    jmp     .done_expr

.parse_decimal:
    mov     ARG1, r12
    call    make_literal_node
    jmp     .done_expr

.parse_bool:
    mov     ARG1, r12
    call    make_literal_node
    jmp     .done_expr

.parse_empty:
    mov     ARG1, r12
    call    make_literal_node
    jmp     .done_expr

.parse_ident_or_call:
    ; Could be: identifier, function call, or start of binop/comparison
    ; Read the identifier
    mov     ARG1, r12
    call    make_identifier_node
    mov     r15, rax                    ; r15 = identifier node

    ; Check what follows
    mov     ARG1, r12
    call    peek_token_type
    mov     r13d, eax

    ; If followed by operator keywords, build binop
    cmp     r13d, TOK_PLUS_WORD
    je      .make_binop
    cmp     r13d, TOK_MINUS_WORD
    je      .make_binop
    cmp     r13d, TOK_TIMES_WORD
    je      .make_binop
    cmp     r13d, TOK_DIVIDE
    je      .make_binop
    cmp     r13d, TOK_MOD
    je      .make_binop
    cmp     r13d, TOK_POWER
    je      .make_binop
    cmp     r13d, TOK_IS
    je      .make_comparison
    cmp     r13d, TOK_AND
    je      .make_binop
    cmp     r13d, TOK_OR
    je      .make_binop
    cmp     r13d, TOK_GREATER
    je      .make_comparison
    cmp     r13d, TOK_LESS
    je      .make_comparison
    cmp     r13d, TOK_BETWEEN
    je      .make_comparison
    cmp     r13d, TOK_CONTAINS
    je      .make_comparison
    cmp     r13d, TOK_DOT
    je      .make_dot_access
    cmp     r13d, TOK_LPAREN
    je      .make_function_call

    ; Otherwise just return the identifier (as a variable reference or function call with no parens)
    ; Check if it looks like a function call (next token is another expression)
    ; For now, if followed by anything other than newline/eof/keyword, treat as call
    cmp     r13d, TOK_NEWLINE
    je      .ident_done
    cmp     r13d, TOK_EOF
    je      .ident_done
    cmp     r13d, TOK_KEYWORD
    je      .ident_done

    ; It's a function call: ident(arg1 arg2 ...)
    ; Convert the identifier node into a call node
    mov     rax, r15
    ; Save identifier info
    push    r15
    ; Create call node
    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    mov     r15, rax
    mov     dword [r15 + AST_TYPE], NODE_CALL
    mov     dword [r15 + AST_CHILD_COUNT], 0
    lea     rax, [r15 + AST_NODE_SIZE]
    mov     [r15 + AST_CHILDREN], rax
    pop     rcx                         ; function name node
    mov     [r15 + AST_CHILDREN], rcx
    mov     dword [r15 + AST_CHILD_COUNT], 1
    mov     r14, 1                      ; child count so far

    ; Parse arguments
.call_args:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_NEWLINE
    je      .call_done
    cmp     eax, TOK_EOF
    je      .call_done
    cmp     eax, TOK_KEYWORD
    je      .call_done
    cmp     eax, TOK_DOT               ; dot access on call result
    je      .call_done

    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .call_done

    mov     rcx, [r15 + AST_CHILDREN]
    mov     [rcx + r14 * 8], rax
    inc     r14
    mov     [r15 + AST_CHILD_COUNT], r14d
    jmp     .call_args

.call_done:
    mov     rax, r15
    jmp     .done_expr

.ident_done:
    mov     rax, r15
    jmp     .done_expr

.parse_keyword_expr:
    ; Some keywords can be expressions (like "list of", "map", "behaviour")
    mov     ARG1, r12
    call    peek_token_text
    mov     r14, rax
    mov     al, [r14]
    cmp     al, 'l'
    je      .check_list_kw
    cmp     al, 'm'
    je      .check_map_kw
    cmp     al, 's'
    je      .check_size_kw
    cmp     al, 'f'
    je      .check_first_kw
    cmp     al, 'b'
    je      .check_lambda_kw
    jmp     .not_expr

.check_lambda_kw:
    ; "behaviour" keyword as lambda expression
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_lambda
    jmp     .done_expr

.check_list_kw:
    cmp     byte [r14+1], 'i'
    jne     .not_expr
    ; "list" keyword -> list literal
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_list_literal
    jmp     .done_expr

.check_map_kw:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_map_literal
    jmp     .done_expr

.check_size_kw:
    cmp     byte [r14+1], 'i'           ; "size"
    je      .do_size_expr
    cmp     byte [r14+1], 'q'           ; "square"
    je      .do_square_expr
    jmp     .not_expr
.do_size_expr:
    mov     ARG1, r12
    call    consume_token               ; consume "size"
    mov     ARG1, r12
    call    consume_token               ; consume "of"
    mov     ARG1, r12
    call    parse_expression
    jmp     .done_expr
.do_square_expr:
    mov     ARG1, r12
    call    consume_token               ; consume "square"
    mov     ARG1, r12
    call    parse_square_root
    jmp     .done_expr

.check_first_kw:
    mov     ARG1, r12
    call    consume_token
    ; "first item of <expr>" or "last item of <expr>"
    mov     ARG1, r12
    call    consume_token              ; consume "item"
    mov     ARG1, r12
    call    consume_token              ; consume "of"
    mov     ARG1, r12
    call    parse_expression
    jmp     .done_expr

.not_expr:
    xor     rax, rax
    jmp     .done_expr

.parse_paren:
    mov     ARG1, r12
    call    consume_token              ; consume '('
    mov     ARG1, r12
    call    parse_expression
    push    rax
    mov     ARG1, r12
    call    consume_token              ; consume ')'
    pop     rax
    jmp     .done_expr

.parse_list:
    mov     ARG1, r12
    call    consume_token              ; consume '['
    mov     ARG1, r12
    call    parse_list_literal
    jmp     .done_expr

.parse_not:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    ; Wrap in UNOP node
    push    rax
    mov     ARG1, AST_NODE_SIZE + 16
    call    ak_malloc
    pop     rcx
    mov     dword [rax + AST_TYPE], NODE_UNOP
    mov     dword [rax + AST_CHILD_COUNT], 1
    lea     rdx, [rax + AST_NODE_SIZE]
    mov     [rax + AST_CHILDREN], rdx
    mov     [rdx], rcx
    ; Store "not" info in value
    mov     qword [rax + AST_VALUE_PTR], 0
    mov     dword [rax + AST_VALUE_LEN], 1  ; type=not
    jmp     .done_expr

.make_binop:
    ; r15 = left operand, next token is operator
    mov     r14, r13                     ; operator type
    mov     ARG1, r12
    call    consume_token               ; consume operator

    ; Create binop node
    push    r15
    push    r14
    mov     ARG1, AST_NODE_SIZE + 24
    call    ak_malloc
    pop     r14
    pop     r15
    mov     dword [rax + AST_TYPE], NODE_BINOP
    mov     dword [rax + AST_CHILD_COUNT], 2
    lea     rcx, [rax + AST_NODE_SIZE]
    mov     [rax + AST_CHILDREN], rcx
    mov     [rcx], r15                  ; left child
    mov     dword [rax + AST_VALUE_LEN], r14d ; operator type

    ; Parse right operand
    mov     ARG1, r12
    call    parse_expression
    mov     rcx, [rax + AST_CHILDREN]
    add     rcx, 8
    mov     [rcx], rax

    jmp     .done_expr

.make_comparison:
    ; TODO: implement comparison parsing
    ; For now, return the identifier
    mov     rax, r15
    jmp     .done_expr

.make_dot_access:
    ; identifier.property
    mov     ARG1, r12
    call    consume_token              ; consume '.'
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_IDENTIFIER
    jne     .dot_fail

    mov     ARG1, r12
    call    make_identifier_node
    mov     rcx, rax

    ; Create dot_access node
    push    r15
    push    rcx
    mov     ARG1, AST_NODE_SIZE + 16
    call    ak_malloc
    pop     rcx
    pop     r15
    mov     dword [rax + AST_TYPE], NODE_DOT_ACCESS
    mov     dword [rax + AST_CHILD_COUNT], 2
    lea     rdx, [rax + AST_NODE_SIZE]
    mov     [rax + AST_CHILDREN], rdx
    mov     [rdx], r15
    mov     [rdx + 8], rcx
    jmp     .done_expr

.dot_fail:
    xor     rax, rax
    jmp     .done_expr

.make_function_call:
    ; identifier(...)
    mov     ARG1, r12
    call    consume_token              ; consume '('

    ; Create call node
    push    r15
    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    mov     r14, rax
    pop     rcx
    mov     dword [r14 + AST_TYPE], NODE_CALL
    mov     dword [r14 + AST_CHILD_COUNT], 1
    lea     rax, [r14 + AST_NODE_SIZE]
    mov     [r14 + AST_CHILDREN], rax
    mov     [rax], rcx

    xor     r15d, r15d                  ; arg count (first is function name)

.call_arg_loop:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_RPAREN
    je      .end_call_args
    cmp     eax, TOK_EOF
    je      .end_call_args

    ; Check for comma
    cmp     eax, TOK_COMMA
    jne     .parse_call_arg
    mov     ARG1, r12
    call    consume_token
    jmp     .call_arg_loop

.parse_call_arg:
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .end_call_args

    inc     r15d
    mov     rcx, [r14 + AST_CHILDREN]
    mov     [rcx + r15 * 8], rax
    mov     [r14 + AST_CHILD_COUNT], r15d
    inc     r15d                        ; keep index
    jmp     .call_arg_loop

.end_call_args:
    mov     ARG1, r12
    call    consume_token              ; consume ')'

    mov     rax, r14
    jmp     .done_expr

.done_expr:
    add     rsp, 40
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; make_literal_node(parser) -> AST node (NODE_LITERAL)
; Consumes current token and creates a literal node
; ============================================================================
make_literal_node:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 16

    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_LITERAL
    mov     dword [r13 + AST_CHILD_COUNT], 0

    ; Get current token info
    push    r13
    mov     ARG1, r12
    call    peek_token_type
    pop     r13

    mov     dword [r13 + AST_VALUE_LEN], eax  ; store token type

    ; Get token text pointer
    push    r13
    mov     ARG1, r12
    call    peek_token_text
    pop     r13
    mov     [r13 + AST_VALUE_PTR], rax

    ; Consume the token
    push    r13
    mov     ARG1, r12
    call    consume_token
    pop     r13

    mov     rax, r13
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; make_identifier_node(parser) -> AST node (NODE_IDENTIFIER)
; ============================================================================
make_identifier_node:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 16

    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r13 + AST_CHILD_COUNT], 0
    mov     dword [r13 + AST_VALUE_LEN], 0

    ; Get token text
    push    r13
    mov     ARG1, r12
    call    peek_token_text
    pop     r13
    mov     [r13 + AST_VALUE_PTR], rax

    ; Store length TODO
    ; Consume the token
    push    r13
    mov     ARG1, r12
    call    consume_token
    pop     r13

    mov     rax, r13
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_list_literal(parser) -> NODE_LIST_LITERAL
; list of <expr> <expr> ...
; or [<expr>, <expr>, ...]
; ============================================================================
parse_list_literal:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24

    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_LIST_LITERAL
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    xor     r14, r14

    ; Check if started with '[' (from parse_expression)
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_RBRACKET
    je      .empty_list

    ; Check for "of" keyword (from "list of ...")
    cmp     eax, TOK_KEYWORD
    jne     .parse_elements
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'o'
    jne     .parse_elements
    cmp     byte [rax+1], 'f'
    jne     .parse_elements
    mov     ARG1, r12
    call    consume_token              ; consume "of"

.parse_elements:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_RBRACKET
    je      .close_bracket
    cmp     eax, TOK_EOF
    je      .done_list
    cmp     eax, TOK_NEWLINE
    je      .next_element

    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .next_element

    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx + r14 * 8], rax
    inc     r14
    mov     [r13 + AST_CHILD_COUNT], r14d

.next_element:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_COMMA
    je      .consume_comma
    jmp     .parse_elements

.consume_comma:
    mov     ARG1, r12
    call    consume_token
    jmp     .parse_elements

.close_bracket:
    mov     ARG1, r12
    call    consume_token              ; consume ']'

.empty_list:
.done_list:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_block_body(parser) — parse statements until end/else/else if
; Modifies the parent node's children array (appending body nodes)
; ============================================================================
parse_block_body:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, ARG1
    mov     r13, ARG2                   ; parent node (if in r13 via caller convention)

    ; We need the parent node (r13 from caller)
    ; This function is called with r13 = parent node
    xor     r14, r14

.body_loop:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_EOF
    je      .done
    cmp     eax, TOK_KEYWORD
    jne     .parse_body_stmt

    ; Check for end, else, else if
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'e'
    jne     .parse_body_stmt
    ; "end", "else"
    cmp     byte [rax+1], 'n'
    je      .done                       ; "end" — done
    cmp     byte [rax+1], 'l'
    je      .done                       ; "else" — done (handled by caller)
    cmp     byte [rax+1], 'l'
    ; Actually let's just check for "end"
    cmp     byte [rax+1], 'n'
    je      .done

.parse_body_stmt:
    mov     ARG1, r12
    call    parse_statement
    test    rax, rax
    jz      .consume_skip

    ; Add as child to parent node
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.consume_skip:
    jmp     .body_loop

.done:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; Helper functions
; ============================================================================

; peek_token_type(parser) -> token type
peek_token_type:
    mov     rax, [ARG1 + PS_TOKENS]     ; lexer state
    mov     rax, [rax + LEX_TOKENS]     ; token array
    mov     ecx, [ARG1 + PS_POS]       ; position
    imul    rcx, TK_SIZE
    mov     eax, [rax + rcx + TK_TYPE]
    ret

; peek_token_text(parser) -> pointer to token text in source
peek_token_text:
    mov     rax, [ARG1 + PS_TOKENS]     ; lexer state
    mov     rax, [rax + LEX_TOKENS]     ; token array
    mov     ecx, [ARG1 + PS_POS]        ; position
    imul    rcx, TK_SIZE
    mov     rax, [rax + rcx + TK_START] ; token start pointer
    ret

; consume_token(parser) -> token type
consume_token:
    mov     eax, [ARG1 + PS_POS]
    inc     dword [ARG1 + PS_POS]
    mov     rax, [ARG1 + PS_TOKENS]     ; lexer state
    mov     rcx, [rax + LEX_TOKENS]    ; token array
    mov     edx, [ARG1 + PS_POS]
    dec     edx
    imul    rdx, TK_SIZE
    mov     eax, [rcx + rdx + TK_TYPE]
    ret

; expect_token(parser) -> token type without consuming
expect_token:
    mov     eax, [ARG1 + PS_POS]
    mov     rcx, [ARG1 + PS_TOKENS]     ; lexer state
    mov     rcx, [rcx + LEX_TOKENS]    ; token array
    imul    rax, TK_SIZE
    mov     eax, [rcx + rax + TK_TYPE]
    ret

; parser_error(message) — print parse error with context
parser_error:
    push    r12
    mov     r12, ARG1
    ; Get current token line/col
    mov     rax, [rsp + 8]             ; return address
    ; For now, just print the message
    mov     ARG1, r12
    call    ak_print_str
    call    ak_print_newline
    pop     r12
    ret

; add_child_from_last_token(parser, node) — add a child node from the last consumed token
add_child_from_last_token:
    ret

; ============================================================================
; Fully implemented parsers for all AK CODE constructs
; ============================================================================

; ============================================================================
; parse_always(parser) -> AST node
; "always NAME = expression"
; Same structure as let but uses NODE_ALWAYS
; ============================================================================
parse_always:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 16
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_ALWAYS
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    mov     ARG1, r12
    call    consume_token
    cmp     eax, TOK_IDENTIFIER
    jne     .expected_name
    mov     rcx, [r13 + AST_CHILDREN]
    mov     r14, rcx
    mov     rax, [r12 + PS_TOKENS]
    mov     rax, [rax + LEX_TOKENS]
    mov     edx, [r12 + PS_POS]
    dec     edx
    imul    rdx, TK_SIZE
    ; Create identifier node
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     rbx, rax
    mov     dword [rbx + AST_TYPE], NODE_IDENTIFIER
    mov     dword [rbx + AST_CHILD_COUNT], 0
    mov     qword [rbx + AST_VALUE_PTR], r14  ; placeholder
    mov     dword [rbx + AST_VALUE_LEN], 0
    pop     r13
    pop     r12
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rbx
    inc     dword [r13 + AST_CHILD_COUNT]

    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EQUALS
    jne     .expected_equals
    mov     ARG1, r12
    call    consume_token

    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .expected_expr

    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx + 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.expected_name:
    lea     ARG1, [err_missing_name]
    call    parser_error
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.expected_equals:
    lea     ARG1, [err_expected_token]
    call    parser_error
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.expected_expr:
    lea     ARG1, [err_expected_expr]
    call    parser_error
    xor     rax, rax
.fail:
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_ask(parser) -> AST node (NODE_ASK)
; "ask 'question' and store in name [as number]"
; ============================================================================
parse_ask:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 24
    call    ak_malloc
    test    rax, rax
    jz      .ask_fail
    mov     r13, rax

    mov     dword [r13 + AST_TYPE], NODE_ASK
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Consume "ask" already consumed by dispatch
    ; Parse the prompt string
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_STRING
    jne     .ask_no_prompt
    mov     ARG1, r12
    call    consume_token
    ; Create literal node for prompt
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     rbx, rax
    mov     dword [rbx + AST_TYPE], NODE_LITERAL
    mov     dword [rbx + AST_CHILD_COUNT], 0
    mov     dword [rbx + AST_VALUE_LEN], TOK_STRING
    pop     r13
    pop     r12
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rbx
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect "and"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ask_no_and
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'a'
    jne     .ask_no_and
    mov     ARG1, r12
    call    consume_token

    ; Expect "store"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ask_no_store
    mov     ARG1, r12
    call    consume_token

    ; Expect "in"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ask_no_in
    mov     ARG1, r12
    call    consume_token

    ; Expect identifier (variable name)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .ask_no_var
    ; Add var name node
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     rbx, rax
    mov     dword [rbx + AST_TYPE], NODE_IDENTIFIER
    mov     dword [rbx + AST_CHILD_COUNT], 0
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rbx
    inc     dword [r13 + AST_CHILD_COUNT]
    ; end of parsing — proceed to optional "as number/as text"

    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ask_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'a'
    jne     .ask_done
    cmp     byte [rax+1], 's'
    jne     .ask_done
    mov     ARG1, r12
    call    consume_token
    ; "as" consumed, next token is type
    mov     ARG1, r12
    call    consume_token              ; consume type keyword

.ask_done:
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.ask_no_prompt:
.ask_no_and:
.ask_no_store:
.ask_no_in:
.ask_no_var:
    lea     ARG1, [err_expected_token]
    call    parser_error
    xor     rax, rax
.ask_fail:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_repeat(parser) -> AST node
; "repeat N times ... end" or "repeat while cond ... end"
; ============================================================================
parse_program:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 32

    mov     r12, ARG1

    lea     ARG1, [dbg_enter_prog]
    mov     ARG2, 0
    call    ak_print_str

    ; Check if next token indicates "times" or "while"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_NUMBER
    je      .repeat_times
    cmp     eax, TOK_KEYWORD
    je      .check_while
    jmp     .repeat_while

.check_while:
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    je      .repeat_while
    jmp     .repeat_times

.repeat_times:
    ; "repeat N times ... end"
    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .rep_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_REPEAT_TIMES
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Parse count expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .rep_fail
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect "times"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .rep_no_times
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .rep_no_times
    mov     ARG1, r12
    call    consume_token

    ; Parse body
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .rep_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.rep_no_times:
    lea     ARG1, [err_expected_token]
    call    parser_error
    jmp     .rep_fail
.rep_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.repeat_while:
    ; "repeat while condition ... end"
    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .rep_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_REPEAT_WHILE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .rep_while_no_kw
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .rep_while_no_kw
    mov     ARG1, r12
    call    consume_token                 ; consume "while"

    ; Parse condition expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .rep_fail_while
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Parse body
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .rep_no_end_while
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.rep_while_no_kw:
.rep_no_end_while:
    lea     ARG1, [err_expected_token]
    call    parser_error
.rep_fail_while:
    xor     rax, rax
.rep_fail:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_for(parser) -> AST node (NODE_FOR_EACH)
; "for each item in list ... end" or "for each key and value in map ... end"
; ============================================================================
parse_for:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; "for" was consumed by dispatch
    ; Expect "each"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .for_no_each
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .for_no_each
    mov     ARG1, r12
    call    consume_token

    ; Allocate node
    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .for_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_FOR_EACH
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Parse item variable name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .for_no_var
    ; Create identifier node
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r14 + AST_CHILD_COUNT], 0
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Check for "and" (key and value iteration)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_AND
    jne     .for_check_in

    ; "and" found — consuming "and" and the second variable
    mov     ARG1, r12
    call    consume_token
    ; Parse second variable
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .for_no_var2
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]

.for_check_in:
    ; Expect "in"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .for_no_in
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'i'
    jne     .for_no_in
    mov     ARG1, r12
    call    consume_token

    ; Parse the iterable expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .for_no_expr
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Parse body
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .for_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.for_no_each:
.for_no_var:
.for_no_var2:
.for_no_in:
.for_no_expr:
.for_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.for_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_count_from(parser) -> AST node (NODE_COUNT_FROM)
; "count from start to end ... end" or "count from start down to end ... end"
; ============================================================================
parse_count_from:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .cf_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_COUNT_FROM
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "count" consumed by dispatch, expect "from"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .cf_no_from
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'f'
    jne     .cf_no_from
    mov     ARG1, r12
    call    consume_token

    ; Parse start expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .cf_no_start
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Check for "to" or "down to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .cf_no_direction

    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    je      .cf_to
    cmp     byte [rax], 'd'
    je      .cf_down
    jmp     .cf_no_direction

.cf_to:
    mov     ARG1, r12
    call    consume_token
    ; Parse end expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .cf_no_end
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    jmp     .cf_body

.cf_down:
    mov     ARG1, r12
    call    consume_token
    ; Expect "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .cf_no_to
    mov     ARG1, r12
    call    consume_token
    ; Parse end expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .cf_no_end
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.cf_body:
    mov     r14, r13
    call    parse_block_body

    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .cf_no_end_kw
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.cf_no_from:
.cf_no_start:
.cf_no_direction:
.cf_no_to:
.cf_no_end:
.cf_no_end_kw:
    lea     ARG1, [err_expected_token]
    call    parser_error
.cf_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_define(parser) -> AST node (NODE_DEFINE)
; "define name taking param1 and param2 ... body ... end"
; ============================================================================
parse_define:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .def_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_DEFINE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "define" was consumed by dispatch
    ; Expect function name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .def_no_name

    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r14 + AST_CHILD_COUNT], 0
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect "taking"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .def_no_taking
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .def_no_taking
    mov     ARG1, r12
    call    consume_token

    ; Parse parameters (identifiers separated by "and")
.def_param_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .def_body_start

    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r14 + AST_CHILD_COUNT], 0
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token

    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Check for "and" (more parameters)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_AND
    jne     .def_body_start
    mov     ARG1, r12
    call    consume_token
    jmp     .def_param_loop

.def_body_start:
    ; Parse function body
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .def_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.def_no_name:
.def_no_taking:
.def_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.def_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_make_kind(parser) -> AST node (NODE_MAKE_KIND)
; "make kind called Name [extends Parent] ... [has fields] ... [when created] [behaviour] ... end"
; ============================================================================
parse_make_kind:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 40
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 128
    call    ak_malloc
    test    rax, rax
    jz      .mk_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MAKE_KIND
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "make" consumed, expect "kind"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mk_no_kind
    mov     ARG1, r12
    call    consume_token

    ; Expect "called"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mk_no_called
    mov     ARG1, r12
    call    consume_token

    ; Expect class name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mk_no_name
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Optional: "extends Parent"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mk_parse_body
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .mk_parse_body
    mov     ARG1, r12
    call    consume_token

    ; Parse parent class name
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mk_parse_body
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]

.mk_parse_body:
    ; Parse class body: "has" fields, "when created", "behaviour", until "end"
.mk_body_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EOF
    je      .mk_no_end
    cmp     eax, TOK_KEYWORD
    jne     .mk_skip_stmt

    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'e'
    je      .mk_check_end
    cmp     al, 'h'
    je      .mk_has_field
    cmp     al, 'w'
    je     .mk_when_created
    cmp     al, 'b'
    je     .mk_behaviour

.mk_check_end:
    cmp     byte [rax+1], 'n'
    je     .mk_done
    cmp     byte [rax+1], 'l'  ; could be "else" inside
    jne    .mk_skip_stmt

.mk_skip_stmt:
    mov     ARG1, r12
    call    parse_statement
    test    rax, rax
    jz      .mk_advance
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    jmp     .mk_body_loop

.mk_advance:
    mov     ARG1, r12
    call    consume_token
    jmp     .mk_body_loop

.mk_has_field:
    mov     ARG1, r12
    call    consume_token
    ; Parse field name
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mk_body_loop
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    jmp     .mk_body_loop

.mk_when_created:
    mov     ARG1, r12
    call    consume_token
    ; "when" consumed, expect "created"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mk_body_loop
    mov     ARG1, r12
    call    consume_token
    ; Parse "taking" clause and body
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mk_body_loop
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .mk_body_loop
    mov     ARG1, r12
    call    consume_token
    ; Parse constructor body until end
    mov     r14, r13
    call    parse_block_body
    jmp     .mk_body_loop

.mk_behaviour:
    mov     ARG1, r12
    call    consume_token
    ; Parse behaviour name
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mk_body_loop
    mov     ARG1, r12
    call    consume_token
    ; Optional "taking" clause
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mk_body_loop
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .behaviour_body
    mov     ARG1, r12
    call    consume_token
    ; Parse parameters
.behaviour_param_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .behaviour_body
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_AND
    jne     .behaviour_body
    mov     ARG1, r12
    call    consume_token
    jmp     .behaviour_param_loop

.behaviour_body:
    mov     r14, r13
    call    parse_block_body
    jmp     .mk_body_loop

.mk_done:
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 40
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.mk_no_kind:
.mk_no_called:
.mk_no_name:
.mk_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.mk_fail:
    xor     rax, rax
    add     rsp, 40
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_new(parser) -> AST node (NODE_NEW)
; "new Name called with arg1 and arg2"
; ============================================================================
parse_new:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; "new" consumed by dispatch
    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    test    rax, rax
    jz      .new_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_NEW
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Parse class name
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .new_no_class

    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect "called"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .new_no_called
    mov     ARG1, r12
    call    consume_token

    ; Expect "with"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .new_no_with
    mov     ARG1, r12
    call    consume_token

    ; Parse constructor arguments separated by "and"
.new_arg_loop:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_NEWLINE
    je      .new_done
    cmp     eax, TOK_EOF
    je      .new_done
    cmp     eax, TOK_KEYWORD
    je      .new_check_end

    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .new_done

    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Check for "and"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_AND
    jne     .new_done
    mov     ARG1, r12
    call    consume_token
    jmp     .new_arg_loop

.new_check_end:
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .new_done

.new_done:
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.new_no_class:
.new_no_called:
.new_no_with:
    lea     ARG1, [err_expected_token]
    call    parser_error
.new_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_try(parser) -> AST node (NODE_TRY)
; "try body catch error_type body [catch any error as e body] [finally body] end"
; ============================================================================
parse_try:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    test    rax, rax
    jz      .try_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_TRY
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Parse try body
    mov     r14, r13
    call    parse_block_body

    ; Parse catch clauses
.try_catch_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .try_no_end

    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'c'
    je      .try_parse_catch
    cmp     al, 'f'
    je      .try_parse_finally
    cmp     al, 'e'
    je      .try_check_end
    jmp     .try_no_end

.try_parse_catch:
    mov     ARG1, r12
    call    consume_token
    ; Create catch node
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE + 8 * 4
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_CATCH
    mov     dword [r14 + AST_CHILD_COUNT], 0
    lea     rax, [r14 + AST_NODE_SIZE]
    mov     [r14 + AST_CHILDREN], rax
    pop     r13
    pop     r12

    ; Parse catch type
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .try_catch_no_type
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'a'
    jne     .try_catch_named
    cmp     byte [rax+1], 'n'
    jne     .try_catch_named
    ; "any" — generic catch
    mov     ARG1, r12
    call    consume_token
    ; Optional "error as e"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .try_catch_body
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .try_catch_body
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .try_catch_body
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    consume_token                 ; consume variable name
    jmp     .try_catch_body

.try_catch_named:
    ; Named error type
    mov     ARG1, r12
    call    consume_token

.try_catch_body:
    ; Parse catch body
    push    r12
    push    r13
    push    r14
    mov     r14, r14
    call    parse_block_body
    pop     r14
    pop     r13
    pop     r12

    ; Add catch node to try node
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    jmp     .try_catch_loop

.try_catch_no_type:
    jmp     .try_catch_body

.try_parse_finally:
    mov     ARG1, r12
    call    consume_token
    ; Parse finally body
    mov     r14, r13
    call    parse_block_body
    jmp     .try_catch_loop

.try_check_end:
    cmp     byte [rax+1], 'n'
    je      .try_done
    jmp     .try_catch_loop

.try_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error

.try_done:
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.try_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_match(parser) -> AST node (NODE_MATCH)
; "match expr when it is val ... when it is between a and b ... otherwise ... end"
; ============================================================================
parse_match:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 32
    call    ak_malloc
    test    rax, rax
    jz      .match_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MATCH
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "match" consumed by dispatch — parse the match expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .match_no_expr
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.match_when_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EOF
    je      .match_no_end
    cmp     eax, TOK_KEYWORD
    jne     .match_when_loop

    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'w'
    je      .match_when_clause
    cmp     al, 'o'
    je      .match_otherwise
    cmp     al, 'e'
    je      .match_check_end
    jmp     .match_when_loop

.match_when_clause:
    mov     ARG1, r12
    call    consume_token

    ; Create WHEN node
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_WHEN
    mov     dword [r14 + AST_CHILD_COUNT], 0
    lea     rax, [r14 + AST_NODE_SIZE]
    mov     [r14 + AST_CHILDREN], rax
    pop     r13
    pop     r12

    ; Expect "it"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .match_when_skip
    mov     ARG1, r12
    call    consume_token

    ; Expect "is"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IS
    jne     .match_when_no_is
    mov     ARG1, r12
    call    consume_token

    ; Parse condition expression
    push    r12
    push    r13
    push    r14
    mov     ARG1, r12
    call    parse_expression
    mov     r15, rax
    pop     r14
    pop     r13
    pop     r12
    test    r15, r15
    jz      .match_when_body

    mov     rcx, [r14 + AST_CHILDREN]
    mov     [rcx], r15
    inc     dword [r14 + AST_CHILD_COUNT]

.match_when_body:
    ; Parse when body
    push    r12
    push    r13
    push    r14
    mov     r14, r14
    call    parse_block_body
    pop     r14
    pop     r13
    pop     r12

    ; Add to match node
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    jmp     .match_when_loop

.match_when_no_is:
    pop     r12
.match_when_skip:
    jmp     .match_when_loop

.match_otherwise:
    mov     ARG1, r12
    call    consume_token
    ; Parse otherwise body
    mov     r14, r13
    call    parse_block_body
    jmp     .match_when_loop

.match_check_end:
    cmp     byte [rax+1], 'n'
    je      .match_done
    jmp     .match_when_loop

.match_no_expr:
    lea     ARG1, [err_expected_expr]
    call    parser_error
    jmp     .match_fail

.match_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error

.match_done:
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.match_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_bring_in(parser) -> AST node (NODE_BRING_IN)
; "bring in module_name [as alias]"
; ============================================================================
parse_bring_in:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 16
    call    ak_malloc
    test    rax, rax
    jz      .bi_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_BRING_IN
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "bring" consumed by dispatch, "in" was consumed by lexer as multi-word
    ; Expect module name (identifier or string)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    je      .bi_have_name
    cmp     eax, TOK_STRING
    jne     .bi_no_name

.bi_have_name:
    mov     ARG1, r12
    call    consume_token
    ; Store in node value
    mov     qword [r13 + AST_VALUE_PTR], rax

    ; Optional "as alias"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .bi_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'a'
    jne     .bi_done
    cmp     byte [rax+1], 's'
    jne     .bi_done
    mov     ARG1, r12
    call    consume_token
    ; Expect alias identifier
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .bi_done
    mov     ARG1, r12
    call    consume_token

.bi_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.bi_no_name:
    lea     ARG1, [err_missing_name]
    call    parser_error
.bi_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_do_in_background(parser) -> AST node
; "do in background ... end"
; Wraps the block in an async execution node
; ============================================================================
parse_do_in_background:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .dib_fail
    mov     r13, rax
    ; Reuse NODE_REPEAT_WHILE as the async block marker for now
    ; In production we'd define NODE_DO_BACKGROUND
    mov     dword [r13 + AST_TYPE], 36     ; NODE_DO_BACKGROUND temporary
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "do" consumed by dispatch, expect "in"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .dib_no_in
    mov     ARG1, r12
    call    consume_token
    ; Expect "background"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .dib_no_bg
    mov     ARG1, r12
    call    consume_token

    ; Parse body
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .dib_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.dib_no_in:
.dib_no_bg:
.dib_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.dib_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_wait(parser) -> AST node
; "wait for expr" or "wait for all of task1 and task2"
; ============================================================================
parse_wait:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    test    rax, rax
    jz      .wait_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_BINOP  ; reuse with special type
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    mov     dword [r13 + AST_VALUE_LEN], 100    ; special marker for "wait"

    ; "wait" consumed by dispatch, expect "for"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wait_no_for
    mov     ARG1, r12
    call    consume_token

    ; Check for "all"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wait_expr
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'a'
    jne     .wait_expr
    mov     ARG1, r12
    call    consume_token

    ; Expect "of"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wait_no_of

.wait_all_loop:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_NEWLINE
    je      .wait_done
    cmp     eax, TOK_EOF
    je      .wait_done
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .wait_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Check for "and"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_AND
    jne     .wait_done
    mov     ARG1, r12
    call    consume_token
    jmp     .wait_all_loop

.wait_expr:
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .wait_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.wait_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.wait_no_for:
.wait_no_of:
.wait_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_when_block(parser) -> AST node
; "when someone visits/posts to path ... end" — route handler
; ============================================================================
parse_when_block:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    ; "when" consumed by dispatch
    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .wb_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_ROUTE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    mov     dword [r13 + AST_VALUE_LEN], 0  ; 0=GET, 1=POST

    ; Parse "someone"
    mov     ARG1, r12
    call    consume_token
    ; Parse verb: "visits" or "posts"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wb_no_verb
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'v'
    jne     .wb_check_post
    mov     dword [r13 + AST_VALUE_LEN], 0  ; GET
    jmp     .wb_have_verb
.wb_check_post:
    mov     dword [r13 + AST_VALUE_LEN], 1  ; POST
.wb_have_verb:
    mov     ARG1, r12
    call    consume_token

    ; Check for "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wb_check_end

    ; Parse path (string)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_STRING
    jne     .wb_check_end
    mov     ARG1, r12
    call    consume_token

    ; Parse body until "end"
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wb_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.wb_no_verb:
.wb_check_end:
.wb_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.wb_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_plot(parser) -> AST node (NODE_PLOT)
; "plot expr [from N to N]" or "plot [bar chart | scatter] of data"
; ============================================================================
parse_plot:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    test    rax, rax
    jz      .plot_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_PLOT
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "plot" consumed by dispatch

    ; Check for bar/scatter sub-type
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .plot_parse_expr

    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'b'
    je      .plot_bar
    cmp     byte [rax], 's'
    je      .plot_scatter
    jmp     .plot_parse_expr

.plot_bar:
    mov     ARG1, r12
    call    consume_token
    mov     dword [r13 + AST_VALUE_LEN], 1  ; bar chart
    jmp     .plot_of_data

.plot_scatter:
    mov     ARG1, r12
    call    consume_token
    mov     dword [r13 + AST_VALUE_LEN], 2  ; scatter
    jmp     .plot_of_data

.plot_parse_expr:
    mov     dword [r13 + AST_VALUE_LEN], 0  ; function plot
    ; Parse expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .plot_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Optional "from N to N"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .plot_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'f'
    jne     .plot_done
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .plot_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect "to"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .plot_done
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .plot_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    jmp     .plot_done

.plot_of_data:
    ; Expect "of"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .plot_done
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .plot_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.plot_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.plot_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_train(parser) -> AST node (NODE_TRAIN)
; "train Model using data with labels for N rounds [with batch size N]
;  [using optimizer type] [with learning rate N]"
; ============================================================================
parse_train:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 40
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    test    rax, rax
    jz      .train_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_TRAIN
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "train" consumed by dispatch
    ; Parse model name
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .train_no_model
    mov     ARG1, r12
    call    consume_token

    ; Parse training parameters
.train_param_loop:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_EOF
    je      .train_done
    cmp     eax, TOK_NEWLINE
    je      .train_done

    mov     ARG1, r12
    call    peek_token_text
    mov     r14, rax
    mov     al, [r14]
    cmp     al, 'u'
    je      .train_using
    cmp     al, 'w'
    je      .train_with
    cmp     al, 'f'
    je      .train_for
    jmp     .train_done

.train_using:
    mov     ARG1, r12
    call    consume_token
    ; Parse data source or optimizer
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'd'
    je      .train_data
    cmp     al, 'o'
    je     .train_optimizer
    jmp     .train_param_loop

.train_data:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    jmp     .train_param_loop

.train_optimizer:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    consume_token
    jmp     .train_param_loop

.train_with:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'l'
    je      .train_labels
    cmp     al, 'b'
    je      .train_batch
    jmp     .train_param_loop

.train_labels:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    jmp     .train_param_loop

.train_batch:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    jmp     .train_param_loop

.train_for:
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .train_param_loop
    mov     ARG1, r12
    call    consume_token
    jmp     .train_param_loop

.train_no_model:
    lea     ARG1, [err_expected_token]
    call    parser_error
.train_done:
    mov     rax, r13
    add     rsp, 40
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.train_fail:
    xor     rax, rax
    add     rsp, 40
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_map_literal(parser) -> AST node (NODE_MAP_LITERAL)
; "map key is value key is value ... end"
; ============================================================================
parse_map_literal:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .ml_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MAP_LITERAL
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "map" was consumed by dispatch

.ml_pair_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EOF
    je      .ml_no_end
    cmp     eax, TOK_NEWLINE
    je      .ml_consume_nl

    ; Check for "end"
    cmp     eax, TOK_KEYWORD
    jne     .ml_parse_key
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .ml_parse_key
    cmp     byte [rax+1], 'n'
    je      .ml_done
    jmp     .ml_parse_key

.ml_consume_nl:
    mov     ARG1, r12
    call    consume_token
    jmp     .ml_pair_loop

.ml_parse_key:
    ; Parse key expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .ml_no_key
    mov     r14, rax
    mov     r15, 1                      ; expect "is"

    ; Expect "is"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IS
    jne     .ml_no_is

    mov     ARG1, r12
    call    consume_token

    ; Parse value expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .ml_no_value
    mov     r15, rax

    ; Add key-value pair to node
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r15
    inc     dword [r13 + AST_CHILD_COUNT]

    jmp     .ml_pair_loop

.ml_no_key:
.ml_no_is:
.ml_no_value:
    jmp     .ml_pair_loop

.ml_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error

.ml_done:
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.ml_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_protocol_def(parser) -> AST node (NODE_PROTOCOL)
; "protocol called Name requires behaviour taking params giving back type"
; Parses a protocol (interface) definition with required behaviours
; ============================================================================
parse_protocol_def:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 32
    call    ak_malloc
    test    rax, rax
    jz      .pd_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_PROTOCOL
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "protocol" consumed by dispatch, expect "called"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pd_no_called
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'c'
    jne     .pd_no_called
    mov     ARG1, r12
    call    consume_token

    ; Expect protocol name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .pd_no_name
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r14 + AST_CHILD_COUNT], 0
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect "requires"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pd_body
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'r'
    jne     .pd_body
    mov     ARG1, r12
    call    consume_token

.pd_require_loop:
    ; Parse required behaviour name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .pd_body
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r14 + AST_CHILD_COUNT], 0
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Check for "taking"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pd_check_end
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .pd_check_end
    mov     ARG1, r12
    call    consume_token

.pd_param_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .pd_check_giving
    mov     ARG1, r12
    call    consume_token
    ; Check for "and"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_AND
    je      .pd_consume_and
    jmp     .pd_check_giving
.pd_consume_and:
    mov     ARG1, r12
    call    consume_token
    jmp     .pd_param_loop

.pd_check_giving:
    ; Optional "giving back type"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pd_check_end
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'g'
    jne     .pd_check_end
    mov     ARG1, r12
    call    consume_token
    ; Expect "back"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pd_check_end
    mov     ARG1, r12
    call    consume_token
    ; Parse return type
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    je      .pd_consume_type
    cmp     eax, TOK_KEYWORD
    jne     .pd_check_end
.pd_consume_type:
    mov     ARG1, r12
    call    consume_token

.pd_check_end:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pd_no_end_kw
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .pd_no_end_kw
    jmp     .pd_done

.pd_body:
    ; Parse body until "end"
    mov     r14, r13
    call    parse_block_body

.pd_done:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pd_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.pd_no_called:
.pd_no_name:
.pd_no_end_kw:
.pd_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.pd_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_lambda(parser) -> AST node (NODE_LAMBDA)
; "behaviour taking params body end" as expression
; ============================================================================
parse_lambda:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .lambda_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_LAMBDA
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "behaviour" consumed by dispatch
    ; Optional "taking" clause
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .lambda_body
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .lambda_body
    mov     ARG1, r12
    call    consume_token

.lambda_param_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .lambda_body
    push    r12
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r14 + AST_CHILD_COUNT], 0
    pop     r13
    pop     r12
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Check for "and"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_AND
    jne     .lambda_body
    mov     ARG1, r12
    call    consume_token
    jmp     .lambda_param_loop

.lambda_body:
    ; Parse body until "end"
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .lambda_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.lambda_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.lambda_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_async_stmt(parser) -> AST node (NODE_ASYNC)
; "async do ... end" or "async let ..." — marks an async block
; ============================================================================
parse_async_stmt:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .as_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_ASYNC
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "async" consumed by dispatch
    ; Parse body (one statement or block)
    mov     ARG1, r12
    call    parse_statement
    test    rax, rax
    jz      .as_body
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.as_body:
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.as_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_await_stmt(parser) -> AST node (NODE_AWAIT)
; "await expr" — suspends async execution until expr completes
; ============================================================================
parse_await_stmt:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 16
    call    ak_malloc
    test    rax, rax
    jz      .aw_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_AWAIT
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "await" consumed by dispatch — parse the awaited expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .aw_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.aw_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.aw_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_manual_memory(parser) -> AST node (NODE_MANUAL_MEMORY)
; "in manual memory mode ... end"
; Wraps a block of statements in manual memory management context
; ============================================================================
parse_manual_memory:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .mm_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MANUAL_MEMORY
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; "in" consumed by dispatch — expect "manual"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mm_no_manual
    mov     ARG1, r12
    call    consume_token

    ; Expect "memory"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mm_no_memory
    mov     ARG1, r12
    call    consume_token

    ; Expect "mode"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mm_no_mode
    mov     ARG1, r12
    call    consume_token

    ; Parse body
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mm_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.mm_no_manual:
.mm_no_memory:
.mm_no_mode:
.mm_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.mm_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_test_suite(parser) -> AST node (NODE_TEST_SUITE)
; "test suite 'name' ... test 'name' ... end ... end"
; Called with "test" and "suite" already consumed
; ============================================================================
parse_test_suite:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .ts_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_TEST_SUITE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Expect suite name (string)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_STRING
    jne     .ts_no_name
    mov     ARG1, r12
    call    peek_token_text
    mov     [r13 + AST_VALUE_PTR], rax
    mov     ARG1, r12
    call    consume_token

.ts_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EOF
    je      .ts_no_end
    cmp     eax, TOK_NEWLINE
    je      .ts_consume_nl
    cmp     eax, TOK_KEYWORD
    jne     .ts_skip

    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'e'
    je      .ts_check_end
    cmp     al, 't'
    jne     .ts_skip

    ; Parse a test block
    mov     ARG1, r12
    call    consume_token               ; consume "test"
    mov     ARG1, r12
    call    parse_test
    test    rax, rax
    jz      .ts_skip
    mov     rcx, [r13 + AST_CHILDREN]
    mov     edx, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rdx * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    jmp     .ts_loop

.ts_check_end:
    cmp     byte [rax+1], 'n'
    je      .ts_done
    jmp     .ts_skip

.ts_consume_nl:
    mov     ARG1, r12
    call    consume_token
    jmp     .ts_loop

.ts_skip:
    mov     ARG1, r12
    call    consume_token
    jmp     .ts_loop

.ts_no_name:
    lea     ARG1, [err_expected_token]
    call    parser_error
    xor     rax, rax
    jmp     .ts_exit

.ts_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error
    mov     rax, r13
    jmp     .ts_exit

.ts_done:
    mov     ARG1, r12
    call    consume_token               ; consume "end"
    mov     rax, r13

.ts_exit:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.ts_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_test(parser) -> AST node (NODE_TEST)
; "test 'name' ... statements ... end"
; Called with "test" already consumed
; ============================================================================
parse_test:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .pt_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_TEST
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Expect test name (string)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_STRING
    jne     .pt_no_name
    mov     ARG1, r12
    call    peek_token_text
    mov     [r13 + AST_VALUE_PTR], rax
    mov     ARG1, r12
    call    consume_token

    ; Parse body statements until "end"
    mov     r14, r13
    call    parse_block_body

    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pt_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.pt_no_name:
    lea     ARG1, [err_expected_token]
    call    parser_error
    xor     rax, rax
    jmp     .pt_exit
.pt_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error
    mov     rax, r13
.pt_exit:
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.pt_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_expect(parser) -> AST node (NODE_EXPECT)
; "expect expr to be expr" or "expect error when expr"
; Called with "expect" already consumed
; ============================================================================
parse_expect:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1

    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .pe_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_EXPECT
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax

    ; Check for "error when"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pe_normal
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'
    jne     .pe_normal
    cmp     byte [rax+1], 'r'
    jne     .pe_normal
    ; It's "error" keyword
    mov     ARG1, r12
    call    consume_token
    ; Expect "when"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pe_no_when
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .pe_no_when
    mov     ARG1, r12
    call    consume_token
    ; Parse the error expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .pe_done_error
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.pe_done_error:
    mov     dword [r13 + AST_VALUE_LEN], 1  ; error flag
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.pe_no_when:
    ; "error" but no "when" — treat as normal expression expect
    ; Fall through to .pe_normal with the error token re-consumed
    ; Actually we already consumed error, can't go back
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.pe_normal:
    ; Parse the expression to test
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .pe_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]

    ; Expect "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pe_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .pe_done
    mov     ARG1, r12
    call    consume_token

    ; Expect "be"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pe_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'b'
    jne     .pe_done
    mov     ARG1, r12
    call    consume_token

    ; Parse expected value
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .pe_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]

.pe_done:
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.pe_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_run_tests(parser) -> AST node (NODE_RUN_TESTS)
; "run all tests"
; Called with "run" already consumed
; ============================================================================
parse_run_tests:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1

    ; Expect "all"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pr_fail
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'a'
    jne     .pr_fail
    mov     ARG1, r12
    call    consume_token

    ; Expect "tests"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .pr_fail
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .pr_fail
    mov     ARG1, r12
    call    consume_token

    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    test    rax, rax
    jz      .pr_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_RUN_TESTS
    mov     dword [r13 + AST_CHILD_COUNT], 0
    mov     qword [r13 + AST_CHILDREN], 0
    mov     qword [r13 + AST_VALUE_PTR], 0
    mov     dword [r13 + AST_VALUE_LEN], 0

    mov     rax, r13
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

.pr_fail:
    xor     rax, rax
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_square_root(parser) -> AST node (NODE_SQRT)
; "square root of <expression>"
; Called with "square" already consumed
; ============================================================================
parse_square_root:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1
    ; Expect "root"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .sqrt_fail
    mov     ARG1, r12
    call    consume_token               ; consume "root"
    ; Expect "of"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .sqrt_fail
    mov     ARG1, r12
    call    consume_token               ; consume "of"
    ; Parse the expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .sqrt_fail
    push    rax
    ; Create NODE_SQRT node
    mov     ARG1, AST_NODE_SIZE + 8
    call    ak_malloc
    pop     rcx
    test    rax, rax
    jz      .sqrt_fail
    mov     dword [rax + AST_TYPE], NODE_SQRT
    mov     dword [rax + AST_CHILD_COUNT], 1
    lea     rdx, [rax + AST_NODE_SIZE]
    mov     [rax + AST_CHILDREN], rdx
    mov     [rdx], rcx
    mov     qword [rax + AST_VALUE_PTR], 0
    mov     dword [rax + AST_VALUE_LEN], 0
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret
.sqrt_fail:
    xor     rax, rax
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_make_page(parser) -> AST node (NODE_MAKE_PAGE)
; "make page called Name [with text \"string\"]"
; Called with "make" already consumed
; ============================================================================
parse_make_page:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    ; Consume "page"
    mov     ARG1, r12
    call    consume_token
    ; Expect "called"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mp_fail
    mov     ARG1, r12
    call    consume_token               ; consume "called"
    ; Expect identifier (page name)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mp_fail
    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .mp_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MAKE_PAGE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Store name
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    mov     dword [r14 + AST_CHILD_COUNT], 0
    pop     r13
    mov     ARG1, r12
    call    consume_token               ; consume name identifier
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Check for "with"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .mp_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .mp_done
    cmp     byte [rax+1], 'i'
    jne     .mp_done
    mov     ARG1, r12
    call    consume_token               ; consume "with"
    ; Parse remaining options as expression list
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .mp_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.mp_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.mp_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_make_button(parser) -> AST node (NODE_MAKE_BUTTON)
; "make button called Name with text \"string\""
; Called with "make" consumed
; ============================================================================
parse_make_button:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    mov     ARG1, r12
    call    consume_token               ; consume "button"
    ; Expect "called"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mbtn_fail
    mov     ARG1, r12
    call    consume_token
    ; Expect name
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mbtn_fail
    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .mbtn_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MAKE_BUTTON
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Check for "with"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .mbtn_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .mbtn_done
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .mbtn_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.mbtn_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.mbtn_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_make_input(parser) -> AST node (NODE_MAKE_INPUT)
; "make input called Name with placeholder \"string\""
; Called with "make" consumed
; ============================================================================
parse_make_input:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    mov     ARG1, r12
    call    consume_token               ; consume "input"
    ; Expect "called"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .minp_fail
    mov     ARG1, r12
    call    consume_token
    ; Expect name
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .minp_fail
    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .minp_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MAKE_INPUT
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Check for "with"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .minp_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .minp_done
    mov     ARG1, r12
    call    consume_token
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .minp_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.minp_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.minp_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_when_clicked(parser) -> AST node (NODE_EVENT)
; "when name is clicked ... body ... end"
; Called with "when" consumed
; ============================================================================
parse_when_clicked:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .wc_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_EVENT
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Parse element name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .wc_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Expect "is"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IS
    jne     .wc_no_is
    mov     ARG1, r12
    call    consume_token
    ; Expect "clicked"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wc_no_clicked
    mov     ARG1, r12
    call    consume_token
    ; Parse body until "end"
    mov     r14, r13
    call    parse_block_body
    ; Expect "end"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .wc_no_end
    mov     ARG1, r12
    call    consume_token
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.wc_no_is:
.wc_no_clicked:
.wc_no_end:
    lea     ARG1, [err_expected_token]
    call    parser_error
.wc_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_goto(parser) -> AST node (NODE_GOTO)
; "go to page \"path\""
; Called with "go" consumed
; ============================================================================
parse_goto:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1
    ; Expect "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .goto_fail
    mov     ARG1, r12
    call    consume_token               ; consume "to"
    ; Expect "page"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .goto_fail
    mov     ARG1, r12
    call    consume_token               ; consume "page"
    ; Parse target (string expression)
    mov     ARG1, AST_NODE_SIZE + 8
    call    ak_malloc
    test    rax, rax
    jz      .goto_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_GOTO
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .goto_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.goto_done:
    mov     rax, r13
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret
.goto_fail:
    xor     rax, rax
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_send(parser) -> AST node (NODE_SEND)
; "send to server \"path\" the data field is value and field2 is value2"
; Called with "send" consumed
; ============================================================================
parse_send:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1
    ; Expect "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .send_fail
    mov     ARG1, r12
    call    consume_token
    ; Expect "server"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .send_fail
    mov     ARG1, r12
    call    consume_token
    ; Allocate node
    mov     ARG1, AST_NODE_SIZE + 8 * 32
    call    ak_malloc
    test    rax, rax
    jz      .send_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_SEND
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Parse URL/path (string expression)
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .send_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Check for "the"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .send_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .send_done
    mov     ARG1, r12
    call    consume_token               ; consume "the"
    ; Parse data fields: field1 is value1 and field2 is value2 ...
    ; Each field becomes a pair of children (identifier, value)
.send_data_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .send_done
    ; Field name
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Expect "is"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IS
    jne     .send_done
    mov     ARG1, r12
    call    consume_token
    ; Parse value
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .send_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Check for "and"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_AND
    jne     .send_done
    mov     ARG1, r12
    call    consume_token
    jmp     .send_data_loop
.send_done:
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.send_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_connect_db(parser) -> AST node (NODE_CONNECT_DB)
; "connect to database \"path\""
; Called with "connect" consumed
; ============================================================================
parse_connect_db:
    push    rbx
    push    r12
    push    r13
    sub     rsp, 16
    mov     r12, ARG1
    ; Expect "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .cdb_fail
    mov     ARG1, r12
    call    consume_token
    ; Expect "database"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .cdb_fail
    mov     ARG1, r12
    call    consume_token
    ; Allocate node
    mov     ARG1, AST_NODE_SIZE + 8
    call    ak_malloc
    test    rax, rax
    jz      .cdb_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_CONNECT_DB
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Parse path expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .cdb_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.cdb_done:
    mov     rax, r13
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret
.cdb_fail:
    xor     rax, rax
    add     rsp, 16
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_create_table(parser) -> AST node (NODE_CREATE_TABLE)
; "create table Name in database"
; Called with "create" consumed
; ============================================================================
parse_create_table:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    ; Expect "table"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ct_fail
    mov     ARG1, r12
    call    consume_token
    ; Allocate node
    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .ct_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_CREATE_TABLE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Parse table name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .ct_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Expect "in"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ct_done
    mov     ARG1, r12
    call    consume_token               ; consume "in"
    ; Expect "database"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ct_done
    mov     ARG1, r12
    call    consume_token               ; consume "database"
.ct_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.ct_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_make_table(parser) -> AST node (NODE_MAKE_TABLE)
; "make table called Name column colName type [unique] [required] [default Value] ... end"
; Called with "make" consumed
; ============================================================================
parse_make_table:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1
    ; Consume "table"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .mt_fail
    mov     ARG1, r12
    call    consume_token
    ; Expect "called" — actually make table might not need called; handle flexibly
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .mt_fail
    mov     ARG1, r12
    call    consume_token               ; consume "called"
    ; Allocate node
    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .mt_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_MAKE_TABLE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Expect table name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mt_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Parse columns until "end"
.mt_col_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EOF
    je      .mt_no_end
    cmp     eax, TOK_NEWLINE
    je      .mt_consume_nl
    cmp     eax, TOK_KEYWORD
    jne     .mt_skip
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'e'                     ; "end"
    je      .mt_check_end
    cmp     al, 'c'                     ; "column"
    je      .mt_parse_column
    jmp     .mt_skip
.mt_consume_nl:
    mov     ARG1, r12
    call    consume_token
    jmp     .mt_col_loop
.mt_skip:
    mov     ARG1, r12
    call    consume_token
    jmp     .mt_col_loop
.mt_check_end:
    cmp     byte [rax+1], 'n'
    jne     .mt_skip
    mov     ARG1, r12
    call    consume_token               ; consume "end"
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.mt_parse_column:
    mov     ARG1, r12
    call    consume_token               ; consume "column"
    ; Parse column name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .mt_col_loop
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Parse type (keyword or identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    je      .mt_column_type
    cmp     eax, TOK_KEYWORD
    jne     .mt_col_loop
.mt_column_type:
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Skip optional constraints (unique, required, default)
.mt_skip_constraints:
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .mt_col_loop
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'e'                     ; "end" or "else"
    je      .mt_check_end_early
    cmp     al, 'c'                     ; "column"
    je      .mt_col_loop
    mov     ARG1, r12
    call    consume_token               ; consume constraint keyword
    ; If "default", also consume the default value
    cmp     al, 'd'
    jne     .mt_skip_constraints
    mov     ARG1, r12
    call    parse_expression
    jmp     .mt_skip_constraints
.mt_check_end_early:
    cmp     byte [rax+1], 'n'
    jne     .mt_skip_constraints
    mov     ARG1, r12
    call    consume_token               ; consume "end"
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.mt_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error
.mt_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_insert(parser) -> AST node (NODE_INSERT)
; "add to TableName the values field is value ... end"
; Called with "add" consumed
; ============================================================================
parse_insert:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24
    mov     r12, ARG1
    ; Expect "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ins_fail
    mov     ARG1, r12
    call    consume_token
    ; Allocate node
    mov     ARG1, AST_NODE_SIZE + 8 * 64
    call    ak_malloc
    test    rax, rax
    jz      .ins_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_INSERT
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Parse table name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .ins_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Expect "the"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .ins_data_loop
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 't'
    jne     .ins_data_loop
    mov     ARG1, r12
    call    consume_token               ; consume "the"
    ; Expect "values"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .ins_data_loop
    mov     ARG1, r12
    call    consume_token               ; consume "values"
    ; Parse field = value pairs
.ins_data_loop:
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_EOF
    je      .ins_no_end
    cmp     eax, TOK_NEWLINE
    je      .ins_consume_nl
    cmp     eax, TOK_KEYWORD
    jne     .ins_parse_field
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'e'             ; "end"
    je      .ins_check_end
.ins_parse_field:
    ; Parse field name (identifier)
    cmp     eax, TOK_IDENTIFIER
    jne     .ins_done
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Expect "is"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IS
    jne     .ins_done
    mov     ARG1, r12
    call    consume_token
    ; Parse value
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .ins_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Check for "and"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_AND
    je      .ins_consume_and
    jmp     .ins_data_loop
.ins_consume_and:
    mov     ARG1, r12
    call    consume_token
    jmp     .ins_data_loop
.ins_consume_nl:
    mov     ARG1, r12
    call    consume_token
    jmp     .ins_data_loop
.ins_check_end:
    cmp     byte [rax+1], 'n'
    jne     .ins_parse_field
    mov     ARG1, r12
    call    consume_token               ; consume "end"
.ins_done:
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.ins_no_end:
    lea     ARG1, [err_missing_end]
    call    parser_error
    mov     rax, r13
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.ins_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_find(parser) -> AST node (NODE_FIND)
; "find all from TableName where condition"
; "find first from TableName where condition"
; Called with "find" consumed
; ============================================================================
parse_find:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .find_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_FIND
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Check for "all" or "first"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .find_fail
    mov     ARG1, r12
    call    peek_token_text
    mov     al, [rax]
    cmp     al, 'a'                     ; "all"
    je      .find_have_type
    cmp     al, 'f'                     ; "first"
    je      .find_have_type
    jmp     .find_fail
.find_have_type:
    mov     ARG1, r12
    call    consume_token               ; consume "all"/"first"
    ; Store as value (0=all, 1=first)
    cmp     al, 'f'
    setne   al
    mov     byte [r13 + AST_VALUE_LEN], al
    ; Expect "from"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .find_fail
    mov     ARG1, r12
    call    consume_token               ; consume "from"
    ; Parse table name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .find_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Optional "where condition"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .find_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .find_done
    mov     ARG1, r12
    call    consume_token               ; consume "where"
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .find_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.find_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.find_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_update(parser) -> AST node (NODE_UPDATE)
; "update TableName set field to value where condition"
; Called with "update" consumed
; ============================================================================
parse_update:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    mov     ARG1, AST_NODE_SIZE + 8 * 16
    call    ak_malloc
    test    rax, rax
    jz      .upd_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_UPDATE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Parse table name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .upd_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Expect "set"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .upd_fail
    mov     ARG1, r12
    call    consume_token               ; consume "set"
    ; Parse field name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .upd_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Expect "to"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .upd_fail
    mov     ARG1, r12
    call    consume_token
    ; Parse value expression
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .upd_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Optional "where condition"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .upd_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .upd_done
    mov     ARG1, r12
    call    consume_token               ; consume "where"
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .upd_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.upd_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.upd_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; parse_delete(parser) -> AST node (NODE_DELETE)
; "remove from TableName where condition"
; Called with "remove" consumed
; ============================================================================
parse_delete:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 24
    mov     r12, ARG1
    mov     ARG1, AST_NODE_SIZE + 8 * 8
    call    ak_malloc
    test    rax, rax
    jz      .del_fail
    mov     r13, rax
    mov     dword [r13 + AST_TYPE], NODE_DELETE
    mov     dword [r13 + AST_CHILD_COUNT], 0
    lea     rax, [r13 + AST_NODE_SIZE]
    mov     [r13 + AST_CHILDREN], rax
    ; Expect "from"
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_KEYWORD
    jne     .del_fail
    mov     ARG1, r12
    call    consume_token
    ; Parse table name (identifier)
    mov     ARG1, r12
    call    expect_token
    cmp     eax, TOK_IDENTIFIER
    jne     .del_fail
    push    r13
    mov     ARG1, AST_NODE_SIZE
    call    ak_malloc
    mov     r14, rax
    mov     dword [r14 + AST_TYPE], NODE_IDENTIFIER
    pop     r13
    mov     ARG1, r12
    call    consume_token
    mov     rcx, [r13 + AST_CHILDREN]
    mov     [rcx], r14
    inc     dword [r13 + AST_CHILD_COUNT]
    ; Optional "where condition"
    mov     ARG1, r12
    call    peek_token_type
    cmp     eax, TOK_KEYWORD
    jne     .del_done
    mov     ARG1, r12
    call    peek_token_text
    cmp     byte [rax], 'w'
    jne     .del_done
    mov     ARG1, r12
    call    consume_token               ; consume "where"
    mov     ARG1, r12
    call    parse_expression
    test    rax, rax
    jz      .del_done
    mov     rcx, [r13 + AST_CHILDREN]
    mov     eax, [r13 + AST_CHILD_COUNT]
    mov     [rcx + rax * 8], rax
    inc     dword [r13 + AST_CHILD_COUNT]
.del_done:
    mov     rax, r13
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
.del_fail:
    xor     rax, rax
    add     rsp, 24
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; External references
; ============================================================================
extern ak_malloc
extern ak_free
extern ak_memcpy
extern ak_print_str
extern ak_print_num
extern ak_print_newline
extern ak_error
extern ak_strcmp
extern ak_strlen
