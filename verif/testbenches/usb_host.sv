//==============================================================================
// USB 2.0 FS Host side emulation
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

`define USB_PERIOD 83.333ns

module usb_host (
    // USB lines
    usb_fe_if.phy phy
);

//-----------------------------------------------------------------------------
// Connections
//-----------------------------------------------------------------------------
logic dp_tx = 1'bz, dn_tx = 1'bz;
wire  dp_rx, dn_rx;

assign phy.dp = dp_tx;
assign phy.dn = dn_tx;
assign dn_rx = phy.dp;
assign dn_rx = phy.dn;

//-----------------------------------------------------------------------------
// Line control tasks
//-----------------------------------------------------------------------------
task send_raw_bit(
    input logic dp,
    input logic dn
);
begin
        dp_tx <= dp;
        dn_tx <= dn;
        #`USB_PERIOD;
end
endtask : send_raw_bit

task send_k_bit;
begin
      send_raw_bit(0, 1);
end
endtask : send_k_bit

task send_j_bit;
begin
      send_raw_bit(1, 0); 
end
endtask : send_j_bit

task send_se0_bit;
begin
      send_raw_bit(0, 0); 
end
endtask : send_se0_bit

endmodule : usb_host
