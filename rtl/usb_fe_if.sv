//==============================================================================
// Interface to USB "analog" frontend
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

interface usb_fe_if ();

logic dp_rx;     // USB Data+ input
logic dn_rx;     // USB Data- input
logic dp_tx;     // USB Data+ output
logic dn_tx;     // USB Data- output
logic tx_oen;    // USB Data output enable
logic pu;        // USB Data+ pullup control

modport ctrl (
    input  dp_rx,
    input  dn_rx,
    output dp_tx,
    output dn_tx,
    output tx_oen,
    output pu
);

// Analog frontend imitation
wire  dn;        // USB D- line
wire  dp;        // USB D+ line

assign dp = tx_oen ? dp_tx : 1'bz;
assign dn = tx_oen ? dn_tx : 1'bz;
assign dp_rx = dp;
assign dn_rx = dn;

modport phy (
    output pu,
    inout  dn,
    inout  dp
);

endinterface : usb_fe_if
