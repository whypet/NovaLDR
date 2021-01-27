; DOS Header
%define e_magic  0x00
%define e_lfanew 0x3C

; NT Headers
%define SizeOfNtHeaders 0xF8

; File Header
%define NtFileHeader     0x04
%define SizeOfFileHeader 0x14
%define NumberOfSections 0x02

; Optional Header
%define NtOptionalHeader     0x18
%define SizeOfOptionalHeader 0xE0
%define AddressOfEntryPoint  0x10
%define ImageBase            0x1C
%define SizeOfHeaders        0x3C

; Section Headers
%define SizeOfSectionHeader 0x28
%define VirtualSize         0x08
%define VirtualAddress      0x0C
%define SizeOfRawData       0x10
%define PointerToRawData    0x14

; Loads a PE binary located at address KRNL_MEM_BASE into memory.
pe_load: ; ESI = Address of binary in memory
	; Check if base contains the right binary with MZ signature
	mov ax, word [esi+e_magic]
	cmp ax, 0x5A4D
	jne .error
	
	; Get NT headers offset
	mov ebx, dword [esi+e_lfanew]
	add ebx, esi

	; Copy headers
	mov ecx, dword [ebx+NtOptionalHeader+SizeOfHeaders]
	mov edi, dword [ebx+NtOptionalHeader+ImageBase]
	pushad
	rep movsb
	popad

	; Get number of sections
	movzx edx, word [ebx+NtFileHeader+NumberOfSections]
	mov eax, SizeOfSectionHeader
	imul eax, edx
	xor edx, edx
.load_section:
%define SectionHeader edx+SizeOfNtHeaders
	; Zero VirtualSize amount of bytes at the image base in the current section header
	mov ecx, dword [ebx+SectionHeader+VirtualSize]
	mov edi, dword [ebx+SectionHeader+VirtualAddress]
	pushad
	xor al, al
	rep stosb
	popad

	; Copy raw data to image base
	mov ecx, dword [ebx+SectionHeader+SizeOfRawData]
	add edi, dword [ebx+NtOptionalHeader+ImageBase]
	push esi
	add esi, dword [ebx+SectionHeader+PointerToRawData]
	rep movsb
	pop esi

	add edx, SizeOfSectionHeader ; Go to next section and check if we reached the last section
	cmp edx, eax
	jge .end
	jmp .load_section
.error:
	mov esi, pe_error
	xor edi, edi
	mov ah, 0x0C
	call print32 ; Print error message
	hlt ; Halt
.end:
	; Jump to entry point
	mov eax, dword [ebx+NtOptionalHeader+ImageBase]
	add eax, dword [ebx+NtOptionalHeader+AddressOfEntryPoint]
	jmp eax

; Error message
pe_error db "PE loader error: You specified the wrong memory address,", 0x0A, "or you put your binary at the wrong location!", 0x00
