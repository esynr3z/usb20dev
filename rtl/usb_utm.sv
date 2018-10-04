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

//-----------------------------------------------------------------------------
// Recover input line state
//-----------------------------------------------------------------------------
// Double-flop sync input data lines
logic [3:0]       dpair_dd;
utmi_line_state_t dpair;

always_ff @(posedge clk)
begin
    if (rst) begin
        dpair_dd <= '0;
    end else begin
        dpair_dd <= {dpair_dd[1:0], fe_ctrl.dn_rx, fe_ctrl.dp_rx};
    end
end

assign dpair = utmi_line_state_t'(dpair_dd[3:2]);

// We dont use true diff pair, so we have to handle data transition moments
// and sample ine data only after transition. 
// It is supposed, that transition period much shorter than sample clock.
logic data_trans;
utmi_line_state_t line_state;

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        data_trans <= 1'b0;
    else if (((utmi.line_state == UTMI_LS_SE0) && (dpair != UTMI_LS_SE0)) ||
             ((utmi.line_state == UTMI_LS_DK)  && (dpair != UTMI_LS_DK))  ||
             ((utmi.line_state == UTMI_LS_DJ)  && (dpair != UTMI_LS_DJ))  ||
             ((utmi.line_state == UTMI_LS_SE1) && (dpair != UTMI_LS_SE1)))
        data_trans <= 1'b1;
    else
        data_trans <= 1'b0;
end

always_ff @(posedge clk or posedge rst)
begin
    if (rst)
        utmi.line_state <= UTMI_LS_SE0;
    else if (data_trans)
        utmi.line_state <= dpair;
end

//-----------------------------------------------------------------------------
// Temp output control
//-----------------------------------------------------------------------------
assign fe_ctrl.dp_tx  = 1'b0;
assign fe_ctrl.dn_tx  = 1'b0;
assign fe_ctrl.tx_oen = 1'b0;
assign fe_ctrl.pu     = 1'b1;

endmodule : usb_utm
