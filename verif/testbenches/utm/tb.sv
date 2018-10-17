//==============================================================================
// Testbench body for UTM test
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

`include "../testbenches/tb_header.svh"
`include "../testbenches/tb_dut_utm.svh"

//`define STOP_TIME  100ms   // Time when test stops
`define TEST_DESCR "UTM test - receive, transmit and special cases"
`define RND_CYCLES 1000

//-----------------------------------------------------------------------------
// Testbench body
//-----------------------------------------------------------------------------
parameter X_PACKET_LEN = 67;

class packet_tester_t;
    rand integer tx_len;
    rand reg [X_PACKET_LEN-1:0][7:0] tx_data;

    integer rx_len;
    reg [X_PACKET_LEN-1:0][7:0] rx_data;

    constraint LegalOrder
    {
        solve tx_len before tx_data;
    }
    constraint LegalConfig
    {
        tx_len >3; tx_len < X_PACKET_LEN;

        foreach(tx_data[i])
            if (i >= tx_len)
               tx_data[i] == 'b0;
    }

    function new();
        tx_len  = 0;
        tx_data = 0;
        rx_len  = 0;
        rx_data = 0;
    endfunction : new

    function bit is_len_eq();
        is_len_eq = 1;
        if (tx_len !== rx_len) begin
            $display("%0d, E: %m: Error, tx_len and rx_len are not equal!", $time);
            is_len_eq = 0;
        end
    endfunction : is_len_eq

    function bit is_data_eq();
        is_data_eq = 1;

        for (int i = 0; i < tx_len; i++) begin
            if(tx_data[i] !== rx_data[i]) begin
                $display("%0d, E: %m: Error, packets are not equal!", $time);
                $display("\ttx_data[%0d] = 0x%0x; rx_data[%0d] = 0x%0x", i, tx_data[i], i, rx_data[i]);
                is_data_eq = 0;
            end
        end
    endfunction : is_data_eq

endclass : packet_tester_t

initial
begin : tb_body
    //paste to ncim console to view variables
    packet_tester_t ptester = new;

    tb_err = 0; // no errors

    //Reset
    wait(tb_rst_n);
    
    //Test start
    #100ns tb_busy = 1;

    $display("%0d, I: %m: SIE --> UTM --> Host", $time);
    for (int i = 0; i < `RND_CYCLES; i++) begin : crv_tx
        ptester.randomize();
        $display("%0d, I: %m: Cycle %0d, %0d bytes to transmit", $time, i, ptester.tx_len);

        fork
            tb.sie_beh.send_data(ptester.tx_data, ptester.tx_len);
            tb.host_beh.receive_raw_packet(ptester.rx_data, ptester.rx_len);
        join

        if (!ptester.is_len_eq())
            tb_err++;
        else if (!ptester.is_data_eq())
            tb_err++;
    end : crv_tx

    $display("%0d, I: %m: SIE <-- UTM <-- Host", $time);
    for (int i = 0; i < `RND_CYCLES; i++) begin : crv_rx
        ptester.randomize();
        $display("%0d, I: %m: Cycle %0d, %0d bytes to receive", $time, i, ptester.tx_len);

        fork
            tb.host_beh.send_raw_packet(ptester.tx_data, ptester.tx_len);
            tb.sie_beh.receive_data(ptester.rx_data, ptester.rx_len);
        join

        if (!ptester.is_len_eq())
            tb_err++;
        else if (!ptester.is_data_eq())
            tb_err++;
    end : crv_rx

    //Test end
    #3us tb_busy = 0;
end

`include "../testbenches/tb_footer.svh"
