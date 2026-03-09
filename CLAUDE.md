# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Verilog HDL project implementing a complete 8-bit processor system with VGA display output, intended for FPGA synthesis (Xilinx Vivado toolchain). The top-level module is `Complete_System_Top`.

## Simulation & Synthesis

There are no Makefiles or scripts — simulation and synthesis are performed through the Xilinx Vivado IDE:
- Add all `.v` files and `Complete_Demo_ROM.txt` to the Vivado project.
- `Complete_Demo_ROM.txt` must be in the simulation/synthesis working directory so `$readmemh` can load it into ROM.
- For behavioural simulation, create a testbench instantiating `Complete_System_Top` and drive `CLK`, `RESET`.

## Architecture

### Bus System
All peripherals share an 8-bit tri-state bus (`BUS_DATA`, `BUS_ADDR`, `BUS_WE`). Each peripheral drives `BUS_DATA = 8'hZZ` when not selected. ROM is point-to-point with the processor (not on the shared bus).

Address map:
| Range | Peripheral |
|-------|-----------|
| `0x00`–`0x7F` | RAM (128 bytes, bit 7 = 0 selects RAM) |
| `0xB0`–`0xB4` | VGA Peripheral registers |

### Processor (`Processor.v`)
4-state FSM: `FETCH → DECODE → EXECUTE → MEM_WAIT`.

- Two general-purpose registers: **A** and **B**.
- One context register for storing the return address on interrupt.
- Instructions are 8-bit: lower nibble = **Opcode**, upper nibble = **ALU_Op** (used only for opcodes `4`/`5`).
- All instructions that reference memory use the *next ROM byte* as the operand (address or immediate value), so most instructions occupy 2 bytes.
- Interrupt check happens in FETCH; timer interrupt (INTERRUPT[1]) saves PC → Context, jumps to handler at `0x40`.

Opcode table:

| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| `0` | READ A | Read RAM/peripheral at next-byte address into A |
| `1` | READ B | Read RAM/peripheral at next-byte address into B |
| `2` | WRITE A | Write A to RAM/peripheral address in next byte |
| `3` | WRITE B | Write B to RAM/peripheral address in next byte |
| `4` | ALU→A | Perform ALU op (upper nibble) on A,B; result → A |
| `5` | ALU→B | Perform ALU op (upper nibble) on A,B; result → B |
| `6` | BEQ | If A==B, jump to address in next byte; else skip |
| `7` | GOTO | Unconditional jump to address in next byte |
| `8` | LI A | Load immediate next byte → A |
| `9` | LI B | Load immediate next byte → B |
| `A` | RTI | Return from interrupt (restore PC from Context) |

### ALU (`ALU.v`)
Registered (output latches on rising clock edge). Op codes are the upper nibble of the instruction word:

| Code | Operation |
|------|-----------|
| `0` | A + B |
| `1` | A − B |
| `2` | A × B |
| `3` | A << 1 |
| `4` | A >> 1 |
| `5` | A + 1 |
| `6` | B + 1 |
| `7` | A − 1 |
| `8` | B − 1 |
| `9` | A == B (0 or 1) |
| `A` | A > B (0 or 1) |
| `B` | A < B (0 or 1) |

Because the ALU is clocked, its result is available one cycle after the EXECUTE state sets inputs — this aligns with the processor's pipeline: ALU ops (opcodes 4/5) go directly back to FETCH without a MEM_WAIT.

### ROM (`ROM.v`)
256-byte program memory loaded at initialisation from `Complete_Demo_ROM.txt` (hex, one byte per line via `$readmemh`). The processor's PC directly indexes this ROM.

### RAM (`RAM.v`)
128-byte data memory (`0x00`–`0x7F`). Pre-initialised with numeric constants and a colour table:
- `0x06`=0, `0x07`=1, `0x08`=8, `0x09`=160, `0x0A`=120, `0x0E`=3
- `0x70`–`0x75`: colour table entries (8-bit RGB332 colours)

### Timer (`Timer.v`)
Counts to 100,000,000 then raises `INTERRUPT_RAISE[1]` (1-second period at 100 MHz). Cleared on `BUS_INTERRUPT_ACK[1]`.

### VGA Subsystem
`VGA_Peripheral` → `Frame_Buffer` + `VGA_Sig_Gen`.

**VGA bus registers (write-only):**
| Address | Register |
|---------|----------|
| `0xB0` | Frame buffer address [7:0] |
| `0xB1` | Frame buffer address [14:8] (7 bits) |
| `0xB2` | Pixel value [0] + write strobe |
| `0xB3` | Foreground colour (8-bit RGB332) |
| `0xB4` | Background colour (8-bit RGB332) |

**Frame buffer:** Dual-port 1-bit RAM, 32768 entries (256 × 128 pixels). Port A = processor write, Port B = VGA read.

**VGA signal generator:** 640×480 @ 60 Hz. The system clock is divided by 4 (25 MHz pixel clock). Each pixel maps to a 4×4 block, giving an effective resolution of **160×120** addressable cells. Frame buffer address = `{cell_y[6:0], cell_x[7:0]}`.

**Colour encoding:** 8-bit RGB332 — bits [7:5] = R, [4:2] = G, [1:0] = B.

> **Known issue:** `VGA_Sig_Gen` currently assigns `VGA_COLOUR = visible ? BG : 8'hFF` — the `VGA_DATA` (frame buffer pixel) is not used to select between FG and BG. The FG/BG switching logic still needs to be wired up.
