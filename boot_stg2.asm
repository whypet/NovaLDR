%define TEXT_BUFFER 0x000B8000 ; Text buffer address

bits 32

%include "peldr32.asm"

second_stage:
	mov al, 0x0FF
    out 0x0A1, al
    out 0x021, al ; Mask 8259A
	mov esi, KRNL_MEM_BASE ; Address of kernel in memory
	jmp pe_load ; Load kernel PE binary

print32: ; ESI = String to print, EDI = Offset in text buffer, AH = Color
	pushad
	xor edx, edx
	add edi, TEXT_BUFFER ; Add text buffer address to offset
.load_char:
	lodsb
	cmp al, 0x0A ; Check for newline
	je .newline
	test al, al ; If zero, stop printing
	jz .end

	mov word [edi], ax ; Write character
	add edi, 2 ; Next character
	add edx, 2 ; Save the offset for newline
	jmp .load_char
.newline:
	mov ecx, 160 ; 80 (Buffer width) * 2
	sub ecx, edx
	add edi, ecx ; Check how many spaces to add for a newline
	xor edx, edx
	jmp .load_char
.end:
	popad
	ret

times BLDR_SIZE - ($ - $$) db 0x00
incbin "NovaKernel.sys"
times BINARY_SIZE - ($ - $$) db 0x00