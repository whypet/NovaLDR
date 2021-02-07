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
	; Check if binary has MZ magic number
	mov ax, word [esi+e_magic]
	cmp ax, 0x5A4D
	jne .non_pe_error

	; Get NT headers offset
	mov ebx, dword [esi+e_lfanew]
	add ebx, esi

	; Checking for 'PE\0\0' signature
	cmp dword [ebx], 0x00004550
	jne .dos_pe_error
	
	; Checking for Intel 386 machine ID
	cmp word [ebx+NtFileHeader], 0x014C
	jne .non_i386_error

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

%define SectionHeader edx+SizeOfNtHeaders
.load_section:
	; Copy raw data to image base
	pushad
	mov ecx, dword [ebx+SectionHeader+SizeOfRawData]
	add esi, dword [ebx+SectionHeader+PointerToRawData]
	add edi, dword [ebx+SectionHeader+VirtualAddress]

	; Check if virtual size is smaller than raw data size
	cmp ecx, [ebx+SectionHeader+VirtualSize]
	jge .virtual_smaller
	rep movsb

	; Pad the remainder of virtual size with zeros
	mov ecx, dword [ebx+SectionHeader+VirtualSize]
	sub ecx, dword [ebx+SectionHeader+SizeOfRawData]
	xor al, al
	rep stosb
	jmp .next_section
.virtual_smaller:
	; Copy virtual size amount of bytes instead
	mov ecx, [ebx+SectionHeader+VirtualSize]
	rep movsb
%undef SectionHeader
.next_section:
	popad
	add edx, SizeOfSectionHeader ; Go to next section and check if we reached the last section
	cmp edx, eax
	jge .end
	jmp .load_section
.non_pe_error:
	mov esi, msg_non_pe
	jmp .error
.dos_pe_error:
	mov esi, msg_dos_pe
	jmp .error
.non_i386_error:
	mov esi, msg_non_i386
.error:
	xor edi, edi
	mov ah, 0x0C
	call print32 ; Print error message
	hlt ; Halt
.end:
	; Jump to entry point
	mov eax, dword [ebx+NtOptionalHeader+ImageBase]
	add eax, dword [ebx+NtOptionalHeader+AddressOfEntryPoint]
	jmp eax

; Error messages
msg_non_pe db "PE loader error: The specified address does not have a PE binary.", 0x0A, "(Magic number MZ was not present)", 0x00
msg_dos_pe db "PE loader error: The binary is a DOS MZ executable. (No PE signature)", 0x00
msg_non_i386 db "PE loader error: The PE binary is not an Intel 386 binary.", 0x00
