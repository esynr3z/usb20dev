//==============================================================================
// SIE receive side:
//   - data recovery from line states
//   - NRZI decoder
//   - bit unstuffer
//   - receive FSM
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb_sie_rx (
    input  logic    clk,       // Clock
    input  logic    rst,       // Asynchronous reset

    // Frontend rx
    input  logic    dn_rx,     // USB Data- input
    input  logic    dp_rx,     // USB Data+ input

    // SIE rx
    input  logic    tx_active, // Transmit state machine is active
    output bus8_t   rx_data,   // USB data output bus
    output logic    rx_valid,  // rx_data bus has valid data
    output logic    rx_active, // Receive state machine is active
    output logic    rx_error,  // Receive error detection
    output logic    bus_reset  // Bus reset active
);

localparam LINE_STATE_HIST_LEN = 3;

//-----------------------------------------------------------------------------
// Line state recovery
//-----------------------------------------------------------------------------
// Double-flop synchronization for input data lines
logic [3:0]       line_pair_ff;
usb_line_state_t line_pair;
usb_line_state_t line_state_curr;
logic             line_trans;
logic             line_idle;
logic             detect_eop;

always_ff @(posedge clk)
begin
    if (rst)
        line_pair_ff <= 4'b0101;
    else
        line_pair_ff <= {line_pair_ff[1:0], dn_rx, dp_rx};
end

assign line_pair = usb_line_state_t'(line_pair_ff[3:2]);

// We dont use true diff pair, so we have to handle data transition moments
// and change line state one clock after transition.
// It is supposed, that transition period is shorter than sample clock period.

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        line_trans <= 1'b0;
    else if ((line_state_curr != line_pair) && !line_trans)
        line_trans <= 1'b1;
    else
        line_trans <= 1'b0;
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        line_state_curr <= USB_LS_J;
    else if (line_trans)
        line_state_curr <= line_pair;
end

// Generate valid signal in the middle of each bit
logic [1:0] line_phase_cnt;
logic       line_state_valid;

always_ff @(posedge clk or posedge rst)
begin
    if (rst || line_trans)
        line_phase_cnt <= '0;
    else
        line_phase_cnt <= line_phase_cnt + 'b1;
end

assign line_state_valid = (line_phase_cnt == 'b1) ? 1'b1 : 1'b0;

// Push line states to the history buffer for NRZI decoding and EOP detection
usb_line_state_t [LINE_STATE_HIST_LEN-1:0] line_state_hist;

always_ff @(posedge clk or posedge rst)
begin
    for (int i = 0; i < LINE_STATE_HIST_LEN; i++) begin
        if (rst)
            line_state_hist[i] <= USB_LS_J;
        else if (line_state_valid && (i == 0)) begin
            line_state_hist[i] <= line_state_curr;
        end else if (line_state_valid) begin
            line_state_hist[i] <= line_state_hist[i-1];
        end
    end
end

assign detect_eop  = (line_state_hist == USB_EOP_PATTERN);

//-----------------------------------------------------------------------------
// NRZI decoder
//-----------------------------------------------------------------------------
logic dec_nrzi_bit;
logic dec_nrzi_valid;

always_comb
begin
    if ((line_state_hist[1] == USB_LS_J) &&
        (line_state_hist[0] == USB_LS_J)) begin
        dec_nrzi_bit   = 1'b1;
        dec_nrzi_valid = line_state_valid;
    end else if ((line_state_hist[1] == USB_LS_J) &&
                 (line_state_hist[0] == USB_LS_K)) begin
        dec_nrzi_bit   = 1'b0;
        dec_nrzi_valid = line_state_valid;
    end else if ((line_state_hist[1] == USB_LS_K) &&
                 (line_state_hist[0] == USB_LS_J)) begin
        dec_nrzi_bit   = 1'b0;
        dec_nrzi_valid = line_state_valid;
    end else if ((line_state_hist[1] == USB_LS_K) &&
                 (line_state_hist[0] == USB_LS_K)) begin
        dec_nrzi_bit   = 1'b1;
        dec_nrzi_valid = line_state_valid;
    end else begin
        dec_nrzi_bit   = 1'b0;
        dec_nrzi_valid = 1'b0;
    end
end

//-----------------------------------------------------------------------------
// Bit unstuffer
//-----------------------------------------------------------------------------
logic [USB_STUFF_BITS_N-1:0] unstuff_shift;
logic                        unstuff_event;
logic                        unstuff_error;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        unstuff_shift <= '0;
    else if (dec_nrzi_valid)
        unstuff_shift <= {unstuff_shift[USB_STUFF_BITS_N-2:0], dec_nrzi_bit};
end

assign unstuff_event = (unstuff_shift == '1);
assign unstuff_error = unstuff_event && (dec_nrzi_bit != 1'b0);

//-----------------------------------------------------------------------------
// Data bitstream control
//-----------------------------------------------------------------------------
logic  data_bit;
logic  data_bit_valid;
bus8_t data_shift;
logic  detect_sync;

assign data_bit = dec_nrzi_bit;
assign data_bit_valid = dec_nrzi_valid && (!unstuff_event || line_idle) && (!tx_active);

always_ff @(posedge clk or posedge rst)
begin
    if (rst || detect_eop)
        data_shift <= '1;
    else if (data_bit_valid)
        data_shift <= {data_bit, data_shift[7:1]};
end

// SYNC and Idle detection
assign detect_sync = (data_shift == USB_SYNC_VAL);

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        line_idle <= 1'b1;
    else if (detect_sync && line_idle)
        line_idle <= 1'b0;
    else if (detect_eop)
        line_idle <= 1'b1;
end

//-----------------------------------------------------------------------------
// Receive state machine
//-----------------------------------------------------------------------------
enum logic [2:0] {
    RX_WAIT_S,
    STRIP_SYNC_S,
    RX_DATA_S,
    STRIP_EOP_S,
    ERROR_S,
    ABORT_S,
    TERMINATE_S,
    XXX_S = 'x
} fsm_state, fsm_next;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        fsm_state <= RX_WAIT_S;
    else
        fsm_state <= fsm_next;
end

always_comb
begin
    fsm_next = XXX_S;
    case (fsm_state)
        RX_WAIT_S : begin
            if (detect_sync && (!tx_active))
                fsm_next = STRIP_SYNC_S;
            else
                fsm_next = RX_WAIT_S;
        end

        STRIP_SYNC_S : begin
            fsm_next = RX_DATA_S;
        end

        RX_DATA_S : begin
            if (unstuff_error)
                fsm_next = ERROR_S;
            else if (detect_eop)
                fsm_next = STRIP_EOP_S;
            else
                fsm_next = RX_DATA_S;
        end

        STRIP_EOP_S : begin
            fsm_next = RX_WAIT_S;
        end

        ERROR_S : begin
            fsm_next = ABORT_S;
        end

        ABORT_S : begin
            if (line_idle)
                fsm_next = TERMINATE_S;
            else
                fsm_next = ABORT_S;
        end

        TERMINATE_S : begin
            fsm_next = RX_WAIT_S;
        end
    endcase
end

logic  [3:0] data_bit_cnt;
bus8_t       data_hold;
logic        data_valid;
logic        data_active;
logic        data_error;

always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        data_bit_cnt <= '0;
        data_hold    <= '0;
        data_valid   <= 1'b0;
        data_active  <= 1'b0;
        data_error   <= 1'b0;
    end else begin
        case (fsm_state)
            RX_WAIT_S : begin
                data_bit_cnt <= '0;
            end

            STRIP_SYNC_S : begin
                data_active <= 1'b1;
            end

            RX_DATA_S : begin
                // count shifted data bits
                if (data_bit_valid) begin
                    if (data_bit_cnt == 'd8)
                        data_bit_cnt <= 'd1;
                    else
                        data_bit_cnt <= data_bit_cnt + 1;
                end
                // hold data when byte accumulated
                if (data_bit_cnt == 'd8) begin
                    data_hold <= data_shift;
                    data_valid <= 1'b1;
                end else
                    data_valid <= 1'b0;
            end

            STRIP_EOP_S : begin
                data_valid  = 'b0;
                data_active = 'b0;
            end

            ERROR_S : begin
                data_error  = 1'b1;
            end

            ABORT_S : begin
                data_valid  = 1'b0;
                data_error  = 1'b0;
            end

            TERMINATE_S : begin
                data_active = 1'b0;
            end
        endcase
    end
end

// Data valid should be a pulse for FS
logic data_valid_ff;
logic data_valid_pulse;

always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        data_valid_ff <= 1'b0;
    end else begin
        data_valid_ff <= data_valid;
    end
end

assign data_valid_pulse = data_valid && (!data_valid_ff);

//-----------------------------------------------------------------------------
// Outputs registering stage
//-----------------------------------------------------------------------------
always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        rx_data    <= '0;
        rx_valid   <= 1'b0;
        rx_active  <= 1'b0;
        rx_error   <= 1'b0;
        bus_reset  <= 1'b0;
    end else begin
        rx_data    <= data_hold;
        rx_valid   <= data_valid_pulse;
        rx_active  <= data_active;
        rx_error   <= data_error;
        // FIXME: line reset detection logic need to be implemented
        bus_reset  <= 1'b0;
    end
end

endmodule : usb_sie_rx
