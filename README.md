# NovaLDR
This is a basic bootloader using the PE format, compatible with MSVC++ that I coded in a few months (I'm not too good at x86 assembly).\
My friends [@irql0](https://github.com/irql0) [@nikitpad](https://github.com/nikitpad) [@NullExceptionTSB](https://github.com/NullExceptionTSB) helped me a lot through this, I don't think I would've figured it out without them!\
\
For now, this only boots to protected mode and loads a PE binary.\
There is no support for a filesystem, and there is a [GDT](https://en.wikipedia.org/wiki/Global_Descriptor_Table) (Global Descriptor Table) that loads all the 4 gigabytes of memory.\
\
The PE loader included with the bootloader does not support relocations, so you must use a fixed base address.\
To use it, change the `incbin` line in `boot_stg2.asm` to the path of your kernel binary, I used Visual Studio MSVC++ to compile the kernel.\
I do not expect to make any changes to this bootloader for now, such as adding support for FAT16, so it is discontinued.\
\
To compile the bootloader, use [NASM](https://www.nasm.us/) (Netwide Assembler) with the command line `nasm boot.asm -o boot.bin`.\
To emulate it, you can use QEMU with the command line `qemu-system-x86_64 -drive file=boot.bin,format=raw -monitor stdio -no-reboot -no-shutdown`.\
You may add `-accel hax` as a parameter to enable Intel's hypervisor, [HAXM](https://github.com/intel/haxm) (Intel Hardware Accelerated Execution Manager).
