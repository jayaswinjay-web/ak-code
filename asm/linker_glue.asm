; ============================================================================
; AK CODE Linker Glue — ELF64/PE32+ Binary Producer
; Generates valid executable headers so the output is runnable.
; For Linux: emits ELF64 header, program headers, section headers.
; For Windows: emits PE32+ header, section table, import directory.
; ============================================================================

%include "macros.inc"

default rel

section .data
    ; ELF64 magic and header constants
    ELF_MAGIC    db 0x7F, 'E', 'L', 'F'
    ELF_CLASS    db 2           ; 64-bit
    ELF_DATA     db 1           ; little-endian
    ELF_VERSION  db 1
    ELF_OSABI    db 0           ; System V
    ELF_ABIVER   db 0
    ELF_PAD      times 7 db 0

    ; ELF header structure (64 bytes total)
    elf_header:
        db 0x7F, 'E', 'L', 'F'  ; e_ident magic
        db 2                     ; e_ident[EI_CLASS]
        db 1                     ; e_ident[EI_DATA]
        db 1                     ; e_ident[EI_VERSION]
        db 0                     ; e_ident[EI_OSABI]
        db 0                     ; e_ident[EI_ABIVERSION]
        times 7 db 0             ; e_ident padding
        dw 2                     ; e_type = ET_EXEC
        dw 0x3E                  ; e_machine = x86-64
        dd 1                     ; e_version
        dq 0x400000              ; e_entry (default load addr + entry offset)
        dq 64                    ; e_phoff
        dq 0                     ; e_shoff (filled in later)
        dd 0                     ; e_flags
        dw 64                    ; e_ehsize
        dw 56                    ; e_phentsize
        dw 3                     ; e_phnum (NULL, LOAD, DYNAMIC)
        dw 64                    ; e_shentsize
        dw 0                     ; e_shnum
        dw 0                     ; e_shstrndx

    ; Program header for PT_LOAD (text segment)
    ph_text:
        dd 1                     ; p_type = PT_LOAD
        dd 5                     ; p_flags = PF_R | PF_X
        dq 0                     ; p_offset
        dq 0x400000              ; p_vaddr
        dq 0x400000              ; p_paddr
        dq 0                     ; p_filesz (filled)
        dq 0                     ; p_memsz (filled)
        dq 0x1000                ; p_align

    ; Program header for PT_LOAD (data segment)
    ph_data:
        dd 1                     ; p_type = PT_LOAD
        dd 6                     ; p_flags = PF_R | PF_W
        dq 0                     ; p_offset (filled)
        dq 0x600000              ; p_vaddr (filled)
        dq 0x600000              ; p_paddr
        dq 0                     ; p_filesz (filled)
        dq 0                     ; p_memsz (filled)
        dq 0x1000                ; p_align

    ; Program header for PT_GNU_STACK
    ph_stack:
        dd 0x6474E551            ; p_type = PT_GNU_STACK
        dd 6                     ; p_flags = PF_R | PF_W
        dq 0, 0, 0, 0, 0x10     ; p_align

    ; PE32+ constants (Windows)
    PE_MAGIC     db 'P', 'E', 0, 0
    PE_MACHINE   dw 0x8664       ; x86-64
    PE_SECTIONS  dw 3            ; .text, .data, .idata

    ; DOS header for PE (stub)
    dos_header:
        dw 0x5A4D                ; 'MZ'
        dw 0                     ; bytes in last page
        dw 0                     ; pages
        dw 0                     ; relocations
        dw 4                     ; header size (paragraphs)
        dw 0                     ; minalloc
        dw 0xFFFF                ; maxalloc
        dw 0                     ; initial SS
        dw 0                     ; initial SP
        dw 0                     ; checksum
        dw 0                     ; initial IP
        dw 0                     ; initial CS
        dw 0x40                  ; file address of reloc table
        dw 0                     ; overlay number
        times 8 dw 0             ; reserved
        dd 0x80                  ; PE signature offset

    ; PE signature (at offset 0x80)
    pe_sig       dd 0x00004550  ; 'PE\0\0'

    ; COFF header
    coff_header:
        dw 0x8664               ; machine (x86-64)
        dw 3                    ; number of sections
        dd 0                    ; timestamp
        dd 0                    ; pointer to symbol table
        dd 0                    ; number of symbols
        dw 0xF0                 ; size of optional header
        dw 0x22                 ; characteristics (EXECUTABLE | LARGE_ADDRESS_AWARE)

    ; Optional header (PE32+)
    opt_header:
        dw 0x20B                ; PE32+ magic
        db 0                    ; major linker version
        db 0                    ; minor linker version
        dd 0                    ; size of code
        dd 0                    ; size of initialized data
        dd 0                    ; size of uninitialized data
        dd 0x1000               ; entry point (RVA)
        dd 0x1000               ; base of code
        dq 0x140000000          ; image base (typical for x64)
        dd 0x1000               ; section alignment
        dd 0x200                ; file alignment
        dw 0                    ; major OS version
        dw 0                    ; minor OS version
        dw 0                    ; major image version
        dw 0                    ; minor image version
        dw 6                    ; major subsystem version
        dw 0                    ; minor subsystem version
        dd 0                    ; Win32 version value
        dd 0                    ; size of image
        dd 0                    ; size of headers
        dd 0                    ; checksum
        dw 3                    ; subsystem (CONSOLE)
        dw 0x8160               ; DLL characteristics (NX compatible, TS aware, etc.)
        dq 0                    ; size of stack reserve
        dq 0x100000             ; size of stack commit
        dq 0x100000             ; size of heap reserve
        dq 0x1000               ; size of heap commit
        dd 0                    ; loader flags
        dd 16                   ; number of data directory entries

    ; Data directories (16 entries)
    data_dirs:
        dd 0, 0                 ; Export
        dd 0, 0                 ; Import (filled later)
        dd 0, 0                 ; Resource
        dd 0, 0                 ; Exception
        dd 0, 0                 ; Security
        dd 0, 0                 ; Base Reloc
        dd 0, 0                 ; Debug
        dd 0, 0                 ; Architecture
        dd 0, 0                 ; Global Ptr
        dd 0, 0                 ; TLS
        dd 0, 0                 ; Load Config
        dd 0, 0                 ; Bound Import
        dd 0, 0                 ; IAT
        dd 0, 0                 ; Delay Import
        dd 0, 0                 ; COM+
        dd 0, 0                 ; Reserved

section .text
    global ak_build_elf
    global ak_build_pe

; ============================================================================
; ak_build_elf(code_buf, code_size, data_buf, data_size) -> ELF binary
; Wraps the generated code+data in an ELF64 executable.
; Uses correct file offset and vaddr calculations for a minimal ELF.
; ============================================================================
ak_build_elf:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 48

    mov     r12, ARG1                   ; code buffer
    mov     r13, ARG2                   ; code size
    mov     r14, ARG3                   ; data buffer
    mov     r15, ARG4                   ; data size

    ; Calculate sizes
    ; ELF header + program headers = 64 + 3*56 = 232 bytes
    ; Code starts at page-aligned offset 0x1000
    ; Data starts after code, page-aligned

    mov     rax, r13
    add     rax, 0xFFF
    and     rax, ~0xFFF                 ; align_up(code_size, 0x1000)
    mov     rbx, rax                    ; rbx = code_size_aligned

    mov     rax, r15
    add     rax, 0xFFF
    and     rax, ~0xFFF                 ; align_up(data_size, 0x1000)
    mov     rcx, rax                    ; rcx = data_size_aligned

    ; Total buffer size = headers (0x1000) + code_aligned + data_aligned
    mov     rax, 0x1000
    add     rax, rbx
    add     rax, rcx
    mov     ARG1, rax
    call    ak_malloc
    test    rax, rax
    jz      .fail
    mov     rbx, rax                    ; rbx = ELF buffer

    ; Zero out the buffer
    push    rbx
    mov     ARG1, rbx
    xor     ARG2, ARG2
    mov     ARG3, 0x2000
    call    ak_memset
    pop     rbx

    ; --- ELF Header (offset 0) ---
    ; e_ident
    mov     rax, 0x00010102464C457F
    mov     [rbx], rax
    mov     qword [rbx+8], 0

    ; e_type, e_machine, e_version
    mov     word [rbx+16], 2
    mov     word [rbx+18], 0x3E
    mov     dword [rbx+20], 1

    ; e_entry = 0x401000 (vaddr of code section)
    mov     qword [rbx+24], 0x401000

    ; e_phoff = 64
    mov     qword [rbx+32], 64

    ; e_shoff = 0 (no section headers)
    mov     qword [rbx+40], 0

    ; e_flags
    mov     dword [rbx+48], 0

    ; e_ehsize, e_phentsize, e_phnum
    mov     word [rbx+52], 64
    mov     word [rbx+54], 56
    mov     word [rbx+56], 2            ; phnum = 2 (text LOAD, data LOAD)
    mov     word [rbx+58], 0
    mov     word [rbx+60], 0
    mov     word [rbx+62], 0

    ; --- Program header 1: PT_LOAD for text (offset 64) ---
    mov     dword [rbx+64], 1           ; p_type = PT_LOAD
    mov     dword [rbx+68], 5           ; p_flags = PF_R | PF_X
    mov     qword [rbx+72], 0x1000      ; p_offset = 0x1000
    mov     qword [rbx+80], 0x400000    ; p_vaddr
    mov     qword [rbx+88], 0x400000    ; p_paddr
    mov     qword [rbx+96], r13         ; p_filesz = code_size
    mov     qword [rbx+104], r13        ; p_memsz = code_size
    mov     qword [rbx+112], 0x1000     ; p_align

    ; --- Program header 2: PT_LOAD for data (offset 120) ---
    mov     dword [rbx+120], 1          ; p_type = PT_LOAD
    mov     dword [rbx+124], 6          ; p_flags = PF_R | PF_W

    ; Calculate data file offset: 0x1000 + align_up(code_size, 0x1000)
    mov     rax, r13
    add     rax, 0xFFF
    and     rax, ~0xFFF
    add     rax, 0x1000
    mov     qword [rbx+128], rax        ; p_offset (file offset)

    ; Calculate data vaddr: 0x400000 + 0x1000 + align_up(code_size, 0x1000)
    ; But vaddr % 0x1000 must equal file_offset % 0x1000 (which is 0)
    ; So vaddr = 0x400000 + 0x1000 + align_up(code_size, 0x1000) - 0x1000? 
    ; Actually: text PH maps 0x400000..0x400000+code_size at file 0x1000
    ; Data PH maps starting at file offset = 0x1000 + align_up(code_size)
    ; Data vaddr = 0x400000 + align_up(code_size, 0x1000)
    mov     rax, r13
    add     rax, 0xFFF
    and     rax, ~0xFFF
    mov     rcx, rax
    add     rcx, 0x400000               ; data vaddr = base + code_aligned_size
    mov     qword [rbx+136], rcx        ; p_vaddr
    mov     qword [rbx+144], rcx        ; p_paddr
    mov     qword [rbx+152], r15        ; p_filesz = data_size
    mov     qword [rbx+160], r15        ; p_memsz = data_size
    mov     qword [rbx+168], 0x1000     ; p_align

    ; --- Copy code to file offset 0x1000 ---
    mov     ARG1, rbx
    add     ARG1, 0x1000
    mov     ARG2, r12
    mov     ARG3, r13
    call    ak_memcpy

    ; --- Copy data to its file offset ---
    mov     rax, r13
    add     rax, 0xFFF
    and     rax, ~0xFFF
    add     rax, 0x1000
    mov     ARG1, rbx
    add     ARG1, rax
    mov     ARG2, r14
    mov     ARG3, r15
    call    ak_memcpy

    ; Calculate total ELF size and store at buffer[0]
    ; Total = 0x1000 (headers) + align_up(code_size, 0x1000) + align_up(data_size, 0x1000)
    mov     rax, r13
    add     rax, 0xFFF
    and     rax, ~0xFFF                 ; align_up(code_size)
    add     rax, 0x1000                 ; + headers
    mov     rcx, r15
    add     rcx, 0xFFF
    and     rcx, ~0xFFF                 ; align_up(data_size)
    add     rax, rcx                    ; total size
    mov     [rbx], rax                  ; store at buffer[0]

    ; Return pointer to buffer (with total size in first 8 bytes)
    mov     rax, rbx
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
; ak_build_pe(code_buf, code_size, data_buf, data_size) -> PE binary
; Wraps the generated code+data in a PE32+ executable.
; ============================================================================
ak_build_pe:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 48

    mov     r12, ARG1
    mov     r13, ARG2
    mov     r14, ARG3
    mov     r15, ARG4

    ; Allocate buffer for PE
    ; DOS header: 64 bytes (including stub)
    ; PE signature: 4 bytes
    ; COFF header: 20 bytes
    ; Optional header: 240 bytes (PE32+ with 16 data dirs)
    ; Section table: 3 * 40 = 120 bytes
    ; Total headers: 448 bytes
    ; Aligned to file alignment (0x200) = 0x600
    ; Then .text, .data, .idata sections

    mov     rbx, 0x600                     ; header size rounded to file alignment
    add     rbx, r13                       ; + code size
    add     rbx, 0x200                     ; align
    and     rbx, ~0x1FF
    add     rbx, r15                       ; + data size
    add     rbx, 0x200                     ; + import section (approx)

    mov     ARG1, rbx
    call    ak_malloc
    test    rax, rax
    jz      .pe_fail
    mov     rbx, rax

    ; Zero out buffer
    push    rbx
    mov     ARG1, rbx
    xor     ARG2, ARG2
    mov     ARG3, 4096
    call    ak_memset
    pop     rbx

    ; Write DOS header (64 bytes)
    mov     word [rbx], 0x5A4D             ; 'MZ'
    mov     qword [rbx+2], 0
    mov     dword [rbx+0x3C], 0x80         ; e_lfanew = PE sig at offset 0x80

    ; Write PE signature at offset 0x80
    mov     dword [rbx+0x80], 0x00004550   ; 'PE\0\0'

    ; COFF header at offset 0x84
    mov     word [rbx+0x84], 0x8664        ; machine
    mov     word [rbx+0x86], 3             ; number of sections
    mov     dword [rbx+0x88], 0            ; timestamp
    mov     dword [rbx+0x8C], 0            ; ptr to symbols
    mov     dword [rbx+0x90], 0            ; num symbols
    mov     word [rbx+0x94], 0xF0          ; size of optional header
    mov     word [rbx+0x96], 0x22          ; characteristics

    ; Optional header (PE32+) at offset 0x98
    mov     word [rbx+0x98], 0x20B         ; PE32+ magic
    mov     byte [rbx+0x9A], 14            ; major linker
    mov     byte [rbx+0x9B], 0             ; minor linker
    mov     dword [rbx+0x9C], r13d         ; size of code
    mov     dword [rbx+0xA0], r15d         ; size of init data
    mov     dword [rbx+0xA4], 0            ; size of uninit data
    mov     dword [rbx+0xA8], 0x1000       ; entry point (RVA of .text)
    mov     dword [rbx+0xAC], 0x1000       ; base of code (RVA)
    mov     rax, 0x140000000
    mov     [rbx+0xB0], rax                 ; image base
    mov     dword [rbx+0xB8], 0x1000       ; section alignment
    mov     dword [rbx+0xBC], 0x200        ; file alignment

    ; Windows version
    mov     word [rbx+0xC0], 10            ; major OS
    mov     word [rbx+0xC2], 0             ; minor OS
    mov     word [rbx+0xC4], 0             ; major image
    mov     word [rbx+0xC6], 0             ; minor image
    mov     word [rbx+0xC8], 6             ; major subsystem
    mov     word [rbx+0xCA], 0             ; minor subsystem

    mov     dword [rbx+0xCC], 0            ; Win32 version
    mov     dword [rbx+0xD0], 0            ; size of image (filled later)
    mov     dword [rbx+0xD4], 0x600        ; size of headers
    mov     dword [rbx+0xD8], 0            ; checksum
    mov     word [rbx+0xDC], 3             ; subsystem (CONSOLE)
    mov     word [rbx+0xDE], 0x8160        ; DLL characteristics
    mov     qword [rbx+0xE0], 0x100000     ; stack reserve
    mov     qword [rbx+0xE8], 0x10000      ; stack commit
    mov     qword [rbx+0xF0], 0x100000     ; heap reserve
    mov     qword [rbx+0xF8], 0x1000       ; heap commit
    mov     dword [rbx+0x100], 0           ; loader flags
    mov     dword [rbx+0x104], 16          ; data directories

    ; Data directories (at offset 0x108)
    ; We'll fill import directory later
    ; Import directory at RVA 0x8000, size 0x1000 (placeholder)
    mov     dword [rbx+0x118], 0x8000      ; Import RVA
    mov     dword [rbx+0x11C], 0x1000      ; Import size

    ; Section table (at offset 0x108 + 16*8 = 0x188)
    ; But wait, the section table is after optional header
    ; Optional header size = 0xF0, so section table at 0x98 + 0xF0 = 0x188
    ; Actually optional header starts at 0x98, its size is 0xF0 as declared,
    ; so section table starts at 0x98 + 0xF0 = 0x188

    ; Section .text
    ; Name
    mov     dword [rbx+0x188], 0x78742E    ; ".tex"
    mov     dword [rbx+0x18C], 0x00000074  ; "t\0\0\0"
    ; Virtual size
    mov     dword [rbx+0x190], r13d        ; virtual size = code size (rounded up)
    ; Virtual address
    mov     dword [rbx+0x194], 0x1000      ; RVA
    ; Size of raw data
    mov     rax, r13
    add     rax, 0x200 - 1
    and     rax, ~0x1FF                     ; round to file alignment
    mov     dword [rbx+0x198], eax         ; size of raw data
    ; Pointer to raw data
    mov     dword [rbx+0x19C], 0x600       ; raw data ptr
    ; Pointer to relocations
    mov     dword [rbx+0x1A0], 0
    mov     dword [rbx+0x1A4], 0
    ; Characteristics
    mov     dword [rbx+0x1A8], 0x60000020  ; CODE | EXECUTE | READ

    ; Section .data
    mov     dword [rbx+0x1AC], 0x6174612E  ; ".dat"
    mov     dword [rbx+0x1B0], 0x00000061  ; "a\0\0\0"
    mov     dword [rbx+0x1B4], r15d        ; virtual size
    mov     dword [rbx+0x1B8], eax         ; RVA (after .text rounded up)
    ; Actually calculate RVA for data
    mov     eax, r13d
    add     eax, 0x1000 - 1
    and     eax, ~0xFFF
    add     eax, 0x1000                    ; round to section alignment
    mov     dword [rbx+0x1B8], eax         ; RVA for .data
    mov     rax, r15
    add     rax, 0x200 - 1
    and     rax, ~0x1FF
    mov     dword [rbx+0x1BC], eax         ; size of raw data
    ; Pointer to raw data (after .text)
    mov     eax, r13d
    add     eax, 0x200 - 1
    and     eax, ~0x1FF
    add     eax, 0x600                     ; after .text in file
    mov     dword [rbx+0x1C0], eax         ; raw data ptr
    mov     dword [rbx+0x1C4], 0
    mov     dword [rbx+0x1C8], 0
    mov     dword [rbx+0x1CC], 0xC0000040  ; INITIALIZED_DATA | READ | WRITE

    ; Section .idata (import)
    mov     dword [rbx+0x1D0], 0x6174692E  ; ".ida"
    mov     dword [rbx+0x1D4], 0x00006174  ; "ta\0\0"
    mov     dword [rbx+0x1D8], 0x1000      ; virtual size
    mov     dword [rbx+0x1DC], 0x8000      ; RVA
    mov     dword [rbx+0x1E0], 0x200       ; size of raw data (rounded)
    mov     dword [rbx+0x1E4], 0           ; raw data ptr (filled)
    mov     dword [rbx+0x1E8], 0
    mov     dword [rbx+0x1EC], 0
    mov     dword [rbx+0x1F0], 0xC0000040  ; INITIALIZED_DATA | READ

    ; Copy code to offset 0x600
    mov     ARG1, rbx
    add     ARG1, 0x600
    mov     ARG2, r12
    mov     ARG3, r13
    call    ak_memcpy

    ; Copy data after code
    mov     eax, r13d
    add     eax, 0x200 - 1
    and     eax, ~0x1FF
    add     eax, 0x600
    mov     ARG1, rbx
    add     ARG1, rax
    mov     ARG2, r14
    mov     ARG3, r15
    call    ak_memcpy

    ; Calculate image size
    mov     eax, 0x8000                    ; .idata starts at 0x8000
    add     eax, 0x1000                    ; + virtual size
    mov     [rbx+0xD0], eax                ; size of image

    mov     rax, rbx
    add     rsp, 48
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.pe_fail:
    xor     rax, rax
    add     rsp, 48
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================================
; External references
; ============================================================================
extern ak_malloc
extern ak_memcpy
extern ak_memset
extern ak_print_str
extern ak_print_newline
extern ak_exit
