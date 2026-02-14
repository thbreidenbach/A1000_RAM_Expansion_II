// a1000_frontram.v
// Robust async SRAM glue for A1000 Front-RAM with XC9572XL (VQ64)
// - CE2 follows /RAS (early enable)
// - Latch COL/BANK/READ/LANES once per RAS on qualified CAS falling edge
// - Create delayed CAS enable window (cas_win) to avoid WE/OE asserting on old address
// - en deasserts immediately when CAS ends (cas_any_n rises) or RAS ends (ras_n rises)

module a1000_frontram (
    input  wire        ras_n,
    input  wire        rrw_n,
    input  wire        casl0_n,
    input  wire        casu0_n,
    input  wire        casl1_n,
    input  wire        casu1_n,
    input  wire [7:0]  dra,

    output wire [16:0] sram_a,
    output wire        ce2,
    output wire        ce1_l_n,
    output wire        ce1_u_n,
    output wire        oe_n,
    output wire        we_n
);

    // Bank CAS groups (active low)
    wire cas0_n    = casl0_n & casu0_n;   // low => bank0 active
    wire cas1_n    = casl1_n & casu1_n;   // low => bank1 active
    wire cas_any_n = cas0_n   & cas1_n;   // low => any CAS active

    // Qualified CAS: only valid while /RAS low (ignore RAS-only refresh/noise)
    wire cas_qual_n = cas_any_n | ras_n;  // low only when (CAS active) AND (RAS active)

    // ---------------- ROW latch ----------------
    reg [7:0] row_lat;
    always @(negedge ras_n)
        row_lat <= dra;

    // ---------------- First CAS per RAS: latch COL/BANK/READ/LANES ----------------
    reg [7:0] col_lat;
    reg       bank_lat;       // 0=bank0, 1=bank1
    reg       read_lat;       // 1=read, 0=write
    reg       ce1_l_lat_n;    // latched lane selects (active low)
    reg       ce1_u_lat_n;
    reg       cas_seen;

    // reset on end of RAS; latch on first qualified CAS falling
    always @(posedge ras_n or negedge cas_qual_n) begin
        if (ras_n) begin
            cas_seen     <= 1'b0;
            read_lat     <= 1'b1;  // safe default: read
            ce1_l_lat_n  <= 1'b1;
            ce1_u_lat_n  <= 1'b1;
        end else if (!cas_seen) begin
            col_lat <= dra;

            // A314-style bank bit: bank1 => 1, bank0 => 0
            // Using cas0_n works well when only one bank group is active.
            bank_lat <= cas0_n;

            // Latch read/write once (filters RRW spikes)
            read_lat <= rrw_n;

            // Latch lane selects once (filters CAS ringing)
            ce1_l_lat_n <= (casl0_n & casl1_n);
            ce1_u_lat_n <= (casu0_n & casu1_n);

            cas_seen <= 1'b1;
        end
    end

    // Address mapping (A314-style): A[15:8]=COL, A[7:0]=ROW, A16=BANK
    assign sram_a = { bank_lat, col_lat, row_lat };

    // CE2 early (classic): asserted for the whole /RAS-low window
    assign ce2 = ~ras_n;

    // ---------------- CAS window FF (XST-friendly) ----------------
    // Set on qualified CAS falling edge, clear on /RAS rising edge.
    reg cas_win;
    always @(posedge ras_n or negedge cas_qual_n) begin
        if (ras_n)
            cas_win <= 1'b0;
        else
            cas_win <= 1'b1;
    end

    // Enable window:
    // - asserts after cas_win propagates (FF tCO delay)
    // - deasserts immediately when CAS ends or RAS ends
    wire en = cas_win & ~ras_n & ~cas_any_n;

    // Lane CE1# (active low), gated by en
    assign ce1_l_n = ce1_l_lat_n | (~en);
    assign ce1_u_n = ce1_u_lat_n | (~en);

    // OE/WE gated by en and *latched* read/write (prevents rrw glitches)
    // read_lat=1 => OE active during en
    // read_lat=0 => WE active during en
    assign oe_n = (~read_lat) | (~en);
    assign we_n = ( read_lat) | (~en);

endmodule
