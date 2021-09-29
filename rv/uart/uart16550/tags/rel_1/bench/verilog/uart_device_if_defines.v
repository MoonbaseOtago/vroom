//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_device_if_defines.v                                    ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/projects/uart16550/                ////
////                                                              ////
////  Documentation related to this project:                      ////
////  http://www.opencores.org/projects/uart16550/                ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  Device interface for testing purposes                       ////
////                                                              ////
////  Known problems (limits):                                    ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created and updated:   (See log for the revision history)   ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2001 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
//
//
//
//


`define   MEM_DEPTH     1000      // Number of commands in the file.txt

//`define   SHOW_RX_LCR           // Show RX lcr configuration
//`define   SHOW_TX_LCR           // Show TX lcr configuration
//`define   SHOW_RECEIVED_BITS    // Show received bits
//`define   SHOW_FIFO_ACTIVITY    // Shows data being written to FIFO
