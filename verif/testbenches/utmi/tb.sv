//==============================================================================
// Testbench body
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

`include "../testbenches/tb_header.svh"

`define STOP_TIME  50ms   // Time when test stops
`define TEST_DESCR "UTMI test"

//-----------------------------------------------------------------------------
// Testbench body
//-----------------------------------------------------------------------------

initial
begin : tb_body
    //Reset
    wait(tb_rst_n);
    
    //Test start
    #100ns tb_busy = 1;
    #18ns;
    tb.host.send_j_bit();
    tb.host.send_k_bit();
    tb.host.send_j_bit();
    tb.host.send_k_bit();
    tb.host.send_se0_bit();
    tb.host.send_j_bit();
    tb.host.send_k_bit();
    tb.host.send_j_bit();
    tb.host.send_k_bit();

    tb_err = 0; // no errors

    //Test end
    #100ns tb_busy = 0;
end

`include "../testbenches/tb_footer.svh"
