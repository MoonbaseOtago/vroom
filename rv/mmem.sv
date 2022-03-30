//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-22 Paul Campbell - paul@taniwha.com
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

	);
	parameter NPHYS=56;
	parameter NLDSTQ=8;
	parameter TRANS_ID_SIZE=6;
	parameter CACHE_LINE_SIZE=64*8;
	parameter ACACHE_LINE_SIZE=$clog2(CACHE_LINE_SIZE/8);
	parameter MEM_SIZE=8*1024*1024;
	parameter TSIZE=5;

	reg r_mem_raddr_ack;
	assign mem_raddr_ack = r_mem_raddr_ack;
	reg 	r_mem_rdata_req;
	assign mem_rdata_req = r_mem_rdata_req;
	reg 	r_mem_waddr_ack;
	assign mem_waddr_ack = r_mem_waddr_ack;
	reg [CACHE_LINE_SIZE-1:0]r_mem_rdata;
	assign mem_rdata = r_mem_rdata;
	reg [TSIZE-1:0]r_mem_rdata_trans;
	assign mem_rdata_trans = r_mem_rdata_trans;

	reg	r_mem_wdata_done;
	assign mem_wdata_done = r_mem_wdata_done;
	reg [TSIZE-1:0]r_mem_wdata_trans;
	assign mem_wdata_trans = r_mem_wdata_trans; 

	reg [CACHE_LINE_SIZE-1:0]mem[0:MEM_SIZE-1];


	parameter NRTRANS=3;
	reg [NPHYS-1:ACACHE_LINE_SIZE]tr_raddr[0:NRTRANS-1];
	reg [TSIZE-1:0]tr_rtrans[0:NRTRANS-1];
	reg [7:0]tr_rcount[0:NRTRANS-1];
	reg [NRTRANS-1:0]tr_rbusy;

	parameter NWTRANS=3;
	reg [TSIZE-1:0]tr_wtrans[0:NWTRANS-1];
	reg [7:0]tr_wcount[0:NWTRANS-1];
	reg [NWTRANS-1:0]tr_wbusy;

	always @(posedge clk)
	if (reset) begin:i
		int i;
		r_mem_raddr_ack <= 1;
		r_mem_waddr_ack <= 1;
		r_mem_rdata_req <= 0;
		r_mem_wdata_done <= 0;
		for (i = 0; i < NRTRANS; i++)
			tr_rbusy[i] <= 0;
		for (i = 0; i < NWTRANS; i++)
			tr_wbusy[i] <= 0;
	end

	always @(posedge clk)
	if (mem_waddr_req && r_mem_waddr_ack) begin : w
		int i;
		reg found, free;
`ifdef SIMD
if (simd_enable) $display("%d mem write a=%x line=%x",$time,mem_waddr,mem_wdata);
`endif
        found = 0;
        free = 0;
		for (i = 0; i < NWTRANS; i++)
		if (!tr_wbusy[i]) begin
			if (found) begin
				free = 1;
			end else begin
				found = 1;
				tr_wbusy[i] <= 1;
				tr_wcount[i] <= 40;
				tr_wtrans[i] <= mem_waddr_trans;
				mem[mem_waddr[$clog2(MEM_SIZE)+ACACHE_LINE_SIZE-1:ACACHE_LINE_SIZE]] <= mem_wdata;
			end
		end
		if (!free && !r_mem_wdata_done)
	 		r_mem_waddr_ack <= 0;
	end else
	if (r_mem_wdata_done) begin
		r_mem_waddr_ack <= 1;
	end

	always @(posedge clk) begin :ww
		int i;
		reg found;

		found = 0;
		for (i = 0; i < NWTRANS; i++)
		if (tr_wbusy[i]) begin
			if (tr_wcount[i] == 0) begin
				if (!found) begin
					tr_wbusy[i] <= 0;
					r_mem_wdata_trans <= tr_wtrans[i];
					r_mem_wdata_done <= 1;
					found = 1;
				end
			end else begin
				tr_wcount[i] = tr_wcount[i]-1;
			end
		end 
		if (!found)
			r_mem_wdata_done <= 0;
	end

	always @(posedge clk)
	if (mem_raddr_req && r_mem_raddr_ack) begin: r
		int i; reg found, free;

		found = 0;
		free = 0;
		for (i = 0; i < NRTRANS; i++)
		if (!tr_rbusy[i]) begin
			if (found) begin
				free = 1;
			end else begin
				found = 1;
				tr_rbusy[i] <= 1;
				tr_rcount[i] <= 40;
				tr_rtrans[i] <= mem_raddr_trans;
				tr_raddr[i] <= mem_raddr;
			end
		end
	 	if (!free)
			r_mem_raddr_ack <= 0;
	end else
	if (r_mem_rdata_req && mem_rdata_ack) begin
		r_mem_raddr_ack <= 1;
	end


	int lastr;
	always @(posedge clk) begin :rr
		int i;
		reg found;
		reg req;
		int x;

		found = 0;
		x = -1;
		req = 0;
		req = r_mem_rdata_req;
		if (r_mem_rdata_req && mem_rdata_ack) begin
			tr_rbusy[lastr] <= 0;
			req = 0;
			x = lastr;
		end 
		for (i = 0; i < NRTRANS; i++) 
		if (tr_rbusy[i] && (i!=x)) begin
			if (tr_rcount[i] == 0 && !req) begin
				lastr = i;
				r_mem_rdata <= mem[tr_raddr[i][$clog2(MEM_SIZE)+ACACHE_LINE_SIZE-1:ACACHE_LINE_SIZE]];
`ifdef SIMD
if (simd_enable) $display("%d mem read a=%x line=%x",$time,tr_raddr[i],mem[tr_raddr[i][$clog2(MEM_SIZE)+ACACHE_LINE_SIZE-1:ACACHE_LINE_SIZE]]);
`endif
				r_mem_rdata_trans <= tr_rtrans[i];
				req = 1;
			end else begin
				tr_rcount[i] <= tr_rcount[i]-1;
			end
		end
		r_mem_rdata_req <= !reset&&req;
	end
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
