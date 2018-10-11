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
logic done_eop;
logic send_eop;

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
            if (!data_hold_full)
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

logic        data_bit;
logic  [3:0] data_bit_cnt;
bus8_t       data_hold;
bus8_t       data_shift;
logic        data_shift_en;

always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        data_bit_cnt   <= '0;
        data_hold      <= '0;
        data_hold_full <= 1'b0;
        tx_ready       <= 1'b0;
        send_eop       <= 1'b0;
    end else begin
        case (fsm_state)
            TX_WAIT_S : begin
                data_bit_cnt <= 'd0;
                send_eop     <= 1'b0;
            end

            SEND_SYNC_S : begin
                data_shift <= USB_SYNC_PATTERN;
            end

            TX_DATA_LOAD_S : begin
                if (tx_valid) begin
                    data_hold <= data_in;
                    data_hold_full <= 1'b1;
                    tx_ready <= 1'b1;
                end
                else
                    send_eop <= 1'b1;
            end

            TX_DATA_WAIT_S : begin
                tx_ready <= 1'b0;

                if  (data_shift_en) begin
                    data_shift <= data_shift >> 1;

                    if (data_bit_cnt == 'd8)
                        data_bit_cnt <= 'd0;
                    else
                        data_bit_cnt <= data_bit_cnt + 1;
                end

                if (data_bit_cnt == 'd8) begin
                    data_shift <= data_hold;
                    data_hold_full <= 1'b0;
                end
            end

            SEND_EOP_S : begin
                tx_ready <= 1'b0;
            end
        endcase
    end
end

assign data_bit = data_shift[0];

//-----------------------------------------------------------------------------
// Outputs registering stage
//-----------------------------------------------------------------------------
always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        dp_tx    <= 1'b0;
        dn_tx    <= 1'b0;
        tx_oen   <= 1'b0;
    end else begin
        dp_tx    <= 1'b0;
        dn_tx    <= 1'b0;
        tx_oen   <= 1'b0;        
    end
end

endmodule : usb_utm_tx
