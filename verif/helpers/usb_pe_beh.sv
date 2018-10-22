//==============================================================================
// USB 2.0 FS Protocol Engine behavioral model
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_utmi_pkg::*;

module usb_pe_beh (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset

    usb_utmi_if.pe utmi         // UTMI
);

//-----------------------------------------------------------------------------
// Parameters and defines
//-----------------------------------------------------------------------------
localparam USB_RAW_PACKET_BYTES = 1024;

//-----------------------------------------------------------------------------
// Connections and init
//-----------------------------------------------------------------------------
// system bus
logic             suspend_m;    // Places the Macrocell in a suspend mode
utmi_op_mode_t    op_mode;      // Operational modes control
bus8_t            data_in;
logic             tx_valid;

initial
begin
    utmi.suspend_m = '0;
    utmi.op_mode   = UTMI_OM_NORMAL;
    utmi.data_in   = '0;
    utmi.tx_valid  = '0;
end

//-----------------------------------------------------------------------------
// UTMI line control tasks
//-----------------------------------------------------------------------------
task send_data(
    input bit [USB_RAW_PACKET_BYTES-1:0][7:0] data,
    input int len
);
begin
    @(posedge clk);
    for (int i = 0; i < len; i++) begin
        utmi.data_in  = data[i];
        utmi.tx_valid = 1'b1;
        @(posedge clk);
        while(!utmi.tx_ready)
            @(posedge clk);
    end
    @(posedge clk);
    utmi.tx_valid = 1'b0;
end
endtask : send_data

task receive_data(
    output logic [USB_RAW_PACKET_BYTES-1:0][7:0] data,
    output int len
);
begin
    data = 0;
    len = 0;
    wait(utmi.rx_active);
    while(utmi.rx_active) begin
        @(posedge clk);
        if (utmi.rx_active && utmi.rx_valid) begin
            data[len] = utmi.data_out;
            len++;
        end
        if (utmi.rx_error)
            $display("%0d, W: %m: Warning, rx_error is active!", $time);
    end
end
endtask : receive_data


endmodule : usb_pe_beh
