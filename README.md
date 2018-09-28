# USB 2.0 FS Device controller IP core

**usb20dev** is an open source IP core written in SystemVerilog for interfacing USB without any external chips.
The main idea is just to route USB signals directly to FPGA and use simple IO as "analog frontend". Yes, this will be outside of the USB specs, but should work. And USB 2.0 full-speed (12Mbps) is the maximum we can achieve by this way.

```
                         FPGA
            ________   |
 USB      -|__1.5k__|--| usb_pu
____     |             |
    |    |             |
 D+ |----o-------------| usb_dp
    |                  |
 D- |------------------| usb_dm
____|                  |
                       |

```

**UNDER DEVELOPMENT**
