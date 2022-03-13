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

module cpu(input clk, input reset, input [7:0]cpu_id,
	output		reset_out,

`ifdef SIMD
	input simd_enable,
`endif

`ifdef AWS_DEBUG
	output	cpu_trig,
	input	cpu_trig_ack,
	input	trig_in,
	output	trig_in_ack,
	output	xxtrig,
`endif

    output[NPHYS-1:ACACHE_LINE_SIZE]ic_raddr,
    output      ic_raddr_req,
    input       ic_raddr_ack,
	output [TRANS_ID_SIZE-1:0]ic_raddr_trans,
	output [2:0]ic_raddr_snoop,

    input  [CACHE_LINE_SIZE-1:0]ic_rdata,
    input        ic_rdata_req,
    output       ic_rdata_ack,
	input  [TRANS_ID_SIZE-1:0]ic_rdata_trans,
	input  [2:0]ic_rdata_resp,

	input [NPHYS-1:ACACHE_LINE_SIZE]ic_snoop_addr,
	input 	    ic_snoop_addr_req,
	output 	    ic_snoop_addr_ack,
	input  [1:0]ic_snoop_snoop,

	output [2:0]ic_snoop_data_resp,
	//output[CACHE_LINE_SIZE-1:0]ic_snoop_data,

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

	output			   io_clic_m_enable,
	output			   io_clic_h_enable,
	output			   io_clic_s_enable,
	output			   io_clic_u_enable,
	input	      [7:0]io_clic_m_il,
	input[$clog2(NINTERRUPTS)-1:0]io_clic_m_int,
	input			   io_clic_m_pending,
	input			   io_clic_m_vec,
	input	      [7:0]io_clic_h_il,
	input[$clog2(NINTERRUPTS)-1:0]io_clic_h_int,
	input			   io_clic_h_pending,
	input			   io_clic_h_vec,
	input	      [7:0]io_clic_s_il,
	input[$clog2(NINTERRUPTS)-1:0]io_clic_s_int,
	input			   io_clic_s_pending,
	input			   io_clic_s_vec,
	input	      [7:0]io_clic_u_il,
	input[$clog2(NINTERRUPTS)-1:0]io_clic_u_int,
	input			   io_clic_u_pending,
	input			   io_clic_u_vec,
	output			   io_clic_ack,
	output[$clog2(NINTERRUPTS)-1:0]io_clic_ack_int,
	input		 [63:0]io_timer,
	input [NINTERRUPTS-1:0]io_interrupts
	
	);


	parameter RV=64;
	parameter NPHYS=56;
	parameter VA_SZ=48;
	parameter NINTERRUPTS=20;
	parameter CACHE_LINE_SIZE=64*8;
	parameter ACACHE_LINE_SIZE=$clog2(512/8);
	parameter CNTRL_SIZE=6;
	parameter NDEC = 4; // number of decode stages
	parameter LNDEC=2; // log number of decode stages
	parameter NHART=1;	// number of hyperthreads
	parameter LNHART=(NHART==1?1:$clog2(NHART));	// number of bits to encode hyperthreads
	parameter BDEC = (NDEC==1?2:NDEC==2?3:NDEC<=4?4:NDEC<=8?5:6); // LSB of common part of pc for decoders
	parameter NCOMMIT = 32;	// number of commit registers 
	parameter LNCOMMIT = $clog2(NCOMMIT);	// number of bits to encode that
	parameter NUM_PENDING = NCOMMIT;		// number of pending branches
	parameter NUM_PENDING_RET = NCOMMIT/2;	// number of pending call slots

	parameter CALL_STACK_SIZE=32;		// max per mode call stack size
	parameter PC_BRANCH_HISTORY=16;		// simple branch history (1 cycle cache prefetch)
	parameter HISTORY_DEPTH=4;
	parameter NUM_PMP=16;
	parameter TRANS_ID_SIZE=6;
	//
	//	 how many of each type of datapath unit
	//
`ifdef NALU3
	parameter NALU = 3;	
`else
	parameter NALU = 2;	
`endif
	parameter NSHIFT = 1;
`ifdef NADDR4
	parameter NADDR = 4;
`else
	parameter NADDR = 6;
`endif
`ifdef NLOAD2
	parameter NLOAD = 2;
`else
	parameter NLOAD = 4;
`endif
`ifdef NSTORE2
	parameter NSTORE = 2;
`else
	parameter NSTORE = 4;
`endif
	parameter	NLDSTQ = 8;
	parameter NMUL = 1;
	parameter NBRANCH = 1;	// number of branch units per-hart
	parameter NCSR = 1;	// must only be 1/hart
`ifdef FP
	parameter NFPU = 1;
`else
	parameter NFPU = 0;
`endif
	
	parameter N_GLOBAL_UNITS=(NALU+NADDR+NSTORE+NSHIFT+NMUL+NFPU);
	parameter N_LOCAL_UNITS=(NBRANCH+NCSR);
	
    parameter NUM_GLOBAL_READ_PORTS=(2*NALU+3*NSHIFT+NADDR+NSTORE+2*NMUL+NFPU);	// 4+3+6+4+2+0=19 4+3+4+2+2+0=15
    parameter NUM_LOCAL_READ_PORTS=(2*NBRANCH+NCSR);							// 3
    parameter NUM_GLOBAL_WRITE_PORTS=(NALU+NLOAD+NSHIFT+NMUL+NFPU);// 2+4+1+1=8 6 write ports are tied to individual units
    parameter NUM_LOCAL_WRITE_PORTS=(NBRANCH+NCSR);
    parameter NUM_TRANSFER_PORTS=8;	// probably should be equal to NUM_WRITE_PORTS but we want to exp[eriment
`ifdef FP
	parameter NUM_GLOBAL_READ_FP_PORTS=(NSTORE+3*NFPU);
`else
	parameter NUM_GLOBAL_READ_FP_PORTS=(NSTORE);
`endif

`ifdef AWS_DEBUG
	wire	ls_trig;
`endif

	assign ic_snoop_data_resp = 0;

	//
	//	register addressing layout
	//	0_0rrrrr	real register 
	//  1_cccccc	commit register
	parameter RA = ((LNCOMMIT>5?LNCOMMIT:5)+1);
	//

	wire [NHART-1:0]rv32;
	wire [NHART-1:0]tvm;
	wire [NHART-1:0]reset_out_h;
	assign			reset_out = |reset_out_h;
	wire       [3:0]mprv[0:NHART-1];
	wire [NHART-1:0]hyper;
	wire [NHART-1:0]tsr;
	wire      [43:0]sup_ppn[0:NHART-1];
    wire       [3:0]sup_vm_mode[0:NHART-1];
    wire      [15:0]sup_asid[0:NHART-1];
	wire [NHART-1:0]unified_asid;
    wire [NHART-1:0]sup_vm_sum;
    wire [NHART-1:0]mxr;
	wire       [3:0]cpu_mode[0:NHART-1];
	wire      [31:0]trap_ins[0:NHART-1];
	
	wire	  [31:0]u_debug[0:NHART-1];

	PMP         #(.NUM_PMP(NUM_PMP), .NPHYS(NPHYS))pmp[0:1];	// PMP interface
assign pmp[1].valid=0;

	reg [RV-1:1]pc_pre_fetch[0:NHART-1];
	wire [127:0]icache_out[0:NHART-1];
	wire    [NHART-1:0]irand;
	wire			   frand;
	wire    [NHART-1:0]rename_stall;
	wire    [NHART-1:0]pc_stall;
	wire    [NHART-1:0]fetch_ok;
	wire	[NHART-1:0]fetch_fail;
	wire    [NHART-1:0]fetch_okr;
	wire    [NHART-1:0]fetch_trap_type;

    wire       tlb_wr_invalidate;
    wire       tlb_wr_invalidate_asid;
	wire	   tlb_wr_inv_unified;
    wire       tlb_wr_invalidate_addr;
    wire [VA_SZ-1:12]tlb_wr_inv_vaddr;     
    wire   [15:0]tlb_wr_inv_asid;

	wire    [15:0]tlb_d_asid;              // d$ read port
    wire[(NHART==1?0:LNHART-1):0]tlb_d_hart;
    wire[LNCOMMIT-1:0]tlb_d_addr_tid;
    wire [VA_SZ-1:12]tlb_d_vaddr;
    wire          tlb_d_addr_req;
    wire          tlb_d_addr_ack;
    wire          tlb_d_addr_cancel;
    wire          tlb_d_data_req;          // d$ response
    wire[LNCOMMIT-1:0]tlb_d_data_tid;
    wire[NPHYS-1:12]tlb_d_paddr;
	wire[VA_SZ-1:12]tlb_d_data_vaddr;
    wire    [15: 0]tlb_d_data_asid;

    wire     [6:0]tlb_d_gaduwrx;
    wire          tlb_d_2mB;
    wire          tlb_d_4mB;
    wire          tlb_d_1gB;
    wire          tlb_d_512gB;
    wire          tlb_d_valid;
    wire          tlb_d_pmp_fail;

	fetch	#(.RV(RV), .NUM_PMP(NUM_PMP), .BDEC(BDEC), .NHART(2), .VA_SZ(VA_SZ), .NPHYS(NPHYS), .TRANS_ID_SIZE(TRANS_ID_SIZE), .CACHE_LINE_SIZE(CACHE_LINE_SIZE), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .LNCOMMIT(LNCOMMIT))fetch(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
			.xxtrig(xxtrig),
`endif
			.pc_0(pc_pre_fetch[0][RV-1:BDEC]),
			//.stall_0(rename_stall[0]), 
			.stall_0(pc_stall[0]|commit_trap_br_enable[0]), 
			.ok_0(fetch_ok[0]),
			.okr_0(fetch_okr[0]),
			.fail_0(fetch_fail[0]),
			.out_0(icache_out[0]),
			.cpu_mode_0(cpu_mode[0]),
			.trap_type_0(fetch_trap_type[0]),

			.sup_vm_mode_0(sup_vm_mode[0]),
			.sup_asid_0(sup_asid[0]),
			.sup_ppn_0(sup_ppn[0]),

			.pc_1(60'hff80_0000_0000_000),
			.stall_1(1'b1),
			//.ok_1(fetch_ok[1]),
			//.okr_1(fetch_okr[1]),
			//.fail_1(fetch_fail[1]),
			//.out_1(icache_out[1]),
			//.cpu_mode_1(cpu_mode[1]),
			//.sup_vm_mode_1(sup_vm_mode[1]),
			//.sup_asid_1(sup_asid[1]),
			//.sup_ppn_1(sup_ppn[1]),
			//.trap_type_1(fetch_trap_type[1]),

			.cpu_mode_1(4'b1000),
			.sup_vm_mode_1(4'b0),
			.sup_asid_1(16'b0),
			.sup_ppn_1(44'b0),

			.pmp_0(pmp[0]),
			.pmp_1(pmp[1]),

			.tlb_d_asid(tlb_d_asid),              // d$ read port
			.tlb_d_hart(tlb_d_hart),
			.tlb_d_vaddr(tlb_d_vaddr),
			.tlb_d_addr_req(tlb_d_addr_req),
			.tlb_d_addr_tid(tlb_d_addr_tid),
			.tlb_d_addr_ack(tlb_d_addr_ack),
			.tlb_d_addr_cancel(tlb_d_addr_cancel),

			.tlb_d_data_req(tlb_d_data_req),          // i$ response
			.tlb_d_data_tid(tlb_d_data_tid),
			.tlb_d_paddr(tlb_d_paddr),
			.tlb_d_data_vaddr(tlb_d_data_vaddr),
			.tlb_d_data_asid(tlb_d_data_asid),
			.tlb_d_gaduwrx(tlb_d_gaduwrx),
			.tlb_d_2mB(tlb_d_2mB),
			.tlb_d_4mB(tlb_d_4mB),
			.tlb_d_1gB(tlb_d_1gB),
			.tlb_d_512gB(tlb_d_512gB),
			.tlb_d_valid(tlb_d_valid),
			.tlb_d_pmp_fail(tlb_d_pmp_fail),

		    .ic_raddr(ic_raddr),
			.ic_raddr_req(ic_raddr_req),
			.ic_raddr_ack(ic_raddr_ack),
			.ic_raddr_trans(ic_raddr_trans),
			.ic_raddr_snoop(ic_raddr_snoop),
    
			.ic_rdata(ic_rdata),
			.ic_rdata_trans(ic_rdata_trans),
			.ic_rdata_req(ic_rdata_req),
			.ic_rdata_ack(ic_rdata_ack),
			.ic_rdata_resp(ic_rdata_resp),

			.ic_snoop_addr(ic_snoop_addr),
			.ic_snoop_addr_req(ic_snoop_addr_req),
			.ic_snoop_addr_ack(ic_snoop_addr_ack),
			.ic_snoop_snoop(ic_snoop_snoop),

            .tlb_wr_invalidate(tlb_wr_invalidate),
            .tlb_wr_invalidate_asid(tlb_wr_invalidate_asid),
			.tlb_wr_inv_unified(tlb_wr_inv_unified),
            .tlb_wr_inv_asid(tlb_wr_inv_asid),
            .tlb_wr_invalidate_addr(tlb_wr_invalidate_addr),
            .tlb_wr_inv_vaddr(tlb_wr_inv_vaddr),

			.irand(frand),

			.dummy(1'b0));

	wire   [NHART-1:0]fetch_branched;
	wire   [NHART-1:0]dec_br_enable;
	wire   [19:0]dec_br[0:NHART-1];
	wire   [BDEC-1:1]dev_offset[0:NHART-1];

	wire   [NHART-1:0]commit_br_enable[0:NBRANCH-1];
	wire   [NHART-1:0]commit_br_short[0:NBRANCH-1];
	wire   [BDEC-1:1]commit_br_dec[0:NBRANCH-1][0:NHART-1];
	wire   [RV-1:1]commit_br[0:NBRANCH-1][0:NHART-1];
	wire [LNCOMMIT-1:0]commit_br_addr[0:NBRANCH-1][0:NHART-1];

	parameter NCOMMIT_BRANCH=2;	// max branches/commit
    wire  [NCOMMIT_BRANCH-1:0]update_br[0:NHART-1];

	wire[NHART-1:0]commit_interrupt_pending[0:NHART-1];
	wire[NHART-1:0]commit_int_br_enable[0:NHART-1];
	wire[NHART-1:0]commit_int_force_fetch[0:NHART-1];
	wire[NHART-1:0]commit_trap_br_enable[0:NHART-1];
	wire   [RV-1:1]commit_trap_br[0:NHART-1];
	wire [LNCOMMIT-1:0]commit_trap_br_addr[0:NHART-1];

	wire [4:0]rd_commit[0:NCOMMIT-1][0:NHART-1];
	wire      [NCOMMIT-1:0]makes_rd_commit[0:NHART-1];
	wire      [NCOMMIT-1:0]valid_commit[0:NHART-1];
	wire      [RA-1:0]rs1_commit[0:NCOMMIT-1][0:NHART-1];
	wire      [RA-1:0]rs2_commit[0:NCOMMIT-1][0:NHART-1];
	wire      [RA-1:0]rs3_commit[0:NCOMMIT-1][0:NHART-1];
	wire      [31:0]immed_commit[0:NCOMMIT-1][0:NHART-1];
	wire      [RV-1:1]pc_commit[0:NCOMMIT-1][0:NHART-1];
	wire      [RV-1:1]branch_dest_commit[0:NCOMMIT-1][0:NHART-1];
	wire    [BDEC-1:1]branch_dec_commit[0:NCOMMIT-1][0:NHART-1];
	wire    [NCOMMIT-1:0]branch_taken_commit[0:NHART-1];
	wire [$clog2(NUM_PENDING)-1:0]branch_token_commit[0:NCOMMIT-1][0:NHART-1];
	wire [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret_commit[0:NCOMMIT-1][0:NHART-1];
	wire [NUM_PENDING-1:0]commit_token[0:NHART-1];
	wire [NUM_PENDING_RET-1:0]commit_token_ret[0:NHART-1];
	wire            needs_rs2_commit[0:NCOMMIT-1][0:NHART-1];
	wire            needs_rs3_commit[0:NCOMMIT-1][0:NHART-1];
`ifdef FP
	wire      [NCOMMIT-1:0]rd_fp_commit[0:NHART-1];
	wire      [NCOMMIT-1:0]rs1_fp_commit[0:NHART-1];
	wire      [NCOMMIT-1:0]rs2_fp_commit[0:NHART-1];
	wire      [NCOMMIT-1:0]rs3_fp_commit[0:NHART-1];
`endif
	wire      [CNTRL_SIZE-1:0]control_commit[0:NCOMMIT-1][0:NHART-1];
	wire	            [3: 0]unit_type_commit[0:NCOMMIT-1][0:NHART-1];
	

	wire	[LNCOMMIT-1:0]current_start[0: NHART-1]; // valid range of the commit buffer 
	wire	[LNCOMMIT-1:0]current_end[0: NHART-1];	  //   start->end-1
	wire	[LNCOMMIT:0]current_available[0: NHART-1];	  //   start->end-1
	wire	[3:0]total_count_out_rename[0: NHART-1];	  //   registered count_out for perf monitoring

`ifdef FP
    wire    [NCOMMIT-1:0]fpu_ready_commit[0: NHART-1];
`endif
    wire    [NCOMMIT-1:0]alu_ready_commit[0: NHART-1];
    wire	[NCOMMIT-1:0]shift_ready_commit[0: NHART-1];
    wire	[NCOMMIT-1:0]branch_ready_commit[0: NHART-1];
    wire	[NCOMMIT-1:0]mul_ready_commit[0: NHART-1];
    wire	[NCOMMIT-1:0]div_ready_commit[0: NHART-1];
	LS_READY	 #(.LNCOMMIT(LNCOMMIT), .NHART(NHART), .NCOMMIT(NCOMMIT))ls_ready;
wire [NCOMMIT-1:0]load_addr_ready0=ls_ready.load_addr_ready[0];
wire [NCOMMIT-1:0]load_addr_not_ready0=ls_ready.load_addr_not_ready[0];
wire [NCOMMIT-1:0]store_addr_ready0=ls_ready.store_addr_ready[0];
wire [NCOMMIT-1:0]store_addr_not_ready0=ls_ready.store_addr_not_ready[0];
    wire    [NCOMMIT-1:0]csr_ready_commit[0: NHART-1];
    wire    [NCOMMIT-1:0]csr_wfi_pause[0: NHART-1];
    wire    [NHART-1:0]csr_wfi_wake;
	
`ifdef AWS_DEBUG
`ifdef AWS_DEBUG_COMMIT
    wire [NCOMMIT:0]commit_trig[0:NHART-1];
    wire [NCOMMIT:0]commit_trig_ack[0:NHART-1];
`endif
    wire [2*NDEC:0]rn_trig[0:NHART-1];
    wire [2*NDEC:0]rn_trig_ack[0:NHART-1];
	wire			ila_cpu_trig_out, ila_cpu_trig_out_ack;
	wire			reg_cpu_trig_out, reg_cpu_trig_out_ack;
	wire			csr_trig;
`endif

	wire	[NCOMMIT-1:0]commit_store_ack[0:NHART-1];
	wire	[NCOMMIT-1:0]commit_kill[0:NHART-1];
	wire	[NCOMMIT-1:0]commit_commitable[0:NHART-1];

	wire     [NMUL-1:0]divide_busy;
	wire [(NHART==1?0:LNHART-1):0]divide_hart[0:NMUL-1];
	wire[   LNCOMMIT-1:0]divide_commit[0:NMUL-1];

	wire [NUM_TRANSFER_PORTS-1:0]reg_transfer_enable[0:NHART-1];
	wire [4:0]reg_transfer_dest_addr[0:NUM_TRANSFER_PORTS-1][0:NHART-1];
`ifdef FP
	wire [NUM_TRANSFER_PORTS-1:0]reg_transfer_dest_fp[0:NHART-1];
`endif
	wire [LNCOMMIT-1:0]reg_transfer_source_addr[0:NUM_TRANSFER_PORTS-1][0:NHART-1];
		
	wire [5:0]timer_prot[0: NHART-1];
	wire [LNCOMMIT-1:0]num_retired[0: NHART-1];
	wire          [3:0]num_branches_predicted[0: NHART-1];
	wire          [3:0]num_branches_retired[0: NHART-1];

	wire  [NCOMMIT-1:0]commit_completed[0:NHART-1];
	wire  [NCOMMIT-1:0]commit_ended[0:NHART-1];
	wire  [NCOMMIT-1:0]commit_ack[0:NHART-1];
	wire  [NCOMMIT-1:0]commit_req[0:NHART-1];
	wire  [NCOMMIT-1:0]commit_load[0:NHART-1];
	wire  [NCOMMIT-1:0]commit_done[0:NHART-1];
	wire	[NCOMMIT-1:0]xsched[0:NHART-1];
	wire	[NCOMMIT-1:0]xsched_d[0:NHART-1];
	wire    [NHART-1:0]rename_reloading;
	wire   [2*NDEC-1:0]gl_valid_out_dec[0:NHART-1]; 	// for debug
	wire   [2*NDEC-1:0]gl_valid_rename[0:NHART-1]; 	// for debug
	wire          [2:0]gl_type_dec[0:NHART-1]; 	// for debug
	wire          [2:0]gl_type_rename[0:NHART-1]; 	// for debug
	wire	[NHART-1:0]issue_interrupt;
	wire	[NHART-1:0]issue_fetch_trap;
	wire       [RV-1:1]pc_fetch[0:NHART-1]; // pc at fetch output stage

	LS_ADDR  #(.CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .LNCOMMIT(LNCOMMIT), .NADDR(NADDR), .RV(RV))ls;
	LS_VM_ACK #(.NHART(NHART), .LNHART(LNHART), .LNCOMMIT(LNCOMMIT))vm_ack;
	LD_DATA_WB  #(.NHART(NHART), .LNCOMMIT(LNCOMMIT), .NLOAD(NLOAD), .RV(RV))ld_wb;
	ST_DATA #(.RV(RV), .NSTORE(NSTORE), .NHART(NHART), .LNCOMMIT(LNCOMMIT), .LNHART(LNHART))st_data;


	genvar I, J, N, D, H, R, C, F, A, S, L, B, M, K;
	generate 

		for (H = 0; H < NHART; H=H+1) begin: hart
			wire	[2*NDEC-1:0]br_predict;		// if (!br_default) then this one is predicted to be taken (only one bit will be set)
			wire				br_default;		// if true decoder decides
			wire				dec_stall;
			wire				br_stall;

			assign ls_ready.current_start[H] = current_start[H];

			//wire valid_fetch = fetch_okr[H];
			wire valid_fetch = (~dec_stall&fetch_okr[H]&!br_stall)|issue_interrupt[H]|issue_fetch_trap[H];

			reg		 predicted_branch;
			reg  [BDEC-1:1]dec_br_offset;
			reg  [BDEC-1:1]dec_br_start_offset;
			wire	jumping_stall_0, jumping_stall_1, jumping_stall_2, jumping_stall_3;
			wire	jumping_stall_4, jumping_stall_5, jumping_stall_6, jumping_stall_7;
			reg		jumping_stall_pred;
			reg 	[RV-1:1]branch_address;
			reg			subr_push, subr_pop, subr_inc2;
			wire		pop_available;
			wire 	[2*NDEC-1:0]has_jmp;
			wire 	[2*NDEC-1:0]has_jmp_back;

			wire 	[RV-1:1]pc_dest_dec;
			wire [$clog2(NUM_PENDING)-1:0]dec_branch_token;
			wire [$clog2(NUM_PENDING)-1:0]dec_branch_token_prev;
			wire [$clog2(NUM_PENDING_RET)-1:0]dec_branch_token_ret;
			wire [$clog2(NUM_PENDING_RET)-1:0]dec_branch_token_ret_prev;

			pc #(.RV(RV), .HART(H), .NUM_PENDING(NUM_PENDING), .NUM_PENDING_RET(NUM_PENDING_RET), .NDEC(NDEC), .NHART(NHART), .NPHYS(NPHYS), .LNHART(LNHART), .BDEC(BDEC), .PC_BRANCH_HISTORY(PC_BRANCH_HISTORY), .HISTORY_DEPTH(HISTORY_DEPTH), .CALL_STACK_SIZE(CALL_STACK_SIZE))prog_counter(
				.clk(clk),
`ifdef AWS_DEBUG
				.xxtrig(xxtrig),
`endif
				.reset(reset),

				.asid(sup_asid[0]),
				.cpu_mode(cpu_mode[0]),

				.jumping_stall(jumping_stall_pred),
				.issue_interrupt(issue_interrupt[H]),
				.issue_fetch_trap(issue_fetch_trap[H]),
				.commit_int_force_fetch(commit_int_force_fetch[H]),
				.dec_stall(dec_stall),
				.br_stall(br_stall),
				.pc_stall(pc_stall[H]),
				.fetch_ok(fetch_ok[H]),
				.fetch_fail(fetch_fail[H]),
				.subr_push(subr_push),
				.subr_pop(subr_pop),
				.subr_inc2(subr_inc2),
				.pop_available(pop_available),

				.dec_br_enable(predicted_branch),	
				.dec_branch(branch_address),
				.dec_br_offset(dec_br_offset),
				.dec_br_start_offset(dec_br_start_offset),
				.rename_stall(rename_stall[H]),

				.commit_br_enable(commit_br_enable[0][H]),		// only handle 1 branch unit per hart at the moment
				.commit_br(commit_br[0][H]),
				.commit_branch_token(branch_token_commit[commit_br_addr[0][H]][H]),
				.commit_branch_token_ret(branch_token_ret_commit[commit_br_addr[0][H]][H]),
				.commit_br_dec(commit_br_dec[0][H]),
				.commit_br_short(commit_br_short[0][H]),
				.commit_br_taken(branch_taken_commit[H][commit_br_addr[0][H]]),

				.pc_dest_dec(pc_dest_dec),
				.dec_branch_token(dec_branch_token),
				.dec_branch_token_prev(dec_branch_token_prev),
				.dec_branch_token_ret(dec_branch_token_ret),
				.dec_branch_token_ret_prev(dec_branch_token_ret_prev),
				.has_jmp(has_jmp),
				.has_jmp_back(has_jmp_back),
				.jumping_term(jumping_term),
				.jumping_issue(jumping_issue),

				.commit_token(commit_token[H]),
				.commit_token_ret(commit_token_ret[H]),

				.br_predict(br_predict),
				.br_default(br_default),

				.interrupt_pending(commit_interrupt_pending[H]),
				.int_br_enable(commit_int_br_enable[H]),

				.trap_br_enable(commit_trap_br_enable[H]),
				.trap_br(commit_trap_br[H]),
				.trap_branch_token(branch_token_commit[commit_trap_br_addr[H]][H]),

				.fetch_branched(fetch_branched[H]),

				.pc_out(pc_pre_fetch[H]),
				.pc_fetch(pc_fetch[H]));
			
			wire	[2*NDEC-1:0]will_be_valid_rename;
			wire		proceed_rename;
			wire [LNCOMMIT-1: 0]count_out_rename;
	
			wire     [2*NDEC-1:0]valid_out_dec; 	// dec stage data valid
			wire	[ 4:0]rs1_dec[0:2*NDEC-1];
			wire	[ 4:0]rs2_dec[0:2*NDEC-1];
			wire	[ 4:0]rs3_dec[0:2*NDEC-1];
			wire	[ 4:0]rd_dec[0:2*NDEC-1];
			wire	[31:0]immed_dec[0:2*NDEC-1];
 
			wire	[2*NDEC-1:0]needs_rs2_dec;
			wire	[2*NDEC-1:0]needs_rs3_dec;
			wire	[2*NDEC-1:0]rs1_fp_dec;
			wire	[2*NDEC-1:0]rs2_fp_dec;
			wire	[2*NDEC-1:0]rs3_fp_dec;
			wire	[2*NDEC-1:0]rd_fp_dec;
			wire	[2*NDEC-1:0]makes_rd_dec;
			wire    [3:0]unit_type_dec[0:2*NDEC-1];
			wire    [CNTRL_SIZE-1:0]control_dec[0:2*NDEC-1];
			wire 	[RV-1:1]pc_br_fetch[0:2*NDEC-1];
			wire 	[RV-1:1]pc_dec[0:2*NDEC-1];
			wire 	[2*NDEC-1:0]jumping_rel_jmp_fetch;
			wire 	[2*NDEC-1:0]jumping_rel_jmp_end_fetch;
			wire 	[2*NDEC-1:0]jumping_term;
			wire 	[2*NDEC-1:0]jumping_issue;
			wire 	[2*NDEC-1:0]jumping_push;
			wire 	[2*NDEC-1:0]jumping_pop;
			wire 	[2*NDEC-1:0]jumping_inc2;
	
			if (NDEC==2) begin
`include "mk9_4.inc"
			end else
			if (NDEC==4) begin
`include "mk9_8.inc"
			end else
			if (NDEC==8) begin
`include "mk9_16.inc"
			end 

			wire    valid_dec_0, valid_dec_1, valid_dec_2; 
	
			wire [RV-1:1]partial_pc[0:NDEC];
			wire [15:0]partial_ins[0:NDEC];
			//wire       partial_valid[0:NDEC];
			wire partial_valid_0, partial_valid_1, partial_valid_2, partial_valid_3, partial_valid_4;
			wire partial_valid_5, partial_valid_6, partial_valid_7, partial_valid_8;
			wire [31:0]trap_ins_dec[0:NDEC-1];
			wire [1:0]trap_dec[0:NDEC-1];
			wire      partial_valid_int_0;

			decode_partial #(.RV(RV), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC))decp(.reset(reset), .clk(clk),
				.rename_stall(rename_stall[H]),
				.valid_fetch(valid_fetch),
				.partial_nuke((!rename_stall&predicted_branch)|commit_trap_br_enable[H]|commit_int_br_enable[H]|commit_br_enable[0][H]),
				.partial_nuke_now(fetch_branched[H]|issue_fetch_trap[H]),
				//.partial_nuke_now(fetch_branched[H]|issue_interrupt[H]|issue_fetch_trap[H]),

				.save_partial(partial_valid_4),
				//.save_partial(partial_valid[NDEC]),
				.partial_ins(partial_ins[NDEC]),
				.decode_pc(partial_pc[NDEC][RV-1:BDEC]),

				.partial_valid_out(partial_valid_0),
				.partial_valid_out_int(partial_valid_int_0),
				//.partial_valid_out(partial_valid[0]),
				.last_partial(partial_ins[0]),
				.partial_pc(partial_pc[0]));

			if (NDEC == 4) begin : dt
				decode_trap #(.NDEC(NDEC)) badins_trap(.clk(clk), .reset(reset),
							.trap({trap_dec[3],trap_dec[2],trap_dec[1],trap_dec[0]}),
							.trap_ins_in({trap_ins_dec[3],trap_ins_dec[2],trap_ins_dec[1],trap_ins_dec[0]}),
							.trap_ins_out(trap_ins[H]));
			end

			for (D = 0; D < NDEC; D = D+1) begin :dec
				wire valid_in, valid_out;
				wire partial_valid_in, partial_valid_out;
				wire jumping_stall_out;
				if (D == 0) begin	// make verilator happy
					assign valid_in = 1'b0;
					assign valid_dec_0 = valid_out;
					assign partial_valid_in = partial_valid_0;
					assign partial_valid_int_in = partial_valid_int_0;
					assign partial_valid_1 = partial_valid_out;
					assign jumping_stall_0 = jumping_stall_out;
				end else 
				if (D == 1) begin
					assign valid_in = valid_dec_0;
					assign valid_dec_1 = valid_out;
					assign partial_valid_in = partial_valid_1;
					assign partial_valid_2 = partial_valid_out;
					assign jumping_stall_1 = jumping_stall_out;
					assign partial_valid_int_in = 1'b0;
				end else 
				if (D == 2) begin
					assign valid_in = valid_dec_1;
					assign valid_dec_2 = valid_out;
					assign partial_valid_in = partial_valid_2;
					assign partial_valid_3 = partial_valid_out;
					assign jumping_stall_2 = jumping_stall_out;
					assign partial_valid_int_in = 1'b0;
				end else 
				if (D == 3) begin
					assign valid_in = valid_dec_2;
					assign partial_valid_in = partial_valid_3;
					assign partial_valid_4 = partial_valid_out;
					assign jumping_stall_3 = jumping_stall_out;
					assign partial_valid_int_in = 1'b0;
				end 

				decode #(.RV(RV), .ADDR(D), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC))decoder(.reset(reset), .clk(clk),
`ifdef AWS_DEBUG
					.xxtrig(xxtrig),
`endif
					.rename_stall(rename_stall[H]),
					.cpu_mode(cpu_mode[H]),
					.timer_prot(timer_prot[H]),
					.ins(icache_out[H][31+32*D:32*D]), 
					.pc(pc_fetch[H][RV-1:1]), 
					.valid(valid_fetch),
					.valid_in(valid_in),
					.valid_next(valid_out),
					.jumping_stall(jumping_stall_out),
					.issue_interrupt(issue_interrupt[H]),
					.issue_fetch_trap(issue_fetch_trap[H]),
					.fetch_branched(fetch_branched[H]),
					
					.fetch_trap_type(fetch_trap_type[H]),
					.rv32(rv32[H]),
					.tvm(tvm[H]),
					.tsr(tsr[H]),
					.hyper(hyper[H]),
					.partial_nuke(commit_trap_br_enable[H]|commit_int_br_enable[H]|commit_br_enable[0][H]),

					.trap_out(trap_dec[D]),
					.trap_ins(trap_ins_dec[D]),

					.partial_pc_in(partial_pc[D]),
					.partial_pc_out(partial_pc[D+1]),
					.partial_ins_in(partial_ins[D]),
					.partial_ins_out(partial_ins[D+1]),
					.partial_valid_in(partial_valid_in),
					.partial_valid_int_in(partial_valid_int_in),
					.partial_valid_out(partial_valid_out),
					//.partial_valid_in(partial_valid[D]),
					//.partial_valid_out(partial_valid[D+1]),

					.pop_available(pop_available),
					.br_default(br_default),

					.br_predict_1(br_predict[2*D]),
					.valid_out_1(valid_out_dec[2*D]),
					.rs1_1(rs1_dec[2*D]),
					.rs2_1(rs2_dec[2*D]),
					.rs3_1(rs3_dec[2*D]),
					.rd_1(rd_dec[2*D]),
					.immed_1(immed_dec[2*D]),
					.needs_rs2_1(needs_rs2_dec[2*D]),
					.needs_rs3_1(needs_rs3_dec[2*D]),
					.rs1_fp_1(rs1_fp_dec[2*D]),
					.rs2_fp_1(rs2_fp_dec[2*D]),
					.rs3_fp_1(rs3_fp_dec[2*D]),
					.rd_fp_1(rd_fp_dec[2*D]),
					.makes_rd_1(makes_rd_dec[2*D]),
					.unit_type_1(unit_type_dec[2*D]),
					.control_1(control_dec[2*D]),
					.jumping_rel_jmp_1(jumping_rel_jmp_fetch[2*D]),
					.jumping_rel_jmp_end_1(jumping_rel_jmp_end_fetch[2*D]),
					.has_jmp_1(has_jmp[2*D]),
					.has_jmp_back_1(has_jmp_back[2*D]),
					.pc_br_fetch_1(pc_br_fetch[2*D]),
					.pc_1(pc_dec[2*D]),
					.jumping_term_1(jumping_term[2*D]),
					.jumping_issue_1(jumping_issue[2*D]),
					.jumping_push_1(jumping_push[2*D]),
					.jumping_pop_1(jumping_pop[2*D]),
					.jumping_inc2_1(jumping_inc2[2*D]),
		
					.br_predict_2(br_predict[2*D+1]),
					.valid_out_2(valid_out_dec[2*D+1]),
					.rs1_2(rs1_dec[2*D+1]),
					.rs2_2(rs2_dec[2*D+1]),
					.rs3_2(rs3_dec[2*D+1]),
					.rd_2(rd_dec[2*D+1]),
					.rs1_fp_2(rs1_fp_dec[2*D+1]),
					.rs2_fp_2(rs2_fp_dec[2*D+1]),
					.rs3_fp_2(rs3_fp_dec[2*D+1]),
					.rd_fp_2(rd_fp_dec[2*D+1]),
					.immed_2(immed_dec[2*D+1]),
					.needs_rs2_2(needs_rs2_dec[2*D+1]),
					.needs_rs3_2(needs_rs3_dec[2*D+1]),
					.makes_rd_2(makes_rd_dec[2*D+1]),
					.unit_type_2(unit_type_dec[2*D+1]),
					.control_2(control_dec[2*D+1]),
					.jumping_rel_jmp_2(jumping_rel_jmp_fetch[2*D+1]),
					.jumping_rel_jmp_end_2(jumping_rel_jmp_end_fetch[2*D+1]),
					.has_jmp_2(has_jmp[2*D+1]),
					.has_jmp_back_2(has_jmp_back[2*D+1]),
					.pc_br_fetch_2(pc_br_fetch[2*D+1]),
					.pc_2(pc_dec[2*D+1]),
					.jumping_term_2(jumping_term[2*D+1]),
					.jumping_issue_2(jumping_issue[2*D+1]),
					.jumping_push_2(jumping_push[2*D+1]),
					.jumping_pop_2(jumping_pop[2*D+1]),
					.jumping_inc2_2(jumping_inc2[2*D+1]));
			end
assign gl_valid_out_dec[H] = valid_out_dec;
assign gl_type_dec[H] = unit_type_dec[0];

			reg		r_dec_partial0;
			always @(posedge clk)
				r_dec_partial0 <= partial_valid_0;

			wire 	[RV-1:1]pc_dest_rename;
			wire			force_fetch_rename;

			rename_ctrl #(.RV(RV), .HART(H), .NUM_PENDING(NUM_PENDING), .NUM_PENDING_RET(NUM_PENDING_RET), .RA(RA), .CNTRL_SIZE(CNTRL_SIZE), .CALL_STACK_SIZE(CALL_STACK_SIZE), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC))rename_control(.reset(reset), .clk(clk),
				.commit_br_enable(commit_br_enable[0][H]),
				.commit_trap_br_enable(commit_trap_br_enable[H]|commit_int_br_enable[H]),
				.commit_int_force_fetch(commit_int_force_fetch[H]),
				.force_fetch_rename(force_fetch_rename),
				.rename_reloading(rename_reloading[H]),
				.rename_stall(rename_stall[H]),
				.will_be_valid(will_be_valid_rename),
				.proceed(proceed_rename),
				.count_out(count_out_rename),
				.rename_count_out(total_count_out_rename[H]),
				.current_available(current_available[H]),

                .pc_dest(pc_dest_dec),						// note if/when we switch to having a trace cache these will 
                .pc_dest_out(pc_dest_rename)
				);
		

			wire	[LNCOMMIT-1: 0]map_rd_rename[0:2*NDEC-1];
			wire	[ 4: 0]all_rd_rename[0:2*NDEC-1];
			wire	[2*NDEC-1:0]all_makes_rd_rename;
`ifdef FP
			wire	[2*NDEC-1:0]all_rd_fp_rename;
`endif
			wire	[RA-1:0]rs1_rename[0:2*NDEC-1];
			wire	[RA-1:0]rs2_rename[0:2*NDEC-1];
			wire	[RA-1:0]rs3_rename[0:2*NDEC-1];
			wire	[ 4:0]real_rs1_rename[0:2*NDEC-1];
			wire	[ 4:0]real_rs2_rename[0:2*NDEC-1];
			wire	[ 4:0]real_rs3_rename[0:2*NDEC-1];
			wire	[LNCOMMIT-1:0]rd_rename[0:2*NDEC-1];
			wire	[ 4:0]rd_real_rename[0:2*NDEC-1];
			wire	[31:0]immed_rename[0:2*NDEC-1];
			wire	      needs_rs2_rename[0:2*NDEC-1];
			wire	      needs_rs3_rename[0:2*NDEC-1];
			wire	      makes_rd_rename[0:2*NDEC-1];
			wire	      rd_fp_rename[0:2*NDEC-1];
			wire	      rs1_fp_rename[0:2*NDEC-1];
			wire	      rs2_fp_rename[0:2*NDEC-1];
			wire	      rs3_fp_rename[0:2*NDEC-1];
			wire    [3:0]unit_type_rename[0:2*NDEC-1];
			wire    [CNTRL_SIZE-1:0]control_rename[0:2*NDEC-1];
			wire [$clog2(NUM_PENDING)-1:0]branch_token_rename[0:2*NDEC-1];
			wire [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret_rename[0:2*NDEC-1];
			wire      [2*NDEC-1:0]valid_rename;
			wire 	[RV-1:1]pc_rename[0:2*NDEC-1];
`ifdef FP
			wire    [RA-1:0]scoreboard_latest_rename_fp[0:31];
`endif
			wire    [RA-1:0]scoreboard_latest_rename[0:31];
			if (NHART == 1) begin
				assign   scoreboard_latest_rename[0] = 0; 
			end else begin
				wire	[LNHART-1:0]tt=H;
				assign   scoreboard_latest_rename[0] = {1'b0, tt, {RA-LNHART-1{1'b0}}};
			end
assign gl_valid_rename[H] = valid_rename;
assign gl_type_rename[H] = unit_type_rename[0];

			for (D = 0; D < 2*NDEC; D = D+1) begin :rn
				reg [2*NDEC-1:0]sel_out;
				reg [4:0]s1, s2, s3, d;
				reg      makes_d, needs_s2, needs_s3;
				reg		 rd_fp, rs1_fp, rs2_fp, rs3_fp;
				reg	[31:0]immed;
				reg    [3:0]unit_type;
				reg    [CNTRL_SIZE-1:0]control;
				reg 	[RV-1:1]pc;
				reg    [RA-1:0]renamed_rs1, renamed_rs2, renamed_rs3;
				reg			local1, local2, local3;
				reg [$clog2(NUM_PENDING)-1:0]branch_token;
				reg [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret;

				if (NDEC==2) begin
`include "mk2_4.inc"
				end else
				if (NDEC==4) begin
`include "mk2_8.inc"
				end else
				if (NDEC==8) begin
`include "mk2_16.inc"
				end 

			
				rename #(.RV(RV), .HART(H), .RA(RA), .ADDR(D), .NUM_PENDING(NUM_PENDING), .NUM_PENDING_RET(NUM_PENDING_RET), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))renamer(.reset(reset), .clk(clk),
					.rv32(rv32[H]),
					.valid(valid_out_dec),
					.rs1(s1),
                	.rs2(s2),
                	.rs3(s3),
                	.rd(d),
                	.immed(immed),
                	.needs_rs2(needs_s2),
                	.needs_rs3(needs_s3),
					.rd_fp(rd_fp),
					.rs1_fp(rs1_fp),
					.rs2_fp(rs2_fp),
					.rs3_fp(rs3_fp),
                	.makes_rd(makes_d),
                	.control(control),
                	.unit_type(unit_type),
                	.pc(pc),
					.renamed_rs1(renamed_rs1),
					.renamed_rs2(renamed_rs2),
					.renamed_rs3(renamed_rs3),
					.local1(local1),
					.local2(local2),
					.local3(local3),
					.branch_token(branch_token),
					.branch_token_ret(branch_token_ret),
	
					.commit_br_enable(commit_br_enable[0][H]),
					.commit_trap_br_enable(commit_trap_br_enable[H]|commit_int_br_enable[H]),
					.rename_reloading(rename_reloading[H]),
					.rename_stall(rename_stall[H]),
					.commit_done(commit_done[H]),
					.commit_int_force_fetch(commit_int_force_fetch[H]),
					.commit_trap_br_addr(commit_trap_br_addr[H]),
					.commit_trap_br(commit_trap_br[H]),

					.next_start(current_end[H]),
	
					.sel_out(sel_out),

					.next_map_rd(map_rd_rename[D]),
					.next_rd(all_rd_rename[D]),
					.next_makes_rd(all_makes_rd_rename[D]),
`ifdef FP
					.next_rd_fp(all_rd_fp_rename[D]),
`endif

                	.real_rs1_out(real_rs1_rename[D]),
                	.real_rs2_out(real_rs2_rename[D]),
                	.real_rs3_out(real_rs3_rename[D]),
                	.rs1_out(rs1_rename[D]),
                	.rs2_out(rs2_rename[D]),
                	.rs3_out(rs3_rename[D]),
                	.rd_out(rd_rename[D]),
                	.rd_real_out(rd_real_rename[D]),
                	.immed_out(immed_rename[D]),
                	.needs_rs2_out(needs_rs2_rename[D]),
                	.needs_rs3_out(needs_rs3_rename[D]),
					.rd_fp_out(rd_fp_rename[D]),
					.rs1_fp_out(rs1_fp_rename[D]),
					.rs2_fp_out(rs2_fp_rename[D]),
					.rs3_fp_out(rs3_fp_rename[D]),
                	.makes_rd_out(makes_rd_rename[D]),
                	.control_out(control_rename[D]),
                	.unit_type_out(unit_type_rename[D]),
                	.pc_out(pc_rename[D]),
					.will_be_valid(will_be_valid_rename[D]),
					.branch_token_out(branch_token_rename[D]),
					.branch_token_ret_out(branch_token_ret_rename[D]),
					.valid_out(valid_rename[D])
					);

`ifdef AWS_DEBUG
`ifdef NOTDEF
begin
				wire [RV-1:0]tpc={pc_rename[D], 1'b0};
				ila_rename ila_rename(.clk(clk),
						//.trig_in(rn_trig[H][D]),
						//.trig_in_ack(rn_trig_ack[H][D]),
						//.trig_out(rn_trig[H][D+1]),
						//.trig_out_ack(rn_trig_ack[H][D+1]),
						//.xxtrig(xxtrig),

						.valid(valid_rename[D]),
						.pc(tpc[23:0]),
						.unit_type(unit_type_rename[D]),
						.renamed_rs1(renamed_rs1),
						.real_rs1(real_rs1_rename[D]),
						.rs1(rs1_rename[D]),
						.pc_dest_rename({pc_dest_rename[31:1], 1'b0}),
						.rd(rd_rename[D]));
end
`endif
`endif

			end  


`ifdef FP
			for (R = 0; R < 32; R=R+1) begin : sbf
				wire is_fp = 1'b1;
				wire [NCOMMIT-1:0]commit_match;
				for (C = 0; C < NCOMMIT; C=C+1) begin
					assign commit_match[C] = (rd_commit[C][H]==R)&rd_fp_commit[H][C]&makes_rd_commit[H][C]&valid_commit[H][C]&!commit_kill[H][C]&!commit_done[H][C]&!commit_ended[H][C];
				end

				reg	rename_match_valid;
				reg   [LNCOMMIT-1:0]rename_result;
				wire [2*NDEC-1:0]rename_match;
				if (NDEC == 2) begin
`include "mk3_4.inc"
				end else
				if (NDEC == 4) begin
`include "mk3_8.inc"
				end else
				if (NDEC == 8) begin
`include "mk3_16.inc"
				end 

				scoreboard #(.RV(RV), .HART(H), .RA(RA), .ADDR(R), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC))score_board(.reset(reset), .clk(clk),

					.rename_result(rename_result),
					.rename_valid(rename_match_valid),
					.rename_reloading(rename_reloading[H]),
					.rename_stall(rename_stall[H]),
	
					.current_end(current_end[H]),

					.commit_reg(commit_done[H]),
					.commit_match(commit_match),

					.scoreboard_latest_rename(scoreboard_latest_rename_fp[R])
				);
			end
`endif
			for (R = 1; R < 32; R=R+1) begin : sb
`ifdef FP
				wire is_fp = 1'b0;
`endif
				wire [NCOMMIT-1:0]commit_match;
				for (C = 0; C < NCOMMIT; C=C+1) begin
`ifdef FP
					assign commit_match[C] = (rd_commit[C][H]==R)&~rd_fp_commit[H][C]&makes_rd_commit[H][C]&valid_commit[H][C]&!commit_kill[H][C]&!commit_done[H][C]&!commit_ended[H][C];
`else
					assign commit_match[C] = (rd_commit[C][H]==R)&makes_rd_commit[H][C]&valid_commit[H][C]&!commit_kill[H][C]&!commit_done[H][C]&!commit_ended[H][C];
`endif
				end
			
				reg	rename_match_valid;
				reg   [LNCOMMIT-1:0]rename_result;
				wire [2*NDEC-1:0]rename_match;
				if (NDEC == 2) begin
`include "mk3_4.inc"
				end else
				if (NDEC == 4) begin
`include "mk3_8.inc"
				end else
				if (NDEC == 8) begin
`include "mk3_16.inc"
				end 

				scoreboard #(.RV(RV), .HART(H), .RA(RA), .ADDR(R), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC))score_board(.reset(reset), .clk(clk),

					.rename_result(rename_result),
					.rename_valid(rename_match_valid),
					.rename_reloading(rename_reloading[H]),
					.rename_stall(rename_stall[H]),
	
					.current_end(current_end[H]),

					.commit_reg(commit_done[H]),
					.commit_match(commit_match),

					.scoreboard_latest_rename(scoreboard_latest_rename[R])
				);
			
			end

			wire	[NCOMMIT-1:0]commit_store_req;

			for (K = 0; K < NUM_TRANSFER_PORTS; K=K+1) begin
				assign reg_transfer_dest_addr[K][H] = rd_commit[reg_transfer_source_addr[K][H]][H];
`ifdef FP
				assign reg_transfer_dest_fp[H][K] = rd_fp_commit[H][reg_transfer_source_addr[K][H]];
`endif
			end

			wire [NCOMMIT-1:0]commit_branch;
			wire [NCOMMIT-1:0]commit_branch_ok;
			wire  [RV-1:1]commit_update_pc[0:NCOMMIT-1];
			wire  [RV-1:1]commit_update_dest[0:NCOMMIT-1];
			wire  [NCOMMIT-1:0]commit_update_taken;
			wire             commit_update_short_pc[0:NCOMMIT-1];

			reg [NUM_PENDING-1:0]r_commit_token;
			assign commit_token[H] = r_commit_token;
			wire [NUM_TRANSFER_PORTS-1:0]current_commit_mask;
			wire [NUM_TRANSFER_PORTS-1:0]token_match[0:NUM_PENDING-1];
			for (I = 0; I < NUM_TRANSFER_PORTS; I=I+1) begin
				wire [$clog2(NCOMMIT)-1:0]ind = current_start[H]+I;
				wire [$clog2(NUM_PENDING)-1:0]tok = branch_token_commit[ind][H];
				for (J = 0; J < NUM_PENDING; J = J + 1) begin
					assign token_match[J][I] = current_commit_mask[(NUM_TRANSFER_PORTS-1)-I] && tok == J;
				end
			end
			for (I = 0; I < NUM_PENDING; I = I + 1) begin
				always @(posedge clk)
					r_commit_token[I] <= |token_match[I];
			end

			reg [NUM_PENDING_RET-1:0]r_commit_token_ret;
			assign commit_token_ret[H] = r_commit_token_ret;
			wire [NUM_TRANSFER_PORTS-1:0]token_match_ret[0:NUM_PENDING_RET-1];
			for (I = 0; I < NUM_TRANSFER_PORTS; I=I+1) begin
				wire [$clog2(NCOMMIT)-1:0]ind = current_start[H]+I;
				wire [$clog2(NUM_PENDING_RET)-1:0]tok = branch_token_ret_commit[ind][H];
				for (J = 0; J < NUM_PENDING_RET; J = J + 1) begin
					assign token_match_ret[J][I] = current_commit_mask[(NUM_TRANSFER_PORTS-1)-I] && tok == J;
				end
			end
			for (I = 0; I < NUM_PENDING_RET; I = I + 1) begin
				always @(posedge clk)
					r_commit_token_ret[I] <= |token_match_ret[I];
			end

			commit_ctrl #(.RV(RV), .HART(H), .RA(RA), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .NUM_TRANSFER_PORTS(NUM_TRANSFER_PORTS))cc(.reset(reset), .clk(clk),
				.advance_count(count_out_rename),
				.advance(proceed_rename),
				.commit_trap_br_addr(commit_trap_br_addr[H]),
				.commit_trap_br_enable(commit_trap_br_enable[H]|commit_int_br_enable[H]),
				.commit_br_enable(commit_br_enable[0][H]),	// just one branch unit/hart for the moment
				.commit_br_addr(commit_br_addr[0][H]),
				.commit_kill(commit_kill[H]),

				.commit_branch(commit_branch),
				.commit_branch_ok(commit_branch_ok),
				.current_commit_mask(current_commit_mask),

				.commit_write_enable(reg_transfer_enable[H]),
				.commit_write_port_0(reg_transfer_source_addr[0][H]),
				.commit_write_port_1(reg_transfer_source_addr[1][H]),
				.commit_write_port_2(reg_transfer_source_addr[2][H]),
				.commit_write_port_3(reg_transfer_source_addr[3][H]),

				.commit_write_port_4(reg_transfer_source_addr[4][H]),
				.commit_write_port_5(reg_transfer_source_addr[5][H]),
				.commit_write_port_6(reg_transfer_source_addr[6][H]),
				.commit_write_port_7(reg_transfer_source_addr[7][H]),

				.commit_req(commit_req[H]),
				.commit_ack(commit_ack[H]),
				.commit_store_req(commit_store_req),
				.commit_store_ack(commit_store_ack[H]),
				.commit_done(commit_done[H]),
				.commit_ended(commit_ended[H]),

				.commit_start(current_start[H]),
				.commit_end(current_end[H]),
				.commit_available(current_available[H]),
				.num_retired(num_retired[H]),
				.num_branches_predicted(num_branches_predicted[H]),
				.num_branches_retired(num_branches_retired[H])
				);

			for (C = 0; C < NCOMMIT; C=C+1) begin : cm
				reg xload;
				reg [4:0]real_rd;
				reg [4:0]real_rs1, real_rs2, real_rs3;
				reg [RA-1:0]rs1, rs2, rs3;
				reg [31:0]immed;
				reg	  makes_rd, needs_rs2, needs_rs3;
				reg	  rd_fp, rs1_fp, rs2_fp, rs3_fp;
				reg [CNTRL_SIZE-1:0]control;
				reg [3:0]unit_type;
				reg 	[RV-1:1]pc_rn;
				reg [$clog2(NUM_PENDING)-1:0]branch_token;
				reg [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret;
	
				if (NDEC == 2) begin
`include "mk5_4.inc"
				end else
				if (NDEC == 4) begin
`include "mk5_8.inc"
				end else
				if (NDEC == 8) begin
`include "mk5_16.inc"
				end 

				reg      this_load_done, this_divide_busy;
				reg		 this_addr_done;
				reg		 this_vm_pause;
				reg		 this_vm_stall;
				reg [1:0]this_trap_type;
				if (NADDR==6 && NLOAD == 4 && NSTORE == 4 && NMUL == 1) begin
`include "mk14_6_4_4_1.inc"
				end else
				if (NADDR == 4 && NLOAD == 2 && NSTORE == 2 && NMUL == 1) begin
`include "mk14_4_2_2_1.inc"
				end 

				assign commit_load[H][C] = xload&~(commit_br_enable[0][H]|commit_trap_br_enable[H]|commit_int_br_enable[H]);

				commit #(.RV(RV), .HART(H), .RA(RA), .ADDR(C), .NUM_PENDING(NUM_PENDING), .NUM_PENDING_RET(NUM_PENDING_RET), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NDEC(NDEC), .BDEC(BDEC), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .CALL_STACK_SIZE(CALL_STACK_SIZE))commiter(.reset(reset), .clk(clk),
`ifdef SIMD
					.simd_enable(simd_enable),
`endif
`ifdef AWS_DEBUG
`ifdef AWS_DEBUG_COMMIT
                    .trig_in(commit_trig[H][C]),
                    .trig_in_ack(commit_trig_ack[H][C]),
                    .trig_out(commit_trig[H][C+1]),
                    .trig_out_ack(commit_trig_ack[H][C+1]),
					.xxtrig(xxtrig),
`endif
`endif
					.load(commit_load[H][C]),
        			.rs1(rs1),
        			.rs2(rs2),
        			.rs3(rs3),
					.real_rs1(real_rs1),
					.real_rs2(real_rs2),
					.real_rs3(real_rs3),
        			.rd(real_rd),
        			.immed(immed),
        			.makes_rd(makes_rd),
        			.needs_rs2(needs_rs2),
        			.needs_rs3(needs_rs3),
`ifdef FP
					.rd_fp(rd_fp),
					.rs1_fp(rs1_fp),
					.rs2_fp(rs2_fp),
					.rs3_fp(rs3_fp),
`endif
        			.control(control),
        			.pc(pc_rn),
					.pc_dest(pc_dest_rename),
					.branch_token(branch_token),
					.branch_token_ret(branch_token_ret),
        			.unit_type(unit_type), 
					.force_fetch(force_fetch_rename),

					.commit_kill(commit_kill[H][C]),
					.br_in(commit_br_addr[0][H]==C&&commit_br_enable[0][H]),

`ifdef FP
               		.fpu_ready(fpu_ready_commit[H][C]),
`endif
               		.alu_ready(alu_ready_commit[H][C]),
                	.shift_ready(shift_ready_commit[H][C]),
                	.branch_ready(branch_ready_commit[H][C]),
                	.mul_ready(mul_ready_commit[H][C]),
                	.div_ready(div_ready_commit[H][C]),
                	.load_addr_ready(ls_ready.load_addr_ready[H][C]),
                	.load_addr_not_ready(ls_ready.load_addr_not_ready[H][C]),
                	.store_addr_ready(ls_ready.store_addr_ready[H][C]),
                	.store_addr_not_ready(ls_ready.store_addr_not_ready[H][C]),
                	.store_data_ready(ls_ready.store_data_ready[H][C]),
               		.csr_ready(csr_ready_commit[H][C]),

					.csr_wfi_pause(csr_wfi_pause[H][C]),
					.csr_wfi_wake(csr_wfi_wake[H]),

					.commit_branch(commit_branch[C]),
					.commit_branch_ok(commit_branch_ok[C]),
					.commit_update_pc(commit_update_pc[C]),
					.commit_update_dest(commit_update_dest[C]),
					.commit_update_taken(commit_update_taken[C]),
					.commit_update_short_pc(commit_update_short_pc[C]),
					.commit_br(commit_br[0][H]),

					.completed(commit_completed[H]),
					.commit_done(commit_done[H]),
					.commit_done_out(commit_done[H][C]),
					.commit_ended(commit_ended[H][C]),
					.schedule(xsched[H][C]),
					.schedule_d(xsched_d[H][C]),
					.commit_ack(commit_ack[H]),
					.commit_req(commit_req[H][C]),
					.commit_store_ack(commit_store_ack[H][C]),
					.commit_store_req(commit_store_req[C]),
					.commit_first(current_start[H]==C),
					.commit_commitable(commit_commitable[H][C]),
					.commit_vm_stall(this_vm_stall),
					.commit_vm_pause(this_vm_pause),

					.commit_vm_done(vm_ack.hart[H] && vm_ack.rd == C),
					.commit_vm_done_fail(vm_ack.fail),
					.commit_vm_done_pmp(vm_ack.pmp),

					.commit_load_done(this_load_done),
					.commit_addr_done(this_addr_done),
					.commit_addr_trap_type(this_trap_type),
					.commit_divide_busy(this_divide_busy),

					.makes_rd_out(makes_rd_commit[H][C]),
					.rd_out(rd_commit[C][H]),
					.rs1_out(rs1_commit[C][H]),
					.rs2_out(rs2_commit[C][H]),
					.rs3_out(rs3_commit[C][H]),
					.immed_out(immed_commit[C][H]),
					.needs_rs2_out(needs_rs2_commit[C][H]),
					.needs_rs3_out(needs_rs3_commit[C][H]),
`ifdef FP
					.rd_fp_out(rd_fp_commit[H][C]),
					.rs1_fp_out(rs1_fp_commit[H][C]),
					.rs2_fp_out(rs2_fp_commit[H][C]),
					.rs3_fp_out(rs3_fp_commit[H][C]),
`endif
					.control_out(control_commit[C][H]),
					.unit_type_out(unit_type_commit[C][H]),
					.pc_out(pc_commit[C][H]),
					.branch_dest_out(branch_dest_commit[C][H]),
					.branch_dec_out(branch_dec_commit[C][H]),
					.branch_taken_out(branch_taken_commit[H][C]),
					.branch_token_out(branch_token_commit[C][H]),
					.branch_token_ret_out(branch_token_ret_commit[C][H]),
					.valid_out(valid_commit[H][C]),
					.completed_out(commit_completed[H][C])
					);
			
			end
		end

		
        reg [NHART-1:0]reg_read_enable[0:NUM_GLOBAL_READ_PORTS-1];
        wire [RV-1:0]reg_read_data[0:NUM_GLOBAL_READ_PORTS-1][0:NHART-1];
        wire [RA-1:0]reg_read_addr[0:NUM_GLOBAL_READ_PORTS-1];
`ifdef FP
        reg [NHART-1:0]fpu_reg_read_enable[0:NUM_GLOBAL_READ_FP_PORTS-1];
        wire [RV-1:0]fpu_reg_read_data[0:NUM_GLOBAL_READ_FP_PORTS-1][0:NHART-1];
        wire [RA-1:0]fpu_reg_read_addr[0:NUM_GLOBAL_READ_FP_PORTS-1];
`endif

        reg  [NHART-1:0]local_reg_read_enable[0:NUM_LOCAL_READ_PORTS-1][0:NHART-1];
        wire [RV-1:0]local_reg_read_data[0:NUM_LOCAL_READ_PORTS-1][0:NHART-1];
        wire [RA-1:0]local_reg_read_addr[0:NUM_LOCAL_READ_PORTS-1][0:NHART-1];

        wire [NHART-1:0]reg_write_enable[0:NUM_GLOBAL_WRITE_PORTS-1];
        wire [RV-1:0]reg_write_data[0:NUM_GLOBAL_WRITE_PORTS-1];
        wire [LNCOMMIT-1:0]reg_write_addr[0:NUM_GLOBAL_WRITE_PORTS-1];
        wire [(NHART==1?0:LNHART-1):0]reg_write_hart[0:NUM_GLOBAL_WRITE_PORTS-1];
`ifdef FP
        wire [NUM_GLOBAL_WRITE_PORTS-1:0]reg_write_fp;
`endif

        wire [NHART-1:0]local_reg_write_enable[0:NUM_LOCAL_WRITE_PORTS-1][0:NHART-1];
        wire [RV-1:0]local_reg_write_data[0:NUM_LOCAL_WRITE_PORTS-1][0:NHART-1];
        wire [LNCOMMIT-1:0]local_reg_write_addr[0:NUM_LOCAL_WRITE_PORTS-1][0:NHART-1];

		wire [LNCOMMIT-1:0]alu_sched[0:N_GLOBAL_UNITS-1];	// true during read cycle
		wire [LNCOMMIT-1:0]local_alu_sched[0:N_LOCAL_UNITS-1][0:NHART-1];	// true during read cycle
		wire [(NHART==1?0:LNHART-1):0]hart_sched[0:N_GLOBAL_UNITS-1];// valid during read_cycls
		wire [N_GLOBAL_UNITS-1:0]enable_sched;
		wire             local_enable_sched[0:N_LOCAL_UNITS-1][0:NHART-1];

		for (A = 0; A < NADDR; A=A+1) begin
			assign enable_sched[N_GLOBAL_UNITS-NADDR-NSTORE+A] = ls.req[A].enable;
			assign alu_sched[N_GLOBAL_UNITS-NADDR-NSTORE+A] = ls.req[A].rd;
			assign hart_sched[N_GLOBAL_UNITS-NADDR-NSTORE+A] = ls.req[A].hart;
		end
		for (S = 0; S < NSTORE; S=S+1) begin
			assign enable_sched[N_GLOBAL_UNITS-NSTORE+S] = 0;	// not used here
			assign alu_sched[N_GLOBAL_UNITS-NSTORE+S] ='bx;
			assign hart_sched[N_GLOBAL_UNITS-NSTORE+S] ='bx;
		end

		if (N_GLOBAL_UNITS == (3+6+4+1+1+0) && N_LOCAL_UNITS == 2) begin
`include "mk15_15_2.inc"
		end
		if (N_GLOBAL_UNITS == (2+6+4+1+1+0) && N_LOCAL_UNITS == 2) begin
`include "mk15_14_2.inc"
		end
		if (N_GLOBAL_UNITS == (3+4+2+1+1+1) && N_LOCAL_UNITS == 2) begin
`include "mk15_12_2.inc"
		end
		if (N_GLOBAL_UNITS == (3+4+2+1+1+0) && N_LOCAL_UNITS == 2) begin
`include "mk15_11_2.inc"
		end
		if (N_GLOBAL_UNITS == (2+4+2+1+1+0) && N_LOCAL_UNITS == 2) begin
`include "mk15_10_2.inc"
		end

		for (A = 0; A < NALU; A=A+1) begin: alu
			assign reg_read_addr[2*A] = rs1_commit[alu_sched[A]][hart_sched[A]];
			always @(*) begin
				reg_read_enable[2*A] = 0;
				reg_read_enable[2*A][hart_sched[A]] = enable_sched[A];
			end
			assign reg_read_addr[2*A+1] = rs2_commit[alu_sched[A]][hart_sched[A]];
			always @(*) begin
				reg_read_enable[2*A+1] = 0;
				reg_read_enable[2*A+1][hart_sched[A]] = enable_sched[A];
			end

			alu #(.RV(RV), .RA(RA), .ADDR(A), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))a(.reset(reset), .clk(clk), 
`ifdef SIMD
				.simd_enable(simd_enable),
`endif
				.enable(enable_sched[A]),
				.r1(reg_read_data[2*A][hart_sched[A]]),
				.r2(reg_read_data[2*A+1][hart_sched[A]]),
				.control(control_commit[alu_sched[A]][hart_sched[A]]),
				.rd(alu_sched[A]),
				.makes_rd(makes_rd_commit[hart_sched[A]][alu_sched[A]]),
				.needs_rs2(needs_rs2_commit[alu_sched[A]][hart_sched[A]]),
				.pc(pc_commit[alu_sched[A]][hart_sched[A]]),
				.immed(immed_commit[alu_sched[A]][hart_sched[A]]),
				.hart(hart_sched[A]),
				.rv32(rv32[hart_sched[A]]),

				.result(reg_write_data[A]),
				.res_rd(reg_write_addr[A]),
				.res_makes_rd(reg_write_enable[A])
				);
`ifdef FP
				assign reg_write_fp[A] = 0;
`endif
		end
		for (S = 0; S < NSHIFT; S=S+1) begin: shift
			assign reg_read_addr[2*NALU+3*S] = rs1_commit[alu_sched[NALU+S]][hart_sched[NALU+S]];
			always @(*) begin
				reg_read_enable[2*NALU+3*S] = 0;
				reg_read_enable[2*NALU+3*S][hart_sched[NALU+S]] = enable_sched[NALU+S];
			end
			assign reg_read_addr[2*NALU+3*S+1] = rs2_commit[alu_sched[NALU+S]][hart_sched[NALU+S]];
			always @(*) begin
				reg_read_enable[2*NALU+3*S+1] = 0;
				reg_read_enable[2*NALU+3*S+1][hart_sched[NALU+S]] = enable_sched[NALU+S];
			end
			assign reg_read_addr[2*NALU+3*S+2] = rs3_commit[alu_sched[NALU+S]][hart_sched[NALU+S]];
			always @(*) begin
				reg_read_enable[2*NALU+3*S+2] = 0;
				reg_read_enable[2*NALU+3*S+2][hart_sched[NALU+S]] = enable_sched[NALU+S];
			end
			shift #(.RV(RV), .RA(RA), .ADDR(S), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))s(.reset(reset), .clk(clk), 
`ifdef SIMD
				.simd_enable(simd_enable),
`endif
				.enable(enable_sched[NALU+S]),
				.r1(reg_read_data[2*NALU+3*S][hart_sched[NALU+S]]),
				.r2(reg_read_data[2*NALU+3*S+1][hart_sched[NALU+S]]),
				.r3(reg_read_data[2*NALU+3*S+2][hart_sched[NALU+S]]),
				.control(control_commit[alu_sched[NALU+S]][hart_sched[NALU+S]]),
				.rd(alu_sched[NALU+S]),
				.makes_rd(makes_rd_commit[hart_sched[NALU+S]][alu_sched[NALU+S]]),
				.needs_rs2(needs_rs2_commit[alu_sched[NALU+S]][hart_sched[NALU+S]]),
				.immed(immed_commit[alu_sched[NALU+S]][hart_sched[NALU+S]]),
				.hart(hart_sched[NALU+S]),
				.rv32(rv32[hart_sched[NALU+S]]),


				.result(reg_write_data[NALU+S]),
				.res_rd(reg_write_addr[NALU+S]),
				.res_makes_rd(reg_write_enable[NALU+S])
				);
`ifdef FP
				assign reg_write_fp[NFPU+NALU+S] = 0;
`endif
		end
		for (A = 0; A < NADDR; A=A+1) begin: addr
			assign reg_read_addr[NFPU+2*NMUL+3*NSHIFT+2*NALU+A] = rs1_commit[ls.sched[A].rd][ls.sched[A].hart];
			always @(*) begin
				reg_read_enable[NFPU+2*NMUL+3*NSHIFT+2*NALU+A] = 0;
				reg_read_enable[NFPU+2*NMUL+3*NSHIFT+2*NALU+A][ls.sched[A].hart] = ls.sched[A].enable;
			end
			assign ls.req[A].r1 = reg_read_data[NFPU+2*NMUL+3*NSHIFT+2*NALU+A][ls.sched[A].hart];
			assign ls.req[A].immed = immed_commit[ls.sched[A].rd][ls.sched[A].hart];
			assign ls.req[A].makes_rd = makes_rd_commit[ls.sched[A].hart][ls.sched[A].rd];
			assign ls.req[A].enable = ls.sched[A].enable;
			assign ls.req[A].rd = ls.sched[A].rd;
			assign ls.req[A].hart = ls.sched[A].hart;
			assign ls.req[A].control = control_commit[ls.sched[A].rd][ls.sched[A].hart];
			assign ls.req[A].load = unit_type_commit[ls.sched[A].rd][ls.sched[A].hart] == 3;
		end
		for (L = 0; L < NLOAD; L=L+1) begin: load
			assign reg_write_data[NMUL+NFPU+NSHIFT+NALU+L] = ld_wb.wb[L].result;
			assign reg_write_addr[NMUL+NFPU+NSHIFT+NALU+L] = ld_wb.wb[L].rd;
`ifdef FP
			assign reg_write_enable[NMUL+NFPU+NSHIFT+NALU+L] = (ld_wb.wb[L].makes_rd && !ld_wb.wb[L].fp ? ld_wb.wb[L].hart:0);
			assign reg_write_fp[NFPU+L] = (ld_wb.wb[L].makes_rd && ld_wb.wb[L].fp ? ld_wb.wb[L].hart:0);
`else
			assign reg_write_enable[NMUL+NFPU+NSHIFT+NALU+L] = (ld_wb.wb[L].makes_rd ? ld_wb.wb[L].hart:0);
`endif
		end
		for (S = 0; S < NSTORE; S=S+1) begin: store
			assign reg_read_addr[NFPU+2*NMUL+NFPU+NADDR+2*(NALU)+3*NSHIFT+S] = rs2_commit[st_data.req[S].rd][st_data.req[S].hart];
			always @(*) begin
				reg_read_enable[NFPU+2*NMUL+NFPU+NADDR+2*(NALU)+3*NSHIFT+S] = 0;
`ifdef FP
				reg_read_enable[NFPU+2*NMUL+NFPU+NADDR+2*(NALU)+3*NSHIFT+S][st_data.req[S].hart] = st_data.req[S].enable & ~st_data.req[S].fp;
`else
				reg_read_enable[NFPU+2*NMUL+NFPU+NADDR+2*(NALU)+3*NSHIFT+S][st_data.req[S].hart] = st_data.req[S].enable;
`endif
			end
`ifdef FP
			assign fpu_reg_read_addr[S] = rs2_commit[st_data.req[S].rd][st_data.req[S].hart];
			always @(*) begin
				fpu_reg_read_enable[S] = 0;
				fpu_reg_read_enable[S][st_data.req[S].hart] = st_data.req[S].enable & st_data.req[S].fp;
			end
`endif
`ifdef FP
			assign reg_write_fp[NMUL+NFPU+NSHIFT+NALU+NLOAD+S] = 0;
`endif
			assign st_data.ack[S].data = reg_read_data[2*NMUL+NFPU+NADDR+3*NSHIFT+2*(NALU)+S][st_data.req[S].hart];
`ifdef FP
			assign st_data.ack[S].fp = fpu_reg_read_data[S][st_data.req[S].hart];
`endif
		end

		load_store #(.RV(RV), .NPHYS(NPHYS), .NUM_PMP(NUM_PMP), .VA_SZ(VA_SZ), .CACHE_LINE_SIZE(CACHE_LINE_SIZE), .RA(RA), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .NADDR(NADDR), .NLOAD(NLOAD), .NSTORE(NSTORE), .NLDSTQ(NLDSTQ),.TRANS_ID_SIZE(TRANS_ID_SIZE))load_store(.reset(reset), .clk(clk),
`ifdef SIMD
			.simd_enable(simd_enable),
`endif
`ifdef AWS_DEBUG
			.cpu_trig(trig_in),
			.cpu_trig_ack(trig_in_ack),
			.xxtrig(xxtrig),
			.ls_trig(ls_trig),
`endif

			.cpu_mode_0(cpu_mode[0]),
			.sup_vm_mode_0(sup_vm_mode[0]),
			.sup_asid_0(sup_asid[0]),
			.sup_vm_sum_0(sup_vm_sum[0]),
			.mxr_0(mxr[0]),
			.mprv_0(mprv[0]),
			//.cpu_mode_1(cpu_mode[1]),
			//.sup_vm_mode_1(sup_vm_mode[1]),
			//.sup_asid_1(sup_asid[1]),
			//.sup_vm_sum_1(sup_vm_sum[1]),
			//.mxr_1(mxr[1]),
			//.mprv_1(mprv[1]),

			.ls(ls),
			.vm_ack(vm_ack),
			.ld_wb(ld_wb),
			.st(st_data),

			.store_commit_0(commit_store_ack[0]),
			.commit_kill_0(commit_kill[0]),
			.commit_completed_0(commit_completed[0]),
			.commit_commitable_0(commit_commitable[0]),
			//.store_commit_1(commit_store_ack[1]),
			//.commit_kill_1(commit_kill[1]),
			//.commit_completed_1(commit_completed[1]),
			//.commit_commitable_1(commit_commitable[1]),


			.ls_ready(ls_ready),

			.dc_raddr(dc_raddr),
			.dc_raddr_req(dc_raddr_req),
			.dc_raddr_ack(dc_raddr_ack),
			.dc_raddr_trans(dc_raddr_trans),
			.dc_raddr_snoop(dc_raddr_snoop),
			.dc_rdata(dc_rdata),
			.dc_rdata_trans(dc_rdata_trans),
			.dc_rdata_req(dc_rdata_req),
			.dc_rdata_ack(dc_rdata_ack),
			.dc_rdata_resp(dc_rdata_resp),
			.dc_waddr(dc_waddr),
			.dc_waddr_req(dc_waddr_req),
			.dc_waddr_ack(dc_waddr_ack),
			.dc_waddr_snoop(dc_waddr_snoop),
			.dc_waddr_trans(dc_waddr_trans),
			.dc_wdata(dc_wdata),
			.dc_wdata_trans(dc_wdata_trans),
			.dc_wdata_done(dc_wdata_done),
			.dc_snoop_addr(dc_snoop_addr),
			.dc_snoop_addr_req(dc_snoop_addr_req),
			.dc_snoop_addr_ack(dc_snoop_addr_ack),
			.dc_snoop_snoop(dc_snoop_snoop),
			.dc_snoop_data_resp(dc_snoop_data_resp),
			.dc_snoop_data(dc_snoop_data),

			.io_cpu_addr_req(io_cpu_addr_req),
			.io_cpu_addr_ack(io_cpu_addr_ack),
			.io_cpu_addr(io_cpu_addr),
			.io_cpu_read(io_cpu_read),
			.io_cpu_lock(io_cpu_lock),
			.io_cpu_mask(io_cpu_mask),
			.io_cpu_wdata(io_cpu_wdata),
			.io_cpu_data_req(io_cpu_data_req),
			.io_cpu_data_ack(io_cpu_data_ack),
			.io_cpu_rdata(io_cpu_rdata),
			.io_cpu_data_err(io_cpu_data_err),

			.unified_asid(unified_asid),
            .tlb_wr_invalidate(tlb_wr_invalidate),
            .tlb_wr_invalidate_asid(tlb_wr_invalidate_asid),
			.tlb_wr_inv_unified(tlb_wr_inv_unified),
            .tlb_wr_inv_asid(tlb_wr_inv_asid),
            .tlb_wr_invalidate_addr(tlb_wr_invalidate_addr),
            .tlb_wr_inv_vaddr(tlb_wr_inv_vaddr),

			.irand(^irand),
			.orand(frand),

			.pmp_0(pmp[0]),
			//.pmp_1(pmp[1]),

			.tlb_d_asid(tlb_d_asid),              // d$ read port
			.tlb_d_hart(tlb_d_hart),
			.tlb_d_vaddr(tlb_d_vaddr),
			.tlb_d_addr_req(tlb_d_addr_req),
			.tlb_d_addr_tid(tlb_d_addr_tid),
			.tlb_d_addr_ack(tlb_d_addr_ack),
			.tlb_d_addr_cancel(tlb_d_addr_cancel),

			.tlb_d_data_req(tlb_d_data_req),          // i$ response
			.tlb_d_data_tid(tlb_d_data_tid),
			.tlb_d_paddr(tlb_d_paddr),
			.tlb_d_data_vaddr(tlb_d_data_vaddr),
			.tlb_d_data_asid(tlb_d_data_asid),
			.tlb_d_gaduwrx(tlb_d_gaduwrx),
			.tlb_d_2mB(tlb_d_2mB),
			.tlb_d_4mB(tlb_d_4mB),
			.tlb_d_1gB(tlb_d_1gB),
			.tlb_d_512gB(tlb_d_512gB),
			.tlb_d_valid(tlb_d_valid),
			.tlb_d_pmp_fail(tlb_d_pmp_fail),

			.dummy(1'b0) );


		for (M = 0; M < NMUL; M=M+1) begin: multiply
			assign reg_read_addr[3*NSHIFT+2*(NALU+M)] = rs1_commit[alu_sched[NSHIFT+NALU+M]][hart_sched[NSHIFT+NALU+M]];
			always @(*) begin
				reg_read_enable[3*NSHIFT+2*(NALU+M)] = 0;
				reg_read_enable[3*NSHIFT+2*(NALU+M)][hart_sched[NSHIFT+NALU+M]] = enable_sched[NSHIFT+NALU+M];
			end
			assign reg_read_addr[3*NSHIFT+2*(NALU+M)+1] = rs2_commit[alu_sched[NSHIFT+NALU+M]][hart_sched[NSHIFT+NALU+M]];
			always @(*) begin
				reg_read_enable[3*NSHIFT+2*(NALU+M)+1] = 0;
				reg_read_enable[3*NSHIFT+2*(NALU+M)+1][hart_sched[NSHIFT+NALU+M]] = enable_sched[NSHIFT+NALU+M];
			end
			mul #(.RV(RV), .RA(RA), .ADDR(M), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))m(.reset(reset), .clk(clk), 
				.enable(enable_sched[NALU+NSHIFT+M]),
				.r1(reg_read_data[3*NSHIFT+2*(NALU+M)][hart_sched[NSHIFT+NALU+M]]),
				.r2(reg_read_data[3*NSHIFT+2*(NALU+M)+1][hart_sched[NSHIFT+NALU+M]]),
				.control(control_commit[alu_sched[NSHIFT+NALU+M]][hart_sched[NSHIFT+NALU+M]]),
				.rd(alu_sched[NSHIFT+NALU+M]),
				.makes_rd(makes_rd_commit[hart_sched[NSHIFT+NALU+M]][alu_sched[NSHIFT+NALU+M]]),
				.hart(hart_sched[NSHIFT+NALU+M]),
				.rv32(rv32[hart_sched[NSHIFT+NALU+M]]),

				.commit_kill_0(commit_kill[0]),
				//.commit_kill_1(commit_kill[1]),
				.divide_busy(divide_busy[M]),
				.divide_rd(divide_commit[M]),
				.divide_hart(divide_hart[M]),
				.result(reg_write_data[NSHIFT+NALU+M]),
				.res_rd(reg_write_addr[NSHIFT+NALU+M]),
				.res_makes_rd(reg_write_enable[NSHIFT+NALU+M])
				);
`ifdef FP
				assign reg_write_fp[NSHIFT+NALU+M] = 0;
`endif
		end

`ifdef FP
		for (F = 0; F < NFPU; F=F+1) begin :fpu
			// i port
			assign reg_read_addr[3*NSHIFT+2*(NALU+NMUL)+F] = rs1_commit[alu_sched[NSHIFT+NALU+NMUL+F]][hart_sched[NSHIFT+NALU+NMUL+F]];
			always @(*) begin
				reg_read_enable[3*NSHIFT+2*(NALU+NMUL)+F] = 0;
				reg_read_enable[3*NSHIFT+2*(NALU+NMUL)+F][hart_sched[NSHIFT+NALU+NMUL+F]] = enable_sched[NSHIFT+NALU+NMUL+F]& ~rs1_fp_commit[hart_sched[NSHIFT+NALU+NMUL+F]][alu_sched[NSHIFT+NALU+NMUL+F]];
			end
			// f1 port
			assign fpu_reg_read_addr[3*F+0] = rs1_commit[alu_sched[NSHIFT+NALU+NMUL+F]][hart_sched[NSHIFT+NALU+NMUL+F]];
			always @(*) begin
				fpu_reg_read_enable[3*F+0] = 0;
				fpu_reg_read_enable[3*F+0][hart_sched[NSHIFT+NALU+NMUL+F]] = enable_sched[NSHIFT+NALU+NMUL+F]& rs1_fp_commit[hart_sched[NSHIFT+NALU+NMUL+F]][alu_sched[NSHIFT+NALU+NMUL+F]];
			end
			// f2 port
			assign fpu_reg_read_addr[3*F+1] = rs2_commit[alu_sched[NSHIFT+NALU+NMUL+F]][hart_sched[NSHIFT+NALU+NMUL+F]];
			always @(*) begin
				fpu_reg_read_enable[3*F+1] = 0;
				fpu_reg_read_enable[3*F+1][hart_sched[NSHIFT+NALU+NMUL+F]] = enable_sched[NSHIFT+NALU+NMUL+F]& rs2_fp_commit[hart_sched[NSHIFT+NALU+NMUL+F]][alu_sched[NSHIFT+NALU+NMUL+F]];
			end
			// f3 port
			assign fpu_reg_read_addr[3*F+2] = rs2_commit[alu_sched[NSHIFT+NALU+NMUL+F]][hart_sched[NSHIFT+NALU+NMUL+F]];
			always @(*) begin
				fpu_reg_read_enable[3*F+2] = 0;
				fpu_reg_read_enable[3*F+2][hart_sched[NSHIFT+NALU+NMUL+F]] = enable_sched[NSHIFT+NALU+NMUL+F] & rs3_fp_commit[hart_sched[NSHIFT+NALU+NMUL+F]][alu_sched[NSHIFT+NALU+NMUL+F]];
			end

			fpu #(.RV(RV), .RA(RA), .ADDR(F), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))f(.reset(reset), .clk(clk), 
`ifdef SIMD
				.simd_enable(simd_enable),
`endif
				.enable(enable_sched[NSHIFT+NALU+NMUL+F]),
				.ir1(reg_read_data[3*NSHIFT+2*(NALU+NMUL)+F][hart_sched[NSHIFT+NALU+NMUL+F]]),
				.fr1(fpu_reg_read_data[3*F+0][hart_sched[NSHIFT+NALU+NMUL+F]]),
				.fr2(fpu_reg_read_data[3*F+1][hart_sched[NSHIFT+NALU+NMUL+F]]),
				.fr3(fpu_reg_read_data[3*F+2][hart_sched[NSHIFT+NALU+NMUL+F]]),
				.control(control_commit[alu_sched[NSHIFT+NALU+NMUL+F]][hart_sched[NSHIFT+NALU+NMUL+F]]),
				.rd(alu_sched[NSHIFT+NALU+NMUL+F]),
				.makes_rd(makes_rd_commit[hart_sched[NSHIFT+NALU+NMUL+F]][alu_sched[NSHIFT+NALU+NMUL+F]]),
				.hart(hart_sched[NSHIFT+NALU+NMUL+F]),
				.rv32(rv32[hart_sched[NSHIFT+NALU+NMUL+F]]),

				.commit_kill_0(commit_kill[0]),
				//.commit_kill_0(commit_kill[1]),

				.result(reg_write_data[NSHIFT+NALU+NMUL+F]),
				.res_rd(reg_write_addr[NSHIFT+NALU+NMUL+F]),
				.res_makes_rd(reg_write_enable[NSHIFT+NALU+NMUL+F]),
				.res_makes_fp(reg_write_fp[NSHIFT+NALU+NMUL+F])
				);
		end
`endif


		// units from here on are per-hart 
		for (H = 0; H < NHART; H=H+1) begin : loc

			for (B = 0; B < NBRANCH; B=B+1) begin: branch
				assign local_reg_read_addr[2*B][H] = rs1_commit[local_alu_sched[B][H]][H];
				always @(*) 
					local_reg_read_enable[2*B][H] = local_enable_sched[B][H];
				assign local_reg_read_addr[2*B+1][H] = rs2_commit[local_alu_sched[B][H]][H];
				always @(*) 
					local_reg_read_enable[2*B+1][H] = local_enable_sched[B][H];
				branch #(.RV(RV), .RA(RA), .ADDR(B), .HART(H), .CNTRL_SIZE(CNTRL_SIZE), .BDEC(BDEC), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))b(.reset(reset), .clk(clk), 
`ifdef SIMD
					.simd_enable(simd_enable),
`endif
					.enable(local_enable_sched[B][H]),
					.r1(local_reg_read_data[2*(B)][H]),
					.r2(local_reg_read_data[2*(B)+1][H]),
					.control(control_commit[local_alu_sched[B][H]][H]),
					.rd(local_alu_sched[B][H]),
					.makes_rd(makes_rd_commit[H][local_alu_sched[B][H]]),
					.immed(immed_commit[local_alu_sched[B][H]][H]),
					.pc(pc_commit[local_alu_sched[B][H]][H]),
					.branch_dest(branch_dest_commit[local_alu_sched[B][H]][H]),

					.commit_br_enable(commit_br_enable[B][H]),		// only handle 1 branch unit at the moment
					.commit_br_short(commit_br_short[B][H]),
					.commit_br_dec(commit_br_dec[B][H]),
					.commit_br(commit_br[B][H]),
					.commit_kill(commit_kill[H]),
					.result(local_reg_write_data[B][H]),
					.res_rd(local_reg_write_addr[B][H]),
					.res_makes_rd(local_reg_write_enable[B][H]),
					.commit_br_addr(commit_br_addr[B][H])
					);
			end
	
			assign local_reg_read_addr[2*(NBRANCH)][H] = rs1_commit[local_alu_sched[NBRANCH][H]][H];
			always @(*) 
				local_reg_read_enable[2*(NBRANCH)][H] = local_enable_sched[NBRANCH][H];
			csr #(.RV(RV), .RA(RA), .NPHYS(NPHYS), .NUM_PMP(NUM_PMP), .HART(H), .CNTRL_SIZE(CNTRL_SIZE), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .NUM_TRANSFER_PORTS(NUM_TRANSFER_PORTS), .NINTERRUPTS(NINTERRUPTS))csr_trap(.reset(reset), .clk(clk), 
`ifdef SIMD
				.simd_enable(simd_enable),
`endif
`ifdef AWS_DEBUG
				.xxtrig(xxtrig),
				.csr_trig(csr_trig),
`endif
				.enable(local_enable_sched[NBRANCH][H]),
				.r1(local_reg_read_data[2*(NBRANCH)][H]),
				.control(control_commit[local_alu_sched[NBRANCH][H]][H]),
				.rd(local_alu_sched[NBRANCH][H]),
				.makes_rd(makes_rd_commit[H][local_alu_sched[NBRANCH][H]]),
				.immed(immed_commit[local_alu_sched[NBRANCH][H]][H]),
				.pc(pc_commit[local_alu_sched[NBRANCH][H]][H]),

				.interrupt_pending(commit_interrupt_pending[H]),
				.int_force_fetch(commit_int_force_fetch[H]),
				.int_br_enable(commit_int_br_enable[H]),
				.trap_br_enable(commit_trap_br_enable[H]),
				.trap_br_addr(commit_trap_br_addr[H]),
				.trap_br(commit_trap_br[H]),
				.result(local_reg_write_data[NBRANCH][H]),
				.res_rd(local_reg_write_addr[NBRANCH][H]),
				.res_makes_rd(local_reg_write_enable[NBRANCH][H]),
				.sup_ppn(sup_ppn[H]),
				.sup_vm_mode(sup_vm_mode[H]),
				.sup_asid(sup_asid[H]),
				.unified_asid(unified_asid[H]),
				.sup_vm_sum(sup_vm_sum[H]),
				.mxr(mxr[H]),
				.cpu_mode(cpu_mode[H]),
				.num_retired(num_retired[H]),
				.num_branches_predicted(num_branches_predicted[H]),
				.num_branches_retired(num_branches_retired[H]),
				.count_out_rename(total_count_out_rename[H]),
				.timer_prot(timer_prot[H]),
				.rv32(rv32[H]),
				.tsr(tsr[H]),
				.tvm(tvm[H]),
				.mprv(mprv[H]),
				.hyper(hyper[H]),
				.trap_ins(trap_ins[H]),
				.cpu_id(cpu_id),
				.reset_out(reset_out_h[H]),
				.u_debug(u_debug[H]),
				.csr_wfi_pause(|csr_wfi_pause[H]),
				.csr_wfi_wake(csr_wfi_wake[H]),

				.pmp(pmp[H]),

				.clic_m_enable(io_clic_m_enable),
				.clic_h_enable(io_clic_h_enable),
				.clic_s_enable(io_clic_s_enable),
				.clic_u_enable(io_clic_u_enable),
				.clic_m_il(io_clic_m_il),
				.clic_m_int(io_clic_m_int),
				.clic_m_pending(io_clic_m_pending),
				.clic_m_vec(io_clic_m_vec),
				.clic_h_il(io_clic_h_il),
				.clic_h_int(io_clic_h_int),
				.clic_h_pending(io_clic_h_pending),
				.clic_h_vec(io_clic_h_vec),
				.clic_s_il(io_clic_s_il),
				.clic_s_int(io_clic_s_int),
				.clic_s_pending(io_clic_s_pending),
				.clic_s_vec(io_clic_s_vec),
				.clic_u_il(io_clic_u_il),
				.clic_u_int(io_clic_u_int),
				.clic_u_pending(io_clic_u_pending),
				.clic_u_vec(io_clic_u_vec),
				.clic_ack(io_clic_ack),
				.clic_ack_int(io_clic_ack_int),
				.io_interrupts(io_interrupts),
				.io_timer(io_timer),

				.orand(irand[H])
			);

		end

		for (H = 0; H < NHART; H=H+1) begin : registers
`ifndef FP
			if (NCOMMIT==32 && NUM_GLOBAL_READ_PORTS==19 && NUM_LOCAL_READ_PORTS==3 && NUM_GLOBAL_WRITE_PORTS == 8 && NUM_LOCAL_WRITE_PORTS == 2 && NUM_GLOBAL_READ_FP_PORTS == 4) begin :r4
				if (NUM_TRANSFER_PORTS == 8) begin :y
`include "rfile_19_3_8_2_8_32_2.inc"  
				end 
`ifdef NSTORE2
			end else
			if (NCOMMIT==32 && NUM_GLOBAL_READ_PORTS==15 && NUM_LOCAL_READ_PORTS==3 && NUM_GLOBAL_WRITE_PORTS == 6 && NUM_LOCAL_WRITE_PORTS == 2 && NUM_GLOBAL_READ_FP_PORTS == 2) begin :r22
				if (NUM_TRANSFER_PORTS == 8) begin :y
`include "rfile_15_3_6_2_8_32_2.inc"  
				end 
`endif
`ifdef NALU3
			end else
			if (NCOMMIT==32 && NUM_GLOBAL_READ_PORTS==15 && NUM_LOCAL_READ_PORTS==3 && NUM_GLOBAL_WRITE_PORTS == 7 && NUM_LOCAL_WRITE_PORTS == 2 && NUM_GLOBAL_READ_FP_PORTS == 1) begin :r
				if (NUM_TRANSFER_PORTS == 4) begin :x
`include "rfile_15_3_7_2_4_32_1.inc"
				end 
				if (NUM_TRANSFER_PORTS == 8) begin :y
`include "rfile_15_3_7_2_8_32_1.inc"  
				end 
`endif
			end
`else
			if (NCOMMIT==32 && NUM_GLOBAL_READ_PORTS==14 && NUM_LOCAL_READ_PORTS==3 && NUM_GLOBAL_WRITE_PORTS == 7 && NUM_LOCAL_WRITE_PORTS == 2 && NUM_GLOBAL_READ_FP_PORTS == 4) begin :r4
				if (NUM_TRANSFER_PORTS == 4) begin :x4
`include "rfile_14_3_7_2_4_32_4.inc"
				end 
				if (NUM_TRANSFER_PORTS == 8) begin :y4
`include "rfile_14_3_7_2_8_32_4.inc"
				end 
`ifdef NALU3
			end else
			if (NCOMMIT==32 && NUM_GLOBAL_READ_PORTS==16 && NUM_LOCAL_READ_PORTS==3 && NUM_GLOBAL_WRITE_PORTS == 8 && NUM_LOCAL_WRITE_PORTS == 2 && NUM_GLOBAL_READ_FP_PORTS == 4) begin :r3
				if (NUM_TRANSFER_PORTS == 4) begin :x4
`include "rfile_16_3_8_2_4_32_4.inc"
				end 
				if (NUM_TRANSFER_PORTS == 8) begin :y4
`include "rfile_16_3_8_2_8_32_4.inc"
				end 
`endif
			end
`endif
		end


		if (NFPU==0 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NALU == 2 && NBRANCH == 1) begin : alu_ctrl2
				alu_ctrl #(.RV(RV), .RA(RA), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .NSHIFT(NSHIFT), .NMUL(NMUL), .NLDSTQ(NLDSTQ), .NALU(NALU), .NFPU(NFPU), .NBRANCH(NBRANCH)) alu_control(.reset(reset), .clk(clk),
`ifdef AWS_DEBUG
			.trig_in(reg_cpu_trig_out),
			.trig_in_ack(reg_cpu_trig_out_ack),
            .trig_out(rn_trig[0][0]),
            .trig_out_ack(rn_trig_ack[0][0]),
			.xxtrig(xxtrig),
`endif
			// note missing close ");" is missing (comes from the include file) on purpose here 
`include "alu_ctrl_inst_4_1_32_2_1_1_1_0.inc"
`ifdef NALU3
		end else
		if (NFPU==0 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NALU == 3 && NBRANCH == 1) begin : alu_ctrl
				alu_ctrl #(.RV(RV), .RA(RA), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .NSHIFT(NSHIFT), .NMUL(NMUL), .NLDSTQ(NLDSTQ), .NALU(NALU), .NFPU(NFPU), .NBRANCH(NBRANCH)) alu_control(.reset(reset), .clk(clk),
`ifdef AWS_DEBUG
			.trig_in(reg_cpu_trig_out),
			.trig_in_ack(reg_cpu_trig_out_ack),
            .trig_out(rn_trig[0][0]),
            .trig_out_ack(rn_trig_ack[0][0]),
			.xxtrig(xxtrig),
`endif
			// note missing close ");" is missing (comes from the include file) on purpose here 
`include "alu_ctrl_inst_4_1_32_3_1_1_1_0.inc"
`endif
		end
`ifdef FP
		if (NFPU==1 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NALU == 2 && NBRANCH == 1) begin : alu_ctrlf
				alu_ctrl #(.RV(RV), .RA(RA), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT), .NSHIFT(NSHIFT), .NMUL(NMUL), .NLDSTQ(NLDSTQ), .NALU(NALU), .NFPU(NFPU), .NBRANCH(NBRANCH)) alu_control(.reset(reset), .clk(clk),
`ifdef AWS_DEBUG
			.trig_in(reg_cpu_trig_out),
			.trig_in_ack(reg_cpu_trig_out_ack),
            .trig_out(rn_trig[0][0]),
            .trig_out_ack(rn_trig_ack[0][0]),
			.xxtrig(xxtrig),
`endif
			// note missing close ");" is missing (comes from the include file) on purpose here 
`include "alu_ctrl_inst_4_1_32_2_1_1_1_1.inc"
		end
`endif
	endgenerate


wire [31:0]pc_xxx = {pc_commit[current_start[0]][0][31:1], 1'b0}; // debug
wire [4:0]commit_xxx = current_start[0];
`ifdef AWS_DEBUG

`ifdef AWS_DEBUG_COMMIT
    assign commit_trig[0][0] = rn_trig[0][2*NDEC];
    assign rn_trig_ack[0][2*NDEC] = commit_trig_ack[0][0];
    assign cpu_trig = commit_trig[0][NCOMMIT];
    assign commit_trig_ack[0][NCOMMIT] = cpu_trig_ack;
`else
    assign cpu_trig = rn_trig[0][2*NDEC];
    assign rn_trig_ack[0][2*NDEC] = cpu_trig_ack;
`endif

	reg [7:0]r_idle_count;
    reg r_idle;
    always @(posedge clk) begin
        if (reset) begin
            r_idle <= 0;
            r_idle_count <= 8'b1100_0000;
        end else
        if (num_retired[0] != 0) begin
            r_idle <= 0;
            r_idle_count <= 8'b1100_0000;
        end else
        if (r_idle_count == 0) begin
            r_idle_count <= 0;
            r_idle <= 1;
        end else begin
            r_idle_count <= r_idle_count-1;
        end
    end

	//assign xxtrig = commit_trap_br_enable[0] && ({commit_trap_br[0][31:1], 1'b0}==32'h002011b0);
	//assign xxtrig = commit_trap_br_enable[0]&&(u_debug[0]==32'h00057600);
	//assign xxtrig = r_idle;
    wire [3:0]xxtrig_sel;
    wire [31:0]xxtrig_cmp;
	wire [15:0]xxtrig_count;
	wire [39:0]xxtrig_ticks;

    reg [15:0]r_trig_count;
    reg       r_trig_count_en;
    reg xtrig;

    always @(posedge clk) begin
        r_trig_count_en <= xtrig;
        if (reset) begin
            r_trig_count <= xxtrig_count;
        end else
        if (xtrig && !r_trig_count_en && r_trig_count !=0) begin
            r_trig_count <= r_trig_count-1;
        end
    end

	wire aatrig = commit_trap_br_enable[0] && ({commit_trap_br[0][31:1], 1'b0}==32'h002011b0);
	assign xxtrig = xtrig && r_trig_count == 0;

    reg [31:1]r_last_pc_commmit;
    reg [5:0]r_last_pc_count;
    always @(posedge clk) begin
        r_last_pc_commmit <= pc_commit[current_start[0]][0][31:1];
        if (reset || r_last_pc_commmit != pc_commit[current_start[0]][0][31:1]) begin
            r_last_pc_count <= 6'h3f;
        end else
        if (r_last_pc_count != 0) begin
            r_last_pc_count <= r_last_pc_count-1;
        end
    end

    reg [39:0]r_tick_count;
    always @(posedge clk)
    if (reset || u_debug[0] == 0) begin
        r_tick_count <= 0;
    end else begin
        r_tick_count <= r_tick_count+1;
    end

    always @(*) begin
        case (xxtrig_sel)
        0:  xtrig = r_idle;
        1:  xtrig = aatrig;
        2:  xtrig = u_debug[0]==xxtrig_cmp;
        3:  xtrig = cpu_mode[0][0]&&(num_retired[0]!=0);
        4:  xtrig = cpu_mode[0][0]&&({pc_commit[current_start[0]][0][31:1], 1'b0}==xxtrig_cmp) && (num_retired[0]!=0);
        5:  xtrig = ({pc_commit[current_start[0]][0][31:1], 1'b0}==xxtrig_cmp) && (num_retired[0]!=0);
        6:  xtrig = commit_trap_br_enable[0]&&({pc_commit[current_start[0]][0][31:1], 1'b0}==xxtrig_cmp);
        7:  xtrig = csr_trig;
        8:  xtrig = r_last_pc_count==0;
        9:  xtrig = r_last_pc_count==0 && ({pc_commit[current_start[0]][0][31:1], 1'b0}==xxtrig_cmp);
		10: xtrig = ls_trig;
		11: xtrig = ls_trig && u_debug[0]==xxtrig_cmp;
		12: xtrig = r_tick_count == xxtrig_ticks;
		13: xtrig = r_tick_count == xxtrig_ticks && u_debug[0]==xxtrig_cmp;
		14: xtrig = csr_trig && u_debug[0]==xxtrig_cmp;
		default: xtrig = 0;
        endcase
    end

	wire _cpu_trig_out, _cpu_trig_out_ack;
    ila_cpu ila_cpu(.clk(clk),
            .reset(reset),
            .idle(r_idle),

            .trig_out(_cpu_trig_out),
            .trig_out_ack(_cpu_trig_out_ack),

            .pc_fetch({pc_fetch[0], 1'b0}),
            .cache_pc_fetch({pc_pre_fetch[0], 1'b0}),
            .pc_stall(pc_stall[0]),
            .fetch_ok(fetch_ok[0]),
            .ins(icache_out[0][63:0]),
            .num_retired(num_retired[0]),
            .current_start(current_start[0]),
            .current_end(current_end[0]),
            .trap_br({commit_trap_br[0][31:1], 1'b0}),
            .trap_enable(commit_trap_br_enable[0]),
            .completed(commit_completed[0]),
            .commit_ended(commit_ended[0]),
            .commit_ack(commit_ack[0]),
            .commit_req(commit_req[0]),
            .commit_load(commit_load[0]),
            .commit_done(commit_done[0]),
            .valid_commit(valid_commit[0]),
            .pc_commit({pc_commit[current_start[0]][0][31:1], 1'b0}),
            .pc_commit_valid(valid_commit[current_start[0]]&commit_ended[0][current_start[0]]),
            .commit_kill(commit_kill[H]),
            .valid_out_dec(gl_valid_out_dec[0]),
            .u_debug(u_debug[0]),

            .load_enable_0(enable_sched[NALU+NSHIFT+0]),
            .load_immed_0(immed_commit[alu_sched[NSHIFT+NALU+0]][hart_sched[NSHIFT+NALU+0]][15:0]),
            .ls_read_addr_0(reg_read_addr[3*NSHIFT+2*NALU+0]),
            .alu_sched0(alu_sched[NSHIFT+NALU+0]),
            .load_enable_1(enable_sched[NALU+NSHIFT+1]),
            .load_immed_1(immed_commit[alu_sched[NSHIFT+NALU+1]][hart_sched[NSHIFT+NALU+1]][15:0]),
            .ls_read_addr_1(reg_read_addr[3*NSHIFT+2*NALU+1]),
            .alu_sched1(alu_sched[NSHIFT+NALU+1]),
            .csr_read_addr(local_reg_read_addr[2*(NBRANCH)][0]),
            .ticks(r_tick_count),
            .xxtrig(xxtrig),
            .issue_interrupt(issue_interrupt[0]),
            .issue_fetch_trap(issue_fetch_trap[0]),
            .partial_valid_0(partial_valid_0),
            .int_stuff({gl_type_dec[0], gl_type_rename[0], 1'b0, gl_valid_rename[0]}),    // 8+8+3+3
            .fetch_branched(fetch_branched[0]));

`ifdef NOTDEF
    wire trig_type_out, trig_type_out_ack;
    ila_type ila_type(.clk(clk),
        .trig_in(_cpu_trig_out),
        .trig_in_ack(_cpu_trig_out_ack),
        .trig_out(trig_type_out),
        .trig_out_ack(trig_type_out_ack),
        .unit_type_0(unit_type_commit[0][0]),
        .unit_type_1(unit_type_commit[1][0]),
        .unit_type_2(unit_type_commit[2][0]),
        .unit_type_3(unit_type_commit[3][0]),
        .unit_type_4(unit_type_commit[4][0]),
        .unit_type_5(unit_type_commit[5][0]),
        .unit_type_6(unit_type_commit[6][0]),
        .unit_type_7(unit_type_commit[7][0]),
        .unit_type_8(unit_type_commit[8][0]),
        .unit_type_9(unit_type_commit[9][0]),
        .unit_type_10(unit_type_commit[10][0]),
        .unit_type_11(unit_type_commit[11][0]),
        .unit_type_12(unit_type_commit[12][0]),
        .unit_type_13(unit_type_commit[13][0]),
        .unit_type_14(unit_type_commit[14][0]),
        .unit_type_15(unit_type_commit[15][0]),
        .unit_type_16(unit_type_commit[16][0]),
        .unit_type_17(unit_type_commit[17][0]),
        .unit_type_18(unit_type_commit[18][0]),
        .unit_type_19(unit_type_commit[19][0]),
        .unit_type_20(unit_type_commit[20][0]),
        .unit_type_21(unit_type_commit[21][0]),
        .unit_type_22(unit_type_commit[22][0]),
        .unit_type_23(unit_type_commit[23][0]),
        .unit_type_24(unit_type_commit[24][0]),
        .unit_type_25(unit_type_commit[25][0]),
        .unit_type_26(unit_type_commit[26][0]),
        .unit_type_27(unit_type_commit[27][0]),
        .unit_type_28(unit_type_commit[28][0]),
        .unit_type_29(unit_type_commit[29][0]),
        .unit_type_30(unit_type_commit[30][0]),
        .unit_type_31(unit_type_commit[31][0]));

    wire trig_immed_out, trig_immed_out_ack;
    ila_immed ila_immed(.clk(clk),
        .trig_in(trig_type_out),
        .trig_in_ack(trig_type_out_ack),
        .trig_out(trig_immed_out),
        .trig_out_ack(trig_immed_out_ack),
        .immed_0(immed_commit[0][0][7:0]),
        .immed_1(immed_commit[1][0][7:0]),
        .immed_2(immed_commit[2][0][7:0]),
        .immed_3(immed_commit[3][0][7:0]),
        .immed_4(immed_commit[4][0][7:0]),
        .immed_5(immed_commit[5][0][7:0]),
        .immed_6(immed_commit[6][0][7:0]),
        .immed_7(immed_commit[7][0][7:0]),
        .immed_8(immed_commit[8][0][7:0]),
        .immed_9(immed_commit[9][0][7:0]),
        .immed_10(immed_commit[10][0][7:0]),
        .immed_11(immed_commit[11][0][7:0]),
        .immed_12(immed_commit[12][0][7:0]),
        .immed_13(immed_commit[13][0][7:0]),
        .immed_14(immed_commit[14][0][7:0]),
        .immed_15(immed_commit[15][0][7:0]),
        .immed_16(immed_commit[16][0][7:0]),
        .immed_17(immed_commit[17][0][7:0]),
        .immed_18(immed_commit[18][0][7:0]),
        .immed_19(immed_commit[19][0][7:0]),
        .immed_20(immed_commit[20][0][7:0]),
        .immed_21(immed_commit[21][0][7:0]),
        .immed_22(immed_commit[22][0][7:0]),
        .immed_23(immed_commit[23][0][7:0]),
        .immed_24(immed_commit[24][0][7:0]),
        .immed_25(immed_commit[25][0][7:0]),
        .immed_26(immed_commit[26][0][7:0]),
        .immed_27(immed_commit[27][0][7:0]),
        .immed_28(immed_commit[28][0][7:0]),
        .immed_29(immed_commit[29][0][7:0]),
        .immed_30(immed_commit[30][0][7:0]),
        .immed_31(immed_commit[31][0][7:0]));

    ila_rs1 ila_rs1(.clk(clk),
        .trig_in(trig_immed_out),
        .trig_in_ack(trig_immed_out_ack),
        .trig_out(ila_cpu_trig_out),
        .trig_out_ack(ila_cpu_trig_out_ack),
        .rs1_0(rs1_commit[0][0]),
        .rs1_1(rs1_commit[1][0]),
        .rs1_2(rs1_commit[2][0]),
        .rs1_3(rs1_commit[3][0]),
        .rs1_4(rs1_commit[4][0]),
        .rs1_5(rs1_commit[5][0]),
        .rs1_6(rs1_commit[6][0]),
        .rs1_7(rs1_commit[7][0]),
        .rs1_8(rs1_commit[8][0]),
        .rs1_9(rs1_commit[9][0]),
        .rs1_10(rs1_commit[10][0]),
        .rs1_11(rs1_commit[11][0]),
        .rs1_12(rs1_commit[12][0]),
        .rs1_13(rs1_commit[13][0]),
        .rs1_14(rs1_commit[14][0]),
        .rs1_15(rs1_commit[15][0]),
        .rs1_16(rs1_commit[16][0]),
        .rs1_17(rs1_commit[17][0]),
        .rs1_18(rs1_commit[18][0]),
        .rs1_19(rs1_commit[19][0]),
        .rs1_20(rs1_commit[20][0]),
        .rs1_21(rs1_commit[21][0]),
        .rs1_22(rs1_commit[22][0]),
        .rs1_23(rs1_commit[23][0]),
        .rs1_24(rs1_commit[24][0]),
        .rs1_25(rs1_commit[25][0]),
        .rs1_26(rs1_commit[26][0]),
        .rs1_27(rs1_commit[27][0]),
        .rs1_28(rs1_commit[28][0]),
        .rs1_29(rs1_commit[29][0]),
        .rs1_30(rs1_commit[30][0]),
        .rs1_31(rs1_commit[31][0]));
`endif

    vio_cpu vio_cpu(.clk(clk),
            // outputs
             .xxtrig_sel(xxtrig_sel),
             .xxtrig_cmp(xxtrig_cmp),
			 .xxtrig_count(xxtrig_count),
			 .xxtrig_ticks(xxtrig_ticks)
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


