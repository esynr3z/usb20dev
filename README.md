# USB 2.0 FS Device controller IP core

**UNDER DEVELOPMENT - CONSISTENCE BETWEEN THE CODE/DESCRIPTION/OTHER INFORMATION MAY BE BROKEN**

**usb20dev** is an open source IP core written in SystemVerilog for interfacing USB without any external chips.
The main idea is just to route USB signals directly to FPGA and use a pair of tri-state IO as "analog" frontend. Yes, this will be outside of the USB specs, but should work. And USB 2.0 full-speed (12Mbps) is the maximum can be achieved this way.

## Functional blocks

![func_sch](doc/func_sch.png)

* **"Analog" Frontend (FE)** : Two generic 3.3V tri-state IO
* **Serial Interface Engine (SIE)** :
    * NRZI encoding / decoding
    * Bit stuffing / unstuffing
    * Serial-Parallel / Parallel-Serial Conversion
    * SYNC, RESET and EOP detection
* **[Not implemented yet] Protocol Engine (PE)** :
    * Packet recognition
    * Transaction sequencing
    * CRC generation and checking
    * Packet ID (PID) generation and checking / decoding
* **[Not implemented yet] Endpoints Router (EPR)** : Interface for endpoints array
* **[Not implemented yet] Control Endpoint (EP0)** : Endpoint 0 IN and Endpoint 0 OUT logic
* **[Not implemented yet] Device Specific Endpoinds** : All other user application endpoints
