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

`include "lstypes.si"

module load_store(
	input clk,
	input reset, 
`ifdef SIMD
	input simd_enable,
`endif
`ifdef AWS_DEBUG
	input cpu_trig,
	output cpu_trig_ack,
	input xxtrig,
	output ls_trig,
`endif

	LS_ADDR ls,		// load/store address phase

	LS_VM_ACK   vm_ack,		// VM req done
	
	LD_DATA_WB	ld_wb,	// load data done

	ST_DATA		st, 

	LS_READY            ls_ready, // 
	
	input 	[NCOMMIT-1:0]store_commit_0,	// one per HART
	input 	[NCOMMIT-1:0]commit_kill_0,		// one per HART
	input 	[NCOMMIT-1:0]commit_completed_0,	// one per HART
	input 	[NCOMMIT-1:0]commit_commitable_0,	// one per HART
	//input 	[NCOMMIT-1:0]store_commit_1,	// one per HART
	//input 	[NCOMMIT-1:0]commit_kill_1,		// one per HART
	//input 	[NCOMMIT-1:0]commit_completed_1,	// one per HART
	//input 	[NCOMMIT-1:0]commit_commitable_1,// one per HART

	input [ 3: 0]cpu_mode_0,
	input [ 3: 0]sup_vm_mode_0,
	input [15: 0]sup_asid_0,
	input        sup_vm_sum_0,
	input        mxr_0,
	input	[3:0]mprv_0,
	input [NHART-1:0]unified_asid,

	input [ 3: 0]cpu_mode_1,
	//input [ 3: 0]sup_vm_mode_1,
	//input [15: 0]sup_asid_1,
	//input        sup_vm_sum_1,
	//input        mxr_1,
	//input	  [3:0]mprv_1;

	//-------

    output[NPHYS-1:ACACHE_LINE_SIZE]dc_raddr,
    output      dc_raddr_req,
    input       dc_raddr_ack,
	output [TRANS_ID_SIZE-1:0]dc_raddr_trans,
	output [2:0]dc_raddr_snoop,

    input  [CACHE_LINE_SIZE-1:0]dc_rdata,
	input  [TRANS_ID_SIZE-1:0]dc_rdata_trans,
    input       dc_rdata_req,
    output      dc_rdata_ack,
	input  [2:0]dc_rdata_resp,

    output[NPHYS-1:ACACHE_LINE_SIZE]dc_waddr,
    output      dc_waddr_req,
    input       dc_waddr_ack,
    output [1:0]dc_waddr_snoop,
    output [TRANS_ID_SIZE-1:0]dc_waddr_trans,
    output[CACHE_LINE_SIZE-1:0]dc_wdata,

	input    [TRANS_ID_SIZE-1:0]dc_wdata_trans,
	input 	     dc_wdata_done,

	input [NPHYS-1:ACACHE_LINE_SIZE]dc_snoop_addr,
	input 	    dc_snoop_addr_req,
	output 	    dc_snoop_addr_ack,
	input  [1:0]dc_snoop_snoop,

	output [2:0]dc_snoop_data_resp,
	output[CACHE_LINE_SIZE-1:0]dc_snoop_data,

	output	           io_cpu_addr_req,
	input	           io_cpu_addr_ack,
	output	[NPHYS-1:0]io_cpu_addr,
	output			   io_cpu_read,
	output			   io_cpu_lock,
	output	      [7:0]io_cpu_mask,
	output	   [RV-1:0]io_cpu_wdata,
	input			   io_cpu_data_req,
	output			   io_cpu_data_ack,
	input	   [RV-1:0]io_cpu_rdata,
	input		       io_cpu_data_err,

    output       tlb_wr_invalidate,
    output       tlb_wr_invalidate_asid,
	output		 tlb_wr_inv_unified,
    output       tlb_wr_invalidate_addr,
    output [VA_SZ-1:12]tlb_wr_inv_vaddr,     
    output   [15:0]tlb_wr_inv_asid,

	input		irand,
	output		orand,

	PMP			pmp_0,				// PMP  per HART
	//PMP		pmp_1,			

	output    [15:0]tlb_d_asid,              // TLB L2 req
    output[(NHART==1?0:LNHART-1):0]tlb_d_hart,
    output [VA_SZ-1:12]tlb_d_vaddr,
	output[LNCOMMIT-1:0]tlb_d_addr_tid,
    output        tlb_d_addr_req,
    input         tlb_d_addr_ack,
    output        tlb_d_addr_cancel,

    input         tlb_d_data_req,          // TLB L2 ack
	input[LNCOMMIT-1:0]tlb_d_data_tid,
	input[VA_SZ-1:12]tlb_d_data_vaddr,
	input   [15: 0]tlb_d_data_asid,
    input[NPHYS-1:12]tlb_d_paddr,
    input   [6:0] tlb_d_gaduwrx,
    input         tlb_d_2mB,
    input         tlb_d_4mB,
    input         tlb_d_1gB,
    input         tlb_d_512gB,
    input         tlb_d_valid,
	input		  tlb_d_pmp_fail,

	input dummy);

    parameter CNTRL_SIZE=7;
    parameter ADDR=0;
    parameter NHART=1;
 	parameter RV=64;
    parameter LNHART=0;
	parameter NUM_PMP=5;
    parameter NCOMMIT = 32; // number of commit registers
    parameter LNCOMMIT = 5; // number of bits to encode that
 	parameter RA=5;
	parameter NADDR=6;	// number of vaddr translation units
	parameter NLOAD=4;	// number of load instruction units (also number of read ports to cache)
	parameter NSTORE=4;	// number of store instruction units
	parameter NWPORT=1;	// number of write ports to cache
	parameter NLDSTQ=16;
	parameter NPHYS=56;
	parameter VA_SZ=48;
	parameter TRANS_ID_SIZE=6;
	parameter CACHE_LINE_SIZE=64*8;
	parameter ACACHE_LINE_SIZE=6;
	parameter CACHE_ADDR=$clog2(CACHE_LINE_SIZE/8);

`include "cache_protocol.si"

	wire [ 3: 0]cpu_mode[0:NHART-1];
	wire [ 3: 0]mprv[0:NHART-1];
	wire [ 3: 0]sup_vm_mode[0:NHART-1];
	wire [15: 0]sup_asid[0:NHART-1];
	wire [NHART-1:0]sup_vm_sum;
	wire [NHART-1:0]mxr;

	assign cpu_mode[0] = cpu_mode_0;
	assign mprv[0] = mprv_0;
	assign sup_vm_mode[0] = sup_vm_mode_0;
	assign sup_asid[0] = sup_asid_0;
	assign sup_vm_sum[0] = sup_vm_sum_0;
	assign mxr[0] = mxr_0;

	//assign cpu_mode[1] = cpu_mode_1;
	//assign mprv[1] = mprv_1;
	//assign sup_vm_mode[1] = sup_vm_mode_1;
	//assign sup_asid[1] = sup_asid_1;
	//assign sup_vm_sum[1] = sup_vm_sum_1;
	//assign mxr[1] = mxr_1;
	wire	  [3:0]mprv_1;	// FIXME just to keep synth happy

	wire 	[NCOMMIT-1:0]store_commit[0:NHART-1];	// one per HART
	wire 	[NCOMMIT-1:0]commit_kill[0:NHART-1];	// one per HART
	wire 	[NCOMMIT-1:0]commit_completed[0:NHART-1];	// one per HART
	wire 	[NCOMMIT-1:0]commit_commitable[0:NHART-1];	// one per HART
	assign store_commit[0] = store_commit_0;
	assign commit_kill[0] = commit_kill_0;
	assign commit_completed[0] = commit_completed_0;
	assign commit_commitable[0] = commit_commitable_0;
	//assign store_commit[1] = store_commit_1;
	//assign commit_kill[1] = commit_kill_1;
	//assign commit_completed[1] = commit_completed_1;
	//assign commit_commitable[1] = commit_commitable_1;

	//
	//	load:		unit_type == 3
    //   
	//  4 - amo  (1 means LC)
	//	3 - int/fp
	//	2 - not sign extended (load only)
	//	1:0 - size 0 - 1 byte
	//			   1 - 2
	//			   2 - 4
	//			   3 - 8
	//
	//	store:		unit_type == 4
    //   
	//	5 - 0				
	//  4 - amo
	//	3 - int/fp		
	//	2 - not sign extended (load only)
	//	1:0 - size 0 - 1 byte
	//			   1 - 2
	//			   2 - 4
	//			   3 - 8
	//
	//	fence:		unit_type == 4
    //   
	//	5 - 1
	//  4		- rs1==0
	//	3		- rs2==0
	//	2:0 - size 0 - sfence.vma
	//			   1 - hfence.vvma
	//		       2 - hfence.gvma
	//		       3 - fence.i
	//			   4 - fence
	//
	//		immed:
	//				31:	fm == 1000
	//				30: pi		before (this instruction can never move before any of these)
	//				29: po
	//				28: pr
	//				27: pw
	//				26: si		after (later instructions must wait for this one)
	//				25: so
	//				24: sr
	//				23: sw
	//
	//				26: aq		no later instruction can be executed before this one
	//				25: rl		no prior instruction can be executed after this one
	//				


	reg      [NADDR-1:0]r_addr_busy;
	reg            [1:0]r_addr_aq_rl[0:NADDR-1];
	reg           [31:0]r_addr_immed[0:NADDR-1];
	reg [CNTRL_SIZE-1:0]r_addr_control[0:NADDR-1];
	reg      [NADDR-1:0]r_addr_load;
	reg   [LNCOMMIT-1:0]r_addr_rd[0:NADDR-1];
	reg   [LNCOMMIT-1:0]c_addr_rd[0:NADDR-1];
	reg      [NADDR-1:0]r_addr_makes_rd;
	reg      [NADDR-1:0]r_addr_vm_stall, c_addr_vm_stall;
	reg      [NADDR-1:0]r_addr_vm_pause, c_addr_vm_pause;
	wire[(NHART==1?0:LNHART-1):0]addr_hart[0:NADDR-1];

	reg       [RV-1:0]addr_v[0:NADDR-1];	// pre TLB virt addres
	reg      [NPHYS:0]addr_p[0:NADDR-1];	// post TLB phys addres
	reg[(RV==64?7:3):0]addr_mask[0:NADDR-1];
	wire  [NADDR-1:0]addr_match_mask[0:NHART-1][0:NCOMMIT-1];
	wire   [NADDR-1:0]addr_io;
	wire   [NADDR-1:0]addr_is_ok;
	wire   [NADDR-1:0]addr_fence;
	reg         [4:0]r_addr_amo[0:NADDR-1];
	reg    [NADDR-1:0]addr_enable;
	reg          [1:0]addr_fd[0:NADDR-1];
	reg [LNCOMMIT-1:0]addr_rd[0:NADDR-1];
	reg  [NCOMMIT-1:0]addr_soft_hazard[0:NADDR-1];		// soft hazards are address based and might change when another address is resolved
	reg  [NCOMMIT-1:0]addr_hard_hazard[0:NADDR-1];		// hard hazards are aq/rl or fence based and can't change 
	reg          [3:0]addr_blocks[0:NADDR-1];
	reg          [3:0]addr_isblocked[0:NADDR-1];

	//
	//		active transaction DB
	//

	reg [NCOMMIT-1:0]r_c_valid[0:NHART-1];
	reg [NCOMMIT-1:0]c_c_valid[0:NHART-1];
`ifdef FP
	reg [NCOMMIT-1:0]r_c_fp[0:NHART-1];
	reg [NCOMMIT-1:0]c_c_fp[0:NHART-1];
`endif
	reg [NCOMMIT-1:0]r_c_load[0:NHART-1];
	reg [NCOMMIT-1:0]c_c_load[0:NHART-1];
	reg [NCOMMIT-1:0]r_c_fence[0:NHART-1];
	reg [NCOMMIT-1:0]c_c_fence[0:NHART-1];
	reg [NCOMMIT-1:0]r_c_io[0:NHART-1];
	reg [NCOMMIT-1:0]c_c_io[0:NHART-1];
	reg [NCOMMIT-1:0]r_c_makes_rd[0:NHART-1];
	reg [NCOMMIT-1:0]c_c_makes_rd[0:NHART-1];
	reg         [4:0]r_c_amo[0:NHART-1][0:NCOMMIT-1];
	reg         [4:0]c_c_amo[0:NHART-1][0:NCOMMIT-1];
	reg   [NPHYS-1:0]r_c_paddr[0:NHART-1][0:NCOMMIT-1];
	reg   [NPHYS-1:0]c_c_paddr[0:NHART-1][0:NCOMMIT-1];
	reg [CNTRL_SIZE-1:0]r_c_control[0:NHART-1][0:NCOMMIT-1];
	reg [CNTRL_SIZE-1:0]c_c_control[0:NHART-1][0:NCOMMIT-1];
	reg          [1:0]r_c_aq_rl[0:NHART-1][0:NCOMMIT-1];
	reg          [1:0]c_c_aq_rl[0:NHART-1][0:NCOMMIT-1];
	reg [(RV==64?7:3):0]r_c_mask[0:NHART-1][0:NCOMMIT-1];
	reg [(RV==64?7:3):0]c_c_mask[0:NHART-1][0:NCOMMIT-1];
	reg [NCOMMIT-1:0]r_c_soft_hazard[0:NHART-1][0:NCOMMIT-1];
	reg [NCOMMIT-1:0]c_c_soft_hazard[0:NHART-1][0:NCOMMIT-1];
	reg [NCOMMIT-1:0]r_c_hard_hazard[0:NHART-1][0:NCOMMIT-1];
	reg [NCOMMIT-1:0]c_c_hard_hazard[0:NHART-1][0:NCOMMIT-1];
	reg         [3:0]r_c_block[0:NHART-1][0:NCOMMIT-1];
	reg         [3:0]c_c_block[0:NHART-1][0:NCOMMIT-1];
	reg         [1:0]r_c_fd[0:NHART-1][0:NCOMMIT-1];
	reg         [1:0]c_c_fd[0:NHART-1][0:NCOMMIT-1];
	reg [NCOMMIT-1:0]hazard_clear_load[0:NHART-1];
	reg [NCOMMIT-1:0]hazard_clear_store[0:NHART-1];

	//
	//	load controller
	//

	reg [$clog2(NLDSTQ)-1:0]load_qindex[0:NLOAD-1];
	reg	[NLOAD-1:0]load_hazard;
	wire [NLOAD-1:0]load_enable;
	reg  [NLOAD-1:0]r_load_enable, xload_enable;
	reg [LNCOMMIT-1:0]r_load_rd[0:NLOAD-1];
	reg [LNCOMMIT-1:0]load_rd[0:NLOAD-1];
	reg [(NHART==1?0:LNHART-1):0]r_load_hart[0:NLOAD-1];
	wire [(NHART==1?0:LNHART-1):0]load_hart[0:NLOAD-1];
	reg [RV/8-1:0]r_load_mask[0:NLOAD-1];
	reg [CNTRL_SIZE-1:0]r_load_control[0:NLOAD-1];
	reg [1:0]r_load_aq_rl[0:NLOAD-1];
	reg [NPHYS-1:0]r_load_paddr[0:NLOAD-1];
	reg [NPHYS-1:0]c_load_paddr[0:NLOAD-1];
	reg [NLOAD-1:0]r_load_io, c_load_io;
	reg [NLOAD-1:0]r_load_sc;
	reg [NLOAD-1:0]r_load_sc_okv;
	reg [NLOAD-1:0]r_load_amo;
`ifdef FP
	reg [NLOAD-1:0]r_load_fp;
`endif
	reg [NLOAD-1:0]r_load_makes_rd;
	reg [NLOAD-1:0]r_load_queued, load_queued;
	reg  [NLOAD-1:0]load_allocate;
    reg  [$clog2(NLDSTQ)-1:0]r_load_ack_entry[0:NLOAD-1];

	wire	[NLDSTQ-1:0]depends[0:NLDSTQ-1];
	LOAD_SNOOP #(.NLDSTQ(NLDSTQ), .NPHYS(NPHYS), .LNHART(LNHART), .NHART(NHART), .NLOAD(NLOAD), .RV(RV))load_snoop();

	reg [RV-1:0]r_load_res_data[0:NLOAD-1];
	reg [(NHART==1?0:LNHART-1):0]r_load_res_hart[0:NLOAD-1];
	reg [LNCOMMIT-1:0]r_load_res_rd[0:NLOAD-1];
	reg [NLOAD-1:0]r_load_res_makes_rd;
`ifdef FP
	reg [NLOAD-1:0]r_load_res_fp;
`endif
	reg [NLOAD-1:0]r_load_res_done;
	reg [RV-1:0]load_snoop_result[0:NLOAD-1];
	wire [NLDSTQ-1:0]load_snoop_hit_mask[0:NLOAD-1];

	DCACHE_LOAD		#(.RV(RV), .NPHYS(NPHYS), .NLOAD(NLOAD))dc_load();

	//
	//	store controller
	//

	reg [NSTORE-1: 0]store_enable, xstore_enable;
	wire [LNHART-1:0]store_hart[0:NSTORE-1];
	reg [LNCOMMIT-1: 0]store_rd[0:NSTORE-1];

	reg [NSTORE-1:0]r_store_enable;
	reg [(NHART==1?0:LNHART-1):0]r_store_hart[0:NLOAD-1];
	reg[LNCOMMIT-1:0]r_store_rd[0:NSTORE-1];
`ifdef FP
	reg [NSTORE-1:0]r_store_fp, c_store_fp;
`endif
	reg [NSTORE-1:0]r_store_io, c_store_io;
	reg [NSTORE-1:0]r_store_fence, c_store_fence;
	reg [NSTORE-1:0]r_store_makes_rd, c_store_makes_rd;
	reg       [4:0]r_store_amo[0:NSTORE-1];
	reg       [4:0]c_store_amo[0:NSTORE-1];
	reg [NPHYS-1:0]r_store_paddr[0:NSTORE-1];
	reg [NPHYS-1:0]c_store_paddr[0:NSTORE-1];
	reg [CNTRL_SIZE-1:0]r_store_control[0:NSTORE-1];
	reg [CNTRL_SIZE-1:0]c_store_control[0:NSTORE-1];
	reg			[1:0]r_store_fd[0:NSTORE-1];
	reg			[1:0]c_store_fd[0:NSTORE-1];
	reg         [1:0]r_store_aq_rl[0:NSTORE-1];
	reg         [1:0]c_store_aq_rl[0:NSTORE-1];

	reg [RV-1:0]store_data[0:NSTORE-1];
	reg [RV/8-1:0]store_mask[0:NSTORE-1];

	STORE_SNOOP #(.NLDSTQ(NLDSTQ), .NPHYS(NPHYS), .RV(RV), .NSTORE(NSTORE))store_snoop();

	wire [NLDSTQ-1:0]store_hazard[0:NSTORE-1];
	wire [NSTORE-1:0]store_allocate;

	//
	
	wire [$clog2(NLDSTQ):0]num_free;
	reg [$clog2(NLDSTQ):0]num_load_unused;
	reg [$clog2(NLDSTQ):0]num_store_unused;
	reg [$clog2(NLDSTQ):0]num_load_used;
	reg [$clog2(NLDSTQ):0]num_store_used;

	reg	 [$clog2(NLDSTQ):0]r_num_available;
	always @(posedge clk) begin
		if (reset) begin
			r_num_available <= NLDSTQ;
		end else begin
			r_num_available <= r_num_available - (num_store_used+num_load_used) + (num_load_unused+num_store_unused+num_free);
		end
	end

	//

    wire [RV-1:0]dc_rd_data[0:NLOAD-1];
wire [RV-1:0]dc_rd_data_0=dc_rd_data[0];
	reg [(NHART==1?0:LNHART-1):0]dc_rd_hart[0:NLOAD-1];
	reg	 [NLOAD-1:0]dc_rd_lr;

	wire  [NWPORT-1:0]dc_wr_enable;             // CPU write port
    wire [NPHYS-1:$clog2(RV/8)]dc_wr_addr[0:NWPORT-1];
    wire [RV-1:0]dc_wr_data[0:NWPORT-1];
    wire [(RV/8)-1:0]dc_wr_mask[0:NWPORT-1];
    wire [(NHART==1?0:LNHART-1):0]dc_wr_hart[0:NWPORT-1];
    wire [5:0]dc_wr_amo[0:NWPORT-1];

    wire  [NWPORT-1:0]dc_wr_sc;
    wire  [NWPORT-1:0]dc_wr_hit_ok_write;			// write hit
    wire  [NWPORT-1:0]dc_wr_hit_must_invalidate;	// ??
    wire  [NWPORT-1:0]dc_wr_wait;					// write must wait

	wire [RV-1:0]load_snoop_data[0:NLDSTQ-1];
	wire [LNCOMMIT-1:0]wq_rd[0:NLDSTQ-1];
`ifdef FP
	wire [NLDSTQ-1:0]wq_fp;
`endif
	wire [NLDSTQ-1:0]wq_makes_rd;
	wire [(NHART==1?0:LNHART-1):0]wq_hart[0:NLDSTQ-1];
	wire [3:0]wq_control[0:NLDSTQ-1];
	wire [5:0]wq_amo[0:NLDSTQ-1];
	wire [1:0]wq_aq_rl[0:NLDSTQ-1];

	wire [$clog2(NSTORE+NLOAD+1)-1:0]num_allocate;

    reg [NPHYS-1:ACACHE_LINE_SIZE]dc_raddr_out;
	assign	dc_raddr = dc_raddr_out;
    reg        dc_raddr_req_out;
    assign      dc_raddr_req = dc_raddr_req_out;
	reg [TRANS_ID_SIZE-1:0]dc_raddr_trans_out;
	assign dc_raddr_trans = dc_raddr_trans_out;
	reg [2:0]dc_raddr_snoop_out;
	assign	dc_raddr_snoop = dc_raddr_snoop_out;

	reg [NPHYS-1:ACACHE_LINE_SIZE]r_reserved_address[0:NHART-1];	// reserved for LR/SC
	reg [NPHYS-1:ACACHE_LINE_SIZE]c_reserved_address[0:NHART-1];
	reg [NHART-1:0]r_reserved_address_set, c_reserved_address_set;

	wire [NHART-1:0]hart_vm_pause;
	reg  [NHART-1:0]r_hart_vm_pause;


	wire [NLDSTQ-1:0]free;
	wire [NLDSTQ-1:0]q_load_ready;
	wire [NLDSTQ-1:0]store_mem;	// write strobe
	reg [NLDSTQ-1:0]store_ack;

	wire [NPHYS-1:0]write_mem_addr[0:NLDSTQ-1];
	wire [NLDSTQ-1:0]write_mem_io;
	wire [RV-1:0]write_mem_data[0:NLDSTQ-1];
	wire [(RV/8)-1:0]write_mem_mask[0:NLDSTQ-1];
	reg  [5:0]write_mem_amo[0:NLDSTQ-1];
wire [5:0]write_mem_amo_1 = write_mem_amo[1];
	wire [(NHART==1?0:LNHART-1):0]write_mem_hart[0:NLDSTQ-1];
	wire [NLDSTQ-1:0]write_mem_sc;
	wire [NLDSTQ-1:0]write_mem_sc_okv;
	reg [NPHYS-1:$clog2(RV/8)]q_mem_addr;
	reg q_mem_io;
	reg [RV-1:0]q_mem_data;
	reg [(NHART==1?0:LNHART-1):0]q_mem_hart;
	reg       q_mem_sc;
	reg  [5:0]q_mem_amo;
	reg [(RV/8)-1:0]q_mem_mask;
	wire [NLDSTQ-1:0]mem_read_req;
	wire [NLDSTQ-1:0]mem_read_cancel;
	wire [NLDSTQ-1:0]mem_write_req;
	wire [NLDSTQ-1:0]mem_write_invalidate;
	reg  [$clog2(NLDSTQ)-1:0]mem_req;


	TLB	#(.VA_SZ(VA_SZ), .NPHYS(NPHYS), .NADDR(NADDR))dtlb();		// DTLB interface

	reg [$clog2(NLDSTQ)-1:0]num_ldstq_avail;

	wire [NLDSTQ-1:0]q_allocate;
	wire [NLDSTQ-1:0]q_load;
    wire [NLDSTQ-1:0]q_store;
    wire [NLDSTQ-1:0]q_fence;
    reg  [NPHYS-1:0]q_addr[0:NLDSTQ-1];
    wire [NLDSTQ-1:0]q_io;
    wire [5:0]q_amo[0:NLDSTQ-1];
    reg  [RV-1:0]q_data[0:NLDSTQ-1];
    reg  [(RV/8)-1:0]q_mask[0:NLDSTQ-1];
    reg  [(NHART==1?0:LNHART-1):0]q_hart[0:NLDSTQ-1];
    reg  [2:0]q_control[0:NLDSTQ-1];
    reg  [LNCOMMIT-1:0]q_rd[0:NLDSTQ-1];
`ifdef FP
    reg  [NLDSTQ-1:0]q_fp;
`endif
    reg  [1:0]q_aq_rl[0:NLDSTQ-1];
    wire [1:0]q_fd[0:NLDSTQ-1];
    reg  [NLDSTQ-1:0]q_hazard[0:NLDSTQ-1];
    reg  [NLDSTQ-1:0]q_line_busy;
    reg  [$clog2(NLDSTQ)-1:0]q_line_busy_index[0:NLDSTQ-1];
    wire [NLDSTQ-1:0]q_load_ack;
    wire [NLDSTQ-1:0]q_load_ack_fail;
    reg  [NLDSTQ-1:0]q_makes_rd;
    wire [NLDSTQ-1:0]q_cache_miss;
	reg  [$clog2(NLOAD)-1:0]q_load_unit_s0;

	reg	 [$clog2(NLDSTQ)-1:0]load_line_busy_index[0:NLOAD-1];
	reg	 [$clog2(NLDSTQ)-1:0]store_line_busy_index[0:NSTORE-1];

	wire [1:0]q_fence_type[0:NLDSTQ-1];
	wire [1:0]fence_tlb_inv_type[0:NLDSTQ-1];
	reg [1:0]tlb_inv_type;
	wire [NLDSTQ-1:0]fence_tlb_invalidate;
	reg [VA_SZ-1:12]tlb_inv_addr;
	reg [15:0]tlb_inv_asid;
	reg [(NHART==1?0:LNHART-1):0]tlb_inv_hart;
	
    wire [NLDSTQ-1:0]all_active;
    wire [NLDSTQ-1:0]store_mem_hit = dc_wr_hit_ok_write[0]?store_mem&store_ack:0;

	wire [NLDSTQ-1:0]write_io_read_req, write_io_write_req;
	wire [NLDSTQ-1:0]write_io_lock;
	reg [NLDSTQ-1:0]io_ack;

	wire [NCOMMIT-1:0]addr_rdy[0:NHART-1];	// for mk15*
	reg [NCOMMIT-1:0]addr_inh[0:NADDR-2];
	wire [NCOMMIT-1:0]ld_rdy[0:NHART-1];
	reg [(NLDSTQ+NCOMMIT)-1:0]ld_inh[0:NLOAD-2];
	wire [NCOMMIT-1:0]st_rdy[0:NHART-1];
	reg [NCOMMIT-1:0]st_inh[0:NSTORE-2];


	genvar C, D, A, H, I, L, S;
	generate

		if (NCOMMIT == 32 && NADDR == 6 && NLOAD == 4 && NSTORE == 4 && NLDSTQ == 16) begin
`include "mk21_32_6_4_4_16.inc"
		end else
		if (NCOMMIT == 32 && NADDR == 6 && NLOAD == 4 && NSTORE == 4 && NLDSTQ == 32) begin
`include "mk21_32_6_4_4_32.inc"
		end else
		if (NCOMMIT == 32 && ADDR == 4 && NLOAD == 2 && NSTORE == 2 && NLDSTQ == 16) begin
`include "mk21_32_4_2_2_16.inc"
		end else
		if (NCOMMIT == 32 && ADDR == 4 && NLOAD == 2 && NSTORE == 2 && NLDSTQ == 32) begin
`include "mk21_32_4_2_2_32.inc"
		end 

		for (A = 0; A < NADDR; A=A+1) begin: addr

			assign ls.sched[A].enable = addr_enable[A];
			assign ls.sched[A].rd  = addr_rd[A];
			assign ls.sched[A].hart = addr_hart[A];

			wire            addr_pmp_fail;
			wire [NHART-1:0]addr_pmp_fail_h;
			wire       [3:0]addr_cpu_mode;
			wire	   [3:0]addr_mprv;
			wire			addr_mxr;
			wire	   [3:0]addr_sup_vm_mode;
			wire	  [15:0]addr_sup_asid;
			wire			addr_sup_vm_sum;

			assign addr_cpu_mode = cpu_mode[addr_hart[A]];
			assign addr_mprv = mprv[addr_hart[A]];
			assign addr_sup_vm_mode = sup_vm_mode[addr_hart[A]];
			assign addr_sup_asid = sup_asid[addr_hart[A]];
			assign addr_sup_vm_sum = sup_vm_sum[addr_hart[A]];
			assign addr_mxr = mxr[addr_hart[A]];

			assign addr_pmp_fail = addr_pmp_fail_h[addr_hart[A]];

			assign dtlb.req[A].enable = r_addr_busy[A]&&(!addr_mprv[3])&&!addr_fence[A];
			assign dtlb.req[A].vaddr = addr_v[A][RV-1:12];
			assign dtlb.req[A].asid = addr_sup_asid;


			for (H = 0; H < NHART; H=H+1) begin: pmp
				if (H == 0) begin
					pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))pmp_check(
						.m(mprv[H][3]),
						.su(mprv[H][1]|mprv[H][0]),
						.mprv(1'b0),
						.addr(addr_p[A][NPHYS-1:2]),
						.sz({1'b0,r_addr_control[A][1:0]==3?1'b1:1'b0}),
						.check_x(cpu_mode[H][3]&&addr_mxr&&r_addr_load[A]),
						.check_r(r_addr_load[A]),
						.check_w(!r_addr_load[A]),
						.fail(addr_pmp_fail_h[H]),
						.pmp(pmp_0));	// FIXME for 2nd hart
				end
			end

			if (RV == 64) begin
				always @(*) 
					addr_v[A] = ls.req[A].r1+{{RV-32{r_addr_immed[A][31]}},r_addr_immed[A]};
				always @(*) begin
					casez ({addr_mprv[3], dtlb.ack[A].valid, addr_sup_vm_mode}) // synthesis full_case parallel_case
					6'b1_?_????, 
					6'b0_0_???0, 
					6'b0_?_???1:begin
									addr_p[A]  = addr_v[A][NPHYS-1:0];
									addr_io[A] = addr_v[A][NPHYS-1];
								end
					6'b0_1_??1?:begin
									addr_p[A]  = {dtlb.ack[A].paddr[NPHYS-1:22],
												  dtlb.ack[A].is4mB?addr_v[A][21:12]:dtlb.ack[A].paddr[21:12],
												  addr_v[A][11:0]};
									addr_io[A] = dtlb.ack[A].paddr[NPHYS-1];
								end
					6'b0_1_?1??:begin
									addr_p[A]  = {dtlb.ack[A].paddr[NPHYS-1:30],
											  	  dtlb.ack[A].is1gB?addr_v[A][29:21]:dtlb.ack[A].paddr[29:21],
												  dtlb.ack[A].is2mB?addr_v[A][20:12]:dtlb.ack[A].paddr[20:12],
												  addr_v[A][11:0]};
									addr_io[A] = dtlb.ack[A].paddr[NPHYS-1];
								end
					6'b0_1_1???:begin
									addr_p[A]  = {dtlb.ack[A].paddr[NPHYS-1:39],
												  dtlb.ack[A].is512gB?addr_v[A][38:30]:dtlb.ack[A].paddr[38:30],
												  dtlb.ack[A].is1gB?  addr_v[A][29:21]:dtlb.ack[A].paddr[29:21],
												  dtlb.ack[A].is2mB?  addr_v[A][20:12]:dtlb.ack[A].paddr[20:12],
												  addr_v[A][11:0]};
									addr_io[A] = dtlb.ack[A].paddr[NPHYS-1];
								end
					default: begin addr_p[A] = 'bx; addr_io[A] = 1'bx; end
					endcase
				end
			end else begin
				always @(*) 
					addr_v[A] = ls.req[A].r1+r_addr_immed[A];
				always @(*) begin
					casez ({addr_mprv[3], dtlb.ack[A].valid, addr_sup_vm_mode[1:0]}) // synthesis full_case parallel_case
					4'b1_?_??, 
					4'b1_0_?1,
					4'b0_?_?1: addr_p[A] = addr_v[A][NPHYS-1:0];
					4'b0_1_1?: addr_p[A] = {dtlb.ack[A].paddr[NPHYS-1:22],
										    dtlb.ack[A].is4mB?addr_v[A][21:10]:dtlb.ack[A].paddr[21:10],
										    addr_v[A][11:0]};
					default:   addr_p[A] = 'bx; 
					endcase
					addr_io[A] = 0; // FIXME maybe
				end
			end


			reg		 addr_alignment_bad;
			reg		 addr_ok;
			reg	[3:0]prot;
			reg [1:0]trap_type;

			always @(*) begin
				prot = 4'bxxxx;
				if (r_addr_load[A]) begin
					casez({addr_mprv, addr_sup_vm_mode[0], addr_sup_vm_sum, dtlb.ack[A].valid, addr_mxr&dtlb.ack[A].aduwrx[0], dtlb.ack[A].aduwrx[5:1], addr_pmp_fail}) // synthesis full_case parallel_case
					14'b1???_?_?_?_?_?????_0: prot = 4'b0001;	// M mode
					14'b1???_?_?_?_?_?????_1: prot = 4'b0100;	// M mode - locked
	
					14'b??1?_1_?_0_?_?????_0,					// turned off
					14'b???1_1_?_0_?_?????_0: prot = 4'b0001;	// turned off
					14'b??1?_1_?_0_?_?????_1,					// turned off pmp fault
					14'b???1_1_?_0_?_?????_1: prot = 4'b0100;	// turned off pmp fault
	
					14'b??1?_0_?_0_?_?????_?: prot = 4'b1000;	// sup tlb miss (handled by attempting to fetch)
					14'b??1?_0_?_1_?_0?0??_?: prot = 4'b0010;	// sup tlb not A
					14'b??1?_0_?_1_0_1?0?0_?: prot = 4'b0010;	// sup tlb read not OK
					14'b??1?_0_?_1_1_1?0?0_0: prot = 4'b0001;	// sup tbl read OK
					14'b??1?_0_?_1_?_1?0?1_0: prot = 4'b0001;	// sup tbl read OK
					14'b??1?_0_?_1_1_1?0?0_1: prot = 4'b0100;	// sup tbl read OK	pmp fail
					14'b??1?_0_?_1_?_1?0?1_1: prot = 4'b0100;	// sup tbl read OK	pmp fail
	
					14'b??1?_0_0_1_?_??1??_?: prot = 4'b0010;	// sup tlb read not OK
					14'b??1?_0_1_1_?_0?1??_?: prot = 4'b0010;	// sup tlb read not A
					14'b??1?_0_1_1_0_1?1?0_?: prot = 4'b0010;	// sup tlb read not OK
					14'b??1?_0_1_1_1_1?1?0_0: prot = 4'b0001;	// sup tbl read OK
					14'b??1?_0_1_1_?_1?1?1_0: prot = 4'b0001;	// sup tbl read OK
					14'b??1?_0_1_1_1_1?1?0_1: prot = 4'b0100;	// sup tbl read OK  pmp fail
					14'b??1?_0_1_1_?_1?1?1_1: prot = 4'b0100;	// sup tbl read OK  pmp fail
	
					14'b???1_0_?_0_?_?????_?: prot = 4'b1000;	// usr tlb miss (handled by attempting to fetch)
					14'b???1_0_?_1_?_??0??_?: prot = 4'b0010;	// usr tlb read sup page
					14'b???1_0_?_1_?_0?1??_?: prot = 4'b0010;	// usr tlb read not A
					14'b???1_0_?_1_0_1?1?0_?: prot = 4'b0010;	// usr tlb read not OK
					14'b???1_0_?_1_1_1?1?0_0: prot = 4'b0001;	// usr tbl read OK
					14'b???1_0_?_1_?_1?1?1_0: prot = 4'b0001;	// usr tbl read OK
					14'b???1_0_?_1_1_1?1?0_1: prot = 4'b0100;	// usr tbl read OK pmp
					14'b???1_0_?_1_?_1?1?1_1: prot = 4'b0100;	// usr tbl read OK pmp
					default: prot = 4'bxxxx; 
					endcase	
				end else begin	// else store
					casez ({addr_mprv, addr_sup_vm_mode[0], addr_sup_vm_sum, dtlb.ack[A].valid, dtlb.ack[A].aduwrx[5:1], addr_pmp_fail}) // synthesis full_case parallel_case
					'b1???_?_?_?_?????_0: prot = 4'b0001;	// M mode
					'b1???_?_?_?_?????_1: prot = 4'b0100;	// M mode
	
					'b??1?_1_?_0_?????_0,					// turned off
					'b???1_1_?_0_?????_0: prot = 4'b0001;	
					'b??1?_1_?_0_?????_1,					// turned off pmap
					'b???1_1_?_0_?????_1: prot = 4'b0100;	
	
					'b??1?_0_?_0_?????_?: prot = 4'b1000;	// sup tlb miss (handled by attempting to fetch)
					'b??1?_0_0_1_??1??_?: prot = 4'b0010;	// sup tlb U not OK
					'b??1?_0_?_1_??00?_?: prot = 4'b0010;	// sup tlb write not OK
					'b??1?_0_?_1_?001?_?: prot = 4'b0010;	// sup tlb D not set
					'b??1?_0_?_1_0101?_?: prot = 4'b0010;	// usr tlb A not set
					'b??1?_0_?_1_11010_?: prot = 4'b0010;	// usr tlb bad format
					'b??1?_0_?_1_11011_0: prot = 4'b0001;	// sup tlb write OK
					'b??1?_0_?_1_11011_1: prot = 4'b0100;	// sup tlb write OK pmap fail
	
					'b??1?_0_1_1_??10?_?: prot = 4'b0010;	// sup tlb write not OK
					'b??1?_0_1_1_?011?_?: prot = 4'b0010;	// sup tlb D not set
					'b??1?_0_1_1_0111?_?: prot = 4'b0010;	// sup tlb A not set
					'b??1?_0_1_1_11110_?: prot = 4'b0010;	// sup tlb bad format
					'b??1?_0_1_1_11111_0: prot = 4'b0001;	// sup tlb write OK
					'b??1?_0_1_1_11111_1: prot = 4'b0100;	// sup tlb write OK pmap fail
	
					'b???1_0_?_0_?????_?: prot = 4'b1000;	// usr tlb miss (handled by attempting to fetch)
					'b???1_0_?_1_??0??_?: prot = 4'b0010;	// usr tlb write sup page
					'b???1_0_?_1_??10?_?: prot = 4'b0010;	// usr tlb write not OK
					'b???1_0_?_1_?011?_?: prot = 4'b0010;	// usr tlb D not set
					'b???1_0_?_1_0111?_?: prot = 4'b0010;	// usr tlb A not set
					'b???1_0_?_1_11110_?: prot = 4'b0010;	// usr tlb bad format
					'b???1_0_?_1_11111_0: prot = 4'b0001;	// usr tlb write OK
					'b???1_0_?_1_11111_1: prot = 4'b0100;	// usr tlb write OK pmap fail
					default:			  prot = 4'bxxxx; 
					endcase
				end
			end

			always @(*) begin
				addr_ok = 1'bx;
				casez ({addr_mprv[3], addr_sup_vm_mode}) // synthesis full_case parallel_case
				5'b1_????: addr_ok = 1;
				5'b0_???1: addr_ok = 1;
				5'b0_??1?: addr_ok = 1;
				5'b0_?1??: addr_ok = !addr_v[A][38]?(addr_v[A][RV-1:39]==25'h0):(addr_v[A][RV-1:39]==25'h1_ff_ff_ff);
				5'b0_1???: addr_ok = !addr_v[A][47]?(addr_v[A][RV-1:48]==16'h0):(addr_v[A][RV-1:48]==16'hff_ff);
				default:   addr_ok = 1'bx; 
				endcase
			end

			if (RV==64) begin
				always @(*) begin
					casez(r_addr_control[A][1:0]) // synthesis full_case parallel_case
					2'b11:	addr_alignment_bad = addr_p[A][2:0]!=0;
					2'b10:	addr_alignment_bad = addr_p[A][1:0]!=0;
					2'b01:	addr_alignment_bad = addr_p[A][0]!=0;
					2'b00:	addr_alignment_bad = 0;
					endcase
					casez ({r_addr_control[A][1:0], addr_p[A][2:0]}) // synthesis full_case parallel_case
					5'b11_???: addr_mask[A] = 8'b1111_1111;
					5'b10_0??: addr_mask[A] = 8'b0000_1111;
					5'b10_1??: addr_mask[A] = 8'b1111_0000;
					5'b01_00?: addr_mask[A] = 8'b0000_0011;
					5'b01_01?: addr_mask[A] = 8'b0000_1100;
					5'b01_10?: addr_mask[A] = 8'b0011_0000;
					5'b01_11?: addr_mask[A] = 8'b1100_0000;
					5'b00_000: addr_mask[A] = 8'b0000_0001;
					5'b00_001: addr_mask[A] = 8'b0000_0010;
					5'b00_010: addr_mask[A] = 8'b0000_0100;
					5'b00_011: addr_mask[A] = 8'b0000_1000;
					5'b00_100: addr_mask[A] = 8'b0001_0000;
					5'b00_101: addr_mask[A] = 8'b0010_0000;
					5'b00_110: addr_mask[A] = 8'b0100_0000;
					5'b00_111: addr_mask[A] = 8'b1000_0000;
					endcase
				end
			end else begin
				always @(*) begin
					casez(r_addr_control[A][1:0]) // synthesis full_case parallel_case
					2'b10:	addr_alignment_bad = addr_p[A][1:0]!=0;
					2'b01:	addr_alignment_bad = addr_p[A][0]!=0;
					2'b00:	addr_alignment_bad = 0;
					default:addr_alignment_bad = 1'bx; 
					endcase
				end
				always @(*) begin
					casez ({r_addr_control[A][1:0], addr_p[A][1:0]}) // synthesis full_case parallel_case
					4'b10_??: addr_mask[A] = 4'b1111;
					4'b01_0?: addr_mask[A] = 4'b0011;
					4'b01_1?: addr_mask[A] = 4'b1100;
					4'b00_00: addr_mask[A] = 4'b0001;
					4'b00_01: addr_mask[A] = 4'b0010;
					4'b00_10: addr_mask[A] = 4'b0100;
					4'b00_11: addr_mask[A] = 4'b1000;
					default:  addr_mask[A] = 4'bxxxx; 
					endcase
				end
			end

			always @(*) begin 
				trap_type = 2'bxx;
				casez ({addr_fence[A], addr_alignment_bad, ~addr_ok,  prot}) // synthesis parallel_case full_case
				7'b0_1?_????:	trap_type = 1; // alligned
				7'b0_00_1???,
				7'b0_00_??1?:	trap_type = 3; // page fault
				
				7'b0_01_????,
				7'b0_00_?1??:	trap_type = 2; // protection
				7'b1_??_????,
				7'b0_00_???1:	trap_type = 0; // no trap
				default:    trap_type = 2'bxx; 
				endcase
			end

			always @(*) begin
				c_addr_vm_pause[A] = (r_hart_vm_pause[addr_hart[A]]||hart_vm_pause[addr_hart[A]])&&r_addr_busy[A]&&!addr_killed;
				c_addr_vm_stall[A] = !addr_fence[A]&&prot[3]&&r_addr_busy[A]&&!addr_killed&&!(r_hart_vm_pause[addr_hart[A]]||hart_vm_pause[addr_hart[A]]);
			end

			wire addr_killed = commit_kill[ls.req[A].hart][ls.req[A].rd];

			wire [1:0]addr_aq_rl = (ls.req[A].load ? ls.req[A].control[4]:ls.req[A].control[5:4]==2'b01) ? ls.req[A].immed[26:25]:2'b00;
	
			always @(*) begin
				c_addr_rd[A] = r_addr_rd[A];
				if (ls.req[A].enable && !addr_killed) begin
					c_addr_rd[A] = ls.req[A].rd;
				end
			end
			
			always @(posedge clk)  begin
				if (reset) begin
					r_addr_busy[A] <= 0;
				end else
				if (ls.req[A].enable && !addr_killed) begin
					r_addr_busy[A] <= 1;
					r_addr_control[A] <= ls.req[A].control;
					r_addr_makes_rd[A] <= ls.req[A].makes_rd;
					r_addr_load[A] <= ls.req[A].load;
					r_addr_amo[A] <= (ls.req[A].load || !ls.req[A].control[4] ? 5'b0 :ls.req[A].immed[31:27]);
					r_addr_immed[A] <= (ls.req[A].load ? ls.req[A].control[4]:ls.req[A].control[5:4]==2'b01) ? 32'b0: ls.req[A].immed;
					r_addr_aq_rl[A] <= addr_aq_rl;
				end else begin
					r_addr_busy[A] <= 0;
				end
				if (reset) begin
					r_addr_vm_stall[A] <= 0;
					r_addr_vm_pause[A] <= 0;
				end else begin
					r_addr_vm_stall[A] <= c_addr_vm_stall[A];
					r_addr_vm_pause[A] <= c_addr_vm_pause[A];
				end
				r_addr_rd[A] <= c_addr_rd[A];
			end
		
			if (NHART == 1) begin
				assign addr_hart[A] = 0;
			end else begin :hh
				reg r_addr_hart;
				assign addr_hart[A] = r_addr_hart;

				always @(posedge clk) 
                if (reset) begin
                    r_addr_hart <= 0;
                end else
                if (ls.req[A].enable && !addr_killed) begin
					r_addr_hart <= ls.req[A].hart;
				end
			end

			assign addr_is_ok[A] = trap_type == 0;

			assign addr_fence[A] = !r_addr_load[A] && r_addr_control[A][5];
			assign addr_fd[A] = r_addr_immed[A][24:23];

			if (NHART == 1) begin
				assign ls.ack[A].hart[0] = r_addr_busy[A];
			end else begin
				reg [NHART-1:0]h;
				always @(*) begin
					h = 0;
					if (r_addr_busy[A])
						h[addr_hart[A]] = 1;
				end
				assign ls.ack[A].hart = h;
			end
			assign ls.ack[A].rd = r_addr_rd[A];	
			assign ls.ack[A].trap_type = trap_type;
			assign ls.ack[A].vm_pause = c_addr_vm_pause[A];
			assign ls.ack[A].vm_stall = c_addr_vm_stall[A];


			always @(*) begin
				casez ({addr_fence[A], addr_aq_rl[0]}) // synthesis full_case parallel_case
				2'b1?:	addr_isblocked[A] = r_addr_immed[A][30:27];
				2'b?1:	addr_isblocked[A] = 4'b1111;
				2'b00:	addr_isblocked[A] = {addr_io[A]& r_addr_load[A],
										     addr_io[A]&~r_addr_load[A],
									        ~addr_io[A]& r_addr_load[A],
									        ~addr_io[A]&~r_addr_load[A]};
				endcase
			end
	     	
			// this is what we block after us
			always @(*) begin
				casez ({addr_fence[A], addr_aq_rl[1]}) // synthesis full_case parallel_case
				2'b1?:	addr_blocks[A] = r_addr_immed[A][26:23];
				2'b?1:	addr_blocks[A] = 4'b1111;
				2'b00:	addr_blocks[A] = {addr_io[A], addr_io[A], 1'b0, 1'b0}; // IOs go in order
				endcase
			end

			for (C = 0; C < NCOMMIT; C=C+1) begin : nc
				wire [NADDR-1:0]h_soft;
				wire [NADDR-1:0]h_hard;
				for (I = 0; I < NADDR; I=I+1) 
				if (I >= A) begin
					assign h_soft[I] = 0;
					assign h_hard[I] = 0;
				end else begin 
					assign h_soft[I] = r_addr_busy[I] &&  r_addr_rd[I] == C && !commit_kill[addr_hart[I]][C] && !commit_completed[addr_hart[I]][C] &&
                        ((!r_addr_load[A]||!r_addr_load[I])&&(addr_p[A][NPHYS-1:3]==addr_p[I][NPHYS-1:3]));
					assign h_hard[I] = r_addr_busy[I] &&  r_addr_rd[I] == C && !commit_kill[addr_hart[I]][C] && !commit_completed[addr_hart[I]][C] &&
                        (r_addr_aq_rl[A][0] || |(addr_isblocked[A]&addr_blocks[I]));
				end


				wire [NHART-1:0]hart_block;
				for (H = 0; H < NHART; H=H+1) begin
					assign addr_match_mask[H][C][A] = r_c_valid[H][C] && (r_c_paddr[H][C][NPHYS-1:3] == addr_p[A][NPHYS-1:3]) && |(r_c_mask[H][C]&addr_mask[A]);
					assign hart_block[H]  = |(addr_isblocked[A]&r_c_block[H][C]); 
				end

				wire hazard_valid = (r_addr_rd[A] >= ls_ready.current_start[addr_hart[A]] ? C >= ls_ready.current_start[addr_hart[A]] && C < r_addr_rd[A] : C >= ls_ready.current_start[addr_hart[A]] || C < r_addr_rd[A]);

				assign addr_soft_hazard[A][C] = hazard_valid &&
							(|h_soft || 
							 (r_c_valid[addr_hart[A]][C] && !commit_kill[addr_hart[A]][C] && !commit_completed[addr_hart[A]][C] &&
						      ((addr_match_mask[addr_hart[A]][C][A] && (!r_c_load[addr_hart[A]][C]||!r_addr_load[A])))) ||
						     (ls_ready.store_addr_ready[addr_hart[A]][C]|ls_ready.store_addr_not_ready[addr_hart[A]][C]) ||
					         (!r_addr_load[A]&&(ls_ready.load_addr_ready[addr_hart[A]][C]|ls_ready.load_addr_not_ready[addr_hart[A]][C])));	
				assign addr_hard_hazard[A][C] = hazard_valid &&
							(|h_hard || (r_c_valid[addr_hart[A]][C] && !commit_kill[addr_hart[A]][C] && !commit_completed[addr_hart[A]][C] && hart_block[addr_hart[A]]));
			end

`ifdef SIMD
			always @(posedge clk)
				if (r_addr_busy[A] && simd_enable) $display("V%d %d a=%x %x->%d.%x",A[2:0],$time,r_addr_rd[A],addr_v[A],addr_io[A], addr_p[A]);
`endif
		end


		wire [NCOMMIT-1:0]inhibit_hazard[0:NHART-1][0:NCOMMIT-1];
		wire [NCOMMIT-1:0]hazard_gone[0:NHART-1];
		for (H = 0; H < NHART; H=H+1) begin
			reg [NADDR-1:0]sum[0:NCOMMIT-1][0:NCOMMIT-1];
			for (A = 0; A < NADDR; A=A+1) begin
				for (C = 0; C < NCOMMIT; C=C+1) begin
					reg s;
					always @(*)
						s = r_addr_busy[A] && addr_hart[A] == H && !addr_match_mask[H][C][A];
					for (D = 0; D < NCOMMIT-1; D=D+1) begin
						always @(*)
							sum[C][D][A] = s && r_addr_rd[A] == D;
					end
				end
			end
			for (C = 0; C < NCOMMIT; C=C+1) begin
				for (D = 0; D < NCOMMIT-1; D=D+1) begin
					assign inhibit_hazard[H][C][D] = |sum[C][D]; 
				end
			end
		end

		for (H = 0; H < NHART; H=H+1) 
		for (C = 0; C < NCOMMIT; C = C+1) begin
			wire [NLOAD-1:0]loading;
			wire [NSTORE-1:0]storing;
			for (L=0; L < NLOAD; L=L+1) begin
				assign loading[L] = r_load_enable[L]&&(r_load_rd[L]==C)&&(r_load_hart[L]==H);
			end
			for (S=0; S < NSTORE; S=S+1) begin
				assign storing[S] = r_store_enable[S]&&(r_store_rd[S]==C)&&(r_store_hart[S]==H);
			end

			wire done = |loading || |storing;

			always @(*) begin
				hazard_clear_load[H][C]  = c_c_valid[H][C]&~|c_c_soft_hazard[H][C]&~|c_c_hard_hazard[H][C]&c_c_load[H][C]&!done;
				hazard_clear_store[H][C] = c_c_valid[H][C]&~|c_c_soft_hazard[H][C]&~|c_c_hard_hazard[H][C]&~c_c_load[H][C]&&ls_ready.store_data_ready[H][C]&!done;
			end

			assign hazard_gone[H][C] = done;

			always @(posedge clk) begin
				r_c_valid[H][C]	    <= c_c_valid[H][C]&&!done;
				r_c_load[H][C]	    <= c_c_load[H][C];
				r_c_fence[H][C]	    <= c_c_fence[H][C];
				r_c_io[H][C]	    <= c_c_io[H][C];
				r_c_makes_rd[H][C]  <= c_c_makes_rd[H][C];
				r_c_paddr[H][C]	    <= c_c_paddr[H][C];
				r_c_control[H][C]   <= c_c_control[H][C];
				r_c_aq_rl[H][C]     <= c_c_aq_rl[H][C];
				r_c_block[H][C]	    <= c_c_block[H][C];
				r_c_soft_hazard[H][C]<= c_c_soft_hazard[H][C];
				r_c_hard_hazard[H][C]    <= c_c_hard_hazard[H][C];
				r_c_mask[H][C]      <= c_c_mask[H][C];
				r_c_fd[H][C]	    <= c_c_fd[H][C];
				r_c_amo[H][C]	    <= c_c_amo[H][C];
`ifdef FP
				r_c_fp[H][C]	    <= c_c_fp[H][C];
`endif
			end

		end 

		for (L = 0; L < NLOAD; L=L+1) begin : load
			if ( NHART == 1) begin
				assign ld_wb.wb[L].hart = r_load_res_done[L];
			end else begin
				reg [NHART-1:0]res;
				always @(*) begin
					res = 0;
					if (r_load_res_done[L])
						res[r_load_res_hart[L]] = 1;
				end
				assign ld_wb.wb[L].hart = res;
			end
			assign ld_wb.wb[L].result = r_load_res_data[L];
			assign ld_wb.wb[L].rd = r_load_res_rd[L];
			assign ld_wb.wb[L].makes_rd = r_load_res_makes_rd[L];
`ifdef FP
			assign ld_wb.wb[L].fp = r_load_res_fp[L];
`endif

			assign dc_load.req[L].addr = r_load_paddr[L][NPHYS-1:$clog2(RV/8)];

			assign load_snoop.req[L].addr = r_load_paddr[L][NPHYS-1:$clog2(RV/8)];
			assign load_snoop.req[L].io = r_load_io[L];
			assign load_snoop.req[L].mask = r_load_mask[L];
			assign load_snoop.req[L].hart = r_load_hart[L];


wire [NLDSTQ-1:0]load_snoop_hit = load_snoop.ack[L].hit; // debug stuff
wire [NLDSTQ-1:0]load_snoop_hazard = load_snoop.ack[L].hazard;
wire [NLDSTQ-1:0]load_snoop_line_busy = load_snoop.ack[L].line_busy;
			
			always @(*) 
				load_allocate[L] = r_load_enable[L]&&
								   !r_load_queued[L] &&
								   (((|load_snoop.ack[L].hit?|(load_snoop_hit_mask[L]&load_snoop.ack[L].hazard):!dc_load.ack[L].hit||(dc_rd_lr[L]&&dc_load.ack[L].hit_need_o))) ||
									r_load_control[L][4] || r_load_io[L]) &&
                                   !commit_kill[r_load_hart[L]][r_load_rd[L]];

			
			reg [RV-1:0]data, data_out;
			reg [(RV==64?2:1):0]addr_lo;
			if (RV == 64) begin
				always @(*) begin
					casez ({r_load_io[L], r_load_queued[L], r_load_sc[L]}) // synthesis full_case parallel_case
					3'b??1: begin
								data = {63'b0, r_load_sc_okv[L]};
								addr_lo = 0;
						    end
					3'b010: begin
								data = dc_load.ack[L].data;
								addr_lo = r_load_paddr[L][2:0];
							end
					3'b110: begin
								data = r_io_data;
								addr_lo = r_load_paddr[L][2:0];
							end
					3'b?00: begin
								data = (|load_snoop.ack[L].hit?load_snoop_result[L]:dc_load.ack[L].data);
								addr_lo = r_load_paddr[L][2:0];
							end
					default:begin addr_lo = 3'bxxx;  data = 'bx; end
					endcase
					casez ({r_load_control[L][2:0], addr_lo}) // synthesis full_case parallel_case
					6'b?_11_???: data_out = data;
					6'b1_10_0??: data_out = {32'b0, data[31:0]};
					6'b1_10_1??: data_out = {32'b0, data[63:32]};
					6'b0_10_0??: data_out = {{32{data[31]}}, data[31:0]};
					6'b0_10_1??: data_out = {{32{data[63]}}, data[63:32]};
					6'b1_01_00?: data_out = {48'b0, data[15:0]};
					6'b1_01_01?: data_out = {48'b0, data[31:16]};
					6'b1_01_10?: data_out = {48'b0, data[47:32]};
					6'b1_01_11?: data_out = {48'b0, data[63:48]};
					6'b0_01_00?: data_out = {{48{data[15]}}, data[15:0]};
					6'b0_01_01?: data_out = {{48{data[31]}}, data[31:16]};
					6'b0_01_10?: data_out = {{48{data[47]}}, data[47:32]};
					6'b0_01_11?: data_out = {{48{data[63]}}, data[63:48]};
					6'b1_00_000: data_out = {56'b0, data[7:0]};
					6'b1_00_001: data_out = {56'b0, data[15:8]};
					6'b1_00_010: data_out = {56'b0, data[23:16]};
					6'b1_00_011: data_out = {56'b0, data[31:24]};
					6'b1_00_100: data_out = {56'b0, data[39:32]};
					6'b1_00_101: data_out = {56'b0, data[47:40]};
					6'b1_00_110: data_out = {56'b0, data[55:48]};
					6'b1_00_111: data_out = {56'b0, data[63:56]};
					6'b0_00_000: data_out = {{56{data[7]}}, data[7:0]};
					6'b0_00_001: data_out = {{56{data[15]}}, data[15:8]};
					6'b0_00_010: data_out = {{56{data[23]}}, data[23:16]};
					6'b0_00_011: data_out = {{56{data[31]}}, data[31:24]};
					6'b0_00_100: data_out = {{56{data[39]}}, data[39:32]};
					6'b0_00_101: data_out = {{56{data[47]}}, data[47:40]};
					6'b0_00_110: data_out = {{56{data[55]}}, data[55:48]};
					6'b0_00_111: data_out = {{56{data[63]}}, data[63:56]};
					endcase
				end
			end else begin
				always @(*) begin
					casez ({r_load_queued[L], r_load_sc[L]}) // synthesis full_case parallel_case
					2'b?1: begin
							data = {31'b0, r_load_sc_okv[L]};
							addr_lo = 0;
						   end
					2'b10: begin
							data = dc_load.ack[L].data;
							addr_lo = r_load_paddr[L][1:0];
						   end
					2'b00: begin
							data = (|load_snoop.ack[L].hit?load_snoop_result[L]:dc_load.ack[L].data);
							addr_lo = r_load_paddr[L][1:0];
						   end
					default:begin addr_lo = 3'bxxx;  data = 'bx; end
					endcase
					casez ({r_load_control[L][2:0], addr_lo}) // synthesis full_case parallel_case
					5'b?_10_0?: data_out = data;
					5'b1_01_0?: data_out = {16'b0, data[15:0]};
					5'b1_01_1?: data_out = {16'b0, data[31:16]};
					5'b0_01_0?: data_out = {{16{data[15]}}, data[15:0]};
					5'b0_01_1?: data_out = {{16{data[31]}}, data[31:16]};
					5'b1_00_00: data_out = {24'b0, data[7:0]};
					5'b1_00_01: data_out = {24'b0, data[15:8]};
					5'b1_00_10: data_out = {24'b0, data[23:16]};
					5'b1_00_11: data_out = {24'b0, data[31:24]};
					5'b0_00_00: data_out = {{24{data[7]}}, data[7:0]};
					5'b0_00_01: data_out = {{24{data[15]}}, data[15:8]};
					5'b0_00_10: data_out = {{24{data[23]}}, data[23:16]};
					5'b0_00_11: data_out = {{24{data[31]}}, data[31:24]};
					endcase
				end
			end
			always @(posedge clk) 
					r_load_res_data[L] <= data_out;

			always @(*) begin
					c_load_paddr[L] = r_load_paddr[L];
					c_load_io[L] = r_load_io[L];
					if (load_enable[L]) begin
						if (!load_queued[L]) begin
							c_load_io[L] =  c_c_io[load_hart[L]][load_rd[L]];
;
							c_load_paddr[L] = c_c_paddr[load_hart[L]][load_rd[L]];
						end else begin
							c_load_io[L] = write_mem_io[load_qindex[L]];
							c_load_paddr[L] = write_mem_addr[load_qindex[L]];
						end
					end
					dc_rd_hart[L] = r_load_hart[L];
                    dc_rd_lr[L] = r_load_control[L][4];
			end

			always @(posedge clk) begin
`ifdef SIMD
				if (r_load_enable[L]&&(r_load_queued[L]?dc_load.ack[L].hit||r_load_io[L]:!load_allocate[L]) && simd_enable) $display("L%d %d a=%x %x d=%x",L[1:0],$time,r_load_rd[L],r_load_paddr[L],data_out);
`endif


				r_load_enable[L] <= reset?0:load_enable[L];
				if (load_enable[L]) begin
					if (!load_queued[L]) begin
						r_load_rd[L] <= load_rd[L];
						r_load_makes_rd[L] <= c_c_makes_rd[load_hart[L]][load_rd[L]];
`ifdef FP
						r_load_fp[L] <= c_c_fp[load_hart[L]][load_rd[L]];
`endif
						r_load_paddr[L] <= c_c_paddr[load_hart[L]][load_rd[L]];
						r_load_mask[L] <= c_c_mask[load_hart[L]][load_rd[L]];
						r_load_sc[L] <= 0;
						r_load_queued[L] <= 0;
						r_load_aq_rl[L] <= c_c_aq_rl[load_hart[L]][load_rd[L]];
						r_load_hart[L] <= load_hart[L];
						r_load_amo[L] <= 0;
						r_load_control[L] <= c_c_control[load_hart[L]][load_rd[L]];
					end else begin
						r_load_rd[L] <= wq_rd[load_qindex[L]];
`ifdef FP
						r_load_fp[L] <= wq_fp[load_qindex[L]];
`endif
						r_load_amo[L] <= write_mem_amo[load_qindex[L]][0] && !wq_control[load_qindex[L]][3]  && (write_mem_amo[load_qindex[L]][2:1] != 2'b11);
						r_load_makes_rd[L] <= wq_makes_rd[load_qindex[L]];
						r_load_sc[L] <= write_mem_sc[load_qindex[L]];
						r_load_sc_okv[L] <= write_mem_sc_okv[load_qindex[L]];
						r_load_hart[L] <= wq_hart[load_qindex[L]];
	                    r_load_aq_rl[L] <= wq_aq_rl[load_qindex[L]];
						r_load_ack_entry[L] <= load_qindex[L];
						r_load_queued[L] <= 1;
						r_load_control[L] <= {1'bx,wq_control[load_qindex[L]][3],1'b0, wq_control[load_qindex[L]][2:0]};

					end
				end
				r_load_io[L] <= c_load_io[L];
				r_load_paddr[L] <= c_load_paddr[L];

				r_load_res_done[L] <= reset?0:(r_load_enable[L]&&!commit_kill[r_load_hart[L]][r_load_rd[L]]&&(r_load_queued[L]?(dc_load.ack[L].hit||r_load_io[L]):!load_allocate[L]));
				r_load_res_makes_rd[L] <= r_load_makes_rd[L];
				r_load_res_rd[L] <= r_load_rd[L];
				r_load_res_hart[L] <= r_load_hart[L];
				
			end

			if (NHART == 1) begin
				always @(posedge clk) 
					r_load_hart[L] <= 0;	// will be optimised out
			end else begin
				always @(posedge clk) 
					r_load_hart[L] <= load_hart[L];
			end

		end

		for (S = 0; S < NSTORE; S=S+1) begin : store
			
			assign st.req[S].enable = store_enable[S];
			assign st.req[S].rd = store_rd[S];
			assign st.req[S].hart = store_hart[S];
`ifdef FP
			assign st.req[S].fp = store_fp[S];
`endif

			always @(*) begin
				
				c_store_paddr[S] = r_store_paddr[S];
				c_store_control[S] = r_store_control[S];
				c_store_io[S] = r_store_io[S] ;
				c_store_amo[S] = r_store_amo[S] ;
				c_store_fence[S] = r_store_fence[S];
				c_store_makes_rd[S] = r_store_makes_rd[S];
`ifdef FP
				c_store_fp[S] = r_store_fp[S];
`endif
				c_store_fd[S] = r_store_fd[S];
				c_store_aq_rl[S] = r_store_aq_rl[S];
				if (store_enable[S]) begin
					c_store_paddr[S] = c_c_paddr[store_hart[S]][store_rd[S]];
					c_store_control[S] = c_c_control[store_hart[S]][store_rd[S]];
					c_store_io[S] = c_c_io[store_hart[S]][store_rd[S]];
					c_store_fence[S] = c_c_fence[store_hart[S]][store_rd[S]];
`ifdef FP
					c_store_fp[S] = c_c_fp[store_hart[S]][store_rd[S]];
`endif
					c_store_fd[S] = c_c_fd[store_hart[S]][store_rd[S]];
					c_store_amo[S] = c_c_amo[store_hart[S]][store_rd[S]];
					c_store_aq_rl[S] = c_c_aq_rl[store_hart[S]][store_rd[S]];
					c_store_makes_rd[S] = c_c_makes_rd[store_hart[S]][store_rd[S]];
				end
			end

			always @(posedge clk) begin

				r_store_enable[S] <= reset?0:store_enable[S];
				if (store_enable[S]) begin
					r_store_rd[S] <= store_rd[S];
				end
`ifdef FP
				r_store_fp[S] <= c_store_fp[S];
`endif
				r_store_io[S] <= c_store_io[S];
				r_store_paddr[S] <= c_store_paddr[S];
				r_store_control[S] <= c_store_control[S];
				r_store_fence[S] <= c_store_fence[S];
				r_store_fd[S] <= c_store_fd[S];
				r_store_amo[S] <= c_store_amo[S];
				r_store_aq_rl[S] <= c_store_aq_rl[S];
				r_store_makes_rd[S] <= c_store_makes_rd[S];
			end

			if (NHART == 1) begin
				always @(posedge clk) 
					r_store_hart[S] <= 0;	// will be optimised out
			end else begin
				always @(posedge clk) 
					r_store_hart[S] <= store_hart[S];
			end

			if (RV==64) begin
				always @(*) begin
`ifdef FP
					casez ({r_store_control[S][3], r_store_control[S][1:0]})  // synthesis full_case parallel_case
					3'b1_?1: store_data[S] = st.ack[S].fp;
					3'b1_?0: store_data[S] = {st.ack[S].fp,st.ack[S].fp}
					3'b0_11: store_data[S] = st.ack[S].data;
					3'b0_10: store_data[S] = {st.ack[S].data[31:0],st.ack[S].data[31:0]};
					3'b0_01: store_data[S] = {st.ack[S].data[15:0],st.ack[S].data[15:0],st.ack[S].data[15:0],st.ack[S].data[15:0]};
					3'b0_00: store_data[S] = {st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0]};
					default:  store_data[S] = 'bx; 
					endcase
`else
					casez (r_store_control[S][1:0])  // synthesis full_case parallel_case
					2'b11: store_data[S] = st.ack[S].data;
					2'b10: store_data[S] = {st.ack[S].data[31:0],st.ack[S].data[31:0]};
					2'b01: store_data[S] = {st.ack[S].data[15:0],st.ack[S].data[15:0],st.ack[S].data[15:0],st.ack[S].data[15:0]};
					2'b00: store_data[S] = {st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0]};
					default:  store_data[S] = 'bx; 
					endcase
`endif
					casez({r_store_control[S][1:0], r_store_paddr[S][2:0]}) // synthesis full_case parallel_case
					5'b11_???: store_mask[S] = 8'b1111_1111;
					5'b10_0??: store_mask[S] = 8'b0000_1111;
					5'b10_1??: store_mask[S] = 8'b1111_0000;
					5'b01_00?: store_mask[S] = 8'b0000_0011;
					5'b01_01?: store_mask[S] = 8'b0000_1100;
					5'b01_10?: store_mask[S] = 8'b0011_0000;
					5'b01_11?: store_mask[S] = 8'b1100_0000;
					5'b00_000: store_mask[S] = 8'b0000_0001;
					5'b00_001: store_mask[S] = 8'b0000_0010;
					5'b00_010: store_mask[S] = 8'b0000_0100;
					5'b00_011: store_mask[S] = 8'b0000_1000;
					5'b00_100: store_mask[S] = 8'b0001_0000;
					5'b00_101: store_mask[S] = 8'b0010_0000;
					5'b00_110: store_mask[S] = 8'b0100_0000;
					5'b00_111: store_mask[S] = 8'b1000_0000;
					endcase
				end
			end else begin
				always @(*) begin
`ifdef FP
					casez ({r_store_control[S][3], r_store_control[S][1:0]})  // synthesis full_case parallel_case
					3'b1_??: store_data[S] = st.ack[S].data;
					3'b0_10: store_data[S] = st.ack[S].data;
					3'b0_01: store_data[S] = {st.ack[S].data[15:0],st.ack[S].data[15:0]};
					3'b0_00: store_data[S] = {st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0]};
					default:  store_data[S] = 'bx; 
					endcase
`else
					casez (r_store_control[S][1:0])  // synthesis full_case parallel_case
					2'b10: store_data[S] = st.ack[S].data;
					2'b01: store_data[S] = {st.ack[S].data[15:0],st.ack[S].data[15:0]};
					2'b00: store_data[S] = {st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0],st.ack[S].data[7:0]};
					default:  store_data[S] = 'bx; 
					endcase
`endif
					casez({r_store_control[S][1:0], r_store_paddr[S][1:0]}) // synthesis full_case parallel_case
					4'b10_??: store_mask[S] = 4'b1111;
					4'b01_0?: store_mask[S] = 4'b0011;
					4'b01_1?: store_mask[S] = 4'b1100;
					4'b00_00: store_mask[S] = 4'b0001;
					4'b00_01: store_mask[S] = 4'b0010;
					4'b00_10: store_mask[S] = 4'b0100;
					4'b00_11: store_mask[S] = 4'b1000;
					default:  store_mask[S] = 'bx; 
					endcase
				end
			end
		
			assign store_snoop.req[S].mask = store_mask[S];
			assign store_snoop.req[S].io = r_store_io[S];
			assign store_snoop.req[S].addr = r_store_paddr[S][NPHYS-1:$clog2(RV/8)];

			assign store_hazard[S] = store_snoop.ack[S].hazard;
			assign store_allocate[S] = r_store_enable[S]&!commit_kill[r_store_hart[S]][r_store_rd[S]];
`ifdef SIMD
			always @(posedge clk) begin
				if (store_allocate[S] && simd_enable) $display("S%d %d a=%x %x d=%x",S[1:0],$time,r_store_rd[S],r_store_paddr[S],store_data[S]);
			end;
`endif

	
        end


		always @(posedge clk)
		if (reset) begin
			r_hart_vm_pause <= 0;
		end else begin
			r_hart_vm_pause <= hart_vm_pause;
		end

		reg [$clog2(NLDSTQ)-1:0]io_req;

		assign io_cpu_addr_req = (|write_io_read_req)|(|write_io_write_req);
		assign io_cpu_addr = write_mem_addr[io_req];
		assign io_cpu_read = write_io_read_req[io_req];
		assign io_cpu_lock = write_io_lock[io_req];
		assign io_cpu_mask = write_mem_mask[io_req];
		reg [RV-1:0]c_io_cpu_wdata; 
		assign io_cpu_wdata = c_io_cpu_wdata;

		
		assign tlb_wr_invalidate = |fence_tlb_invalidate;
		assign tlb_wr_invalidate_addr = ~tlb_inv_type[1];
		assign tlb_wr_invalidate_asid = ~tlb_inv_type[0];
		assign tlb_wr_inv_vaddr = tlb_inv_addr;				   
		assign tlb_wr_inv_unified = unified_asid[tlb_inv_hart];
		assign tlb_wr_inv_asid = {unified_asid[tlb_inv_hart]?tlb_inv_asid[15]:tlb_inv_hart,tlb_inv_asid[14:0]};

		if (NLDSTQ == 32 && NLOAD == 4 && NSTORE == 4) begin
`include "mk13_32_4_4.inc"
		end else
		if (NLDSTQ == 32 && NLOAD == 2 && NSTORE == 2) begin
`include "mk13_32_2_2.inc"
		end else
		if (NLDSTQ == 16 && NLOAD == 4 && NSTORE == 4) begin
`include "mk13_16_4_4.inc"
		end else
		if (NLDSTQ == 8 && NLOAD == 2 && NSTORE == 2) begin
`include "mk13_8_2_2.inc"
		end else
		if (NLDSTQ == 16 && NLOAD == 2 && NSTORE == 2) begin
`include "mk13_16_2_2.inc"
		end

		wire [NLDSTQ-1:0]write_io_data_ack;
		assign io_cpu_data_ack = |write_io_data_ack;
		reg [RV-1: 0]r_io_data;
		reg			 r_io_data_err;

		always @(posedge clk)
		if (io_cpu_data_req) begin
			r_io_data <= io_cpu_rdata;
			r_io_data_err <= io_cpu_data_err;
		end

		always @(*) begin :io_amo
			reg [RV-1:0]wdata;

			wdata = write_mem_data[io_req];
			c_io_cpu_wdata = 'bx;
			casez (write_mem_amo[io_req]) // synthesis full_case parallel_case
			default:    c_io_cpu_wdata = wdata;
			6'b001??_1: c_io_cpu_wdata = wdata^r_io_data;			
			6'b011??_1: c_io_cpu_wdata = wdata&r_io_data;			
			6'b010??_1: c_io_cpu_wdata = wdata|r_io_data;			
			endcase
		end

		for (I = 0; I < NLDSTQ; I=I+1) begin: sq
			ldstq #(.RV(RV), .ADDR(I), .NHART(NHART), .NPHYS(NPHYS), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .LNHART(LNHART), .NLDSTQ(NLDSTQ), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .NLOAD(NLOAD), .NSTORE(NSTORE), .TRANS_ID_SIZE(TRANS_ID_SIZE))s(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
					.trig_in(cpu_trig),
					.xxtrig(xxtrig),
`endif
					.allocate(q_allocate[I]),
					.load(q_load[I]),
					.store(q_store[I]),
					.fence(q_fence[I]),
					.addr(q_addr[I]),
					.io(q_io[I]),
					.data(q_data[I]), 
					.mask(q_mask[I]),
					.hart(q_hart[I]),
					.control(q_control[I]),
					.amo(q_amo[I]),
					.aq_rl(q_aq_rl[I]),
					.fd(q_fd[I]),
					.rd(q_rd[I]),
`ifdef FP
					.fp(q_fp[I]),
`endif
					.makes_rd(q_makes_rd[I]),
					.hazard(q_hazard[I]),
					.all_store_mem(store_mem_hit),
					.cache_miss(q_cache_miss[I]),

					.line_busy(q_line_busy[I]),
					.line_busy_trans(q_line_busy_index[I]),
					.dc_raddr_req(dc_raddr_req&dc_raddr_ack),
					.dc_raddr(dc_raddr),
					.dc_raddr_trans(dc_raddr_trans),
					.dc_rdata_req(dc_rdata_req&dc_rdata_ack),
					.dc_rdata_trans(dc_rdata_trans),

					.commit_0(store_commit_0),
					//.commit_1(store_commit_1),
					.commit_kill_0(commit_kill_0),
					//.commit_kill_1(commit_kill_1),
					.commit_completed_0(commit_completed_0),
					//.commit_completed_1(commit_completed_1),
					.commit_commitable_0(commit_commitable_0),
					//.commit_commitable_1(commit_commitable_1),

					.snoop_data(load_snoop_data[I]),
					.depends(depends[I]),

					.load_snoop(load_snoop),



					.lr_valid(r_reserved_address_set[write_mem_hart[I]] && (r_reserved_address[write_mem_hart[I]]==write_mem_addr[I][NPHYS-1:ACACHE_LINE_SIZE]) && !write_mem_io[I]),

					.store_snoop(store_snoop),

					.load_ready(q_load_ready[I]),
					.load_ack(q_load_ack[I]),
					.load_ack_fail(q_load_ack_fail[I]),

					.mem_read_req(mem_read_req[I]),
					.mem_read_cancel(mem_read_cancel[I]),
					.mem_write_req(mem_write_req[I]),
					.mem_write_invalidate(mem_write_invalidate[I]),
					.mem_ack(dc_raddr_ack && (mem_read_req[I]||mem_write_req[I]) && (mem_req == I)),
					.mem_read_done(dc_rdata_req&&dc_rdata_ack&&(dc_rdata_trans[$clog2(NLDSTQ)-1:0]==I)),

					.write_io_read_req(write_io_read_req[I]),
					.write_io_write_req(write_io_write_req[I]),
					.write_io_lock(write_io_lock[I]),
					.write_io_data_ack(write_io_data_ack[I]),
					.io_cpu_addr_ack(io_cpu_addr_ack&io_ack[I]),
					.io_cpu_data_req(io_cpu_data_req),

					.fence_type(q_fence_type[I]),
					.tlb_invalidate(fence_tlb_invalidate[I]),
					.tlb_inv_type(fence_tlb_inv_type[I]),

					.write_mem(store_mem[I]),
					.write_ack(store_ack[I]),
					.write_data(write_mem_data[I]),
					.write_mask(write_mem_mask[I]),
					.write_hart(write_mem_hart[I]),
					.write_sc(write_mem_sc[I]),
					.write_sc_okv(write_mem_sc_okv[I]),
					.write_amo(write_mem_amo[I]),
					.write_addr(write_mem_addr[I]),
					.write_io(write_mem_io[I]),
					.write_ok_write(dc_wr_hit_ok_write[0]),
					.write_must_invalidate(dc_wr_hit_must_invalidate[0]),
					.write_wait(dc_wr_wait[0]),
					.wq_rd(wq_rd[I]),
`ifdef FP
					.wq_fp(wq_fp[I]),
`endif
					.wq_makes_rd(wq_makes_rd[I]),
					.wq_hart(wq_hart[I]),
					.wq_control(wq_control[I]),
					.wq_amo(wq_amo[I]),
					.wq_aq_rl(wq_aq_rl[I]),
					.active(all_active[I]),
					.free(free[I]),
					.all_active(all_active)
				);
		end
		assign dc_wr_enable[0] = |store_mem;
		assign dc_wr_addr[0] = q_mem_addr[NPHYS-1:$clog2(RV/8)];
		assign dc_wr_data[0] = q_mem_data;
		assign dc_wr_mask[0] = q_mem_mask;
		assign dc_wr_hart[0] = q_mem_hart;
		assign dc_wr_sc[0] = q_mem_sc;
		assign dc_wr_amo[0] = q_mem_amo;

		if (NLDSTQ == 8) begin
`include "mk16_8.inc"
		end else
		if (NLDSTQ == 16) begin
`include "mk16_16.inc"
		end else
		if (NLDSTQ == 32) begin
`include "mk16_32.inc"
		end 

		for (H = 0; H < NHART; H=H+1) begin
			// c_terms now live in mk21.*inc
			always @(posedge clk) begin
				r_reserved_address[H] <= c_reserved_address[H];
				r_reserved_address_set[H] <= !reset&&c_reserved_address_set[H];
			end
				
		end


		//assign dc_snoop_addr_ack = !dc_wr_enable[0] && !dc_wr_amo[0];	// AMO snoop stall
		assign dc_snoop_addr_ack = !dc_wr_enable[0];	// write snoop stall

		reg [$clog2(NLOAD)-1:0]r_load_unit_s0;
		always @(posedge clk)
			r_load_unit_s0 <= q_load_unit_s0;

		//
		//	AMO data path
		reg [RV-1:0]wdata[0:NWPORT-1];
		for (S = 0; S < NWPORT; S=S+1) begin
			if (S != 0) begin
				always @(*) wdata[S] = dc_wr_data[S];
			end else begin
				always @(*) begin :amo
					reg [63:0]dc_rd;
					reg [63:0]add64;
					reg [31:0]add32u, add32l;
					reg signed [63:0]s_rd, s_wr;
					reg signed [31:0]s_rd1, s_rd0, s_wr1, s_wr0;
					reg dword;

					reg lt, slt, lt1, slt1, lt0, slt0; 
	
					dc_rd = dc_load.ack[r_load_unit_s0].data;

					s_rd = dc_rd;
					s_rd0 = dc_rd[31:0];
					s_rd1 = dc_rd[63:32];
					s_wr = dc_wr_data[S];
					s_wr1 = dc_wr_data[S][63:32];
					s_wr0 = dc_wr_data[S][31:0];
					add64 = dc_wr_data[S]+dc_rd;
					add32l = dc_wr_data[S][31: 0]+dc_rd[31: 0];	// note for synthesis, make sure this line and the above are made from the same adder
					add32u = dc_wr_data[S][63:32]+dc_rd[63:32];
	
					dword = dc_wr_mask[S][4]&dc_wr_mask[S][0];
	
					lt=dc_wr_data[S]<dc_rd;
					slt=s_wr<s_rd;
					lt1=dc_wr_data[S][63:32]<dc_rd[63:32];
					slt1=s_wr1<s_rd1;
					lt0=dc_wr_data[S][31:0]<dc_rd[31:0];
					slt0=s_wr0<s_rd0;

					casez (dc_wr_amo[S]) // synthesis full_case parallel_case
					6'b?????_0,								// normal write
					6'b???11_1,								// sc
					6'b???01_1: wdata[S] = dc_wr_data[S];	// amoswap
					6'b000?0_1: wdata[S] = (dword?			// amoadd
												add64: {add32u, add32l});
					6'b001??_1: wdata[S] = dc_wr_data[S]^dc_rd;			
					6'b011??_1: wdata[S] = dc_wr_data[S]&dc_rd;			
					6'b010??_1: wdata[S] = dc_wr_data[S]|dc_rd;			
					6'b100??_1:	wdata[S] = (dword?			// amomin
												(slt?dc_wr_data[S]:dc_rd):
												{slt1?dc_wr_data[S][63:32]:dc_rd[63:32],
												slt0?dc_wr_data[S][31:0]:dc_rd[31:0]});
					6'b101??_1:	wdata[S] = (dword?			// amomax
												(!slt?dc_wr_data[S]:dc_rd):
												{!slt1?dc_wr_data[S][63:32]:dc_rd[63:32],
												!slt0?dc_wr_data[S][31:0]:dc_rd[31:0]});
					6'b110??_1:	wdata[S] = (dword?			// amominu
												(lt?dc_wr_data[S]:dc_rd):
												{lt1?dc_wr_data[S][63:32]:dc_rd[63:32],
												lt0?dc_wr_data[S][31:0]:dc_rd[31:0]});
					6'b111??_1:	wdata[S] = (dword?			// amomaxu
												(!lt?dc_wr_data[S]:dc_rd):
												{!lt1?dc_wr_data[S][63:32]:dc_rd[63:32],
												!lt0?dc_wr_data[S][31:0]:dc_rd[31:0]});
					default:  wdata[S] = 'bx; 
					endcase
				end
			end
		end

`ifdef AWS_DEBUG
		wire dc_trig;
`endif

		dcache_l1   #(.RV(RV), .NPHYS(NPHYS), .READPORTS(NLOAD), .TRANS_ID_SIZE(TRANS_ID_SIZE), .NLDSTQ(NLDSTQ), .CACHE_LINE_SIZE(CACHE_LINE_SIZE), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE))dc(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
			.xxtrig(xxtrig),
			.dc_trig(dc_trig),
`endif
`ifdef SIMD
			.simd_enable(simd_enable),
`endif

			.load(dc_load),

			.wenable0(dc_wr_enable[0]),             // CPU write port
			.waddr0(dc_wr_addr[0]),
			.wdata0(wdata[0]),
			.wmask0(dc_wr_mask[0]),
			.whit_ok_write0(dc_wr_hit_ok_write[0]),
			.whit_must_invalidate0(dc_wr_hit_must_invalidate[0]),
			.wwait0(dc_wr_wait[0]),

			.dc_snoop_addr(dc_snoop_addr),			// cache snoop interface
			.dc_snoop_addr_req(dc_snoop_addr_req),
			.dc_snoop_addr_ack(dc_snoop_addr_ack),
			.dc_snoop_snoop(dc_snoop_snoop),
			.dc_snoop_data_resp(dc_snoop_data_resp),
			.dc_snoop_data(dc_snoop_data),

			.dc_rdata_req(dc_rdata_req),
			.dc_rdata_ack(dc_rdata_ack),
			.dc_rdata(dc_rdata),
			.dc_rdata_resp(dc_rdata_resp),
			.dc_raddr(write_mem_addr[dc_rdata_trans[$clog2(NLDSTQ)-1:0]][NPHYS-1:ACACHE_LINE_SIZE]),

			.dc_waddr(dc_waddr),
			.dc_waddr_req(dc_waddr_req),
			.dc_waddr_ack(dc_waddr_ack),
			.dc_waddr_snoop(dc_waddr_snoop),
			.dc_waddr_trans(dc_waddr_trans),
			.dc_wdata(dc_wdata),

			.irand(irand),
			.orand(orand),

			.dummy(1'b0)
		);
	endgenerate
	

	//
	//	this is the VM TLB queue - a queue of pending L1 TLB fill requests 
	//		there's room here for (worst case) NE in one hart queued in 2 clocks and NLOAD+NSTORE
	//		queued from the other hart in the next clock. 
	//		while the first are being resolved
	//

	parameter VMQ_LEN = 2*NHART*(NADDR);

	reg  [(NHART==1?0:LNHART-1):0]r_vmq_hart[0:VMQ_LEN-1];
	reg  [(NHART==1?0:LNHART-1):0]c_vmq_hart[0:VMQ_LEN-1];
	reg  [VA_SZ-1:12]r_vmq_addr[0:VMQ_LEN-1];
	reg  [VA_SZ-1:12]c_vmq_addr[0:VMQ_LEN-1];
	reg[LNCOMMIT-1:0]r_vmq_commit[0:VMQ_LEN-1];
	reg[LNCOMMIT-1:0]c_vmq_commit[0:VMQ_LEN-1];
	reg	[VMQ_LEN-1:0]r_vmq_valid, c_vmq_valid;
	reg       [15: 0]r_vmq_asid[0:VMQ_LEN-1];
	reg       [15: 0]c_vmq_asid[0:VMQ_LEN-1];
	reg [VMQ_LEN-1:0]r_vmq_duplicate, c_vmq_duplicate;	// if set this is a duplicate and needs to be released when scheduled

	reg  [VA_SZ-1:12]r_vmq_pending_addr, c_vmq_pending_addr;
	reg       [15: 0]r_vmq_pending_asid, c_vmq_pending_asid;
	reg[LNCOMMIT-1:0]r_vmq_pending_commit, c_vmq_pending_commit;
	reg  [(NHART==1?0:LNHART-1):0]r_vmq_pending_hart, c_vmq_pending_hart;
	reg	 		 	 r_vmq_pending_valid, c_vmq_pending_valid;

	//
	//	current pending transactions (not logic, just renaming wires for the generate below)
	//
	wire [NADDR-1:0]tlb_rd_stall = c_addr_vm_stall;	// true when a unit has a VM miss

	// 'packed' versions of the above
	reg [NSTORE+NLOAD-1:0]cv_stall;		// true when a unit has a VM miss
	reg     [LNCOMMIT-1:0]cv_commit[0:NADDR-1];
	reg[(NHART==1?0:LNHART-1):0]cv_hart[0:NADDR-1];
	reg        [VA_SZ-1:0]cv_vaddr[0:NADDR-1];
	reg            [15: 0]cv_asid[0:NADDR-1];


	wire	[VMQ_LEN-1:0]vmq_match;
	reg		[VMQ_LEN-1:0]vmq_kill;
	reg [$clog2(VMQ_LEN)-1:0]vmq_first;
	wire vmq_shift = (r_vmq_addr_req&&tlb_d_addr_ack&&!tlb_d_addr_cancel)||(r_vmq_valid[0]&r_vmq_duplicate[0]&!tlb_d_data_req);

	wire [VMQ_LEN-1:0]vmq_hart_busy[0:NHART-1];
wire [VMQ_LEN-1:0]vmq_hart_busy_0=vmq_hart_busy[0];

	genvar V;
	generate
		if (NHART == 1) begin
			if (NADDR == 6) begin
`include "mk17_1_6.inc"
			end else
			if (NADDR == 5) begin
`include "mk17_1_5.inc"
			end else
			if (NADDR == 4) begin
`include "mk17_1_4.inc"
			end 
		end
		for (V = 0; V < VMQ_LEN; V = V + 1) begin
			if (V > 0) begin
				assign vmq_match[V] = r_vmq_valid[V] && ((r_vmq_valid[0]&&r_vmq_addr[V]==r_vmq_addr[0]&&r_vmq_asid[V]==r_vmq_asid[0]&&r_vmq_hart[V]==r_vmq_hart[0]) ||
														 (r_vmq_pending_valid&&r_vmq_addr[V]==r_vmq_pending_addr&&r_vmq_asid[V]==r_vmq_pending_asid&&r_vmq_hart[V]==r_vmq_pending_hart));
			end else begin
				assign vmq_match[0] = r_vmq_valid[0] && (r_vmq_pending_valid&&r_vmq_addr[0]==r_vmq_pending_addr&&r_vmq_asid[0]==r_vmq_pending_asid&&r_vmq_hart[0]==r_vmq_pending_hart);
			end
			always @(*) begin 
				case (r_vmq_hart[V])	// synthesis full_case parallel_case
				0: vmq_kill[V] = commit_kill_0[r_vmq_commit[V]];
				//1: vmq_kill[V] = commit_kill_1[r_vmq_commit[V]];
				endcase
			end
			if (V < (VMQ_LEN-1)) begin
				always @(*) begin
					//
					//
					//
					//
					//	0						vmq_first-1					- active
					//  vmq_first				vmq_first+NLOAD+NSTORE-1	- allocatable
					//	vmq_first+NLOAD+NSTORE	VLEN-1						- free
					//
					if (V >= vmq_first) begin
						if (V >= (vmq_first+NLOAD+NSTORE)) begin
							c_vmq_valid[V] = 0;
							c_vmq_addr[V] = 'bx;
							c_vmq_hart[V] = 'bx;
							c_vmq_commit[V] = 'bx;
							c_vmq_asid[V] = 'bx;
							c_vmq_duplicate[V] = 'bx;
						end else begin
							c_vmq_valid[V] = cv_stall[V-vmq_first];
							c_vmq_addr[V] = cv_vaddr[V-vmq_first];
							c_vmq_hart[V] = cv_hart[V-vmq_first];
							c_vmq_commit[V] = cv_commit[V-vmq_first];
							c_vmq_asid[V] = cv_asid[V-vmq_first];
							c_vmq_duplicate[V] = 0;
						end
					end else
					if ((vmq_shift||!r_vmq_valid[V])) begin
						c_vmq_valid[V] = r_vmq_valid[V+1]&&!vmq_kill[V+1];
						c_vmq_addr[V] = r_vmq_addr[V+1];
						c_vmq_hart[V] = r_vmq_hart[V+1];
						c_vmq_commit[V] = r_vmq_commit[V+1];
						c_vmq_asid[V] = r_vmq_asid[V+1];
						c_vmq_duplicate[V] = r_vmq_duplicate[V+1]|vmq_match[V+1];
					end else begin
						c_vmq_valid[V] = r_vmq_valid[V]&&!vmq_kill[V];
						c_vmq_addr[V] = r_vmq_addr[V];
						c_vmq_hart[V] = r_vmq_hart[V];
						c_vmq_commit[V] = r_vmq_commit[V];
						c_vmq_asid[V] = r_vmq_asid[V];
						c_vmq_duplicate[V] = r_vmq_duplicate[V]|vmq_match[V];
					end
				end
				for (H=0; H < NHART; H=H+1) begin
					assign vmq_hart_busy[H][V] = r_vmq_valid[V] && (r_vmq_hart[V]==H);
				end
			end else begin
				always @(*) begin
					if (V >= vmq_first) begin
						if (V >= (vmq_first+NLOAD+NSTORE)) begin
							c_vmq_valid[V] = 0;
							c_vmq_addr[V] = 'bx;
							c_vmq_hart[V] = 'bx;
							c_vmq_commit[V] = 'bx;
							c_vmq_asid[V] = 'bx;
							c_vmq_duplicate[V] = 'bx;
						end else begin
							c_vmq_valid[V] = cv_stall[V-vmq_first];
							c_vmq_addr[V] = cv_vaddr[V-vmq_first];
							c_vmq_hart[V] = cv_hart[V-vmq_first];
							c_vmq_commit[V] = cv_commit[V-vmq_first];
							c_vmq_asid[V] = cv_asid[V-vmq_first];
							c_vmq_duplicate[V] = 0;
						end
					end else
					if (vmq_shift) begin
						c_vmq_valid[V] = 0;
						c_vmq_addr[V] = 'bx;
						c_vmq_hart[V] = 'bx;
						c_vmq_commit[V] = 'bx;
						c_vmq_asid[V] = 'bx;
						c_vmq_duplicate[V] = 'bx;
					end else begin
						c_vmq_valid[V] = r_vmq_valid[V]&&!vmq_kill[V];
						c_vmq_addr[V] = r_vmq_addr[V];
						c_vmq_hart[V] = r_vmq_hart[V];
						c_vmq_commit[V] = r_vmq_commit[V];
						c_vmq_asid[V] = r_vmq_asid[V];
						c_vmq_duplicate[V] = r_vmq_duplicate[V]|vmq_match[V];
					end
				end
				for (H=0; H < NHART; H=H+1) begin
					assign vmq_hart_busy[H][V] = r_vmq_valid[V] && (r_vmq_hart[V]==H);
				end
			end
			always @(posedge clk) begin
				r_vmq_valid[V] <= !reset && c_vmq_valid[V];
				r_vmq_asid[V] <= c_vmq_asid[V];
				r_vmq_commit[V] <= c_vmq_commit[V];
				r_vmq_addr[V] <= c_vmq_addr[V];
				r_vmq_hart[V] <= (reset?0:c_vmq_hart[V]);
				r_vmq_duplicate[V] <= c_vmq_duplicate[V];
			end
		end

		//for (H = 0; H < NHART; H=H+1) begin
		//	assign vm_busy[H] = (r_vmq_pending_valid&&(r_vmq_pending_hart==H)) ||  ( | vmq_hart_busy[H]);
		//end
	endgenerate

	reg		r_vmq_addr_req;
	wire	c_vmq_addr_req = c_vmq_valid[0] && !tlb_d_addr_cancel && !c_vmq_duplicate[0] && (!c_vmq_pending_valid || c_vmq_pending_addr!=c_vmq_addr[0] || c_vmq_hart[0]!=c_vmq_pending_hart);

	assign tlb_d_asid     = r_vmq_asid[0];
	assign tlb_d_vaddr    = r_vmq_addr[0];
	assign tlb_d_hart     = r_vmq_hart[0];
	assign tlb_d_addr_tid = r_vmq_commit[0];
	assign tlb_d_addr_req = r_vmq_addr_req && !tlb_d_addr_cancel && !vmq_kill[0];

	reg vmq_done_kill;

	generate
		if (NHART == 1) begin
			assign vm_ack.hart[0] = ((tlb_d_data_req && !vmq_done_kill) || (r_vmq_valid[0] && r_vmq_duplicate[0]));
		end else begin
			reg [NHART-1:0]h;
			always @(*) begin
				h = 0;
				if ((tlb_d_data_req && !vmq_done_kill) || (r_vmq_valid[0] && r_vmq_duplicate[0]))
					h[tlb_d_data_req ? r_vmq_pending_hart: r_vmq_hart[0]] = 1;	// FIXME ?
			end
			assign vm_ack.hart = h;
		end
	endgenerate
	
	assign vm_ack.fail = (tlb_d_data_req?!tlb_d_valid: 0);
	assign vm_ack.pmp  = (tlb_d_data_req?!tlb_d_valid&tlb_d_pmp_fail:0);
	assign vm_ack.rd = (tlb_d_data_req ?tlb_d_data_tid : r_vmq_commit[0]);

	always @(*) begin
		//case (??)	// synthesis full_case parallel_case
		vmq_done_kill = commit_kill_0[tlb_d_data_tid];	// FIXME
	end
		

	reg vmq_pending_kill;
	
	always @(*) begin
		case (r_vmq_pending_hart)	// synthesis full_case parallel_case
		0: vmq_pending_kill = commit_kill_0[r_vmq_pending_commit];
		//1: vmq_pending_kill = commit_kill_1[r_vmq_pending_commit];
		endcase
	end

	always @(*) begin
		c_vmq_pending_valid = r_vmq_pending_valid;
		c_vmq_pending_addr = r_vmq_pending_addr;
		c_vmq_pending_asid = r_vmq_pending_asid;
		c_vmq_pending_hart = r_vmq_pending_hart;
		c_vmq_pending_commit = r_vmq_pending_commit;
		
		if (r_vmq_addr_req && tlb_d_addr_ack && !tlb_d_addr_cancel && !vmq_kill[0]) begin 
			c_vmq_pending_valid = 1;
			c_vmq_pending_addr = r_vmq_addr[0];
			c_vmq_pending_asid = r_vmq_asid[0];
			c_vmq_pending_hart = r_vmq_hart[0];
			c_vmq_pending_commit = r_vmq_commit[0];
		end else
		if ((tlb_d_data_req && r_vmq_pending_commit == tlb_d_data_tid) || tlb_d_addr_cancel) begin // FIXME for multiple harts need to test hart here and carry hart with tlb_d_data_tid
			c_vmq_pending_valid = 0;
		end

	end

	assign tlb_d_addr_cancel = r_vmq_pending_valid && vmq_pending_kill;

	always @(posedge clk) begin
		r_vmq_addr_req <= !reset&&c_vmq_addr_req;
		r_vmq_pending_valid <= !reset && c_vmq_pending_valid;
		r_vmq_pending_addr <= c_vmq_pending_addr;
		r_vmq_pending_asid <= c_vmq_pending_asid;
		r_vmq_pending_hart <= (reset?0:c_vmq_pending_hart);
		r_vmq_pending_commit <= c_vmq_pending_commit;
	end

	dtlb		#(.RV(RV), .VA_SZ(VA_SZ), .NADDR(NADDR), .NHART(NHART), .LNHART(LNHART), .NPHYS(NPHYS), .TLB_SETS(0), .TLB_ENTRIES(32))tlb(.clk(clk), .reset(reset),
			.tlb(dtlb),

			.wr_vaddr(tlb_d_data_vaddr),     // write path
			.wr_asid(tlb_d_data_asid),
			.wr_paddr(tlb_d_paddr),
			.wr_entry(tlb_d_data_req&&tlb_d_valid&&!vmq_done_kill),
			.wr_gaduwrx(tlb_d_gaduwrx),
			.wr_2mB(tlb_d_2mB),
			.wr_4mB(tlb_d_4mB),
			.wr_1gB(tlb_d_1gB),
			.wr_512gB(tlb_d_512gB),

			.wr_inv_vaddr(tlb_wr_inv_vaddr),     // write invalidate path
			.wr_inv_asid(tlb_wr_inv_asid),
			.wr_invalidate(tlb_wr_invalidate),
			.wr_invalidate_asid(tlb_wr_invalidate_asid),	// all asid
			.wr_inv_unified(tlb_wr_inv_unified),
			.wr_invalidate_addr(tlb_wr_invalidate_addr)		// all address

		);

`ifdef AWS_DEBUG
	wire  ls_trig_out, ls_trig_out_ack;
    ila_ls ila_lsx(.clk(clk),
			.xxtrig(xxtrig)
            ));

        ila_ls2 ila_ls2(.clk(clk),
            .xxtrig(xxtrig)
			);

        ila_ls3 ila_ls3(.clk(clk),
            .xxtrig(xxtrig)
			);

        );

    wire [3:0]xxtrig_sel;
    wire [31:0]xxtrig_cmp;
    wire [15:0]xxtrig_count;
    wire [39:0]xxtrig_ticks;


    reg xls_trig;
    assign ls_trig=xls_trig;
    always @(*)
    case (xxtrig_sel)
    //0: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0];
    //1: xls_trig = r_store_state[0] && c_store_paddr[0][31:0] == xxtrig_cmp[31:0];
    //2: xls_trig = r_load_state[0] && c_load_vaddr[0][31:0] == xxtrig_cmp[31:0];
    //3: xls_trig = r_load_state[0] && c_load_paddr[0][31:0] == xxtrig_cmp[31:0];
    //4: xls_trig = r_load_state[1] && c_load_vaddr[1][31:0] == xxtrig_cmp[31:0];
    //5: xls_trig = r_load_state[1] && c_load_paddr[1][31:0] == xxtrig_cmp[31:0];
    //6: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][15:0] == xxtrig_count[15:0];
    //7: xls_trig = r_store_state[0] && c_store_paddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][15:0] == xxtrig_count[15:0];
    //8: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][31:0] == xxtrig_ticks[31:0];
    //9: xls_trig = r_store_state[0] && c_store_paddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][31:0] == xxtrig_ticks[31:0];
    //10: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][7:0] == xxtrig_count[7:0];
    //11: xls_trig = r_store_state[0] && istore_r2[0][31:0] == xxtrig_cmp[31:0];
    //12: xls_trig = r_store_state[0] && c_store_vaddr[0][31:3] == xxtrig_cmp[31:3];
	13: xls_trig = dc_trig;
    default: xls_trig=0;
    endcase

    vio_cpu vio_ls_trig(.clk(clk),
            // outputs
             .xxtrig_sel(xxtrig_sel),
             .xxtrig_cmp(xxtrig_cmp),
			 .xxtrig_count(xxtrig_count),
			 .xxtrig_ticks(xxtrig_ticks)
            );

`ifdef NOTDEF
    vio_ls vio_ls(.clk(clk),
            .io_cpu_addr_req(io_cpu_addr_req),
            .io_cpu_addr_ack(io_cpu_addr_ack),
            .io_cpu_data_req(io_cpu_data_req),
            .io_cpu_data_ack(io_cpu_data_ack),
            .load_ready(load_ready), // 8-bit
            .p0(8'b0),
            .p1(1'b0),
            .p2(1'b0),
            .p3(1'b0),
            .p4(1'b0));
`endif

`endif

endmodule

//
//	store queue entries aka write buffers
//		(also used for loads who are blocked by smaller stores to the same cache line and some other not easily 
//		resolved edge cases)
//
module ldstq(
	input 		clk,
	input 		reset,
`ifdef AWS_DEBUG
	input		trig_in,
	input		xxtrig,
`endif

	input		load,
	input		store,
	input		fence,
	input 		allocate,
	input 		makes_rd,
	input   [NPHYS-1:0]addr,
	input		       io,
	input   [RV-1:0]data,
	input [RV/8-1:0]mask,
	input [(NHART==1?0:LNHART-1):0]hart,
	input [2:0]control,
	input [1:0]aq_rl,
	input [1:0]fd,
	input  [LNCOMMIT-1:0]rd,
`ifdef FP
	input  fp,
`endif
	input  [5:0]amo,
	input  [NLDSTQ-1:0]hazard,
	input  [NLDSTQ-1:0]all_store_mem,
	input  [NLDSTQ-1:0]all_active,
	input		lr_valid,
	input		cache_miss,


	input					  line_busy,
	input [$clog2(NLDSTQ)-1:0]line_busy_trans,
	input					  dc_raddr_req,
	input [NPHYS-1:ACACHE_LINE_SIZE]dc_raddr,
	input [$clog2(NLDSTQ)-1:0]dc_raddr_trans,
	input				      dc_rdata_req,
	input [$clog2(NLDSTQ)-1:0]dc_rdata_trans,
					
	input [NCOMMIT-1:0]commit_0,	// per-hart commit
	//input [NCOMMIT-1:0]commit_1,
	input [NCOMMIT-1:0]commit_completed_0,	// per-hart commit
	//input [NCOMMIT-1:0]commit_completed_1,
	input [NCOMMIT-1:0]commit_kill_0,	// per-hart commit
	//input [NCOMMIT-1:0]commit_kill_1,
	input [NCOMMIT-1:0]commit_commitable_0,
	//input [NCOMMIT-1:0]commit_commitable_1,
				

	output [RV-1:0]snoop_data,
	output [NLDSTQ-1:0]depends,

	LOAD_SNOOP  load_snoop,

	STORE_SNOOP store_snoop,

	output		write_mem,
	input		write_ack,
	input		write_ok_write,
	input		write_must_invalidate,
	input		write_wait,
	output  [5:0]write_amo,
	output  [RV-1:0]write_data,
	output [RV/8-1:0]write_mask,
	output [NPHYS-1:0]write_addr,
	output      write_io,
	output [(NHART==1?0:LNHART-1):0]write_hart,
	output			  write_sc,
	output			  write_sc_okv,
	output [LNCOMMIT-1:0]wq_rd,
`ifdef FP
	output			wq_fp,
`endif
	output		wq_makes_rd,
	output [(NHART==1?0:LNHART-1):0]wq_hart,
	output [3:0]wq_control,
	output [5:0]wq_amo, 
	output [1:0]wq_aq_rl, 

	output		mem_read_req,
	output		mem_read_cancel,
	output		mem_write_req,
	input		mem_read_done,
	output		mem_write_invalidate,
	input		mem_ack,

	output		write_io_read_req,
	output		write_io_write_req,
	output		write_io_lock,
	output		write_io_data_ack,
	input		io_cpu_addr_ack,
	input		io_cpu_data_req,

	output		tlb_invalidate,
	output [1:0]tlb_inv_type,		// 1 - rs1==0 - all addresses
	input  [1:0]fence_type,			// 0 - rs2==0 - all ASID

	output		load_ready,
	input		load_ack,
	input		load_ack_fail,

	output		free,
	output		active
	);
	parameter RV=32;
	parameter LNCOMMIT=5;
	parameter NCOMMIT=32;
	parameter LNHART=0;
	parameter NHART=1;
	parameter NLDSTQ=8;
	parameter NPHYS=56;
	parameter ACACHE_LINE_SIZE=6;
	parameter ADDR=0;
	parameter TRANS_ID_SIZE=6;
	parameter NLOAD=2;
	parameter NSTORE=2;

	reg			c_write_io_read_req;
	assign		write_io_read_req = c_write_io_read_req;
	reg			c_write_io_write_req;
	assign		write_io_write_req = c_write_io_write_req;
	reg			c_write_io_lock;
	assign		write_io_lock = c_write_io_lock;
	reg			c_write_io_data_ack;
	assign		write_io_data_ack = c_write_io_data_ack;

	//
	//		read -> tlb fetch -> cache fetch -> done
	//
	//		write -> tlb fetch -> commit -> cache fetch -> done
	//
	//

	reg [NPHYS-1:0]r_addr, c_addr;
	reg		       r_io, c_io;
	reg [RV-1:0]r_data, c_data;
	reg [(RV/8)-1:0]r_mask, c_mask;
	reg 		r_valid, c_valid;
	assign active = r_valid;
	reg [(NHART==1?0:LNHART-1):0]r_hart, c_hart;
	assign wq_hart = r_hart;
	assign write_hart = r_hart;
	reg [2:0]r_control, c_control;
	reg    [5:0]r_amo, c_amo;		// LSB is AMO valid bit, upper 4 bits identify which one
	assign wq_amo = r_amo;
	assign wq_control = {r_load&r_amo[0],r_control};
	assign write_amo = r_amo;
	reg    [1:0]r_aq_rl, c_aq_rl;	// aq = bit 1 rl = bit 0
	assign wq_aq_rl = r_aq_rl;
	reg    [1:0]r_fd, c_fd;	// fence data bits 24:23
	reg  [LNCOMMIT-1:0]r_rd, c_rd;
	assign		wq_rd = r_rd;
`ifdef FP
	reg         r_fp, c_fp;	
	assign		wq_fp = r_fp;
`endif
	reg			r_makes_rd, c_makes_rd;
	assign		wq_makes_rd = r_makes_rd;
	reg 		r_commit, c_commit;
	reg 		r_killed, c_killed;
	reg 		r_cache_miss, c_cache_miss;
	reg  [NLDSTQ-1:0]r_hazard, c_hazard;

	wire [3:0]pred = r_amo[4:1];		// fence predecessors IORW
	wire [3:0]succ = {r_aq_rl, r_fd};	// fence successors	  IORW


	

	wire fence_against_following_reads = (r_valid&&r_store&&r_amo[0]&&r_aq_rl[1]) ||
								         (r_valid&&r_load&&r_amo[0]&&r_aq_rl[1]);

	wire [NLOAD-1:0]load_match;
	wire [NLOAD-1:0]load_line_hit;
	wire [NSTORE-1:0]store_line_hit;
	wire [NSTORE-1:0]store_addr_hit;
	genvar L, S;
	generate 

		for (L = 0; L < NLOAD; L=L+1) begin : ld
			assign load_line_hit[L] = r_valid&&!r_killed&&!r_fence&&(load_snoop.req[L].addr[NPHYS-1:ACACHE_LINE_SIZE]==r_addr[NPHYS-1:ACACHE_LINE_SIZE]) && !load_snoop.req[L].io && !r_io;
			assign load_match[L] = r_valid&&!r_killed&&r_store&&(load_snoop.req[L].addr[NPHYS-1:$clog2(RV/8)]==r_addr[NPHYS-1:$clog2(RV/8)]) && !load_snoop.req[L].io&& !r_io;
			assign load_snoop.ack[L].hit[ADDR] = load_match[L]&&((load_snoop.req[L].mask&r_mask)!=0);
			assign load_snoop.ack[L].hazard[ADDR] = load_match[L]&&(((load_snoop.req[L].mask&r_mask)!=load_snoop.req[L].mask&r_mask)||(r_amo[0])) ||
							fence_against_following_reads ||
							(r_valid&&r_fence&&succ[1]&&!load_snoop.req[L].io)||
							(r_valid&&r_fence&&succ[3]&&load_snoop.req[L].io)||
							(r_valid && r_io && load_snoop.req[L].io);
			assign load_snoop.ack[L].line_busy[ADDR] = load_line_hit[L]&r_waiting_memory;

		end
		assign depends = r_hazard;

		for (S = 0; S < NSTORE; S=S+1) begin
			assign store_addr_hit[S] = r_valid&&!r_killed&&!r_fence&&(store_snoop.req[S].addr[NPHYS-1:$clog2(RV/8)]==r_addr[NPHYS-1:$clog2(RV/8)]) && !r_io && !store_snoop.req[S].io;
			assign store_line_hit[S] = r_valid&&!r_killed&&!r_fence&&(store_snoop.req[S].addr[NPHYS-1:ACACHE_LINE_SIZE]==r_addr[NPHYS-1:ACACHE_LINE_SIZE]) && !r_io && !store_snoop.req[S].io;
			assign store_snoop.ack[S].line_busy[ADDR] = store_line_hit[S]&r_waiting_memory;
			assign store_snoop.ack[S].hazard[ADDR] = store_addr_hit[S] &&
							 (((store_snoop.req[S].mask&r_mask)!=0)||(r_amo[0])) ||
                            fence_against_following_reads || // ??
                            (r_valid&&r_fence&&succ[0]&&!store_snoop.req[S].io)||
                            (r_valid&&r_fence&&succ[2]&&store_snoop.req[S].io)||
                            (r_valid && r_io && store_snoop.req[S].io);
		end
	endgenerate

	assign snoop_data = r_data;

	assign write_data = r_data;
	assign write_mask = r_mask;
	assign write_addr = r_addr;
	assign write_io = r_io;
	reg commit, killed, commitable;
	reg r_free, c_free;
	reg free_out;
	assign free = r_valid && free_out;

	reg		c_load_ready;
	assign load_ready = c_load_ready&!r_killed;
	
	reg		r_load, c_load;
	reg		r_store, c_store;
	reg		r_store_cond, c_store_cond;
	assign write_sc = c_store_cond;
	reg		r_store_cond_okv, c_store_cond_okv;
	assign write_sc_okv = c_store_cond_okv;
	reg		r_fence, c_fence;
	reg		r_load_acked, c_load_acked;
	reg		r_last_load_acked, c_last_load_acked;
	reg	[1:0]r_io_state, c_io_state;
	reg		r_acked, c_acked;
	reg		r_cache_invalidate, c_cache_invalidate;
	reg		r_waiting_hazard, c_waiting_hazard;
	reg		r_waiting_line_busy, c_waiting_line_busy;
	reg  [$clog2(NLDSTQ)-1:0]r_waiting_line_index, c_waiting_line_index;
	reg		r_waiting_memory, c_waiting_memory;
	reg		r_send_cancel, c_send_cancel;
	reg		r_ack_waiting;
	wire	c_ack_waiting;
	reg		write_done;
	reg		r_tlb_invalidate;
	reg		completed;
	assign tlb_invalidate = completed&&r_valid&&r_fence&&(r_control[2:0] <=2)&&!r_free&&!(killed||r_killed);
	reg[1:0]r_tlb_inv_type, c_tlb_inv_type;
	assign	tlb_inv_type = r_tlb_inv_type;

	always @(*) begin
		c_waiting_line_busy = r_waiting_line_busy;
		c_waiting_line_index = r_waiting_line_index;
		if (reset || (!r_valid&&!allocate) || (r_valid && dc_rdata_req && r_waiting_line_index==dc_rdata_trans)) begin
			c_waiting_line_busy = 0;
		end else
		if (allocate && !fence) begin
			c_waiting_line_busy = (line_busy && !io) && !(dc_rdata_req && line_busy_trans==dc_rdata_trans);
			c_waiting_line_index = line_busy_trans;
		end else
		if (dc_raddr_req && r_valid && !r_fence && !r_io && dc_raddr==r_addr[NPHYS-1:ACACHE_LINE_SIZE] && dc_raddr_trans != ADDR) begin
			c_waiting_line_busy = 1;
			c_waiting_line_index = dc_raddr_trans;
		end
	end

	assign mem_read_req = r_load&r_waiting_memory&!r_acked&!killed || r_send_cancel;
	assign mem_write_req = r_store&r_cache_miss&!r_acked;
	assign mem_write_invalidate = r_cache_invalidate;
	assign mem_read_cancel = r_send_cancel;

	reg do_write_amo;
	reg r_do_write_sc, c_do_write_sc;
	assign write_mem = !reset && !r_io && r_store && (!r_amo[0]?1'b1:((r_amo[2:1]==2'b11)? lr_valid:do_write_amo)) && !allocate && (r_do_write_sc|do_write_amo|c_commit) && !r_cache_miss && !r_waiting_line_busy && !r_waiting_hazard && !c_killed;
	always @(*) begin
		if (reset || allocate || !r_valid) begin
			free_out = 0;
		end else
		casez ({r_store, r_fence, r_load}) // synthesis full_case parallel_case
		3'b1??: free_out = (r_free || (((killed&!c_commit&r_valid)|r_killed)) || write_done ||
						   (r_load_acked&((!load_ack_fail&&write_done)||r_amo[2:0]==3'b111)));
		3'b?1?:	if (r_control[2:0] < 3) begin
					free_out = ((c_killed&(completed|!c_commit)&r_valid) || r_killed ||  r_free || r_tlb_invalidate || tlb_invalidate);
				end else begin
					free_out = (r_load_acked || r_control[2:0]==4 || ((r_killed || killed)&&r_valid));
				end
		3'b??1: free_out = c_killed && !c_send_cancel;
		default:free_out = 'bx; 
		endcase
	end

	always @(*) begin
		case (r_hart)  // synthesis full_case parallel_case
	        0: commit = commit_0[r_rd];
	        //1: commit = commit_1[r_rd];
		default: commit = 1'bx;
		endcase
		c_commit = 0;
		if (!reset&&!allocate&&r_valid&&(r_commit||!(killed|r_killed))) 
			c_commit = commit | r_commit;
	end
	
	always @(*) begin
		if (!r_valid) begin
			commitable = 0;
		end else
		case (r_hart) // synthesis full_case parallel_case
	        0: commitable = commit_commitable_0[r_rd];
	        //1: commitable = commit_commitable_1[r_rd];
		default: commitable = 1'bx;
		endcase
	end
	
	always @(*) begin
		if (!r_valid) begin
			killed = 0;
		end else
		case (r_hart) // synthesis full_case parallel_case
	        0: killed = commit_kill_0[r_rd];
	        //1: killed = commit_kill_1[r_rd];
		default: killed = 1'bx;
		endcase
	end
	
	always @(*) begin
		if (!r_valid) begin
			completed = 0;
		end else
		case (r_hart) // synthesis full_case parallel_case
	        0: completed = commit_completed_0[r_rd];
	        //1: completed = commit_completed_1[r_rd];
		default: completed = 1'bx;
		endcase
	end

	always @(*) begin
		c_write_io_data_ack = 0;
		c_write_io_read_req = 0;
		c_write_io_write_req = 0;
		c_write_io_lock = 0;
		do_write_amo = 0;
		c_do_write_sc = 0;
		c_io_state = r_io_state;
		c_acked = (mem_ack|r_acked)&!reset;
		c_valid = r_valid;
		c_data = r_data;
		c_mask = r_mask;
		//c_commit = r_commit;
		c_rd = r_rd;
`ifdef FP
		c_fp = r_fp;
`endif
		c_aq_rl = r_aq_rl;
		c_fd = r_fd;
		c_makes_rd = r_makes_rd;
		c_killed = r_killed;
		c_hart = r_hart;
		c_control = r_control;
		c_amo = r_amo;
		c_hazard = r_hazard&~all_store_mem&all_active;
		c_load_ready = 0;
		c_load_acked = r_load_acked;
		c_last_load_acked = 0;
		c_cache_miss = r_cache_miss&!reset&!c_waiting_line_busy;
		c_cache_invalidate = r_cache_invalidate;
		c_store_cond = r_store_cond;
		c_store_cond_okv = r_store_cond_okv;
		//write_mem_out = 0;
		c_free = 0;
		write_done = 0;
		c_send_cancel = r_send_cancel&!c_acked;
		c_waiting_hazard = r_waiting_hazard;
		c_waiting_memory = r_waiting_memory;
		c_tlb_inv_type = r_tlb_inv_type;
		if (reset) begin
			c_valid = 0;
			//c_commit = 0;
			c_hart = 0;
			c_rd = 0;
			c_killed = 0;
			c_load_acked = 0;
			c_load = 0;
			c_fence = 0;
			c_store = 0;
			c_io_state = 0;
			c_send_cancel = 0;
			c_addr = 56'bx;
			c_io = 1'bx;
			c_waiting_memory = 0;
		end else
		if (allocate) begin
			c_io_state = 0;
			c_cache_invalidate = 0;
			c_acked = 0;
			c_valid = 1;
			c_data = data;
			c_addr = addr;
			c_io = io;
			c_mask = mask;
			c_cache_miss = cache_miss && !line_busy;
			c_rd = rd;
`ifdef FP
			c_fp = fp;
`endif
			c_aq_rl = aq_rl;
			c_fd = fd;
			c_amo = amo;
			c_hart = hart;
			c_control = (load||fence?control:{2'b01, mask[7]&mask[3]});	// amo is .d or .w
			//c_commit = 0;
			c_load = load;
			c_store = store;
			c_store_cond = 0;
			c_store_cond_okv = 0;
			c_send_cancel = 0;
			c_fence = fence;
			c_makes_rd = makes_rd;
			c_hazard = hazard&~all_store_mem;
			c_waiting_hazard = (hazard!=0 || amo[0]) && !fence;
			c_waiting_memory = ((!c_waiting_hazard))&&cache_miss;
			c_load_acked = 0;
			c_tlb_inv_type = fence_type;
			case (hart) // synthesis full_case parallel_case
	        0: c_killed = commit_kill_0[rd];
	        //1: c_killed = commit_kill_1[rd];
			default: c_killed = 1'bx;
			endcase
		end else begin
			c_addr = r_addr;
			c_io = r_io;
			c_load = r_load;
			c_fence = r_fence;
			c_store = r_store;
			if (r_valid) begin
	
				casez ({r_amo[0], (r_amo[2:1]==2'b11), r_store, r_fence, r_load}) // synthesis full_case parallel_case
				default: ;
				5'b0?1??:		// store
					begin
						c_killed = !c_commit&(r_killed|killed);
						if (r_waiting_hazard) begin
							c_waiting_hazard = c_hazard != 0;
						end else
						if (r_io) begin
							if ((c_commit|r_commit)&!(r_killed|killed)) begin 
								c_write_io_write_req = 1;
								if (io_cpu_addr_ack) begin
									c_free = 1;
									write_done = 1;
								end
							end
						end else begin
							if (!r_waiting_line_busy) begin
								write_done = write_mem&&!write_wait&&write_ok_write&&!write_must_invalidate&&write_ack; 
								if (mem_write_req&&mem_ack) 
										c_waiting_memory = ~(r_killed|killed);
								if (write_mem && !write_wait && write_ack) begin
									if ( !write_ok_write || write_must_invalidate ) begin
										c_cache_miss = 1;
										c_cache_invalidate = write_must_invalidate;
										c_acked = 0;
									end
								end else
								if (mem_read_done) begin
									c_cache_miss = 0;
									c_waiting_memory = 0;
								end
								c_free = (r_commit|((commit)&r_valid)) && !c_cache_miss && write_done;
							end
						end
					end
				5'b111??:		// sc	- MUST be handled at first
					begin
						c_killed = !c_commit&(r_killed|killed);
						c_load_acked = r_load_acked|load_ack;
						if (r_io) begin
							c_load_ready = 1;
							c_store_cond = 1;
							c_store_cond_okv = 1;
							write_done = r_load_acked;
							c_free = r_load_acked;
						end else begin
							if (r_waiting_hazard) begin
								c_waiting_hazard = c_hazard != 0;
							end 
							if (!r_waiting_line_busy)
							if (r_store_cond) begin
								c_load_ready = !r_load_acked&&!c_waiting_hazard;
								write_done = r_load_acked;
								c_store_cond_okv = r_store_cond_okv|load_ack_fail;
							end else
							if (!lr_valid) begin
								c_load_ready = 1;
								c_store_cond = 1;
								c_store_cond_okv = 1;
							end else
							if (write_mem && write_ack) begin
								c_load_ready = 1;
								c_store_cond = 1;						
								c_store_cond_okv = r_store_cond_okv || !(!write_wait&&write_ok_write&&!write_must_invalidate);
							end else begin
								c_do_write_sc = write_ack;
							end
							c_free = write_ack && (r_commit|((commit)&r_valid)) && !c_cache_miss;
						end
					end
				5'b101??:		// store.amo	- MUST be handled at first 
					begin
						c_killed = !c_commit&(r_killed|killed);
						if (r_io) begin
							c_write_io_lock = 1;
							case (r_io_state ) // synthesis full_case parallel_case
							0:	begin
									c_write_io_read_req = 1;
									if (io_cpu_addr_ack) begin
										c_io_state = 1;
									end
								end
							1:  begin
									if (io_cpu_data_req) begin
										c_load_ready = 1;
										if (load_ack) begin
											c_write_io_data_ack = 1;
											c_io_state = 2;
										end
									end
								end
							2:  begin
									c_write_io_write_req = 1;
									if (io_cpu_addr_ack) begin
										write_done = 1;
										c_free = 1;
									end
								end
							default: 
								begin
									c_free = 'bx;
									c_io_state = 'bx;
									write_done = 'bx;
								end
							endcase
						end else begin
							if (r_waiting_hazard) begin
								c_waiting_hazard = c_hazard != 0;
							end 
							if (!r_waiting_line_busy)
							if (r_cache_miss) begin		// waiting for cache line fetch
								c_load_acked = 0;
								if (mem_read_done) begin
									c_cache_miss = 0;
									c_waiting_memory = 0;
									c_load_ready = 1;
									c_load_acked = r_load_acked|load_ack;
								end
							end else
							if (r_load_acked) begin	// waiting for load unit
								if (load_ack_fail) begin		// cache miss do a write
									c_load_acked = 0;
									c_cache_miss = 1;
									c_cache_invalidate = 0;
									c_acked = 0;
								end else begin
									do_write_amo = 1;
									if (!write_ok_write && write_ack) begin		// cache miss do an update
										c_load_acked = 0;
										c_cache_miss = 1;
										c_cache_invalidate = write_must_invalidate;
										c_acked = 0;
									end else begin
										write_done = 1;
									end
								end
							end else begin
								c_load_ready = !c_waiting_hazard;
								c_load_acked = r_load_acked|load_ack;
							end
							c_free = write_ack && (r_commit|((commit)&r_valid)) && !c_cache_miss;
						end
					end
				5'b???1?:		// fence
					begin
						c_killed = r_killed || (killed);
						if (r_killed || (killed)) begin
							c_free = r_valid;
						end else
						if (r_control[2:0] < 3) begin
							c_free = completed && r_valid && c_hazard == 0;
						end else begin
                            c_load_acked = r_load_acked|load_ack;
                            c_load_ready = r_control[2:0]!= 4;
                            c_store_cond = r_control[2:0]!= 4;
                            c_free = (r_commit|((commit)&r_valid)) && c_hazard == 0;
						end
					end 
				5'b????1:		// load
					begin
						//
						//	load states
						//
						//	waiting for store hazard to clear	c_hazard!=0 -> then retry load
						//
						//	waiting for line_hit (we got a cache miss and there's a load or store
						//		ahead of us in the queue to the same line) -> then retry load
						//
						//	waiting for load-retry  (we retried the load in the previous clock,
						//		did we get a cache hit?) -> either done or we got a new line_hit
						//		and wait or we start a memory load load
						//
						//	waiting for mem load -> then retry load
						//	
						//
						c_killed = r_killed|killed;
						c_load_acked = r_load_acked|load_ack;
						c_last_load_acked = load_ack;
						if (r_io) begin
							if (commitable) begin 
								case (r_io_state ) // synthesis full_case parallel_case
								0:	begin
										c_write_io_read_req = 1;
										if (io_cpu_addr_ack) begin
											c_io_state = 1;
										end
									end
								1:  begin
										if (io_cpu_data_req) begin
											c_load_ready = 1;
											if (load_ack) begin
												c_io_state = 2;
											end
										end
									end
								2:	begin
										c_write_io_data_ack = 1;
										c_free = 1;
										c_killed = 1;
									end
								default: 
									begin
										c_write_io_data_ack = 'bx;
										c_free = 'bx;
										c_killed = 'bx;
										c_io_state = 'bx;
									end
								endcase
							end
						end else begin
							casez ({r_last_load_acked, r_waiting_hazard, r_waiting_line_busy, r_waiting_memory, r_ack_waiting, r_send_cancel}) // synthesis full_case parallel_case
							6'b1?????:begin
										if (!load_ack_fail) begin
											c_killed = 1;
										end else
										if (!r_waiting_line_busy) begin
											c_cache_miss = 1;
											c_waiting_memory = !(killed||r_killed);
											c_acked = 0;
										end
									end
							6'b01????:begin
										if (c_hazard == 0) begin
											c_waiting_hazard = 0;
											if (r_waiting_line_busy) begin
												if (!c_waiting_line_busy) begin
													c_load_ready = 1;
												end
											end else
											if (r_cache_miss && r_amo[0]) begin
												c_cache_miss = !(killed||r_killed);
												c_waiting_memory = !(killed||r_killed);
												c_acked = 0;
											end else begin
												c_load_ready = !(killed||r_killed);
											end
										end 
									end
							6'b001???:begin
										if (killed||r_killed)
											c_cache_miss = 0;
										if (!c_waiting_line_busy) begin
											if (r_cache_miss && r_amo[0]) begin
                                                c_cache_miss = !(killed||r_killed);
                                                c_waiting_memory = !(killed||r_killed);
                                                c_acked = 0;
                                            end else begin
												c_load_ready = !(killed||r_killed);
											end
										end
									end
							6'b0001??:begin
										if (killed||r_killed) begin
											if (!c_acked) begin
												c_waiting_memory = 0;
											end else begin
												c_waiting_memory = 0;
												c_send_cancel = 1;
												c_acked = 0;
											end
										end else
										if (c_waiting_line_busy) begin
											c_waiting_memory = 0;
										end else
										if (mem_read_done) begin
											c_load_ready = 1;
											c_waiting_memory = 0;
										end
									end
							6'b00001?:begin
										c_load_ready = 1;
									end
							6'b000001:begin
										c_send_cancel = !c_acked;
									end
							default:	;
							endcase
							c_free = (((r_commit|((commit)&r_valid)) && !c_cache_miss && !c_send_cancel) || (r_send_cancel&&c_acked));
						end
					end
				endcase
			end
		end
	//	if (free_out) begin
	//		c_valid = 0;
	//		c_commit = 0;
	//		c_killed = 0;
	//	end
	end
	assign c_ack_waiting = c_load_ready & !load_ack;
	

	always @(posedge clk) begin
		r_tlb_invalidate <= !reset&&(tlb_invalidate||r_tlb_invalidate)&&r_valid;
		r_tlb_inv_type <= c_tlb_inv_type;
		r_ack_waiting <= c_ack_waiting;
		r_do_write_sc <= c_do_write_sc;
		r_commit <= c_commit&&!write_done&&!free_out;
		r_store_cond <= c_store_cond;
		r_store_cond_okv <= c_store_cond_okv;
		r_cache_miss <= c_cache_miss;
		r_addr <= c_addr;
		r_io <= c_io;
		r_data <= c_data;
		r_mask <= c_mask;
		r_valid <= c_valid&!free_out;
		r_hart <= c_hart;
		r_control <= c_control;
		r_amo <= c_amo;
		r_rd <= c_rd;
`ifdef FP
		r_fp <= c_fp;
`endif
		r_aq_rl <= c_aq_rl;
		r_fd <= c_fd;
		r_killed <= (c_killed&&!free_out)||(r_commit&&write_done);
		r_free <= c_free&c_valid;
		r_hazard <= c_hazard;
		r_makes_rd <= c_makes_rd && !(killed|c_killed);
		r_load <= c_load;
		r_fence <= c_fence;
		r_store <= c_store;
		r_load_acked <= c_load_acked;
		r_last_load_acked <= c_last_load_acked;
		r_acked <= c_acked;
		r_cache_invalidate <= c_cache_invalidate;
		r_waiting_memory <= !reset&&c_waiting_memory && !(allocate&&line_busy&&!fence);
		r_waiting_line_busy <= c_waiting_line_busy;
		r_waiting_line_index <= c_waiting_line_index;
		r_waiting_hazard <= c_waiting_hazard;
		r_io_state <= c_io_state;
		r_send_cancel <= c_send_cancel;
	end

`ifdef AWS_DEBUG
`ifdef NOTDEF
    vio_ldstq(.clk(clk),
            .allocate(allocate),
            .valid(r_valid),
            .addr(r_addr[23:0]),
            .load(r_load),
            .store(r_store),
            .io(r_io),
            .amo(r_amo[2:0]),
			.rd(r_rd),
            .load_acked(r_load_acked),
            .load_ready(load_ready),
            .load_state({r_last_load_acked, r_waiting_hazard, r_waiting_line_busy, r_waiting_memory, r_ack_waiting, r_send_cancel}),
            .p0(1'b0),
            .p1(1'b0),
            .p2(1'b0),
            .p3(1'b0),
            .p4(1'b0),
            .p5(1'b0));
`endif
	ila_ldstq(.clk(clk),
			.reset(reset),
			.xxtrig(xxtrig),
			.allocate(allocate),
			.valid(r_valid),
			.r_rd(r_rd),	// 5
			.r_load(r_load),
			.r_store(r_store),
			.r_io(r_io),
			.r_last_load_acked(r_last_load_acked),
			.r_waiting_hazard(r_waiting_hazard),
			.r_waiting_line_busy(r_waiting_line_busy),
			.r_waiting_memory(r_waiting_memory),
			.r_ack_waiting(r_ack_waiting),
			.r_send_cancel(r_send_cancel),
            .all_active(all_active), // 8
			.all_store_mem(all_store_mem),// 8
			.mem_read_req(mem_read_req),
			.mem_read_cancel(mem_read_cancel),
			.mem_ack(mem_ack),
			.mem_read_done(mem_read_done),
			.load_ready(load_ready),
			.load_ack(load_ack),
			.load_ack_fail(load_ack_fail),
            .r_load_acked(r_load_acked),
            .r_store_cond(r_store_cond),
            .r_store_cond_okv(r_store_cond_okv),
            .write_mem(write_mem),
            .write_wait(write_wait),
            .write_ok_write(write_ok_write),
            .write_must_invalidate(write_must_invalidate),
            .r_do_write_sc(r_do_write_sc),
            .r_control(r_control),  // 3
            .r_fence(r_fence),
			.c_cache_miss(c_cache_miss),
			.killed(killed),
			.r_killed(r_killed),
			.c_free(c_free),
			.c_commit(c_commit),
			.makes_rd(makes_rd),
			.r_makes_rd(r_makes_rd),
			.c_killed(c_killed),
			.completed(completed),
			.commitable(commitable),
            .lr_valid(lr_valid),
            .c_store_cond_okv(c_store_cond_okv),
            .c_store_cond(c_store_cond));


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
