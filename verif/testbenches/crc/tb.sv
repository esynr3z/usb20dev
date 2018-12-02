//==============================================================================
// Testbench body for CRC test
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

`include "../testbenches/tb_header.svh"

//-----------------------------------------------------------------------------
// DUT top
//-----------------------------------------------------------------------------
usb_fe_if usb_fe();

logic [7:0] dut_data = '0;
logic       dut_wr = 1'b0;
logic       dut_clear = 1'b0;
logic       dut_busy;
logic [4:0] dut_crc;

usb_crc5 dut (
    .clk    (tb_clk),
    .rst    (~tb_rst_n),
    .data   (dut_data),
    .wr     (dut_wr),
    .clear  (dut_clear),
    .busy   (dut_busy),
    .crc    (dut_crc)
);

usb_host_beh host_beh (
    .phy (usb_fe.phy)
);

//`define STOP_TIME  100ms   // Time when test stops
`define TEST_DESCR "CRC test: compare CRC5 and CRC16 calculation on Host and Device"
`define DATA_TOTAL 16

//-----------------------------------------------------------------------------
// Testbench body
//-----------------------------------------------------------------------------
logic [4:0] crc5_val;
logic [7:0] data_in [`DATA_TOTAL-1:0];
logic [4:0] data_crc5_host [`DATA_TOTAL-1:0];
logic [4:0] data_crc5_dev [`DATA_TOTAL-1:0];

initial
begin : tb_body
    tb_err = 0; // no errors

    //Reset
    wait(tb_rst_n);

    //Test start
    #100ns tb_busy = 1;

    for (int i = 0; i < `DATA_TOTAL; i++) begin
        data_in[i] = $urandom();
    end

    $display("%0d, I: %m: Host calculate CRC5", $time);
    for (int i = 0; i < `DATA_TOTAL; i++) begin
        #10ns host_beh.step_crc5(data_in[i], crc5_val);
        #1ns  data_crc5_host[i] = host_beh.crc5;
    end

    $display("%0d, I: %m: Device calculate CRC5", $time);
    for (int i = 0; i < `DATA_TOTAL; i++) begin
        @(posedge tb_clk);#1ns;
        dut_data = data_in[i];
        dut_wr = 1'b1;
        @(posedge tb_clk);#1ns;
        dut_wr = 1'b0;
        @(posedge tb_clk);
        wait(!dut_busy);
        @(posedge tb_clk);#1ns;
        data_crc5_dev[i] = dut_crc;
    end

    $display("%0d, I: %m: Compare results", $time);
    for (int i = 0; i < `DATA_TOTAL; i++) begin
        if (data_crc5_dev[i] != data_crc5_host[i])
            tb_err++;
    end

    //Test end
    #3us tb_busy = 0;
end

`include "../testbenches/tb_footer.svh"
