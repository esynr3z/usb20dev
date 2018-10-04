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
