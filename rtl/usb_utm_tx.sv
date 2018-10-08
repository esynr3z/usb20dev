//==============================================================================
// UTM transmit side:
//   - NRZI encoder
//   - bit stuffer
//   - data to line states transform
//   - transmit FSM
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_utmi_pkg::*;

module usb_utm_tx (
    input  logic          clk,          // Clock
    input  logic          rst,          // Asynchronous reset

    // UTMI rx
    input  logic          suspend_m,    // Places the Macrocell in a suspend mode
    input  utmi_op_mode_t op_mode,      // Operational modes control

    input  bus8_t         data_in,      // USB data input bus
    input  logic          tx_valid,     // Transmit data on data_in bus is valid
    output logic          tx_ready      // UTM ready to load transmit data into holding registers
);

assign tx_ready = 1'b0;

endmodule : usb_utm_tx
