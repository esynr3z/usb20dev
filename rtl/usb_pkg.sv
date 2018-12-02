//==============================================================================
// Package with global USB types and parameters
//
//------------------------------------------------------------------------------
// [usb20dev] 2018 Eden Synrez <esynr3z@gmail.com>
//==============================================================================

package usb_pkg;

//-----------------------------------------------------------------------------
// Types
//-----------------------------------------------------------------------------
typedef logic [7:0]  bus8_t;
typedef logic [15:0] bus16_t;
typedef logic [31:0] bus32_t;

typedef enum logic [1:0] {
    USB_LS_SE0 = 2'b00,
    USB_LS_J   = 2'b01,
    USB_LS_K   = 2'b10,
    USB_LS_SE1 = 2'b11
} usb_line_state_t;

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------
parameter        USB_STUFF_BITS_N = 6;
parameter bus8_t USB_SYNC_VAL     = 'h80;

parameter usb_line_state_t [7:0] USB_SYNC_PATTERN = {
    USB_LS_K, USB_LS_J, USB_LS_K, USB_LS_J,
    USB_LS_K, USB_LS_J, USB_LS_K, USB_LS_K
};
parameter usb_line_state_t [2:0] USB_EOP_PATTERN = {
    USB_LS_SE0, USB_LS_SE0, USB_LS_J
};

parameter logic [4:0] USB_CRC5_VALID  = 5'b01100;
parameter bus16_t     USB_CRC16_VALID = 16'b1000000000001101;

endpackage : usb_pkg
