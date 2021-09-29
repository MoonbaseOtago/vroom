//  UART core receiver FIFO
//
// Author: Jacob Gorban   (jacob.gorban@flextronicssemi.com)
// Company: Flextronics Semiconductor
//
// Filename: UART_RX_FIFO.v
//
// The standard FIFO logic is in the FIFO_inc.v file
// Additional logic is in this file.
//
// Releases:
//              1.1     First release
//


`include "timescale.v"
`include "UART_defines.v"

module UART_RX_FIFO (clk,
	wb_rst_i, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	underrun,
	overrun,
	count,
	error_bit
	);

output		error_bit;  // a parity or framing error is inside the receiver FIFO.
wire		error_bit;

`include "FIFO_inc.v"

// Additional logic for detection of error conditions (parity and framing) inside the FIFO
// for the Line Status Register bit 7
wire	[`FIFO_REC_WIDTH-1:0]	word0 = fifo[0];
wire	[`FIFO_REC_WIDTH-1:0]	word1 = fifo[1];
wire	[`FIFO_REC_WIDTH-1:0]	word2 = fifo[2];
wire	[`FIFO_REC_WIDTH-1:0]	word3 = fifo[3];
wire	[`FIFO_REC_WIDTH-1:0]	word4 = fifo[4];
wire	[`FIFO_REC_WIDTH-1:0]	word5 = fifo[5];
wire	[`FIFO_REC_WIDTH-1:0]	word6 = fifo[6];
wire	[`FIFO_REC_WIDTH-1:0]	word7 = fifo[7];

wire	[`FIFO_REC_WIDTH-1:0]	word8 = fifo[8];
wire	[`FIFO_REC_WIDTH-1:0]	word9 = fifo[9];
wire	[`FIFO_REC_WIDTH-1:0]	word10 = fifo[10];
wire	[`FIFO_REC_WIDTH-1:0]	word11 = fifo[11];
wire	[`FIFO_REC_WIDTH-1:0]	word12 = fifo[12];
wire	[`FIFO_REC_WIDTH-1:0]	word13 = fifo[13];
wire	[`FIFO_REC_WIDTH-1:0]	word14 = fifo[14];
wire	[`FIFO_REC_WIDTH-1:0]	word15 = fifo[15];

// a 1 is returned if any of the error bits in the fifo is 1
assign	error_bit = |(word0[1:0]  | word1[1:0]  | word2[1:0]  | word3[1:0]  |
		      word4[1:0]  | word5[1:0]  | word6[1:0]  | word7[1:0]  |
		      word8[1:0]  | word9[1:0]  | word10[1:0] | word11[1:0] |
		      word12[1:0] | word13[1:0] | word14[1:0] | word15[1:0] );

endmodule
