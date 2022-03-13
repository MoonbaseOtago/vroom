//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-21 Paul Campbell - paul@taniwha.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 

module chip (input ireset, 
`ifdef SIMD
	input simd_enable,
`endif
	input clk_in,

`ifndef VSYNTH2
	output			   reset_out,
	input			   reset_out_ack,
`endif

	input [4:0]cpu_id,

	output			   uart_tx,
	input			   uart_rx,
	output			   uart_rts,
	input			   uart_cts,

`ifndef VS2
	input        [31:0]block_count_0,
	input        [31:0]block_addr_0,
	input        [31:0]block_count_1,
	input        [31:0]block_addr_1,
`endif
`ifdef VS2
	input	     [31:0]gpio_pads
`else
`ifdef VERILATOR
	input	     [31:0]gpio_pads
`else
	inout	     [31:0]gpio_pads
`endif
`endif

`ifdef VS2
	,
	input		sh_cl_clk,
	input		sh_cl_reset,

	output		cl_sh_ddr_awvalid,
    input		sh_cl_ddr_awready,
    output[55:6]cl_sh_ddr_awaddr,
    output [TSIZE-1:0]cl_sh_ddr_awid,

    output		cl_sh_ddr_wvalid,
    input		sh_cl_ddr_wready,
    output [TSIZE-1:0]cl_sh_ddr_wid,
    output[511:0]cl_sh_ddr_wdata,

    input[TSIZE-1:0] sh_cl_ddr_bid,
    input[1:0] sh_cl_ddr_bresp,
    input sh_cl_ddr_bvalid,
    output  cl_sh_ddr_bready,

    output		cl_sh_ddr_arvalid,
    input		sh_cl_ddr_arready,
	output [TSIZE-1:0]cl_sh_ddr_arid,
    output[55:6]cl_sh_ddr_araddr,

    output		cl_sh_ddr_rready,
    input		sh_cl_ddr_rvalid,
	input  [TSIZE-1:0]sh_cl_ddr_rid,
    input[511:0]sh_cl_ddr_rdata

`endif
`ifdef VS2
	,
    // AWS SD interface
	output			 sd_clk,
	output			 sd_reset,
    output           sd_command_start,
    input            sd_command_done,
    output           sd_read,
    output     [39:8]sd_address,
    output           sd_out_write,
    output     [63:0]sd_out,
    input            sd_out_full,
    output           sd_in_read,
    input      [63:0]sd_in,
    input            sd_in_empty
`endif
	);

	parameter NCPU=1;
	parameter NHART=1;
	parameter NPHYS=56;
	parameter CACHE_LINE_SIZE=512;
	parameter ACACHE_LINE_SIZE=$clog2(512/8);
	parameter NLDSTQ=16;
	parameter TRANS_ID_SIZE=6;	// 6 for i/tcaches must be >= $clog2(NLDSTQ)
	parameter NI=NCPU*2;
	parameter TSIZE=TRANS_ID_SIZE+$clog2(NI);
	parameter RV=64;
	parameter NINTERRUPTS=20;


`ifdef PSYNTH
	wire yreset, dreset;//, locked;
//	clockgen_simple	clkgen(.clk_in(clk_in), .clk(clk), .locked(locked));
	clockgen_simple	clkgen(.clk_in(clk_in), .clk(clk));
	HARD_SYNC reset_sync(.CLK(clk), .DIN(ireset), .DOUT(dreset));
	assign yreset = dreset;//|!locked;
`else
	wire clk=clk_in;
	wire yreset = ireset;
`endif

	reg [2:0]r_reset_count;	// reset lengthener
	always @(posedge clk)
	if (yreset) begin
		r_reset_count <= ~0;
	end else
	if (r_reset_count != 0) begin
		r_reset_count <= r_reset_count-1;
	end


`ifdef VSYNTH2
	wire			   reset_out;	// note: verilator non AWS case
	wire			   reset_out_ack=reset_out;
`endif

	reg [NCPU-1:0]r_reset_out;
	wire [NCPU-1:0]reset_out_c;
	assign reset_out = |r_reset_out;
	always @(posedge clk)
	if (yreset || r_reset_count != 0 || reset_out_ack) begin
		r_reset_out <= 0;
	end else begin
		r_reset_out <= r_reset_out|reset_out_c;
	end
	wire xreset = yreset || r_reset_count != 0 || |r_reset_out;


	
	reg	 [2:0]r_reset;	// so synth can do fanout
	wire	  reset = r_reset[2];
	always @(posedge clk)
		r_reset <= {r_reset[1:0],xreset};
   


    wire  [NPHYS-1:ACACHE_LINE_SIZE]ic_raddr[0:NCPU-1];
    wire        ic_raddr_req[0:NCPU-1];
    wire        ic_raddr_ack[0:NCPU-1];
    wire   [TRANS_ID_SIZE-1:0]ic_raddr_trans[0:NCPU-1];
    wire   [2:0]ic_raddr_snoop[0:NCPU-1];
    wire [CACHE_LINE_SIZE-1:0]ic_rdata[0:NCPU-1];
    wire        ic_rdata_req[0:NCPU-1];
    wire        ic_rdata_ack[0:NCPU-1];
    wire   [TRANS_ID_SIZE-1:0]ic_rdata_trans[0:NCPU-1];
    wire   [2:0]ic_rdata_resp[0:NCPU-1];
    wire  [NPHYS-1:ACACHE_LINE_SIZE]ic_snoop_addr[0:NCPU-1];
    wire        ic_snoop_addr_req[0:NCPU-1];
    wire        ic_snoop_addr_ack[0:NCPU-1];
    wire   [1:0]ic_snoop_snoop[0:NCPU-1];
    wire   [2:0]ic_snoop_data_resp[0:NCPU-1];

	wire  [NPHYS-1:ACACHE_LINE_SIZE]dc_raddr[0:NCPU-1];
	wire        dc_raddr_req[0:NCPU-1];
	wire        dc_raddr_ack[0:NCPU-1];
	wire   [TRANS_ID_SIZE-1:0]dc_raddr_trans[0:NCPU-1];
	wire   [2:0]dc_raddr_snoop[0:NCPU-1];
	wire [CACHE_LINE_SIZE-1:0]dc_rdata[0:NCPU-1];
	wire   [TRANS_ID_SIZE-1:0]dc_rdata_trans[0:NCPU-1];
	wire        dc_rdata_req[0:NCPU-1];
	wire        dc_rdata_ack[0:NCPU-1];
	wire   [2:0]dc_rdata_resp[0:NCPU-1];
	wire  [NPHYS-1:ACACHE_LINE_SIZE]dc_waddr[0:NCPU-1];
	wire        dc_waddr_req[0:NCPU-1];
	wire        dc_waddr_ack[0:NCPU-1];
	wire   [1:0]dc_waddr_snoop[0:NCPU-1];
	wire   [TRANS_ID_SIZE-1:0]dc_waddr_trans[0:NCPU-1];
	wire [CACHE_LINE_SIZE-1:0]dc_wdata[0:NCPU-1];
	wire   [TRANS_ID_SIZE-1:0]dc_wdata_trans[0:NCPU-1];
	wire        dc_wdata_done[0:NCPU-1];
	wire  [NPHYS-1:ACACHE_LINE_SIZE]dc_snoop_addr[0:NCPU-1];
	wire        dc_snoop_addr_req[0:NCPU-1];
	wire        dc_snoop_addr_ack[0:NCPU-1];
	wire   [1:0]dc_snoop_snoop[0:NCPU-1];
	wire   [2:0]dc_snoop_data_resp[0:NCPU-1];
	wire [CACHE_LINE_SIZE-1:0]dc_snoop_data[0:NCPU-1];

	//
	// IO buses
	//
	wire    [NCPU-1:0]io_cpu_addr_req;
	wire    [NCPU-1:0]io_cpu_addr_ack;
	wire   [NPHYS-1:0]io_cpu_addr[0:NCPU-1];
	wire    [NCPU-1:0]io_cpu_read;
	wire    [NCPU-1:0]io_cpu_lock;
	wire         [7:0]io_cpu_mask[0:NCPU-1];
	wire      [RV-1:0]io_cpu_wdata[0:NCPU-1];
	wire    [NCPU-1:0]io_cpu_data_req;
	wire    [NCPU-1:0]io_cpu_data_ack;
	wire     [RV-1:0]io_cpu_rdata[0:NCPU-1];
	wire   [NCPU-1:0]io_cpu_data_err;

	wire	  [NCPU-1:0]io_clic_m_enable;
	wire	  [NCPU-1:0]io_clic_h_enable;
	wire	  [NCPU-1:0]io_clic_s_enable;
	wire	  [NCPU-1:0]io_clic_u_enable;
	wire	       [7:0]io_clic_m_il[0:NCPU-1];
	wire[$clog2(NINTERRUPTS)-1:0]io_clic_m_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_m_pending;
	wire	  [NCPU-1:0]io_clic_m_vec;
	wire	       [7:0]io_clic_h_il[0:NCPU-1];
	wire[$clog2(NINTERRUPTS)-1:0]io_clic_h_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_h_pending;
	wire	  [NCPU-1:0]io_clic_h_vec;
	wire	       [7:0]io_clic_s_il[0:NCPU-1];
	wire[$clog2(NINTERRUPTS)-1:0]io_clic_s_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_s_pending;
	wire	  [NCPU-1:0]io_clic_s_vec;
	wire	       [7:0]io_clic_u_il[0:NCPU-1];
	wire[$clog2(NINTERRUPTS)-1:0]io_clic_u_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_u_pending;
	wire	  [NCPU-1:0]io_clic_u_vec;
	wire[NINTERRUPTS-1:0]io_interrupts[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_ack;
	wire[$clog2(NINTERRUPTS)-1:0]io_clic_ack_int[0:NCPU-1];

	wire          [63:0]io_timer;

	genvar I;

`ifdef AWS_DEBUG
	wire [NCPU-1:0]cpu_trig;
	wire [NCPU-1:0]cpu_trig_ack;
	wire [NCPU-1:0]trig_in;
	wire [NCPU-1:0]trig_in_ack;
	wire		   xxtrig;
`endif
	generate
		for (I = 0; I < NCPU; I=I+1) begin: c
			wire [2:0]sub_cpu=I;
			cpu #(.NPHYS(NPHYS), .NHART(NHART), .NLDSTQ(NLDSTQ), .TRANS_ID_SIZE(TRANS_ID_SIZE), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .CACHE_LINE_SIZE(CACHE_LINE_SIZE), .NINTERRUPTS(NINTERRUPTS))cpu(.clk(clk), .reset(reset),
				.reset_out(reset_out_c[I]),
				.cpu_id({cpu_id, sub_cpu}),
`ifdef SIMD
				.simd_enable(simd_enable),
`endif
`ifdef AWS_DEBUG
	            .cpu_trig(cpu_trig[I]),
				.cpu_trig_ack(cpu_trig_ack[I]),
	            .trig_in(trig_in[I]),
				.trig_in_ack(trig_in_ack[I]),
				.xxtrig(xxtrig),
`endif

				.ic_raddr(ic_raddr[I]),
				.ic_raddr_req(ic_raddr_req[I]),
				.ic_raddr_ack(ic_raddr_ack[I]),
				.ic_raddr_trans(ic_raddr_trans[I]),
				.ic_raddr_snoop(ic_raddr_snoop[I]),
				.ic_rdata(ic_rdata[I]),
				.ic_rdata_req(ic_rdata_req[I]),
				.ic_rdata_ack(ic_rdata_ack[I]),
				.ic_rdata_trans(ic_rdata_trans[I]),
				.ic_rdata_resp(ic_rdata_resp[I]),
				.ic_snoop_addr(ic_snoop_addr[I]),
				.ic_snoop_addr_req(ic_snoop_addr_req[I]),
				.ic_snoop_addr_ack(ic_snoop_addr_ack[I]),
				.ic_snoop_snoop(ic_snoop_snoop[I]),
				.ic_snoop_data_resp(ic_snoop_data_resp[I]),

				.dc_raddr(dc_raddr[I]),
				.dc_raddr_req(dc_raddr_req[I]),
				.dc_raddr_ack(dc_raddr_ack[I]),
				.dc_raddr_trans(dc_raddr_trans[I]),
				.dc_raddr_snoop(dc_raddr_snoop[I]),
				.dc_rdata(dc_rdata[I]),
				.dc_rdata_trans(dc_rdata_trans[I]),
				.dc_rdata_req(dc_rdata_req[I]),
				.dc_rdata_ack(dc_rdata_ack[I]),
				.dc_rdata_resp(dc_rdata_resp[I]),
				.dc_waddr(dc_waddr[I]),
				.dc_waddr_req(dc_waddr_req[I]),
				.dc_waddr_ack(dc_waddr_ack[I]),
				.dc_waddr_snoop(dc_waddr_snoop[I]),
				.dc_waddr_trans(dc_waddr_trans[I]),
				.dc_wdata(dc_wdata[I]),
				.dc_wdata_trans(dc_wdata_trans[I]),
				.dc_wdata_done(dc_wdata_done[I]),
				.dc_snoop_addr(dc_snoop_addr[I]),
				.dc_snoop_addr_req(dc_snoop_addr_req[I]),
				.dc_snoop_addr_ack(dc_snoop_addr_ack[I]),
				.dc_snoop_snoop(dc_snoop_snoop[I]),
				.dc_snoop_data_resp(dc_snoop_data_resp[I]),
				.dc_snoop_data(dc_snoop_data[I]),

				.io_cpu_addr_req(io_cpu_addr_req[I]),
				.io_cpu_addr_ack(io_cpu_addr_ack[I]),
				.io_cpu_addr(io_cpu_addr[I]),
				.io_cpu_read(io_cpu_read[I]),
				.io_cpu_lock(io_cpu_lock[I]),
				.io_cpu_mask(io_cpu_mask[I]),
				.io_cpu_wdata(io_cpu_wdata[I]),
				.io_cpu_data_req(io_cpu_data_req[I]),
				.io_cpu_data_ack(io_cpu_data_ack[I]),
				.io_cpu_rdata(io_cpu_rdata[I]),
				.io_cpu_data_err(io_cpu_data_err[I]),

				.io_clic_m_enable(io_clic_m_enable[I]),
				.io_clic_h_enable(io_clic_h_enable[I]),
				.io_clic_s_enable(io_clic_s_enable[I]),
				.io_clic_u_enable(io_clic_u_enable[I]),
				.io_clic_m_il(io_clic_m_il[I]),
				.io_clic_m_int(io_clic_m_int[I]),
				.io_clic_m_pending(io_clic_m_pending[I]),
				.io_clic_m_vec(io_clic_m_vec[I]),
				.io_clic_h_il(io_clic_h_il[I]),
				.io_clic_h_int(io_clic_h_int[I]),
				.io_clic_h_pending(io_clic_h_pending[I]),
				.io_clic_h_vec(io_clic_h_vec[I]),
				.io_clic_s_il(io_clic_s_il[I]),
				.io_clic_s_int(io_clic_s_int[I]),
				.io_clic_s_pending(io_clic_s_pending[I]),
				.io_clic_s_vec(io_clic_s_vec[I]),
				.io_clic_u_il(io_clic_u_il[I]),
				.io_clic_u_int(io_clic_u_int[I]),
				.io_clic_u_pending(io_clic_u_pending[I]),
				.io_clic_u_vec(io_clic_u_vec[I]),
				.io_clic_ack(io_clic_ack[I]),
				.io_clic_ack_int(io_clic_ack_int[I]),
				.io_timer(io_timer),
				.io_interrupts(io_interrupts[I])
				);
		end
	endgenerate

    wire  [NPHYS-1:ACACHE_LINE_SIZE]mem_raddr;
    wire        mem_raddr_ack;
    wire   [TSIZE-1:0]mem_raddr_trans;
    wire        mem_raddr_req;
    wire [CACHE_LINE_SIZE-1:0]mem_rdata;
    wire   [TSIZE-1:0]mem_rdata_trans;
    wire        mem_rdata_ack;
    wire        mem_rdata_req;
    wire  [NPHYS-1:ACACHE_LINE_SIZE]mem_waddr;
    wire [CACHE_LINE_SIZE-1:0]mem_wdata;
    wire   [TSIZE-1:0]mem_waddr_trans;
    wire        mem_waddr_req;
    wire        mem_waddr_ack;
    wire   [TSIZE-1:0]mem_wdata_trans;
    wire        mem_wdata_done;

`ifdef AWS_DEBUG
    wire mi_trig_out, mi_trig_out_ack;
`endif

	mem_interconnect #(.NPHYS(NPHYS), .NLDSTQ(NLDSTQ), .TRANS_ID_SIZE(TRANS_ID_SIZE), .TSIZE(TSIZE), .NI(NI), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .CACHE_LINE_SIZE(CACHE_LINE_SIZE))inter_connect(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
         .trig_in(cpu_trig[0]),
         .trig_in_ack(cpu_trig_ack[0]),
         .trig_out(mi_trig_out),
         .trig_out_ack(mi_trig_out_ack),
		.xxtrig(xxtrig),
`endif

		.ic0_raddr(ic_raddr[0]),
		.ic0_raddr_req(ic_raddr_req[0]),
		.ic0_raddr_ack(ic_raddr_ack[0]),
		.ic0_raddr_trans(ic_raddr_trans[0]),
		.ic0_raddr_snoop(ic_raddr_snoop[0]),
		.ic0_rdata(ic_rdata[0]),
		.ic0_rdata_req(ic_rdata_req[0]),
		.ic0_rdata_ack(ic_rdata_ack[0]),
		.ic0_rdata_trans(ic_rdata_trans[0]),
		.ic0_rdata_resp(ic_rdata_resp[0]),
		.ic0_snoop_addr(ic_snoop_addr[0]),
		.ic0_snoop_addr_req(ic_snoop_addr_req[0]),
		.ic0_snoop_addr_ack(ic_snoop_addr_ack[0]),
		.ic0_snoop_snoop(ic_snoop_snoop[0]),
		.ic0_snoop_data_resp(ic_snoop_data_resp[0]),

		.dc0_raddr(dc_raddr[0]),
		.dc0_raddr_req(dc_raddr_req[0]),
		.dc0_raddr_ack(dc_raddr_ack[0]),
		.dc0_raddr_trans(dc_raddr_trans[0]),
		.dc0_raddr_snoop(dc_raddr_snoop[0]),
		.dc0_rdata(dc_rdata[0]),
		.dc0_rdata_trans(dc_rdata_trans[0]),
		.dc0_rdata_req(dc_rdata_req[0]),
		.dc0_rdata_ack(dc_rdata_ack[0]),
		.dc0_rdata_resp(dc_rdata_resp[0]),
		.dc0_waddr(dc_waddr[0]),
		.dc0_waddr_req(dc_waddr_req[0]),
		.dc0_waddr_ack(dc_waddr_ack[0]),
		.dc0_waddr_trans(dc_waddr_trans[0]),
		.dc0_waddr_snoop(dc_waddr_snoop[0]),
		.dc0_wdata(dc_wdata[0]),
		.dc0_wdata_trans(dc_wdata_trans[0]),
		.dc0_wdata_done(dc_wdata_done[0]),
		.dc0_snoop_addr(dc_snoop_addr[0]),
		.dc0_snoop_addr_req(dc_snoop_addr_req[0]),
		.dc0_snoop_addr_ack(dc_snoop_addr_ack[0]),
		.dc0_snoop_snoop(dc_snoop_snoop[0]),
		.dc0_snoop_data_resp(dc_snoop_data_resp[0]),
		.dc0_snoop_data(dc_snoop_data[0]),


		.mem_raddr(mem_raddr),
		.mem_raddr_ack(mem_raddr_ack),
		.mem_raddr_trans(mem_raddr_trans),
		.mem_raddr_req(mem_raddr_req),
		.mem_rdata(mem_rdata),
		.mem_rdata_trans(mem_rdata_trans),
		.mem_rdata_ack(mem_rdata_ack),
		.mem_rdata_req(mem_rdata_req),
		.mem_waddr(mem_waddr),
		.mem_wdata(mem_wdata),
		.mem_waddr_trans(mem_waddr_trans),
		.mem_waddr_req(mem_waddr_req),
		.mem_waddr_ack(mem_waddr_ack),
		.mem_wdata_trans(mem_wdata_trans),
		.mem_wdata_done(mem_wdata_done),
		.dummy(1'b0)
		);

	mem_interface #(.NPHYS(NPHYS), .NLDSTQ(NLDSTQ), .TRANS_ID_SIZE(TRANS_ID_SIZE), .TSIZE(TSIZE), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .CACHE_LINE_SIZE(CACHE_LINE_SIZE))mem(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
		.xxtrig(xxtrig),
`endif
`ifdef SIMD
				.simd_enable(simd_enable),
`endif
`ifdef AWS_DEBUG
	    .cpu_trig(mi_trig_out),
		.cpu_trig_ack(mi_trig_out_ack),
	    .trig_in(trig_in[0]),
		.trig_in_ack(trig_in_ack[0]),
`endif
		.mem_raddr(mem_raddr),
		.mem_raddr_ack(mem_raddr_ack),
		.mem_raddr_trans(mem_raddr_trans),
		.mem_raddr_req(mem_raddr_req),
		.mem_rdata(mem_rdata),
		.mem_rdata_trans(mem_rdata_trans),
		.mem_rdata_ack(mem_rdata_ack),
		.mem_rdata_req(mem_rdata_req),
		.mem_waddr(mem_waddr),
		.mem_wdata(mem_wdata),
		.mem_waddr_trans(mem_waddr_trans),
		.mem_waddr_req(mem_waddr_req),
		.mem_waddr_ack(mem_waddr_ack),
		.mem_wdata_trans(mem_wdata_trans),
		.mem_wdata_done(mem_wdata_done)
`ifdef VS2
		,
		.sh_cl_clk(sh_cl_clk),
		.sh_cl_reset(sh_cl_reset),
		.cl_sh_ddr_awvalid(cl_sh_ddr_awvalid),
		.sh_cl_ddr_awready(sh_cl_ddr_awready),
		.cl_sh_ddr_awaddr(cl_sh_ddr_awaddr),
		.cl_sh_ddr_awid(cl_sh_ddr_awid),

		.cl_sh_ddr_wvalid(cl_sh_ddr_wvalid),
		.sh_cl_ddr_wready(sh_cl_ddr_wready),
		.cl_sh_ddr_wid(cl_sh_ddr_wid),
		.cl_sh_ddr_wdata(cl_sh_ddr_wdata),

        .sh_cl_ddr_bid(sh_cl_ddr_bid),
        .sh_cl_ddr_bresp(sh_cl_ddr_bresp),
        .sh_cl_ddr_bvalid(sh_cl_ddr_bvalid),
        .cl_sh_ddr_bready(cl_sh_ddr_bready),

		.cl_sh_ddr_arvalid(cl_sh_ddr_arvalid),
		.sh_cl_ddr_arready(sh_cl_ddr_arready),
		.cl_sh_ddr_arid(cl_sh_ddr_arid),
		.cl_sh_ddr_araddr(cl_sh_ddr_araddr),
		
		.cl_sh_ddr_rready(cl_sh_ddr_rready),
		.sh_cl_ddr_rvalid(sh_cl_ddr_rvalid),
		.sh_cl_ddr_rid(sh_cl_ddr_rid),
		.sh_cl_ddr_rdata(sh_cl_ddr_rdata)
`endif
		);

	parameter NIOCLIENTS=2;
	wire                io_addr_req;
	wire[NIOCLIENTS-1:0]io_addr_ack=0;
	wire	 [NPHYS-1:0]io_addr;
	wire	            io_read;
	wire           [7:0]io_mask;
	wire        [RV-1:0]io_wdata;
	wire[NIOCLIENTS-1:0]io_data_req=0;
	wire                io_data_ack;
	wire	    [RV-1:0]io_rdata[0:NIOCLIENTS];
	assign io_rdata[0]=0;
	assign io_rdata[1]=0;
	reg	        [RV-1:0]io_rdatav;
	wire[NIOCLIENTS-1:0]io_data_err=0;
	
	always @(*) begin	// FIXME
		casez(io_data_req)	// synthesis full_case parallel_case
		2'b?1:	io_rdatav = io_rdata[0];
		2'b1?:	io_rdatav = io_rdata[1];
		endcase
	end

	assign io_addr_ack = 0;
	assign io_data_req = 0;

	ioi #(.NPHYS(NPHYS), .NHART(NHART), .RV(RV), .NCPU(NCPU), .NIOCLIENTS(NIOCLIENTS), .NINTERRUPTS(NINTERRUPTS))io_switch(.clk(clk), .reset(reset),

`ifdef SIMD
		.simd_enable(simd_enable),
`endif
`ifdef AWS_DEBUG
		.xxtrig(xxtrig),
`endif
		.io_cpu_addr_req_0(io_cpu_addr_req[0]),
		.io_cpu_addr_ack_0(io_cpu_addr_ack[0]),
		.io_cpu_addr_0(io_cpu_addr[0]),
		.io_cpu_read_0(io_cpu_read[0]),
		.io_cpu_lock_0(io_cpu_lock[0]),
		.io_cpu_mask_0(io_cpu_mask[0]),
		.io_cpu_wdata_0(io_cpu_wdata[0]),
		.io_cpu_data_req_0(io_cpu_data_req[0]),
		.io_cpu_data_ack_0(io_cpu_data_ack[0]),
		.io_cpu_rdata_0(io_cpu_rdata[0]),
		.io_cpu_data_err_0(io_cpu_data_err[0]),

		//.io_cpu_addr_req_1(io_cpu_addr_req[1]),
		//.io_cpu_addr_ack_1(io_cpu_addr_ack[1]),
		//.io_cpu_addr_1(io_cpu_addr[1]),
		//.io_cpu_read_1(io_cpu_read[1]),
		//.io_cpu_lock_1(io_cpu_lock[1]),
		//.io_cpu_mask_1(io_cpu_mask[1]),
		//.io_cpu_wdata_1(io_cpu_wdata[1]),
		//.io_cpu_data_req_1(io_cpu_data_req[1]),
		//.io_cpu_data_ack_1(io_cpu_data_ack[1]),
		//.io_cpu_rdata_1(io_cpu_rdata[1]),
		//.io_cpu_data_err_1(io_cpu_data_err[1]),

		.io_addr_req(io_addr_req),
		.io_addr_ack(io_addr_ack),
		.io_addr(io_addr),
		.io_read(io_read),
		.io_mask(io_mask),
		.io_wdata(io_wdata),
		.io_data_req(io_data_req),
		.io_data_ack(io_data_ack),
		.io_rdata(io_rdatav),
		.io_data_err(io_data_err),

		.io_clic_m_enable_0(io_clic_m_enable[0]),
		.io_clic_h_enable_0(io_clic_h_enable[0]),
		.io_clic_s_enable_0(io_clic_s_enable[0]),
		.io_clic_u_enable_0(io_clic_u_enable[0]),
		.io_clic_m_il_0(io_clic_m_il[0]),
		.io_clic_m_int_0(io_clic_m_int[0]),
		.io_clic_m_pending_0(io_clic_m_pending[0]),
		.io_clic_m_vec_0(io_clic_m_vec[0]),
		.io_clic_h_il_0(io_clic_h_il[0]),
		.io_clic_h_int_0(io_clic_h_int[0]),
		.io_clic_h_pending_0(io_clic_h_pending[0]),
		.io_clic_h_vec_0(io_clic_h_vec[0]),
		.io_clic_s_il_0(io_clic_s_il[0]),
		.io_clic_s_int_0(io_clic_s_int[0]),
		.io_clic_s_pending_0(io_clic_s_pending[0]),
		.io_clic_s_vec_0(io_clic_s_vec[0]),
		.io_clic_u_il_0(io_clic_u_il[0]),
		.io_clic_u_int_0(io_clic_u_int[0]),
		.io_clic_u_pending_0(io_clic_u_pending[0]),
		.io_clic_u_vec_0(io_clic_u_vec[0]),
		.io_interrupts_0(io_interrupts[0]),
		.io_clic_ack_0(io_clic_ack[0]),
		.io_clic_ack_int_0(io_clic_ack_int[0]),

		//.io_clic_m_enable_1(io_clic_m_enable[1]),
		//.io_clic_h_enable_1(io_clic_h_enable[1]),
		//.io_clic_s_enable_1(io_clic_s_enable[1]),
		//.io_clic_u_enable_1(io_clic_u_enable[1]),
		//.io_clic_m_il_1(io_clic_m_il[1]),
		//.io_clic_m_int_1(io_clic_m_int[1]),
		//.io_clic_m_pending_1(io_clic_m_pending[1]),
		//.io_clic_m_vec_1(io_clic_m_vec[1]),
		//.io_clic_h_il_1(io_clic_h_il[1]),
		//.io_clic_h_int_1(io_clic_h_int[1]),
		//.io_clic_h_pending_1(io_clic_h_pending[1]),
		//.io_clic_h_vec_1(io_clic_h_vec[1]),
		//.io_clic_s_il_1(io_clic_s_il[1]),
		//.io_clic_s_int_1(io_clic_s_int[1]),
		//.io_clic_s_pending_1(io_clic_s_pending[1]),
		//.io_clic_s_vec_1(io_clic_s_vec[1]),
		//.io_clic_u_il_1(io_clic_u_il[1]),
		//.io_clic_u_int_1(io_clic_u_int[1]),
		//.io_clic_u_pending_1(io_clic_u_pending[1]),
		//.io_clic_u_vec_1(io_clic_u_vec[1]),
		//.io_interrupts_1(io_interrupts[1]),
		//.io_clic_ack_1(io_clic_ack[1]),
		//.io_clic_ack_int_1(io_clic_ack_int[1]),

		.io_timer(io_timer),

		.uart_tx(uart_tx),
		.uart_rx(uart_rx),
		.uart_rts(uart_rts),
		.uart_cts(uart_cts),

`ifndef VS2
		.block_count_0(block_count_0),
		.block_addr_0(block_addr_0),
		.block_count_1(block_count_1),
		.block_addr_1(block_addr_1),
`endif
		.gpio_pads(gpio_pads),

`ifdef VS2
		// AWS SD interface
		.sd_clk(sd_clk),
		.sd_reset(sd_reset),
		.sd_command_start(sd_command_start),
		.sd_command_done(sd_command_done),
		.sd_read(sd_read),
		.sd_address(sd_address),
		.sd_out_write(sd_out_write),
		.sd_out(sd_out),
		.sd_out_full(sd_out_full),
		.sd_in_read(sd_in_read),
		.sd_in(sd_in),
		.sd_in_empty(sd_in_empty),
`endif

		.dummy(1'b0));

endmodule
/* For Emacs:
 * Local Variables:
 * mode:c
 * indent-tabs-mode:t
 * tab-width:4
 * c-basic-offset:4
 * End:
 * For VIM:
 * vim:set softtabstop=4 shiftwidth=4 tabstop=4:
 */

