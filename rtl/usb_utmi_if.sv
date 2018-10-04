//==============================================================================
//  UTMI signals
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;
import usb_utmi_pkg::*;

interface usb_utmi_if ();

// system bus
logic             suspend_m;    // Places the Macrocell in a suspend mode
utmi_op_mode_t    op_mode;      // Operational modes control
utmi_line_state_t line_state;   // Signal to reflect the current state of the recievers

// data bus
bus8_t            data_in;      // USB data input bus
logic             tx_valid;     // Transmit data on data_in bus is valid
logic             tx_ready;     // UTM ready to load transmit data into holding registers
bus8_t            data_out;     // USB data output bus
logic             rx_valid;     // data_out bus has valid data
logic             rx_active;    // Receive state machine is active
logic             rx_error;     // Receive error detection

// USB Transceiver Macrocel side
modport utm (
    // system bus
    input  suspend_m,
    input  op_mode,
    output line_state,

    // data bus
    input  data_in,
    input  tx_valid,
    output tx_ready,
    output data_out,
    output rx_valid,
    output rx_active,
    output rx_error
);

// Serial Interface Engine side
modport sie (
    // system bus
    output suspend_m,
    output op_mode,
    input  line_state,

    // data bus
    output data_in,
    output tx_valid,
    input  tx_ready,
    input  data_out,
    input  rx_valid,
    input  rx_active,
    input  rx_error
);

endinterface : usb_utmi_if
