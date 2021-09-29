//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019 Paul Campbell - paul@taniwha.com
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

module mem_interface(
	input clk,
	input reset,
`ifdef SIMD
	input simd_enable,
`endif

`ifdef AWS_DEBUG
    input cpu_trig,
    output cpu_trig_ack,
    output trig_in,
    input trig_in_ack,
    input xxtrig,
`endif  


	input [NPHYS-1:ACACHE_LINE_SIZE]mem_raddr,
	input  [TSIZE-1:0]mem_raddr_trans,
	input	    mem_raddr_req,
	output	    mem_raddr_ack,

	output [CACHE_LINE_SIZE-1:0]mem_rdata,
	output   [TSIZE-1:0]mem_rdata_trans,
	output 	      mem_rdata_req,
	input 	      mem_rdata_ack,

	input [NPHYS-1:ACACHE_LINE_SIZE]mem_waddr,
	input  [TSIZE-1:0]mem_waddr_trans,
	input	    mem_waddr_req,
	output	    mem_waddr_ack,
	input [CACHE_LINE_SIZE-1:0]mem_wdata,

	output   [TSIZE-1:0]mem_wdata_trans,
	output 	     mem_wdata_done
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

	);
	parameter NPHYS=56;
	parameter NLDSTQ=8;
	parameter CACHE_LINE_SIZE=64*8;
	parameter ACACHE_LINE_SIZE=$clog2(CACHE_LINE_SIZE/8);
	parameter MEM_SIZE=8*1024*1024;
	parameter TSIZE=5;
	parameter TRANS_ID_SIZE=6;

`ifdef VS2
	wire [3:0]tag_match;
	reg	[3:0]avail;

	reg [55:6]r_mem_waddr;
	reg	[TSIZE-1:0]r_mem_wtrans;
	reg [511:0] r_mem_out;
	reg		  r_w_ready;
	assign cl_sh_ddr_awid = r_mem_wtrans; 
	assign cl_sh_ddr_awaddr = r_mem_waddr;
	assign cl_sh_ddr_wid = r_mem_wtrans;
	assign cl_sh_ddr_wdata = r_mem_out;

	reg r_w_out_signal, r_w_in_signal;
	wire synced_w_out_signal, synced_w_in_signal;

	synchoniser w_to(.clk(sh_cl_clk), .in(r_w_out_signal), .out(synced_w_out_signal));
	synchoniser w_from(.clk(clk), .in(r_w_in_signal), .out(synced_w_in_signal));

	always @(posedge clk)
	if (reset) begin
		r_w_ready <= 1;
		r_w_out_signal <= 0;
	end else
	if (r_w_ready && mem_waddr_req && |avail) begin
		r_w_ready <= 0;
		r_w_out_signal <= ~r_w_out_signal;
		r_mem_wtrans <= mem_waddr_trans;
		r_mem_out <= mem_wdata;
		r_mem_waddr <= mem_waddr;
	end else 
	if (r_w_out_signal == synced_w_in_signal) begin
		r_w_ready <= 1;
	end
	assign mem_waddr_ack = r_w_ready && |avail;
	reg r_cl_sh_ddr_awvalid, r_cl_sh_ddr_wvalid;
	assign cl_sh_ddr_awvalid = r_cl_sh_ddr_awvalid;
	assign cl_sh_ddr_wvalid = r_cl_sh_ddr_wvalid;

	reg r_w_running;
	always @(posedge sh_cl_clk)
	if (sh_cl_reset) begin
		r_w_in_signal <= 0;
		r_w_running <= 0;
		r_cl_sh_ddr_awvalid <= 0;
		r_cl_sh_ddr_wvalid <= 0;
	end else
	if (r_w_in_signal != synced_w_out_signal) begin
		if (!r_w_running) begin
			r_w_running <= 1;
			r_cl_sh_ddr_awvalid <= 1;
			r_cl_sh_ddr_wvalid <= 1;
		end else begin
			if (sh_cl_ddr_awready && r_cl_sh_ddr_awvalid)
				r_cl_sh_ddr_awvalid <= 0;
			if (sh_cl_ddr_wready && r_cl_sh_ddr_wvalid)
				r_cl_sh_ddr_wvalid <= 0;
			if ((sh_cl_ddr_awready||!r_cl_sh_ddr_awvalid) &&
				(sh_cl_ddr_wready||!r_cl_sh_ddr_wvalid)) begin
				r_w_in_signal <= synced_w_out_signal;
				r_w_running <= 0;
			end
		end
	end


	reg [55:6]r_mem_raddr;
	assign  cl_sh_ddr_araddr = r_mem_raddr;
	reg [TSIZE-1:0]r_mem_rtrans;
	assign cl_sh_ddr_arid = r_mem_rtrans;
	reg	r_r_running, r_r_out_signal;
	reg r_r_in_signal;

	wire	synced_r_out_signal, synced_r_in_signal;
	synchoniser r_to(.clk(sh_cl_clk), .in(r_r_out_signal), .out(synced_r_out_signal));
	synchoniser r_from(.clk(clk), .in(r_r_in_signal), .out(synced_r_in_signal));


	assign mem_raddr_ack = !r_r_running && !(mem_waddr==mem_raddr && mem_waddr_req && !mem_waddr_ack) && !(|tag_match);
	always @(posedge clk)
	if (reset) begin
		r_r_running <= 0;
		r_r_out_signal <= 0;
	end else 
	if (!r_r_running && mem_raddr_req && !(mem_waddr==mem_raddr && mem_waddr_req && !mem_waddr_ack) && !(|tag_match)) begin
		r_r_running <= 1;
		r_r_out_signal <= ~r_r_out_signal;
		r_mem_rtrans = mem_raddr_trans;
		r_mem_raddr <= mem_raddr;
	end else
	if (r_r_out_signal == synced_r_in_signal) begin
		r_r_running <= 0;
	end


	assign cl_sh_ddr_arvalid = r_r_in_signal != synced_r_out_signal;
	always @(posedge sh_cl_clk)
	if (sh_cl_reset) begin
		r_r_in_signal <= 0;
	end else
	if (r_r_in_signal != synced_r_out_signal && sh_cl_ddr_arready) begin
		r_r_in_signal <= synced_r_out_signal;
	end

// write done
	wire	synced_wdone_out_signal, synced_wdone_in_signal;
	reg		r_wdone_out_signal, r_wdone_ready, r_wdone_in_signal;
	assign  cl_sh_ddr_bready = r_wdone_ready;
	synchoniser wdone_to(.clk(clk), .in(r_wdone_out_signal), .out(synced_wdone_out_signal));
	synchoniser wdone_from(.clk(sh_cl_clk), .in(r_wdone_in_signal), .out(synced_wdone_in_signal));
	reg [TSIZE-1:0]r_wdone_trans_in;
	always @(posedge sh_cl_clk)
	if (reset) begin
		r_wdone_out_signal <= 0;
		r_wdone_ready <= 1;
	end else
	if (r_wdone_ready && sh_cl_ddr_bvalid) begin
		r_wdone_trans_in <= sh_cl_ddr_bid;
		r_wdone_ready <= 0;
		r_wdone_out_signal <= ~r_wdone_out_signal;
	end else
	if (r_wdone_out_signal == synced_wdone_in_signal) begin
		r_wdone_ready <= 1;
	end

	always @(posedge clk)
	if (reset) begin
		r_wdone_in_signal <= 0;
	end else
	if (r_wdone_in_signal != synced_wdone_out_signal) begin
		r_wdone_in_signal <= synced_wdone_out_signal;
	end

	reg [NPHYS-1:ACACHE_LINE_SIZE]r_wr_addr_tag[0:3];
	reg [3:0]r_wr_tag_valid;
	reg [4:0]r_wr_tag[0:3];

	always @(*) begin
		casez (r_wr_tag_valid) // synthesis full_case parallel_case
		4'b???0: avail = 4'b0001;
		4'b??01: avail = 4'b0010;
		4'b?011: avail = 4'b0100;
		4'b0111: avail = 4'b1000;
		default: avail = 0;
		endcase
	end
	genvar I;
	generate 
		for (I = 0; I < 3; I=I+1) begin
			assign tag_match[I] = r_wr_tag_valid[I] && r_wr_addr_tag[I] == mem_raddr;

			always @(posedge clk) 
			if (reset) begin
				r_wr_tag_valid[I] <= 0;
			end else 
			if (r_wdone_in_signal != synced_wdone_out_signal && r_wr_tag_valid[I] && r_wr_tag[I] == r_wdone_trans_in) begin
				r_wr_tag_valid[I] <= 0;
			end else 
			if (avail[I] && mem_waddr_req && mem_waddr_ack) begin
				r_wr_tag_valid[I] <= 1;
				r_wr_tag[I] <= mem_waddr_trans;
				r_wr_addr_tag[I] <= mem_waddr;
			end
		end
	endgenerate

// read done

	wire	synced_rd_out_signal, synced_rd_in_signal;
	reg		r_rd_out_signal, r_rd_ready, r_rd_in_signal;
	assign  cl_sh_ddr_rready = r_rd_ready;
	synchoniser rd_to(.clk(clk), .in(r_rd_out_signal), .out(synced_rd_out_signal));
	synchoniser rd_from(.clk(sh_cl_clk), .in(r_rd_in_signal), .out(synced_rd_in_signal));
	reg	[511:0]r_mem_in;
	reg [TSIZE-1:0]r_mem_rtrans_in;
	assign mem_rdata = r_mem_in;
	assign mem_rdata_trans = r_mem_rtrans_in;
	always @(posedge sh_cl_clk)
	if (reset) begin
		r_rd_out_signal <= 0;
		r_rd_ready <= 1;
	end else
	if (r_rd_ready && sh_cl_ddr_rvalid) begin
		r_mem_in <= sh_cl_ddr_rdata;
		r_mem_rtrans_in <= sh_cl_ddr_rid;
		r_rd_ready <= 0;
		r_rd_out_signal <= ~r_rd_out_signal;
	end else
	if (r_rd_out_signal == synced_rd_in_signal) begin
		r_rd_ready <= 1;
	end

	assign mem_rdata_req = r_rd_in_signal != synced_rd_out_signal;
	always @(posedge clk)
	if (reset) begin
		r_rd_in_signal <= 0;
	end else
	if (r_rd_in_signal != synced_rd_out_signal && mem_rdata_ack) begin
		r_rd_in_signal <= synced_rd_out_signal;
	end

`else
	assign mem_raddr_ack = 0;
	assign mem_rdata_req = 0;
	assign mem_waddr_ack = 0;
	assign mem_rdata = 0;
	assign mem_rdata_trans = 0;

	assign mem_wdata_done = 0;
	assign mem_wdata_trans = 0; 
`endif

`ifdef AWS_DEBUG
	ila_mem ila_mem(.clk(clk),
		.reset(reset),
        .xxtrig(xxtrig),
		.mem_raddr(mem_raddr[ACACHE_LINE_SIZE+23:ACACHE_LINE_SIZE]),
		.mem_raddr_req(mem_raddr_req),
		.mem_raddr_ack(mem_raddr_ack),
		.mem_raddr_trans(mem_raddr_trans),	// 4

		.mem_rdata(mem_rdata[63:0]),
		.mem_rdata_trans(mem_rdata_trans),
		.mem_rdata_req(mem_rdata_req),
		.mem_rdata_ack(mem_rdata_ack),

		.mem_waddr_req(mem_waddr_req),
		.mem_waddr_ack(mem_waddr_ack),
		.mem_waddr(mem_waddr[ACACHE_LINE_SIZE+23:ACACHE_LINE_SIZE]),
		.mem_waddr_trans(mem_waddr_trans[6-1:0]),

		.avail(avail), // 4
		.tag_match(tag_match), // 4
		.r_wr_tag_valid(r_wr_tag_valid), // 4

		.mem_wdata_done(mem_wdata_done),
		.mem_wdata_trans(mem_wdata_trans[6-1:0]),
	    .mem_wdata(mem_wdata[63:0])

	);
`endif

endmodule

module synchoniser(
	input	clk,
	input	in,
	output	out);

	parameter LEN=2;
`ifdef PSYNC
	HARD_SYNC #(.LATENCY(LEN))s(.CLK(clk).DIN(in),.DOUT(out));	// xilinx macro
`else
	reg [LEN-1:0]r_sync;
	assign out = r_sync[LEN-1];

	always @(posedge clk)
		r_sync <= {r_sync[LEN-2:0],in};
`endif
	
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
