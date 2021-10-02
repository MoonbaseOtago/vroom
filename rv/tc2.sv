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

module tcache_l2(	// TLB cache second level (looks like an icache level 1
    input reset,
    input clk,
`ifdef AWS_DEBUG
    input      xxtrig,
`endif

    input [VA_SZ-1:12]rvaddr0,	// CPU read port
	input	    [15:0]rasid0,

    output			  rhit0,
	output[NPHYS-1:12]rpaddr0,
    output     [ 6: 0]rgaduwrx0,
    output            r2mB0,
    output            r4mB0,
    output            r1gB0,
    output            r512gB0,

	input			  wr_entry,
	input [VA_SZ-1:12]wr_vaddr,
	input [NPHYS-1:12]wr_paddr,
	input	    [15:0]wr_asid,
	input	     [6:0]wr_gaduwrx,
	input			  wr_2mB,
	input			  wr_4mB,
	input			  wr_1gB,
	input			  wr_512gB,

	input			  wr_invalidate,
	input			  wr_invalidate_addr,
	input [VA_SZ-1:12]wr_inv_vaddr,
	input		      wr_invalidate_asid,
	input			  wr_inv_unified,
	input	    [15:0]wr_inv_asid,

	input dummy);

	parameter RV=64;
	parameter VA_SZ=64;
	parameter NPHYS=56;

	// cache parameters
	parameter NENTRIES=256;	
	parameter NSETS=4;		
	parameter NENTRIES_512GB=4;
	parameter NENTRIES_1GB=8;
	parameter NENTRIES_4MB=4;
	parameter NENTRIES_2MB=16;



	reg [NPHYS-1:12]r_paddr;	
	assign rpaddr0 = r_paddr;
	reg  [6:0]r_gaduwrx;
	assign rgaduwrx0 = r_gaduwrx;
	reg		r_2mB, r_4mB, r_1gB, r_512gB, r_hit;
	assign rhit0 = r_hit;
	assign r2mB0 = r_2mB;
	assign r4mB0 = r_4mB;
	assign r1gB0 = r_1gB;
	assign r512gB0 = r_512gB;


	//
	//	single page entries
	//
	wire [VA_SZ-1:12+$clog2(NENTRIES)]match_addr = rvaddr0[VA_SZ-1:12+$clog2(NENTRIES)];
	wire [12+$clog2(NENTRIES)-1:12]index = rvaddr0[12+$clog2(NENTRIES)-1:12];

	//
	//	2Mb - just 1 set need some simulation to decide if that's good
	//
	wire [VA_SZ-1:21+$clog2(NENTRIES_2MB)]match_addr_2mB = rvaddr0[VA_SZ-1:21+$clog2(NENTRIES_2MB)];
	wire [21+$clog2(NENTRIES_2MB)-1:21]index_2mB = rvaddr0[21+$clog2(NENTRIES_2MB)-1:21];
	reg   [NENTRIES_2MB-1:0]r_valid_2mB;
	reg   [15:0]r_asid_2mB[0:NENTRIES_2MB-1];
	reg   [VA_SZ-1:21+$clog2(NENTRIES_2MB)]r_vaddr_2mB[0:NENTRIES_2MB-1];
    reg [NPHYS-1:21]r_paddr_2mB[0:NENTRIES_2MB-1];
    reg [ 6: 0]r_gaduwrx_2mB[0:NENTRIES_2MB-1];

	//
	//	4Mb - just 1 set need some simulation to decide if that's good
	//
	wire [VA_SZ-1:22+$clog2(NENTRIES_4MB)]match_addr_4mB = rvaddr0[VA_SZ-1:22+$clog2(NENTRIES_4MB)];
	wire [22+$clog2(NENTRIES_4MB)-1:22]index_4mB = rvaddr0[22+$clog2(NENTRIES_4MB)-1:22];
	reg   [NENTRIES_4MB-1:0]r_valid_4mB;
	reg   [15:0]r_asid_4mB[0:NENTRIES_4MB-1];
	reg   [VA_SZ-1:22+$clog2(NENTRIES_4MB)]r_vaddr_4mB[0:NENTRIES_4MB-1];
    reg [NPHYS-1:22]r_paddr_4mB[0:NENTRIES_4MB-1];
    reg [ 6: 0]r_gaduwrx_4mB[0:NENTRIES_4MB-1];

	//
	//	1gB - just 1 set need some simulation to decide if that's good
	//
	wire [VA_SZ-1:30+$clog2(NENTRIES_1GB)]match_addr_1gB = rvaddr0[VA_SZ-1:30+$clog2(NENTRIES_1GB)];
	wire [30+$clog2(NENTRIES_1GB)-1:30]index_1gB = rvaddr0[30+$clog2(NENTRIES_1GB)-1:30];
	reg   [NENTRIES_1GB-1:0]r_valid_1gB;
	reg   [15:0]r_asid_1gB[0:NENTRIES_1GB-1];
	reg   [VA_SZ-1:30+$clog2(NENTRIES_1GB)]r_vaddr_1gB[0:NENTRIES_1GB-1];
    reg [NPHYS-1:30]r_paddr_1gB[0:NENTRIES_1GB-1];
    reg [ 6: 0]r_gaduwrx_1gB[0:NENTRIES_1GB-1];

	//
	//	512gB - just 1 set need some simulation to decide if that's good
	//
	wire [VA_SZ-1:39+$clog2(NENTRIES_512GB)]match_addr_512gB = rvaddr0[VA_SZ-1:39+$clog2(NENTRIES_512GB)];
	wire [39+$clog2(NENTRIES_512GB)-1:39]index_512gB = rvaddr0[39+$clog2(NENTRIES_512GB)-1:39];
	reg   [NENTRIES_512GB-1:0]r_valid_512gB;
	reg   [15:0]r_asid_512gB[0:NENTRIES_512GB-1];
	reg   [VA_SZ-1:39+$clog2(NENTRIES_512GB)]r_vaddr_512gB[0:NENTRIES_512GB-1];
    reg [NPHYS-1:39]r_paddr_512gB[0:NENTRIES_512GB-1];
    reg [ 6: 0]r_gaduwrx_512gB[0:NENTRIES_512GB-1];

	genvar S, E;
	generate 

		wire [NPHYS-1:12]s_paddr[0:NSETS-1];
		wire [ 6: 0]s_gaduwrx[0:NSETS-1];
		reg [NSETS-1:0]match;

		reg   [NENTRIES-1:0]r_valid[0:NSETS-1];
		for (S=0; S < NSETS; S=S+1) begin: s
			wire [VA_SZ-1:12+$clog2(NENTRIES)]inv_addr;
			reg   [15:0]r_asid[0:NENTRIES-1];
			wire   [15:0]s_asid = r_asid[index];

			wire   s_valid=r_valid[S][index];
			wire   [VA_SZ-1:12+$clog2(NENTRIES)]s_vaddr;

			wire    xva = wr_inv_vaddr[VA_SZ-1:12+$clog2(NENTRIES)] == inv_addr;

			for (E=0;E < NENTRIES; E=E+1) begin
				always @(posedge clk) begin
					if (reset) r_valid[S][E] <= 0; else
					if (wr_entry && E==wr_vaddr[12+$clog2(NENTRIES)-1:12] && r_wr_allocate[S] && !(wr_2mB|wr_4mB|wr_1gB|wr_512gB)) r_valid[S][E] <= 1; else
					if (wr_invalidate) begin : r
						reg va, as, v;

						va = xva && wr_inv_vaddr[12+$clog2(NENTRIES)-1:12]==E;
						as = (wr_inv_asid[14:0] == r_asid[E][14:0] && (wr_inv_unified||(wr_inv_asid[15] == r_asid[E][15])));
						case ({wr_invalidate_asid, wr_invalidate_addr}) // synthesis full_case parallel_case
						2'b00: v = 1;
						2'b01: v = va;
						2'b10: v = as;
						2'b11: v = va&as;
						endcase
						if (v)
							r_valid[S][E] <= 0;
					end
				end
			end

`ifdef AWS_DEBUGnot
ila_tc2 ila_tc2(.clk(clk),
				.xxclk(xxtrig),
				.wr_invalidate(wr_invalidate),
				.wr_inv_vaddr(wr_inv_vaddr[31:12]),	// 20
				.inv_addr(inv_addr[31:12+8]),		// 12
				.xva(xva),
				.wen(wr_entry && !(wr_2mB|wr_4mB|wr_1gB|wr_512gB) && r_wr_allocate[S]),
                .wr_vaddr(wr_vaddr[12+23:12]),  // 24
                .index(index),          // 8
				.r_valid(r_valid[S][wr_inv_vaddr[12+$clog2(NENTRIES)-1:12]]));			
`endif

`ifdef PSYNTH
            tc2_xdata #(.NPHYS(NPHYS), .NENTRIES(NENTRIES), .VA_SZ(VA_SZ))data(.clk(clk),
                .wen(wr_entry && !(wr_2mB|wr_4mB|wr_1gB|wr_512gB) && r_wr_allocate[S]),
                .waddr(wr_vaddr[12+$clog2(NENTRIES)-1:12]),
                .pin(wr_paddr),
                .vin(wr_vaddr[VA_SZ-1:12+$clog2(NENTRIES)]),
                .gin(wr_gaduwrx),
                .raddr_0(index),
                .pout_0(s_paddr[S]),
                .gout_0(s_gaduwrx[S]),
                .vout_0(s_vaddr),
				.raddr_1(wr_inv_vaddr[12+$clog2(NENTRIES)-1:12]),
                .vout_1(inv_addr));
`else
			reg   [VA_SZ-1:12+$clog2(NENTRIES)]r_vaddr[0:NENTRIES-1];
			reg [NPHYS-1:12]r_paddr[0:NENTRIES-1];
			reg [ 6: 0]r_gaduwrx[0:NENTRIES-1];
			assign inv_addr = r_vaddr[wr_inv_vaddr[12+$clog2(NENTRIES)-1:12]]; 
			always @(posedge clk) 
			if (wr_entry && !(wr_2mB|wr_4mB|wr_1gB|wr_512gB) && r_wr_allocate[S]) begin
				r_paddr[wr_vaddr[12+$clog2(NENTRIES)-1:12]] <= wr_paddr;
				r_vaddr[wr_vaddr[12+$clog2(NENTRIES)-1:12]] <= wr_vaddr[VA_SZ-1:12+$clog2(NENTRIES)];
				r_gaduwrx[wr_vaddr[12+$clog2(NENTRIES)-1:12]] <= wr_gaduwrx;
			end
			assign s_paddr[S]=r_paddr[index];
			assign s_gaduwrx[S]=r_gaduwrx[index];
			assign s_vaddr = r_vaddr[index];
`endif
			always @(posedge clk) 
			if (wr_entry && !(wr_2mB|wr_4mB|wr_1gB|wr_512gB) && r_wr_allocate[S]) begin
				r_asid[wr_vaddr[12+$clog2(NENTRIES)-1:12]] <= wr_asid;
			end
			always @(*)
				match[S] = s_valid&&(s_vaddr==match_addr)&&(s_gaduwrx[S][6]||(s_asid==rasid0));
		end

		wire   [15:0]s_asid_2mB=r_asid_2mB[index_2mB];
		wire   [VA_SZ-1:21+$clog2(NENTRIES)]s_vaddr_2mB = r_vaddr_2mB[index_2mB];
		wire[NPHYS-1:21]s_paddr_2mB=r_paddr_2mB[index_2mB];
		wire[6:0]s_gaduwrx_2mB=r_gaduwrx_2mB[index_2mB];
		wire	 match_2mB = r_valid_2mB[index_2mB]&&(s_vaddr_2mB==match_addr_2mB)&&(s_gaduwrx_2mB[6]||(s_asid_2mB==rasid0));

		wire   [15:0]s_asid_4mB=r_asid_4mB[index_4mB];
		wire   [VA_SZ-1:22+$clog2(NENTRIES)]s_vaddr_4mB = r_vaddr_4mB[index_4mB];
		wire[NPHYS-1:22]    s_paddr_4mB=r_paddr_4mB[index_4mB];
		wire[6:0]s_gaduwrx_4mB=r_gaduwrx_4mB[index_4mB];
		wire	 match_4mB = r_valid_4mB[index_4mB]&&(s_vaddr_4mB==match_addr_4mB)&&(s_gaduwrx_4mB[6]||(s_asid_4mB==rasid0));

		wire   [15:0]s_asid_1gB=r_asid_1gB[index_1gB];
		wire   [VA_SZ-1:30+$clog2(NENTRIES)]s_vaddr_1gB = r_vaddr_1gB[index_1gB];
		wire[NPHYS-1:30]s_paddr_1gB=r_paddr_1gB[index_1gB];
		wire[6:0]s_gaduwrx_1gB=r_gaduwrx_1gB[index_1gB];
		wire	 match_1gB = r_valid_1gB[index_1gB]&&(s_vaddr_1gB==match_addr_1gB)&&(s_gaduwrx_1gB[6]||(s_asid_1gB==rasid0));

		wire   [15:0]s_asid_512gB=r_asid_512gB[index_512gB];
		wire   [VA_SZ-1:39+$clog2(NENTRIES)]s_vaddr_512gB = r_vaddr_512gB[index_512gB];
		wire[NPHYS-1:39]s_paddr_512gB=r_paddr_512gB[index_512gB];
		wire[6:0]s_gaduwrx_512gB=r_gaduwrx_512gB[index_512gB];
		wire	 match_512gB = r_valid_512gB[index_512gB]&&(s_vaddr_512gB==match_addr_512gB)&&(s_gaduwrx_512gB[6]||(s_asid_512gB==rasid0));


		always @(*) begin
			r_paddr = 42'bx;
			r_gaduwrx = 7'bx;
			r_2mB = 1'bx;
			r_4mB = 1'bx;
			r_1gB = 1'bx;
			r_512gB = 1'bx;
			r_hit = 1'bx;
			casez ({match,match_512gB,match_1gB,match_4mB,match_2mB})	// synthesis full_case parallel_case
			8'b????_???1:begin
							r_paddr = {s_paddr_2mB, 9'b0};
							r_gaduwrx = s_gaduwrx_2mB;
							r_2mB = 1;
							r_4mB = 0;
							r_1gB = 0;
							r_512gB = 0;
							r_hit = 1;
						end
			8'b????_??1?:begin
							r_paddr = {s_paddr_4mB, 10'b0};
							r_gaduwrx = s_gaduwrx_4mB;
							r_2mB = 0;
							r_4mB = 1;
							r_1gB = 0;
							r_512gB = 0;
							r_hit = 1;
						end
			8'b????_?1??:begin
							r_paddr = {s_paddr_1gB, 18'b0};
							r_gaduwrx = s_gaduwrx_1gB;
							r_2mB = 0;
							r_4mB = 0;
							r_1gB = 1;
							r_512gB = 0;
							r_hit = 1;
						end
			8'b????_1???:begin
							r_paddr = {s_paddr_512gB, 27'b0};
							r_gaduwrx = s_gaduwrx_512gB;
							r_2mB = 0;
							r_4mB = 0;
							r_1gB = 0;
							r_512gB = 1;
							r_hit = 1;
						end
			8'b1???_????:begin
							r_paddr = s_paddr[3];
							r_gaduwrx = s_gaduwrx[3];
							r_2mB = 0;
							r_4mB = 0;
							r_1gB = 0;
							r_512gB = 0;
							r_hit = 1;
						end
			8'b?1??_????:begin
							r_paddr = s_paddr[2];
							r_gaduwrx = s_gaduwrx[2];
							r_2mB = 0;
							r_4mB = 0;
							r_1gB = 0;
							r_512gB = 0;
							r_hit = 1;
						end
			8'b??1?_????:begin
							r_paddr = s_paddr[1];
							r_gaduwrx = s_gaduwrx[1];
							r_2mB = 0;
							r_4mB = 0;
							r_1gB = 0;
							r_512gB = 0;
							r_hit = 1;
						end
			8'b???1_????:begin
							r_paddr = s_paddr[0];
							r_gaduwrx = s_gaduwrx[0];
							r_2mB = 0;
							r_4mB = 0;
							r_1gB = 0;
							r_512gB = 0;
							r_hit = 1;
						end
			8'b0000_0000:begin
							r_paddr = 44'bx;
							r_gaduwrx = 7'bx;
							r_2mB = 1'bx;
							r_4mB = 1'bx;
							r_1gB = 1'bx;
							r_512gB = 1'bx;
							r_hit = 0;
						end
			endcase
		end

		for (E=0;E < NENTRIES_2MB; E=E+1) begin
			always @(posedge clk) begin
				if (reset) r_valid_2mB[E] <= 0; else
				if (wr_entry && E==wr_vaddr[21+$clog2(NENTRIES_2MB)-1:21] && wr_2mB) r_valid_2mB[E] <= 1; else
				if (wr_invalidate) begin : r
					reg va, as, v;

					va = E==wr_inv_vaddr[21+$clog2(NENTRIES_2MB)-1:21] && wr_inv_vaddr[VA_SZ-1:21+$clog2(NENTRIES_2MB)] == r_vaddr_2mB[E];
					as = (wr_inv_asid[14:0] == r_asid_2mB[E][14:0] && (wr_inv_unified||(wr_inv_asid[15] == r_asid_2mB[E][15])));
					case ({wr_invalidate_asid, wr_invalidate_addr}) // synthesis full_case parallel_case
					2'b00: v=1;
					2'b01: v = va;
					2'b10: v = as;
					2'b11: v = va&as;
					endcase
					if (v)
						r_valid_2mB[E] <= 0;
				end

				if (wr_entry && wr_2mB && E==wr_vaddr[21+$clog2(NENTRIES_2MB)-1:21]) begin
						r_asid_2mB[E] <= wr_asid;
						r_paddr_2mB[E] <= wr_paddr;
						r_vaddr_2mB[E] <= wr_vaddr[VA_SZ-1:21+$clog2(NENTRIES_2MB)];
						r_gaduwrx_2mB[E] <= wr_gaduwrx;
				end
			end
		end

		for (E=0;E < NENTRIES_4MB; E=E+1) begin
			always @(posedge clk) begin
				if (reset) r_valid_4mB[E] <= 0; else
				if (wr_entry && E==wr_vaddr[21+$clog2(NENTRIES_4MB)-1:21] && wr_4mB) r_valid_4mB[E] <= 1; else
				if (wr_invalidate) begin : r
					reg va, as, v;

					va = wr_invalidate_addr && E==wr_inv_vaddr[21+$clog2(NENTRIES_4MB)-1:21] && wr_inv_vaddr[VA_SZ-1:21+$clog2(NENTRIES_4MB)] == r_vaddr_4mB[E];
					as = (wr_inv_asid[14:0] == r_asid_4mB[E][14:0] && (wr_inv_unified||(wr_inv_asid[15] == r_asid_4mB[E][15])));
					case ({wr_invalidate_asid, wr_invalidate_addr}) // synthesis full_case parallel_case
					2'b00: v=1;
					2'b01: v = va;
					2'b10: v = as;
					2'b11: v = va&as;
					endcase
					if (v)
						r_valid_4mB[E] <= 0;
				end

				if (wr_entry && wr_4mB && E==wr_vaddr[21+$clog2(NENTRIES_4MB)-1:21]) begin
						r_asid_4mB[E] <= wr_asid;
						r_paddr_4mB[E] <= wr_paddr;
						r_vaddr_4mB[E] <= wr_vaddr[VA_SZ-1:21+$clog2(NENTRIES_4MB)];
						r_gaduwrx_4mB[E] <= wr_gaduwrx;
				end
			end
		end

		for (E=0;E < NENTRIES_1GB; E=E+1) begin
			always @(posedge clk) begin
				if (reset) r_valid_1gB[E] <= 0; else
				if (wr_entry && E==wr_vaddr[22+$clog2(NENTRIES_1GB)-1:22] && wr_1gB) r_valid_1gB[E] <= 1; else
				if (wr_invalidate) begin : r
					reg va, as, v;

					va = wr_invalidate_addr && E==wr_inv_vaddr[22+$clog2(NENTRIES_1GB)-1:22] && wr_inv_vaddr[VA_SZ-1:22+$clog2(NENTRIES_1GB)] == r_vaddr_1gB[E];
					as = (wr_inv_asid[14:0] == r_asid_1gB[E][14:0] && (wr_inv_unified||(wr_inv_asid[15] == r_asid_1gB[E][15])));
					case ({wr_invalidate_asid, wr_invalidate_addr}) // synthesis full_case parallel_case
					2'b00: v=1;
					2'b01: v = va;
					2'b10: v = as;
					2'b11: v = va&as;
					endcase
					if (v)
						r_valid_1gB[E] <= 0;
				end

				if (wr_entry && wr_1gB && E==wr_vaddr[22+$clog2(NENTRIES_1GB)-1:22]) begin
						r_asid_1gB[E] <= wr_asid;
						r_paddr_1gB[E] <= wr_paddr;
						r_vaddr_1gB[E] <= wr_vaddr[VA_SZ-1:22+$clog2(NENTRIES_1GB)];
						r_gaduwrx_1gB[E] <= wr_gaduwrx;
				end
			end
		end

		for (E=0;E < NENTRIES_512GB; E=E+1) begin
			always @(posedge clk) begin
				if (reset) r_valid_512gB[E] <= 0; else
				if (wr_entry && E==wr_vaddr[30+$clog2(NENTRIES_512GB)-1:30] && wr_512gB) r_valid_512gB[E] <= 1; else
				if (wr_invalidate) begin : r
					reg va, as, v;

					va = wr_invalidate_addr && E==wr_inv_vaddr[30+$clog2(NENTRIES_512GB)-1:30] && wr_inv_vaddr[VA_SZ-1:30+$clog2(NENTRIES_512GB)] == r_vaddr_512gB[E];
					as = (wr_inv_asid[14:0] == r_asid_512gB[E][14:0] && (wr_inv_unified||(wr_inv_asid[15] == r_asid_512gB[E][15])));
					case ({wr_invalidate_asid, wr_invalidate_addr}) // synthesis full_case parallel_case
					2'b00: v=1;
					2'b01: v = va;
					2'b10: v = as;
					2'b11: v = va&as;
					endcase
					if (v)
						r_valid_512gB[E] <= 0;
				end

				if (wr_entry && wr_512gB && E==wr_vaddr[30+$clog2(NENTRIES_512GB)-1:30]) begin
						r_asid_512gB[E] <= wr_asid;
						r_paddr_512gB[E] <= wr_paddr;
						r_vaddr_512gB[E] <= wr_vaddr[VA_SZ-1:30+$clog2(NENTRIES_512GB)];
						r_gaduwrx_512gB[E] <= wr_gaduwrx;
				end
			end
		end

		reg [NSETS-1:0]r_wr_allocate;
		always @(posedge clk)
		if (reset) r_wr_allocate <= 1; else
		if (wr_entry && !(wr_2mB|wr_4mB|wr_1gB|wr_512gB)) r_wr_allocate <= {r_wr_allocate[NSETS-2:0],r_wr_allocate[NSETS-1]};
			
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

