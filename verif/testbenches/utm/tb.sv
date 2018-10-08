//==============================================================================
// Testbench body
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

`include "../testbenches/tb_header.svh"

`define STOP_TIME  100ms   // Time when test stops
`define TEST_DESCR "UTMI test"

//-----------------------------------------------------------------------------
// Testbench body
//-----------------------------------------------------------------------------

initial
begin : tb_body
    bit [7:0][7:0] temp_raw_packet;

    //Reset
    wait(tb_rst_n);
    
    //Test start
    #100ns tb_busy = 1;
    #18ns;

    temp_raw_packet[0] = 8'h33;
    temp_raw_packet[1] = 8'h55;
    temp_raw_packet[2] = 8'hEE;
    temp_raw_packet[3] = 8'hFF;
    temp_raw_packet[4] = 8'h00;
    temp_raw_packet[5] = 8'h50;
    temp_raw_packet[6] = 8'hFF;
    temp_raw_packet[7] = 8'hAA;

    tb.host.send_raw_sync();
    tb.host.send_raw_packet(temp_raw_packet, 8*8);
    tb.host.send_raw_eop();

    temp_raw_packet[0] = 8'h22;
    temp_raw_packet[1] = 8'h68;
    temp_raw_packet[2] = 8'h75;
    temp_raw_packet[3] = 8'hCC;
    temp_raw_packet[4] = 8'hBB;
    temp_raw_packet[5] = 8'h88;
    temp_raw_packet[6] = 8'hFF;
    temp_raw_packet[7] = 8'h00;

    tb.host.send_raw_sync();
    tb.host.send_raw_packet(temp_raw_packet, 8*8);
    tb.host.send_raw_eop();

    tb_err = 0; // no errors

    //Test end
    #1us tb_busy = 0;
end

`include "../testbenches/tb_footer.svh"
