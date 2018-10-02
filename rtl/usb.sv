//==============================================================================
// USB 2.0 FS Device controller top module
//
//------------------------------------------------------------------------------
// Copyright (c) 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

module usb (
    // Reset and clock
    input logic clk_48m,        // Clock 48 MHz
    input logic rst_n,          // Asynchronous reset active low

    // USB lines from/to frontend
    input  logic usb_dp_rx,     // USB Data+ input
    input  logic usb_dn_rx,     // USB Data- input
    output logic usb_dp_tx,     // USB Data+ output
    output logic usb_dn_tx,     // USB Data- output
    output logic usb_tx_oen     // USB Data output enable    
);

endmodule // usb