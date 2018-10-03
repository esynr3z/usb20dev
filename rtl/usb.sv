//==============================================================================
// USB 2.0 FS Device controller top module
//
//------------------------------------------------------------------------------
// 2018, Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb (
    // Reset and clock
    input  logic clk_48m,       // Clock 48 MHz
    input  logic rst,           // Asynchronous reset

    // USB lines from/to frontend
    input  logic usb_dp_rx,     // USB Data+ input
    input  logic usb_dn_rx,     // USB Data- input
    output logic usb_dp_tx,     // USB Data+ output
    output logic usb_dn_tx,     // USB Data- output
    output logic usb_tx_oen     // USB Data output enable    
);

usb_utm usb_utm (
    .clk        ( clk_48m    ),
    .rst        ( rst        ),
    .suspend_m  ( suspend_m  ),
    .op_mode    ( op_mode    ),
    .line_state ( line_state ),
    .usb_dp_rx  ( usb_dp_rx  ),
    .usb_dn_rx  ( usb_dn_rx  ),
    .usb_dp_tx  ( usb_dp_tx  ),
    .usb_dn_tx  ( usb_dn_tx  ),
    .usb_tx_oen ( usb_tx_oen ),
    .data_in    ( data_in    ),
    .tx_valid   ( tx_valid   ),
    .tx_ready   ( tx_ready   ),
    .data_out   ( data_out   ),
    .rx_valid   ( rx_valid   ),
    .rx_active  ( rx_active  ),
    .rx_error   ( rx_error   )
);

endmodule : usb
