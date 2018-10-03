`include "../testbenches/tb_header.sv"

`define STOP_TIME  50ms   // Time when test stops
`define TEST_DESCR "Example test that do nothing"

//-----------------------------------------------------------------------------
// Testbench body
//-----------------------------------------------------------------------------
initial
begin : tb_body
    //Reset
    wait(tb_rst_n);
    
    //Test start
    #100ns tb_busy = 1;

    $display("Super-druper test starts doing something...");
    #1ms;
    $display("Still doing...");
    #1ms;
    $display("Oh, enough");

    tb_err = 0; // no errors

    //Test end
    #100ns tb_busy = 0;
end

`include "../testbenches/tb_footer.sv"
