# SecurityOS Architecture

## Design goals

SecurityOS is built as a microkernel-oriented system rather than a fully monolithic kernel. The first milestone keeps several services in the kernel address space for simplicity, but every subsystem is separated as if it will later become an isolated service.

That split matters because the security engine is not an afterthought. It is part of the system contract:

- boot measures the kernel image
- memory mappings encode least-privilege intent
- faults become structured security signals
- shell-facing input routines are bounded and audited
- vulnerability demonstrations happen only inside an educational sandbox

## Boot chain

1. `stage1`
   Loads a fixed-size stage 2 payload from disk via BIOS LBA extensions.

2. `stage2`
   Loads the flat kernel image, enables A20, builds a minimal 64-bit GDT, constructs identity-mapped paging, enables long mode, and jumps into the kernel.

3. `kernel`
   Initializes early console, interrupts, timer, keyboard, secure paging, logger, integrity baseline, and the shell.

## Kernel layers

### Core

- entry point
- boot banner
- init order
- panic path

### Interrupt subsystem

- IDT setup
- exception gates
- IRQ gates
- page-fault and general-fault capture

### Memory subsystem

- first-stage identity mapping
- second-stage 4 KiB page tables
- code as RX
- data and stacks as RW + NX
- write-protect bit enabled in `CR0`

### Security subsystem

- checksum baseline over kernel text
- stack-range enforcement
- page-fault telemetry
- shell input boundary monitoring
- anomaly counters

### Shell and sandbox

- bounded command line editing
- structured inspection commands
- safe vulnerability demonstration that never diverts control flow

## Security engine placement

The defensive engine lives at the boundary between kernel observability and policy:

- interrupt handlers generate raw security signals
- memory manager enforces protection policy
- logger stores structured events
- shell provides operator visibility

This makes the system useful both as an OS project and as a systems-security portfolio artifact.
