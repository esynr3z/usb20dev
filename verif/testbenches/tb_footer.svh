//==============================================================================
// Testbench footer with some common tesbench control
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

// After the end of tb.sv file ...

//-----------------------------------------------------------------------------
// Testbench control
//-----------------------------------------------------------------------------
initial
begin : tb_ctrl
    $display("### Test started ###");
    $display("Test description: %s\n", `TEST_DESCR);
    wait(tb_busy);
    wait(!tb_busy);
    #10;
    if (tb_err)
        $display("\n### Test FAIL ###");
    else
        $display("\n### Test OK ###");
    $stop;
end

//-----------------------------------------------------------------------------
// Testbench stop
//-----------------------------------------------------------------------------
`ifdef STOP_TIME

initial
begin : tb_stop
    #(`STOP_TIME);
    $stop;
end

`endif //STOP_TIME

endmodule : tb
