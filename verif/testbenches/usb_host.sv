//==============================================================================
// USB 2.0 FS Host side emulation
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================
// USB FS 12.000 Mb/s +-0.25% (+-208ps)
`define USB_PERIOD  83333   // ps
`define USB_JIT     100     // ps   

`define USB_PERIOD_DEL  ((`USB_PERIOD + ($urandom_range(0, `USB_JIT*2) - `USB_JIT))/1000.0)
`define USB_PHASE_DEL   ($urandom_range(0,`USB_JIT*2)/1000.0)

module usb_host (
    // USB lines
    usb_fe_if.phy phy
);

//-----------------------------------------------------------------------------
// Connections
//-----------------------------------------------------------------------------
logic dp_tx, dn_tx;
wire  dp_rx, dn_rx;

assign phy.dp = dp_tx;
assign phy.dn = dn_tx;
assign dn_rx = phy.dp;
assign dn_rx = phy.dn;

initial
begin
    send_raw_j();
end

//-----------------------------------------------------------------------------
// Raw line control tasks
//-----------------------------------------------------------------------------
task send_raw_bit(
    input bit dp,
    input bit dn
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

task send_raw_sync;
begin
    send_raw_k();
    send_raw_j();
    send_raw_k();
    send_raw_j();
    send_raw_k();
    send_raw_j();
    send_raw_k();
    send_raw_k();
end
endtask : send_raw_sync

task send_raw_packet(
    input bit [(1023+3)*8-1:0] bitdata,
    input int bitlen
);
int i;
bit enc_nrzi_bit;
int stuff_bit_cnt;
begin
    enc_nrzi_bit = 0;
    stuff_bit_cnt = 0;

    for (i = 0; i < bitlen; i += 1) begin
        // NRZI encoding
        if (!bitdata[i])
            enc_nrzi_bit = !enc_nrzi_bit;
        send_raw_bit(enc_nrzi_bit, !enc_nrzi_bit);

        // Bit stuffing
        if (bitdata[i])
            stuff_bit_cnt += 1;
        else
            stuff_bit_cnt = 0;

        if (stuff_bit_cnt >= 6) begin
            stuff_bit_cnt = 0;
            enc_nrzi_bit = !enc_nrzi_bit;
            send_raw_bit(enc_nrzi_bit, !enc_nrzi_bit);
        end
    end
end
endtask : send_raw_packet

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

task send_raw_eop;
begin
    send_raw_se0();
    send_raw_se0();
    send_raw_j();
    wait_interpacket_delay();
end
endtask : send_raw_eop

endmodule : usb_host
