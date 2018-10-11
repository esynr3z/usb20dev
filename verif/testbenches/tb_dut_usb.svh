//-----------------------------------------------------------------------------
// DUT top
//-----------------------------------------------------------------------------
usb_fe_if usb_fe();

usb dut (
    .clk_48m (tb_clk),
    .rst     (~tb_rst_n),
    .fe_ctrl (usb_fe.ctrl)
);

usb_host_beh host_beh (
    .phy (usb_fe.phy)
);