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

`include "lstypes.si"

module fetch(
    input clk,
`ifdef AWS_DEBUG
	input		xxtrig,
`endif
    input reset,

    input [RV-1:BDEC]pc_0,    // CPU read port
	input		  stall_0,
	output		  fail_0,
    output        ok_0,
    output        okr_0,
	output	      trap_type_0,
    output [127:0]out_0,

    input [RV-1:BDEC]pc_1,    // CPU read port
	input		  stall_1,
	output		  fail_1,
    output		  ok_1,
    output		  okr_1,
	output		  trap_type_1,
    output [127:0]out_1,

	input [ 3: 0]cpu_mode_0,
    input [ 3: 0]sup_vm_mode_0,
    input [15: 0]sup_asid_0,
    input [43: 0]sup_ppn_0,

    input [ 3: 0]cpu_mode_1,
    input [ 3: 0]sup_vm_mode_1,
    input [15: 0]sup_asid_1,
    input [43: 0]sup_ppn_1,

    output[NPHYS-1:ACACHE_LINE_SIZE]ic_raddr,
    output      ic_raddr_req,
    input       ic_raddr_ack,
    output [TRANS_ID_SIZE-1:0]ic_raddr_trans,
    output [2:0]ic_raddr_snoop,

    input  [CACHE_LINE_SIZE-1:0]ic_rdata,
    input  [TRANS_ID_SIZE-1:0]ic_rdata_trans,
    input       ic_rdata_req,
    output      ic_rdata_ack,
    input  [2:0]ic_rdata_resp,

    input [NPHYS-1:ACACHE_LINE_SIZE]ic_snoop_addr,
    input       ic_snoop_addr_req,
    output      ic_snoop_addr_ack,
    input  [1:0]ic_snoop_snoop,

    input       tlb_wr_invalidate,
    input       tlb_wr_invalidate_asid,
	input		tlb_wr_inv_unified,
    input       tlb_wr_invalidate_addr,
    input [VA_SZ-1:12]tlb_wr_inv_vaddr,
    input   [15:0]tlb_wr_inv_asid,

	input    [15:0]tlb_d_asid,              // d$ read port
    input[(NHART==1?0:LNHART-1):0]tlb_d_hart,
    input [VA_SZ-1:12]tlb_d_vaddr,
    input[LNCOMMIT-1:0]tlb_d_addr_tid,
    input          tlb_d_addr_req,
    output         tlb_d_addr_ack,
    input          tlb_d_addr_cancel,
    output         tlb_d_data_req,          // d$ response
    output[LNCOMMIT-1:0]tlb_d_data_tid,
    output[VA_SZ-1:12]tlb_d_data_vaddr,
    output   [15: 0]tlb_d_data_asid,
    output[NPHYS-1:12]tlb_d_paddr,
    output   [6:0] tlb_d_gaduwrx,
    output         tlb_d_2mB,
    output         tlb_d_4mB,
    output         tlb_d_1gB,
    output         tlb_d_512gB,
    output         tlb_d_valid,
    output         tlb_d_pmp_fail,


	input		irand,

	
	PMP		pmp_0,
	PMP		pmp_1,

	input dummy);

	parameter RV=64;
	parameter BDEC=4;
	parameter VA_SZ=48;
	parameter NPHYS=56;
	parameter TRANS_ID_SIZE=6;
	parameter NHART=2;
	parameter LNHART=1;
	parameter LNCOMMIT=5;
	parameter NUM_PMP=5;
	parameter CACHE_LINE_SIZE=512;
	parameter ACACHE_LINE_SIZE=6;

`include "cache_protocol.si"

	wire [RV-1:BDEC]pc[0:NHART-1];
	assign pc[0] = pc_0;
	assign pc[1] = pc_1;

	reg [NHART-1:0]fail;
	assign  fail_0 = fail[0]&!stall_0;
	assign  fail_1 = fail[1]&!stall_1;

	wire [NHART-1:0]stall;
	assign stall[0] = stall_0;
	assign stall[1] = stall_1;

	reg  [127:0]r_res[0:NHART-1];
	assign out_0 = r_res[0];
	assign out_1 = r_res[1];

	assign ok_0 = !reset&(c_rom[0]?1:ic_rd_hit[0]&&!tlb_miss[0]);
	assign ok_1 = !reset&(c_rom[1]?1:ic_rd_hit[1]&&!tlb_miss[1]);
	reg [1:0]r_ok;
	always @(posedge clk)
	if (reset) begin
		r_ok[0] <= 0;
	end else 
	if (!stall[0])
		r_ok[0] <= ok_0&!fail[0];
	always @(posedge clk)
	if (reset) begin
		r_ok[1] <= 0;
	end else 
	if (!stall[1])
		r_ok[1] <= ok_1&!fail[1];
	assign okr_0 = r_ok[0];
	assign okr_1 = r_ok[1];

	reg [1:0]trap_type[0:NHART-1];
	reg [NHART-1:0]r_trap_type;
	assign trap_type_0 = r_trap_type[0];
	assign trap_type_1 = r_trap_type[1];
	always @(posedge clk) begin
		r_trap_type[0] <= trap_type[0][0];
		r_trap_type[1] <= trap_type[1][0];
	end

	wire [ 3: 0]cpu_mode[0:NHART-1];
	assign cpu_mode[0] = cpu_mode_0;
	assign cpu_mode[1] = cpu_mode_1;
    wire [ 3: 0]sup_vm_mode[0:NHART-1];
	assign sup_vm_mode[0] = sup_vm_mode_0;
	assign sup_vm_mode[1] = sup_vm_mode_1;
    wire [15: 0]sup_asid[0:NHART-1];
	assign sup_asid[0] = sup_asid_0;
	assign sup_asid[1] = sup_asid_1;
    wire [43: 0]sup_ppn[0:NHART-1];
	assign sup_ppn[0] = sup_ppn_0;
	assign sup_ppn[1] = sup_ppn_1;

    wire [15:0]tlb_asid[0:NHART-1];
 wire [15:0]tlb_asid_0=tlb_asid[0];
    wire [NHART-1:0]tlb_valid;
    wire [NHART-1:0]tlb_enable;
    wire [NHART-1:0]tlb_2mB;
    wire [NHART-1:0]tlb_4mB;
    wire [NHART-1:0]tlb_1gB;
    wire [NHART-1:0]tlb_512gB;
    wire [NPHYS-1:12]tlb_paddr[0:NHART-1];
wire [NPHYS-1:12]tlb_paddr_0=tlb_paddr[0];
    wire [2: 0]tlb_aux[0:NHART-1];
wire [2: 0]tlb_aux_0=tlb_aux[0];
    reg [NHART-1:0]tlb_miss;

    wire [VA_SZ-1:12]tlb_wr_vaddr;     // write path
    wire   [15:0]tlb_wr_asid;
    wire   [NPHYS-1:12]tlb_wr_paddr;
    wire   [3: 0]tlb_wr_gaux;
    wire		tlb_wr_2mB;
    wire		tlb_wr_4mB;
    wire		tlb_wr_1gB;
    wire		tlb_wr_512gB;

	reg	 [RV-1:BDEC]c_vaddr[0:NHART-1];
wire [RV-1:BDEC]c_vaddr_0=c_vaddr[0];
	reg	 [NPHYS-1:BDEC]c_paddr[0:NHART-1];
wire [NPHYS-1:BDEC]c_paddr_0=c_paddr[0];
	reg	 [NHART-1:0]c_rom;

	reg [3:0]rd_prot[0:NHART-1];
wire [3:0]rd_prot_0=rd_prot[0];
	reg [NHART-1:0]rd_addr_ok;

	reg	 [NPHYS-1:BDEC]ic_rd_addr[0:NHART-1];
	reg [NHART-1:0]ic_rd_hit;
	reg [127:0]ic_rd_data[0:NHART-1];

	reg [NHART-1:0]allocate;

	parameter NITOTAL=8;
	parameter NILOAD=NITOTAL;
	reg [NPHYS-1:ACACHE_LINE_SIZE]r_mem_addr[0:NITOTAL-1];
	reg [NPHYS-1:ACACHE_LINE_SIZE]c_mem_addr[0:NITOTAL-1];
	
	reg [NITOTAL-1:0]r_mem_busy, c_mem_busy;
	reg [NITOTAL-1:0]r_mem_state, c_mem_state;
	reg [$clog2(NILOAD)-1:0]next_avail[0:NILOAD-1];
	reg [NHART-1:0]avail;
	reg			   r_sched, c_sched;
	wire [NITOTAL-1:0]loading[0:NHART-1];
wire [NITOTAL-1:0]loading_0=loading[0];

	wire	tcache_addr_req;
	wire	tcache_addr_fail;
	wire	tcache_addr_sz;
	wire[NPHYS-1:2]tcache_addr;
	wire [TRANS_ID_SIZE-2:0]tcache_addr_trans;

    assign ic_raddr = tcache_addr_req?tcache_addr[NPHYS-1:ACACHE_LINE_SIZE]:r_mem_addr[r_current];
    assign ic_raddr_req = tcache_addr_req|((r_mem_state[r_current] == 0) && r_mem_busy[r_current]);
    assign ic_raddr_trans = tcache_addr_req?{1'b1,tcache_addr_trans}:{1'b0,r_current};
    assign ic_raddr_snoop = RSNOOP_READ_LINE_SHARED;

	reg [$clog2(NILOAD)-1:0]r_current, c_current;

	reg			r_last_tlb, c_last_tlb;
	reg [NHART-1:0]r_tlb_busy, c_tlb_busy;

	reg	 [15:0]r_tlb_wr_asid, c_tlb_wr_asid;
	reg			r_tlb_wr_addr_req, c_tlb_wr_addr_req;
	reg			r_tlb_wr_addr_tid, c_tlb_wr_addr_tid;
	reg			r_tlb_wr_hart, c_tlb_wr_hart;
	reg[VA_SZ-1:12]r_tlb_wr_vaddr, c_tlb_wr_vaddr;
	wire		tlb_wr_addr_ack;
	wire		tlb_wr_data_req;
	wire[VA_SZ-1:12]tlb_wr_data_vaddr;
	wire		tlb_wr_valid;
	wire		tlb_wr_valid_pmp;
	wire		tlb_wr_data_tid;

	genvar H, N;
	generate
		if (NITOTAL == 8) begin
			always @(*) begin: sc
				reg av;
				reg [2:0]x_avail;

				av = 1;
				x_avail = 3'bx;
				casez (r_mem_busy) // synthesis full_case parallel_case
				8'b????_???0:	x_avail = 0;
				8'b????_??01:	x_avail = 1;
				8'b????_?011:	x_avail = 2;
				8'b????_0111:	x_avail = 3;
				8'b???0_1111:	x_avail = 4;
				8'b??01_1111:	x_avail = 5;
				8'b?011_1111:	x_avail = 6;
				8'b0111_1111:	x_avail = 7;
				8'b1111_1111:	av = 0;
				default: ;
				endcase
				c_current = (reset?0:r_current);
				c_sched = (reset?0:r_sched);
				avail = 0;
				casez ({ic_raddr_req, ic_raddr_ack&!tcache_addr_req, r_sched, allocate}) // synthesis full_case parallel_case
				5'b?1_0_11,
				5'b0?_0_11:begin
							avail = {1'b0, av};
							next_avail[0] = x_avail;
							c_current = x_avail;
							next_avail[1] = 3'bx;
							c_sched = ~r_sched;
						 end
				5'b?1_1_11,
				5'b0?_1_11:begin
							avail = {av, 1'b0};
							next_avail[0] = 3'bx;
							next_avail[1] = x_avail;
							c_current = x_avail;
							c_sched = ~r_sched;
						 end
				5'b?1_?_10,
				5'b0?_?_10: begin
							avail = 2'b10;
							next_avail[0] = 3'bx;
							next_avail[1] = x_avail;
							c_current = x_avail;
						 end
				5'b?1_?_01,
				5'b0?_?_01: begin
							avail = 2'b01;
							next_avail[0] = x_avail;
							c_current = x_avail;
							next_avail[1] = 3'bx;
						 end
				5'b10_?_??,
				5'b??_?_00: begin
							avail = 2'b00;
							next_avail[0] = 3'bx;
							next_avail[1] = 3'bx;
						 end
				default: begin
							avail = 2'bxx;
							next_avail[0] = 3'bx;
							next_avail[1] = 3'bx;
							c_current = 3'bx;
							c_sched = 1'bx;
						 end
				endcase
			end
		end

		always @(posedge clk) begin
			r_sched <= c_sched;
			r_current <= c_current;
		end

		for (N=0; N < NILOAD; N = N + 1) begin
			for (H=0; H < NHART; H=H+1) begin
				assign loading[H][N] = r_mem_busy[N] && (r_mem_addr[N] == c_paddr[H][NPHYS-1:ACACHE_LINE_SIZE]);
			end
			always @(*) begin
				c_mem_busy[N] = r_mem_busy[N];
				c_mem_addr[N] = r_mem_addr[N];
				c_mem_state[N] = r_mem_state[N];
				if (reset) begin
					c_mem_busy[N] = 0;
					c_mem_state[N] = 1;
				end else
				if (avail[0] && next_avail[0] == N) begin
					c_mem_addr[N] = c_paddr[0][NPHYS-1:ACACHE_LINE_SIZE];
					c_mem_busy[N] = 1;
					c_mem_state[N] = 0;
				end else
				if (avail[1] && next_avail[1] == N) begin
					c_mem_addr[N] = c_paddr[1][NPHYS-1:ACACHE_LINE_SIZE];
					c_mem_busy[N] = 1;
					c_mem_state[N] = 0;
				end else
				if (ic_rdata_req && !ic_rdata_trans[TRANS_ID_SIZE-1] && ic_rdata_trans[2:0] == N) begin
					c_mem_busy[N] = 0;
				end else
				if (r_current == N && ic_raddr_ack && !tcache_addr_req) begin
					c_mem_state[N] = 1;
				end 
			end

			always @(posedge clk) begin
				r_mem_addr[N] <= c_mem_addr[N];
				r_mem_busy[N] <= c_mem_busy[N];
				r_mem_state[N] <= c_mem_state[N];
			end
		end


		wire tcache_addr_ack = tcache_addr_req&&ic_raddr_ack;

		wire [NHART-1:0]rd_fail;
		
		for (H=0; H < NHART; H=H+1) begin :ld
			assign tlb_asid[H] = sup_asid[H];

			if (H == 0) begin
				pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))pmp_check(
					.m(cpu_mode_0[3]),
					.su(cpu_mode_0[1]|cpu_mode_0[0]),
					.sz(2'h2),
					.mprv(1'b0),
					.addr({c_paddr[H][NPHYS-1:BDEC], {BDEC-2{1'b0}}}),
					.check_x(1'b1),
					.check_r(1'b0),
					.check_w(1'b0),
					.fail(rd_fail[H]),
					
					.pmp(pmp_0));
			end else
			if (H == 1) begin
				pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))pmp_check(
					.m(cpu_mode_1[3]),
					.su(cpu_mode_1[1]|cpu_mode_1[0]),
					.mprv(1'b0),
					.sz(2'h2),
					.addr({c_paddr[H][NPHYS-1:BDEC], {BDEC-2{1'b0}}}),
					.check_x(1'b1),
					.check_r(1'b0),
					.check_w(1'b0),
					.fail(rd_fail[H]),
	
					.pmp(pmp_1));
			end

			if (RV == 64) begin
				always @(*)
					 c_vaddr[H] = pc[H];
				always @(*) begin
					c_rom[H] = 'bx;
					c_paddr[H] = 'bx;
					casez ({cpu_mode[H][3], tlb_valid[H], sup_vm_mode[H]}) // synthesis full_case parallel_case
					6'b1_?_????: begin
									c_rom[H] = c_vaddr[H][VA_SZ-1];
									c_paddr[H] = {{NPHYS-VA_SZ{c_vaddr[H][VA_SZ-1]}}, c_vaddr[H][VA_SZ-1:BDEC]};
								 end
					6'b0_?_???1: begin
									c_rom[H] = 0;
									c_paddr[H] = {{NPHYS-VA_SZ{c_vaddr[H][VA_SZ-1]}}, c_vaddr[H][VA_SZ-1:BDEC]};
								 end
					6'b0_?_??1?: begin
									c_rom[H] = 0;
									c_paddr[H] = {tlb_paddr[H][NPHYS-1:22],
												tlb_4mB[H]?c_vaddr[H][21:12]:tlb_paddr[H][21:12],
												c_vaddr[H][11:BDEC]};
								 end
					6'b0_?_?1??: begin
									c_rom[H] = 0;
									c_paddr[H] = {tlb_paddr[H][NPHYS-1:30],
												tlb_1gB[H]?c_vaddr[H][29:21]:tlb_paddr[H][29:21],
												tlb_2mB[H]?c_vaddr[H][20:12]:tlb_paddr[H][20:12],
												c_vaddr[H][11:BDEC]};
								 end
					6'b0_?_1???: begin
									c_rom[H] = 0;
									c_paddr[H] = {tlb_paddr[H][NPHYS-1:39],
												tlb_512gB[H]?c_vaddr[H][38:30]:tlb_paddr[H][38:30],
												tlb_1gB[H]?c_vaddr[H][29:21]:tlb_paddr[H][29:21],
												tlb_2mB[H]?c_vaddr[H][20:12]:tlb_paddr[H][20:12],
												c_vaddr[H][11:BDEC]};
								 end
					default:	 begin
									c_rom[H] = 1'bx;
									c_paddr[H] = 'bx;
								 end
					endcase
				end
				always @(*)
					ic_rd_addr[H] = c_paddr[H];
			end else begin
				always @(*)
					c_vaddr[H] = pc[H];
				always @(*) begin
					casez ({cpu_mode[H][3], tlb_valid[H], sup_vm_mode[H][1:0]}) // synthesis full_case parallel_case
					4'b1_?_??, 
					4'b1_0_?1,
					4'b0_?_?1: c_paddr[H] = c_vaddr[H][NPHYS-1:BDEC];
					4'b0_1_1?: c_paddr[H] = {tlb_paddr[H][NPHYS-1:22],
											tlb_4mB[H]?c_vaddr[H][21:10]:tlb_paddr[H][21:10],
											c_vaddr[H][11:BDEC]};
					default: c_paddr[H] = 'bx;
					endcase
					c_rom[H] = 0; // FIXME maybe
				end
				always @(*)
					ic_rd_addr[H] = c_paddr[H];
			end
			always @(*) begin
				rd_prot[H] = 4'bxxxx;
				casez({cpu_mode[H], sup_vm_mode[H][0], tlb_valid[H], tlb_aux[H], rd_fail[H], c_paddr[H][NPHYS-1]}) // synthesis full_case parallel_case
				11'b1???_?_?_???_0_?: rd_prot[H] = 4'b0001;	// M mode
				11'b1???_?_?_???_1_?: rd_prot[H] = 4'b0100;	// M mode PMAP fail

				11'b??1?_1_?_???_0_0: rd_prot[H] = 4'b0001;	// turned off
				11'b???1_1_?_???_0_0: rd_prot[H] = 4'b0001;	// turned off
				11'b??1?_1_?_???_1_?: rd_prot[H] = 4'b0100;	// turned off PMAP fail
				11'b???1_1_?_???_1_?: rd_prot[H] = 4'b0100;	// turned off PMAP fail
				11'b??1?_1_?_???_0_1: rd_prot[H] = 4'b0100;	// turned off fetch to ROM not OK
				11'b???1_1_?_???_0_1: rd_prot[H] = 4'b0100;	// turned off fetch to ROM not OK

				11'b??1?_0_0_???_?_?: rd_prot[H] = 4'b1000;	// sup tlb miss (handled by attempting to fetch)
				11'b??1?_0_1_?1?_?_?: rd_prot[H] = 4'b0010;	// sup tlb u read not OK
				11'b??1?_0_1_?00_?_?: rd_prot[H] = 4'b0010;	// sup tlb read not OK
				11'b??1?_0_1_001_0_0: rd_prot[H] = 4'b0010;	// sup tbl no A
				11'b??1?_0_1_101_0_0: rd_prot[H] = 4'b0001;	// sup tbl read OK
				11'b??1?_0_1_101_1_?: rd_prot[H] = 4'b0100;	// sup tbl read OK PMAP fail
				11'b??1?_0_1_101_?_1: rd_prot[H] = 4'b0100;	// sup tbl fetch to ROM not OK


				11'b???1_0_0_???_?_?: rd_prot[H] = 4'b1000;	// usr tlb miss (handled by attempting to fetch)
				11'b???1_0_1_?0?_?_?: rd_prot[H] = 4'b0010;	// usr tlb read sup page
				11'b???1_0_1_?10_?_?: rd_prot[H] = 4'b0010;	// usr tlb read not OK
				11'b???1_0_1_011_0_0: rd_prot[H] = 4'b0010;	// usr tbl no A
				11'b???1_0_1_111_0_0: rd_prot[H] = 4'b0001;	// usr tbl read OK
				11'b???1_0_1_111_1_0: rd_prot[H] = 4'b0100;	// usr tbl read OK PMAP fail
				11'b???1_0_1_111_?_1: rd_prot[H] = 4'b0100;	// usr tbl read OK fetch to ROM not OK
				default: rd_prot[H] = 4'bxxxx;
				endcase
			end
			always @(*) begin
				tlb_miss[H] = !cpu_mode[H][3] && sup_vm_mode[H][0] == 0 && !tlb_valid[H];
				casez ({cpu_mode[H][3], sup_vm_mode[H]}) // synthesis full_case parallel_case
				5'b1_????: rd_addr_ok[H] = 1;
				5'b0_???1: rd_addr_ok[H] = 1;
				5'b0_??1?: rd_addr_ok[H] = 1;
				5'b0_?1??: rd_addr_ok[H] = !c_vaddr[H][38]?(c_vaddr[H][RV-1:39]==25'h0):(c_vaddr[H][RV-1:39]==25'h1_ff_ff_ff);
				5'b0_1???: rd_addr_ok[H] = !c_vaddr[H][47]?(c_vaddr[H][RV-1:48]==16'h0):(c_vaddr[H][RV-1:48]==16'hff_ff);
				default: rd_addr_ok[H] = 1'bx;
				endcase
			end
			always @(*) begin
				trap_type[H] = 'bx;
				casez ({tlb_wr_data_req, tlb_wr_valid, tlb_wr_valid_pmp,~rd_addr_ok[H],rd_prot[H]}) // synthesis parallel_case
				8'b100_?_????,
				8'b0??_0_1???,
				8'b0??_0_??1?: trap_type[H] = 3; // page fault
				8'b101_?_????,
				8'b0??_1_????,
				8'b0??_0_?1??: trap_type[H] = 2; // protection
				8'b0??_0_???1: trap_type[H] = 0; // no trap
				default: trap_type[H] = 2'bxx;
				endcase
				allocate[H] = !c_rom[H]&&!ic_rd_hit[H]&&rd_prot[H][0]&&~(|loading[H])&&!tlb_miss[H];
				fail[H] = (!rd_prot[H][0]&!rd_prot[H][3]) || (tlb_wr_data_req&(H==tlb_wr_data_tid)&!tlb_wr_valid&(tlb_wr_data_vaddr==c_vaddr[H][VA_SZ-1:12]));
			end

			wire [127:0]rom_data;
			if (H == 0) begin
				bootrom0	rom(.addr(c_vaddr[H][12:4]), .data(rom_data));
			end else begin
				bootrom1	rom(.addr(c_vaddr[H][12:4]), .data(rom_data));
			end
		
			always @(posedge clk) 
			if (!stall[H])
				r_res[H] <= c_rom[H]?rom_data:ic_rd_data[H];

			assign tlb_enable[H] = !stall[H] && c_rom[H] && ic_rd_hit[0] && !tlb_miss[0] && !sup_vm_mode[H][3] && !sup_vm_mode[H][0];

		end
	endgenerate

	always @(posedge clk) begin
		r_last_tlb <= c_last_tlb;
		r_tlb_busy <= c_tlb_busy;
		r_tlb_wr_asid <= c_tlb_wr_asid;
		r_tlb_wr_addr_req <= c_tlb_wr_addr_req;
		r_tlb_wr_addr_tid <= c_tlb_wr_addr_tid;
		r_tlb_wr_hart <= c_tlb_wr_hart;
		r_tlb_wr_vaddr <= c_tlb_wr_vaddr;
	end

	always @(*) begin
		c_tlb_wr_asid = r_tlb_wr_asid;
		c_tlb_wr_addr_tid = r_tlb_wr_addr_tid;
		c_tlb_wr_hart = r_tlb_wr_hart;
		c_tlb_wr_vaddr = r_tlb_wr_vaddr;
		c_tlb_busy = r_tlb_busy&~{tlb_wr_data_req&tlb_wr_data_tid, tlb_wr_data_req&~tlb_wr_data_tid};
		c_last_tlb = r_last_tlb;
		c_tlb_wr_addr_req = r_tlb_wr_addr_req&~tlb_wr_addr_ack;
		if (reset) begin
			c_tlb_busy = 0;
			c_last_tlb = 0;
			c_tlb_wr_addr_req = 0;
		end else
		casez ({stall[1], tlb_miss[1], r_tlb_busy[1],  stall[0], tlb_miss[0], r_tlb_busy[0], r_last_tlb, r_tlb_wr_addr_req&~tlb_wr_addr_ack}) // synthesis full_case parallel_case
		8'b???_???_?1:		;	// busy

		8'b010_???_10,			// allocate 1
		8'b010_1??_00,
		8'b010_?0?_00,
		8'b010_??1_00:	begin
							c_tlb_wr_addr_req = 1;
							c_tlb_wr_asid = sup_asid[1];          
							c_tlb_wr_hart = 1;
							c_tlb_wr_vaddr = c_vaddr[1][RV-1:12];
							c_tlb_wr_addr_tid = 1;
							c_tlb_busy[1] = 1;
							c_last_tlb = 0;
						end
		8'b???_010_00,			// allocate 1
		8'b1??_010_10,
		8'b?0?_010_10,
		8'b??1_010_10:	begin
							c_tlb_wr_addr_req = 1;
							c_tlb_wr_asid = sup_asid[0];          
							c_tlb_wr_hart = 0;
							c_tlb_wr_vaddr = c_vaddr[0][RV-1:12];
							c_tlb_wr_addr_tid = 0;
							c_tlb_busy[0] = 1;
							c_last_tlb = 1;
						end
		default: ;
		endcase
	end

	assign	ic_rdata_ack = 1;
	icache_l1   #(.RV(RV), .NPHYS(NPHYS), .TRANS_ID_SIZE(TRANS_ID_SIZE), .CACHE_LINE_SIZE(CACHE_LINE_SIZE), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE))ic(.clk(clk), .reset(reset),
			.raddr0(ic_rd_addr[0]),
			.rhit0(ic_rd_hit[0]),
			.rdata0(ic_rd_data[0]),
	
			.raddr1(ic_rd_addr[1]),
			.rhit1(ic_rd_hit[1]),
			.rdata1(ic_rd_data[1]),

			.ic_snoop_addr(ic_snoop_addr),			// cache snoop interface
			.ic_snoop_addr_req(ic_snoop_addr_req),
			.ic_snoop_addr_ack(ic_snoop_addr_ack),
			.ic_snoop_snoop(ic_snoop_snoop),

			.ic_rdata_req(ic_rdata_req && !ic_rdata_trans[TRANS_ID_SIZE-1]),
			.ic_rdata(ic_rdata),
			.ic_rdata_resp(ic_rdata_resp),
			.ic_raddr(r_mem_addr[ic_rdata_trans[$clog2(NITOTAL)-1:0]]),

			.irand(irand),

			.dummy(1'b0)
		);

	
	itlb		#(.RV(RV), .VA_SZ(VA_SZ), .NHART(NHART), .LNHART(LNHART), .NPHYS(NPHYS), .TLB_SETS(0), .TLB_ENTRIES(32))itlb(.clk(clk), .reset(reset),
			.rd_vaddr_0(c_vaddr[0][VA_SZ-1:12]),
			.rd_asid_0(tlb_asid[0]),
			.rd_enable_0(tlb_enable[0]),
			.rd_valid_0(tlb_valid[0]),
			.rd_2mB_0(tlb_2mB[0]),
			.rd_4mB_0(tlb_4mB[0]),
			.rd_1gB_0(tlb_1gB[0]),
			.rd_512gB_0(tlb_512gB[0]),
			.rd_paddr_0(tlb_paddr[0]),
			.rd_aux_0(tlb_aux[0]),

			.rd_vaddr_1(c_vaddr[1][VA_SZ-1:12]),
			.rd_asid_1(tlb_asid[1]),
			.rd_enable_1(tlb_enable[1]),
			.rd_valid_1(tlb_valid[1]),
			.rd_2mB_1(tlb_2mB[1]),
			.rd_4mB_1(tlb_4mB[1]),
			.rd_1gB_1(tlb_1gB[1]),
			.rd_512gB_1(tlb_512gB[1]),
			.rd_paddr_1(tlb_paddr[1]),
			.rd_aux_1(tlb_aux[1]),

			.wr_entry(tlb_wr_data_req&tlb_wr_valid),
			.wr_vaddr(tlb_wr_data_vaddr),     // write path
			.wr_asid(sup_asid[tlb_wr_data_tid]),
			.wr_paddr(tlb_wr_paddr),
			.wr_gaux(tlb_wr_gaux),
			.wr_2mB(tlb_wr_2mB),
			.wr_4mB(tlb_wr_4mB),
			.wr_1gB(tlb_wr_1gB),
			.wr_512gB(tlb_wr_512gB),

			.wr_invalidate(tlb_wr_invalidate),
			.wr_invalidate_asid(tlb_wr_invalidate_asid),
			.wr_inv_unified(tlb_wr_inv_unified),
			.wr_inv_asid(tlb_wr_inv_asid),
			.wr_invalidate_addr(tlb_wr_invalidate_addr),
			.wr_inv_vaddr(tlb_wr_inv_vaddr)
		);

		// TLB fetcher shares this memory interface

		tlb_fetcher	#(.RV(RV), .VA_SZ(VA_SZ), .NHART(NHART), .LNHART(LNHART), .NPHYS(NPHYS), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .CACHE_LINE_SIZE(CACHE_LINE_SIZE), .LNCOMMIT(LNCOMMIT))tlbf(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
				.xxtrig(xxtrig),
`endif
				.i_asid(r_tlb_wr_asid),              // i$ read port
				.i_hart(r_tlb_wr_hart),
				.i_vaddr(r_tlb_wr_vaddr),
				.i_addr_tid(r_tlb_wr_addr_tid),
				.i_addr_req(r_tlb_wr_addr_req),
				.i_addr_ack(tlb_wr_addr_ack),
				.i_addr_cancel(1'b0),

				.i_data_req(tlb_wr_data_req),          // i$ response
				.i_data_tid(tlb_wr_data_tid),
				.i_data_vaddr(tlb_wr_data_vaddr),
				.i_paddr(tlb_wr_paddr),
				.i_gaux(tlb_wr_gaux),
				.i_2mB(tlb_wr_2mB),
				.i_4mB(tlb_wr_4mB),
				.i_1gB(tlb_wr_1gB),
				.i_512gB(tlb_wr_512gB),
				.i_valid(tlb_wr_valid),
				.i_pmp_fail(tlb_wr_valid_pmp),

				.d_asid(tlb_d_asid),					// d$ read port
				.d_hart(tlb_d_hart),
				.d_vaddr(tlb_d_vaddr),
				.d_addr_req(tlb_d_addr_req),
				.d_addr_tid(tlb_d_addr_tid),
				.d_addr_ack(tlb_d_addr_ack),
				.d_addr_cancel(tlb_d_addr_cancel),

				.d_data_req(tlb_d_data_req),			// d$ response
				.d_data_tid(tlb_d_data_tid),
				.d_paddr(tlb_d_paddr),
				.d_data_vaddr(tlb_d_data_vaddr),
				.d_data_asid(tlb_d_data_asid),
				.d_gaduwrx(tlb_d_gaduwrx),
				.d_2mB(tlb_d_2mB),
				.d_4mB(tlb_d_4mB),
				.d_1gB(tlb_d_1gB),
				.d_512gB(tlb_d_512gB),
				.d_valid(tlb_d_valid),
				.d_pmp_fail(tlb_d_pmp_fail),

				.sup_vm_mode_0(sup_vm_mode_0),
				.sup_asid_0(sup_asid_0),
				.sup_ppn_0(sup_ppn_0),

				.sup_vm_mode_1(sup_vm_mode_1),
				.sup_asid_1(sup_asid_1),
				.sup_ppn_1(sup_ppn_1),

				.wr_invalidate(tlb_wr_invalidate),
				.wr_invalidate_asid(tlb_wr_invalidate_asid),
				.wr_inv_unified(tlb_wr_inv_unified),
				.wr_inv_asid(tlb_wr_inv_asid),
				.wr_invalidate_addr(tlb_wr_invalidate_addr),
				.wr_inv_vaddr(tlb_wr_inv_vaddr),

				.ic_snoop_addr(ic_snoop_addr),			// cache snoop interface
				.ic_snoop_addr_req(ic_snoop_addr_req),
				.ic_snoop_snoop(ic_snoop_snoop),

				.ic_addr_req(tcache_addr_req),
				.ic_addr_ack(tcache_addr_ack|tcache_addr_fail),
				.ic_addr(tcache_addr),
				.ic_addr_sz(tcache_addr_sz),
				.ic_addr_trans(tcache_addr_trans),

				.ic_data_req(ic_rdata_req&&ic_rdata_trans[TRANS_ID_SIZE-1]),	// 6/7 used for tcache
				.ic_data_trans(ic_rdata_trans[TRANS_ID_SIZE-2:0]),
				.ic_data(ic_rdata)
		);

		//
		//	timing note - 2 clocks tcache_addr_hart->tcache_addr_fail and tcache_addr_sz->tcache_addr_fail
		//
		//	checking TLB fetches
		//
		pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))vm_pmp_check(
				.m(tcache_addr_hart?cpu_mode_1[3]:cpu_mode_0[3]),
				.su(tcache_addr_hart?(cpu_mode_1[1]|cpu_mode_1[0]):(cpu_mode_0[1]|cpu_mode_0[0])),
				.sz(tcache_addr_sz?2'h1:2'h0),	// 8 or 4
				.mprv(1'b0),
				.addr(tcache_addr),
				.check_x(1'b0),
				.check_r(1'b1),
				.check_w(1'b0),
				.fail(tcache_addr_fail),

				.pmp(pmp_0));	// FIXME - really need to switch between pmp_0 and pmp_1 on tcache_addr_hart here

`ifdef AWS_DEBUG
  ila_fetch ila_fetch(.clk(clk),
            .xxtrig(xxtrig),
            .reset(reset),
            .pc_0({pc_0[23:4], 4'b0}),    // 24
            .stall_0(stall_0),
            .fail_0(fail_0),
            .ok_0(ok_0),
            .trap_type0(trap_type_0),
            .fail0(fail[0]),
            .tlb_wr_data_req(tlb_wr_data_req),
            .tlb_wr_valid(tlb_wr_valid),
            .tlb_wr_valid_pmp(tlb_wr_valid_pmp),
            .rd_addr_ok0(rd_addr_ok[0]),
            .tlb_valid0(tlb_valid[0]),
            .rd_fail0(rd_fail[0]),
            .c_paddr0({c_paddr[0][23:4], 4'b0}),    // 24
            .r_tlb_wr_addr_req(r_tlb_wr_addr_req),
            .rd_prot0(rd_prot[0]),  // 4
            .trap_type_0(trap_type[0]), // 2
            .tlb_aux0(tlb_aux[0]),  // 3
            .misc({stall[1], tlb_miss[1], r_tlb_busy[1],  stall[0], tlb_miss[0], r_tlb_busy[0], r_last_tlb, r_tlb_wr_addr_req&~tlb_wr_addr_ack}), // 8
            .tlb_wr_data_vaddr(tlb_wr_data_vaddr[12+23:12]),    // 24
            .c_vaddr0(c_vaddr[0][12+23:12]),    // 24
            .allocate0(allocate[0]),
            .tlb_wr_data_tid(tlb_wr_data_tid),
            .r_tlb_wr_addr_tid(r_tlb_wr_addr_tid),
            .loading_0(loading[0]), // 8
            .r_mem_busy(r_mem_busy),  // 8
            .ic_addr_req(ic_raddr_req),
            .ic_addr(ic_raddr), // 24
            .ic_addr_trans(ic_raddr_trans), // 5
            .ic_data_req(ic_rdata_req),
            .ic_data_trans(ic_rdata_trans) // 5
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



