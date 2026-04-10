# Implementation Plan

## Phase 1: Bootable foundation

1. Write `stage1.asm`
2. Write `stage2.asm`
3. Load kernel at a fixed physical address
4. Enter long mode
5. Print a kernel banner

Exit criterion:

- system boots to a visible 64-bit kernel message in QEMU

## Phase 2: Early kernel runtime

1. Add VGA and serial output helpers
2. Add IDT support and default exception handlers
3. Remap PIC and enable PIT
4. Add keyboard input path

Exit criterion:

- timer ticks advance and key input reaches the shell

## Phase 3: Secure memory

1. Replace temporary page tables with 4 KiB mappings
2. Mark kernel text RX
3. Mark data, BSS, stack, VGA, and device pages RW + NX
4. Enable `CR0.WP`
5. Log page faults

Exit criterion:

- memory policy is visible through `memcheck`

## Phase 4: Security engine

1. Add in-memory event logger
2. Record checksum baseline for kernel text
3. Add stack boundary checks
4. Add process and anomaly counters
5. Expose integrity and telemetry through the shell

Exit criterion:

- `integrity` and `procstat` return meaningful data

## Phase 5: Safe vulnerability lab

1. Create a synthetic stack frame buffer
2. Visualize it before mutation
3. Run a deliberately unsafe copy into the synthetic frame
4. Detect the corrupted fake return address
5. Print memory and register traces

Exit criterion:

- `vuln-demo` demonstrates a controlled overflow without altering actual control flow

## Phase 6: True microkernel evolution

1. Split shell into a user task
2. Add a syscall ABI
3. Move logger and security analysis into dedicated service threads
4. Add IPC
5. Add a small filesystem and persistent logs

Exit criterion:

- services communicate via explicit message boundaries rather than direct calls
