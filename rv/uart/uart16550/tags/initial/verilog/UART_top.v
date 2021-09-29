// UART	Wishbone-compatible core top level 
//
// Author: Jacob Gorban	  (jacob.gorban@flextronicssemi.com)
// Company: Flextronics	Semiconductor
//
// Releases:
//		1.1	First release
//

`include "timescale.v"
`include "UART_defines.v"

module UART_top	(
	clk, 
	
	// Wishbone signals
	wb_rst_i, wb_addr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o,	
	int_o, // interrupt request

	// UART	signals
	// serial input/output
	stx_o, srx_i,

	// modem signals
	rts_o, cts_i, dtr_o, dsr_i, ri_i, dcd_i

	);


input		clk;

// WISHBONE interface
input		wb_rst_i;
input	[`ADDR_WIDTH-1:0]	wb_addr_i;
input	[7:0]	wb_dat_i;
output	[7:0]	wb_dat_o;
input		wb_we_i;
input		wb_stb_i;
input		wb_cyc_i;
output		wb_ack_o;
output		int_o;

// UART	signals
input		srx_i;
output		stx_o;
output		rts_o;
input		cts_i;
output		dtr_o;
input		dsr_i;
input		ri_i;
input		dcd_i;

wire		stx_o;
wire		rts_o;
wire		dtr_o;

wire	[`ADDR_WIDTH-1:0]	wb_addr_i;
wire	[7:0]	wb_dat_i;
wire	[7:0]	wb_dat_o;

wire		we_o;	// Write enable for registers

wire	[3:0]	ier;
wire	[7:0]	iir;
wire	[3:0]	fcr;  /// bits 7,6,2,1 of fcr. Other bits are ignored
wire	[4:0]	mcr;
wire	[7:0]	lcr;
wire	[7:0]	lsr;	
wire	[7:0]	msr;
wire	[31:0]	dl;  // 32-bit divisor latch

wire		enable;

//
// MODULE INSTANCES
//

////  WISHBONE interface module
UART_wb		wb_interface(
		.clk(		clk		),
		.wb_rst_i(	wb_rst_i	),
//		.wb_dat_i(	wb_dat_i	),
//		.wb_dat_o(	wb_dat_o	),
		.wb_we_i(	wb_we_i		),
		.wb_stb_i(	wb_stb_i	),
		.wb_cyc_i(	wb_cyc_i	),
		.wb_ack_o(	wb_ack_o	),
//		.int_o(		int_o		),
		.we_o(		we_o		)
		);

// Registers
UART_regs	regs(
		.clk(		clk		),
		.wb_rst_i(	wb_rst_i	),
		.wb_addr_i(	wb_addr_i	),
		.wb_dat_i(	wb_dat_i	),
		.wb_dat_o(	wb_dat_o	),
		.wb_we_i(	we_o		),
		.ier(		ier		),
		.iir(		iir		),
		.fcr(		fcr		),
		.mcr(		mcr		),
		.lcr(		lcr		),
		.lsr(		lsr		),
		.msr(		msr		),
		.dl(		dl		),
		.modem_inputs(	{cts_i, dsr_i,
				 ri_i,  dcd_i}	),
		.stx_o(		stx_o		),
		.srx_i(		srx_i		),
		.enable(	enable		),
		.rts_o(		rts_o		),
		.dtr_o(		dtr_o		)
		);

endmodule
