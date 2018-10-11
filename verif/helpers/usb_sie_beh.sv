//==============================================================================
// USB 2.0 FS Serial Interface Engine behavioral model
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================


module usb_sie_beh (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset
    
    usb_utmi_if.sie utmi        // UTMI
);

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
    utmi.op_mode   = '0;
    utmi.data_in   = '0;
    utmi.tx_valid  = '0;
end

//-----------------------------------------------------------------------------
// UTMI line control tasks
//-----------------------------------------------------------------------------
task send_data(
    input bit [2047:0][7:0] data,
    input int len
);
int i;
begin
    @(posedge clk);
    for (i = 0; i < len; i += 1) begin
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


endmodule : usb_sie_beh
