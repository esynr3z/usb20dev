//==============================================================================
// USB CRC5 calculation and checking. Parallel load with serializer inside.
//
// Polynomial:
//   G(X) = X^5 + X^2 + 1
// Bit representation:
//   00101
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb_crc5(
    input  logic       clk,    // Clock
    input  logic       rst,    // Asynchronous reset

    input  bus8_t      data,   // Input data
    input  logic       wr,     // Data write strobe
    input  logic       clear,  // Init CRC with default value
    output logic       busy,   // CRC is being calculated
    output logic [4:0] crc     // CRC data
);

//-----------------------------------------------------------------------------
// Data serializer
//-----------------------------------------------------------------------------
bus8_t      dbyte;
logic       dbit;
logic [2:0] dbit_cnt;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        busy  <= 1'b0;
    else if (wr)
        busy  <= 1'b1;
    else if (dbit_cnt == '1)
        busy  <= 1'b0;
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        dbyte <= 'h0;
    else if (wr)
        dbyte <= data;
    else if (busy)
        dbyte <= {1'b0, dbyte[7:1]};
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        dbit_cnt <= '0;
    else if (busy)
        dbit_cnt <= dbit_cnt + 1;
    else
        dbit_cnt <= '0;
end

assign dbit = dbyte[0];

//-----------------------------------------------------------------------------
// CRC5 calculation and checking
//-----------------------------------------------------------------------------
logic       crc_in;
logic [4:0] crc_next;
logic       crc_en;

assign crc_en   = busy;
assign crc_in   = dbit^crc[4];
assign crc_next = {crc[3], crc[2], crc[1]^crc_in, crc[0], crc_in};

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        crc <= '1;
    else if (crc_en)
        crc <= crc_next;
    else if (clear)
        crc <= '1;
end

endmodule : usb_crc5
