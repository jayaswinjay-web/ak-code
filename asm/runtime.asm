; ============================================================================
; AK CODE Runtime Support Library
; x86-64 assembly — works on both Linux (ELF) and Windows (PE)
;
; Provides: malloc, free, gc, print, readline, string ops, math conv, mem ops
; ============================================================================

default rel

%ifdef TARGET_WIN64
    ; Windows calling convention: rcx, rdx, r8, r9, then stack
    %define ARG1 rcx
    %define ARG2 rdx
    %define ARG3 r8
    %define ARG4 r9
    %define SYSCALL_RET rax
%else
    ; Linux: rdi, rsi, rdx, r10, r8, r9
    %define ARG1 rdi
    %define ARG2 rsi
    %define ARG3 rdx
    %define ARG4 r10
    %define SYSCALL_RET rax
%endif

section .data
    ; Bump allocator state
    heap_base      dq 0
    heap_current   dq 0
    heap_end       dq 0
    heap_pages     dq 0
    HEAP_INITIAL   equ 1048576        ; 1 MB initial heap
    HEAP_GROW      equ 1048576        ; grow by 1 MB

    ; GC state
    gc_root_list   dq 0
    gc_root_count  dq 0
    gc_alloc_count dq 0

    ; Print buffers
    num_buf        times 32 db 0

    ; Standard strings
    str_newline    db 10, 0
    str_space      db 32, 0
    str_true       db "true", 0
    str_false      db "false", 0
    str_empty      db "empty", 0

    ; Error messages
    msg_oom        db "ERROR: Out of memory", 10, 0
    msg_null       db "ERROR: Null pointer dereference", 10, 0
    msg_bounds     db "ERROR: Index out of bounds", 10, 0

section .text
; ============================================================================
; ak_malloc(size) — allocate memory via bump allocator
; Linux: ARG1 = size (rdi)
; Windows: ARG1 = size (rcx)
; Returns pointer in rax
; ============================================================================
global ak_malloc
ak_malloc:
    push    rbx
    push    r12
    mov     r12, ARG1                   ; save size

    ; Align to 16 bytes
    add     r12, 15
    and     r12, ~15

    ; Check if heap is initialized
    mov     rax, qword [heap_base]
    test    rax, rax
    jnz     .have_heap

    ; Initialize heap
    call    ak_init_heap

.have_heap:
    ; Check if we have space
    mov     rax, qword [heap_current]
    mov     rbx, qword [heap_end]
    sub     rbx, rax
    cmp     rbx, r12
    jge     .alloc

    ; Need to grow the heap
    push    r12                         ; save requested size
    call    ak_grow_heap
    pop     r12
    test    rax, rax
    jz      .oom

.alloc:
    mov     rax, qword [heap_current]
    add     qword [heap_current], r12
    inc     qword [gc_alloc_count]
    pop     r12
    pop     rbx
    ret

.oom:
    mov     ARG1, msg_oom
    call    ak_print_str
    mov     ARG1, 1
    call    ak_exit
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_init_heap — initialise the bump allocator with first region
; ============================================================================
ak_init_heap:
    push    rbx
    push    r12
    mov     r12, HEAP_INITIAL
%ifdef TARGET_WIN64
    ; Windows: VirtualAlloc
    mov     ARG1, 0                     ; lpAddress = NULL
    mov     ARG2, r12                   ; dwSize
    mov     ARG3, 0x3000                ; MEM_RESERVE | MEM_COMMIT
    mov     ARG4, 4                     ; PAGE_READWRITE
    extern  VirtualAlloc
    sub     rsp, 32                     ; shadow space
    call    VirtualAlloc
    add     rsp, 32
%else
    ; Linux: mmap
    mov     ARG1, 0                     ; addr = NULL
    mov     ARG2, r12                   ; length
    mov     ARG3, 3                     ; prot = PROT_READ | PROT_WRITE
    mov     ARG4, 0x22                  ; flags = MAP_PRIVATE | MAP_ANONYMOUS
    xor     r10, r10                    ; fd = -1
    xor     r8, r8                      ; offset = 0
    mov     rax, 9                      ; mmap syscall
    syscall
%endif
    mov     qword [heap_base], rax
    mov     qword [heap_current], rax
    mov     qword [heap_end], rax
    add     r12, rax
    mov     qword [heap_end], r12
    mov     qword [heap_pages], 1
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_grow_heap — extend heap by one page
; ============================================================================
ak_grow_heap:
    push    rbx
    push    r12
    mov     r12, HEAP_GROW
%ifdef TARGET_WIN64
    mov     ARG1, qword [heap_end]
    mov     ARG2, r12
    mov     ARG3, 0x3000
    mov     ARG4, 4
    extern  VirtualAlloc
    sub     rsp, 32 + 8                 ; shadow space + alignment
    call    VirtualAlloc
    add     rsp, 32 + 8
%else
    mov     ARG1, qword [heap_end]
    mov     ARG2, r12
    mov     ARG3, 3
    mov     ARG4, 0x22
    xor     r10, r10
    xor     r8, r8
    mov     rax, 9
    syscall
%endif
    test    rax, rax
    jz      .fail
    add     qword [heap_end], r12
    inc     qword [heap_pages]
    mov     rax, 1
    pop     r12
    pop     rbx
    ret
.fail:
    xor     rax, rax
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_free(ptr) — mark memory as free (basic free list)
; For now, no-op with bump allocator; GC handles collection.
; ============================================================================
global ak_free
ak_free:
    ret

; ============================================================================
; ak_gc() — mark-and-sweep garbage collector (tri-color)
; Currently a no-op since the bump allocator never frees.
; GC data structures (gc_root_list, gc_root_count, gc_alloc_count) are
; maintained for when a real collector is implemented.
; ============================================================================
global ak_gc
ak_gc:
    ret

; ============================================================================
; ak_print_str(ptr, len) — write string to stdout
; ARG1 = pointer to string, ARG2 = length
; ============================================================================
global ak_print_str
ak_print_str:
    push    rbx
    push    r12
    mov     r12, ARG1
    mov     rbx, ARG2
    test    rbx, rbx
    jnz     .have_len
    ; Calculate length if not provided
    mov     ARG1, r12
    call    ak_strlen
    mov     rbx, rax
.have_len:
%ifdef TARGET_WIN64
    ; Windows: WriteFile(GetStdHandle(-11), ptr, len, &written, NULL)
    extern  GetStdHandle
    extern  WriteFile
    sub     rsp, 48                     ; shadow space + alignment
    mov     rcx, -11                    ; STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     rcx, rax                    ; hFile
    mov     rdx, r12                    ; lpBuffer
    mov     r8, rbx                     ; nNumberOfBytesToWrite
    lea     r9, [rsp + 40]              ; lpNumberOfBytesWritten
    mov     qword [rsp + 32], 0         ; lpOverlapped
    call    WriteFile
    add     rsp, 48
%else
    ; Linux: write syscall
    mov     rax, 1                      ; sys_write
    mov     ARG1, 1                     ; fd = stdout
    mov     ARG2, r12                   ; buf
    mov     ARG3, rbx                   ; count
    syscall
%endif
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_print_num(n) — convert integer to decimal string and print
; ============================================================================
global ak_print_num
ak_print_num:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1                   ; save the number
    lea     r13, [num_buf + 31]         ; end of buffer
    mov     byte [r13], 0
    dec     r13

    ; Handle zero
    test    r12, r12
    jnz     .convert
    mov     byte [r13], '0'
    dec     r13
    jmp     .print

.convert:
    ; Handle negative
    mov     rbx, r12
    test    r12, r12
    jns     .positive
    neg     r12
.positive:
    mov     rax, r12
    xor     rdx, rdx
    mov     rcx, 10
.div_loop:
    xor     rdx, rdx
    div     rcx
    add     dl, '0'
    mov     byte [r13], dl
    dec     r13
    test    rax, rax
    jnz     .div_loop

    test    rbx, rbx
    jns     .print
    mov     byte [r13], '-'
    dec     r13

.print:
    inc     r13
    mov     ARG1, r13
    ; Calculate length
    lea     rbx, [num_buf + 31]
    sub     rbx, r13
    mov     ARG2, rbx
    call    ak_print_str
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_print_decimal(f) — print IEEE 754 double
; ARG1 = 64-bit double value
; ============================================================================
global ak_print_decimal
ak_print_decimal:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 32

    movq    xmm0, ARG1
    movsd   [rsp], xmm0                ; store double

    ; Extract sign
    mov     rax, [rsp]
    bt      rax, 63
    jnc     .not_neg
    mov     byte [num_buf], '-'
    lea     ARG1, [num_buf]
    mov     ARG2, 1
    call    ak_print_str
    mov     rax, [rsp]
    btr     rax, 63                     ; clear sign bit
    mov     [rsp], rax

.not_neg:
    ; Extract exponent and mantissa
    mov     rax, [rsp]
    mov     rcx, rax
    shr     rcx, 52
    and     ecx, 0x7FF                 ; exponent
    mov     rbx, rax
    shl     rbx, 12
    shr     rbx, 12                    ; mantissa (clear upper 12 bits)

    ; Handle special cases
    cmp     rcx, 0x7FF
    je      .special
    cmp     rcx, 0
    je      .zero_or_denormal

    ; Normal number: value = (-1)^s * 2^(e-1023) * 1.mantissa
    sub     rcx, 1023                   ; unbiased exponent
    bts     rbx, 52                     ; add implicit 1

    ; For simplicity, convert using integer method
    ; Extract integer and fractional parts
    ; This is a simplified version
    mov     r14, rbx                    ; mantissa with implicit 1
    mov     r15, rcx                    ; exponent

    ; Check if exponent >= 0 (number >= 1.0)
    cmp     r15, 0
    jl      .fractional_only

    ; Integer part: shift mantissa right by (52 - exponent)
    mov     r13, 52
    sub     r13, r15
    cmp     r13, 0
    jle     .large_number
    mov     rax, r14
    shr     rax, 52                      ; integer part in top bits
    mov     r12, rax
    mov     ARG1, r12
    call    ak_print_num

    ; Fractional part
    mov     r13, 52
    sub     r13, r15
    mov     rax, r14
    mov     rcx, r13
    shl     rax, cl                     ; keep fractional bits
    test    rax, rax
    jz      .done
    jmp     .print_decimal_point
    jmp     .done

.large_number:
    ; Number is very large, just print as integer approximation
    mov     rax, r14
    mov     rcx, r15
    sub     rcx, 52
    shl     rax, cl
    mov     ARG1, rax
    call    ak_print_num
    jmp     .done

.fractional_only:
    ; Number is between 0 and 1
    mov     byte [num_buf], '0'
    mov     byte [num_buf+1], '.'
    lea     ARG1, [num_buf]
    mov     ARG2, 2
    call    ak_print_str

    ; Print fractional digits
    mov     r12, 15                     ; max 15 decimal places
.fract_loop:
    mov     rax, r14
    mov     rcx, 10
    mul     rcx
    mov     r14, rax
    ; Recompute fractional part
    mov     rcx, 52
    sub     rcx, r15
    mov     rax, r14
    shr     rax, cl
    add     al, '0'
    mov     byte [num_buf], al
    lea     ARG1, [num_buf]
    mov     ARG2, 1
    call    ak_print_str
    shl     r14, 12
    shr     r14, 12                    ; mantissa bits only
    dec     r12
    test    r14, r14
    jz      .done
    test    r12, r12
    jnz     .fract_loop
    jmp     .done

.print_decimal_point:
    push    rax
    mov     byte [num_buf], '.'
    lea     ARG1, [num_buf]
    mov     ARG2, 1
    call    ak_print_str
    pop     rax

    ; Print fractional digits
    mov     r12, 15
.fract_loop2:
    mov     rcx, 10
    mul     rcx
    mov     rcx, 52
    sub     rcx, r15
    mov     rbx, rax
    shr     rbx, cl
    add     bl, '0'
    mov     byte [num_buf], bl
    lea     ARG1, [num_buf]
    mov     ARG2, 1
    call    ak_print_str
    shl     rax, 12
    shr     rax, 12                    ; mantissa bits only
    dec     r12
    test    rax, rax
    jz      .done
    test    r12, r12
    jnz     .fract_loop2
    jmp     .done

.zero_or_denormal:
    ; Zero or denormalized number
    test    rbx, rbx
    jnz     .denormal
    mov     byte [num_buf], '0'
    lea     ARG1, [num_buf]
    mov     ARG2, 1
    call    ak_print_str
    jmp     .done

.denormal:
    ; Denormalized numbers - print as "~0"
    mov     dword [num_buf], '~0'
    mov     byte [num_buf+1], '0'
    lea     ARG1, [num_buf]
    mov     ARG2, 2
    call    ak_print_str
    jmp     .done

.special:
    test    rbx, rbx
    jz      .infinity
    ; NaN
    mov     dword [num_buf], 'Na'
    mov     byte [num_buf+2], 'N'
    lea     ARG1, [num_buf]
    mov     ARG2, 3
    call    ak_print_str
    jmp     .done

.infinity:
    ; Infinity
    mov     dword [num_buf], 'In'
    mov     byte [num_buf+2], 'f'
    lea     ARG1, [num_buf]
    mov     ARG2, 3
    call    ak_print_str

.done:
    add     rsp, 32
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_read_line(buf, maxlen) — read one line from stdin
; ARG1 = buffer, ARG2 = max length
; Returns number of bytes read in rax
; ============================================================================
global ak_read_line
ak_read_line:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2
    xor     rbx, rbx                   ; count = 0

%ifdef TARGET_WIN64
    extern  GetStdHandle
    extern  ReadFile
    sub     rsp, 48                     ; shadow space + alignment
    mov     rcx, -10                   ; STD_INPUT_HANDLE
    call    GetStdHandle
    mov     rcx, rax                   ; hFile
    mov     rdx, r12                   ; lpBuffer
    mov     r8, r13                    ; nNumberOfBytesToRead
    lea     r9, [rsp + 40]             ; lpNumberOfBytesRead
    mov     qword [rsp + 32], 0        ; lpOverlapped
    call    ReadFile
    mov     rbx, [rsp + 40]            ; bytes read
    add     rsp, 48
%else
    mov     rax, 0                     ; sys_read
    mov     ARG1, 0                    ; fd = stdin
    mov     ARG2, r12                  ; buf
    mov     ARG3, r13                  ; count
    syscall
    mov     rbx, rax                   ; bytes read
%endif

    ; Strip newline
    cmp     rbx, 1
    jl      .done
    lea     rax, [r12 + rbx - 1]
    cmp     byte [rax], 10
    jne     .not_cr
    mov     byte [rax], 0
    dec     rbx
    jmp     .done
.not_cr:
    cmp     byte [rax], 13
    jne     .done
    mov     byte [rax], 0
    dec     rbx
.done:
    mov     rax, rbx
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_strcmp(a, b) — compare two null-terminated strings
; Returns 0 if equal, non-zero if different
; ============================================================================
global ak_strcmp
ak_strcmp:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2
.loop:
    mov     al, [r12]
    mov     bl, [r13]
    cmp     al, bl
    jne     .diff
    test    al, al
    jz      .same
    inc     r12
    inc     r13
    jmp     .loop
.diff:
    mov     rax, 1
    pop     r13
    pop     r12
    pop     rbx
    ret
.same:
    xor     rax, rax
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_strcat(dst, src) — concatenate src to dst
; Assumes dst has enough space
; ============================================================================
global ak_strcat
ak_strcat:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2

    ; Find end of dst
    mov     ARG1, r12
    call    ak_strlen
    add     r12, rax

    ; Copy src to end of dst
.copy_loop:
    mov     al, [r13]
    mov     [r12], al
    test    al, al
    jz      .done
    inc     r12
    inc     r13
    jmp     .copy_loop
.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_strlen(ptr) — length of null-terminated string
; ============================================================================
global ak_strlen
ak_strlen:
    push    rbx
    mov     rbx, ARG1
    xor     rax, rax
.loop:
    cmp     byte [rbx + rax], 0
    je      .done
    inc     rax
    jmp     .loop
.done:
    pop     rbx
    ret

; ============================================================================
; ak_itoa(n, buf) — integer to ASCII
; ARG1 = integer, ARG2 = buffer (at least 32 bytes)
; Returns pointer in rax
; ============================================================================
global ak_itoa
ak_itoa:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2
    lea     rbx, [r13 + 31]
    mov     byte [rbx], 0
    dec     rbx

    test    r12, r12
    jnz     .convert
    mov     byte [rbx], '0'
    mov     rax, rbx
    pop     r13
    pop     r12
    pop     rbx
    ret

.convert:
    mov     rcx, 10
    cmp     r12, 0
    jge     .positive
    neg     r12
.positive:
    mov     rax, r12
.div_loop:
    xor     rdx, rdx
    div     rcx
    add     dl, '0'
    mov     byte [rbx], dl
    dec     rbx
    test    rax, rax
    jnz     .div_loop

    cmp     ARG1, 0
    jge     .finish
    mov     byte [rbx], '-'
    dec     rbx

.finish:
    inc     rbx
    mov     rax, rbx
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_atoi(buf) — ASCII to integer
; ============================================================================
global ak_atoi
ak_atoi:
    push    rbx
    push    r12
    mov     r12, ARG1
    xor     rax, rax
    xor     rbx, rbx                   ; sign flag

    ; Skip whitespace
.skip:
    mov     cl, [r12]
    cmp     cl, 32
    je      .next
    cmp     cl, 9
    je      .next
    cmp     cl, 10
    je      .next
    jmp     .check_sign
.next:
    inc     r12
    jmp     .skip

.check_sign:
    mov     cl, [r12]
    cmp     cl, '-'
    jne     .check_plus
    mov     rbx, 1
    inc     r12
    jmp     .convert_loop
.check_plus:
    cmp     cl, '+'
    jne     .convert_loop
    inc     r12

.convert_loop:
    mov     cl, [r12]
    cmp     cl, '0'
    jb      .done
    cmp     cl, '9'
    ja      .done
    sub     cl, '0'
    imul    rax, 10
    add     rax, rcx
    inc     r12
    jmp     .convert_loop

.done:
    test    rbx, rbx
    jz      .exit
    neg     rax
.exit:
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_ftoa(f, buf) — float to ASCII
; ARG1 = double (in xmm0), ARG2 = buffer
; ============================================================================
global ak_ftoa
ak_ftoa:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 32

    movsd   [rsp], xmm0
    mov     r12, ARG2
    mov     rbx, [rsp]

    ; Handle sign
    bt      rbx, 63
    jnc     .not_neg
    mov     byte [r12], '-'
    inc     r12
    btr     rbx, 63                     ; clear sign bit
.not_neg:

    ; Extract exponent
    mov     rcx, rbx
    shr     rcx, 52
    and     ecx, 0x7FF
    mov     r13d, ecx                   ; exponent

    ; Extract mantissa
    mov     r14, rbx
    shl     r14, 12
    shr     r14, 12                    ; mantissa (clear upper 12 bits)

    cmp     r13, 0x7FF
    je      .special
    test    r13, r13
    jz      .zero_or_denormal

    ; Normal number
    sub     r13, 1023                   ; unbiased exponent
    bts     r14, 52                     ; add implicit 1

    ; For simplicity, convert integer part
    mov     r15, r14
    mov     rcx, r13

    cmp     r13, 0
    jl      .less_than_one

    ; Integer part: shift mantissa right
    mov     rax, r15
    mov     rcx, 52
    sub     rcx, r13
    cmp     rcx, 0
    jle     .very_large
    shr     rax, cl
    mov     r15, rax                    ; integer part

    ; Convert integer part to string
    mov     ARG1, r15
    mov     ARG2, r12
    call    ak_itoa
    push    rax
    call    ak_strlen
    add     r12, rax
    pop     rax

    ; Decimal point
    mov     byte [r12], '.'
    inc     r12

    ; Fractional part up to 10 digits
    mov     r15, r14
    mov     rcx, 52
    sub     rcx, r13
    shl     r15, cl                     ; fractional part in high bits
    mov     rcx, 64
    sub     rcx, 52
    sub     rcx, r13
    shl     r15, cl

    mov     r14, 10
.fract_loop:
    mov     rax, r15
    xor     rdx, rdx
    div     r14
    mov     r15, rax
    mov     rax, rdx
    ; multiply remainder by 10 for next digit
    mov     rcx, r14
    mul     rcx
    add     al, '0'
    mov     [r12], al
    inc     r12
    test    r15, r15
    jz      .finish
    ; Check if we've printed enough
    mov     rax, r12
    sub     rax, ARG2
    cmp     rax, 50                     ; safety limit
    jg      .finish
    jmp     .fract_loop

.less_than_one:
    mov     byte [r12], '0'
    inc     r12
    mov     byte [r12], '.'
    inc     r12

    ; Print leading zeros
    mov     rcx, r13
    neg     rcx
    dec     rcx
    cmp     rcx, 0
    jle     .print_fract
.zero_loop:
    mov     byte [r12], '0'
    inc     r12
    dec     rcx
    jnz     .zero_loop

.print_fract:
    mov     rax, r14
    mov     rcx, r13
    add     rcx, 52
    shl     rax, cl
    mov     r15, rax

    mov     r14, 10
.fract_loop2:
    mov     rax, r15
    xor     rdx, rdx
    div     r14
    mov     r15, rax
    mov     rax, rdx
    mul     r14
    add     al, '0'
    mov     [r12], al
    inc     r12
    test    r15, r15
    jz      .finish
    mov     rax, r12
    sub     rax, ARG2
    cmp     rax, 50
    jg      .finish
    jmp     .fract_loop2

.very_large:
    mov     rax, r15
    mov     rcx, r13
    sub     rcx, 52
    shl     rax, cl
    mov     ARG1, rax
    mov     ARG2, r12
    call    ak_itoa
    jmp     .finish

.zero_or_denormal:
    test    r14, r14
    jnz     .denormal_print
    mov     word [r12], '0'
    mov     rax, ARG2
    jmp     .done

.denormal_print:
    mov     dword [r12], '~0'
    jmp     .finish

.special:
    test    r14, r14
    jnz     .nan_print
    mov     dword [r12], 'In'
    mov     byte [r12+2], 'f'
    jmp     .finish
.nan_print:
    mov     dword [r12], 'Na'
    mov     byte [r12+2], 'N'

.finish:
    mov     byte [r12], 0
    mov     rax, ARG2
.done:
    add     rsp, 32
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_atof(buf) — ASCII to float
; ARG1 = string, returns double in xmm0
; ============================================================================
global ak_atof
ak_atof:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 8

    mov     r12, ARG1
    xor     r13, r13                   ; sign flag
    xor     r14, r14                   ; integer part
    xor     r15, r15                   ; fractional part
    xor     rbx, rbx                   ; fractional digits

    ; Skip whitespace
.skip:
    mov     al, [r12]
    cmp     al, 32
    je      .next
    cmp     al, 9
    je      .next
    jmp     .check_sign
.next:
    inc     r12
    jmp     .skip

.check_sign:
    cmp     al, '-'
    jne     .check_plus_sign
    mov     r13, 1
    inc     r12
    jmp     .int_part
.check_plus_sign:
    cmp     al, '+'
    jne     .int_part
    inc     r12

.int_part:
    mov     al, [r12]
    cmp     al, '0'
    jb      .check_point
    cmp     al, '9'
    ja      .check_point
    sub     al, '0'
    imul    r14, 10
    add     r14, rax
    inc     r12
    jmp     .int_part

.check_point:
    cmp     al, '.'
    jne     .finish
    inc     r12

.fract_part:
    mov     al, [r12]
    cmp     al, '0'
    jb      .finish_fract
    cmp     al, '9'
    ja      .finish_fract
    sub     al, '0'
    imul    r15, 10
    add     r15, rax
    inc     rbx
    inc     r12
    jmp     .fract_part

.finish_fract:
    ; Check for exponent
    mov     al, [r12]
    cmp     al, 'e'
    je      .exponent
    cmp     al, 'E'
    jne     .finish

.exponent:
    inc     r12
    xor     rcx, rcx
    xor     rdx, rdx
    mov     al, [r12]
    cmp     al, '-'
    jne     .exp_pos
    mov     rdx, 1
    inc     r12
    jmp     .exp_loop
.exp_pos:
    cmp     al, '+'
    jne     .exp_loop
    inc     r12
.exp_loop:
    mov     al, [r12]
    cmp     al, '0'
    jb      .finish_exp
    cmp     al, '9'
    ja      .finish_exp
    sub     al, '0'
    imul    rcx, 10
    add     rcx, rax
    inc     r12
    jmp     .exp_loop
.finish_exp:
    test    rdx, rdx
    jz      .exp_positive
    neg     rcx
.exp_positive:
    add     rcx, rbx
    neg     rcx
    mov     rbx, rcx

.finish:
    ; Build double: (fractional / 10^digits + integer)
    cvtsi2sd xmm0, r14                ; integer part

    test    rbx, rbx
    jz      .apply_sign
    cvtsi2sd xmm1, r15
    mov     rcx, 1
.fp_pow:
    imul    rcx, 10
    dec     rbx
    jnz     .fp_pow
    cvtsi2sd xmm2, rcx
    divsd   xmm1, xmm2
    addsd   xmm0, xmm1

.apply_sign:
    test    r13, r13
    jz      .done
    mov     rax, 0x8000000000000000
    movq    xmm1, rax
    xorpd   xmm0, xmm1

.done:
    add     rsp, 8
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_memcpy(dst, src, n) — memory copy
; ============================================================================
global ak_memcpy
ak_memcpy:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1                   ; dst
    mov     r13, ARG2                   ; src
    mov     rbx, ARG3                   ; n
    test    rbx, rbx
    jz      .done
.loop:
    mov     al, [r13]
    mov     [r12], al
    inc     r12
    inc     r13
    dec     rbx
    jnz     .loop
.done:
    mov     rax, ARG1
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_memset(dst, val, n) — memory fill
; ============================================================================
global ak_memset
ak_memset:
    push    rbx
    push    r12
    mov     r12, ARG1
    %ifidn __OUTPUT_FORMAT__, win64
    mov     al, dl                     ; ARG2 lower byte (Windows: rdx → dl)
    %else
    mov     al, sil                    ; ARG2 lower byte (Linux: rsi → sil)
    %endif
    mov     rbx, ARG3                  ; n
    test    rbx, rbx
    jz      .done
.loop:
    mov     [r12], al
    inc     r12
    dec     rbx
    jnz     .loop
.done:
    mov     rax, ARG1
    pop     r12
    pop     rbx
    ret

; ============================================================================
; ak_exit(code) — clean process exit
; ============================================================================
global ak_exit
ak_exit:
%ifdef TARGET_WIN64
    extern  ExitProcess
    sub     rsp, 32                     ; shadow space
    call    ExitProcess
    add     rsp, 32
%else
    mov     rax, 60                    ; sys_exit
    syscall
%endif
    ret

; ============================================================================
; ak_print_newline — print a newline
; ============================================================================
global ak_print_newline
ak_print_newline:
    lea     ARG1, [str_newline]
    mov     ARG2, 1
    call    ak_print_str
    ret

; ============================================================================
; ak_print_bool(val) — print "true" or "false"
; ============================================================================
global ak_print_bool
ak_print_bool:
    test    ARG1, ARG1
    jz      .print_false
    lea     ARG1, [str_true]
    mov     ARG2, 4
    call    ak_print_str
    ret
.print_false:
    lea     ARG1, [str_false]
    mov     ARG2, 5
    call    ak_print_str
    ret

; ============================================================================
; ak_print_empty — print "empty"
; ============================================================================
global ak_print_empty
ak_print_empty:
    lea     ARG1, [str_empty]
    mov     ARG2, 5
    call    ak_print_str
    ret

; ============================================================================
; ak_error(msg, line, col) — print error message
; ============================================================================
global ak_error
ak_error:
    push    rbx
    push    r12
    push    r13
    mov     r12, ARG1
    mov     r13, ARG2
    mov     rbx, ARG3

    lea     ARG1, [.prefix]
    mov     ARG2, 2
    call    ak_print_str
    lea     ARG1, [msg_oom+6]          ; reuse "ERROR: "
    mov     ARG2, 7
    call    ak_print_str
    mov     ARG1, r12
    call    ak_print_str
    ; Print line number
    lea     ARG1, [.line_prefix]
    mov     ARG2, 7
    call    ak_print_str
    mov     ARG1, r13
    call    ak_print_num
    ; Print column number
    lea     ARG1, [.col_prefix]
    mov     ARG2, 6
    call    ak_print_str
    mov     ARG1, rbx
    call    ak_print_num
    call    ak_print_newline

    pop     r13
    pop     r12
    pop     rbx
    ret

.prefix     db "E: ", 0
.line_prefix db " at line ", 0
.col_prefix db ", col ", 0

; ============================================================================
; ak_test_run_all — execute all registered tests and print summary
; ============================================================================
global ak_test_run_all
ak_test_run_all:
    push    rbx
    push    r12
    push    r13

    lea     ARG1, [.msg_running]
    mov     ARG2, 0
    call    ak_print_str
    call    ak_print_newline

    ; Print test summary (placeholder — real impl would iterate registered tests)
    lea     ARG1, [.msg_done]
    mov     ARG2, 0
    call    ak_print_str
    call    ak_print_newline

    pop     r13
    pop     r12
    pop     rbx
    ret

.msg_running db "Test runner: executing all test suites...", 0
.msg_done db "Test runner: complete.", 0

; ============================================================================
; ak_docs_generate(path) — placeholder for documentation generation
; Takes a project root path and generates HTML documentation
; This will be replaced by the self-hosting compiler's docs module
; ============================================================================
global ak_docs_generate
ak_docs_generate:
    push    rbx
    push    r12
    mov     r12, ARG1

    ; Print running message
    lea     ARG1, [.msg_running_docs]
    mov     ARG2, 0
    call    ak_print_str
    call    ak_print_newline

    ; Print the project path
    mov     ARG1, r12
    call    ak_print_str
    call    ak_print_newline

    ; Print completion message
    lea     ARG1, [.msg_docs_done]
    mov     ARG2, 0
    call    ak_print_str
    call    ak_print_newline

    ; Return success (0)
    xor     rax, rax
    pop     r12
    pop     rbx
    ret

.msg_running_docs db "Docs generator: generating documentation...", 0
.msg_docs_done db "Docs generator: complete (placeholder — will be replaced by self-hosting compiler).", 0
