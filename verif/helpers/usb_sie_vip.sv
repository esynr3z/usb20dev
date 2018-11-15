//==============================================================================
// SIE Verification IP
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

import usb_pkg::*;

module usb_sie_vip (
    input  logic    clk,        // Clock
    input  logic    rst,        // Asynchronous reset

    usb_sie_if.pe   sie_bus     // SIE Data Bus
);

//-----------------------------------------------------------------------------
// Parameters and defines
//-----------------------------------------------------------------------------
localparam SIE_RAW_BYTES = 1024;

//-----------------------------------------------------------------------------
// Connections and init
//-----------------------------------------------------------------------------
initial
begin
    sie_bus.tx_data   = '0;
    sie_bus.tx_valid  = '0;
end

//-----------------------------------------------------------------------------
// Data control tasks
//-----------------------------------------------------------------------------
task send_data(
    input bit [SIE_RAW_BYTES-1:0][7:0] data, // Data bytes
    input int                          len   // Data bytes total
);
begin
    @(posedge clk);
    for (int i = 0; i < len; i++) begin
        sie_bus.tx_data  = data[i];
        sie_bus.tx_valid = 1'b1;
        @(posedge clk);
        while(!sie_bus.tx_ready)
            @(posedge clk);
    end
    @(posedge clk);
    sie_bus.tx_valid = 1'b0;
end
endtask : send_data

task receive_data(
    output logic [SIE_RAW_BYTES-1:0][7:0] data,  // Data bytes
    output int                            len    // Data bytes total
);
begin
    data = 0;
    len  = 0;
    wait(sie_bus.rx_active);
    while(sie_bus.rx_active) begin
        @(posedge clk);
        if (sie_bus.rx_active && sie_bus.rx_valid) begin
            data[len] = sie_bus.rx_data;
            len++;
        end
        if (sie_bus.rx_error)
            $display("%0d, W: %m: Warning, rx_error is active!", $time);
    end
end
endtask : receive_data

task detect_reset;
begin
    while(!sie_bus.reset)
        @(posedge clk);
    $display("%0d, I: %m: Bus reset detected", $time);

    while(sie_bus.reset)
        @(posedge clk);
    $display("%0d, I: %m: Bus reset released", $time);
end
endtask : detect_reset

endmodule : usb_sie_vip
