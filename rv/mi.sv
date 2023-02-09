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


//
//	Note: FIXME - there's a known problem here with flow control when we run out of available memeory read transaction
//		  at the moment by setting NMEMTRANS >= NLDSTQ - that's not a real fix, since this whole area is up for a
//		  full rewrite when we do L2 this is just a temporary bandaid
//

module mem_interconnect(	// interconnect
	input clk,
	input reset,

`ifdef AWS_DEBUG
	input  trig_in,
	output trig_in_ack,
	output trig_out,
	input  trig_out_ack,
	input  xxtrig,
`endif
	//-------

    input [NPHYS-1:ACACHE_LINE_SIZE]ic0_raddr,
    input       ic0_raddr_req,
    output      ic0_raddr_ack,
	input  [TRANS_ID_SIZE-1:0]ic0_raddr_trans,
	input  [2:0]ic0_raddr_snoop,

    output [CACHE_LINE_SIZE-1:0]ic0_rdata,
    output      ic0_rdata_req,
    input       ic0_rdata_ack,
	output [TRANS_ID_SIZE-1:0]ic0_rdata_trans,
	output [2:0]ic0_rdata_resp,

	output[NPHYS-1:ACACHE_LINE_SIZE]ic0_snoop_addr,
	output	    ic0_snoop_addr_req,
	input	    ic0_snoop_addr_ack,
	output [1:0]ic0_snoop_snoop,

	input  [2:0]ic0_snoop_data_resp,	// the clock after the ic0_snoop_addr_req
	//input [CACHE_LINE_SIZE-1:0]ic0_snoop_data,

	//-------

    input [NPHYS-1:ACACHE_LINE_SIZE]dc0_raddr,
    input       dc0_raddr_req,
    output      dc0_raddr_ack,
	input  [TRANS_ID_SIZE-1:0]dc0_raddr_trans,
	input  [2:0]dc0_raddr_snoop,

    output [CACHE_LINE_SIZE-1:0]dc0_rdata,
	output [TRANS_ID_SIZE-1:0]dc0_rdata_trans,
    output      dc0_rdata_req,
    input       dc0_rdata_ack,
	output [2:0]dc0_rdata_resp,

    input [NPHYS-1:ACACHE_LINE_SIZE]dc0_waddr,
    input       dc0_waddr_req,
    output      dc0_waddr_ack,
	input  [TRANS_ID_SIZE-1:0]dc0_waddr_trans,
    input  [1:0]dc0_waddr_snoop,
    input [CACHE_LINE_SIZE-1:0]dc0_wdata,

	output   [TRANS_ID_SIZE-1:0]dc0_wdata_trans,
	output	     dc0_wdata_done,

	output[NPHYS-1:ACACHE_LINE_SIZE]dc0_snoop_addr,
	output	    dc0_snoop_addr_req,
	input	    dc0_snoop_addr_ack,
	output [1:0]dc0_snoop_snoop,

	input  [2:0]dc0_snoop_data_resp,	// the clock after the dc0_snoop_addr_req
	input [CACHE_LINE_SIZE-1:0]dc0_snoop_data,

	//-------

	output [NPHYS-1:ACACHE_LINE_SIZE]mem_raddr,
    output       mem_raddr_req,
	output  [RTSIZE-1:0]mem_raddr_trans,
    input        mem_raddr_ack,

    input [CACHE_LINE_SIZE-1:0]mem_rdata,
	input   [RTSIZE-1:0]mem_rdata_trans,
    output       mem_rdata_ack,
    input        mem_rdata_req,

    output [NPHYS-1:ACACHE_LINE_SIZE]mem_waddr,
    output      [CACHE_LINE_SIZE-1:0]mem_wdata,
	output				 [WTSIZE-1:0]mem_waddr_trans,
    output							 mem_waddr_req,
    input							 mem_waddr_ack,

	input  [WTSIZE-1:0]mem_wdata_trans,
	input			   mem_wdata_done,

		dummy);

`include "cache_protocol.si"

	parameter NI = 2;
	parameter NPHYS = 48;
	parameter CACHE_LINE_SIZE = 512;
	parameter ACACHE_LINE_SIZE = 6;
	parameter NLDSTQ = 8;
	parameter TRANS_ID_SIZE = 6;
	parameter RTSIZE=8;
	parameter WTSIZE=TRANS_ID_SIZE+$clog2(NI);

	// --------------------------------
	
	wire [NPHYS-1:ACACHE_LINE_SIZE]raddr[0:NI-1];
	assign raddr[0] = ic0_raddr;
	assign raddr[1] = dc0_raddr;
	reg  [NI-1:0]r_raddr_ack, c_raddr_ack;
    assign ic0_raddr_ack = r_raddr_ack[0];
    assign dc0_raddr_ack = r_raddr_ack[1];
	wire [NI-1:0]raddr_req;
	assign raddr_req[0] = ic0_raddr_req;
	assign raddr_req[1] = dc0_raddr_req;
	wire [2:0]raddr_snoop[0:NI-1];
	assign raddr_snoop[0] = ic0_raddr_snoop;
	assign raddr_snoop[1] = dc0_raddr_snoop;
	wire [TRANS_ID_SIZE-1:0]raddr_trans[0:NI-1];
	assign raddr_trans[0] = ic0_raddr_trans;
	assign raddr_trans[1] = dc0_raddr_trans;

	wire	[NI-1:0]raddr_cancel;

	reg [CACHE_LINE_SIZE-1:0]r_rdata[0:NI-1];
	reg [CACHE_LINE_SIZE-1:0]c_rdata[0:NI-1];
	assign ic0_rdata = r_rdata[0];
	assign dc0_rdata = r_rdata[1];
	reg [NI-1:0]r_rdata_req, c_rdata_req;
	assign ic0_rdata_req = r_rdata_req[0];
	assign dc0_rdata_req = r_rdata_req[1];
	wire [NI-1:0]rdata_ack;
	assign rdata_ack[0] = ic0_rdata_ack;
	assign rdata_ack[1] = dc0_rdata_ack;
	reg [TRANS_ID_SIZE-1:0]r_rdata_trans[0:NI-1];
	reg [TRANS_ID_SIZE-1:0]c_rdata_trans[0:NI-1];
	assign ic0_rdata_trans = r_rdata_trans[0];
	assign dc0_rdata_trans = r_rdata_trans[1];
	reg [2:0]r_rdata_resp[0:NI-1];
	reg [2:0]c_rdata_resp[0:NI-1];
	assign ic0_rdata_resp = r_rdata_resp[0];
	assign dc0_rdata_resp = r_rdata_resp[1];


	// --------------------------------
	
	
	wire [NI-1:0]has_write_interface;
	assign has_write_interface[0] = 0;	// icache doesn't write
	assign has_write_interface[1] = 1;

	wire [NPHYS-1:ACACHE_LINE_SIZE]waddr[0:NI-1];
	assign waddr[0] = 50'bx;
	assign waddr[1] = dc0_waddr;
	wire [NI-1:0]waddr_req;
	assign waddr_req[0] = 0;
	assign waddr_req[1] = dc0_waddr_req;
	reg  [NI-1:0]r_waddr_ack, c_waddr_ack;
    assign dc0_waddr_ack = r_waddr_ack[1];
	wire [1:0]waddr_snoop[0:NI-1];
	assign waddr_snoop[0] = 2'bx;
	assign waddr_snoop[1] = dc0_waddr_snoop;
	wire [TRANS_ID_SIZE-1:0]waddr_trans[0:NI-1];
	assign waddr_trans[0] = 3'bx;
	assign waddr_trans[1] = dc0_waddr_trans;
    wire [CACHE_LINE_SIZE-1:0]wdata[0:NI-1];
	assign wdata[0] = 512'bx;
	assign wdata[1] = dc0_wdata;


	reg [NI-1:0]r_wdata_done, c_wdata_done;
	assign dc0_wdata_done = r_wdata_done[1];
	reg [TRANS_ID_SIZE-1:0]r_wdata_trans[0:NI-1];
	reg [TRANS_ID_SIZE-1:0]c_wdata_trans[0:NI-1];
	assign dc0_wdata_trans = r_wdata_trans[1];

	// --------------------------------
	
	wire [NI-1:0]snoop_interface;
	assign snoop_interface[0] = 1;
	assign snoop_interface[1] = 1;
	wire [NI-1:0]snoop_interface_read_only;
	assign snoop_interface_read_only[0] = 1;
	assign snoop_interface_read_only[1] = 0;
	reg [NPHYS-1:ACACHE_LINE_SIZE]r_snoop_addr;
	reg [NPHYS-1:ACACHE_LINE_SIZE]c_snoop_addr;
	assign ic0_snoop_addr = r_snoop_addr;
	assign dc0_snoop_addr = r_snoop_addr;
	reg [NI-1:0]r_snoop_addr_req, c_snoop_addr_req;
	assign ic0_snoop_addr_req = r_snoop_addr_req[0];
	assign dc0_snoop_addr_req = r_snoop_addr_req[1];
	wire [NI-1:0]snoop_addr_ack;
	assign snoop_addr_ack[0] = ic0_snoop_addr_ack;
	assign snoop_addr_ack[1] = dc0_snoop_addr_ack;
	reg [NI-1:0]r_snoop_data_req, c_snoop_data_req;
	reg [1:0]r_snoop_snoop, c_snoop_snoop;
	assign ic0_snoop_snoop = r_snoop_snoop;
	assign dc0_snoop_snoop = r_snoop_snoop;

	wire  [2:0]snoop_data_resp[0:NI-1];
	assign  snoop_data_resp[0] = ic0_snoop_data_resp;
	assign  snoop_data_resp[1] = dc0_snoop_data_resp;
	wire [CACHE_LINE_SIZE-1:0]snoop_data[0:NI-1];
	assign snoop_data[0] = 512'bx;
	assign snoop_data[1] = dc0_snoop_data;

	// --------------------------------

	reg [$clog2(NI)-1:0]r_sn_last, c_sn_last;
	reg [NI-1:0]r_snoop_rd_current, c_snoop_rd_current;
	reg [NI-1:0]r_snoop_wr_current, c_snoop_wr_current;
	reg [NI-1:0]r_snoop_rd_current2;
	reg [NI-1:0]r_snoop_wr_current2;
	

	reg		[1:0]r_snoop_rd_type[0:NI-1];
	reg		[1:0]c_snoop_rd_type[0:NI-1];
	reg		[1:0]c_snoop_wr_type[0:NI-1];
	reg	 [NI-1:0]r_snoop_rd_request, c_snoop_rd_request;
	reg	 [NI-1:0]r_snoop_wr_request, c_snoop_wr_request;
	reg  [NI-1:0]snoop_rd_ack;
	reg  [NI-1:0]snoop_wr_ack;

	reg	   [NPHYS-1:ACACHE_LINE_SIZE]r_raddr[0:NI-1];
	reg	   [NPHYS-1:ACACHE_LINE_SIZE]c_raddr[0:NI-1];
	reg	   [NPHYS-1:ACACHE_LINE_SIZE]r_waddr[0:NI-1];
	reg	   [NPHYS-1:ACACHE_LINE_SIZE]c_waddr[0:NI-1];
	reg	   [TRANS_ID_SIZE-1:0]r_raddr_trans[0:NI-1];
	reg	   [TRANS_ID_SIZE-1:0]c_raddr_trans[0:NI-1];
	reg	   [TRANS_ID_SIZE-1:0]r_waddr_trans[0:NI-1];
	reg	   [TRANS_ID_SIZE-1:0]c_waddr_trans[0:NI-1];
	reg	   [2:0]r_raddr_snoop[0:NI-1];
	reg	   [2:0]c_raddr_snoop[0:NI-1];
	reg	   [1:0]r_waddr_snoop[0:NI-1];
	reg	   [1:0]c_waddr_snoop[0:NI-1];
	reg	 [CACHE_LINE_SIZE-1:0]r_wdata[0:NI-1];
wire [CACHE_LINE_SIZE-1:0]r_wdata_1=r_wdata[1];
	reg	 [CACHE_LINE_SIZE-1:0]c_wdata[0:NI-1];
	reg	 [CACHE_LINE_SIZE-1:0]snoop_d;
	reg	 [2:0]snoop_r;

	reg			r_snoop_start_req, c_snoop_start_req;
	reg			r_next_snoop_data_valid, c_next_snoop_data_valid;

	// snoop arbiter
	always @(*) begin
		// FIXME - make this generic
		if (r_snoop_addr_req==0 || (r_snoop_addr_req&snoop_addr_ack) == r_snoop_addr_req) begin
			c_snoop_start_req = c_snoop_rd_request || c_snoop_wr_request;
			casez ({snoop_retry, r_sn_last, c_snoop_rd_request, c_snoop_wr_request}) // synthesis full_case parallel_case
			default:		begin
								c_snoop_addr = 'bx;
								c_snoop_snoop = 'bx;
								c_snoop_rd_current = 'bx;
								c_snoop_wr_current = 'bx;
								c_snoop_addr_req = 'bx;
								c_sn_last = 'bx;
							end
			6'b1_?_??_??:	begin
								c_snoop_addr = r_snoop_addr;
								c_snoop_snoop = r_snoop_snoop;
								c_snoop_rd_current = r_snoop_rd_current;
								c_snoop_wr_current = r_snoop_wr_current;
								c_snoop_addr_req = r_snoop_addr_req;
								c_sn_last = r_sn_last;
							end
			6'b?_0_??_?1:	begin
								c_snoop_addr = c_waddr[0];
								c_snoop_snoop = c_snoop_wr_type[0];
								c_snoop_rd_current = 2'b00;
								c_snoop_wr_current = 2'b01;
								c_snoop_addr_req = ~c_snoop_wr_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_0_??_10:	begin
								c_snoop_addr = c_waddr[1];
								c_snoop_snoop = c_snoop_wr_type[1];
								c_snoop_rd_current = 2'b00;
								c_snoop_wr_current = 2'b10;
								c_snoop_addr_req = ~c_snoop_wr_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_0_?1_00:	begin
								c_snoop_addr = c_raddr[0];
								c_snoop_snoop = c_snoop_rd_type[0];
								c_snoop_rd_current = 2'b01;
								c_snoop_wr_current = 2'b00;
								c_snoop_addr_req = ~c_snoop_rd_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_0_10_00:	begin
								c_snoop_addr = c_raddr[1];
								c_snoop_snoop = c_snoop_rd_type[1];
								c_snoop_rd_current = 2'b10;
								c_snoop_wr_current = 2'b00;
								c_snoop_addr_req = ~c_snoop_rd_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_1_??_01:	begin
								c_snoop_addr = c_waddr[0];
								c_snoop_snoop = c_snoop_wr_type[0];
								c_snoop_rd_current = 2'b00;
								c_snoop_wr_current = 2'b01;
								c_snoop_addr_req = ~c_snoop_wr_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_1_??_1?:	begin
								c_snoop_addr = c_waddr[1];
								c_snoop_snoop = c_snoop_wr_type[1];
								c_snoop_rd_current = 2'b00;
								c_snoop_wr_current = 2'b10;
								c_snoop_addr_req = ~c_snoop_wr_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_1_01_00:	begin
								c_snoop_addr = c_raddr[0];
								c_snoop_snoop = c_snoop_rd_type[0];
								c_snoop_rd_current = 2'b01;
								c_snoop_wr_current = 2'b00;
								c_snoop_addr_req = ~c_snoop_rd_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_1_1?_00:	begin
								c_snoop_addr = c_raddr[1];
								c_snoop_snoop = c_snoop_rd_type[1];
								c_snoop_rd_current = 2'b10;
								c_snoop_wr_current = 2'b00;
								c_snoop_addr_req = ~c_snoop_rd_current;
								c_sn_last = r_sn_last+1;
							end
			6'b?_?_00_00:	begin
								c_snoop_addr = 50'bx;
								c_snoop_addr_req = 0;
								c_snoop_snoop = r_snoop_snoop;
								c_snoop_rd_current = 2'b00;
								c_snoop_wr_current = 2'b00;
								c_snoop_start_req = 0;
								c_sn_last = r_sn_last;
							end
			endcase
		end else begin
			c_snoop_start_req = 0;
			c_snoop_addr = r_snoop_addr;
			c_snoop_addr_req = r_snoop_addr_req&~snoop_addr_ack;
			c_snoop_snoop = r_snoop_snoop;
			c_snoop_rd_current = r_snoop_rd_current;
			c_snoop_wr_current = r_snoop_wr_current;
			c_sn_last = r_sn_last;
		end
	end

	always @(*) begin
		// snoop takes 1 or 2 clocks max, it starts to be valid 1 clock after
		c_snoop_data_req = (reset?0:r_snoop_start_req?r_snoop_addr_req: r_snoop_data_req);
		//c_next_snoop_data_valid = (r_snoop_start_req ? r_snoop_addr_req !=0 && (r_snoop_addr_req&snoop_addr_ack) == r_snoop_addr_req: r_snoop_addr_req!=0);
		//c_next_snoop_data_valid = r_snoop_addr_req !=0 && (r_snoop_addr_req&snoop_addr_ack) == r_snoop_addr_req;
		c_next_snoop_data_valid = r_snoop_addr_req !=0 && (r_snoop_addr_req&snoop_addr_ack) == r_snoop_addr_req && !snoop_retry;
									
		if (r_next_snoop_data_valid) begin
			snoop_rd_ack = r_snoop_rd_current2;
			snoop_wr_ack = r_snoop_wr_current2;
		end else begin
			snoop_rd_ack = 0;
			snoop_wr_ack = 0;
		end
		casez ({(r_snoop_data_req[1]?snoop_data_resp[1]:3'b0), (r_snoop_data_req[0]?snoop_data_resp[0]:3'b0)}) // synthesis full_case parallel_case
		6'b1??_???:	begin snoop_r = snoop_data_resp[1]; snoop_d = snoop_data[1]; end
		6'b0??_1??:	begin snoop_r = snoop_data_resp[0]; snoop_d = snoop_data[0]; end
		6'b01?_0??:	begin snoop_r = snoop_data_resp[1]; snoop_d = snoop_data[1]; end
		6'b00?_01?:	begin snoop_r = snoop_data_resp[0]; snoop_d = snoop_data[0]; end
		6'b001_00?:	begin snoop_r = snoop_data_resp[1]; snoop_d = snoop_data[1]; end
		6'b000_001:	begin snoop_r = snoop_data_resp[0]; snoop_d = snoop_data[0]; end
		6'b000_000: begin snoop_r = 0; snoop_d = 512'bx; end
		default: begin snoop_r = 1'bx; snoop_d = 512'bx; end
		endcase
	end

	always @(posedge clk) begin
		r_snoop_start_req <= c_snoop_start_req;
		if (reset) begin
			r_snoop_addr_req <= 0;
		end else begin
			r_snoop_addr_req <= c_snoop_addr_req;
		end
		r_sn_last <= (reset?0:c_sn_last);
		r_snoop_rd_current <= c_snoop_rd_current;
		r_snoop_wr_current <= c_snoop_wr_current;
		r_snoop_rd_current2 <= r_snoop_rd_current;
		r_snoop_wr_current2 <= r_snoop_wr_current;
		r_snoop_data_req <= c_snoop_data_req;
		r_snoop_snoop <= c_snoop_snoop;
		r_snoop_addr <= c_snoop_addr;
		r_next_snoop_data_valid <= c_next_snoop_data_valid;
	end

	//
	//	memory state machine
	//
	//parameter NMEMTRANS	= 8;	// number of concurrent memory transactions
	//reg	 [NMEMTRANS-1:0]r_mem_active, c_mem_active;
	//reg    [NPHYS-1:ACACHE_LINE_SIZE]r_mem_addr[0:NMEMTRANS-1];
	//reg    [NPHYS-1:ACACHE_LINE_SIZE]c_mem_addr[0:NMEMTRANS-1];
	
	reg [NPHYS-1:ACACHE_LINE_SIZE]mem_raddr_out;
	assign mem_raddr = mem_raddr_out;
	reg [RTSIZE-1:0]mem_raddr_trans_out;
	reg [TSIZE-1:0]mem_raddr_req_trans;
	assign mem_raddr_trans = mem_raddr_trans_out;
	reg    mem_raddr_req_out;
	wire    mem_raddr_req_ok;
	assign mem_raddr_req = mem_raddr_req_out&&mem_raddr_req_ok;

	reg [NI-1:0]mem_rdata_ack_out;
	assign mem_rdata_ack = mem_rdata_ack_out == interface_rdone_pending;
	
	reg [NPHYS-1:ACACHE_LINE_SIZE]mem_waddr_out;
	assign mem_waddr = mem_waddr_out;
	reg [WTSIZE-1:0]mem_waddr_trans_out;
	assign mem_waddr_trans = mem_waddr_trans_out;
	reg    mem_waddr_req_out;
	assign mem_waddr_req = mem_waddr_req_out;
	reg [CACHE_LINE_SIZE-1:0]mem_wdata_out;
	assign mem_wdata = mem_wdata_out;

	 reg [NI-1:0]r_mem_rd_req, c_mem_rd_req;
	 reg [NI-1:0]r_mem_wr_req, c_mem_wr_req;

	reg [$clog2(NI)-1:0]r_rmem_next, c_rmem_next;
	reg [$clog2(NI)-1:0]r_wmem_next, c_wmem_next;
	reg [NI-1:0]mem_rd_ack;
	reg [NI-1:0]mem_wr_ack;
	reg [1:0]r_write_pending[0:NI-1];
	reg [1:0]c_write_pending[0:NI-1];
wire [1:0]r_write_pending_1=r_write_pending[1];
	reg [NI-1:0]r_rd_mem_pending, c_rd_mem_pending;

	//parameter NMEM_RTRANS=8;
	parameter NMEM_RTRANS=RTSIZE;
	parameter TSIZE=TRANS_ID_SIZE+$clog2(NI);
	reg [NMEM_RTRANS-1:0]r_pending_mem_read_valid, c_pending_mem_read_valid;
	reg [NMEM_RTRANS-1:0]r_pending_mem_read_cancel, c_pending_mem_read_cancel;
	reg [NMEM_RTRANS-1:0]r_pending_mem_read_exclusive, c_pending_mem_read_exclusive;
	reg [NMEM_RTRANS-1:0]r_pending_mem_read_indir, c_pending_mem_read_indir;
	reg [NPHYS-1:0]r_pending_mem_read_addr[0:NMEM_RTRANS-1];
	reg [NPHYS-1:0]c_pending_mem_read_addr[0:NMEM_RTRANS-1];
	reg [RTSIZE-1:0]r_pending_mem_read_trans[0:NMEM_RTRANS-1];
	reg [RTSIZE-1:0]c_pending_mem_read_trans[0:NMEM_RTRANS-1];
	reg [TSIZE-1:0]r_pending_mem_read_itrans[0:NMEM_RTRANS-1];
wire [TSIZE-1:0]pending_mem_read_itrans_0 = r_pending_mem_read_itrans[0];
wire [TSIZE-1:0]pending_mem_read_itrans_1 = r_pending_mem_read_itrans[1];
wire [TSIZE-1:0]pending_mem_read_itrans_2 = r_pending_mem_read_itrans[2];
wire [TSIZE-1:0]pending_mem_read_itrans_3 = r_pending_mem_read_itrans[3];
wire [TSIZE-1:0]pending_mem_read_trans_0 = r_pending_mem_read_trans[0];
wire [TSIZE-1:0]pending_mem_read_trans_1 = r_pending_mem_read_trans[1];
wire [TSIZE-1:0]pending_mem_read_trans_2 = r_pending_mem_read_trans[2];
wire [TSIZE-1:0]pending_mem_read_trans_3 = r_pending_mem_read_trans[3];
	reg [TSIZE-1:0]c_pending_mem_read_itrans[0:NMEM_RTRANS-1];
	wire [NMEM_RTRANS-1:0]match_snoop_pending;
	wire [NMEM_RTRANS-1:0]match_snoop_pending_done;
	reg r_snoop_retry;
	always @(posedge clk)
		r_snoop_retry <= !reset&&|match_snoop_pending_done;
	wire snoop_retry = |match_snoop_pending_done | r_snoop_retry;
	reg [NPHYS-1:0]data_mem_read_addr;
	if (RTSIZE == 8) begin
		always @(*)
		casez(mem_rdata_trans) // synthesis full_case parallel_case
		8'b????_???1: data_mem_read_addr = r_pending_mem_read_addr[0];
		8'b????_??1?: data_mem_read_addr = r_pending_mem_read_addr[1];
		8'b????_?1??: data_mem_read_addr = r_pending_mem_read_addr[2];
		8'b????_1???: data_mem_read_addr = r_pending_mem_read_addr[3];
		8'b???1_????: data_mem_read_addr = r_pending_mem_read_addr[4];
		8'b??1?_????: data_mem_read_addr = r_pending_mem_read_addr[5];
		8'b?1??_????: data_mem_read_addr = r_pending_mem_read_addr[6];
		8'b1???_????: data_mem_read_addr = r_pending_mem_read_addr[7];
		endcase
	end
	wire snoop_collision =	|r_rdata_req && |r_snoop_addr_req && ic0_snoop_addr == data_mem_read_addr;
	wire [NMEM_RTRANS-1:0]match_pending;
	wire [NMEM_RTRANS-1:0]match_pending_not_cancelled;
	wire [NMEM_RTRANS-1:0]match_pending_done;
	wire [NMEM_RTRANS-1:0]match_pending_done_not_cancelled;
	reg [TRANS_ID_SIZE-1:0]interface_rdone_trans_interface[0:NI-1];
wire [TRANS_ID_SIZE-1:0]interface_rdone_trans_interface_0 = interface_rdone_trans_interface[0];
wire [TRANS_ID_SIZE-1:0]interface_rdone_trans_interface_1 = interface_rdone_trans_interface[1];
	reg [NI-1:0]interface_rdone_pending;
	reg [NMEM_RTRANS-1:0]mem_raddr_req_ok_x;
	assign mem_raddr_req_ok = |mem_raddr_req_ok_x;

	
	wire [NMEM_RTRANS-1:0]next_rtrans;
	wire [NI-1:0]mem_addr_matches_done;

	genvar I, M, Q;
	
	generate 

		for (I = 0; I < NI; I=I+1) begin

			wire [NMEM_RTRANS-1:0]macc;

			for (M = 0; M < NMEM_RTRANS; M=M+1) begin
				assign macc[M] = r_pending_mem_read_valid[M] && r_raddr[I] == r_pending_mem_read_addr[M] && |(mem_rdata_trans&r_pending_mem_read_trans[M]) && !r_pending_mem_read_cancel[M] && mem_rdata_req;
			end

			assign mem_addr_matches_done[I] = |macc;


			assign raddr_cancel[I] = raddr_snoop[I]==RSNOOP_READ_CANCEL;
		end
		
		for (M = 0; M < NMEM_RTRANS; M=M+1) begin
			if (M == 0) begin
				assign next_rtrans[M] = !r_pending_mem_read_valid[M];
			end else begin:s
				wire [M-1:0]z = 0;
				assign next_rtrans[M] = r_pending_mem_read_valid[M:0] == {1'b0, ~z};
			end
			always @(*) begin
				mem_raddr_req_ok_x[M] = 0;
				c_pending_mem_read_valid[M] = r_pending_mem_read_valid[M];
				c_pending_mem_read_cancel[M] = r_pending_mem_read_cancel[M];
				c_pending_mem_read_addr[M] = r_pending_mem_read_addr[M];
				c_pending_mem_read_exclusive[M] = r_pending_mem_read_exclusive[M];
				c_pending_mem_read_trans[M] = r_pending_mem_read_trans[M];
				c_pending_mem_read_itrans[M] = r_pending_mem_read_itrans[M];
				c_pending_mem_read_indir[M] = r_pending_mem_read_indir[M];
				if (reset) begin
					c_pending_mem_read_valid[M] = 0;
					c_pending_mem_read_cancel[M] = 0;
				end else
				if (mem_raddr_req_out && mem_raddr_ack && !r_pending_mem_read_valid[M]) begin
					if (next_rtrans[M]) begin
						c_pending_mem_read_valid[M] = 1;
						c_pending_mem_read_cancel[M] = 0;
						c_pending_mem_read_addr[M] = mem_raddr_out;
						c_pending_mem_read_itrans[M] = mem_raddr_req_trans;
						casez (match_pending_not_cancelled) // synthesis full_case parallel_case
						8'b1???_????:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[7];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b?1??_????:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[6];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b??1?_????:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[5];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b???1_????:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[4];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b????_1???:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[3];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b????_?1??:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[2];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b????_??1?:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[1];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b????_???1:begin
										c_pending_mem_read_exclusive[M] = 0;
										c_pending_mem_read_trans[M] = r_pending_mem_read_trans[0];
										c_pending_mem_read_indir[M] = 1;
									end
						8'b0000_0000: begin
									c_pending_mem_read_trans[M] = mem_raddr_trans_out;
									//c_pending_mem_read_exclusive[M] = mem_raddr_trans_out[TRANS_ID_SIZE];
									c_pending_mem_read_exclusive[M] = mem_raddr_trans_out[TRANS_ID_SIZE];
									c_pending_mem_read_indir[M] = 0;
									mem_raddr_req_ok_x[M] = 1;
								 end
						endcase
					end else
					if (match_pending[M]) begin
						c_pending_mem_read_exclusive[M] = 0;
					end
				end else
				if ((mem_rdata_req && |(mem_rdata_trans&r_pending_mem_read_trans[M]) &&  (mem_rdata_ack_out[r_pending_mem_read_itrans[M][TSIZE-1:TRANS_ID_SIZE]]|| r_pending_mem_read_cancel[M]))) begin
					c_pending_mem_read_valid[M] = 0;
				end else
				if (r_pending_mem_read_valid[M] && raddr_req[r_pending_mem_read_itrans[M][TSIZE-1:TRANS_ID_SIZE]] && r_raddr_ack[r_pending_mem_read_itrans[M][TSIZE-1:TRANS_ID_SIZE]] && raddr_cancel[r_pending_mem_read_itrans[M][TSIZE-1:TRANS_ID_SIZE]] && r_pending_mem_read_itrans[M][TRANS_ID_SIZE-1:0] == raddr_trans[r_pending_mem_read_itrans[M][TSIZE-1:TRANS_ID_SIZE]])  begin
					c_pending_mem_read_cancel[M] = 1;
				end else
				if (mem_raddr_req_out && mem_raddr_ack && match_pending[M]) begin
					c_pending_mem_read_exclusive[M] = 0;
				end
			end
			assign match_pending[M] = r_pending_mem_read_valid[M] && !r_pending_mem_read_indir[M] && (r_pending_mem_read_addr[M]==mem_raddr_out);
			assign match_pending_not_cancelled[M] = r_pending_mem_read_valid[M] && !r_pending_mem_read_cancel[M] && !r_pending_mem_read_indir[M] && (r_pending_mem_read_addr[M]==mem_raddr_out);
			assign match_snoop_pending[M] = r_pending_mem_read_valid[M] && !r_pending_mem_read_cancel[M] && !r_pending_mem_read_indir[M] && |r_snoop_addr_req &&  (r_pending_mem_read_addr[M]==r_snoop_addr);
			assign match_pending_done[M] = r_pending_mem_read_valid[M] && mem_rdata_req && |(mem_rdata_trans&r_pending_mem_read_trans[M]);
			assign match_pending_done_not_cancelled[M] = r_pending_mem_read_valid[M] && !r_pending_mem_read_cancel[M] && mem_rdata_req && |(mem_rdata_trans&r_pending_mem_read_trans[M]);
			assign match_snoop_pending_done[M] = match_snoop_pending[M] && match_pending_done[M];

			always @(posedge clk) begin
				r_pending_mem_read_valid[M] <= c_pending_mem_read_valid[M];
				r_pending_mem_read_cancel[M] <= c_pending_mem_read_cancel[M];
				r_pending_mem_read_exclusive[M] <= c_pending_mem_read_exclusive[M];
				r_pending_mem_read_addr[M] <= c_pending_mem_read_addr[M];
				r_pending_mem_read_trans[M] <= c_pending_mem_read_trans[M];
				r_pending_mem_read_itrans[M] <= c_pending_mem_read_itrans[M];
				r_pending_mem_read_indir[M] <= c_pending_mem_read_indir[M];
			end
		end
	
		wire match_pending_done_exclusive = |(match_pending_done&r_pending_mem_read_exclusive);

		for (I = 0; I < NI; I=I+1) begin
			always @(*)	begin // FIXME
				interface_rdone_pending[I] = |(match_pending_done_not_cancelled&
											{(r_pending_mem_read_itrans[7][TSIZE-1:TRANS_ID_SIZE]==I),
                                             (r_pending_mem_read_itrans[6][TSIZE-1:TRANS_ID_SIZE]==I),
                                             (r_pending_mem_read_itrans[5][TSIZE-1:TRANS_ID_SIZE]==I),
                                             (r_pending_mem_read_itrans[4][TSIZE-1:TRANS_ID_SIZE]==I),
											 (r_pending_mem_read_itrans[3][TSIZE-1:TRANS_ID_SIZE]==I),
                                             (r_pending_mem_read_itrans[2][TSIZE-1:TRANS_ID_SIZE]==I),
                                             (r_pending_mem_read_itrans[1][TSIZE-1:TRANS_ID_SIZE]==I),
                                             (r_pending_mem_read_itrans[0][TSIZE-1:TRANS_ID_SIZE]==I)});
				interface_rdone_trans_interface[I] = 'bx;
				casez(match_pending_done_not_cancelled&
										 { (r_pending_mem_read_itrans[7][TSIZE-1:TRANS_ID_SIZE]==I),
										   (r_pending_mem_read_itrans[6][TSIZE-1:TRANS_ID_SIZE]==I),
										   (r_pending_mem_read_itrans[5][TSIZE-1:TRANS_ID_SIZE]==I),
										   (r_pending_mem_read_itrans[4][TSIZE-1:TRANS_ID_SIZE]==I),
										   (r_pending_mem_read_itrans[3][TSIZE-1:TRANS_ID_SIZE]==I),
										   (r_pending_mem_read_itrans[2][TSIZE-1:TRANS_ID_SIZE]==I),
										   (r_pending_mem_read_itrans[1][TSIZE-1:TRANS_ID_SIZE]==I),
										   (r_pending_mem_read_itrans[0][TSIZE-1:TRANS_ID_SIZE]==I)}) // synthesis full_case parallel_case
				8'b1???_????:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[7][TRANS_ID_SIZE-1:0];
				8'b?1??_????:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[6][TRANS_ID_SIZE-1:0];
				8'b??1?_????:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[5][TRANS_ID_SIZE-1:0];
				8'b???1_????:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[4][TRANS_ID_SIZE-1:0];
				8'b????_1???:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[3][TRANS_ID_SIZE-1:0];
				8'b????_?1??:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[2][TRANS_ID_SIZE-1:0];
				8'b????_??1?:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[1][TRANS_ID_SIZE-1:0];
				8'b????_???1:	interface_rdone_trans_interface[I] = r_pending_mem_read_itrans[0][TRANS_ID_SIZE-1:0];
				endcase
			end
		end
	endgenerate

	always @(*) begin
		mem_rd_ack = 2'b00;
		mem_raddr_req_out = 0;
		c_rmem_next = (reset?0:r_rmem_next);
		mem_raddr_out = 50'bx;
		mem_raddr_trans_out = 'bx;
		mem_raddr_req_trans = 'bx;
		casez ({r_rmem_next, mem_raddr_ack, c_mem_rd_req}) // synthesis full_case parallel_case
		4'b?_0_??,	// do nothing
		4'b?_?_00:	;

		4'b0_1_?1,	// issue for channel 0
		4'b1_1_01:	begin
						mem_raddr_trans_out = next_rtrans; //{3'b0, r_raddr_trans[0]};
						mem_raddr_req_trans = {3'b0, r_raddr_trans[0]};
						mem_raddr_out = r_raddr[0];
						mem_raddr_req_out = !(snoop_rd_ack[0] && mem_addr_matches_done[0] && !(r_rdata_req[0] &&rdata_ack[0] && r_raddr_trans[0] == r_rdata_trans[0]));
						mem_rd_ack = 2'b01;
						c_rmem_next = r_rmem_next+1; // FIXME
					end
		
		4'b0_1_10,	// issue for channel 1
		4'b1_1_1?:	begin
						mem_raddr_trans_out = next_rtrans; //{3'b1, r_raddr_trans[1]};
						mem_raddr_req_trans = {3'b1, r_raddr_trans[1]};
						mem_raddr_out = r_raddr[1];
						mem_raddr_req_out = !(snoop_rd_ack[1] && mem_addr_matches_done[1] && !(r_rdata_req[1] &&rdata_ack[1] && r_raddr_trans[1] == r_rdata_trans[1]));
						mem_rd_ack = 2'b10;
						c_rmem_next = r_rmem_next+1; // FIXME
					end
		default:	begin
						mem_raddr_trans_out = 'bx;
						mem_raddr_out = 'bx;
						mem_raddr_req_out = 'bx;
						mem_rd_ack = 'bx;
						c_rmem_next = 'bx;
					end
		endcase
	end

	always @(*) begin
		casez ({r_wmem_next, mem_waddr_ack, r_mem_wr_req, has_write_interface}) // synthesis full_case parallel_case
		6'b?_0_??_??,	// do nothing
		6'b?_?_00_??,
		6'b?_1_?1_?0,
		6'b?_1_?1_?0,
		6'b?_1_1?_0?,	
		6'b?_1_1?_0?:begin
						mem_wr_ack = 2'b00;
						mem_waddr_req_out = 0;
						mem_waddr_out = 50'bx;
						mem_waddr_trans_out = 6'bx;
						mem_wdata_out = 512'bx;
						c_wmem_next = (reset?0:r_wmem_next);
					 end

		6'b0_1_?1_?1,	// issue for channel 0	(probably optimised out)
		6'b1_1_01_?1:begin
						mem_waddr_trans_out = {3'b0, r_waddr_trans[0]};
						mem_waddr_out = r_waddr[0];
						mem_waddr_req_out = 1;
						mem_wr_ack = 2'b01;
						mem_wdata_out = r_wdata[0];
						c_wmem_next = r_wmem_next+1; // FIXME
					end
		
		6'b0_1_10_1?,	// issue for channel 1
		6'b1_1_1?_1?:begin
						mem_waddr_trans_out = {3'b1, r_waddr_trans[1]};
						mem_waddr_out = r_waddr[1];
						mem_waddr_req_out = 1;
						mem_wr_ack = 2'b10;
						mem_wdata_out = r_wdata[1];
						c_wmem_next = r_wmem_next+1; // FIXME
					end
		default:	begin
						mem_waddr_trans_out = 'bx;
						mem_waddr_out = 'bx;
						mem_waddr_req_out = 'bx;
						mem_wr_ack = 'bx;
						mem_wdata_out = 'bx;
						c_wmem_next = 'bx;
					end
		endcase
	end

	always @(posedge clk) begin
		r_rmem_next <= c_rmem_next;
		r_wmem_next <= c_wmem_next;
	end

	//
	//	clients
	//
	reg [NI-1:0]srd_ack;
	reg [NI-1:0]srd_ack_inv;
	generate 
		for (I = 0; I < NI; I=I+1) begin:i

			always @(*)
			if (!has_write_interface[I]) begin
				c_waddr[I] = 50'bx;
				c_waddr_trans[I] = 3'bx;
				c_waddr_snoop[I] = 2'bx;
				c_snoop_wr_request[I] = 0;
				c_waddr_ack[I] = 1'bx;
				c_snoop_wr_type[I] = SNOOP_READ_INVALID;
				c_write_pending[I] = 2'bx;
				c_mem_wr_req[I] = 0;
				c_wdata[I] = 'bx;
			end else begin
				c_snoop_wr_type[I] = SNOOP_READ_INVALID;
				if (waddr_req[I] && r_waddr_ack[I]) begin
					c_waddr[I] = waddr[I];
					c_waddr_trans[I] = waddr_trans[I];
					c_waddr_snoop[I] = waddr_snoop[I];
					c_write_pending[I] = 2'b11;
					c_wdata[I] = wdata[I];
					c_mem_wr_req[I] = 1;
					c_snoop_wr_request[I] = 1;
					//case (waddr_snoop[I]) 
					//WSNOOP_WRITE_LINE:			begin
					//								c_snoop_wr_type[I] = SNOOP_READ_INVALID;
					//							end	
					//WSNOOP_WRITE_LINE_OWNED:	begin
					//								c_snoop_wr_type[I] = SNOOP_READ_INVALID;
					//							end
					//WSNOOP_WRITE_LINE_OWNED_L2:	begin
					//								c_snoop_wr_type[I] = SNOOP_READ_INVALID;
					//							end
					//endcase
				end else begin
					c_mem_wr_req[I] = r_mem_wr_req[I];
					c_snoop_wr_request[I] = (reset?0:r_snoop_wr_request[I]&~r_snoop_wr_current[I]);
					c_wdata[I] = r_wdata[I];
					c_waddr[I] = r_waddr[I];
					c_waddr_trans[I] = r_waddr_trans[I];
					c_waddr_snoop[I] = r_waddr_snoop[I];
					c_write_pending[I] = (reset?0:r_write_pending[I]);
				end
				if (snoop_wr_ack[I])
					c_write_pending[I][1] = 0; 
				if (mem_wr_ack[I])
					c_write_pending[I][0] = 0; 
				c_waddr_ack[I] = c_write_pending[I] == 2'b00;
			end

			always @(*)
			if (mem_wdata_done && (mem_wdata_trans[TSIZE-1:TRANS_ID_SIZE] == I)) begin
				c_wdata_trans[I] = mem_wdata_trans[TRANS_ID_SIZE-1:0];
				c_wdata_done[I] = 1;
			end else begin
				c_wdata_trans[I] = 3'bx;
				c_wdata_done[I] = 0;
			end

			always @(*) begin
				c_raddr_snoop[I] = r_raddr_snoop[I];
				c_raddr_trans[I] = r_raddr_trans[I];
				c_snoop_rd_type[I] = r_snoop_rd_type[I];
				c_snoop_rd_request[I] = (reset?0:r_snoop_rd_request[I]&~r_snoop_rd_current[I]);
				c_raddr_ack[I] = (reset?0:r_raddr_ack[I]);
				c_raddr[I] = r_raddr[I];
				c_rd_mem_pending[I] = (reset?0:r_rd_mem_pending[I]);;
				if (raddr_req[I] && r_raddr_ack[I] && !raddr_cancel[I]) begin
					c_raddr[I] = raddr[I];
					c_raddr_trans[I] = raddr_trans[I];
					//c_raddr_ack[I] = 0;
					c_raddr_snoop[I] = raddr_snoop[I];
					case (raddr_snoop[I])
					RSNOOP_READ_LINE:			begin
													c_snoop_rd_request[I] = 1;
													c_snoop_rd_type[I] = SNOOP_READ_UNSHARED;
												end	
					RSNOOP_READ_LINE_SHARED:	begin
													c_snoop_rd_request[I] = 1;
													c_snoop_rd_type[I] = SNOOP_READ_SHARED;
												end
					RSNOOP_READ_LINE_EXCLUSIVE:	begin
													c_snoop_rd_request[I] = 1;
													c_snoop_rd_type[I] = SNOOP_READ_EXCLUSIVE;
												end
					RSNOOP_READ_LINE_INV_SHARED:begin
													c_snoop_rd_request[I] = 1;
													c_snoop_rd_type[I] = SNOOP_READ_INVALID;
												end
					endcase
				end 
				if (snoop_rd_ack[I]) begin // && ((r_snoop_addr_req&snoop_addr_ack) == r_snoop_addr_req) && !snoop_retry) begin
					if (c_mem_rd_req[I] && (!mem_raddr_ack || mem_raddr_req_trans[TSIZE-1:TRANS_ID_SIZE] != I)) begin
						c_rd_mem_pending[I] = 1;
					end else begin
						c_raddr_ack[I] = 1;
					end
				end else
				if (r_rd_mem_pending[I] && mem_raddr_ack && mem_raddr_req_trans[TSIZE-1:TRANS_ID_SIZE] == I) begin
					c_raddr_ack[I] = 1;
					c_rd_mem_pending[I] = 0;
				end else
				if (raddr_req[I] && r_raddr_ack[I] && !raddr_cancel[I]) begin
					c_raddr_ack[I] = 0;
				end
			end

			always @(*) begin 
				srd_ack[I] = 0;
				srd_ack_inv[I] = 0;
				c_rdata_req[I] = 0;
				c_rdata[I] = r_rdata[I];
				c_rdata_trans[I] = r_rdata_trans[I];
				c_mem_rd_req[I] = r_mem_rd_req[I];
				c_rdata_resp[I] = r_rdata_resp[I];
				if (snoop_rd_ack[I]) begin // && ((r_snoop_addr_req&snoop_addr_ack) == r_snoop_addr_req) && !snoop_retry) begin
					case (r_raddr_snoop[I])
					RSNOOP_READ_LINE,
					RSNOOP_READ_LINE_SHARED,
					RSNOOP_READ_LINE_EXCLUSIVE:
						if (snoop_r[SNOOP_RESP_DATA_INCLUDED]) begin
							srd_ack[I] = 1;
						end else begin // make a memory access
							c_mem_rd_req[I] = 1;
						end
					RSNOOP_READ_LINE_INV_SHARED:
						begin
							srd_ack[I] = 1;
							srd_ack_inv[I] = 1;
						end
					default:;
					endcase
				end
				mem_rdata_ack_out[I] = 0;
				if (r_rdata_req[I] && !rdata_ack[I]) begin
					c_rdata_req[I] = 1;
					c_rdata[I] = r_rdata[I];
					c_rdata_resp[I] = r_rdata_resp[I];
				end else
				//if (srd_ack[I] && ~(|r_snoop_addr_req)) begin
				if (srd_ack[I]) begin
					c_rdata_req[I] = 1;
					c_rdata_trans[I] = r_raddr_trans[I];
					c_rdata_resp[I] = (srd_ack_inv[I]?3'b010:snoop_r);
					c_rdata[I] = snoop_d;
				end else 
				if (mem_rdata_req) begin
					if (interface_rdone_pending[I]) begin
						c_rdata_req[I] = 1;
						c_rdata_trans[I] = interface_rdone_trans_interface[I];
						if (match_pending_done_exclusive && !(|r_rd_mem_pending&&|(match_pending&match_pending_done)) && !(|(snoop_rd_ack&mem_addr_matches_done))) begin
							c_rdata_resp[I] = 3'b011;
						end else begin
							c_rdata_resp[I] = 3'b001;
						end
						c_rdata[I] = mem_rdata;
						mem_rdata_ack_out[I] = 1;
					end else
					if (r_rd_mem_pending[I] && !r_mem_rd_req[I] && |(match_pending&match_pending_done)) begin
						c_rdata_req[I] = 1;
						c_rdata_trans[I] = r_raddr_trans[I];
						c_rdata_resp[I] = 3'b001;
						c_rdata[I] = mem_rdata;
						mem_rdata_ack_out[I] = 1;
					end else
					if (snoop_rd_ack[I] && mem_addr_matches_done[I] && !(r_rdata_req[I] &&rdata_ack[I] && r_raddr_trans[I] == r_rdata_trans[I])) begin
						c_rdata_req[I] = 1;
						c_rdata_trans[I] = r_raddr_trans[I];
						c_rdata_resp[I] = 3'b001;
						c_rdata[I] = mem_rdata;
					end
				end
			end

			always @(posedge clk) begin
				if (reset) begin
					r_raddr_ack[I] <= 1;
					r_waddr_ack[I] <= 1;
					r_rdata_req[I] <= 0;
					r_wdata_done[I] <= 0;
				end else begin
					r_raddr_ack[I] <= c_raddr_ack[I];
					r_waddr_ack[I] <= c_waddr_ack[I];
					r_rdata_req[I] <= c_rdata_req[I];
					r_wdata_done[I] <= c_wdata_done[I];
				end
				r_mem_rd_req[I] <= c_mem_rd_req[I]&!reset&!mem_rd_ack[I];
				r_mem_wr_req[I] <= c_mem_wr_req[I]&!reset&!mem_wr_ack[I];
				r_snoop_rd_request[I] <= c_snoop_rd_request[I];
				r_snoop_rd_type[I] <= c_snoop_rd_type[I];
				r_snoop_wr_request[I] <= c_snoop_wr_request[I];
				r_raddr[I] <= c_raddr[I];
				r_rdata_trans[I] <= c_rdata_trans[I];
				r_raddr_snoop[I] <= c_raddr_snoop[I];
				r_raddr_trans[I] <= c_raddr_trans[I];
				r_rdata[I] <= c_rdata[I];
				r_rdata_resp[I] <= c_rdata_resp[I];
				r_waddr[I] <= c_waddr[I];
				r_waddr_snoop[I] <= c_waddr_snoop[I];
				r_waddr_trans[I] <= c_waddr_trans[I];
				r_wdata[I] <= c_wdata[I];
				r_wdata_trans[I] <= c_wdata_trans[I];
				r_write_pending[I] <= c_write_pending[I];
				r_rd_mem_pending[I] <= c_rd_mem_pending[I];
			end
		end
	endgenerate



`ifdef AWS_DEBUG
    ila_mi ila_mi(.clk(clk),
            .reset(reset),
			.trig_in(trig_in),
			.trig_in_ack(trig_in_ack),
			.trig_out(trig_out),
			.trig_out_ack(trig_out_ack),
            .mem_raddr(mem_raddr[23+ACACHE_LINE_SIZE:ACACHE_LINE_SIZE]),
            .mem_raddr_req(mem_raddr_req),
            .mem_raddr_ack(mem_raddr_ack),
            .mem_raddr_trans(mem_raddr_trans),
            .mem_rdata_req(mem_rdata_req),
            .mem_rdata_ack(mem_rdata_ack),
            .mem_rdata_trans(mem_rdata_trans),
            
            .ic0_raddr(ic0_raddr[23+ACACHE_LINE_SIZE:ACACHE_LINE_SIZE]),
            .ic0_raddr_req(ic0_raddr_req),
            .ic0_raddr_ack(ic0_raddr_ack),
            .ic0_raddr_trans(ic0_raddr_trans),
            .ic0_rdata_req(ic0_rdata_req),
            .ic0_rdata_ack(ic0_rdata_ack),
            .ic0_rdata_trans(ic0_rdata_trans),
            
            .ic0_snoop_addr_req(ic0_snoop_addr_req),
            .ic0_snoop_addr_ack(ic0_snoop_addr_ack),
            .ic0_snoop_addr_snoop(ic0_snoop_addr_snoop),
            .ic0_snoop_addr_resp(ic0_snoop_addr_resp),
            
            .dc0_raddr(dc0_raddr[23+ACACHE_LINE_SIZE:ACACHE_LINE_SIZE]),
            .dc0_raddr_req(dc0_raddr_req),
            .dc0_raddr_ack(dc0_raddr_ack),
            .dc0_raddr_trans(dc0_raddr_trans),
            .dc0_rdata_req(dc0_rdata_req),
            .dc0_rdata_ack(dc0_rdata_ack),
            .dc0_rdata_trans(dc0_rdata_trans),
            
            .dc0_snoop_addr_req(dc0_snoop_addr_req),
            .dc0_snoop_addr_ack(dc0_snoop_addr_ack),
            .dc0_snoop_addr_snoop(dc0_snoop_addr_snoop),
            .dc0_snoop_addr_resp(dc0_snoop_addr_resp),
            
            .r_pending_mem_read_valid(r_pending_mem_read_valid), // 8
            .r_pending_mem_read_exclusive(r_pending_mem_read_exclusive), //8
            .r_pending_mem_read_indir(r_pending_mem_read_indir), //8
            .r_pending_mem_read_trans({r_pending_mem_read_trans[7],r_pending_mem_read_trans[6],r_pending_mem_read_trans[5],r_pending_mem_read_trans[4], r_pending_mem_read_trans[3],r_pending_mem_read_trans[2],r_pending_mem_read_trans[1],r_pending_mem_read_trans[0]}),//48
            .r_pending_mem_read_itrans({r_pending_mem_read_itrans[7],r_pending_mem_read_itrans[6],r_pending_mem_read_itrans[5],r_pending_mem_read_itrans[4],r_pending_mem_read_itrans[3],r_pending_mem_read_itrans[2],r_pending_mem_read_itrans[1],r_pending_mem_read_itrans[0]}),//48

            .r_snoop_retry(r_snoop_retry), // 1
            .r_snoop_rd_current(r_snoop_rd_current), // 2
            .r_snoop_wr_current(r_snoop_wr_current), // 2
            .r_snoop_rd_current2(r_snoop_rd_current2), // 2
            .r_snoop_wr_current2(r_snoop_wr_current2), // 2
            .r_rmem_next(r_rmem_next), // 2
            .r_wmem_next(r_wmem_next), // 2
            .r_mem_rd_req(r_mem_rd_req), // 2
            .r_mem_wr_req(r_mem_wr_req), // 2
            .r_write_pending({r_write_pending[1],r_write_pending[0]}), // 4
            .r_rd_mem_pending(r_rd_mem_pending), // 2
            .mem_raddr_req_out(mem_raddr_req_out), // 1
            .mem_raddr_req_ok(mem_raddr_req_ok), // 1
            .interface_rdone_trans_interface_0(interface_rdone_trans_interface[0]), // 6
            .interface_rdone_trans_interface_1(interface_rdone_trans_interface[1]), // 6
            .match_pending(match_pending),  // 8
            .match_pending_done(match_pending_done),    // 8
            .match_pending_done_exclusive(match_pending_done_exclusive),
			.xxtrig(xxtrig)
            );
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


