//==============================================================================
// Package with UTM types and parameters
//
//------------------------------------------------------------------------------
// 2018, Eden Synrez <esynr3z@gmail.com>
//==============================================================================

package usb_utm_pkg;

import usb_pkg::*; // main package chaining
export usb_pkg::*;

typedef enum logic [1:0] {
    UTM_LS_SE0 = 2'b00, 
    UTM_LS_J   = 2'b01, 
    UTM_LS_K   = 2'b10, 
    UTM_LS_SE1 = 2'b11 
} utm_line_state_t;

typedef enum logic [1:0] {
    UTM_OM_NORMAL   = 2'b00, 
    UTM_OM_NONDRIVE = 2'b01,
    UTM_OM_DISABLE  = 2'b10
} utm_op_mode_t;

endpackage : usb_utm_pkg
