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
// UTM receive side
//-----------------------------------------------------------------------------
usb_utm_rx rx (
    .clk        (clk),
    .rst        (rst),
    .suspend_m  (utmi.suspend_m),
    .op_mode    (utmi.op_mode),
    .line_state (utmi.line_state),
    .data_out   (utmi.data_out),
    .rx_valid   (utmi.rx_valid),
    .rx_active  (utmi.rx_active),
    .rx_error   (utmi.rx_error)
);

//-----------------------------------------------------------------------------
// UTM transmit side
//-----------------------------------------------------------------------------
usb_utm_tx tx (
    .clk        (clk),
    .rst        (rst),
    .suspend_m  (utmi.suspend_m),
    .op_mode    (utmi.op_mode),
    .data_in    (utmi.data_in),
    .tx_valid   (utmi.tx_valid),
    .tx_ready   (utmi.tx_ready)
);


//-----------------------------------------------------------------------------
// Temp output control
//-----------------------------------------------------------------------------
assign fe_ctrl.dp_tx  = 1'b0;
assign fe_ctrl.dn_tx  = 1'b0;
assign fe_ctrl.tx_oen = 1'b0;
assign fe_ctrl.pu     = 1'b1;

endmodule : usb_utm
