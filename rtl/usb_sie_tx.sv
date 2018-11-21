//==============================================================================
// SIE transmit side:
//   - NRZI encoder
//   - bit stuffer
//   - data to line states convert
//   - transmit FSM
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb_sie_tx (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset

    // Frontend tx
    output logic    dp_tx,      // USB Data+ output
    output logic    dn_tx,      // USB Data- output
    output logic    tx_oen,     // USB Data output enable

    // SIE tx
    input  bus8_t   tx_data,    // USB data input bus
    input  logic    tx_valid,   // Transmit data on tx_data bus is valid
    output logic    tx_ready,   // UTM ready to load transmit data into holding registers
    output logic    tx_active   // Transmit state machine is active (from SYNC sending start to EOP sending end)
);

//-----------------------------------------------------------------------------
// Transmit state machine
//-----------------------------------------------------------------------------
logic data_hold_full;
logic data_oen;
logic data_se0;

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
logic        stuff_event;

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
        data_se0        <= 1'b0;
    end else begin
        case (fsm_state)
            TX_WAIT_S : begin
                data_bit_cnt    <= 'd0;
                data_shift_last <= 1'b0;
            end

            SEND_SYNC_S : begin
                data_shift <= USB_SYNC_VAL;
            end

            TX_DATA_LOAD_S : begin
                if (tx_valid) begin
                    data_hold      <= tx_data;
                    data_hold_full <= 1'b1;
                    tx_ready       <= 1'b1;
                end else if (!tx_valid && data_oen) begin
                    data_hold       <= 'd0;
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
                    if (data_se0 && (data_bit_cnt == 'd12))
                        data_hold_full <= 1'b0;
                end else if (data_bit_cnt == 'd8) begin
                    data_shift     <= data_hold;
                    data_hold_full <= 1'b0;
                    if (!data_shift_last)
                        data_bit_cnt   <= 'd0;
                end

                // data output enable should be active till last se0 of eop have been transmitted
                if (data_bit_strobe)
                    data_oen <= (data_se0 && (data_bit_cnt == 'd12)) ? 1'b0 : 1'b1;

                // signalling that last bit of last byte transmitted and next will be se0 of eop
                if ((data_bit_cnt == 'd10) && data_shift_last && (!stuff_event)) begin
                    data_se0 <= 1'b1;
                end else if (data_bit_strobe && data_se0 && (data_bit_cnt == 'd12)) begin
                    data_se0 <= 1'b0;
                end
            end
        endcase
    end
end

logic       data_bit;
logic [1:0] data_bit_phase_cnt;
logic       data_bit_valid;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        data_bit_phase_cnt <= '1;
    else if (!data_oen)
        data_bit_phase_cnt <= '1;
    else
        data_bit_phase_cnt <= data_bit_phase_cnt + 'b1;
end

assign data_bit_valid = (data_bit_phase_cnt == '1);

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        data_bit <= 1'b0;
    else if (!data_oen)
        data_bit <= 1'b0;
    else if (data_bit_strobe)
        data_bit <= data_shift[0];
end

assign data_bit_strobe = data_bit_valid && (!stuff_event);

//-----------------------------------------------------------------------------
// Bit stuffer
//-----------------------------------------------------------------------------
logic [USB_STUFF_BITS_N-1:0] stuff_shift;
logic                        stuff_bit;
logic                        stuff_bit_valid;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        stuff_shift <= '0;
    else if (data_bit_valid)
        stuff_shift <= {stuff_shift[USB_STUFF_BITS_N-2:0], stuff_event? 1'b0 : data_bit};
end

assign stuff_event     = (stuff_shift == '1);

always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        stuff_bit       <= 1'b0;
        stuff_bit_valid <= 1'b0;
    end else if (!data_oen) begin
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
    if (rst)
        enc_nrzi_bit <= 1'b1;
    else if (!data_oen)
        enc_nrzi_bit <= 1'b1;
    else if (stuff_bit_valid && (stuff_bit == 1'b0))
        enc_nrzi_bit <= ~enc_nrzi_bit;
end

//-----------------------------------------------------------------------------
// Data to line states converter
//-----------------------------------------------------------------------------
always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        {dn_tx, dp_tx} <= USB_LS_J;
    else if (!data_oen)
        {dn_tx, dp_tx} <= USB_LS_J;
    else if (stuff_bit_valid && data_se0)
        {dn_tx, dp_tx} <= USB_LS_SE0;
    else if (stuff_bit_valid)
        {dn_tx, dp_tx} <= {!enc_nrzi_bit, enc_nrzi_bit};
end

// Output enable expander - to drive J one bit time after EOP transmitted
logic [3:0] data_oen_ff;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        data_oen_ff <= '0;
    else
        data_oen_ff <= {data_oen_ff[2:0], data_oen};
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        tx_oen <= 1'b0;
    else
        tx_oen <= |data_oen_ff;
end

assign tx_active = tx_oen;

endmodule : usb_sie_tx
