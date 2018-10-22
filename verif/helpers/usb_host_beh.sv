//==============================================================================
// USB 2.0 FS Host behavioral model
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_utmi_pkg::*;

module usb_host_beh (
    // USB lines
    usb_fe_if.phy phy
);

//-----------------------------------------------------------------------------
// Parameters and defines
//-----------------------------------------------------------------------------
// USB FS 12.000 Mb/s +-0.25% (+-208ps)
localparam USB_PERIOD = 83333;   // ps
localparam USB_JIT    = 100;     // ps
`define USB_PERIOD_DEL  ((USB_PERIOD + ($urandom_range(0, USB_JIT*2) - USB_JIT))/1000.0)
`define USB_PHASE_DEL   ($urandom_range(0, USB_JIT*2)/1000.0)

localparam USB_RAW_PACKET_BYTES = 1024;
localparam USB_RAW_PACKET_BITS  = USB_RAW_PACKET_BYTES*8;

//-----------------------------------------------------------------------------
// Connections
//-----------------------------------------------------------------------------
logic dp_tx, dn_tx;
wire  dp_rx, dn_rx;

pullup  (phy.dp);
pulldown(phy.dn);

assign phy.dp = dp_tx;
assign phy.dn = dn_tx;
assign dp_rx = phy.dp;
assign dn_rx = phy.dn;

initial
begin
    send_raw_nondrive();
end

//-----------------------------------------------------------------------------
// Raw line control tasks
//-----------------------------------------------------------------------------
task wait_interpacket_delay;
begin
    #`USB_PERIOD_DEL;
    #`USB_PERIOD_DEL;
    #`USB_PERIOD_DEL;
    #`USB_PERIOD_DEL;
    #`USB_PERIOD_DEL;
    #`USB_PERIOD_DEL;
end
endtask : wait_interpacket_delay

task send_raw_bit(
    input logic dp,
    input logic dn
);
bit jit_sel;
begin
    jit_sel = $urandom_range(0,1);

    if (jit_sel) begin
        dp_tx <= dp;
        #`USB_PHASE_DEL dn_tx <= dn;
    end else begin
        dn_tx <= dn;
        #`USB_PHASE_DEL dp_tx <= dp;
    end

    #`USB_PERIOD_DEL;
end
endtask : send_raw_bit

task send_raw_nondrive;
begin
    send_raw_bit(1'bz, 1'bz);
end
endtask : send_raw_nondrive

task send_raw_k;
begin
      send_raw_bit(0, 1);
end
endtask : send_raw_k

task send_raw_j;
begin
      send_raw_bit(1, 0);
end
endtask : send_raw_j

task send_raw_se0;
begin
      send_raw_bit(0, 0);
end
endtask : send_raw_se0

task send_raw_packet(
    input logic [USB_RAW_PACKET_BITS-1:0] data,
    input int len
);
bit enc_nrzi_bit;
int stuff_bit_cnt;
begin
    //Sync
    send_raw_k();
    send_raw_j();
    send_raw_k();
    send_raw_j();
    send_raw_k();
    send_raw_j();
    send_raw_k();
    send_raw_k();

    enc_nrzi_bit = 0;
    stuff_bit_cnt = 1;

    for (int i = 0; i < len*8; i++) begin
        // NRZI encoding
        if (!data[i])
            enc_nrzi_bit = !enc_nrzi_bit;
        send_raw_bit(enc_nrzi_bit, !enc_nrzi_bit);

        // Bit stuffing
        if (data[i])
            stuff_bit_cnt++;
        else
            stuff_bit_cnt = 0;

        if (stuff_bit_cnt >= USB_STUFF_BITS_N) begin
            stuff_bit_cnt = 0;
            enc_nrzi_bit = !enc_nrzi_bit;
            send_raw_bit(enc_nrzi_bit, !enc_nrzi_bit);
        end
    end

    // EOP
    send_raw_se0();
    send_raw_se0();
    send_raw_j();
    wait_interpacket_delay();
end
endtask : send_raw_packet

task receive_raw_packet (
    output logic [USB_RAW_PACKET_BITS-1:0] data,
    output int len
);
utmi_line_state_t [7:0]         line_state_hist;
int                             unstuff_cnt;
int                             bit_cnt;
logic [USB_RAW_PACKET_BITS-1:0] bit_data;
begin
    bit_cnt = 0;
    bit_data = '0;
    line_state_hist = {8{UTMI_LS_DJ}};

    // wait for sync pattern
    while (line_state_hist != USB_SYNC_PATTERN) begin
        line_state_hist = {line_state_hist[6:0], utmi_line_state_t'({dn_rx, dp_rx})};
        #`USB_PERIOD_DEL;
    end

    unstuff_cnt = 1; // SYNC has 1 in the end

    // get data
    while (line_state_hist[2:0] != USB_EOP_PATTERN) begin
        line_state_hist = {line_state_hist[6:0], utmi_line_state_t'({dn_rx, dp_rx})};

        if (line_state_hist[2:0] == USB_EOP_PATTERN) begin
            if (line_state_hist[3] == UTMI_LS_SE0)
                $display("%0d, W: %m: Warning, EOP must have 2 se0 bits!", $time);
            break;
        end
        else if (line_state_hist[0] == UTMI_LS_SE0) begin
            //continue;
        end else if (unstuff_cnt == USB_STUFF_BITS_N) begin
            if (line_state_hist[0] == line_state_hist[1])
                $display("%0d, W: %m: Warning, should be '0' after 6 '1's!", $time);
            unstuff_cnt = 0;
        end else begin // regular data bit
            bit_cnt = bit_cnt + 1;
            // NRZI decoding and bit stuffing control
            if (line_state_hist[0] == line_state_hist[1]) begin
                bit_data = {1'b1, bit_data[USB_RAW_PACKET_BITS-1:1]};
                unstuff_cnt = unstuff_cnt + 1;
            end else begin
                bit_data = {1'b0, bit_data[USB_RAW_PACKET_BITS-1:1]};
                unstuff_cnt = 0;
            end
        end

        #`USB_PERIOD_DEL;
    end

    // shift lsb to the array bottom
    bit_data = bit_data >> (USB_RAW_PACKET_BITS - bit_cnt);

    data = bit_data;
    len  = bit_cnt/8;
    if (bit_cnt%8 != 0)
        $display("%0d, W: %m: Warning, number of bits is not multiple of 8!", $time);

    wait_interpacket_delay();
end
endtask : receive_raw_packet

endmodule : usb_host_beh
