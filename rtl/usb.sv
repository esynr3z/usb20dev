//==============================================================================
// USB 2.0 FS Device controller top module
//
// References:
//   - Universal Serial Bus Specification Revision 2.0
//   - UTMI specification, version 1.05.
//   - USB 101: An Introduction to Universal Serial Bus 2.0 (AN57294)
//   - USB in a Nutshell
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb (
    input  logic clk_48m,       // Clock 48 MHz
    input  logic rst,           // Asynchronous reset

    usb_fe_if.ctrl fe_ctrl      // USB frontend control
);

usb_utmi_if utmi();

usb_utm utm(
    .clk     (clk_48m), //  i: Clock
    .rst     (rst),     //  i: Asynchronous reset
    .fe_ctrl (fe_ctrl), // if: USB frontend control
    .utmi    (utmi.utm) // if: UTMI
);

endmodule : usb
