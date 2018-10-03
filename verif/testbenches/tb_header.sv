`timescale 1ns/1ps

`define PERIOD_48MHz    20.8333ns
`define CLK_PERIOD      `PERIOD_48MHz
`define RST_DELAY_TIME  100ns

module tb();

bit tb_busy = 0;
bit tb_err = 0;

//-----------------------------------------------------------------------------
// Clock and reset
//-----------------------------------------------------------------------------
logic tb_clk = 0;
logic tb_rst_n = 0;

always
begin
    #(`CLK_PERIOD/2);
    tb_clk <= ~tb_clk;
end

initial
begin
    #(`RST_DELAY_TIME) tb_rst_n <= 1;
end

//-----------------------------------------------------------------------------
// DUT top
//-----------------------------------------------------------------------------
usb_fe_if usb_fe();

usb dut (
    .clk_48m    (tb_clk),
    .rst        (~tb_rst_n),
    .fe_ctrl    (usb_fe.ctrl)
);

// To be continued in tb.sv file ...
