//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_device_if_memory.v                                     ////
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
`include "uart_device_if_defines.v"

module uart_device_if_memory (adr, data_in, data_out, read, write);

parameter DATA_WIDTH = 36;

input   [31:0]            adr;
input                     read, write;
input   [DATA_WIDTH-1:0]  data_in;

output  [DATA_WIDTH-1:0]  data_out;
reg     [DATA_WIDTH-1:0]  data_out;

reg [35:0] mem [0:`MEM_DEPTH-1];

always @ (adr)
begin
  data_out = mem[adr];          // Reading instructions from internal memory
end

initial
begin
  $readmemh("vapi.log", mem);   // Copying instruction from file to internal memory.
end

endmodule
