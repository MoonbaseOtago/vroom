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

module tlb_fetcher(	// TLB cache second level control - 2 interfaces i$ and d$ 
    input reset,
    input clk,
`ifdef AWS_DEBUG
	input		xxtrig,
`endif

	input    [15:0]i_asid,				// i$ read port
	input[(NHART==1?0:LNHART-1):0]i_hart,
    input [VA_SZ-1:12]i_vaddr,			
	input		   i_addr_tid,
	input		   i_addr_req,
	output		   i_addr_ack,
	input		   i_addr_cancel,

	output		   i_data_req,			// i$ response
	output		   i_data_tid,
    output[VA_SZ-1:12]i_data_vaddr,
	output[NPHYS-1:12]i_paddr,
	output	 [3:0] i_gaux,
	output		   i_2mB,
	output		   i_4mB,
	output		   i_1gB,
	output		   i_512gB,
	output		   i_valid, 
	output		   i_pmp_fail, 

	input    [15:0]d_asid,				// d$ read port
	input[(NHART==1?0:LNHART-1):0]d_hart,
    input [VA_SZ-1:12]d_vaddr,
	input [LNCOMMIT-1:0]d_addr_tid,
	input		   d_addr_req,
	output		   d_addr_ack,
	input		   d_addr_cancel,

	output		   d_data_req,			// d$ response
	output[NPHYS-1:12]d_paddr,
	output[LNCOMMIT-1:0]d_data_tid,
    output   [15: 0]d_data_asid,
    output[VA_SZ-1:12]d_data_vaddr,
	output	 [6:0] d_gaduwrx,
	output		   d_2mB,
	output		   d_4mB,
	output		   d_1gB,
	output		   d_512gB,
	output		   d_valid,
	output		   d_pmp_fail,	// only valid if d_valid==0

	//	sup_vm_mode	[0] - off
	//				[1] - Sv-32
	//				[2] - Sv-39
	//				[3] - Sv-48

	input [ 3: 0]sup_vm_mode_0,
    input [15: 0]sup_asid_0,
    input [43: 0]sup_ppn_0,

	input [ 3: 0]sup_vm_mode_1,
    input [15: 0]sup_asid_1,
    input [43: 0]sup_ppn_1,

    input             wr_invalidate,
    input             wr_invalidate_addr,
    input [VA_SZ-1:12]wr_inv_vaddr,
    input             wr_invalidate_asid,
	input			  wr_inv_unified,
    input       [15:0]wr_inv_asid,

	input [NPHYS-1:ACACHE_LINE_SIZE]ic_snoop_addr,			// snoop port
	input 	    ic_snoop_addr_req,
	input  [1:0]ic_snoop_snoop,

	output		ic_addr_req,
	input		ic_addr_ack,
	input		ic_addr_fail,
	output	[NPHYS-1:2]ic_addr,
	output	[TRANS_ID_SIZE-2:0]ic_addr_trans,
	output		ic_addr_sz,

	input		ic_data_req,
	input [TRANS_ID_SIZE-2:0]ic_data_trans,
	input [CACHE_LINE_SIZE-1:0]ic_data,
	input dummy);

`include "cache_protocol.si"

	parameter RV=64;
	parameter VA_SZ=64;
	parameter ACACHE_LINE_SIZE=6;
	parameter CACHE_LINE_SIZE=64*8;		// 64 bytes   5:0	- 6 bits	32 bytes
	parameter NPHYS=56;
	parameter NHART=1;
	parameter LNHART=$clog2(NHART);
	parameter LNCOMMIT=5;
	parameter TRANS_ID_SIZE=6;

	parameter NTCACHE=5;	// (2/3 level of lookup plus 1/2 of PTE data)*number_of_harts*i/d
	
	//
	//		1 set per hart X
	//		2 sets for I/D X
	//		5 sets for Sv-48 levels	
	//		
	reg	[CACHE_LINE_SIZE-1:0]r_cache_line[0:NHART-1][0:1][0:NTCACHE-1];	// cache lines 
	reg	[NPHYS-1:ACACHE_LINE_SIZE]r_cache_tag[0:NHART-1][0:1][0:NTCACHE-1];	// cache lines 
	reg	     [NTCACHE-1:0]r_cache_valid[0:NHART-1][0:1];
	reg	     [NTCACHE-1:0]r_cache_busy[0:NHART-1][0:1];
	wire				  busy_cache, done_cache;

	wire would_ic_addr_req = r_mem_addr_req&&!(r_cancelling||cancel);
	genvar E, H, ID;
	generate 
		wire [NTCACHE-1:0]busyENTRY, doneENTRY;
		assign busy_cache = |busyENTRY;
		assign done_cache = |doneENTRY;
		for (E = 0; E < NTCACHE; E=E+1) begin
				wire [NHART-1:0]busyHART, doneHART;
				assign busyENTRY[E] = |busyHART;
				assign doneENTRY[E] = |doneHART;
			for (H = 0; H < NHART; H=H+1) begin
				wire [1:0]busyID, doneID;
				assign busyHART[H] = |busyID;
				assign doneHART[H] = |doneID;
				for (ID = 0; ID < 2; ID=ID+1) begin
					assign busyID[ID] = r_cache_busy[H][ID][E] && r_cache_tag[H][ID][E] == r_fetch_addr[NPHYS-1:ACACHE_LINE_SIZE];
					wire done_match = ic_data_req && E==ic_data_trans[$clog2(NTCACHE)-1:0] && H==ic_data_trans[$clog2(NTCACHE)+1] && ID==ic_data_trans[$clog2(NTCACHE)];
					assign doneID[ID] = busyID[ID] && done_match;
					always @(posedge clk) begin
						if (reset || (ic_snoop_addr_req && r_cache_valid[H][ID][E] && ic_snoop_addr == r_cache_tag[H][ID][E])) r_cache_valid[H][ID][E] <= 0; else
						if (would_ic_addr_req && E==ic_addr_trans[$clog2(NTCACHE)-1:0] && H==ic_addr_trans[$clog2(NTCACHE)+1] && ID==ic_addr_trans[$clog2(NTCACHE)]) r_cache_valid[H][ID][E] <= 0; else
						if (done_match || (done_cache && (busyID[ID]||(would_ic_addr_req && (busy_cache||ic_addr_ack) && E==ic_addr_trans[$clog2(NTCACHE)-1:0] && H==ic_addr_trans[$clog2(NTCACHE)+1] && ID==ic_addr_trans[$clog2(NTCACHE)])))) r_cache_valid[H][ID][E] <= 1;

						if (done_match || (done_cache && (busyID[ID]||(would_ic_addr_req && (busy_cache||ic_addr_ack) && E==ic_addr_trans[$clog2(NTCACHE)-1:0] && H==ic_addr_trans[$clog2(NTCACHE)+1] && ID==ic_addr_trans[$clog2(NTCACHE)])))) begin
							r_cache_line[H][ID][E] <= ic_data;
						end
						if (would_ic_addr_req && E==ic_addr_trans[$clog2(NTCACHE)-1:0] && H==ic_addr_trans[$clog2(NTCACHE)+1] && ID==ic_addr_trans[$clog2(NTCACHE)]) begin
							r_cache_tag[H][ID][E] <= r_fetch_addr[NPHYS-1:ACACHE_LINE_SIZE];
						end
						if (reset || done_match || (done_cache && busyID[ID])) begin
							r_cache_busy[H][ID][E] <= 0;
						end else
						if (would_ic_addr_req && (busy_cache||ic_addr_ack) && E==ic_addr_trans[$clog2(NTCACHE)-1:0] && H==ic_addr_trans[$clog2(NTCACHE)+1] && ID==ic_addr_trans[$clog2(NTCACHE)]) begin
							r_cache_busy[H][ID][E] <= !done_cache;
						end
					end
				end
			end
		end
	endgenerate

	reg [2:0]r_fetch_index, c_fetch_index;

	wire      [CACHE_LINE_SIZE-1:0]pte_line = r_cache_line[r_hart][r_req][r_fetch_index];
	wire [NPHYS-1:ACACHE_LINE_SIZE]pte_tag = r_cache_tag[r_hart][r_req][r_fetch_index];
	wire                           pte_valid = r_cache_valid[r_hart][r_req][r_fetch_index];
	reg [31:0]pte_32;
	reg [63:0]pte_64;

	reg [NPHYS-1:2]r_fetch_addr, c_fetch_addr;
	assign ic_addr = r_fetch_addr;
	assign ic_addr_sz = !r_32;
	always @(*) begin
		case (r_fetch_addr[5:2]) // synthesis full_case parallel_case
		0: pte_32 = pte_line[31:0];
		1: pte_32 = pte_line[63:32];
		2: pte_32 = pte_line[95:64];
		3: pte_32 = pte_line[127:96];
		4: pte_32 = pte_line[159:128];
		5: pte_32 = pte_line[191:160];
		6: pte_32 = pte_line[223:192];
		7: pte_32 = pte_line[255:224];
		8: pte_32 = pte_line[287:256];
		9: pte_32 = pte_line[319:288];
		10: pte_32 = pte_line[351:320];
		11: pte_32 = pte_line[383:352];
		12: pte_32 = pte_line[415:384];
		13: pte_32 = pte_line[447:416];
		14: pte_32 = pte_line[479:448];
		15: pte_32 = pte_line[511:480];
		endcase
	end
	always @(*) begin
		case (r_fetch_addr[5:3]) // synthesis full_case parallel_case
		0: pte_64 = pte_line[63:0];
		1: pte_64 = pte_line[127:64];
		2: pte_64 = pte_line[191:128];
		3: pte_64 = pte_line[255:192];
		4: pte_64 = pte_line[319:256];
		5: pte_64 = pte_line[383:320];
		6: pte_64 = pte_line[447:384];
		7: pte_64 = pte_line[511:448];
		endcase
	end

	wire [6:0]gaduwrx_32={pte_32[5],pte_32[6], pte_32[7],pte_32[4],pte_32[2],pte_32[1],pte_32[3]};
	wire	  valid_32 = pte_32[0];
	wire [21:12]ppn0_32 = pte_32[19:10];
	wire [33:22]ppn1_32 = pte_32[31:20];
	wire		indir_32 = pte_32[3:1]==0;

	wire [6:0]gaduwrx_64={pte_64[5],pte_64[6],pte_64[7],pte_64[4],pte_64[2],pte_64[1],pte_64[3]};
	wire	  valid_64 = pte_64[0];
	wire [20:12]ppn0_64 = pte_64[18:10];
	wire [29:21]ppn1_64 = pte_64[27:19];
	wire [38:30]ppn2_64 = pte_64[36:28];
	wire [55:39]ppn3_64 = pte_64[55:37];
	wire		indir_64 = pte_64[3:1]==0;

	reg				r_32, c_32;
	reg		   [1:0]r_64_fetch, c_64_fetch;
	wire		indir = (r_32?indir_32:indir_64);
	wire		valid = (r_32?valid_32:valid_64);
	wire   [6:0]gaduwrx = (r_32?gaduwrx_64:gaduwrx_32);

	wire [NPHYS-1:12]rpaddr;
	wire			 rhit, r2mB, r4mB, r1gB, r512gB;
	wire	    [6:0]rgaduwrx;

	reg		   [2:0]r_fstate, c_fstate;
    reg		  [15:0]r_asid, c_asid;
    reg		  [15:0]r_asid_p;
    reg[(NHART==1?0:LNHART-1):0]r_hart, c_hart;
    reg [VA_SZ-1:12]r_vaddr, c_vaddr;
    reg [VA_SZ-1:12]r_vaddr_p;
	reg				r_req, c_req;

	reg				r_d_data_req, c_d_data_req;
	reg				r_i_data_req, c_i_data_req;
	reg	[LNCOMMIT-1:0]r_tid, c_tid;
	reg	[LNCOMMIT-1:0]r_rtid, c_rtid;
	reg [NPHYS-1:12]r_paddr, c_paddr;
	reg	       [6:0]r_gaduwrx, c_gaduwrx;
	reg				r_2mB, c_2mB;
	reg				r_4mB, c_4mB;
	reg				r_1gB, c_1gB;
	reg				r_512gB, c_512gB;
	reg				r_valid, c_valid;
	reg				r_pmp_fail, c_pmp_fail;
	assign i_data_req = r_i_data_req;
	assign i_data_tid = r_rtid[0];
	assign i_data_vaddr = r_vaddr_p;
	assign i_paddr = r_paddr[NPHYS-1:12];
	assign i_gaux = {r_gaduwrx[6:5], r_gaduwrx[3], r_gaduwrx[0]};
	assign i_2mB = r_2mB;
	assign i_4mB = r_4mB;
	assign i_1gB = r_1gB;
	assign i_512gB = r_512gB;
	assign i_valid = r_valid;
	assign i_pmp_fail = r_pmp_fail;

	assign d_data_req = r_d_data_req;
	assign d_data_tid = r_rtid;
	assign d_data_asid = r_asid_p;
	assign d_data_vaddr = r_vaddr_p;
	assign d_paddr = r_paddr;
	assign d_gaduwrx = {r_gaduwrx[6:0]};
	assign d_2mB = r_2mB;
	assign d_4mB = r_4mB;
	assign d_1gB = r_1gB;
	assign d_512gB = r_512gB;
	assign d_valid = r_valid;
	assign d_pmp_fail = r_pmp_fail;
	reg			c_i_addr_ack;
	reg			c_d_addr_ack;
	assign i_addr_ack = c_i_addr_ack;
	assign d_addr_ack = c_d_addr_ack;

	reg		r_wr_entry, c_wr_entry;
	reg		r_mem_addr_req, c_mem_addr_req;
	assign ic_addr_req = would_ic_addr_req&&!busy_cache;
	assign ic_addr_trans = {r_hart, r_req, r_fetch_index};

	wire cancel = r_req?i_addr_cancel:d_addr_cancel;
	reg		r_cancelling, c_cancelling;

	always @(posedge clk) begin
		r_cancelling <= c_cancelling;
		r_pmp_fail <= c_pmp_fail;
		r_fstate <= c_fstate;
		r_asid <= c_asid;
		r_asid_p <= r_asid;
		r_hart <= c_hart;
		r_vaddr <= c_vaddr;
		r_vaddr_p <= r_vaddr;
		r_d_data_req <= c_d_data_req;
		r_i_data_req <= c_i_data_req;
		r_paddr <= c_paddr;
		r_gaduwrx <= c_gaduwrx;
		r_2mB <= c_2mB;
		r_4mB <= c_4mB;
		r_1gB <= c_1gB;
		r_512gB <= c_512gB;
		r_valid <= c_valid;
		r_fetch_addr <= c_fetch_addr;
		r_req <= c_req;
		r_32 <= c_32;
		r_64_fetch <= c_64_fetch;
		r_fetch_index <= c_fetch_index;
		r_wr_entry <= c_wr_entry;
		r_mem_addr_req <= c_mem_addr_req;
		r_tid <= c_tid;
		r_rtid <= c_rtid;
	end
	

	reg restart;
	always @(*) begin : xx

		restart = 0;
		c_cancelling = r_cancelling;
		c_pmp_fail = r_pmp_fail;
		c_32 = r_32;
		c_64_fetch = r_64_fetch;
		c_fetch_addr = r_fetch_addr;
		c_fetch_index = r_fetch_index;
		c_wr_entry = 0;
		c_d_addr_ack = 0;
		c_i_addr_ack = 0;
		c_d_data_req = 0;
		c_i_data_req = 0;
		c_fstate = r_fstate;
		c_vaddr = r_vaddr;
		c_hart = r_hart;
		c_asid = r_asid;
		c_paddr = 'bx;
		c_gaduwrx = 'bx;
		c_2mB = 'bx;
		c_4mB = 'bx;
		c_1gB = 'bx;
		c_512gB = 'bx;
		c_valid = r_valid;
		c_mem_addr_req = r_mem_addr_req;
		c_tid = r_tid;
		c_rtid = r_rtid;
		c_req = r_req;
		if (reset) begin
			c_fstate = 0;
			c_mem_addr_req = 0;
			c_cancelling = 0;
		end else
		if (cancel) begin
			restart = 1;
			c_mem_addr_req = 0;
		end else
		case (r_fstate)	// synthesis full_case parallel_case
		0: begin
				restart = 1;
		   end
		1:if (cancel||r_cancelling) begin
			restart = 1;
		  end else
		  if (r_hart?sup_vm_mode_1[0]:sup_vm_mode_0[0]) begin
			if (r_req) begin
				c_i_data_req = 1;
			end else begin
				c_d_data_req = 1;
			end
			c_rtid = r_tid;
			c_valid = 0;
			c_pmp_fail = 0;
			restart = 1;
		  end else
		  if (rhit) begin
			if (r_req) begin
				c_i_data_req = 1;
			end else begin
				c_d_data_req = 1;
			end
			c_rtid = r_tid;
			c_paddr = rpaddr;
			c_gaduwrx = rgaduwrx;
			c_2mB = r2mB;
			c_4mB = r4mB;
			c_1gB = r1gB;
			c_512gB = r512gB;
			c_valid = !(rpaddr[NPHYS]&r_req);
			c_pmp_fail = rpaddr[NPHYS]&r_req;
			restart = 1;
		  end else
		  if (pte_valid && pte_tag == r_fetch_addr[NPHYS-1:ACACHE_LINE_SIZE]) begin
			if (!valid) begin
				if (r_req) begin
					c_i_data_req = 1;
				end else begin
					c_d_data_req = 1;
				end
				c_rtid = r_tid;
				c_valid = 0;
				c_pmp_fail = 0;
				restart = 1;
			end else
			if (!indir) begin	// early termination
				if (r_req) begin
					c_i_data_req = 1;
				end else begin
					c_d_data_req = 1;
				end
				c_rtid = r_tid;
				casez ({r_64_fetch,r_32}) // synthesis full_case parallel_case
				3'b1?_?:c_paddr = {ppn3_64, 9'b0, 9'b0, 9'b0};
				3'b?1_?:c_paddr = {ppn3_64, ppn2_64, 9'b0, 9'b0};
				3'b??_1:c_paddr = {{57-34{ppn1_32[33]}}, ppn1_32, 10'b0};
				default: c_paddr = 'bx;
				endcase
				c_gaduwrx = gaduwrx;
				c_2mB = 0;
				c_4mB = r_32;
				c_1gB = r_64_fetch[0];
				c_512gB = r_64_fetch[1];
				c_valid = !(c_paddr[NPHYS]&r_req);
				c_pmp_fail = c_paddr[NPHYS]&r_req;
				c_wr_entry = 1;
				restart = 1;
			end else begin
				casez ({r_64_fetch,r_32}) // synthesis full_case parallel_case
				3'b1?_?:c_fetch_addr = {ppn3_64, ppn2_64, ppn1_64, ppn0_64, r_vaddr[38:30],1'b0};
				3'b?1_?:c_fetch_addr = {ppn3_64, ppn2_64, ppn1_64, ppn0_64, r_vaddr[29:21],1'b0};
				3'b??_1:c_fetch_addr = {{57-34{1'b0}}, ppn1_32, ppn0_32, r_vaddr[21:12]};
				default: c_fetch_addr = 'bx;
				endcase
				casez ({r_64_fetch,r_32}) // synthesis full_case parallel_case
				3'b1?_?:c_fetch_index = 1;
				3'b?1_?:c_fetch_index = 1;
				3'b??_1:c_fetch_index = 4;
				default: c_fetch_index = 'bx;
				endcase
				c_fstate = 3;
			end
		  end else 
		  if (!r_cache_busy[r_hart][r_req][r_fetch_index]) begin
			c_mem_addr_req = 1;
			c_fstate = 2;
		  end
		2:begin
			c_cancelling = r_cancelling|cancel;
			if (done_cache) begin
				c_fstate = 1;
				c_mem_addr_req = 0;
			end else
			if ((ic_addr_req&ic_addr_ack)||ic_addr_fail||r_cancelling||cancel) begin
				c_mem_addr_req = 0;
			end
			if (ic_addr_fail||cancel||r_cancelling) begin
				if (r_req) begin
					c_i_data_req = !(cancel || r_cancelling);
				end else begin
					c_d_data_req = !(cancel || r_cancelling);
				end
				c_rtid = r_tid;
				c_valid = 0;
				c_pmp_fail = 1;
				restart = 1;
			end
		  end
		3:if (cancel||r_cancelling) begin
			restart = 1;
			c_cancelling = 0;
		  end else
		  if (pte_valid && pte_tag == r_fetch_addr[NPHYS-1:ACACHE_LINE_SIZE]) begin
			if (!valid) begin
				if (r_req) begin
					c_i_data_req = 1;
				end else begin
					c_d_data_req = 1;
				end
				c_rtid = r_tid;
				c_valid = 0;
				c_pmp_fail = 0;
				restart = 1;
			end else
			if (!indir) begin	// early termination
				if (r_req) begin
					c_i_data_req = 1;
				end else begin
					c_d_data_req = 1;
				end
				c_rtid = r_tid;
				casez ({r_64_fetch,r_32}) // synthesis full_case parallel_case
				3'b1?_?:c_paddr = {ppn3_64, ppn2_64, 9'b0, 9'b0};
				3'b?1_?:c_paddr = {ppn3_64, ppn2_64, ppn1_64, 9'b0};
				3'b??_1:c_paddr = 'bx;
				default: c_paddr = 'bx;
				endcase
				c_gaduwrx = gaduwrx;
				c_2mB = r_64_fetch[0];
				c_4mB = 0;
				c_1gB = r_64_fetch[1];
				c_512gB = 0;
				c_valid = !(c_paddr[NPHYS]&r_req);
				c_pmp_fail = c_paddr[NPHYS]&r_req;
				c_wr_entry = 1;
				restart = 1;
			end else 
			if (r_32) begin	// 
				if (r_req) begin
					c_i_data_req = 1;
				end else begin
					c_d_data_req = 1;
				end
				c_rtid = r_tid;
				c_valid = 0;
				c_pmp_fail = 0;
				restart = 1;
			end else begin 
				casez ({r_64_fetch}) // synthesis full_case parallel_case
				2'b1?:c_fetch_addr = {ppn3_64, ppn2_64, ppn1_64, ppn0_64, r_vaddr[29:21],1'b0};
				2'b?1:c_fetch_addr = {ppn3_64, ppn2_64, ppn1_64, ppn0_64, r_vaddr[20:12],1'b0};
				default: c_fetch_addr = 'bx;
				endcase
				casez ({r_64_fetch}) // synthesis full_case parallel_case
				2'b1?:c_fetch_index = 2;
				2'b?1:c_fetch_index = 2;
				default: c_fetch_index = 'bx;
				endcase
				c_fstate = 5;
			end
		  end else 
		  if (!r_cache_busy[r_hart][r_req][r_fetch_index]) begin
			c_mem_addr_req = 1;
			c_fstate = 4;
		  end
		4:begin
			c_cancelling = r_cancelling|cancel;
			if (done_cache) begin
				c_mem_addr_req = 0;
				c_fstate = 3;
			end else 
			if ((ic_addr_req&ic_addr_ack)||ic_addr_fail||r_cancelling||cancel) begin
				c_mem_addr_req = 0;
			end
			if (ic_addr_fail||cancel||r_cancelling) begin
				if (r_req) begin
					c_i_data_req = !(cancel||r_cancelling);
				end else begin
					c_d_data_req = !(cancel||r_cancelling);
				end
				c_rtid = r_tid;
				c_valid = 0;
				c_pmp_fail = 1;
				restart = 1;
			end
		  end
		5:if (cancel||r_cancelling) begin
			restart = 1;
			c_cancelling = 0;
		  end else
		  if (pte_valid && pte_tag == r_fetch_addr[NPHYS-1:ACACHE_LINE_SIZE]) begin
			if (!valid) begin
				if (r_req) begin
					c_i_data_req = 1;
				end else begin
					c_d_data_req = 1;
				end
				c_rtid = r_tid;
				c_valid = 0;
				c_pmp_fail = 0;
				restart = 1;
			end else
			if (!indir) begin	// early termination
				if (r_req) begin
					c_i_data_req = 1;
				end else begin
					c_d_data_req = 1;
				end
				c_rtid = r_tid;
				c_paddr = {ppn3_64, ppn2_64, ppn1_64, ppn0_64};
				c_gaduwrx = gaduwrx;
				c_2mB = r_64_fetch[1];
				c_4mB = 0;
				c_1gB = 0;
				c_512gB = 0;
				c_valid = !(c_paddr[NPHYS]&r_req);
				c_pmp_fail = c_paddr[NPHYS]&r_req;
				c_wr_entry = 1;
				restart = 1;
			end else begin 
				c_fetch_addr = {ppn3_64, ppn2_64, ppn1_64, ppn0_64, r_vaddr[29:21], 1'b0};
				c_fetch_index = 3;
				c_fstate = 7;
			end
		  end else 
		  if (!r_cache_busy[r_hart][r_req][r_fetch_index]) begin
			c_mem_addr_req = 1;
			c_fstate = 6;
		  end
		6:begin
			c_cancelling = r_cancelling|cancel;
			if (ic_addr_ack||done_cache) begin
				c_mem_addr_req = 0;
				c_fstate = 5;
			end else
			if ((ic_addr_req&ic_addr_ack)||ic_addr_fail||r_cancelling||cancel) begin
				c_mem_addr_req = 0;
			end
			if (ic_addr_fail||cancel||r_cancelling) begin
				if (r_req) begin
					c_i_data_req = !(cancel||r_cancelling);
				end else begin
					c_d_data_req = !(cancel||r_cancelling);
				end
				c_rtid = r_tid;
				c_valid = 0;
				c_pmp_fail = 1;
				restart = 1;
			end
		  end
		7:if (cancel||r_cancelling) begin
			restart = 1;
		  end else
		  if (!pte_valid || pte_tag != r_fetch_addr[NPHYS-1:ACACHE_LINE_SIZE]) begin
			if (!r_cache_busy[r_hart][r_req][r_fetch_index]) begin
				c_mem_addr_req = 1;
				c_fstate = 6;
			end
		  end else
		  if (!valid || indir) begin
			if (r_req) begin
				c_i_data_req = 1;
			end else begin
				c_d_data_req = 1;
			end
			c_rtid = r_tid;
			c_valid = 0;
			c_pmp_fail = 0;
			restart = 1;
		  end else begin	// 
			if (r_req) begin
				c_i_data_req = 1;
			end else begin
				c_d_data_req = 1;
			end
			c_rtid = r_tid;
			c_paddr = {ppn3_64, ppn2_64, ppn1_64, ppn0_64};
			c_gaduwrx = gaduwrx;
			c_2mB = 0;
			c_4mB = 0;
			c_1gB = 0;
			c_512gB = 0;
			c_valid = !(c_paddr[NPHYS]&r_req);
			c_pmp_fail = c_paddr[NPHYS]&r_req;
			c_wr_entry = 1;
			restart = 1;
		  end
		endcase

		if (restart) begin
			c_cancelling = 0;
			if (d_addr_req&&!d_addr_cancel) begin
				c_d_addr_ack = 1;
				c_tid = d_addr_tid;
				c_vaddr = d_vaddr;
				c_hart = d_hart;
				c_asid = d_asid;
				c_req = 0;
				c_fstate = 1;
			end else
			if (i_addr_req&&!i_addr_cancel) begin
				c_i_addr_ack = 1;
				c_tid = {{LNCOMMIT-1{1'bx}},i_addr_tid};
				c_vaddr = i_vaddr;
				c_hart = i_hart;
				c_asid = i_asid;
				c_req = 1;
				c_fstate = 1;
			end else begin
				c_fstate = 0;
			end
			c_32 = (c_hart?sup_vm_mode_1[1]:sup_vm_mode_0[1]);
			c_64_fetch = (c_hart?sup_vm_mode_1[3:2]:sup_vm_mode_0[3:2]);
			casez ({c_64_fetch,c_32}) // synthesis full_case parallel_case
			3'b1?_?: c_fetch_addr = {(c_hart?sup_ppn_1:sup_ppn_0), c_vaddr[47:39],1'b0};
			3'b?1_?: c_fetch_addr = {(c_hart?sup_ppn_1:sup_ppn_0), c_vaddr[38:30],1'b0};
			3'b??_1: c_fetch_addr = {(c_hart ? sup_ppn_1[21:0]:sup_ppn_0[21:0]), c_vaddr[31:22]};
			default: c_fetch_addr = 'bx;
			endcase
			c_fetch_index = 0;
		end
	end

	tcache_l2	#(.RV(RV), .VA_SZ(VA_SZ), .NPHYS(NPHYS))tcache(
				.reset(reset),
				.clk(clk),
`ifdef AWS_DEBUG
				.xxtrig(xxtrig),
`endif

				.rvaddr0(r_vaddr),
				.rasid0(r_asid),
				.rhit0(rhit),
				.rpaddr0(rpaddr),
				.rgaduwrx0(rgaduwrx),
				.r2mB0(r2mB),
				.r4mB0(r4mB),
				.r1gB0(r1gB),
				.r512gB0(r512gB),

				.wr_entry(r_wr_entry),
				.wr_vaddr(r_vaddr_p),
				.wr_paddr(r_paddr),
				.wr_asid(r_asid_p),
				.wr_gaduwrx(r_gaduwrx),
				.wr_2mB(r_2mB),
				.wr_4mB(r_4mB),
				.wr_1gB(r_1gB),
				.wr_512gB(r_512gB),

				.wr_invalidate(wr_invalidate),
				.wr_invalidate_addr(wr_invalidate_addr),
				.wr_inv_vaddr(wr_inv_vaddr),
				.wr_invalidate_asid(wr_invalidate_asid),
				.wr_inv_unified(wr_inv_unified),
				.wr_inv_asid(wr_inv_asid)
					);
`ifdef AWS_DEBUG
        ila_tlbf ila_tlbf(.clk(clk),
            .xxtrig(xxtrig),
            .i_addr_req(i_addr_req),
            .i_vaddr(i_vaddr[12+16-1:12]),    // 16
            .i_data_req(i_data_req),
            .i_valid(i_valid),
			.i_gaux(i_gaux),                // 4
            .d_addr_req(d_addr_req),
            .d_vaddr(d_vaddr[12+16-1:12]),    // 16
            .d_data_req(d_data_req),
            .d_valid(d_valid),
            .ic_addr_req(ic_addr_req),
            .ic_data_req(ic_data_req),
            .ic_addr({ic_addr[23:2], 2'b0}),    // 24
            .ic_addr_fail(ic_addr_fail),
            .r_fstate(r_fstate),    // 4
            .r_req(r_req),
            .pte_valid(pte_valid),
			.pte_64(pte_64),
            .indir(indir),
            .cancel(cancel),
			.r_cancelling(r_cancelling),
			.valid(valid),
            .wr_invalidate(wr_invalidate),
            .wr_invalidate_addr(wr_invalidate_addr),
            .wr_invalidate_asid(wr_invalidate_asid),
			.r_vaddr(r_vaddr[23+12:12]),	// 24
            .rhit(rhit),
            .rgaduwrx(rgaduwrx),	// 7
            .rxxxxx({r512gB,r1gB,r4mB, r2mB}),	// 4
            .r_fetch_index(r_fetch_index), // 3
            .ic_snoop_addr_req(ic_snoop_addr_req),
            .ic_snoop_addr(ic_snoop_addr[23+ACACHE_LINE_SIZE:ACACHE_LINE_SIZE]), //24
            .r_cache_valid(r_cache_valid[0][0]), // 6
            .r_cache_tag(r_cache_tag[0][0][r_fetch_index][23+ACACHE_LINE_SIZE:ACACHE_LINE_SIZE]), // 24
            .d_addr_ack(d_addr_ack),
            .d_addr_cancel(d_addr_cancel),
			.busy({busy_cache, done_cache, would_ic_addr_req}),
            .restart(restart));

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

