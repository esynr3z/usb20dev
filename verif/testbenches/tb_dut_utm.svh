//-----------------------------------------------------------------------------
// DUT top
//-----------------------------------------------------------------------------
usb_fe_if usb_fe();
usb_utmi_if usb_utmi();

usb_utm dut (
    .clk     (tb_clk),
    .rst     (~tb_rst_n),
    .fe_ctrl (usb_fe.ctrl),
    .utmi    (usb_utmi.utm)
);

usb_host_beh host_beh (
    .phy (usb_fe.phy)
);

usb_pe_beh pe_beh (
    .clk  (tb_clk),
    .rst  (~tb_rst_n),
    .utmi (usb_utmi.pe)
);

