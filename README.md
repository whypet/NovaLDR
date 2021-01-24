# NovaLDR
a basic PE bootloader that i coded in a few months since i'm a huge asm noob\
my friends [@irql0](https://github.com/irql0) [@nikitpad](https://github.com/nikitpad) [@NullExceptionTSB](https://github.com/NullExceptionTSB) helped me a lot through this so mega huge pogchamp shoutouts to them\
\
for now, this only boots to protected mode and loads your pe binary\
(change the incbin line in boot_stg2.asm to your kernel, i used MSVC to compile the kernel)
anyways just do whatever you want i'll probably make this into something more advanced later,\
maybe it'll have support for a filesystem? FAT32?\
\
to compile the bootloader, use nasm with `nasm boot.asm -o boot.bin` and to run it use qemu with\
`qemu-system-x86_64 -drive file=boot.bin,format=raw -monitor stdio -no-reboot -no-shutdown`\
(you may add `-accel hax` as a parameter to enable intel's hypervisor haxm that you can download from github)
