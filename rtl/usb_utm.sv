//==============================================================================
// USB 2.0 Transceiver Macrocel (UTM) FS Only implementation with 
// 8 bit interface. All references to UTMI specification, version 1.05.
//
// The main differences from the reference are: analog frontend and clock 
// generator are placed outside the usb block.
//
//------------------------------------------------------------------------------
// 2018, Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_utm_pkg::*;

module usb_utm (
    // System interface
    input  logic            clk,           // Clock
    input  logic            rst,           // Asynchronous reset
    input  logic            suspend_m,     // Places the Macrocell in a suspend mode
    input  utm_op_mode_t    op_mode,       // Operational modes control
    output utm_line_state_t line_state,    // Signal to reflect the current state of the recievers

    // USB interface
    input  logic            usb_dp_rx,     // USB Data+ input
    input  logic            usb_dn_rx,     // USB Data- input
    output logic            usb_dp_tx,     // USB Data+ output
    output logic            usb_dn_tx,     // USB Data- output
    output logic            usb_tx_oen,    // USB Data output enable  

    // Data interface
    input  bus8_t           data_in,       // USB data input bus
    input  logic            tx_valid,      // Transmit data on data_in bus is valid
    output logic            tx_ready,      // UTM ready to load transmit data into holding registers
    output bus8_t           data_out,      // USB data output bus
    output logic            rx_valid,      // data_out bus has valid data
    output logic            rx_active,     // Receive state machine is active
    output logic            rx_error       // Receive error detection
);

endmodule : usb_utm
