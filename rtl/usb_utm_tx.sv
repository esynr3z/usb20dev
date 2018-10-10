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

    // Frontend tx
    output  logic         dp_tx,        // USB Data+ output
    output  logic         dn_tx,        // USB Data- output
    output  logic         tx_oen,       // USB Data output enable

    // UTMI tx
    input  logic          suspend_m,    // Places the Macrocell in a suspend mode
    input  utmi_op_mode_t op_mode,      // Operational modes control
    input  bus8_t         data_in,      // USB data input bus
    input  logic          tx_valid,     // Transmit data on data_in bus is valid
    output logic          tx_ready      // UTM ready to load transmit data into holding registers
);

//-----------------------------------------------------------------------------
// Transmit state machine
//-----------------------------------------------------------------------------
logic data_hold_full;
logic data_hold_empty;
logic done_eop;

enum logic [2:0] {
    TX_WAIT_S,
    SEND_SYNC_S,
    TX_DATA_LOAD_S,
    TX_DATA_WAIT_S,
    SEND_EOP_S,
    XXX_S = 'x
} fsm_state, fsm_next;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        fsm_state <= TX_WAIT_S;
    else
        fsm_state <= fsm_next;
end

always_comb
begin
    fsm_next = XXX_S;
    case (fsm_state)
        TX_WAIT_S : begin
            if (tx_valid)
                fsm_next = SEND_SYNC_S;
            else
                fsm_next = TX_WAIT_S;
        end

        SEND_SYNC_S : begin
            fsm_next = TX_DATA_LOAD_S;
        end

        TX_DATA_LOAD_S : begin
            if (!tx_valid)
                fsm_next = SEND_EOP_S;
            else if (data_hold_full)
                fsm_next = TX_DATA_WAIT_S;
            else
                fsm_next = TX_DATA_LOAD_S;
        end

        TX_DATA_WAIT_S : begin
            if (data_hold_empty)
                fsm_next = TX_DATA_LOAD_S;
            else
                fsm_next = TX_DATA_WAIT_S;
        end

        SEND_EOP_S : begin
            if (done_eop)
                fsm_next = TX_WAIT_S;
            else
                fsm_next = SEND_EOP_S;
        end
    endcase
end
/*
always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin

    end else begin
        case (fsm_state)
            TX_WAIT_S : begin

            end

            SEND_SYNC_S : begin

            end

            TX_DATA_LOAD_S : begin

            end

            TX_DATA_WAIT_S : begin

            end

            SEND_EOP_S : begin

            end
            end
        endcase
    end
end
*/
//-----------------------------------------------------------------------------
// Outputs registering stage
//-----------------------------------------------------------------------------
always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        tx_ready <= 1'b0;
        dp_tx    <= 1'b0;
        dn_tx    <= 1'b0;
        tx_oen   <= 1'b0;
    end else begin
        tx_ready <= 1'b0;
        dp_tx    <= 1'b0;
        dn_tx    <= 1'b0;
        tx_oen   <= 1'b0;        
    end
end

endmodule : usb_utm_tx
