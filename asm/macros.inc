; ============================================================================
; AK CODE Assembly Macros — Common Definitions for All Source Files
; Auto-detects target platform from NASM output format.
; ============================================================================

%ifidn __OUTPUT_FORMAT__, win64
    ; Microsoft x64 calling convention
    %define ARG1 rcx
    %define ARG2 rdx
    %define ARG3 r8
    %define ARG4 r9
    %define TARGET_WIN64 1
%else
    ; System V AMD64 calling convention (Linux)
    %define ARG1 rdi
    %define ARG2 rsi
    %define ARG3 rdx
    %define ARG4 r10
    %define TARGET_LINUX 1
%endif
