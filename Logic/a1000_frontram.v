// a1000_frontram.v
// 256 KiB A1000 Front-RAM (ChipRAM) Expansion Glue Logic for XC9572XL (VQ64)
// Target memory: 2x 128Kx8 asynchronous SRAM with CE1# (active low), CE2 (active high),
// OE# (active low), WE# (active low) (e.g. CY62128ELL/CY7C109D/CY7C1009D family)
//
// Core idea:
// - DRA[7:0] is a multiplexed address bus (DRAM-style).
// - Latch ROW[7:0] at the falling edge of /RAS.
// - Latch COL[7:0] and BANK (A16) at the falling edge of "any CAS".
// - Present SRAM address as: A[7:0]=COL, A[15:8]=ROW, A16=BANK.
// - Byte lane selection is performed via separate CE1# for low- and high-byte SRAM.
// - OE#/WE# are gated by CAS to minimize bus-driving window and prevent spurious writes.
//
// Notes:
// - /RRW is assumed to behave like DRAM /WE: low = write, high = read.
// - BANK is derived from CAS1 group: BANK=1 if either /CASL1 or /CASU1 is asserted.
//
module a1000_frontram (
    input  wire        ras_n,      // /RAS from Agnus (active low)
    input  wire        rrw_n,      // /RRW (active low write enable)
    input  wire        casl0_n,     // /CASL0 (bank0, low byte)
    input  wire        casu0_n,     // /CASU0 (bank0, high byte)
    input  wire        casl1_n,     // /CASL1 (bank1, low byte)
    input  wire        casu1_n,     // /CASU1 (bank1, high byte)
    input  wire [7:0]  dra,        // multiplexed address lines DRA[7:0]

    output wire [16:0] sram_a,     // to both SRAMs A0..A16
    output wire        ce2,        // to both SRAMs CE2 (active high)
    output wire        ce1_l_n,    // to low-byte SRAM CE1# (active low)
    output wire        ce1_u_n,    // to high-byte SRAM CE1# (active low)
    output wire        oe_n,       // to both SRAMs OE# (active low)
    output wire        we_n        // to both SRAMs WE# (active low)
);

    // Any CAS active? (low when any CAS is asserted low)
    wire cas_any_n = casl0_n & casu0_n & casl1_n & casu1_n;

    // Latch row on /RAS falling edge.
    reg [7:0] row_lat;
    always @(negedge ras_n) begin
        row_lat <= dra;
    end

    // Latch column (and bank) on CAS falling edge of the cycle.
    reg [7:0] col_lat;
    reg       bank_lat;
    wire      bank_next = ~(casl1_n & casu1_n); // 1 if any CAS1 asserted (byte or word)

    always @(negedge cas_any_n) begin
        col_lat  <= dra;
        bank_lat <= bank_next;
    end

    // SRAM address mapping: A[7:0]=COL, A[15:8]=ROW, A16=BANK
    assign sram_a = { bank_lat, row_lat, col_lat };

    // Chip enables:
    // CE2 (active high): asserted during /RAS low.
    // CE1# per lane: asserted low when the corresponding CAS (bank0 or bank1) is low.
    assign ce2     = ~ras_n;
    assign ce1_l_n = casl0_n & casl1_n;
    assign ce1_u_n = casu0_n & casu1_n;

    // Control signals:
    // - WE# low only for write cycles, and only while CAS is active (low).
    // - OE# low only for read cycles, and only while CAS is active (low).
    //
    // If you prefer "DRAM-like OE always enabled", you may tie OE# to GND externally
    // and remove oe_n from the design.
    assign we_n = rrw_n | cas_any_n;        // write: rrw_n=0 AND cas_any_n=0 => WE#=0
    assign oe_n = (~rrw_n) | cas_any_n;     // read : rrw_n=1 AND cas_any_n=0 => OE#=0

endmodule
