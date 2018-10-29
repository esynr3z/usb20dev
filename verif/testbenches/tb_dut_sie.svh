//-----------------------------------------------------------------------------
// DUT top
//-----------------------------------------------------------------------------
usb_fe_if usb_fe();
usb_sie_if usb_sie_bus();

usb_sie dut (
    .clk     (tb_clk),
    .rst     (~tb_rst_n),
    .fe_ctrl (usb_fe.ctrl),
    .sie_bus (usb_sie_bus.sie)
);

usb_host_beh host_beh (
    .phy (usb_fe.phy)
);

usb_sie_vip sie_vip (
    .clk     (tb_clk),
    .rst     (~tb_rst_n),
    .sie_bus (usb_sie_bus.pe)
);

