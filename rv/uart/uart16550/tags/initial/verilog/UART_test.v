`include "timescale.v"
module UART_test ();

`include "UART_defines.v"

reg				clkr;
reg				wb_rst_ir;
reg	[`ADDR_WIDTH-1:0]	wb_addr_ir;
reg	[7:0]			wb_dat_ir;
wire	[7:0]			wb_dat_o;
reg				wb_we_ir;
reg				wb_stb_ir;
reg				wb_cyc_ir;
wire				wb_ack_o;
wire				int_o;
wire				stx_o;
reg				srx_ir;
wire				rts_o;
reg				cts_ir;
wire				dtr_o;
reg				dsr_ir;
reg				ri_ir;
reg				dcd_ir;
wire	[2:0]			wb_addr_i;
wire	[7:0]			wb_dat_i;




UART_top	uart_snd(
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


// All the signals and regs named with a 1 are receiver fifo signals

reg	[`ADDR_WIDTH-1:0]	wb1_addr_ir;
reg	[7:0]			wb1_dat_ir;
wire	[7:0]			wb1_dat_o;
reg				wb1_we_ir;
reg				wb1_stb_ir;
reg				wb1_cyc_ir;
wire				wb1_ack_o;
wire				int1_o;
wire				stx1_o;
reg				srx1_ir;
wire				rts1_o;
reg				cts1_ir;
wire				dtr1_o;
reg				dsr1_ir;
reg				ri1_ir;
reg				dcd1_ir;
wire	[2:0]			wb1_addr_i;
wire	[7:0]			wb1_dat_i;


UART_top	uart_rcv(
	clk, 
	
	// Wishbone signals
	wb_rst_i, wb1_addr_i, wb1_dat_i, wb1_dat_o, wb1_we_i, wb1_stb_i, wb1_cyc_i, wb1_ack_o,	
	int1_o, // interrupt request

	// UART	signals
	// serial input/output
	stx1_o, srx1_i,

	// modem signals
	rts1_o, cts1_i, dtr1_o, dsr1_i, ri1_i, dcd1_i

	);

assign clk = clkr;
assign wb_dat_i = wb_dat_ir;
assign wb_we_i = wb_we_ir;
assign wb_rst_i = wb_rst_ir;
assign wb_addr_i = wb_addr_ir;
assign wb_stb_i = wb_stb_ir;
assign wb_cyc_i = wb_cyc_ir;
assign srx_i = srx_ir;
assign cts_i = cts_ir;
assign dsr_i = dsr_ir;
assign ri_i = ri_ir;
assign dcd_i = dcd_ir;

assign wb1_dat_i = wb1_dat_ir;
assign wb1_we_i = wb1_we_ir;
assign wb1_addr_i = wb1_addr_ir;
assign wb1_stb_i = wb1_stb_ir;
assign wb1_cyc_i = wb1_cyc_ir;
assign srx1_i = srx1_ir;
assign cts1_i = cts1_ir;
assign dsr1_i = dsr1_ir;
assign ri1_i = ri1_ir;
assign dcd1_i = dcd1_ir;

/////////// CONNECT THE UARTS
always @(stx_o)
begin
	srx1_ir = stx_o;	
end

initial
begin
	clkr = 0;
	#20000 $finish;
end

task cycle;    // transmitter
input		we;
input	[2:0]	addr;
input	[7:0]	dat;		
begin
	@(negedge clk)
	wb_addr_ir <= #1 addr;
	wb_we_ir <= #1 we;
	wb_dat_ir <= #1 dat;
	wb_stb_ir <= #1 1;
	wb_cyc_ir <= #1 1;
	wait (wb_ack_o==1)
	@(posedge clk);
	wb_we_ir <= #1 0;
	wb_stb_ir<= #1 0;
	wb_cyc_ir<= #1 0;
end
endtask

task cycle1;   // receiver
input		we;
input	[2:0]	addr;
input	[7:0]	dat;		
begin
	@(negedge clk)
	wb1_addr_ir <= #1 addr;
	wb1_we_ir <= #1 we;
	wb1_dat_ir <= #1 dat;
	wb1_stb_ir <= #1 1;
	wb1_cyc_ir <= #1 1;
	wait (wb1_ack_o==1)
	@(posedge clk);
	wb1_we_ir <= #1 0;
	wb1_stb_ir<= #1 0;
	wb1_cyc_ir<= #1 0;
end
endtask

// The test sequance
initial
begin
	#1 wb_rst_ir = 1;
	#10 wb_rst_ir = 0;
	wb_stb_ir = 0;
	wb_cyc_ir = 0;
	wb_we_ir = 0;
	
	//write to lcr. set bit 7
	//wb_cyc_ir = 1;
	cycle(1, `REG_LC, 8'b10011011);
	// set dl to divide by 3
	cycle(1, `REG_DL1, 8'd2);
	@(posedge clk);
	@(posedge clk);
	// restore normal registers
	cycle(1, `REG_LC, 8'b00011011);
	cycle(1, 0, 8'b01101011);
	@(posedge clk);
	@(posedge clk);
	cycle(1, 0, 8'b01000101);
	#100;
	wait (uart_snd.regs.state==0 && uart_snd.regs.tf_count==0);
	#100;
	$finish;
	
end

// receiver side
initial
begin
	#11;
	wb1_stb_ir = 0;
	wb1_cyc_ir = 0;
	wb1_we_ir = 0;
	
	//write to lcr. set bit 7
	//wb_cyc_ir = 1;
	cycle1(1, `REG_LC, 8'b10011011);
	// set dl to divide by 3
	cycle1(1, `REG_DL1, 8'd2);
	@(posedge clk);
	@(posedge clk);
	// restore normal registers
	cycle1(1, `REG_LC, 8'b00011011);
end

//always @(uart_rcv.regs.rstate)
//begin
//	$display($time,": Receiver state changed to: ", uart_rcv.regs.rstate);
//end

always
begin
	#5 clkr = ~clk;
end

endmodule
