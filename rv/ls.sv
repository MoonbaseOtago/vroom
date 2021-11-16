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

	input 		      load_enable_0,
	input [CNTRL_SIZE-1:0]load_control_0,
	input     [LNCOMMIT-1:0]load_rd_0,
	input	          load_makes_rd_0,
	input     [RV-1:0]load_r1_0,
	input       [31:0]load_immed_0,
	input	[(NHART==1?0:LNHART-1):0]load_hart_0,
	output    [RV-1:0]load_result_0,
	output [LNCOMMIT-1:0]load_res_rd_0, 
`ifdef FP
	output				load_res_fp_0,
`endif
	output [NHART-1:0]load_res_makes_rd_0,

	output		load_done_0,
	output	[LNCOMMIT-1:0]load_done_commit_0,
	output	[(NHART==1?0:LNHART-1):0]load_done_hart_0,
	output	[ 1: 0]load_trap_type_0,	// 0 for no trap, 1 align, 2 access, 3 page
	output		load_pending_0,
	//
	//	when an access takes a TLB miss  we need to pause subsequent ones, 'stalled'
	//		accesses are currently doing TLB misses, or queued for TLB misses
	//		'paused' ones are retrying back to the scheduler waiting for the 
	//		'stalled' accesses to complete
	//
	output		load_vm_stall_0,
	output		load_vm_pause_0,
	

	input 		      load_enable_1,
	input [CNTRL_SIZE-1:0]load_control_1,
	input     [LNCOMMIT-1:0]load_rd_1,
	input	          load_makes_rd_1,
	input [RV-1:0]load_r1_1,
	input [31:0]load_immed_1,
	input	[(NHART==1?0:LNHART-1):0]load_hart_1,
	output [RV-1:0]load_result_1,
	output [LNCOMMIT-1:0]load_res_rd_1, 
`ifdef FP
	output				load_res_fp_1,
`endif
	output [NHART-1:0]load_res_makes_rd_1,

	output		load_done_1,
	output	[LNCOMMIT-1:0]load_done_commit_1,
	output	[(NHART==1?0:LNHART-1):0]load_done_hart_1,
	output	[ 1: 0]load_trap_type_1,	// 0 for no trap
	output		load_pending_1,
	output		load_vm_stall_1,
	output		load_vm_pause_1,

//	input 		      load_enable_2,
//	input [CNTRL_SIZE-1:0]load_control_2,
//	input     [LNCOMMIT-1:0]load_rd_2,
//	input	          load_makes_rd_2,
//	input [RV-1:0]load_r1_2,
//	input [31:0]load_immed_2,
//	input	[(NHART==1?0:LNHART-1):0]load_hart_2,
//	output [RV-1:0]load_result_2,
//	output [LNCOMMIT-1:0]load_res_rd_2, 
`ifdef FP
//	output				load_res_fp_2,
`endif
//	output [NHART-1:0]load_res_makes_rd_2,

//	output		load_done_2,
//	output	[LNCOMMIT-1:0]load_done_commit_2,
//	output	[(NHART==1?0:LNHART-1):0]load_done_hart_2,
//	output	[ 1: 0]load_trap_type_2,	// 0 for no trap, 1 align, 2 access, 3 page
//	output		load_pending_2,
//	output		load_vm_stall_2,
//	output		load_vm_pause_2,

	input 	[NCOMMIT-1:0]store_commit_0,	// one per HART
	input 	[NCOMMIT-1:0]commit_kill_0,		// one per HART
	input 	[NCOMMIT-1:0]commit_completed_0,	// one per HART
	input 	[NCOMMIT-1:0]commit_commitable_0,	// one per HART
	//input 	[NCOMMIT-1:0]store_commit_1,	// one per HART
	//input 	[NCOMMIT-1:0]commit_kill_1,		// one per HART
	//input 	[NCOMMIT-1:0]commit_completed_1,	// one per HART
	//input 	[NCOMMIT-1:0]commit_commitable_1,// one per HART

	input 		      store_enable_0,
	input   [LNCOMMIT-1:0]store_rd_0,
	input [CNTRL_SIZE-1:0]store_control_0,
	input [RV-1:0]store_r1_0, store_r2_0,
`ifdef FP
	input [RV-1:0]store_r2_fp_0,
`endif
	input [31:0]store_immed_0,
	input	[(NHART==1?0:LNHART-1):0]store_hart_0,
	input	store_makes_rd_0,

	output			store_running_0,
	output	[ 1: 0]store_running_trap_type_0,	// 0 for no trap, 1 align, 2 access, 3 page
	output [(NHART==1?0:LNHART-1):0]store_running_hart_0,
	output	[LNCOMMIT-1:0]store_running_commit_0,
	output			store_vm_stall_0,
	output			store_vm_pause_0,


`ifdef NSTORE2
	input 		      store_enable_1,
	input   [LNCOMMIT-1:0]store_rd_1,
	input [CNTRL_SIZE-1:0]store_control_1,
	input [RV-1:0]store_r1_1, store_r2_1,
`ifdef FP
	input [RV-1:0]store_r2_fp_1,
`endif
	input [31:0]store_immed_1,
	input	[(NHART==1?0:LNHART-1):0]store_hart_1,
	input	store_makes_rd_1,

	output			store_running_1,
	output	[ 1: 0]store_running_trap_type_1,	// 0 for no trap, 1 align, 2 access, 3 page
	output [(NHART==1?0:LNHART-1):0]store_running_hart_1,
	output	[LNCOMMIT-1:0]store_running_commit_1,
	output			store_vm_stall_1,
	output			store_vm_pause_1,
`endif

	output			vm_done,
	output			vm_done_fail,
	output			vm_done_pmp,
	output	 [(NHART==1?0:LNHART-1):0]vm_done_hart,
	output	 [LNCOMMIT-1:0]vm_done_commit,
	output	[NHART-1:0]vm_busy,


	output [$clog2(NLDSTQ):0]num_ldstq_available,	// number of slots

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

	input [NUM_PMP-1:0]pmp_valid_0,		// sadly arrays of buses aren't well supported 
	input [NUM_PMP-1:0]pmp_locked_0,	// so we need to get verbose - unused wires will be optimised
	input [NPHYS-1:2]pmp_start_0_0,		// out during synthesis
	input [NPHYS-1:2]pmp_start_1_0,
	input [NPHYS-1:2]pmp_start_2_0,
	input [NPHYS-1:2]pmp_start_3_0,
	input [NPHYS-1:2]pmp_start_4_0,
	input [NPHYS-1:2]pmp_start_5_0,
	input [NPHYS-1:2]pmp_start_6_0,
	input [NPHYS-1:2]pmp_start_7_0,
	input [NPHYS-1:2]pmp_start_8_0,
	input [NPHYS-1:2]pmp_start_9_0,
	input [NPHYS-1:2]pmp_start_10_0,
	input [NPHYS-1:2]pmp_start_11_0,
	input [NPHYS-1:2]pmp_start_12_0,
	input [NPHYS-1:2]pmp_start_13_0,
	input [NPHYS-1:2]pmp_start_14_0,
	input [NPHYS-1:2]pmp_start_15_0,
	input [NPHYS-1:2]pmp_end_0_0,
	input [NPHYS-1:2]pmp_end_1_0,
	input [NPHYS-1:2]pmp_end_2_0,
	input [NPHYS-1:2]pmp_end_3_0,
	input [NPHYS-1:2]pmp_end_4_0,
	input [NPHYS-1:2]pmp_end_5_0,
	input [NPHYS-1:2]pmp_end_6_0,
	input [NPHYS-1:2]pmp_end_7_0,
	input [NPHYS-1:2]pmp_end_8_0,
	input [NPHYS-1:2]pmp_end_9_0,
	input [NPHYS-1:2]pmp_end_10_0,
	input [NPHYS-1:2]pmp_end_11_0,
	input [NPHYS-1:2]pmp_end_12_0,
	input [NPHYS-1:2]pmp_end_13_0,
	input [NPHYS-1:2]pmp_end_14_0,
	input [NPHYS-1:2]pmp_end_15_0,
	input	[2:0]pmp_prot_0_0,
	input	[2:0]pmp_prot_1_0,
	input	[2:0]pmp_prot_2_0,
	input	[2:0]pmp_prot_3_0,
	input	[2:0]pmp_prot_4_0,
	input	[2:0]pmp_prot_5_0,
	input	[2:0]pmp_prot_6_0,
	input	[2:0]pmp_prot_7_0,
	input	[2:0]pmp_prot_8_0,
	input	[2:0]pmp_prot_9_0,
	input	[2:0]pmp_prot_10_0,
	input	[2:0]pmp_prot_11_0,
	input	[2:0]pmp_prot_12_0,
	input	[2:0]pmp_prot_13_0,
	input	[2:0]pmp_prot_14_0,
	input	[2:0]pmp_prot_15_0,
	input [NUM_PMP-1:0]pmp_valid_1,		
	input [NUM_PMP-1:0]pmp_locked_1,
	input [NPHYS-1:2]pmp_start_0_1,
	input [NPHYS-1:2]pmp_start_1_1,
	input [NPHYS-1:2]pmp_start_2_1,
	input [NPHYS-1:2]pmp_start_3_1,
	input [NPHYS-1:2]pmp_start_4_1,
	input [NPHYS-1:2]pmp_start_5_1,
	input [NPHYS-1:2]pmp_start_6_1,
	input [NPHYS-1:2]pmp_start_7_1,
	input [NPHYS-1:2]pmp_start_8_1,
	input [NPHYS-1:2]pmp_start_9_1,
	input [NPHYS-1:2]pmp_start_10_1,
	input [NPHYS-1:2]pmp_start_11_1,
	input [NPHYS-1:2]pmp_start_12_1,
	input [NPHYS-1:2]pmp_start_13_1,
	input [NPHYS-1:2]pmp_start_14_1,
	input [NPHYS-1:2]pmp_start_15_1,
	input [NPHYS-1:2]pmp_end_0_1,
	input [NPHYS-1:2]pmp_end_1_1,
	input [NPHYS-1:2]pmp_end_2_1,
	input [NPHYS-1:2]pmp_end_3_1,
	input [NPHYS-1:2]pmp_end_4_1,
	input [NPHYS-1:2]pmp_end_5_1,
	input [NPHYS-1:2]pmp_end_6_1,
	input [NPHYS-1:2]pmp_end_7_1,
	input [NPHYS-1:2]pmp_end_8_1,
	input [NPHYS-1:2]pmp_end_9_1,
	input [NPHYS-1:2]pmp_end_10_1,
	input [NPHYS-1:2]pmp_end_11_1,
	input [NPHYS-1:2]pmp_end_12_1,
	input [NPHYS-1:2]pmp_end_13_1,
	input [NPHYS-1:2]pmp_end_14_1,
	input [NPHYS-1:2]pmp_end_15_1,
	input	[2:0]pmp_prot_0_1,
	input	[2:0]pmp_prot_1_1,
	input	[2:0]pmp_prot_2_1,
	input	[2:0]pmp_prot_3_1,
	input	[2:0]pmp_prot_4_1,
	input	[2:0]pmp_prot_5_1,
	input	[2:0]pmp_prot_6_1,
	input	[2:0]pmp_prot_7_1,
	input	[2:0]pmp_prot_8_1,
	input	[2:0]pmp_prot_9_1,
	input	[2:0]pmp_prot_10_1,
	input	[2:0]pmp_prot_11_1,
	input	[2:0]pmp_prot_12_1,
	input	[2:0]pmp_prot_13_1,
	input	[2:0]pmp_prot_14_1,
	input	[2:0]pmp_prot_15_1,

	output    [15:0]tlb_d_asid,              // d$ read port
    output[(NHART==1?0:LNHART-1):0]tlb_d_hart,
    output [VA_SZ-1:12]tlb_d_vaddr,
	output[LNCOMMIT-1:0]tlb_d_addr_tid,
    output        tlb_d_addr_req,
    input         tlb_d_addr_ack,
    output        tlb_d_addr_cancel,

    input         tlb_d_data_req,          // d$ response
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
	parameter NLOAD=2;
	parameter NSTORE=1;
	parameter NLDSTQ=4;
	parameter NPHYS=56;
	parameter VA_SZ=48;
	parameter TRANS_ID_SIZE=6;
	parameter CACHE_LINE_SIZE=64*8;
	parameter ACACHE_LINE_SIZE=6;
	parameter CACHE_ADDR=$clog2(CACHE_LINE_SIZE/8);

`include "cache_protocol.si"
	// these 'i' (for 'internal') wires are simply to repack inputs into arrays so we can use
	//		generates below
	wire [RV-1:0]iload_r1[0:NLOAD-1];
	assign iload_r1[0] = load_r1_0;
	assign iload_r1[1] = load_r1_1;
	wire [LNCOMMIT-1:0]iload_rd[0:NLOAD-1];
	assign iload_rd[0] = load_rd_0;
	assign iload_rd[1] = load_rd_1;
	wire  [NLOAD-1:0]iload_makes_rd;
	assign iload_makes_rd[0] = load_makes_rd_0;
	assign iload_makes_rd[1] = load_makes_rd_1;
	wire [CNTRL_SIZE-1:0]iload_control[0:NLOAD-1];
	assign iload_control[0] = load_control_0;
	assign iload_control[1] = load_control_1;
	wire [31:0]iload_immed[0:NLOAD-1];
	assign iload_immed[0] = load_immed_0;
	assign iload_immed[1] = load_immed_1;
	wire [(NHART==1?0:LNHART-1):0]iload_hart[0:NLOAD-1];
	assign iload_hart[0] = load_hart_0;
	assign iload_hart[1] = load_hart_1;
	wire  [NLOAD-1:0]iload_enable;
	assign iload_enable[0] = load_enable_0;
	assign iload_enable[1] = load_enable_1;

	wire [RV-1:0]istore_r1[0:NSTORE-1];
	assign istore_r1[0] = store_r1_0;
	wire [RV-1:0]istore_r2[0:NSTORE-1];
	assign istore_r2[0] = store_r2_0;
`ifdef FP
	wire [RV-1:0]istore_r2_fp[0:NSTORE-1];
	assign istore_r2_fp[0] = store_r2_fp_0;
`endif
	wire [CNTRL_SIZE-1:0]istore_control[0:NSTORE-1];
	assign istore_control[0] = store_control_0;
	wire [31:0]istore_immed[0:NSTORE-1];
	assign istore_immed[0] = store_immed_0;
	wire [(NHART==1?0:LNHART-1):0]istore_hart[0:NSTORE-1];
	assign istore_hart[0] = store_hart_0;
	wire [LNCOMMIT-1:0]istore_rd[0:NSTORE-1];
	assign istore_rd[0] = store_rd_0;
	wire  [NSTORE-1:0]istore_enable;
	assign istore_enable[0] = store_enable_0;
	wire  [NSTORE-1:0]istore_makes_rd;
	assign istore_makes_rd[0] = store_makes_rd_0;
`ifdef NSTORE2
	assign istore_r1[1] = store_r1_1;
	assign istore_r2[1] = store_r2_1;
`ifdef FP
	assign istore_r2_fp[1] = store_r2_fp_1;
`endif
	assign istore_control[1] = store_control_1;
	assign istore_immed[1] = store_immed_1;
	assign istore_hart[1] = store_hart_1;
	assign istore_rd[1] = store_rd_1;
	assign istore_enable[1] = store_enable_1;
	assign istore_makes_rd[1] = store_makes_rd_1;
`endif

	reg 	[NLOAD-1:0]r_load_vm_stall, c_load_vm_stall;
	reg 	[NLOAD-1:0]r_load_vm_pause, c_load_vm_pause;
	assign load_vm_stall_0 = r_load_vm_stall[0];
	assign load_vm_stall_1 = r_load_vm_stall[1];
	//assign load_vm_stall_2 = r_load_vm_stall[2];
	assign load_vm_pause_0 = r_load_vm_pause[0];
	assign load_vm_pause_1 = r_load_vm_pause[1];
	//assign load_vm_pause_2 = r_load_vm_pause[2];

	reg 	[NSTORE-1:0]r_store_vm_stall, c_store_vm_stall;
	reg 	[NSTORE-1:0]r_store_vm_pause, c_store_vm_pause;
	assign store_vm_stall_0 = r_store_vm_stall[0];
	assign store_vm_pause_0 = r_store_vm_pause[0];
`ifdef NSTORE2
	assign store_vm_stall_1 = r_store_vm_stall[1];
	assign store_vm_pause_1 = r_store_vm_pause[1];
`endif

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
	//				30: pi
	//				29: po
	//				28: pr
	//				27: pw
	//				26: si
	//				25: so
	//				24: sr
	//				23: sw


	reg [31:0]r_load_immed[0:NLOAD-1];
	reg	[(NHART==1?0:LNHART-1):0]r_load_hart[0:NLOAD-1];
	reg [CNTRL_SIZE-1:0]r_load_control[0:NLOAD-1];
	reg [1:0]r_load_aq_rl[0:NLOAD-1];
wire [CNTRL_SIZE-1:0]r_load_control_0=r_load_control[0];
	reg [LNCOMMIT-1:0]r_load_rd[0:NLOAD-1];
`ifdef FP
	reg [NLOAD-1:0]r_load_fp;
`endif
	reg	[NLOAD-1:0]r_load_makes_rd;
	reg	[NLOAD-1:0]r_load_amo;
	reg [NLOAD-1:0]r_load_state;
	reg [NLOAD-1:0]load_killed;


	reg	[NLOAD-1:0]r_load_done;
	assign load_done_0 = r_load_done[0];
	assign load_done_1 = r_load_done[1];
	reg [1:0]r_load_trap_type[0:NLOAD-1], c_load_trap_type[0:NLOAD-1];
wire [1:0]c_load_trap_type_0=c_load_trap_type[0];
	assign load_trap_type_0 = r_load_trap_type[0];
	assign load_trap_type_1 = r_load_trap_type[1];
	reg  [LNCOMMIT-1:0]r_load_done_commit[0:NLOAD-1];
	assign load_done_commit_0 = r_load_done_commit[0];
	assign load_done_commit_1 = r_load_done_commit[1];
	assign load_done_hart_0 = 0;
	assign load_done_hart_1 = 0;
	reg	[RV-1:0]r_res[0:NLOAD-1];
	assign load_result_0=r_res[0];
	assign load_result_1=r_res[1];
	assign load_res_rd_0=r_load_done_commit[0];
	assign load_res_rd_1=r_load_done_commit[1];
`ifdef FP
	reg  [NLOAD-1:0]r_load_fp_commit;
	assign load_res_fp_0 = r_load_fp_commit[0];
	assign load_res_fp_1 = r_load_fp_commit[1];
//	assign load_done_fp_2 = r_load_fp_commit[2];
`endif
	reg	[NHART-1:0]r_res_makes_rd[0:NLOAD-1];
	reg	[NHART-1:0]c_res_makes_rd[0:NLOAD-1];
	assign load_res_makes_rd_0=r_res_makes_rd[0];
	assign load_res_makes_rd_1=r_res_makes_rd[1];

	wire [NLDSTQ-1:0]load_snoop_hit[0:NLOAD-1];
wire [NLDSTQ-1:0]load_snoop_hit_0=load_snoop_hit[0];
wire [NLDSTQ-1:0]load_snoop_hit_1=load_snoop_hit[1];
	wire [NLDSTQ-1:0]load_snoop_hazard[0:NLOAD-1];
wire [NLDSTQ-1:0]load_snoop_hazard0=load_snoop_hazard[0];
wire [NLDSTQ-1:0]load_snoop_hazard1=load_snoop_hazard[1];
	wire [NLDSTQ-1:0]load_snoop_line_hit[0:NLOAD-1];
	reg [RV-1:0]load_snoop[0:NLOAD-1];
	reg	[NLOAD-1:0]load_hazard;
	reg [RV/8-1:0]c_load_mask[0:NLOAD-1];
	reg	[NLOAD-1:0]c_load_alignment_bad;
	reg [RV-1:0]c_load_vaddr[0:NLOAD-1];
wire [RV-1:0]c_load_vaddr_0=c_load_vaddr[0];
	reg [NPHYS-1:0]c_load_paddr[0:NLOAD-1];
wire [NPHYS-1:0]c_load_paddr_0=c_load_paddr[0];
	reg [NLOAD-1:0]r_load_io, c_load_io;
	reg  [NLOAD-1:0]c_load_allocate;
	reg  [NLOAD-1:0]r_load_pending;
	reg  [3:0]rd_prot[0:NLOAD-1];
wire [3:0]rd_prot_0=rd_prot[0];
	reg  [NLOAD-1:0]rd_addr_ok;
	assign load_pending_0 = r_load_pending[0];
	assign load_pending_1 = r_load_pending[1];
    reg  [$clog2(NLDSTQ)-1:0]r_load_ack_entry[0:NLOAD-1];
	reg [NLOAD-1:0]r_load_page_fault;

	wire [ 3: 0]rd_cpu_mode[0:NLOAD-1];
	wire [ 3: 0]rd_mprv[0:NLOAD-1];
wire [ 3: 0]rd_cpu_mode_0=rd_cpu_mode[0];
	wire [ 3: 0]rd_sup_vm_mode[0:NLOAD-1];
wire [ 3: 0]rd_sup_vm_mode_0=rd_sup_vm_mode[0];
	wire [15: 0]rd_sup_asid[0:NLOAD-1];
	wire [NLOAD-1:0]rd_sup_vm_sum;
	wire [NLOAD-1:0]rd_mxr;

	wire [ 3: 0]wr_cpu_mode[0:NSTORE-1];
	wire [ 3: 0]wr_mprv[0:NSTORE-1];
wire [ 3: 0]wr_cpu_mode_0=wr_cpu_mode[0];
	wire [ 3: 0]wr_sup_vm_mode[0:NSTORE-1];
wire [ 3: 0]wr_sup_vm_mode_0=wr_sup_vm_mode[0];
	wire [15: 0]wr_sup_asid[0:NSTORE-1];
wire [15: 0]wr_sup_asid_0=wr_sup_asid[0];
	wire  [NSTORE-1:0]wr_sup_vm_sum;


	reg [NLOAD-1:0]r_load_queued;
	reg [NLOAD-1:0]c_load_queued_ready;
	reg [NLOAD-1:0]r_load_sc;
	reg [NLOAD-1:0]r_load_sc_okv;
    reg  [$clog2(NLDSTQ)-1:0]c_load_queued_index[0:NLOAD-1];
wire [$clog2(NLDSTQ)-1:0]c_load_queued_index_0=c_load_queued_index[0];
wire [$clog2(NLDSTQ)-1:0]c_load_queued_index_1=c_load_queued_index[1];

	wire [NLDSTQ-1:0]free;
	wire [NLDSTQ-1:0]load_ready;
	wire [NLDSTQ-1:0]store_mem;	// write strobe

	wire [NPHYS-1:0]write_mem_addr[0:NLDSTQ-1];
	wire [NLDSTQ-1:0]write_mem_io;
	wire [RV-1:0]write_mem_data[0:NLDSTQ-1];
	wire [(RV/8)-1:0]write_mem_mask[0:NLDSTQ-1];
	reg  [5:0]write_mem_amo[0:NLDSTQ-1];
wire [5:0]write_mem_amo_1 = write_mem_amo[1];
	wire [(NHART==1?0:LNHART-1):0]write_mem_hart[0:NLDSTQ-1];
	wire [NLDSTQ-1:0]write_mem_sc;
	wire [NLDSTQ-1:0]write_mem_sc_okv;
	reg [NPHYS-1:(RV==64?3:2)]q_mem_addr;
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

	reg [(RV/8)-1:0]c_store_mask[0:NSTORE-1];
	reg	[NSTORE-1:0]c_store_alignment_bad;
	reg [RV-1:0]c_store_vaddr[0:NSTORE-1];
	reg [NPHYS-1:0]c_store_paddr[0:NSTORE-1];
	reg [NSTORE-1:0]c_store_io;
	reg [RV-1:0]c_store_data[0:NSTORE-1];
	reg	[NSTORE-1:0]c_store_allocate;
	reg	[NSTORE-1:0]c_store_fence;
	reg [NSTORE-1:0]r_store_state, c_store_state;
	reg [31:0]r_store_immed[0:NSTORE-1];
	reg [4:0]r_store_amo[0:NSTORE-1];
	reg [LNCOMMIT-1:0]r_store_rd[0:NSTORE-1], c_store_rd[0:NSTORE-1];
	reg [LNCOMMIT-1:0]r_store_rd2[0:NSTORE-1];
	reg [NSTORE-1:0]r_store_makes_rd, c_store_makes_rd;
	wire [NLDSTQ-1:0]store_snoop_line_hit[0:NSTORE-1];
	reg  [3:0]wr_prot[0:NSTORE-1];
wire  [3:0]wr_prot_0 = wr_prot[0];
	reg  [NSTORE-1:0]wr_addr_ok;
	reg [NSTORE-1:0]store_killed;

	assign	store_running_commit_0=r_store_rd2[0];
	reg [CNTRL_SIZE-1:0]r_store_control[0:NSTORE-1];
wire [CNTRL_SIZE-1:0]r_store_control_0=r_store_control[0];
	reg [1:0]r_store_aq_rl[0:NSTORE-1];
	reg [1:0]r_store_fd[0:NSTORE-1];
	reg	[(NHART==1?0:LNHART-1):0]r_store_hart[0:NSTORE-1], r_store_hart2[0:NSTORE-1];
wire [(NHART==1?0:LNHART-1):0]r_store_hart_0=r_store_hart[0];
	assign	store_running_hart_0=r_store_hart2[0];
	reg		[NSTORE-1:0]r_store_running, c_store_running;
	assign store_running_0 = r_store_running[0];
	reg		[1:0]r_store_running_trap_type[0:NSTORE-1], c_store_running_trap_type[0:NSTORE-1]; // 0 for no trap, 1 align, 2 access, 3 page
	assign store_running_trap_type_0 = r_store_running_trap_type[0];
	
`ifdef NSTORE2
	assign	store_running_commit_1=r_store_rd2[1];
	assign	store_running_hart_1=r_store_hart2[1];
	assign store_running_1 = r_store_running[1];
	assign store_running_trap_type_1 = r_store_running_trap_type[1];
`endif
	

	wire [NLOAD+NSTORE-1:0]tlb_rd_enable;
    wire [VA_SZ-1:12]tlb_rd_vaddr[0:NLOAD+NSTORE-1];       // read path
    wire [15:0]tlb_rd_asid[0:NLOAD+NSTORE-1];       
wire [15:0]tlb_rd_asid_2=tlb_rd_asid[2];
    wire [NLOAD+NSTORE-1:0]tlb_rd_valid;
    wire [NLOAD+NSTORE-1:0]tlb_rd_2mB;
    wire [NLOAD+NSTORE-1:0]tlb_rd_4mB;
    wire [NLOAD+NSTORE-1:0]tlb_rd_1gB;
    wire [NLOAD+NSTORE-1:0]tlb_rd_512gB;
    wire [NPHYS-1:12]tlb_rd_paddr[0:NLOAD+NSTORE-1];
wire [NPHYS-1:12]tlb_rd_paddr_0=tlb_rd_paddr[0];
wire [NPHYS-1:12]tlb_rd_paddr_2=tlb_rd_paddr[2];
    wire [5: 0]tlb_rd_aduwrx[0:NLOAD+NSTORE-1];
wire [5: 0]tlb_rd_aduwrx_0=tlb_rd_aduwrx[0];
wire [5: 0]tlb_rd_aduwrx_2=tlb_rd_aduwrx[2];

    wire [VA_SZ-1:12]tlb_wr_vaddr;     // write path
    wire   [15:0]tlb_wr_asid;
    wire   [(NHART==1?0:LNHART-1):0]tlb_wr_hart;

	reg [NPHYS-1:(RV==64?3:2)]dc_rd_addr[0:NLOAD-1]; // CPU read port
    wire	[NLOAD-1:0]dc_rd_hit;
    wire	[NLOAD-1:0]dc_rd_hit_need_o;
    wire [RV-1:0]dc_rd_data[0:NLOAD-1];
wire [RV-1:0]dc_rd_data_0=dc_rd_data[0];
	reg [(NHART==1?0:LNHART-1):0]dc_rd_hart[0:NLOAD-1];
	reg	 [NLOAD-1:0]dc_rd_lr;

	wire  [NSTORE-1:0]dc_wr_enable;             // CPU write port
    wire [NPHYS-1:(RV==64?3:2)]dc_wr_addr[0:NSTORE-1];
    wire [RV-1:0]dc_wr_data[0:NSTORE-1];
    wire [(RV/8)-1:0]dc_wr_mask[0:NSTORE-1];
    wire [(NHART==1?0:LNHART-1):0]dc_wr_hart[0:NSTORE-1];
    wire [5:0]dc_wr_amo[0:NSTORE-1];
    wire  [NSTORE-1:0]dc_wr_sc;
    wire  [NSTORE-1:0]dc_wr_hit_ok_write;			// write hit
    wire  [NSTORE-1:0]dc_wr_hit_must_invalidate;	// ??
    wire  [NSTORE-1:0]dc_wr_wait;					// write must wait

	reg [$clog2(NLDSTQ)-1:0]r_ldstq_in, r_ldstq_out;
	reg [$clog2(NLDSTQ):0]r_ldstq_available;
	wire [RV-1:0]load_snoop_data[0:NLDSTQ];
	wire [LNCOMMIT-1:0]wq_rd[0:NLDSTQ-1];
    wire [NLDSTQ-1:0]wq_new_active[0:NLDSTQ-1];
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

	assign num_ldstq_available=r_ldstq_available;
	always @(posedge clk) begin
		if (reset) begin
			r_ldstq_in <= 0;
			r_ldstq_available <= NLDSTQ;
			r_ldstq_out <= 0;
		end else
		if (|c_store_allocate || |c_load_allocate) begin
			r_ldstq_out <= r_ldstq_out+num_allocate;
			if (|free) begin
				r_ldstq_in <= r_ldstq_in+1;
				r_ldstq_available <= r_ldstq_available-num_allocate+1;
			end else begin
				r_ldstq_available <= r_ldstq_available-num_allocate;
			end
		end else
		if (|free) begin
			r_ldstq_in <= r_ldstq_in+1;
			r_ldstq_available <= r_ldstq_available+1;
		end
	end

	wire [NLOAD-1:0]rd_pmp_fail_h[0:NHART-1];
	wire [NSTORE-1:0]wr_pmp_fail_h[0:NHART-1];
	wire [NLOAD-1:0]rd_pmp_fail;
    wire [NSTORE-1:0]wr_pmp_fail;

	reg [NLOAD-1:0]x_load_killed;
	reg [NSTORE-1:0]x_store_killed;

	wire [NLOAD-1:0]h_load_vm_stall[0:NHART-1];
wire [NLOAD-1:0]h_load_vm_stall_0=h_load_vm_stall[0];
	wire [NSTORE-1:0]h_store_vm_stall[0:NHART-1];
wire [NLOAD-1:0]h_store_vm_stall_0=h_store_vm_stall[0];
	wire [NHART-1:0]hart_vm_pause;
	reg  [NHART-1:0]r_hart_vm_pause;

	always @(posedge clk)
	if (reset) begin
		r_hart_vm_pause <= 0;
	end else begin
		r_hart_vm_pause <= hart_vm_pause;
	end

	genvar I, L, S, H;
	generate

		for (H = 0; H < NHART; H=H+1) begin
			assign hart_vm_pause[H] = (|h_load_vm_stall[H]) || (|h_store_vm_stall[H]);
		end

		for (L = 0; L < NLOAD; L=L+1) begin: ld
			assign rd_cpu_mode[L] = cpu_mode[r_load_hart[L]];
			assign rd_mprv[L] = mprv[r_load_hart[L]];
			assign rd_sup_vm_mode[L] = sup_vm_mode[r_load_hart[L]];
			assign rd_sup_asid[L] = sup_asid[r_load_hart[L]];
			assign rd_sup_vm_sum[L] = sup_vm_sum[r_load_hart[L]];
			assign rd_mxr[L] = mxr[r_load_hart[L]];

			assign tlb_rd_asid[L] = rd_sup_asid[L];


			assign tlb_rd_enable[L] = r_load_state[L]&&!r_load_queued[L]&(!rd_mprv[L][3]);

			pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))pmp_check_0(
				.m(mprv_0[3]),
				.su(mprv_0[1]|mprv_0[0]),
				.mprv(1'b0),
				.addr(c_load_paddr[L][NPHYS-1:2]),
				.sz({1'b0,r_load_control[L][1:0]==3?1'b1:1'b0}),
				.check_x(cpu_mode_0[3]&&rd_mxr[L]),
				.check_r(1'b1),
				.check_w(1'b0),
				.fail(rd_pmp_fail_h[0][L]),

				.pmp_valid(pmp_valid_0),		// sadly arrays of buses aren't well supported 
				.pmp_locked(pmp_locked_0),	// so we need to get verbose - unused wires will be optimised
				.pmp_start_0(pmp_start_0_0),		// out during synthesis
				.pmp_start_1(pmp_start_1_0),
				.pmp_start_2(pmp_start_2_0),
				.pmp_start_3(pmp_start_3_0),
				.pmp_start_4(pmp_start_4_0),
				.pmp_start_5(pmp_start_5_0),
				.pmp_start_6(pmp_start_6_0),
				.pmp_start_7(pmp_start_7_0),
				.pmp_start_8(pmp_start_8_0),
				.pmp_start_9(pmp_start_9_0),
				.pmp_start_10(pmp_start_10_0),
				.pmp_start_11(pmp_start_11_0),
				.pmp_start_12(pmp_start_12_0),
				.pmp_start_13(pmp_start_13_0),
				.pmp_start_14(pmp_start_14_0),
				.pmp_start_15(pmp_start_15_0),
				.pmp_end_0(pmp_end_0_0),
				.pmp_end_1(pmp_end_1_0),
				.pmp_end_2(pmp_end_2_0),
				.pmp_end_3(pmp_end_3_0),
				.pmp_end_4(pmp_end_4_0),
				.pmp_end_5(pmp_end_5_0),
				.pmp_end_6(pmp_end_6_0),
				.pmp_end_7(pmp_end_7_0),
				.pmp_end_8(pmp_end_8_0),
				.pmp_end_9(pmp_end_9_0),
				.pmp_end_10(pmp_end_10_0),
				.pmp_end_11(pmp_end_11_0),
				.pmp_end_12(pmp_end_12_0),
				.pmp_end_13(pmp_end_13_0),
				.pmp_end_14(pmp_end_14_0),
				.pmp_end_15(pmp_end_15_0),
				.pmp_prot_0(pmp_prot_0_0),
				.pmp_prot_1(pmp_prot_1_0),
				.pmp_prot_2(pmp_prot_2_0),
				.pmp_prot_3(pmp_prot_3_0),
				.pmp_prot_4(pmp_prot_4_0),
				.pmp_prot_5(pmp_prot_5_0),
				.pmp_prot_6(pmp_prot_6_0),
				.pmp_prot_7(pmp_prot_7_0),
				.pmp_prot_8(pmp_prot_8_0),
				.pmp_prot_9(pmp_prot_9_0),
				.pmp_prot_10(pmp_prot_10_0),
				.pmp_prot_11(pmp_prot_11_0),
				.pmp_prot_12(pmp_prot_12_0),
				.pmp_prot_13(pmp_prot_13_0),
				.pmp_prot_14(pmp_prot_14_0),
				.pmp_prot_15(pmp_prot_15_0));
			
			if (NHART > 1) begin
				pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))pmp_check_1(
					.m(mprv_1[3]),
					.su(mprv_1[1]|mprv_1[0]),
					.mprv(1'b0),
					.addr(c_load_paddr[L][NPHYS-1:2]),
					.sz({1'b0,r_load_control[L][1:0]==3?1'b1:1'b0}),
					.check_x(cpu_mode_1[3]&&rd_mxr[L]),
					.check_r(1'b1),
					.check_w(1'b0),
					.fail(rd_pmp_fail_h[1][L]),
	
					.pmp_valid(pmp_valid_1),		// sadly arrays of buses aren't well supported 
					.pmp_locked(pmp_locked_1),	// so we need to get verbose - unused wires will be optimised
					.pmp_start_0(pmp_start_0_1),		// out during synthesis
					.pmp_start_1(pmp_start_1_1),
					.pmp_start_2(pmp_start_2_1),
					.pmp_start_3(pmp_start_3_1),
					.pmp_start_4(pmp_start_4_1),
					.pmp_start_5(pmp_start_5_1),
					.pmp_start_6(pmp_start_6_1),
					.pmp_start_7(pmp_start_7_1),
					.pmp_start_8(pmp_start_8_1),
					.pmp_start_9(pmp_start_9_1),
					.pmp_start_10(pmp_start_10_1),
					.pmp_start_11(pmp_start_11_1),
					.pmp_start_12(pmp_start_12_1),
					.pmp_start_13(pmp_start_13_1),
					.pmp_start_14(pmp_start_14_1),
					.pmp_start_15(pmp_start_15_1),
					.pmp_end_0(pmp_end_0_1),
					.pmp_end_1(pmp_end_1_1),
					.pmp_end_2(pmp_end_2_1),
					.pmp_end_3(pmp_end_3_1),
					.pmp_end_4(pmp_end_4_1),
					.pmp_end_5(pmp_end_5_1),
					.pmp_end_6(pmp_end_6_1),
					.pmp_end_7(pmp_end_7_1),
					.pmp_end_8(pmp_end_8_1),
					.pmp_end_9(pmp_end_9_1),
					.pmp_end_10(pmp_end_10_1),
					.pmp_end_11(pmp_end_11_1),
					.pmp_end_12(pmp_end_12_1),
					.pmp_end_13(pmp_end_13_1),
					.pmp_end_14(pmp_end_14_1),
					.pmp_end_15(pmp_end_15_1),
					.pmp_prot_0(pmp_prot_0_1),
					.pmp_prot_1(pmp_prot_1_1),
					.pmp_prot_2(pmp_prot_2_1),
					.pmp_prot_3(pmp_prot_3_1),
					.pmp_prot_4(pmp_prot_4_1),
					.pmp_prot_5(pmp_prot_5_1),
					.pmp_prot_6(pmp_prot_6_1),
					.pmp_prot_7(pmp_prot_7_1),
					.pmp_prot_8(pmp_prot_8_1),
					.pmp_prot_9(pmp_prot_9_1),
					.pmp_prot_10(pmp_prot_10_1),
					.pmp_prot_11(pmp_prot_11_1),
					.pmp_prot_12(pmp_prot_12_1),
					.pmp_prot_13(pmp_prot_13_1),
					.pmp_prot_14(pmp_prot_14_1),
					.pmp_prot_15(pmp_prot_15_1));

				assign rd_pmp_fail[L] = rd_pmp_fail_h[r_load_hart[L]][L];
			end else begin
				assign rd_pmp_fail[L] = rd_pmp_fail_h[0][L];
			end

			if (RV == 64) begin
				always @(*) begin
						c_load_vaddr[L] = iload_r1[L]+{{RV-32{r_load_immed[L][31]}},r_load_immed[L]};
				end
				always @(*) begin
					if (r_load_queued[L]) begin
						c_load_paddr[L] = write_mem_addr[r_load_ack_entry[L]];
						c_load_io[L] = write_mem_io[r_load_ack_entry[L]];
					end else begin
						casez ({rd_mprv[L][3], tlb_rd_valid[L], rd_sup_vm_mode[L]}) // synthesis full_case parallel_case
						6'b1_?_????, 
						6'b0_0_???0, 
						6'b0_?_???1:begin
										c_load_paddr[L] = c_load_vaddr[L][NPHYS-1:0];
										c_load_io[L] = c_load_vaddr[L][NPHYS-1];
									end
						6'b0_1_??1?:begin
										c_load_paddr[L] = {tlb_rd_paddr[L][NPHYS-1:22],
													tlb_rd_4mB[L]?c_load_vaddr[L][21:12]:tlb_rd_paddr[L][21:12],
													c_load_vaddr[L][11:0]};
										c_load_io[L] = tlb_rd_paddr[L][NPHYS-1];
									end
						6'b0_1_?1??:begin
										c_load_paddr[L] = {tlb_rd_paddr[L][NPHYS-1:30],
													tlb_rd_1gB[L]?c_load_vaddr[L][29:21]:tlb_rd_paddr[L][29:21],
													tlb_rd_2mB[L]?c_load_vaddr[L][20:12]:tlb_rd_paddr[L][20:12],
													c_load_vaddr[L][11:0]};
										c_load_io[L] = tlb_rd_paddr[L][NPHYS-1];
									end
						6'b0_1_1???:begin
										c_load_paddr[L] = {tlb_rd_paddr[L][NPHYS-1:39],
													tlb_rd_512gB[L]?c_load_vaddr[L][38:30]:tlb_rd_paddr[L][38:30],
													tlb_rd_1gB[L]?c_load_vaddr[L][29:21]:tlb_rd_paddr[L][29:21],
													tlb_rd_2mB[L]?c_load_vaddr[L][20:12]:tlb_rd_paddr[L][20:12],
													c_load_vaddr[L][11:0]};
										c_load_io[L] = tlb_rd_paddr[L][NPHYS-1];
									end
						default: begin c_load_paddr[L] = 'bx; c_load_io[L] = 1'bx; end
						endcase
					end
					dc_rd_addr[L] = c_load_paddr[L][NPHYS-1:(RV==64?3:2)];
					dc_rd_hart[L] = r_load_hart[L];	
					dc_rd_lr[L] = r_load_control[L][4];
				end
			end else begin
				always @(*) begin
					c_load_vaddr[L] = iload_r1[L]+r_load_immed[L];
				end
				always @(*) begin
					if (r_load_queued[L]) begin
						c_load_paddr[L] = write_mem_addr[r_load_ack_entry[L]];
						c_load_io[L] = write_mem_io[r_load_ack_entry[L]];
					end else begin
						casez ({rd_mprv[L][3], tlb_rd_valid[L], rd_sup_vm_mode[L][1:0]}) // synthesis full_case parallel_case
						4'b1_?_??, 
						4'b1_0_?1,
						4'b0_?_?1: c_load_paddr[L] = c_load_vaddr[L][NPHYS-1:0];
						4'b0_1_1?: c_load_paddr[L] = {tlb_rd_paddr[L][NPHYS-1:22],
													tlb_rd_4mB[L]?c_load_vaddr[L][21:10]:tlb_rd_paddr[L][21:10],
													c_load_vaddr[L][11:0]};
						default: begin c_load_paddr[L] = 'bx; end
						endcase
						c_load_io[L] = 0; // FIXME maybe
					end
					dc_rd_addr[L] = c_load_paddr[L][NPHYS-1:(RV==64?3:2)];
					dc_rd_hart[L] = r_load_hart[L];
					dc_rd_lr[L] = r_load_control[L][4];
				end
			end
			always @(*) begin
				rd_prot[L] = 4'bxxxx;
				casez({rd_mprv[L], rd_sup_vm_mode[L][0], rd_sup_vm_sum[L], tlb_rd_valid[L], rd_mxr[L]&tlb_rd_aduwrx[L][0], tlb_rd_aduwrx[L][5:1], rd_pmp_fail[L]}) // synthesis full_case parallel_case
				14'b1???_?_?_?_?_?????_0: rd_prot[L] = 4'b0001;	// M mode
				14'b1???_?_?_?_?_?????_1: rd_prot[L] = 4'b0100;	// M mode - locked

				14'b??1?_1_?_0_?_?????_0,							// turned off
				14'b???1_1_?_0_?_?????_0: rd_prot[L] = 4'b0001;	// turned off
				14'b??1?_1_?_0_?_?????_1,							// turned off pmp fault
				14'b???1_1_?_0_?_?????_1: rd_prot[L] = 4'b0100;	// turned off pmp fault

				14'b??1?_0_?_0_?_?????_?: rd_prot[L] = 4'b1000;	// sup tlb miss (handled by attempting to fetch)
				14'b??1?_0_?_1_?_0?0??_?: rd_prot[L] = 4'b0010;	// sup tlb not A
				14'b??1?_0_?_1_0_1?0?0_?: rd_prot[L] = 4'b0010;	// sup tlb read not OK
				14'b??1?_0_?_1_1_1?0?0_0: rd_prot[L] = 4'b0001;	// sup tbl read OK
				14'b??1?_0_?_1_?_1?0?1_0: rd_prot[L] = 4'b0001;	// sup tbl read OK
				14'b??1?_0_?_1_1_1?0?0_1: rd_prot[L] = 4'b0100;	// sup tbl read OK	pmp fail
				14'b??1?_0_?_1_?_1?0?1_1: rd_prot[L] = 4'b0100;	// sup tbl read OK	pmp fail

				14'b??1?_0_0_1_?_??1??_?: rd_prot[L] = 4'b0010;	// sup tlb read not OK
				14'b??1?_0_1_1_?_0?1??_?: rd_prot[L] = 4'b0010;	// sup tlb read not A
				14'b??1?_0_1_1_0_1?1?0_?: rd_prot[L] = 4'b0010;	// sup tlb read not OK
				14'b??1?_0_1_1_1_1?1?0_0: rd_prot[L] = 4'b0001;	// sup tbl read OK
				14'b??1?_0_1_1_?_1?1?1_0: rd_prot[L] = 4'b0001;	// sup tbl read OK
				14'b??1?_0_1_1_1_1?1?0_1: rd_prot[L] = 4'b0100;	// sup tbl read OK  pmp fail
				14'b??1?_0_1_1_?_1?1?1_1: rd_prot[L] = 4'b0100;	// sup tbl read OK  pmp fail

				14'b???1_0_?_0_?_?????_?: rd_prot[L] = 4'b1000;	// usr tlb miss (handled by attempting to fetch)
				14'b???1_0_?_1_?_??0??_?: rd_prot[L] = 4'b0010;	// usr tlb read sup page
				14'b???1_0_?_1_?_0?1??_?: rd_prot[L] = 4'b0010;	// usr tlb read not A
				14'b???1_0_?_1_0_1?1?0_?: rd_prot[L] = 4'b0010;	// usr tlb read not OK
				14'b???1_0_?_1_1_1?1?0_0: rd_prot[L] = 4'b0001;	// usr tbl read OK
				14'b???1_0_?_1_?_1?1?1_0: rd_prot[L] = 4'b0001;	// usr tbl read OK
				14'b???1_0_?_1_1_1?1?0_1: rd_prot[L] = 4'b0100;	// usr tbl read OK pmp
				14'b???1_0_?_1_?_1?1?1_1: rd_prot[L] = 4'b0100;	// usr tbl read OK pmp
				default: rd_prot[L] = 4'bxxxx; 
				endcase
				//rd_tlb_miss[L] = !rd_mprv[L][3] && rd_sup_vm_mode[L][0] == 0 && !tlb_rd_valid[L];
				casez ({rd_mprv[L][3], rd_sup_vm_mode[L]}) // synthesis full_case parallel_case
				5'b1_????: rd_addr_ok[L] = 1;
				5'b0_???1: rd_addr_ok[L] = 1;
				5'b0_??1?: rd_addr_ok[L] = 1;
				5'b0_?1??: rd_addr_ok[L] = !c_load_vaddr[L][38]?(c_load_vaddr[L][RV-1:39]==25'h0):(c_load_vaddr[L][RV-1:39]==25'h1_ff_ff_ff);
				5'b0_1???: rd_addr_ok[L] = !c_load_vaddr[L][47]?(c_load_vaddr[L][RV-1:48]==16'h0):(c_load_vaddr[L][RV-1:48]==16'hff_ff);
				default: rd_addr_ok[L] = 1'bx; 
				endcase
			end
			
			if (RV==64) begin
				always @(*) begin
					casez(r_load_control[L][1:0]) // synthesis full_case parallel_case
					2'b11:	c_load_alignment_bad[L] = c_load_paddr[L][2:0]!=0;
					2'b10:	c_load_alignment_bad[L] = c_load_paddr[L][1:0]!=0;
					2'b01:	c_load_alignment_bad[L] = c_load_paddr[L][0]!=0;
					2'b00:	c_load_alignment_bad[L] = 0;
					endcase
					casez ({r_load_control[L][1:0], c_load_paddr[L][2:0]}) // synthesis full_case parallel_case
					5'b11_???: c_load_mask[L] = 8'b1111_1111;
					5'b10_0??: c_load_mask[L] = 8'b0000_1111;
					5'b10_1??: c_load_mask[L] = 8'b1111_0000;
					5'b01_00?: c_load_mask[L] = 8'b0000_0011;
					5'b01_01?: c_load_mask[L] = 8'b0000_1100;
					5'b01_10?: c_load_mask[L] = 8'b0011_0000;
					5'b01_11?: c_load_mask[L] = 8'b1100_0000;
					5'b00_000: c_load_mask[L] = 8'b0000_0001;
					5'b00_001: c_load_mask[L] = 8'b0000_0010;
					5'b00_010: c_load_mask[L] = 8'b0000_0100;
					5'b00_011: c_load_mask[L] = 8'b0000_1000;
					5'b00_100: c_load_mask[L] = 8'b0001_0000;
					5'b00_101: c_load_mask[L] = 8'b0010_0000;
					5'b00_110: c_load_mask[L] = 8'b0100_0000;
					5'b00_111: c_load_mask[L] = 8'b1000_0000;
					endcase
				end
			end else begin
				always @(*) begin
					casez(r_load_control[L][1:0]) // synthesis full_case parallel_case
					2'b10:	c_load_alignment_bad[L] = c_load_paddr[L][1:0]!=0;
					2'b01:	c_load_alignment_bad[L] = c_load_paddr[L][0]!=0;
					2'b00:	c_load_alignment_bad[L] = 0;
					default: c_load_alignment_bad[L] = 1'bx; 
					endcase
					casez ({r_load_control[L][1:0], c_load_paddr[L][1:0]}) // synthesis full_case parallel_case
					4'b10_??: c_load_mask[L] = 4'b1111;
					4'b01_0?: c_load_mask[L] = 4'b0011;
					4'b01_1?: c_load_mask[L] = 4'b1100;
					4'b00_00: c_load_mask[L] = 4'b0001;
					4'b00_01: c_load_mask[L] = 4'b0010;
					4'b00_10: c_load_mask[L] = 4'b0100;
					4'b00_11: c_load_mask[L] = 4'b1000;
					default:  c_load_mask[L] = 4'bxxxx; 
					endcase
				end
			end
			always @(*) begin 
				c_load_trap_type[L] = 2'bxx;
				casez ({r_load_queued[L], r_load_io[L]&r_load_queued[L]&r_io_data_err, c_load_alignment_bad[L],~rd_addr_ok[L], rd_prot[L]}) // synthesis parallel_case full_case
				8'b0_?1?_????:	c_load_trap_type[L] = 1; // alligned
				8'b0_?00_1???,
				8'b0_?00_??1?:	c_load_trap_type[L] = 3; // page fault
				
				8'b1_100_????,
				8'b0_?01_????,
				8'b0_000_?1??:	c_load_trap_type[L] = 2; // protection
				8'b1_0??_????,
				8'b0_000_???1:	c_load_trap_type[L] = 0; // no trap
				default:  c_load_trap_type[L] = 2'bxx; 
				endcase
				c_load_vm_pause[L] = (r_hart_vm_pause[r_load_hart[L]]||hart_vm_pause[r_load_hart[L]])&&r_load_state[L]&&!r_load_queued[L]&&!x_load_killed[L];
				c_load_vm_stall[L] = rd_prot[L][3]&&r_load_state[L]&&!r_load_queued[L]&&!x_load_killed[L]&&!(r_hart_vm_pause[r_load_hart[L]]||hart_vm_pause[r_load_hart[L]]);
			end
			always @(*) begin
				case (r_load_hart[L]) // synthesis full_case parallel_case
				0: x_load_killed[L] = commit_kill_0[r_load_rd[L]];
				//1: x_load_killed[L]= commit_kill_1[r_load_rd[L]];
				default: x_load_killed[L] = 1'bx;
				endcase
				c_load_allocate[L] = r_load_state[L]&&
							!r_load_queued[L] &&
							(((|load_snoop_hit[L]?load_hazard[L]:!dc_rd_hit[L]||(dc_rd_lr[L]&&dc_rd_hit_need_o[L]))&&(c_load_trap_type[L]==0)) || 
								r_load_control[L][4] ||  c_load_io[L]) &&
							!rd_prot[L][3] &&
							!(r_hart_vm_pause[r_load_hart[L]]||hart_vm_pause[r_load_hart[L]]) &&
							!x_load_killed[L];
//if (L==0)$display($time,,"c_load_allocate[%d]=%d",L,c_load_allocate[L]);
//if (L==0)$displayb($time,,r_load_state[L],,r_load_queued[L],,load_hazard[L],,load_snoop_hit[L],,dc_rd_hit[L],,c_load_trap_type[L]);
				c_res_makes_rd[L] = 0;
				if (!reset) begin
					c_res_makes_rd[L][r_load_hart[L]] = r_load_state[L]&(r_load_queued[L]&&(r_load_io[L]||(dc_rd_hit[L]&&!(dc_rd_lr[L]&&dc_rd_hit_need_o[L])))?r_load_makes_rd[L]||!r_load_amo[L]:r_load_makes_rd[L]&!c_load_allocate[L])&(c_load_trap_type[L]==0)&&!x_load_killed[L];
				end
			end
		
			always @(posedge clk) begin // scheduler ensures loads come first and then stores
				case (iload_hart[L]) // synthesis full_case parallel_case
				0: load_killed[L] = commit_kill_0[iload_rd[L]];
				//1: load_killed[L] = commit_kill_1[iload_rd[L]];
				default: load_killed[L] = 1'bx;
				endcase
				if (reset) begin
					r_load_state[L] <= 0;
					r_load_queued[L] <= 0;
					r_load_hart[L] <= 0;
				end else
				if (iload_enable[L] && !load_killed[L]) begin
					r_load_state[L] <= 1;
					r_load_rd[L] <= iload_rd[L];
`ifdef FP
					r_load_fp[L] <= iload_control[L][3];
`endif
					r_load_makes_rd[L] <= iload_makes_rd[L];
					r_load_amo[L] <= 0;
					r_load_control[L] <= iload_control[L];
					r_load_aq_rl[L] <= iload_control[L][4]?iload_immed[L][26:25]:0;
					r_load_immed[L] <= iload_control[L][4]?0:iload_immed[L];
					r_load_hart[L] <= iload_hart[L];
					r_load_queued[L] <= 0;
					r_load_page_fault[L] <= 0;
					r_load_sc[L] <= 0;
					r_load_io[L] <= 0;
				end else
				if (c_load_queued_ready[L]) begin
					r_load_state[L] <= 1;
// !!!!!! c_load_queued_index ????
					r_load_rd[L] <= wq_rd[c_load_queued_index[L]];
`ifdef FP
					r_load_fp[L] <= wq_fp[c_load_queued_index[L]];
`endif
					r_load_amo[L] <= write_mem_amo[c_load_queued_index[L]][0] && !wq_control[c_load_queued_index[L]][3]  && (write_mem_amo[c_load_queued_index[L]][2:1] != 2'b11);
					r_load_makes_rd[L] <= wq_makes_rd[c_load_queued_index[L]];
					r_load_sc[L] <= write_mem_sc[c_load_queued_index[L]];
					r_load_io[L] <= write_mem_io[c_load_queued_index[L]];
					r_load_sc_okv[L] <= write_mem_sc_okv[c_load_queued_index[L]];
					r_load_hart[L] <= wq_hart[c_load_queued_index[L]];
					r_load_aq_rl[L] <= wq_aq_rl[c_load_queued_index[L]];
					r_load_ack_entry[L] <= c_load_queued_index[L];
					r_load_queued[L] <= 1;
					r_load_control[L] <= {1'bx,wq_control[c_load_queued_index[L]][3],1'b0, wq_control[c_load_queued_index[L]][2:0]};
					r_load_page_fault[L] <= 0; // FIXME??
				end else begin
					r_load_state[L] <= 0;
					r_load_queued[L] <= 0;
				end

				if (reset) begin
					r_load_done[L] <= 0;
					r_load_pending[L] <= 0;
					r_load_vm_stall[L] <= 0;
					r_load_vm_pause[L] <= 0;
				end else
				if (r_load_state[L]) begin :l0
					reg [RV-1:0]data;
					reg [(RV==64?2:1):0]addr_lo;
				
					if (RV == 64) begin
						casez ({r_load_io[L], r_load_queued[L], r_load_sc[L]}) // synthesis full_case parallel_case
						3'b??1: begin
								data = {63'b0, r_load_sc_okv[L]};
								addr_lo = 0;
							   end
						3'b010: begin
								data = dc_rd_data[L];
								addr_lo = write_mem_addr[r_load_ack_entry[L]][2:0];
							   end
						3'b110: begin
								data = r_io_data;
								addr_lo = write_mem_addr[r_load_ack_entry[L]][2:0];
							   end
						3'b?00: begin
								data = (|load_snoop_hit[L]?load_snoop[L]:dc_rd_data[L]);
								addr_lo = c_load_paddr[L][2:0];
							   end
						default:  begin addr_lo = 3'bxxx;  data = 'bx; end
						endcase
						casez ({r_load_control[L][2:0], addr_lo}) // synthesis full_case parallel_case
						6'b?_11_???: r_res[L] <= data;
						6'b1_10_0??: r_res[L] <= {32'b0, data[31:0]};
						6'b1_10_1??: r_res[L] <= {32'b0, data[63:32]};
						6'b0_10_0??: r_res[L] <= {{32{data[31]}}, data[31:0]};
						6'b0_10_1??: r_res[L] <= {{32{data[63]}}, data[63:32]};
						6'b1_01_00?: r_res[L] <= {48'b0, data[15:0]};
						6'b1_01_01?: r_res[L] <= {48'b0, data[31:16]};
						6'b1_01_10?: r_res[L] <= {48'b0, data[47:32]};
						6'b1_01_11?: r_res[L] <= {48'b0, data[63:48]};
						6'b0_01_00?: r_res[L] <= {{48{data[15]}}, data[15:0]};
						6'b0_01_01?: r_res[L] <= {{48{data[31]}}, data[31:16]};
						6'b0_01_10?: r_res[L] <= {{48{data[47]}}, data[47:32]};
						6'b0_01_11?: r_res[L] <= {{48{data[63]}}, data[63:48]};
						6'b1_00_000: r_res[L] <= {56'b0, data[7:0]};
						6'b1_00_001: r_res[L] <= {56'b0, data[15:8]};
						6'b1_00_010: r_res[L] <= {56'b0, data[23:16]};
						6'b1_00_011: r_res[L] <= {56'b0, data[31:24]};
						6'b1_00_100: r_res[L] <= {56'b0, data[39:32]};
						6'b1_00_101: r_res[L] <= {56'b0, data[47:40]};
						6'b1_00_110: r_res[L] <= {56'b0, data[55:48]};
						6'b1_00_111: r_res[L] <= {56'b0, data[63:56]};
						6'b0_00_000: r_res[L] <= {{56{data[7]}}, data[7:0]};
						6'b0_00_001: r_res[L] <= {{56{data[15]}}, data[15:8]};
						6'b0_00_010: r_res[L] <= {{56{data[23]}}, data[23:16]};
						6'b0_00_011: r_res[L] <= {{56{data[31]}}, data[31:24]};
						6'b0_00_100: r_res[L] <= {{56{data[39]}}, data[39:32]};
						6'b0_00_101: r_res[L] <= {{56{data[47]}}, data[47:40]};
						6'b0_00_110: r_res[L] <= {{56{data[55]}}, data[55:48]};
						6'b0_00_111: r_res[L] <= {{56{data[63]}}, data[63:56]};
						endcase
					end else begin
						casez ({r_load_queued[L], r_load_sc[L]}) // synthesis full_case parallel_case
						2'b?1: begin
								data = {31'b0, r_load_sc_okv[L]};
								addr_lo = 0;
							   end
						2'b10: begin
								data = dc_rd_data[L];
								addr_lo = write_mem_addr[r_load_ack_entry[L]][1:0];
							   end
						2'b00: begin
								data = (|load_snoop_hit[L]?load_snoop[L]:dc_rd_data[L]);
								addr_lo = c_load_paddr[L][1:0];
							   end
						default:  begin addr_lo = 3'bxxx;  data = 'bx; end
						endcase
						casez ({r_load_control[L][2:0], addr_lo}) // synthesis full_case parallel_case
						5'b?_10_0?: r_res[L] <= data;
						5'b1_01_0?: r_res[L] <= {16'b0, data[15:0]};
						5'b1_01_1?: r_res[L] <= {16'b0, data[31:16]};
						5'b0_01_0?: r_res[L] <= {{16{data[15]}}, data[15:0]};
						5'b0_01_1?: r_res[L] <= {{16{data[31]}}, data[31:16]};
						5'b1_00_00: r_res[L] <= {24'b0, data[7:0]};
						5'b1_00_01: r_res[L] <= {24'b0, data[15:8]};
						5'b1_00_10: r_res[L] <= {24'b0, data[23:16]};
						5'b1_00_11: r_res[L] <= {24'b0, data[31:24]};
						5'b0_00_00: r_res[L] <= {{24{data[7]}}, data[7:0]};
						5'b0_00_01: r_res[L] <= {{24{data[15]}}, data[15:8]};
						5'b0_00_10: r_res[L] <= {{24{data[23]}}, data[23:16]};
						5'b0_00_11: r_res[L] <= {{24{data[31]}}, data[31:24]};
						endcase
					end
`ifdef SIMD
					if (!c_load_allocate[L] && simd_enable) $display("L%d %d %x a=%x %x d=%x",L[1:0],$time,r_load_rd[L],c_load_vaddr[L],c_load_paddr[L],data);
`endif
					r_load_done_commit[L] <= r_load_rd[L];
					r_load_done[L] <= 1;
					r_load_vm_pause[L] <= c_load_vm_pause[L];
					r_load_vm_stall[L] <= c_load_vm_stall[L];
					r_load_pending[L] <= (!r_load_queued[L]?c_load_allocate[L]:(!r_load_sc[L])&&(!r_load_io[L]&&!dc_rd_hit[L]&&!(dc_rd_lr[L]&&dc_rd_hit_need_o[L])));
					r_load_trap_type[L] <= c_load_trap_type[L];
				end else begin
					r_load_pending[L] <= 0;
					r_load_done[L] <= 0;
					r_load_vm_stall[L] <= 0;
					r_load_vm_pause[L] <= 0;
				end
				r_res_makes_rd[L] <= c_res_makes_rd[L];
`ifdef FP
				r_load_fp_commit[L] <= r_load_fp[L];
`endif
			end

			for (H = 0; H < NHART; H=H+1) begin
				assign h_load_vm_stall[H][L] = (r_load_hart[L]==H) && r_load_vm_stall[L];
			end
		end

		for (S = 0; S < NSTORE; S=S+1) begin :wr 

			assign wr_cpu_mode[S] = cpu_mode[r_store_hart[S]];
			assign wr_mprv[S] = mprv[r_store_hart[S]];
			assign wr_sup_vm_mode[S] = sup_vm_mode[r_store_hart[S]];
			assign wr_sup_asid[S] = sup_asid[r_store_hart[S]];
			assign wr_sup_vm_sum[S] = sup_vm_sum[r_store_hart[S]];

			assign tlb_rd_asid[NLOAD+S] = wr_sup_asid[S];

			assign tlb_rd_enable[NLOAD+S] = r_store_state[S]&&(!r_store_control[S][5]||r_store_control[S][2:0]>2)&&(!wr_mprv[S][3]);

			pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))pmp_check_0(
				.m(mprv_0[3]),
				.su(mprv_0[1]|mprv_0[0]),
				.mprv(1'b0),
				.addr(c_store_paddr[S][NPHYS-1:2]),
				.sz({1'b0,r_store_control[S][1:0]==3?1'b1:1'b0}),
				.check_x(1'b0),
				.check_r(1'b0),
				.check_w(1'b1),
				.fail(wr_pmp_fail_h[0][S]),

				.pmp_valid(pmp_valid_0),		// sadly arrays of buses aren't well supported 
				.pmp_locked(pmp_locked_0),	// so we need to get verbose - unused wires will be optimised
				.pmp_start_0(pmp_start_0_0),		// out during synthesis
				.pmp_start_1(pmp_start_1_0),
				.pmp_start_2(pmp_start_2_0),
				.pmp_start_3(pmp_start_3_0),
				.pmp_start_4(pmp_start_4_0),
				.pmp_start_5(pmp_start_5_0),
				.pmp_start_6(pmp_start_6_0),
				.pmp_start_7(pmp_start_7_0),
				.pmp_start_8(pmp_start_8_0),
				.pmp_start_9(pmp_start_9_0),
				.pmp_start_10(pmp_start_10_0),
				.pmp_start_11(pmp_start_11_0),
				.pmp_start_12(pmp_start_12_0),
				.pmp_start_13(pmp_start_13_0),
				.pmp_start_14(pmp_start_14_0),
				.pmp_start_15(pmp_start_15_0),
				.pmp_end_0(pmp_end_0_0),
				.pmp_end_1(pmp_end_1_0),
				.pmp_end_2(pmp_end_2_0),
				.pmp_end_3(pmp_end_3_0),
				.pmp_end_4(pmp_end_4_0),
				.pmp_end_5(pmp_end_5_0),
				.pmp_end_6(pmp_end_6_0),
				.pmp_end_7(pmp_end_7_0),
				.pmp_end_8(pmp_end_8_0),
				.pmp_end_9(pmp_end_9_0),
				.pmp_end_10(pmp_end_10_0),
				.pmp_end_11(pmp_end_11_0),
				.pmp_end_12(pmp_end_12_0),
				.pmp_end_13(pmp_end_13_0),
				.pmp_end_14(pmp_end_14_0),
				.pmp_end_15(pmp_end_15_0),
				.pmp_prot_0(pmp_prot_0_0),
				.pmp_prot_1(pmp_prot_1_0),
				.pmp_prot_2(pmp_prot_2_0),
				.pmp_prot_3(pmp_prot_3_0),
				.pmp_prot_4(pmp_prot_4_0),
				.pmp_prot_5(pmp_prot_5_0),
				.pmp_prot_6(pmp_prot_6_0),
				.pmp_prot_7(pmp_prot_7_0),
				.pmp_prot_8(pmp_prot_8_0),
				.pmp_prot_9(pmp_prot_9_0),
				.pmp_prot_10(pmp_prot_10_0),
				.pmp_prot_11(pmp_prot_11_0),
				.pmp_prot_12(pmp_prot_12_0),
				.pmp_prot_13(pmp_prot_13_0),
				.pmp_prot_14(pmp_prot_14_0),
				.pmp_prot_15(pmp_prot_15_0));
			
			if (NHART > 1) begin
				pmp_checker #(.NPHYS(NPHYS), .NUM_PMP(NUM_PMP))pmp_check_1(
					.m(mprv_1[3]),
					.su(mprv_1[1]|mprv_1[0]),
					.mprv(1'b0),
					.addr(c_store_paddr[S][NPHYS-1:2]),
					.sz({1'b0,r_store_control[S][1:0]==3?1'b1:1'b0}),
					.check_x(1'b0),
					.check_r(1'b0),
					.check_w(1'b1),
					.fail(wr_pmp_fail_h[1][S]),
	
					.pmp_valid(pmp_valid_1),		// sadly arrays of buses aren't well supported 
					.pmp_locked(pmp_locked_1),	// so we need to get verbose - unused wires will be optimised
					.pmp_start_0(pmp_start_0_1),		// out during synthesis
					.pmp_start_1(pmp_start_1_1),
					.pmp_start_2(pmp_start_2_1),
					.pmp_start_3(pmp_start_3_1),
					.pmp_start_4(pmp_start_4_1),
					.pmp_start_5(pmp_start_5_1),
					.pmp_start_6(pmp_start_6_1),
					.pmp_start_7(pmp_start_7_1),
					.pmp_start_8(pmp_start_8_1),
					.pmp_start_9(pmp_start_9_1),
					.pmp_start_10(pmp_start_10_1),
					.pmp_start_11(pmp_start_11_1),
					.pmp_start_12(pmp_start_12_1),
					.pmp_start_13(pmp_start_13_1),
					.pmp_start_14(pmp_start_14_1),
					.pmp_start_15(pmp_start_15_1),
					.pmp_end_0(pmp_end_0_1),
					.pmp_end_1(pmp_end_1_1),
					.pmp_end_2(pmp_end_2_1),
					.pmp_end_3(pmp_end_3_1),
					.pmp_end_4(pmp_end_4_1),
					.pmp_end_5(pmp_end_5_1),
					.pmp_end_6(pmp_end_6_1),
					.pmp_end_7(pmp_end_7_1),
					.pmp_end_8(pmp_end_8_1),
					.pmp_end_9(pmp_end_9_1),
					.pmp_end_10(pmp_end_10_1),
					.pmp_end_11(pmp_end_11_1),
					.pmp_end_12(pmp_end_12_1),
					.pmp_end_13(pmp_end_13_1),
					.pmp_end_14(pmp_end_14_1),
					.pmp_end_15(pmp_end_15_1),
					.pmp_prot_0(pmp_prot_0_1),
					.pmp_prot_1(pmp_prot_1_1),
					.pmp_prot_2(pmp_prot_2_1),
					.pmp_prot_3(pmp_prot_3_1),
					.pmp_prot_4(pmp_prot_4_1),
					.pmp_prot_5(pmp_prot_5_1),
					.pmp_prot_6(pmp_prot_6_1),
					.pmp_prot_7(pmp_prot_7_1),
					.pmp_prot_8(pmp_prot_8_1),
					.pmp_prot_9(pmp_prot_9_1),
					.pmp_prot_10(pmp_prot_10_1),
					.pmp_prot_11(pmp_prot_11_1),
					.pmp_prot_12(pmp_prot_12_1),
					.pmp_prot_13(pmp_prot_13_1),
					.pmp_prot_14(pmp_prot_14_1),
					.pmp_prot_15(pmp_prot_15_1));

				assign wr_pmp_fail[S] = wr_pmp_fail_h[r_load_hart[S]][S];
			end else begin
				assign wr_pmp_fail[S] = wr_pmp_fail_h[0][S];
			end
			if (RV == 64) begin
				always @(*) begin
					c_store_vaddr[S] = istore_r1[S]+{{RV-32{r_store_immed[S][31]}},r_store_immed[S]};
				end
				always @(*) begin
					c_store_paddr[S] = 'bx;
					c_store_io[S] = 'bx;
					casez ({wr_mprv[S][3], wr_sup_vm_mode[S]}) // synthesis full_case parallel_case
					5'b1_????, 
					5'b0_???1:begin
								c_store_paddr[S] = c_store_vaddr[S];
								c_store_io[S] = c_store_vaddr[S][NPHYS-1];
							  end
					/* verilator lint_off SELRANGE */
					5'b0_??1?:begin
								c_store_paddr[S] = {tlb_rd_paddr[NLOAD+S][NPHYS-1:22],
												tlb_rd_4mB[NLOAD+S]?c_store_vaddr[S][21:10]:tlb_rd_paddr[NLOAD+S][21:12],
												c_store_vaddr[S][11:0]};
								c_store_io[S] = tlb_rd_paddr[NLOAD+S][NPHYS-1];
							  end
					/* verilator lint_on SELRANGE */
					5'b0_?1??:begin
								c_store_paddr[S] = {tlb_rd_paddr[NLOAD+S][NPHYS-1:30],
												tlb_rd_1gB[NLOAD+S]?c_store_vaddr[S][29:21]:tlb_rd_paddr[NLOAD+S][29:21],
												tlb_rd_2mB[NLOAD+S]?c_store_vaddr[S][20:12]:tlb_rd_paddr[NLOAD+S][20:12],
												c_store_vaddr[S][11:0]};
								c_store_io[S] = tlb_rd_paddr[NLOAD+S][NPHYS-1];
							  end
					5'b0_1???:begin
								c_store_paddr[S] = {tlb_rd_paddr[NLOAD+S][NPHYS-1:39],
												tlb_rd_512gB[NLOAD+S]?c_store_vaddr[S][38:30]:tlb_rd_paddr[NLOAD+S][38:30],
												tlb_rd_1gB[NLOAD+S]?c_store_vaddr[S][29:21]:tlb_rd_paddr[NLOAD+S][29:21],
												tlb_rd_2mB[NLOAD+S]?c_store_vaddr[S][20:12]:tlb_rd_paddr[NLOAD+S][20:12],
												c_store_vaddr[S][11:0]};
								c_store_io[S] = tlb_rd_paddr[NLOAD+S][NPHYS-1];
							  end
					default:  begin c_store_io[S] = 1'bx;  c_store_paddr[S] = 'bx; end
					endcase
				end
			end else begin
				always @(*) begin
					c_store_vaddr[S] = istore_r1[S]+{{RV-32{r_store_immed[S][31]}},r_store_immed[S]};
				end
				always @(*) begin
					c_store_paddr[S] = 'bx;
					casez ({wr_mprv[S][3], wr_sup_vm_mode[S][1:0]}) // synthesis full_case parallel_case
					3'b1_??, 
					3'b0_?1: c_store_paddr[S] = c_store_vaddr[S];
					3'b0_1?: c_store_paddr[S] = {tlb_rd_paddr[NLOAD+S][NPHYS-1:22],
												  tlb_rd_4mB[NLOAD+S]?c_store_vaddr[S][21:10]:tlb_rd_paddr[NLOAD+S][21:10],
												  c_store_vaddr[S][11:0]};
					default:  begin c_store_paddr[S] = 'bx; end
					endcase
					c_store_io[S] = 0; // FIXME maybe
				end
			end

			always @(*) begin
				wr_addr_ok[S] = 1'bx;
				casez ({wr_mprv[S][3], wr_sup_vm_mode[S]}) // synthesis full_case parallel_case
				5'b1_????: wr_addr_ok[S] = 1;
				5'b0_???1: wr_addr_ok[S] = 1;
				5'b0_??1?: wr_addr_ok[S] = 1;
				5'b0_?1??: wr_addr_ok[S] = !c_store_vaddr[S][38]?(c_store_vaddr[S][RV-1:39]==25'h0):(c_store_vaddr[S][RV-1:39]==25'h1_ff_ff_ff);
				5'b0_1???: wr_addr_ok[S] = !c_store_vaddr[S][47]?(c_store_vaddr[S][RV-1:48]==16'h0):(c_store_vaddr[S][RV-1:48]==16'hff_ff);
				default: wr_addr_ok[S] = 1'bx; 
				endcase
				casez ({wr_mprv[S], wr_sup_vm_mode[S][0], wr_sup_vm_sum[S], tlb_rd_valid[NLOAD+S], tlb_rd_aduwrx[NLOAD+S][5:1], wr_pmp_fail[S]}) // synthesis full_case parallel_case
				'b1???_?_?_?_?????_0: wr_prot[S] = 4'b0001;	// M mode
				'b1???_?_?_?_?????_1: wr_prot[S] = 4'b0100;	// M mode

				'b??1?_1_?_0_?????_0,						// turned off
				'b???1_1_?_0_?????_0: wr_prot[S] = 4'b0001;	
				'b??1?_1_?_0_?????_1,						// turned off pmap
				'b???1_1_?_0_?????_1: wr_prot[S] = 4'b0100;	

				'b??1?_0_?_0_?????_?: wr_prot[S] = 4'b1000;	// sup tlb miss (handled by attempting to fetch)
				'b??1?_0_0_1_??1??_?: wr_prot[S] = 4'b0010;	// sup tlb U not OK
				'b??1?_0_?_1_??00?_?: wr_prot[S] = 4'b0010;	// sup tlb write not OK
				'b??1?_0_?_1_?001?_?: wr_prot[S] = 4'b0010;	// sup tlb D not set
				'b??1?_0_?_1_0101?_?: wr_prot[S] = 4'b0010;	// usr tlb A not set
				'b??1?_0_?_1_11010_?: wr_prot[S] = 4'b0010;	// usr tlb bad format
				'b??1?_0_?_1_11011_0: wr_prot[S] = 4'b0001;	// sup tlb write OK
				'b??1?_0_?_1_11011_1: wr_prot[S] = 4'b0100;	// sup tlb write OK pmap fail

				'b??1?_0_1_1_??10?_?: wr_prot[S] = 4'b0010;	// sup tlb write not OK
				'b??1?_0_1_1_?011?_?: wr_prot[S] = 4'b0010;	// sup tlb D not set
				'b??1?_0_1_1_0111?_?: wr_prot[S] = 4'b0010;	// sup tlb A not set
				'b??1?_0_1_1_11110_?: wr_prot[S] = 4'b0010;	// sup tlb bad format
				'b??1?_0_1_1_11111_0: wr_prot[S] = 4'b0001;	// sup tlb write OK
				'b??1?_0_1_1_11111_1: wr_prot[S] = 4'b0100;	// sup tlb write OK pmap fail

				'b???1_0_?_0_?????_?: wr_prot[S] = 4'b1000;	// usr tlb miss (handled by attempting to fetch)
				'b???1_0_?_1_??0??_?: wr_prot[S] = 4'b0010;	// usr tlb write sup page
				'b???1_0_?_1_??10?_?: wr_prot[S] = 4'b0010;	// usr tlb write not OK
				'b???1_0_?_1_?011?_?: wr_prot[S] = 4'b0010;	// usr tlb D not set
				'b???1_0_?_1_0111?_?: wr_prot[S] = 4'b0010;	// usr tlb A not set
				'b???1_0_?_1_11110_?: wr_prot[S] = 4'b0010;	// usr tlb bad format
				'b???1_0_?_1_11111_0: wr_prot[S] = 4'b0001;	// usr tlb write OK
				'b???1_0_?_1_11111_1: wr_prot[S] = 4'b0100;	// usr tlb write OK pmap fail
				default:  wr_prot[S] = 4'bxxxx; 
				endcase
				//wr_tlb_miss[S] = !wr_mprv[S][3] && wr_sup_vm_mode[S][0] == 0 && !tlb_rd_valid[NLOAD+S];

				c_store_state[S] = 0;	
				c_store_rd[S] = r_store_rd[S];
				c_store_makes_rd[S] = r_store_makes_rd[S];
				case (istore_hart[S]) // synthesis full_case parallel_case
				0: store_killed[S] = commit_kill_0[istore_rd[S]];
				//1: store_killed[S] = commit_kill_1[istore_rd[S]];
				default: store_killed[S] = 1'bx;
				endcase
				if (reset) begin
					c_store_state[S] = 0;
				end else
				if (istore_enable[S] && !store_killed[S]) begin
					c_store_state[S] = 1;
					c_store_rd[S] = istore_rd[S];
					c_store_makes_rd[S] = istore_makes_rd[S];
				end 
			end
		
			if (RV==64) begin
				always @(*) begin
`ifdef FP
					casez ({r_store_control[S][3], r_store_control[S][1:0]})  // synthesis full_case parallel_case
					3'b1_?1: c_store_data[S] = istore_r2_fp[S];
					3'b1_?0: c_store_data[S] = {istore_r2_fp[S][31:0],istore_r2_fp[S][31:0]};
					3'b0_11: c_store_data[S] = istore_r2[S];
					3'b0_10: c_store_data[S] = {istore_r2[S][31:0],istore_r2[S][31:0]};
					3'b0_01: c_store_data[S] = {istore_r2[S][15:0],istore_r2[S][15:0],istore_r2[S][15:0],istore_r2[S][15:0]};
					3'b0_00: c_store_data[S] = {istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0]};
					default:  c_store_data[S] = 'bx; 
					endcase
`else
					casez (r_store_control[S][1:0])  // synthesis full_case parallel_case
					2'b11: c_store_data[S] = istore_r2[S];
					2'b10: c_store_data[S] = {istore_r2[S][31:0],istore_r2[S][31:0]};
					2'b01: c_store_data[S] = {istore_r2[S][15:0],istore_r2[S][15:0],istore_r2[S][15:0],istore_r2[S][15:0]};
					2'b00: c_store_data[S] = {istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0]};
					default:  c_store_data[S] = 'bx; 
					endcase
`endif
					casez(r_store_control[S][1:0]) // synthesis full_case parallel_case
					2'b11:	c_store_alignment_bad[S] = c_store_paddr[S][2:0]!=0;
					2'b10:	c_store_alignment_bad[S] = c_store_paddr[S][1:0]!=0;
					2'b01:	c_store_alignment_bad[S] = c_store_paddr[S][0]!=0;
					2'b00:	c_store_alignment_bad[S] = 0;
					endcase
					casez({r_store_control[S][1:0], c_store_paddr[S][2:0]}) // synthesis full_case parallel_case
					5'b11_???: c_store_mask[S] = 8'b1111_1111;
					5'b10_0??: c_store_mask[S] = 8'b0000_1111;
					5'b10_1??: c_store_mask[S] = 8'b1111_0000;
					5'b01_00?: c_store_mask[S] = 8'b0000_0011;
					5'b01_01?: c_store_mask[S] = 8'b0000_1100;
					5'b01_10?: c_store_mask[S] = 8'b0011_0000;
					5'b01_11?: c_store_mask[S] = 8'b1100_0000;
					5'b00_000: c_store_mask[S] = 8'b0000_0001;
					5'b00_001: c_store_mask[S] = 8'b0000_0010;
					5'b00_010: c_store_mask[S] = 8'b0000_0100;
					5'b00_011: c_store_mask[S] = 8'b0000_1000;
					5'b00_100: c_store_mask[S] = 8'b0001_0000;
					5'b00_101: c_store_mask[S] = 8'b0010_0000;
					5'b00_110: c_store_mask[S] = 8'b0100_0000;
					5'b00_111: c_store_mask[S] = 8'b1000_0000;
					endcase
				end
			end else begin
				always @(*) begin
`ifdef FP
					casez ({r_store_control[S][3], r_store_control[S][1:0]})  // synthesis full_case parallel_case
					3'b1_??: c_store_data[S] = istore_r2[S];
					3'b0_10: c_store_data[S] = istore_r2[S];
					3'b0_01: c_store_data[S] = {istore_r2[S][15:0],istore_r2[S][15:0]};
					3'b0_00: c_store_data[S] = {istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0]};
					default:  c_store_data[S] = 'bx; 
					endcase
`else
					casez (r_store_control[S][1:0])  // synthesis full_case parallel_case
					2'b10: c_store_data[S] = istore_r2[S];
					2'b01: c_store_data[S] = {istore_r2[S][15:0],istore_r2[S][15:0]};
					2'b00: c_store_data[S] = {istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0],istore_r2[S][7:0]};
					default:  c_store_data[S] = 'bx; 
					endcase
`endif
					casez(r_store_control[S][1:0]) // synthesis full_case parallel_case
					2'b10: c_store_alignment_bad[S] = c_store_paddr[S][1:0]!=0;
					2'b01: c_store_alignment_bad[S] = c_store_paddr[S][0]!=0;
					2'b00: c_store_alignment_bad[S] = 0;
					default:  c_store_alignment_bad[S] = 'bx; 
					endcase
					casez({r_store_control[S][1:0], c_store_paddr[S][1:0]}) // synthesis full_case parallel_case
					4'b10_??: c_store_mask[S] = 4'b1111;
					4'b01_0?: c_store_mask[S] = 4'b0011;
					4'b01_1?: c_store_mask[S] = 4'b1100;
					4'b00_00: c_store_mask[S] = 4'b0001;
					4'b00_01: c_store_mask[S] = 4'b0010;
					4'b00_10: c_store_mask[S] = 4'b0100;
					4'b00_11: c_store_mask[S] = 4'b1000;
					default:  c_store_mask[S] = 'bx; 
					endcase
				end
			end
			
			always @(*) begin 
				case (r_store_hart[S]) // synthesis full_case parallel_case
				0: x_store_killed[S] = commit_kill_0[r_store_rd[S]];
				//1: x_store_killed[S]= commit_kill_1[r_store_rd[S]];
				default: x_store_killed[S] = 1'bx;
				endcase
				if (r_store_state[S]) begin
					c_store_running[S] = 1;
					c_store_running_trap_type[S] = 'bx;
					//casez ({r_store_control[S][5]&&(r_store_control[S][2:0] > 2), c_store_alignment_bad[S], ~wr_addr_ok[S], wr_prot[S]}) // synthesis full_case parallel_case
					casez ({r_store_control[S][5], c_store_alignment_bad[S], ~wr_addr_ok[S], wr_prot[S]}) // synthesis full_case parallel_case
					8'b0_1?_????:	c_store_running_trap_type[S] = 1; // alligned
					8'b0_00_1???,
					8'b0_00_??1?:	c_store_running_trap_type[S] = 3; // page fault
					8'b0_00_?1??,
					8'b0_01_????:	c_store_running_trap_type[S] = 2; // protection
					8'b1_??_????,
					8'b0_00_???1:	c_store_running_trap_type[S] = 0;  // no trap
					default:  c_store_running_trap_type[S] = 'bx; 
					endcase
					c_store_vm_pause[S] = (r_hart_vm_pause[r_store_hart[S]] || hart_vm_pause[r_store_hart[S]] || (|c_load_vm_stall)) && !x_store_killed[S]&&!r_store_control[S][5]; // must pause for load that stall in same clock
					c_store_allocate[S] = (c_store_running_trap_type[S] == 0) && !(wr_prot[S][3]&&!x_store_killed[S]&&!r_store_control[S][5]) && !(r_hart_vm_pause[r_store_hart[S]] || hart_vm_pause[r_store_hart[S]]) && !(|c_load_vm_stall);
					c_store_vm_stall[S] = wr_prot[S][3]&&!x_store_killed[S]&&!r_store_control[S][5]&&!(r_hart_vm_pause[r_store_hart[S]] || hart_vm_pause[r_store_hart[S]]) && !(|c_load_vm_stall);
					c_store_fence[S] = r_store_control[S][5];
				end else begin
					c_store_vm_pause[S] = 0;
					c_store_vm_stall[S] = 0;
					c_store_running[S] = 0;
					c_store_allocate[S] = 0;
					c_store_running_trap_type[S] = 2'bx;
					c_store_fence[S] = 1'bx;
				end
			end

			always @(posedge clk) begin
				r_store_state[S] <= c_store_state[S];
				r_store_rd[S] <= c_store_rd[S];
				r_store_makes_rd[S] <= c_store_makes_rd[S];
				r_store_rd2[S] <= r_store_rd[S];
				r_store_hart[S] <= istore_hart[S];
				r_store_hart2[S] <= r_store_hart[S];
				r_store_amo[S] <= istore_immed[S][31:27];
				r_store_fd[S] <= istore_immed[S][24:23];
				r_store_aq_rl[S] <= istore_control[S][5:4]!=0?istore_immed[S][26:25]:0;
				r_store_immed[S] <= istore_control[S][5:4]!=0?32'b0:istore_immed[S];
				r_store_control[S] <= istore_control[S];
				r_store_running[S] <= c_store_running[S];
				r_store_running_trap_type[S] <= c_store_running_trap_type[S];
				r_store_vm_stall[S] <= c_store_vm_stall[S];
				r_store_vm_pause[S] <= c_store_vm_pause[S];
`ifdef SIMD
				if (c_store_allocate[S] && simd_enable) $display("S%d %d %x a=%x m=%x d=%x",S[1:0], $time,r_store_rd[S],c_store_vaddr[S],c_store_mask[S],c_store_data[S]);
`endif
			end

			for (H = 0; H < NHART; H=H+1) begin
				assign h_store_vm_stall[H][S] = (r_store_hart[S]==H) && r_store_vm_stall[S];
			end

        end

		wire [NLDSTQ-1:0]q_allocate;
		wire [NLDSTQ-1:0]q_load;
        wire [NLDSTQ-1:0]q_store;
        wire [NLDSTQ-1:0]q_fence;
        wire [NPHYS-1:0]q_addr[0:NLDSTQ-1];
        wire [NLDSTQ-1:0]q_io;
        wire [5:0]q_amo[0:NLDSTQ-1];
        wire [RV-1:0]q_data[0:NLDSTQ-1];
        wire [(RV/8)-1:0]q_mask[0:NLDSTQ-1];
        wire [(NHART==1?0:LNHART-1):0]q_hart[0:NLDSTQ-1];
        wire [2:0]q_control[0:NLDSTQ-1];
        wire [LNCOMMIT-1:0]q_rd[0:NLDSTQ-1];
`ifdef FP
        wire [NLDSTQ-1:0]q_fp;
`endif
        wire [1:0]q_aq_rl[0:NLDSTQ-1];
        wire [1:0]q_fd[0:NLDSTQ-1];
        wire [NLDSTQ-1:0]q_hazard[0:NLDSTQ-1];
        wire [NLDSTQ-1:0]q_line_hit[0:NLDSTQ-1];
        wire [NLDSTQ-1:0]q_load_ack;
        wire [NLDSTQ-1:0]q_load_ack_fail;
        wire [NLDSTQ-1:0]q_makes_rd;
        wire [NLDSTQ-1:0]q_cache_miss;
		reg  [$clog2(NLOAD)-1:0]q_load_unit_s0;

		wire [1:0]q_fence_type[0:NLDSTQ-1];
		wire [1:0]fence_tlb_inv_type[0:NLDSTQ-1];
		reg [1:0]tlb_inv_type;
		wire [NLDSTQ-1:0]fence_tlb_invalidate;
		reg [VA_SZ-1:12]tlb_inv_addr;
		reg [15:0]tlb_inv_asid;
		reg [(NHART==1?0:LNHART-1):0]tlb_inv_hart;
	
		assign tlb_wr_invalidate = |fence_tlb_invalidate;
		assign tlb_wr_invalidate_addr = ~tlb_inv_type[1];
		assign tlb_wr_invalidate_asid = ~tlb_inv_type[0];
		assign tlb_wr_inv_vaddr = tlb_inv_addr;				   
		assign tlb_wr_inv_unified = unified_asid[tlb_inv_hart];
		assign tlb_wr_inv_asid = {unified_asid[tlb_inv_hart]?tlb_inv_asid[15]:tlb_inv_hart,tlb_inv_asid[14:0]};

`ifdef NSTORE2
		if (NLDSTQ == 8 && NLOAD == 2 && NSTORE == 2) begin
`include "mk13_8_2_2.inc"
		end
		if (NLDSTQ == 16 && NLOAD == 2 && NSTORE == 2) begin
`include "mk13_16_2_2.inc"
		end
`else
		if (NLDSTQ == 8 && NLOAD == 2 && NSTORE == 1) begin
`include "mk13_8_2_1.inc"
		end
		if (NLDSTQ == 16 && NLOAD == 2 && NSTORE == 1) begin
`include "mk13_16_2_1.inc"
		end
`endif
        wire [NLDSTQ-1:0]all_active;
        wire [NLDSTQ-1:0]store_mem_hit = dc_wr_hit_ok_write[0]?store_mem:0;

		wire [NLDSTQ-1:0]write_io_read_req, write_io_write_req;
		wire [NLDSTQ-1:0]write_io_lock;
		assign io_cpu_addr_req = (|write_io_read_req)|(|write_io_write_req);
		assign io_cpu_addr = write_mem_addr[r_ldstq_in];
		assign io_cpu_read = |write_io_read_req;
		assign io_cpu_lock = |write_io_lock;
		assign io_cpu_mask = write_mem_mask[r_ldstq_in];
		reg [RV-1:0]c_io_cpu_wdata; 
		assign io_cpu_wdata = c_io_cpu_wdata;

		
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

			wdata = write_mem_data[r_ldstq_in];
			c_io_cpu_wdata = 'bx;
			casez (write_mem_amo[r_ldstq_in]) // synthesis full_case parallel_case
			default:    c_io_cpu_wdata = wdata;
			6'b001??_1: c_io_cpu_wdata = wdata^r_io_data;			
			6'b011??_1: c_io_cpu_wdata = wdata&r_io_data;			
			6'b010??_1: c_io_cpu_wdata = wdata|r_io_data;			
			endcase
		end

		for (I = 0; I < NLDSTQ; I=I+1) begin: sq
			ldstq #(.RV(RV), .ADDR(I), .NHART(NHART), .NPHYS(NPHYS), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .LNHART(LNHART), .NLDSTQ(NLDSTQ), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))s(.clk(clk), .reset(reset),
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
					.line_hit(q_line_hit[I]),
					.all_store_mem(store_mem_hit),
					.cache_miss(q_cache_miss[I]),

					.commit_0(store_commit_0),
					//.commit_1(store_commit_1),
					.commit_kill_0(commit_kill_0),
					//.commit_kill_1(commit_kill_1),
					.commit_completed_0(commit_completed_0),
					//.commit_completed_1(commit_completed_1),
					.commit_commitable_0(commit_commitable_0),
					//.commit_commitable_1(commit_commitable_1),

					.snoop_data(load_snoop_data[I]),

					.snoop_addr_0(c_load_paddr[0][NPHYS-1:$clog2(RV/8)]),
					.snoop_io_0(c_load_io[0]),
					.snoop_mask_0(c_load_mask[0]),
					.snoop_hart_0(r_load_hart[0]),
					.snoop_hit_0(load_snoop_hit[0][I]),
					.snoop_hazard_0(load_snoop_hazard[0][I]),
					.snoop_line_hit_0(load_snoop_line_hit[0][I]),

					.snoop_addr_1(c_load_paddr[1][NPHYS-1:$clog2(RV/8)]),
					.snoop_io_1(c_load_io[1]),
					.snoop_mask_1(c_load_mask[1]),
					.snoop_hart_1(r_load_hart[1]),
					.snoop_hit_1(load_snoop_hit[1][I]),
					.snoop_hazard_1(load_snoop_hazard[1][I]),
					.snoop_line_hit_1(load_snoop_line_hit[1][I]),

					.lr_valid(r_reserved_address_set[write_mem_hart[I]] && (r_reserved_address[write_mem_hart[I]]==write_mem_addr[I][NPHYS-1:ACACHE_LINE_SIZE]) && !write_mem_io[I]),

					.wsnoop_addr_0(c_store_paddr[0][NPHYS-1:$clog2(RV/8)]),
					.wsnoop_io_0(c_store_io[0]),
					.wsnoop_line_hit_0(store_snoop_line_hit[0][I]),

					.load_ready(load_ready[I]),
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
					.io_cpu_addr_ack(io_cpu_addr_ack),
					.io_cpu_data_req(io_cpu_data_req),

					.fence_type(q_fence_type[I]),
					.tlb_invalidate(fence_tlb_invalidate[I]),
					.tlb_inv_type(fence_tlb_inv_type[I]),

					.first(r_ldstq_in==I),
					.write_mem(store_mem[I]),
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
					.new_active(wq_new_active[I]),
					.all_active(all_active),
					.free(free[I])
				);
		end
		assign dc_wr_enable[0] = |store_mem;
		assign dc_wr_addr[0] = q_mem_addr[NPHYS-1:(RV==64?3:2)];
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
		end 
		if (NLDSTQ == 32) begin
`include "mk16_32.inc"
		end 

		for (H = 0; H < NHART; H=H+1) begin

			always @(*) begin
					c_reserved_address[H] = r_reserved_address[H];
					c_reserved_address_set[H] = r_reserved_address_set[H];
				
					// need a loop over NLOAD here - FIXME	
					if (r_load_state[1] && dc_rd_hit[1] && dc_rd_hart[1] == H && dc_rd_lr[1] && !c_load_allocate[1] && !r_load_sc[1]) begin
						c_reserved_address[H] = dc_rd_addr[1][NPHYS-1:ACACHE_LINE_SIZE];
						c_reserved_address_set[H] = 1;
					end else
					if (r_load_state[0] && dc_rd_hit[0] && dc_rd_hart[0] == H && dc_rd_lr[0] && !c_load_allocate[0] && !r_load_sc[0]) begin
						c_reserved_address[H] = dc_rd_addr[0][NPHYS-1:ACACHE_LINE_SIZE];
						c_reserved_address_set[H] = 1;
					end 
					if ((dc_wr_enable[0] && dc_wr_addr[0][NPHYS-1:ACACHE_LINE_SIZE] == c_reserved_address[H] && (dc_wr_hart[0] != H )) || // invalidate when line written by other hart 
					    (dc_wr_enable[0] && dc_wr_hart[0] == H && dc_wr_sc[0]) || // invalidate when SC occurs
					    (dc_snoop_addr_req && dc_snoop_addr_ack && c_reserved_address[H] == dc_snoop_addr && (dc_snoop_snoop==SNOOP_READ_EXCLUSIVE||dc_snoop_snoop==SNOOP_READ_INVALID))) begin	// invalidate when line is stolen
							c_reserved_address_set[H] = 0;
					end
			end

			always @(posedge clk) begin
				r_reserved_address[H] <= c_reserved_address[H];
				r_reserved_address_set[H] <= !reset&&c_reserved_address_set[H];
			end
				
		end

	endgenerate

	//assign dc_snoop_addr_ack = !dc_wr_enable[0] && !dc_wr_amo[0];	// AMO snoop stall
	assign dc_snoop_addr_ack = !dc_wr_enable[0];	// write snoop stall

	reg [$clog2(NLOAD)-1:0]r_load_unit_s0;
	always @(posedge clk)
		r_load_unit_s0 <= q_load_unit_s0;

	//
	//	AMO data path
	reg [RV-1:0]wdata[0:NSTORE-1];
	for (S = 0; S < NSTORE; S=S+1) begin
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

				dc_rd = dc_rd_data[r_load_unit_s0];

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

	dcache_l1   #(.RV(RV), .NPHYS(NPHYS), .TRANS_ID_SIZE(TRANS_ID_SIZE), .NLDSTQ(NLDSTQ), .CACHE_LINE_SIZE(CACHE_LINE_SIZE), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE))dc(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
			.xxtrig(xxtrig),
			.dc_trig(dc_trig),
`endif
`ifdef SIMD
			.simd_enable(simd_enable),
`endif
			.raddr0(dc_rd_addr[0]),
			.rhit0(dc_rd_hit[0]),
			.rhit_need_o0(dc_rd_hit_need_o[0]),
			.rdata0(dc_rd_data[0]),
	
			.raddr1(dc_rd_addr[1]),
			.rhit1(dc_rd_hit[1]),
			.rhit_need_o1(dc_rd_hit_need_o[1]),
			.rdata1(dc_rd_data[1]),

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

	

	//
	//	this is the VM TLB queue - a queue of pending L1 TLB fill requests 
	//		there's room here for (worst case) NLOAD+NSTORE in one hart queued in 2 clocks and NLOAD+NSTORE
	//		queued from the other hart in the next clock. 
	//		while the first are being resolved
	//

	parameter VMQ_LEN = 2*NHART*(NLOAD+NSTORE);

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
	wire [NSTORE+NLOAD-1:0]tlb_rd_stall = {c_store_vm_stall, c_load_vm_stall};	// true when a unit has a VM miss
	wire     [LNCOMMIT-1:0]tlb_rd_commit[0:NSTORE+NLOAD-1];
	wire[(NHART==1?0:LNHART-1):0]tlb_rd_hart[0:NSTORE+NLOAD-1];

	// tlb_rd_vaddr
	// tlb_rd_asid
	// 
	generate
		for (L = 0; L < NLOAD; L=L+1) begin
			assign tlb_rd_vaddr[L] = c_load_vaddr[L][RV-1:12];
			assign tlb_rd_hart[L] = r_load_hart[L];
			assign tlb_rd_commit[L] = r_load_rd[L];
		end
		for (S = 0; S < NSTORE; S=S+1) begin
			assign tlb_rd_vaddr[NLOAD+S] = c_store_vaddr[S][RV-1:12];
			assign tlb_rd_hart[NLOAD+S] = r_store_hart[S];
			assign tlb_rd_commit[NLOAD+S] = r_store_rd[S];
		end
	endgenerate

	// 'packed' versions of the above
	reg [NSTORE+NLOAD-1:0]cv_stall;		// true when a unit has a VM miss
	reg     [LNCOMMIT-1:0]cv_commit[0:NSTORE+NLOAD-1];
	reg[(NHART==1?0:LNHART-1):0]cv_hart[0:NSTORE+NLOAD-1];
	reg        [VA_SZ-1:0]cv_vaddr[0:NSTORE+NLOAD-1];
	reg            [15: 0]cv_asid[0:NSTORE+NLOAD-1];


	wire	[VMQ_LEN-1:0]vmq_match;
	reg		[VMQ_LEN-1:0]vmq_kill;
	reg [$clog2(VMQ_LEN)-1:0]vmq_first;
	wire vmq_shift = (r_vmq_addr_req&&tlb_d_addr_ack&&!tlb_d_addr_cancel)||(r_vmq_valid[0]&r_vmq_duplicate[0]&!tlb_d_data_req);

	wire [VMQ_LEN-1:0]vmq_hart_busy[0:NHART-1];
wire [VMQ_LEN-1:0]vmq_hart_busy_0=vmq_hart_busy[0];

	genvar V;
	generate
		if (NHART == 1) begin
			if (NLOAD == 2 && NSTORE == 1) begin
`include "mk17_1_2_1.inc"
			end else
			if (NLOAD == 3 && NSTORE == 2) begin
`include "mk17_1_3_2.inc"
			end else
			if (NLOAD == 2 && NSTORE == 2) begin
`include "mk17_1_2_2.inc"
			end 
		end else
		if (NHART == 2) begin
			if (NLOAD == 3 && NSTORE == 2) begin
`include "mk17_2_3_2.inc"
			end else
			if (NLOAD == 2 && NSTORE == 2) begin
`include "mk17_2_2_2.inc"
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

		for (H = 0; H < NHART; H=H+1) begin
			assign vm_busy[H] = (r_vmq_pending_valid&&(r_vmq_pending_hart==H)) ||  ( | vmq_hart_busy[H]);
		end
	endgenerate

	reg		r_vmq_addr_req;
	wire	c_vmq_addr_req = c_vmq_valid[0] && !tlb_d_addr_cancel && !c_vmq_duplicate[0] && (!c_vmq_pending_valid || c_vmq_pending_addr!=c_vmq_addr[0] || c_vmq_hart[0]!=c_vmq_pending_hart);

	assign tlb_d_asid     = r_vmq_asid[0];
	assign tlb_d_vaddr    = r_vmq_addr[0];
	assign tlb_d_hart     = r_vmq_hart[0];
	assign tlb_d_addr_tid = r_vmq_commit[0];
	assign tlb_d_addr_req = r_vmq_addr_req && !tlb_d_addr_cancel && !vmq_kill[0];

	reg vmq_done_kill;

	assign vm_done		= ((tlb_d_data_req && !vmq_done_kill) || (r_vmq_valid[0] && r_vmq_duplicate[0]));
	assign vm_done_fail = (tlb_d_data_req?!tlb_d_valid: 0);
	assign vm_done_pmp  = (tlb_d_data_req?!tlb_d_valid&tlb_d_pmp_fail:0);
	assign vm_done_hart = (tlb_d_data_req ? r_vmq_pending_hart: r_vmq_hart[0]);	// FIXME
	assign vm_done_commit = (tlb_d_data_req ?tlb_d_data_tid : r_vmq_commit[0]);

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

	dtlb		#(.RV(RV), .VA_SZ(VA_SZ), .NHART(NHART), .LNHART(LNHART), .NPHYS(NPHYS), .TLB_SETS(0), .TLB_ENTRIES(32))tlb(.clk(clk), .reset(reset),
			.rd_enable_0(tlb_rd_enable[0]),
			.rd_vaddr_0(tlb_rd_vaddr[0]),
			.rd_asid_0(tlb_rd_asid[0]),
			.rd_valid_0(tlb_rd_valid[0]),
			.rd_2mB_0(tlb_rd_2mB[0]),
			.rd_4mB_0(tlb_rd_4mB[0]),
			.rd_1gB_0(tlb_rd_1gB[0]),
			.rd_512gB_0(tlb_rd_512gB[0]),
			.rd_paddr_0(tlb_rd_paddr[0]),
			.rd_aduwrx_0(tlb_rd_aduwrx[0]),

			.rd_enable_1(tlb_rd_enable[1]),
			.rd_vaddr_1(tlb_rd_vaddr[1]),
			.rd_asid_1(tlb_rd_asid[1]),
			.rd_valid_1(tlb_rd_valid[1]),
			.rd_2mB_1(tlb_rd_2mB[1]),
			.rd_4mB_1(tlb_rd_4mB[1]),
			.rd_1gB_1(tlb_rd_1gB[1]),
			.rd_512gB_1(tlb_rd_512gB[1]),
			.rd_paddr_1(tlb_rd_paddr[1]),
			.rd_aduwrx_1(tlb_rd_aduwrx[1]),

			.rd_enable_2(tlb_rd_enable[2]),
			.rd_vaddr_2(tlb_rd_vaddr[2]),
			.rd_asid_2(tlb_rd_asid[2]),
			.rd_valid_2(tlb_rd_valid[2]),
			.rd_2mB_2(tlb_rd_2mB[2]),
			.rd_4mB_2(tlb_rd_4mB[2]),
			.rd_1gB_2(tlb_rd_1gB[2]),
			.rd_512gB_2(tlb_rd_512gB[2]),
			.rd_paddr_2(tlb_rd_paddr[2]),
			.rd_aduwrx_2(tlb_rd_aduwrx[2]),

`ifdef NSTORE2
			.rd_enable_3(tlb_rd_enable[3]),
			.rd_vaddr_3(tlb_rd_vaddr[3]),
			.rd_asid_3(tlb_rd_asid[3]),
			.rd_valid_3(tlb_rd_valid[3]),
			.rd_2mB_3(tlb_rd_2mB[3]),
			.rd_4mB_3(tlb_rd_4mB[3]),
			.rd_1gB_3(tlb_rd_1gB[3]),
			.rd_512gB_3(tlb_rd_512gB[3]),
			.rd_paddr_3(tlb_rd_paddr[3]),
			.rd_aduwrx_3(tlb_rd_aduwrx[3]),
`endif

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
            .reset(reset),
			.xxtrig(xxtrig),
			.cpu_trig(cpu_trig),
			.cpu_trig_ack(cpu_trig_ack),
			.trig_out(ls_trig_out),
			.trig_out_ack(ls_trig_out_ack),
            .load_enable0(load_enable_0),
			.immed_0(r_load_immed[0][15:0]),
            .load_rd0(load_rd_0),
            .load_ctrl0(load_control_0),
			.load_rs0(load_r1_0[31:0]), 
            .load_vaddr0(c_load_vaddr[0][31:0]),
            .load_paddr_0(c_load_paddr[0][31:0]),
			.dc_rd_hit_0(dc_rd_hit[0]),
            .load_done0(load_done_0),
            .load_vm_stall_0(load_vm_stall_0),
			.load_done_commit_0(load_done_commit_0),
            .load_enable1(load_enable_1),
            .load_rd1(load_rd_1),
            .load_ctrl1(load_control_1),
            .load_rs1(load_r1_1[31:0]),
            .load_vaddr1(c_load_vaddr[1][31:0]),
            .load_paddr_1(c_load_paddr[1][31:0]),
			.dc_rd_hit_1(dc_rd_hit[1]),
            .load_done1(load_done_1),
            .load_vm_stall_1(load_vm_stall_1),
			.load_done_commit_1(load_done_commit_1),
            .store_enable0(store_enable_0),
            .store_rd0(store_rd_0),
            .store_ctrl0(store_control_0),
            .store_addr0(c_store_paddr[0][23:0]),
			.dc_wr_hit_ok_write(dc_wr_hit_ok_write[0]),
            .dc_wr_hit_must_invalidate(dc_wr_hit_must_invalidate[0]),
            .store_rs0(store_r1_0[23:0]),
            .store_data0(store_r2_0[7:0]),
            .store_running0(store_running_0),
			.store_running_commit_0(store_running_commit_0),
            .store_vm_stall_0(store_vm_stall_0),
            .store_running_trap_type_0(store_running_trap_type_0),
            .ldstq_in(r_ldstq_in),
            .ldstq_out(r_ldstq_out),
            .io_cpu_addr_req(io_cpu_addr_req),
            .io_cpu_addr(io_cpu_addr[23:0]),
            .io_cpu_read(io_cpu_read),
            .io_cpu_data_req(io_cpu_data_req),
            .io_cpu_data_ack(io_cpu_data_ack),
            .vm_busy(vm_busy[0]),
			.dc_raddr(dc_raddr[23+ACACHE_LINE_SIZE:ACACHE_LINE_SIZE]),
            .dc_raddr_req(dc_raddr_req),
            .dc_raddr_ack(dc_raddr_ack),
            .dc_raddr_trans(dc_raddr_trans[$clog2(NLDSTQ)-1:0]),
            .dc_raddr_snoop(dc_raddr_snoop),
            .dc_rdata_req(dc_rdata_req),
            .dc_rdata_ack(dc_rdata_ack),
            .dc_rdata_trans(dc_rdata_trans[$clog2(NLDSTQ)-1:0]),
            .dc_rdata_resp(dc_rdata_resp),
            .vm_done(vm_done),
            .vm_done_fail(vm_done_fail),
            .vm_done_pmp(vm_done_pmp),
            .vm_done_commit(vm_done_commit),
            .tlb_d_addr_req(tlb_d_addr_req),
            .tlb_d_addr_ack(tlb_d_addr_ack),
            .tlb_d_addr_cancel(tlb_d_addr_cancel),
            .tlb_d_data_req(tlb_d_data_req),
            .tlb_d_data_tid(tlb_d_data_tid),
            .tlb_d_data_vaddr(tlb_d_data_vaddr),
            .tlb_d_gaduwrx(tlb_d_gaduwrx),
            .tlb_d_valid(tlb_d_valid));

        ila_ls2 ila_ls2(.clk(clk),
            .trig_in(ls_trig_out),
            .trig_in_ack(ls_trig_out_ack),
            .xxtrig(xxtrig),
            .r_vmq_addr_req(r_vmq_addr_req),
            .r_vmq_pending_valid(r_vmq_pending_valid),
            .r_vmq_pending_commit(r_vmq_pending_commit),
			.r_vmq_pending_addr(r_vmq_pending_addr),
            .r_vmq_valid0(r_vmq_valid[0]),
            .r_vmq_commit0(r_vmq_commit[0]),
            .r_vmq_duplicate0(r_vmq_duplicate[0]),
            .r_vmq_valid1(r_vmq_valid[1]),
            .r_vmq_commit1(r_vmq_commit[1]),
            .r_vmq_duplicate1(r_vmq_duplicate[1]),
            .t_d_addr_req(tlb_d_addr_req),
            .t_d_addr_ack(tlb_d_addr_ack),
            .t_d_data_req(tlb_d_data_req),
            .t_d_addr_cancel(tlb_d_addr_cancel),
            .commit_kill_0(commit_kill_0),
            .vmq_first(vmq_first),
            .vmq_shift(vmq_shift),
            .vm_kill0(vmq_kill[0]),
            .load_enable0(load_enable_0),
            .load_rd0(load_rd_0),   // 5
			.rd_mprv0(rd_mprv[0]),
            .load_done0(load_done_0),
            .load_pending_0(load_pending_0),
            .load_vm_stall_0(load_vm_stall_0),
            .load_vm_pause_0(load_vm_pause_0),
            .load_enable1(load_enable_1),
            .load_rd1(load_rd_1),   // 5
			.rd_mprv1(rd_mprv[1]),
            .load_done1(load_done_1),
            .load_pending_1(load_pending_1),
            .load_vm_stall_1(load_vm_stall_1),
            .load_vm_pause_1(load_vm_pause_1),
            .store_enable_0(store_enable_0),
            .store_vaddr0(c_store_vaddr[0][31:0]),  // 32
            .store_paddr0(c_store_paddr[0][23:0]),  // 24
            .store_data0(istore_r2[0][15:0]),   // 16
            .store_rd_0(store_rd_0),        // 5
            .store_running_0(store_running_0),
            .store_running_trap_type_0(store_running_trap_type_0),  // 2
            .store_running_commit_0(store_running_commit_0),    // 5
            .store_vm_stall_0(store_vm_stall_0),
            .store_vm_pause_0(store_vm_pause_0),
			.r_load_state0(r_load_state[0]),
            .r_load_state1(r_load_state[1]),
            .r_load_done_commit0(r_load_done_commit[0]), // 5
            .r_load_done_commit1(r_load_done_commit[1]), // 5
            .r_load_rd0(r_load_rd[0]), //5
            .r_load_queued0(r_load_queued[0]),
            .r_load_queued1(r_load_queued[1]),
            .dc_rd_hit0(dc_rd_hit[0]),
            .load_ready(load_ready),        // 8
            .q_load_ack(q_load_ack),        // 8
            .q_load_ack_fail(q_load_ack_fail),      // 8
			.c_load_queued_ready(c_load_queued_ready), // 2
			.r_load_amo(r_load_amo),        //2
			.wq_control(wq_control[c_load_queued_index[0]]),    // 4
			.write_mem_amo(write_mem_amo[c_load_queued_index[0]]),      // 6
			.c_res_makes_rd(c_res_makes_rd[0][0]),
			.r_load_makes_rd0(r_load_makes_rd[0]),
			.store_makes_rd_0(store_makes_rd_0),
			.c_load_queued_index0(c_load_queued_index[0]),  // 3
			.wq_makes_rd(wq_makes_rd), // 8
			.dc_rd_lr({dc_rd_hit_need_o,dc_rd_lr})); //4

        ila_ls3 ila_ls3(.clk(clk),
            .xxtrig(xxtrig),

            .load_enable0(load_enable_0),
            .load_rd0(load_rd_0),                   // 5
            .load_vaddr0(c_load_vaddr[0][31:0]),    // 32
            .load_paddr_0(c_load_paddr[0][31:0]),   // 32
            .c_load_allocate0(c_load_allocate[0]),
            .dc_rd_hit_0(dc_rd_hit[0]),
            .load_snoop_hit_0(load_snoop_hit[0]),   // 8
            .load_hazard_0(load_hazard[0]),
            .load_done0(load_done_0),
			.load_res0(r_res[0]), // 32
            .load_vm_stall_0(load_vm_stall_0),
            .load_done_commit_0(load_done_commit_0),// 5

            .load_enable1(load_enable_1),
            .load_rd1(load_rd_1),
            .load_vaddr1(c_load_vaddr[1][31:0]),
            .load_paddr_1(c_load_paddr[1][31:0]),
            .c_load_allocate1(c_load_allocate[1]),
            .dc_rd_hit_1(dc_rd_hit[1]),
            .load_snoop_hit_1(load_snoop_hit[1]),
            .load_hazard_1(load_hazard[1]),
            .load_done1(load_done_1),
			.load_res1(r_res[1]), // 32
            .load_vm_stall_1(load_vm_stall_1),
            .load_done_commit_1(load_done_commit_1),

            .store_enable_0(store_enable_0),
            .store_vaddr0(c_store_vaddr[0][31:0]),  // 32
            .store_paddr0(c_store_paddr[0][31:0]),  // 32
            .store_data0(istore_r2[0][31:0]),   // 32
            .store_rd_0(store_rd_0),        // 5
            .store_running_0(store_running_0),
            .store_running_trap_type_0(store_running_trap_type_0),  // 2
            .store_running_commit_0(store_running_commit_0)    // 5
        );

    wire [3:0]xxtrig_sel;
    wire [31:0]xxtrig_cmp;
    wire [15:0]xxtrig_count;
    wire [39:0]xxtrig_ticks;


    reg xls_trig;
    assign ls_trig=xls_trig;
    always @(*)
    case (xxtrig_sel)
    0: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0];
    1: xls_trig = r_store_state[0] && c_store_paddr[0][31:0] == xxtrig_cmp[31:0];
    2: xls_trig = r_load_state[0] && c_load_vaddr[0][31:0] == xxtrig_cmp[31:0];
    3: xls_trig = r_load_state[0] && c_load_paddr[0][31:0] == xxtrig_cmp[31:0];
    4: xls_trig = r_load_state[1] && c_load_vaddr[1][31:0] == xxtrig_cmp[31:0];
    5: xls_trig = r_load_state[1] && c_load_paddr[1][31:0] == xxtrig_cmp[31:0];
    6: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][15:0] == xxtrig_count[15:0];
    7: xls_trig = r_store_state[0] && c_store_paddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][15:0] == xxtrig_count[15:0];
    8: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][31:0] == xxtrig_ticks[31:0];
    9: xls_trig = r_store_state[0] && c_store_paddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][31:0] == xxtrig_ticks[31:0];
    10: xls_trig = r_store_state[0] && c_store_vaddr[0][31:0] == xxtrig_cmp[31:0] && istore_r2[0][7:0] == xxtrig_count[7:0];
    11: xls_trig = r_store_state[0] && istore_r2[0][31:0] == xxtrig_cmp[31:0];
    12: xls_trig = r_store_state[0] && c_store_vaddr[0][31:3] == xxtrig_cmp[31:3];
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
            .ldstq_in(r_ldstq_in),
            .ldstq_out(r_ldstq_out),
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
	input  [NLDSTQ-1:0]line_hit,
	input  [NLDSTQ-1:0]all_store_mem,
	input  [NLDSTQ-1:0]all_active,
	input  [NLDSTQ-1:0]new_active,
	input		lr_valid,
	input		cache_miss,
					
	input [NCOMMIT-1:0]commit_0,	// per-hart commit
	//input [NCOMMIT-1:0]commit_1,
	input [NCOMMIT-1:0]commit_completed_0,	// per-hart commit
	//input [NCOMMIT-1:0]commit_completed_1,
	input [NCOMMIT-1:0]commit_kill_0,	// per-hart commit
	//input [NCOMMIT-1:0]commit_kill_1,
	input [NCOMMIT-1:0]commit_commitable_0,
	//input [NCOMMIT-1:0]commit_commitable_1,
					
	output [RV-1:0]snoop_data,
	input [NPHYS-1:$clog2(RV/8)]snoop_addr_0,
	input       snoop_io_0,
	input [RV/8-1:0]snoop_mask_0,
	input [(NHART==1?0:LNHART-1):0]snoop_hart_0,
	output 		snoop_hit_0,
	output		snoop_hazard_0,
	output		snoop_line_hit_0,

	input [NPHYS-1:$clog2(RV/8)]snoop_addr_1,
	input       snoop_io_1,
	input [RV/8-1:0]snoop_mask_1,
	input [(NHART==1?0:LNHART-1):0]snoop_hart_1,
	output 		snoop_hit_1,
	output		snoop_hazard_1,
	output		snoop_line_hit_1,

	input [NPHYS-1:$clog2(RV/8)]wsnoop_addr_0,
	input		wsnoop_io_0,
	output		wsnoop_line_hit_0,

	input 		first,
	output		write_mem,
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

	output		active,
	output 		free
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
	reg 		   r_commit, c_commit;
	reg 		   r_killed, c_killed;
	reg 		   r_cache_miss, c_cache_miss;
	reg  [NLDSTQ-1:0]r_hazard, c_hazard;
	reg  [NLDSTQ-1:0]r_line_hit, c_line_hit;

	wire [3:0]pred = r_amo[4:1];		// fence predecessors IORW
	wire [3:0]succ = {r_aq_rl, r_fd};	// fence successors	  IORW
	

	wire fence_against_following_reads = (r_valid&&r_store&&r_amo[0]&&r_aq_rl[1]) ||
								         (r_valid&&r_load&&r_amo[0]&&r_aq_rl[1]);

	assign wsnoop_line_hit_0 = r_valid&&!r_killed&&!r_fence&&(wsnoop_addr_0[NPHYS-1:ACACHE_LINE_SIZE]==r_addr[NPHYS-1:ACACHE_LINE_SIZE]) && !r_io && !wsnoop_io_0;

	wire snoop_match_0 = r_valid&&!r_killed&&r_store&&(snoop_addr_0==r_addr[NPHYS-1:$clog2(RV/8)]) && !snoop_io_0&& !r_io;
//always @(snoop_match_0) if (ADDR<=1)$displayb(ADDR,,"c_valid=",c_valid," c_load=",c_load," c_fence=",c_fence," snoop_addr_0=",snoop_addr_0," c_addr=",c_addr);
	assign snoop_hit_0 = snoop_match_0&&((snoop_mask_0&r_mask)!=0);
//always @(snoop_hit_0) if (ADDR<=1) $displayb(ADDR,,"snoop_match_0=",snoop_match_0," snoop_mask_0=",snoop_mask_0," c_mask=",c_mask);
	assign snoop_hazard_0 = snoop_match_0&&(((snoop_mask_0&r_mask)!=snoop_mask_0)||(r_amo[0])) ||
							fence_against_following_reads ||
							(r_valid&&r_fence&&succ[1]&&!snoop_io_0)||
							(r_valid&&r_fence&&succ[3]&&snoop_io_0)||
							(r_valid && r_io && snoop_io_0);
	assign snoop_line_hit_0 = r_valid&&!r_killed&&!r_fence&&(snoop_addr_0[NPHYS-1:ACACHE_LINE_SIZE]==r_addr[NPHYS-1:ACACHE_LINE_SIZE]) && !snoop_io_0 && !r_io;

	wire snoop_match_1 = r_valid&&!r_killed&&r_store&&(snoop_addr_1==r_addr[NPHYS-1:$clog2(RV/8)]) && !snoop_io_1&& !r_io;
	assign snoop_hit_1 = snoop_match_1&&((snoop_mask_1&r_mask)!=0);
	assign snoop_hazard_1 = snoop_match_1&&(((snoop_mask_1&r_mask)!=snoop_mask_1)||(r_amo[0])) ||
							fence_against_following_reads ||
							(r_valid&&r_fence&&succ[1]&&!snoop_io_1)||
							(r_valid&&r_fence&&succ[3]&&snoop_io_1) ||
							(r_valid && r_io && snoop_io_1);
	assign snoop_line_hit_1 = r_valid&&!r_killed&&!r_fence&&(snoop_addr_1[NPHYS-1:ACACHE_LINE_SIZE]==r_addr[NPHYS-1:ACACHE_LINE_SIZE]) && !snoop_io_1 && !r_io;

	assign snoop_data = r_data;

	assign write_data = r_data;
	assign write_mask = r_mask;
	assign write_addr = r_addr;
	assign write_io = r_io;
	reg commit, killed, commitable;
	reg r_free, c_free;
	reg free_out;
	assign free = free_out;

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
	reg		r_waiting_line_hit, c_waiting_line_hit;
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


	assign mem_read_req = r_waiting_memory&!r_acked&!killed || r_send_cancel;
	assign mem_write_req = r_store&r_cache_miss&!r_acked;
	assign mem_write_invalidate = r_cache_invalidate;
	assign mem_read_cancel = r_send_cancel;

	reg do_write_amo;
	reg r_do_write_sc, c_do_write_sc;
	assign write_mem = !reset && !r_io && r_store && (!r_amo[0]?1'b1:((r_amo[2:1]==2'b11)? lr_valid:do_write_amo)) && !allocate && first && (r_do_write_sc|do_write_amo|c_commit) && !r_cache_miss && !c_killed;
	always @(*) begin
		if (reset || allocate || !r_valid) begin
			free_out = 0;
		end else
		casez ({r_store, r_fence, r_load}) // synthesis full_case parallel_case
		3'b1??: free_out = (r_free || (first && ((killed&!c_commit&r_valid)|r_killed)) || write_done ||
						   (r_load_acked&((!load_ack_fail&&write_done)||r_amo[2:0]==3'b111)&&first));
		3'b?1?:	if (r_control[2:0] < 3) begin
					free_out = first && ((c_killed&(completed|!c_commit)&r_valid) || r_killed ||  r_free || r_tlb_invalidate || tlb_invalidate);
				end else begin
					free_out = first && (r_load_acked || r_control[2:0]==4 || ((r_killed || killed)&&r_valid));
				end
		3'b??1: free_out = first && c_killed && !c_send_cancel;
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
		c_line_hit = r_line_hit&all_active;
		c_load_ready = 0;
		c_load_acked = r_load_acked;
		c_last_load_acked = 0;
		c_cache_miss = r_cache_miss&!reset;
		c_cache_invalidate = r_cache_invalidate;
		c_store_cond = r_store_cond;
		c_store_cond_okv = r_store_cond_okv;
		//write_mem_out = 0;
		c_free = 0;
		write_done = 0;
		c_send_cancel = r_send_cancel&!c_acked;
		c_waiting_hazard = r_waiting_hazard;
		c_waiting_line_hit = r_waiting_line_hit;
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
			c_line_hit = line_hit&(all_active|new_active);
			c_cache_miss = cache_miss;
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
			c_waiting_hazard = (hazard!=0 || amo[0]) && load;
			c_waiting_line_hit = (line_hit&(all_active|new_active))!=0 &&load;
			c_waiting_memory = ((!c_waiting_line_hit&&!c_waiting_hazard))&&cache_miss;
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
						if (r_io) begin
							if (first&(c_commit|r_commit)&!(r_killed|killed)) begin 
								c_write_io_write_req = 1;
								if (io_cpu_addr_ack) begin
									c_free = 1;
									write_done = 1;
								end
							end
						end else begin
							write_done = write_mem&&!write_wait&&write_ok_write&&!write_must_invalidate; 
							if (write_mem && !write_wait) begin
								if ( !write_ok_write || write_must_invalidate ) begin
									c_cache_miss = 1;
									c_cache_invalidate = write_must_invalidate;
									c_acked = 0;
								end
							end else
							if (mem_read_done)
								c_cache_miss = 0;
							c_free = first && (r_commit|((commit)&r_valid)) && !c_cache_miss && write_done;
						end
					end
				5'b111??:		// sc	- MUST be handled at first
					begin
						c_killed = !c_commit&(r_killed|killed);
						c_load_acked = r_load_acked|load_ack;
						if (r_io) begin
							if (first) begin 
								c_load_ready = 1;
								c_store_cond = 1;
								c_store_cond_okv = 1;
								write_done = r_load_acked;
								c_free = r_load_acked;
							end	
						end else begin
							if (r_store_cond) begin
								c_load_ready = !r_load_acked;
								write_done = r_load_acked;
								c_store_cond_okv = r_store_cond_okv|load_ack_fail;
							end else
							if (!lr_valid && first) begin
								c_load_ready = 1;
								c_store_cond = 1;
								c_store_cond_okv = 1;
							end else
							if (write_mem) begin
								c_load_ready = 1;
								c_store_cond = 1;						
								c_store_cond_okv = r_store_cond_okv || !(!write_wait&&write_ok_write&&!write_must_invalidate);
							end else begin
								c_do_write_sc = first;
							end
							c_free = first && (r_commit|((commit)&r_valid)) && !c_cache_miss;
						end
					end
				5'b101??:		// store.amo	- MUST be handled at first 
					begin
						c_killed = !c_commit&(r_killed|killed);
						if (r_io) begin
							if (first) begin 
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
							end
						end else begin
							if (r_cache_miss) begin		// waiting for cache line fetch
								c_load_acked = 0;
								if (mem_read_done) begin
									c_cache_miss = 0;
									c_load_ready = first;
									c_load_acked = r_load_acked|load_ack;
								end
							end else
							if (r_load_acked) begin	// waiting for load unit
								c_load_acked = 0;
								if (load_ack_fail) begin		// cache miss do a write
									c_cache_miss = 1;
									c_cache_invalidate = 0;
									c_acked = 0;
								end else begin
									do_write_amo = 1;
									if (!write_ok_write) begin		// cache miss do an update
										c_cache_miss = 1;
										c_cache_invalidate = write_must_invalidate;
										c_acked = 0;
									end else begin
										write_done = 1;
									end
								end
							end else begin
								c_load_ready = first;
								c_load_acked = r_load_acked|load_ack;
							end
							c_free = first && (r_commit|((commit)&r_valid)) && !c_cache_miss;
						end
					end
				5'b???1?:		// fence
					begin
						c_killed = r_killed || (killed);
						if (r_killed || (killed)) begin
							c_free = first&r_valid;
						end else
						if (r_control[2:0] < 3) begin
							c_free = completed && r_valid;
						end else begin
                            c_load_acked = r_load_acked|load_ack;
                            c_load_ready = first&&r_control[2:0]!= 4;
                            c_store_cond = first&&r_control[2:0]!= 4;
                            c_free = first && (r_commit|((commit)&r_valid)) && !c_cache_miss;
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
							if (first&&commitable) begin 
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
							casez ({r_last_load_acked, r_waiting_hazard, r_waiting_line_hit, r_waiting_memory, r_ack_waiting, r_send_cancel}) // synthesis full_case parallel_case
							6'b1?????:begin
										if (!load_ack_fail) begin
											c_killed = 1;
										end else
										if (r_line_hit != 0) begin
											c_line_hit = r_line_hit&all_active;
											if ((r_line_hit&all_active) == 0) begin
												c_load_ready = !(killed||r_killed);
											end else begin
												c_waiting_line_hit = 1;
												c_load_acked = 0;
											end
										end else begin
											c_cache_miss = 1;
											c_waiting_memory = !(killed||r_killed);
											c_acked = 0;
										end
									end
							6'b01????:begin
										if (c_hazard == 0) begin
											c_waiting_hazard = 0;
											if (r_waiting_line_hit) begin
												if (c_line_hit == 0) begin
													c_load_ready = 1;
													c_waiting_line_hit = 0;
												end
											end else
											if (r_cache_miss && r_amo[0]) begin
												c_cache_miss = !(killed||r_killed);
												c_waiting_memory = !(killed||r_killed);
												c_acked = 0;
											end else begin
												c_load_ready = !(killed||r_killed);
											end
										end else
										if (r_waiting_line_hit && c_line_hit == 0) begin
											c_waiting_line_hit = 0;
										end
									end
							6'b001???:begin
										if (killed||r_killed)
											c_cache_miss = 0;
										if (c_line_hit == 0) begin
											c_waiting_line_hit = 0;
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
							c_free = first && (((r_commit|((commit)&r_valid)) && !c_cache_miss && !c_send_cancel) || (r_send_cancel&&c_acked));
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
		r_line_hit <= c_line_hit;
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
		r_waiting_memory <= !reset&c_waiting_memory;
		r_waiting_line_hit <= c_waiting_line_hit;
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
            .free(free),
            .first(first),
            .load_acked(r_load_acked),
            .load_ready(load_ready),
            .load_state({r_last_load_acked, r_waiting_hazard, r_waiting_line_hit, r_waiting_memory, r_ack_waiting, r_send_cancel}),
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
			.first(first),
			.free(free),
			.r_rd(r_rd),	// 5
			.r_load(r_load),
			.r_store(r_store),
			.r_io(r_io),
			.r_last_load_acked(r_last_load_acked),
			.r_waiting_hazard(r_waiting_hazard),
			.r_waiting_line_hit(r_waiting_line_hit),
			.r_waiting_memory(r_waiting_memory),
			.r_ack_waiting(r_ack_waiting),
			.r_send_cancel(r_send_cancel),
			.line_hit(line_hit),	// 8
            .r_line_hit(r_line_hit), // 8
            .all_active(all_active), // 8
            .new_active(new_active), // 8
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
			.free_out(free_out),
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
