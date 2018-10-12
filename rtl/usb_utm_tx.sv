//==============================================================================
// UTM transmit side:
//   - NRZI encoder
//   - bit stuffer
//   - data to line states convert
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
logic data_oen;
logic send_eop;

enum logic [2:0] {
    TX_WAIT_S,
    SEND_SYNC_S,
    TX_DATA_LOAD_S,
    TX_DATA_WAIT_S,
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
            if ((!tx_valid) && (!data_oen))
                fsm_next = TX_WAIT_S;
            else
                fsm_next = TX_DATA_WAIT_S;
        end

        TX_DATA_WAIT_S : begin
            if (!data_hold_full)
                fsm_next = TX_DATA_LOAD_S;
            else
                fsm_next = TX_DATA_WAIT_S;
        end
    endcase
end

logic        data_shift_last;
logic  [3:0] data_bit_cnt;
bus8_t       data_hold;
bus8_t       data_shift;
logic        data_bit_strobe;

always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        data_bit_cnt    <= '0;
        data_hold       <= '0;
        data_shift      <= '0;
        data_oen        <= 1'b0;
        data_shift_last <= 1'b0;
        data_hold_full  <= 1'b0;
        tx_ready        <= 1'b0;
        send_eop        <= 1'b0;
    end else begin
        case (fsm_state)
            TX_WAIT_S : begin
                data_bit_cnt    <= 'd0;
                data_shift_last <= 1'b0;
            end

            SEND_SYNC_S : begin
                data_shift <= USB_SYNC_PATTERN;
            end

            TX_DATA_LOAD_S : begin
                if (tx_valid) begin
                    data_hold      <= data_in;
                    data_hold_full <= 1'b1;
                    tx_ready       <= 1'b1;
                end else if (!tx_valid && data_oen) begin
                    data_hold       <= 'd3;
                    data_hold_full  <= 1'b1;
                    tx_ready        <= 1'b0;
                    data_shift_last <= 1'b1;
                end
            end

            TX_DATA_WAIT_S : begin
                tx_ready <= 1'b0;

                // data shifting on every strobe
                if (data_bit_strobe) begin
                    data_shift   <= data_shift >> 1;
                    data_bit_cnt <= data_bit_cnt + 1;
                    if (send_eop && (data_bit_cnt == 'd2))
                        data_hold_full <= 1'b0;
                end else if (data_bit_cnt == 'd8) begin
                    data_shift     <= data_hold;
                    data_bit_cnt   <= 'd0;
                    data_hold_full <= 1'b0;
                end

                // data output enable should be active till last se0 of eop have been transmitted
                if (data_bit_strobe)
                    data_oen <= (send_eop && (data_bit_cnt == 'd2)) ? 1'b0 : 1'b1;

                // signalling that last bit of last byte transmitted and next is se0 of eop
                if ((data_bit_cnt == 'd8) && data_shift_last) begin
                    send_eop <= 1'b1;
                end else if (data_bit_strobe && send_eop && (data_bit_cnt == 'd2)) begin
                    send_eop <= 1'b0;
                end
            end
        endcase
    end
end


//-----------------------------------------------------------------------------
// Bit stuffer
//-----------------------------------------------------------------------------
logic                        data_bit;
logic [1:0]                  data_bit_phase_cnt;
logic                        data_bit_valid;
logic [USB_STUFF_BITS_N-1:0] stuff_shift;
logic                        stuff_event;
logic                        stuff_bit;
logic                        stuff_bit_valid;

always_ff @(posedge clk or posedge rst)
begin
    if (rst || (!data_oen))
        data_bit_phase_cnt <= '1;
    else
        data_bit_phase_cnt <= data_bit_phase_cnt + 'b1;
end

assign data_bit_valid = (data_bit_phase_cnt == '1);

always_ff @(posedge clk or posedge rst)
begin
    if (rst || (!data_oen))
        data_bit <= 1'b0;
    else if (data_bit_strobe)
        data_bit <= data_shift[0];
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        stuff_shift <= '0;
    else if (data_bit_valid)
        stuff_shift <= {stuff_shift[USB_STUFF_BITS_N-2:0], stuff_event? 1'b0 : data_bit};
end

assign stuff_event     = (stuff_shift == '1);
assign data_bit_strobe = data_bit_valid && (!stuff_event);

always_ff @(posedge clk or posedge rst)
begin
    if (rst || (!data_oen)) begin
        stuff_bit       <= 1'b0;
        stuff_bit_valid <= 1'b0;
    end else begin
        stuff_bit       <= stuff_event? 1'b0 : data_bit;
        stuff_bit_valid <= data_bit_valid;
    end
end

//-----------------------------------------------------------------------------
// NRZI encoder
//-----------------------------------------------------------------------------
logic enc_nrzi_bit;

always_ff @(posedge clk or posedge rst)
begin
    if (rst || (!data_oen)) begin
        enc_nrzi_bit <= 1'b1;
    end else if (stuff_bit_valid && (stuff_bit == 1'b0))
        enc_nrzi_bit = ~enc_nrzi_bit;
end

//-----------------------------------------------------------------------------
// Data to line states converter
//-----------------------------------------------------------------------------
always_ff @(posedge clk or posedge rst)
begin
    if (rst || (!data_oen)) begin
        dp_tx    <= 1'b1;
        dn_tx    <= 1'b0;
    end else if (stuff_bit_valid && send_eop) begin
        dp_tx    <= 1'b0;
        dn_tx    <= 1'b0;
    end else if (stuff_bit_valid) begin
        dp_tx    <= enc_nrzi_bit;
        dn_tx    <= !enc_nrzi_bit;
    end
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        tx_oen <= 1'b0;
    else
        tx_oen <= data_oen;
end

endmodule : usb_utm_tx
