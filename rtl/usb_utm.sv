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

// TODO: add logic for handling suspend_m and op_mode signals

//-----------------------------------------------------------------------------
// UTM receive side
//-----------------------------------------------------------------------------
usb_utm_rx rx (
    .clk        (clk),              //  i: Clock
    .rst        (rst),              //  i: Asynchronous reset

    .dn_rx      (fe_ctrl.dn_rx),    //  i: USB Data- input
    .dp_rx      (fe_ctrl.dp_rx),    //  i: USB Data+ input

    .tx_active  (fe_ctrl.tx_oen),   //  i: Transmit state machine is active
    .suspend_m  (utmi.suspend_m),   //  i: Places the Macrocell in a suspend mode
    .line_state (utmi.line_state),  //  o: Signal to reflect the current state of the recievers
    .data_out   (utmi.data_out),    //  o: USB data output bus
    .rx_valid   (utmi.rx_valid),    //  o: data_out bus has valid data
    .rx_active  (utmi.rx_active),   //  o: Receive state machine is active
    .rx_error   (utmi.rx_error)     //  o: Receive error detection
);

//-----------------------------------------------------------------------------
// UTM transmit side
//-----------------------------------------------------------------------------
usb_utm_tx tx (
    .clk        (clk),              //  i: Clock
    .rst        (rst),              //  i: Asynchronous reset

    .dp_tx      (fe_ctrl.dp_tx),    //  o: USB Data+ output
    .dn_tx      (fe_ctrl.dn_tx),    //  o: USB Data- output
    .tx_oen     (fe_ctrl.tx_oen),   //  o: USB Data output enable

    .suspend_m  (utmi.suspend_m),   //  i: Places the Macrocell in a suspend mode
    .op_mode    (utmi.op_mode),     //  i: Operational modes control
    .data_in    (utmi.data_in),     //  i: USB data input bus
    .tx_valid   (utmi.tx_valid),    //  i: Transmit data on data_in bus is valid
    .tx_ready   (utmi.tx_ready)     //  o: UTM ready to load transmit data into holding registers
);

// FIXME: fix pullup control
assign fe_ctrl.pu = 1'b1;

endmodule : usb_utm
