//==============================================================================
// USB 2.0 Transceiver Macrocel (UTM) FS Only implementation with 
// 8 bit interface. All references to UTMI specification, version 1.05.
//
// The main differences from the reference are: analog frontend and clock 
// generator are placed outside the usb block.
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_utmi_pkg::*;

module usb_utm (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset

    usb_fe_if.ctrl  fe_ctrl,    // USB frontend control

    usb_utmi_if.utm utmi        // UTMI
);

//-----------------------------------------------------------------------------
// Recovering input line state
//-----------------------------------------------------------------------------
logic [3:0] dpair_dd;

always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        dpair_dd <= '0;
    end else begin
        dpair_dd <= {dpair_dd[1:0], fe_ctrl.dn_rx, fe_ctrl.dp_rx};
    end
end

assign utmi.line_state = dpair_dd[3:0];

//-----------------------------------------------------------------------------
// Temp output control
//-----------------------------------------------------------------------------
assign fe_ctrl.dp_tx  = 1'b0;
assign fe_ctrl.dn_tx  = 1'b0;
assign fe_ctrl.tx_oen = 1'b0;
assign fe_ctrl.pu     = 1'b1;

endmodule : usb_utm
