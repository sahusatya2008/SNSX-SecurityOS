# Security Engine

## Mission

The security engine is a defensive runtime companion for the kernel. It is educational by design but uses real low-level mechanisms wherever possible.

## Components

### Stack Integrity Monitor

- stores stack high/low boundaries
- checks current `RSP` against policy thresholds
- logs boundary and deep-growth anomalies
- validates controlled return-address corruption only inside the sandbox demo

### Memory Protection Analyzer

- enforces code RX and data RW + NX
- records page fault address and error code
- treats write attempts into protected code as integrity events

### Process Behavior Tracker

- records timer ticks, shell iterations, input events, and demo loop counters
- flags suspicious hot-loop behavior in monitored demo contexts

### System Integrity Checker

- computes a baseline checksum over kernel text during boot
- recomputes on demand from the `integrity` shell command
- can halt execution on mismatch in stricter modes

### Input Safety Layer

- bounded shell line buffer
- overflow attempts are ignored and logged
- replaces unsafe copy patterns with explicit-length routines

## Logging format

Every event follows the same operator-facing structure:

`[TIME] [MODULE] [EVENT] [DETAILS]`

Examples:

- `[128] [SEC] [STACK_WARN] [rsp crossed low-water threshold]`
- `[314] [MMU] [PAGE_FAULT] [cr2=0x000000000001F000 err=0x0000000000000007]`
- `[402] [SBOX] [RETADDR_TAINT] [fake return address left kernel text range]`

## Safe vulnerability lab principles

- no shellcode
- no control-flow hijack
- no persistence
- only synthetic, bounded corruption inside a diagnostic buffer
- full before/after visibility for learning
