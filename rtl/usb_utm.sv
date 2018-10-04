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

endmodule : usb_utm
