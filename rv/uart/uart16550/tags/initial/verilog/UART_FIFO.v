//  UART core transmitter FIFO
//
// Author: Jacob Gorban   (jacob.gorban@flextronicssemi.com)
// Company: Flextronics Semiconductor
//
// Filename: UART_FIFO.v
//
// The actual FIFO logic is in the FIFO_inc.v file
//
// Releases:
//              1.1     First release
//


`include "timescale.v"
`include "UART_defines.v"

module UART_TX_FIFO (clk, 
	wb_rst_i, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	underrun,
	overrun,
	count
	);

`include "FIFO_inc.v"

endmodule
