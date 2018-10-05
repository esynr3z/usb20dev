//==============================================================================
// USB 2.0 Transceiver Macrocel (UTM) FS Only implementation with 
// 8 bit interface. All references to UTMI specification, version 1.05.
//
// The main differences from the reference are: analog frontend and clock 
// generator are placed outside the usb block.
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_utmi_pkg::*;

module usb_utm (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset

    usb_fe_if.ctrl  fe_ctrl,    // USB frontend control

    usb_utmi_if.utm utmi        // UTMI
);

localparam LINE_STATE_HIST_LEN = 8;
localparam STUFF_BITS_N = 6;

int i;

//-----------------------------------------------------------------------------
// Line state recovery
//-----------------------------------------------------------------------------
// Double-flop synchronization for input data lines
logic [3:0]       dpair_dd;
utmi_line_state_t dpair;

always_ff @(posedge clk)
begin
    dpair_dd <= {dpair_dd[1:0], fe_ctrl.dn_rx, fe_ctrl.dp_rx};
end

assign dpair = utmi_line_state_t'(dpair_dd[3:2]);

// We dont use true diff pair, so we have to handle data transition moments
// and change line state one clock after transition.
// It is supposed, that transition period is shorter than sample clock period.
logic line_trans;
utmi_line_state_t line_state;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        line_trans <= 1'b0;
    else if ((utmi.line_state != dpair) && !line_trans)
        line_trans <= 1'b1;
    else
        line_trans <= 1'b0;
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        utmi.line_state <= UTMI_LS_DJ;
    else if (line_trans)
        utmi.line_state <= dpair;
end

// Generate valid signal in the middle of each bit
logic [1:0] line_phase_cnt;
logic line_state_valid;

always_ff @(posedge clk or posedge rst) 
begin
    if (rst || line_trans)
        line_phase_cnt <= '0;
    else
        line_phase_cnt <= line_phase_cnt + 'b1;
end

assign line_state_valid = (line_phase_cnt == 'b1) ? 1'b1 : 1'b0;


// Push line states to the history buffer for NRZI decoding, and SYNC, EOP detection
utmi_line_state_t line_state_hist [LINE_STATE_HIST_LEN-1:0];

always_ff @(posedge clk or posedge rst)
begin
    for (i = 0; i < LINE_STATE_HIST_LEN; i++) begin
        if (rst)
            line_state_hist[i] <= UTMI_LS_DJ;
        else if (line_state_valid && (i == 0)) begin
            line_state_hist[i] <= utmi.line_state;
        end else if (line_state_valid) begin
            line_state_hist[i] <= line_state_hist[i-1];
        end
    end
end

//-----------------------------------------------------------------------------
// NRZI decoder
//-----------------------------------------------------------------------------
logic dec_nrzi_bit;
logic dec_nrzi_valid;

always_comb
begin
    if ((line_state_hist[1] == UTMI_LS_DJ) &&
        (line_state_hist[0] == UTMI_LS_DJ)) begin
        dec_nrzi_bit   = 1'b1;
        dec_nrzi_valid = line_state_valid;
    end else if ((line_state_hist[1] == UTMI_LS_DJ) &&
                 (line_state_hist[0] == UTMI_LS_DK)) begin
        dec_nrzi_bit   = 1'b0;
        dec_nrzi_valid = line_state_valid;
    end else if ((line_state_hist[1] == UTMI_LS_DK) &&
                 (line_state_hist[0] == UTMI_LS_DJ) )begin
        dec_nrzi_bit   = 1'b0;
        dec_nrzi_valid = line_state_valid;
    end else if ((line_state_hist[1] == UTMI_LS_DK) &&
                 (line_state_hist[0] == UTMI_LS_DK)) begin
        dec_nrzi_bit   = 1'b1;
        dec_nrzi_valid = line_state_valid;
    end else begin
        dec_nrzi_bit = 1'b0;
        dec_nrzi_valid = 1'b0;
    end
end

//-----------------------------------------------------------------------------
// Bit unstuffer
//-----------------------------------------------------------------------------
logic [STUFF_BITS_N-1:0] unstuff_shifter;
logic unstuff_event;
logic unstuff_error;
logic dbit;
logic dbit_valid;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        unstuff_shifter <= '0;
    else if (dec_nrzi_valid)
        unstuff_shifter <= {unstuff_shifter[STUFF_BITS_N-2:0], dec_nrzi_bit};
end

assign unstuff_event = (unstuff_shifter == '1);
assign unstuff_error = unstuff_event && (dec_nrzi_bit != 1'b0);

// Data input serial bitstream
assign dbit = dec_nrzi_bit;
assign dbit_valid = dec_nrzi_valid && (!unstuff_event);

//-----------------------------------------------------------------------------
// Temp output control
//-----------------------------------------------------------------------------
assign fe_ctrl.dp_tx  = 1'b0;
assign fe_ctrl.dn_tx  = 1'b0;
assign fe_ctrl.tx_oen = 1'b0;
assign fe_ctrl.pu     = 1'b1;

endmodule : usb_utm
