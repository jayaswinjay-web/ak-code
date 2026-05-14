; ============================================================================
; AK CODE Package Manager (akpkg) — Windows x64 Bootstrap Entry Point
; Prints banner and usage information, then exits.
; The real akpkg is compiled from akpkg.ak via the AK CODE compiler.
; This is a standalone console application using only kernel32.
; ============================================================================

default rel

global main

extern GetStdHandle
extern WriteFile
extern ExitProcess

section .data
    msg_banner      db "AK Package Manager v1.0", 13, 10
    banner_len      equ $ - msg_banner
    msg_usage       db "Usage: akpkg <command> [package]", 13, 10
                    db "Commands: install, add, remove, publish, list, update", 13, 10
                    db 13, 10
                    db "Run 'akpkg' without arguments for detailed help.", 13, 10
    usage_len       equ $ - msg_usage

section .text

; ============================================================================
; main — program entry point (called by CRT)
; All parameters ignored — just prints banner and exits.
; ============================================================================
main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 64                     ; allocate shadow space + alignment

    ; Get stdout handle
    mov     ecx, -11                    ; STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     r12, rax                    ; r12 = stdout handle

    ; Write banner string
    mov     rcx, r12                    ; hFile
    lea     rdx, [msg_banner]           ; lpBuffer
    mov     r8d, banner_len             ; nNumberOfBytesToWrite
    lea     r9, [rsp + 40]              ; lpNumberOfBytesWritten
    mov     qword [rsp + 32], 0         ; lpOverlapped (NULL)
    call    WriteFile

    ; Write usage string
    mov     rcx, r12                    ; hFile
    lea     rdx, [msg_usage]            ; lpBuffer
    mov     r8d, usage_len              ; nNumberOfBytesToWrite
    lea     r9, [rsp + 40]              ; lpNumberOfBytesWritten
    mov     qword [rsp + 32], 0         ; lpOverlapped (NULL)
    call    WriteFile

    ; Exit with code 0
    xor     ecx, ecx                    ; uExitCode = 0
    call    ExitProcess

    ; Should never reach here
    hlt
