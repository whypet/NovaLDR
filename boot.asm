bits 16
org 0x7C00 ; Set image base

; Macros
%define STAGE2_MEM_BASE    0x00007E00                         ; Second stage bootloader base in memory (0x00007C00 + 0x00000200)
%define KRNL_MEM_BASE      STAGE2_MEM_BASE + 0x400            ; Kernel base in memory
%define STAGE2_SECTOR_SIZE 2                                  ; Second stage bootloader size in sectors
%define KRNL_SECTOR_SIZE   64                                 ; Kernel size in sectors
%define BLDR_SIZE          512 + STAGE2_SECTOR_SIZE * 512     ; Size of bootloader binary
%define BINARY_SIZE        BLDR_SIZE + KRNL_SECTOR_SIZE * 512 ; Size of binary

xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax ; Clear segment registers

mov esp, 0x7C00
mov ebp, esp ; Stack starts at bootloader base
mov byte [boot_disk], dl ; Keep boot disk value to load boot

jmp 0x0000:load ; Clear CS, some BIOSes set CS=0x7C0 and IP=0

load:
	call cls ; Clear text buffer
	call a20 ; Enable A20 gate
	
	push dx
	xor ax, ax
	mov ds, ax
	mov ah, 0x42 ; Extended read sectors function
	mov dl, byte [boot_disk] ; Boot disk
	mov si, dap ; Send DAP parameter (Disk Address Packet)
	int 0x13 ; Load required sectors ahead of MBR
	pop dx

	; Enter protected mode
	cli ; Disable interrupts
	lgdt [gdt.descriptor] ; Load GDTR

	mov eax, cr0 
	or al, 1
	mov cr0, eax ; Set protection enable bit in control register 0
	
	mov ax, 0x10
	mov ds, ax
	mov ss, ax 
	mov es, ax
	mov fs, ax
	mov gs, ax ; Set segment registers

	jmp 0x0008:second_stage ; Jump to second stage bootloader

cls: ; A simple "workaround" that just sets a video mode and it clears the screen.
	push ax
	mov ah, 0x00 ; Set video mode function
	mov al, 0x03 ; Text mode, 80x25, 16 colors
	int 0x10
	pop ax
	ret

a20:
	push ax
	in al, 0x92
	or al, 0x02
	out 0x92, al
	pop ax
	ret

; Structures
dap: ; Disk Address Packet
	db 16                                    ; DAP is 16 bytes long
	db 0x00                                  ; Unused byte
	dw STAGE2_SECTOR_SIZE + KRNL_SECTOR_SIZE ; Amount of sectors
	dw 0x0000, STAGE2_MEM_BASE >> 4          ; Write to STAGE2_MEM_BASE:0x0000
	dq 1                                     ; Second sector

gdt: ; Global Descriptor Table
	.start:
	dq 0 ; Null descriptor
	
	; Code segment descriptor
	dw 0xFFFF ; Limit (bits 0-15), full 4GB address space
	dw 0x0000 ; Segment base (bits 0-15)
	db 0x00 ; Segment base (bits 16-23)
	db 10011010b ; Accessed bit = 0, R/W = 1 (Read access for code segment), Direction = 0 (Segment grows up), Executable = 1, Descriptor type = 1, Privilege = 00 (Ring 0, Kernel), Present = 1
	db 11001111b ; Limit (bits 16-19), flags: 32-bit protected mode, page granularity
	db 0x00 ; Segment base (bits 24-31)
	
	; Data segment descriptor
	dw 0xFFFF ; Limit (bits 0-15), full 4GB address space
	dw 0x0000 ; Segment base (bits 0-15)
	db 0x00 ; Segment base (bits 16-23)
	db 10010010b ; Accessed bit = 0, R/W = 1 (Write access for data segment), Direction = 0 (Segment grows up), Executable = 0, Descriptor type = 1, Privilege = 00 (Ring 0, Kernel), Present = 1
	db 11001111b ; Limit (bits 16-19), flags: 32-bit protected mode, page granularity
	db 0x00 ; Segment base (bits 24-31)
	
	; No task state segment descriptor
	.end:
	
	.descriptor:
	dw gdt.end - gdt.start - 1 ; Size
	dd gdt.start ; Offset

; Data
boot_disk db 0x00

times 510 - ($ - $$) db 0
dw 0xAA55 ; Signature

%include "boot_stg2.asm"
