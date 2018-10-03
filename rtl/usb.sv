//==============================================================================
// USB 2.0 FS Device controller top module
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb (
    // Reset and clock
    input  logic clk_48m,       // Clock 48 MHz
    input  logic rst,           // Asynchronous reset

    // USB frontend control
    usb_fe_if.ctrl fe_ctrl
);

usb_utmi_if utmi();

usb_utm utm (
    .clk        ( clk_48m  ),
    .rst        ( rst      ),
    .fe_ctrl    ( fe_ctrl  ),
    .utmi       ( utmi.utm )
);

endmodule : usb
