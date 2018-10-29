//==============================================================================
// USB Serial Interface Engine with 8 bit interface
//
// Main functions:
//   - Bit stuffing / unstuffing
//   - NRZI encoding / decoding
//   - SYNC and EOP handling
//   - Serial-Parallel / Parallel-Serial Conversion
//
// Based on:
//   - UTMI specification, version 1.05.
//   - Universal Serial Bus Specification Revision 2.0, Ch. 7
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb_sie (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset

    usb_fe_if.ctrl  fe_ctrl,    // USB frontend control

    usb_sie_if.sie  sie_bus     // SIE Data Bus
);

//-----------------------------------------------------------------------------
// Receive side
//-----------------------------------------------------------------------------
usb_sie_rx rx (
    .clk        (clk),                  //  i: Clock
    .rst        (rst),                  //  i: Asynchronous reset

    .dn_rx      (fe_ctrl.dn_rx),        //  i: USB Data- input
    .dp_rx      (fe_ctrl.dp_rx),        //  i: USB Data+ input

    .tx_active  (sie_bus.tx_active),    //  i: Transmit state machine is active
    .rx_data    (sie_bus.rx_data),      //  o: Received USB data
    .rx_valid   (sie_bus.rx_valid),     //  o: rx_data bus has valid data
    .rx_active  (sie_bus.rx_active),    //  o: Receive state machine is active (from detecting SYNC to detecting EOP)
    .rx_error   (sie_bus.rx_error),     //  o: Receive error detection (bitstuff error)
    .bus_reset  (sie_bus.reset)         //  o: Bus reset active
);

//-----------------------------------------------------------------------------
// Transmit side
//-----------------------------------------------------------------------------
usb_sie_tx tx (
    .clk        (clk),                  //  i: Clock
    .rst        (rst),                  //  i: Asynchronous reset

    .dp_tx      (fe_ctrl.dp_tx),        //  o: USB Data+ output
    .dn_tx      (fe_ctrl.dn_tx),        //  o: USB Data- output
    .tx_oen     (fe_ctrl.tx_oen),       //  o: USB Data output enable

    .tx_data    (sie_bus.tx_data),      //  i: USB data to transmit
    .tx_valid   (sie_bus.tx_valid),     //  i: Data on tx_data bus is valid
    .tx_ready   (sie_bus.tx_ready),     //  o: SIE ready to load transmit data into holding registers
    .tx_active  (sie_bus.tx_active)     //  o: Transmit state machine is active (from SYNC sending start to EOP sending end)
);

// FIXME: fix pullup control
assign fe_ctrl.pu = 1'b1;

endmodule : usb_sie
