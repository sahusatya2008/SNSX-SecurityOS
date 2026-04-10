# SecurityOS

SecurityOS is a from-scratch x86/x86-64 microkernel-oriented operating system written primarily in NASM assembly with a security-first design.

This repository is organized to support two goals at once:

1. Build a real boot path from BIOS to a 64-bit kernel.
2. Evolve that kernel into a security research platform with defensive monitoring built into the core runtime.

## Milestone in this scaffold

This first scaffold is designed around a clean foundation:

- BIOS stage 1 boot sector
- Stage 2 loader that enters 64-bit long mode
- Flat 64-bit kernel image loaded at `0x10000`
- VGA text console and COM1 serial output
- Early IDT, PIC, PIT, and keyboard initialization hooks
- Security engine scaffolding for:
  - stack integrity checks
  - kernel text checksum verification
  - page-fault logging
  - safe input boundaries
  - a controlled vulnerability demo

The implementation is intentionally modular so the kernel can grow from a single-address-space prototype into a stricter microkernel split.

## Directory layout

`/bootloader`

- BIOS stage 1 sector loader
- stage 2 long-mode transition code

`/kernel`

- 64-bit kernel entry
- interrupt setup
- common kernel services

`/memory`

- paging and memory protection logic

`/security`

- logging, integrity, and anomaly monitoring

`/sandbox`

- safe vulnerability lab and diagnostic demos

`/drivers`

- console, serial, keyboard, PIT, and PIC helpers

`/shell`

- command parser and shell loop

`/docs`

- architecture and implementation guidance

## Build

Requirements:

- `nasm`
- `qemu-system-x86_64`
- `dd`

Build the image:

```bash
make
```

Run in QEMU:

```bash
make run
```

Headless debug output over serial:

```bash
make run-serial
```

## Commands planned for the shell

- `memcheck`
- `integrity`
- `procstat`
- `vuln-demo`

## Implementation roadmap

The detailed plan lives in:

- [Architecture](/Volumes/Blockchain Drive/HighLevelSoftwares/SecurityOS/docs/ARCHITECTURE.md)
- [Boot Plan](/Volumes/Blockchain Drive/HighLevelSoftwares/SecurityOS/docs/BOOTFLOW.md)
- [Security Engine](/Volumes/Blockchain Drive/HighLevelSoftwares/SecurityOS/docs/SECURITY_ENGINE.md)
- [Implementation Steps](/Volumes/Blockchain Drive/HighLevelSoftwares/SecurityOS/docs/IMPLEMENTATION_PLAN.md)
# SNSX-SecurityOS
# SNSX-SecurityOS
