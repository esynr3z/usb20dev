//==============================================================================
//  SIE interface signals
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

interface usb_sie_if ();

logic             reset;        // USB line reset active

bus8_t            tx_data;      // USB data to transmit
logic             tx_valid;     // Data on tx_data bus is valid
logic             tx_ready;     // SIE ready to load transmit data into holding registers
logic             tx_active;    // Transmit state machine is active (from SYNC sending start to EOP sending end)

bus8_t            rx_data;      // Received USB data
logic             rx_valid;     // rx_data bus has valid data
logic             rx_active;    // Receive state machine is active (from detecting SYNC to detecting EOP)
logic             rx_error;     // Receive error detection (bitstuff error)

// Serial Interface Engine side
modport sie (
    output reset,

    input  tx_data,
    input  tx_valid,
    output tx_ready,
    output tx_active,

    output rx_data,
    output rx_valid,
    output rx_active,
    output rx_error
);

// Protocol Engine side
modport pe (
    input  reset,

    output tx_data,
    output tx_valid,
    input  tx_ready,
    input  tx_active,

    input  rx_data,
    input  rx_valid,
    input  rx_active,
    input  rx_error
);

endinterface : usb_sie_if
