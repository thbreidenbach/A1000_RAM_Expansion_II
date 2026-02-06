# A1000 Front-RAM 256 KiB (ChipRAM) Expansion – XC9572XL + 2x 128Kx8 SRAM

This folder contains a complete *starting point* HDL + constraints + command-line build scripts
for an Amiga 1000 front expansion memory board.

## What this implements

- Replaces the classic “A1050 style” 256 KiB ChipRAM board (8x 64K×4 DRAM) with:
  - 2× 128K×8 async SRAM (e.g. CY7C109)
  - 1× XC9572XL CPLD as glue logic for multiplexed DRA[7:0], /RAS, /CASx, /RRW

## Electrical rationale

- XC9572XL I/O are **5 V tolerant inputs**, outputs are **3.3 V** (TTL-high compatible for 5 V SRAM with TTL inputs).
- CY7C109/CY62128ELL is a **5 V** SRAM with TTL-compatible inputs (4.5–5.5 V supply), so **no level shifting** is required for SRAM if you power it at 5 V.

## Connections overview (logic)

### From A1000 front connector to CPLD inputs
- DRA0..7  -> `dra[0..7]`
- /RAS     -> `ras_n`
- /RRW     -> `rrw_n`
- /CASL0,/CASU0,/CASL1,/CASU1 -> `casl0_n`, `casu0_n`, `casl1_n`, `casu1_n`

### From CPLD outputs to SRAMs
Common to both SRAMs:
- `sram_a[16:0]` -> A0..A16
- `ce2`          -> CE2 (active high)
- `oe_n`         -> /OE
- `we_n`         -> /WE

Low-byte SRAM:
- `ce1_l_n`      -> CE1 (active low)

High-byte SRAM:
- `ce1_u_n`      -> CE1 (active low)

### SRAM data bus
- Low-byte SRAM DQ0..7  -> Amiga D0..D7
- High-byte SRAM DQ0..7 -> Amiga D8..D15

## Files
- `a1000_frontram.v`   : Verilog top module
- `a1000_frontram.ucf` : Example pin constraints (adjust to your PCB!)
- `a1000_frontram.prj` : XST project file
- `a1000_frontram.xst` : XST run script
- `build.sh`           : Linux/macOS bash build (ISE tools in PATH)
- `build_windows.cmd`  : Windows build
- `pins.pcf`           : Informational pin map (ISE uses UCF)

## Build (command line)
- Linux/macOS:
  - `chmod +x build.sh`
  - `./build.sh`
- Windows:
  - ensure ISE bin is in PATH
  - `build_windows.cmd`

Outputs:
- `a1000_frontram.jed` : JEDEC programming file
- `a1000_frontram.svf` : SVF JTAG file

