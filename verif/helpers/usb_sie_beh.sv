//==============================================================================
// USB 2.0 FS Serial Interface Engine behavioral model
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================


module usb_sie_beh (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset
    
    usb_utmi_if.sie utmi        // UTMI
);

//-----------------------------------------------------------------------------
// Connections
//-----------------------------------------------------------------------------
/*logic dp_tx, dn_tx;
wire  dp_rx, dn_rx;

assign phy.dp = dp_tx;
assign phy.dn = dn_tx;
assign dn_rx = phy.dp;
assign dn_rx = phy.dn;

initial
begin
    send_raw_j();
end
*/
//-----------------------------------------------------------------------------
// UTMI line control tasks
//-----------------------------------------------------------------------------



endmodule : usb_sie_beh
