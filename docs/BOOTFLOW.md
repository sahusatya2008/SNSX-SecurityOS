# Boot Flow

## Stage 1 boot sector

Responsibilities:

- start in 16-bit real mode at `0x7C00`
- initialize segment registers and stack
- preserve BIOS boot drive from `DL`
- use BIOS extended read (`INT 13h AH=42h`) to load stage 2
- jump to stage 2 at `0x8000`

Why keep it tiny:

- it must fit in 512 bytes including the `0xAA55` signature
- complexity belongs in stage 2, not the boot sector

## Stage 2 loader

Responsibilities:

- print early status
- enable A20
- load the kernel image at `0x10000`
- build a temporary GDT
- build minimal identity-mapped paging
- enable long mode
- far jump into 64-bit code

The stage 2 mapping is deliberately permissive. The kernel later replaces it with finer-grained secure mappings.

## Kernel entry

Responsibilities:

- install a stable kernel stack
- bring up serial and VGA output
- initialize IDT, PIC, PIT, and keyboard path
- replace temporary paging
- initialize security engine
- enter the shell loop

## Debugging strategy

- use serial output as soon as possible
- keep each boot phase visibly logged
- after each new feature, confirm boot still reaches the shell
