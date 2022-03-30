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

module itlb(input clk, input reset,

	input [VA_SZ-1:12]rd_vaddr_0,		// read path
	input	[15:0]rd_asid_0,
	input		rd_enable_0,
	output  	rd_valid_0,
	output  	rd_2mB_0,
	output  	rd_4mB_0,
	output  	rd_1gB_0,
	output  	rd_512gB_0,
	output [NPHYS-1:12]rd_paddr_0,
	output	[2: 0]rd_aux_0,

	input [VA_SZ-1:12]rd_vaddr_1,		// read path
	input	[15:0]rd_asid_1,
	input		rd_enable_1,
	output  	rd_valid_1,
	output  	rd_2mB_1,
	output  	rd_4mB_1,
	output  	rd_1gB_1,
	output  	rd_512gB_1,
	output	[NPHYS-1:12]rd_paddr_1,
	output	[2: 0]rd_aux_1,

	input [VA_SZ-1:12]wr_vaddr,		// write path
	input	[15:0]wr_asid,
	input	[NPHYS-1:12]wr_paddr,
	input		wr_entry,
	input	[3: 0]wr_gaux,
	input		wr_2mB,
	input		wr_4mB,
	input		wr_1gB,
	input		wr_512gB,

	input		wr_invalidate, 
	input		wr_invalidate_asid, 
	input	[15:0]wr_inv_asid,
	input		wr_inv_unified,
	input		wr_invalidate_addr,
	input [VA_SZ-1:12]wr_inv_vaddr
	);

	parameter RV=64;
	parameter TLB_SETS=0;
	parameter TLB_ENTRIES=32;
	parameter NPHYS=44;
	parameter VA_SZ=48;
	parameter NHART=1;
	parameter LNHART=1;


	reg	[NPHYS-1:12]rd_paddr_res_0;
	assign rd_paddr_0 = rd_paddr_res_0;
	reg	[ 2: 0]rd_aux_res_0;
	assign rd_aux_0 = rd_aux_res_0;

	reg	[NPHYS-1:12]rd_paddr_res_1;
	assign rd_paddr_1 = rd_paddr_res_1;
	reg	[ 2: 0]rd_aux_res_1;
	assign rd_aux_1 = rd_aux_res_1;

	genvar I;
	generate
		wire [TLB_ENTRIES-1:0]rd_match_0, rd_match_1, rd_match_2;

		reg [TLB_ENTRIES-1:0]r_tlb_valid;
		reg [16-1:0]r_tlb_asid[0:TLB_ENTRIES-1];
		reg [VA_SZ-1:12]r_tlb_vaddr[0:TLB_ENTRIES-1];
		reg [NPHYS-1:12]r_tlb_paddr[0:TLB_ENTRIES-1];
		reg [ 3: 0]r_tlb_gaux[0:TLB_ENTRIES-1];
		reg [TLB_ENTRIES-1:0]r_tlb_2mB;
		reg [TLB_ENTRIES-1:0]r_tlb_4mB;
		reg [TLB_ENTRIES-1:0]r_tlb_1gB;
		reg [TLB_ENTRIES-1:0]r_tlb_512gB;

		reg [$clog2(TLB_ENTRIES)-1:0]r_repl;
		always @(posedge clk)
		if (reset) begin
			r_repl <= 0;
		end else
		if (wr_entry ||
		    (rd_enable_0&&rd_match_0[r_repl]) ||
		    (rd_enable_0&&rd_match_1[r_repl])) begin
			r_repl <= r_repl+1;
		end 

		for (I = 0; I < TLB_ENTRIES; I=I+1) begin : u
			wire rd_vld = r_tlb_valid[I];
			wire [15:0]rd_as = r_tlb_asid[I];
			wire [VA_SZ-1:12]rd_va = r_tlb_vaddr[I];

			assign rd_match_0[I] = rd_vld && ((rd_asid_0 == rd_as) || r_tlb_gaux[I][3]) && 
						rd_va[VA_SZ-1:39] == rd_vaddr_0[VA_SZ-1:39] &&
						(r_tlb_512gB[I] || rd_va[38:30] == rd_vaddr_0[38:30]) &&
						(r_tlb_512gB[I] || r_tlb_1gB[I] || rd_va[29:22] == rd_vaddr_0[29:22]) &&
						(r_tlb_512gB[I] || r_tlb_1gB[I] || r_tlb_4mB[I] || rd_va[21] == rd_vaddr_0[21]) &&
						(r_tlb_512gB[I] || r_tlb_1gB[I] || r_tlb_4mB[I] || r_tlb_2mB[I] || rd_va[20:12] == rd_vaddr_0[20:12]);

			assign rd_match_1[I] = rd_vld && ((rd_asid_1 == rd_as) || r_tlb_gaux[I][3]) && 
						rd_va[VA_SZ-1:39] == rd_vaddr_1[VA_SZ-1:39] &&
						(r_tlb_512gB[I] || rd_va[38:30] == rd_vaddr_1[38:30]) &&
						(r_tlb_512gB[I] || r_tlb_1gB[I] || rd_va[29:22] == rd_vaddr_1[29:22]) &&
						(r_tlb_512gB[I] || r_tlb_1gB[I] || r_tlb_4mB[I] || rd_va[21] == rd_vaddr_1[21]) &&
						(r_tlb_512gB[I] || r_tlb_1gB[I] || r_tlb_4mB[I] || r_tlb_2mB[I] || rd_va[20:12] == rd_vaddr_1[20:12]);

			wire [15:0]wr_as = r_tlb_asid[I];
			wire [VA_SZ-1:12]wr_va = r_tlb_vaddr[I];
			wire wr_inv_asid_match = wr_inv_asid == wr_as;
			wire wr_inv_addr_match = wr_inv_vaddr == wr_va;
			wire wr_inv_hart_match = wr_inv_unified||wr_inv_asid[15]==wr_as[15];

			always @(posedge clk)
			casez ({reset, wr_entry&&r_repl==I, wr_invalidate, !wr_invalidate_addr|wr_inv_addr_match, wr_invalidate_asid?wr_inv_asid_match:wr_inv_hart_match}) // synthesis full_case parallel_case
			5'b0_1_0_??: begin
							r_tlb_valid[I] <= 1;
							r_tlb_asid[I] <= wr_asid;
							r_tlb_vaddr[I] <= wr_vaddr;
							r_tlb_paddr[I] <= wr_paddr;
							r_tlb_gaux[I] <= wr_gaux;
							r_tlb_2mB[I] <= wr_2mB;
							r_tlb_4mB[I] <= wr_4mB;
							r_tlb_1gB[I] <= wr_1gB;
							r_tlb_512gB[I] <= wr_512gB;
						end
			5'b1_?_?_??,
			5'b0_?_1_10,
			5'b0_?_1_01,
			5'b0_?_1_11: r_tlb_valid[I] <= 0;

			5'b0_0_0_??,
			5'b0_0_1_00: ;
			endcase
		end

//		if (TLB_ENTRIES == 16) begin
//`include "mk11_16_2.inc"
//		end else
		if (TLB_ENTRIES == 32) begin
`include "mk11_32_2.inc"
//		end else
//		if (TLB_ENTRIES == 64) begin
//`include "mk11_64_2.inc"
		end 

		assign rd_valid_0 = |rd_match_0;
		assign rd_2mB_0 = |(rd_match_0&r_tlb_2mB);
		assign rd_4mB_0 = |(rd_match_0&r_tlb_4mB);
		assign rd_1gB_0 = |(rd_match_0&r_tlb_1gB);
		assign rd_512gB_0 = |(rd_match_0&r_tlb_512gB);

		assign rd_valid_1 = |rd_match_1;
		assign rd_2mB_1 = |(rd_match_1&r_tlb_2mB);
		assign rd_4mB_1 = |(rd_match_1&r_tlb_4mB);
		assign rd_1gB_1 = |(rd_match_1&r_tlb_1gB);
		assign rd_512gB_1 = |(rd_match_1&r_tlb_512gB);

	endgenerate

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

