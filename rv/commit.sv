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

module commit_ctrl(input clk,
	input reset,

	input advance,
	input [LNCOMMIT-1:0]advance_count,
	input [NCOMMIT-1:0]commit_done,
	input	              commit_br_enable,
	input	[LNCOMMIT-1:0]commit_br_addr,
	input	[LNCOMMIT-1:0]commit_trap_br_addr,
	input				  commit_trap_br_enable,
	output [NCOMMIT-1:0]commit_ended,

	output [LNCOMMIT-1:0]commit_start,
	output [LNCOMMIT-1:0]commit_end,
	output [LNCOMMIT:0]commit_available,

    output [NUM_TRANSFER_PORTS-1:0]commit_write_enable,
    output [LNCOMMIT-1:0]commit_write_port_0,	// need to parameterise these
    output [LNCOMMIT-1:0]commit_write_port_1,
    output [LNCOMMIT-1:0]commit_write_port_2,
    output [LNCOMMIT-1:0]commit_write_port_3,
    output [LNCOMMIT-1:0]commit_write_port_4,
    output [LNCOMMIT-1:0]commit_write_port_5,
    output [LNCOMMIT-1:0]commit_write_port_6,
    output [LNCOMMIT-1:0]commit_write_port_7,
	output [LNCOMMIT-1:0]num_retired,
	input [NCOMMIT-1:0]commit_req,
	output[NCOMMIT-1:0]commit_ack,
	output[NCOMMIT-1:0]commit_kill,
	input[NCOMMIT-1:0]commit_store_req,
	output[NCOMMIT-1:0]commit_store_ack,

	output	[3:0]num_branches_predicted,
	output	[3:0]num_branches_retired,

	input [NCOMMIT-1:0]commit_branch,
	input [NCOMMIT-1:0]commit_branch_ok,
	output [NUM_TRANSFER_PORTS-1:0]current_commit_mask);

    parameter CNTRL_SIZE=7;
    parameter NDEC = 4; // number of decode stages
    parameter LNHART=0;      
    parameter NHART=1;      
    parameter BDEC= 4;
	parameter RV=64;
	parameter VA_SZ=48;
    parameter NA=6;
    parameter RA=6;
    parameter HART=0;
    parameter NUM_TRANSFER_PORTS=0;
    parameter NCOMMIT = 32; // number of commit register
    parameter LNCOMMIT = 5; // number of bits to encode that

	reg [LNCOMMIT-1:0]r_commit_start, c_commit_start, r_commit_end;
	assign commit_start = r_commit_start;
	assign commit_end = r_commit_end;

	reg [NCOMMIT-1:0]c_commit_ended;
	assign commit_ended = c_commit_ended;

	reg		r_full, c_full;
	reg [LNCOMMIT:0]r_available;
	assign commit_available = r_available;
	reg [LNCOMMIT-1:0]inc;
	assign num_retired = inc;

	wire [LNCOMMIT-1:0]commit_br_addr_plus_1 = commit_br_addr+1;
	wire [LNCOMMIT-1:0]commit_trap_br_addr_plus_1 = commit_trap_br_addr+1;
	
	wire [LNCOMMIT-1:0]diff = {1'b1, {LNCOMMIT{1'b0}}}-((r_commit_end+advance_count)-(r_commit_start+inc));
	wire equal = diff==0;
	always @(*)
	if (reset) begin
		c_full = 0;
	end else begin
		if (commit_br_enable || commit_trap_br_enable) begin
			c_full = r_commit_end == commit_br_addr_plus_1;
		end else
		if (advance) begin
			if (inc > advance_count) begin
				c_full = 0;
			end else
			if (inc < advance_count) begin
				c_full = diff == 0;
			end else begin
				c_full = r_full;
			end
		end else
		if (inc != 0) begin
			c_full = 0;
		end else begin
			c_full = r_full;
		end
	end
	
	always @(posedge clk)
		r_full <= c_full;
	
	always @(posedge clk)
	if (reset) begin
		r_commit_start <= 0;
		r_commit_end <= 0;
		r_available <= {1'b1, {LNCOMMIT{1'b0}}};
	end else begin 
		if (commit_trap_br_enable) begin
			r_commit_end <= commit_trap_br_addr_plus_1;
			r_available <= {1'b1, {LNCOMMIT{1'b0}}}-{1'b0,(commit_trap_br_addr_plus_1-{r_commit_start+inc})};
		end else
		if (commit_br_enable) begin
			r_commit_end <= commit_br_addr_plus_1;
			if (r_commit_end != commit_br_addr_plus_1)
				r_available <= {1'b1, {LNCOMMIT{1'b0}}}-{1'b0,(commit_br_addr_plus_1-(r_commit_start+inc))};
		end else begin
			if (advance) begin
				r_commit_end <= r_commit_end+advance_count;
			end
			r_available <= (!c_full&&equal?{1'b1, {LNCOMMIT{1'b0}}}: {1'b0, diff});
		end
		r_commit_start <= r_commit_start+inc;
	end

	generate
		if (NCOMMIT == 32) begin: c32
			if (NUM_TRANSFER_PORTS==8) begin
				if (NDEC==2) begin : t82
`include "mk7_4_8_32.inc"
				end else
				if (NDEC==4) begin : t84
`include "mk7_8_8_32.inc"
				end else
				if (NDEC==8) begin: t88
`include "mk7_16_8_32.inc"
				end 
			end else
			if (NUM_TRANSFER_PORTS==4) begin
				if (NDEC==2) begin: t42
`include "mk7_4_4_32.inc" 
				end else
				if (NDEC==4) begin: t44
`include "mk7_8_4_32.inc"
				end else
				if (NDEC==8) begin: t48
`include "mk7_16_4_32.inc"
				end	
			end
		end
		if (NCOMMIT == 16) begin :t16
`include "mk12_16.inc"
		end else
		if (NCOMMIT == 32) begin: t32
`include "mk12_32.inc"
		end else
		if (NCOMMIT == 64) begin:t32
`include "mk12_64.inc"
		end 
	endgenerate

endmodule

module commit(input clk,
	input reset,
`ifdef AWS_DEBUG
`ifdef AWS_DEBUG_COMMIT
    input   xxtrig,
    input   trig_in,
    output  trig_in_ack,
    output  trig_out,
    input   trig_out_ack,
`endif
`endif

	input load,

`ifdef SIMD
	input simd_enable,
`endif
	input [RA-1:0]rs1,
	input [4:0]real_rs1,
	input [RA-1:0]rs2,
	input [4:0]real_rs2,
	input [RA-1:0]rs3,
	input [4:0]real_rs3,
`ifdef RENAME_OPT
	input [RA-1:0]commit_rs1,
	input [RA-1:0]commit_rs2,
	input [RA-1:0]commit_rs3,
`endif
	input [4:0]rd,
	input [31:0]immed,
	input       makes_rd,
	input       short,
	input       start,
	input       needs_rs2,
	input       needs_rs3,
`ifdef FP
	input		rd_fp,
	input		rs1_fp,
	input		rs2_fp,
	input		rs3_fp,
`endif
	input [CNTRL_SIZE-1:0]control,
	input [VA_SZ-1:1]pc,
	input [VA_SZ-1:1]pc_dest,
	input [$clog2(NUM_PENDING)-1:0]branch_token,
	input [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret,
	input  [3:0]unit_type,       // 0 ALU, 1 shift, 2 mul/dev, 3 ld, 4 st, 5 fp, 6 jmp, 7 trap
	input	[NCOMMIT-1:0]commit_ack,
	input	[NCOMMIT-1:0]commit_completed,

	input			commit_kill,
	input			br_in,
    input   [RV-1:1]commit_br,

	output       valid_out,
	output [RA-1:0]rs1_out,
	output [RA-1:0]rs2_out,
	output [RA-1:0]rs3_out,
	output [ 4:0]rd_out,
	output [31:0]immed_out,
	output       makes_rd_out,
	output       short_out,
	output       start_out,
`ifdef FP
	output	[3:0]fpu_ready,		// bits {div, 3 clocks, 2 clocks, 1 clock}
`endif
	output       needs_rs2_out,
	output       needs_rs3_out,
`ifdef FP
	output		 rd_fp_out,
	output		 rs1_fp_out,
	output		 rs2_fp_out,
	output		 rs3_fp_out,
`endif
	output [CNTRL_SIZE-1:0]control_out,
	output     [3:0]unit_type_out,
	output  [VA_SZ-1:1]pc_out,
	output  [VA_SZ-1:1]branch_dest_out,
	output  [BDEC-1:1]branch_dec_out,
	output		 branch_taken_out,
	output [$clog2(NUM_PENDING)-1:0]branch_token_out,
	output [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret_out,
`ifdef TRACE_CACHE
	output		 will_trap_out, 
`endif

    output	alu_ready,
    output	shift_ready,
`ifndef COMBINED_BRANCH
    output	branch_ready,
`endif
    output	mul_ready,
    output	div_ready,
    output	load_addr_ready,
    output	load_addr_not_ready,
    output	store_addr_ready,
    output	store_addr_not_ready,
    output	store_data_ready,
    output	csr_ready,
    output	csr_wfi_pause,
    input	csr_wfi_wake,

	input	[NCOMMIT-1:0]commit_done,
	output	commit_done_out,
	input   commit_ended,

	input	schedule,	// true
	input	schedule_d,

	input	force_fetch,

    output commit_load_store,
    output commit_branch,
    output commit_branch_ok,
    output  [VA_SZ-1:1]commit_update_pc,
    output  [VA_SZ-1:1]commit_update_dest,
    output      commit_update_taken,
    output      commit_update_short_pc,
	
	output		 completed_out,
	output		 commit_req,

	input		 commit_first,
	output		 commit_commitable,

	input		 commit_divide_busy,

	input		 commit_addr_done,
	input   [1:0]commit_addr_trap_type,					// valid when commit_addr_done is true

	input		 commit_load_done,

	input		 commit_vm_stall,					// true if this load or store is stalled
	input		 commit_vm_pause,					// true if this load or store is pause (just resched)

	input		 commit_vm_done,					// a waiting vm_stall is done
	input		 commit_vm_done_fail,					// did we get a VM accees fail?
	input		 commit_vm_done_pmp,					// did we get a VM accees fail because of pmp?

	output		 commit_store_req,
	input		 commit_store_ack);

    parameter RN=7;
    parameter CNTRL_SIZE=7;
    parameter NDEC = 4; // number of decode stages
    parameter ADDR=0;
    parameter LNHART=0;      
    parameter NHART=1;      
    parameter BDEC= 4;
    parameter NA=6;
    parameter RA=6;
    parameter HART=0;
	parameter RV=64;
	parameter VA_SZ=48;
    parameter NCOMMIT = 32; // number of commit register
    parameter LNCOMMIT = 5; // number of bits to encode that
	parameter CALL_STACK_SIZE = 32;
	parameter NUM_PENDING=32;
	parameter NUM_PENDING_RET=8;

	assign commit_commitable = commit_first;	// true when we know that this instruction will be committed
												// really need something better

	reg [RA-1:0]r_rs1;
	reg [RA-1:0]r_rs2;
	reg [RA-1:0]r_rs3;
	reg [ 4:0]r_rd;
	reg [ 4:0]r_real_rs1;
	reg [ 4:0]r_real_rs2;
	reg [ 4:0]r_real_rs3;
`ifdef RENAME_OPT
	reg [RA-1:0]r_commit_rs1;
	reg [RA-1:0]r_commit_rs2;
	reg [RA-1:0]r_commit_rs3;
`endif
	reg [31:0]r_immed;
	reg       r_makes_rd;
	reg       r_start, c_start;
	reg       r_short, c_short;
	reg       r_needs_rs2;
	reg       r_needs_rs3;
`ifdef FP
	reg		  r_rd_fp, c_rd_fp;
	reg		  r_rs1_fp;
	reg		  r_rs2_fp;
	reg		  r_rs3_fp;
`endif
	reg [CNTRL_SIZE-1:0]r_control, c_control;
	reg [VA_SZ-1:1]r_pc;
	reg  [3:0]r_unit_type, c_unit_type;
	reg		  ready;
	assign rs1_out = r_rs1;
	assign rs2_out = r_rs2;
	assign rs3_out = r_rs3;
	assign rd_out = r_rd;
	assign immed_out = r_immed;
	assign makes_rd_out = r_makes_rd;
	assign short_out = r_short;
	assign start_out = r_start;
	assign needs_rs2_out = r_needs_rs2;
	assign needs_rs3_out = r_needs_rs3;
`ifdef FP
	assign rd_fp_out = r_rd_fp;
	assign rs1_fp_out = r_rs1_fp;
	assign rs2_fp_out = r_rs2_fp;
	assign rs3_fp_out = r_rs3_fp;
`endif
	assign control_out = r_control;
	assign unit_type_out = r_unit_type;
	assign valid_out = r_valid;
	assign commit_req = r_commit_req;
	assign commit_store_req = r_commit_store_req;
	assign commit_done_out = r_done;
	assign pc_out = r_pc;
	
    assign commit_branch = r_unit_type==6;
    assign commit_branch_ok = r_br_ok;
    assign commit_update_pc = r_pc;
	assign	branch_dec_out = r_pc[BDEC-1:1];
	assign	branch_taken_out = ~r_control[5];
	reg [VA_SZ-1:1]r_pc_dest;
	assign branch_dest_out = r_pc_dest;
	reg [$clog2(NUM_PENDING)-1:0]r_branch_token;
	reg [$clog2(NUM_PENDING_RET)-1:0]r_branch_token_ret;
	assign branch_token_out = r_branch_token;
	assign branch_token_ret_out = r_branch_token_ret;
    assign  commit_update_dest = r_pc_dest;
    assign  commit_update_taken = r_control[5]; 

	assign commit_update_short_pc = r_control[4];

	reg		r_force_fetch;	// we've doing a vector fetch
	

	//
	//	Normal ALU operation
	//r_valid      schedule
	//	valid  ready  read	busy	avail committing committed  finished trap
	//	0	   0	  0		0		0		0			0		0		 0	idle
	//
	//	1	   0	  0		0		0		0			0		0		 0	we're waiting for some other unit to
	//																		complete
	//
	//	1	   1	  0		0		0		0			0		0		 0	input data will be available in a 
	//																		register or by bypass in the
	//																		next clock
	//
	//	1	   0	  1		0		0		0			0		0		 0	input registers are being read
	//
	//	1	   0	  0		1		0		0			0		0		 0	unit is working (includes next state at
	//																		end, ALUs probbaly dont spend time
	//																		here)
	//
	//  1      0	  0		1		1		0			0		0		 0	available - our output will be available
	//																		in a register or by bypass in the
	//																		next clock (true until commit)
	//
	//	1	   0	  0		0		1		1			0		0		 0	we're waiting for a commit slot
	//
	//	1	   0	  0		0		1		1			1		1		 0	data is committed (or being committed
	//																		and is bypassable)
	//	0	   0	  0		0		0		0			0		0		 0	idle
	//
	//
	//	Normal ALU operation with no writeback
	//r_valid      schedule
	//	valid  ready  read	busy	avail committing committed  finished trap
	//	0	   0	  0		0		0		0			0		0		 0	idle
	//
	//	1	   0	  0		0		0		0			0		0		 0	we're waiting for some other unit to
	//																		complete
	//
	//	1	   1	  0		0		0		0			0		0		 0	input data will be available in a 
	//																		register or by bypass in the
	//																		next clock
	//
	//	1	   0	  1		0		0		0			0		0		 0	input registers are being read
	//
	//	1	   0	  0		1		0		0			0		0		 0	unit is working (includes next state at
	//																		end, ALUs probbaly dont spend time
	//																		here)
	//
	//  1      0	  0		1		1		0			0		0		 0	available - our output will be available
	//																		in a register or by bypass in the
	//																		next clock (true until commit)
	//
	//	1	   0	  0		0		1		0			0		1		 0	data is committed (or being committed
	//																		and is bypassable)
	//	0	   0	  0		0		0		0			0		0		 0	idle
	//
	//
	//	trap from decoder
	//	valid  ready  read	busy	avail  committing committed  finished trap
	//	0	   0	  0		0		0		0			0		 0		  0	idle
	//
	//	1	   1	  0		0		0		0			0		 0		  1	trap pending (will be serviced at end)
	//	1	   1	  0		0		0		0			0		 1		  1	trap being serviced
	//
	//
	//	trap from execution (load/store/div 0 etc)
	//	valid  ready  read  busy	avail  committing committed  finished trap
	//	0	   0	  0		0		0		0			0		 0		  0	idle
	//
	//	1	   0	  0		0		0		0			0		 0		  0	we're waiting for some other unit to complete
	//
	//	1	   1	  0		0		0		0			0		 0		  0	input data will be available in a 
	//																			register or by bypass in the
	//																			next clock
	//	1	   0	  1		0		0		0			0		 0		  0	input registers are being read
	//
	//	1      0	  0		1		0		0			0		 0		  0	unit is working
	//
	//	1	   0	  0		1		0		0			0		 0		  1	trap pending
	//
	//	1	   1	  0		0		0		0			0		 1		  1	trap being serviced
	//
	//
	// ready means we're ready to execute
	//
	//	done means we've written back our data
	//
	reg		  r_done, c_done;

	reg	r_valid, c_valid;
	reg r_completed, c_completed;
	assign completed_out = r_completed;
	reg	r_commit_req, c_commit_req;
	reg	r_commit_store_req, c_commit_store_req;
	reg r_busy, c_busy;
	reg r_busy2, c_busy2;
	reg r_busy3, c_busy3;
	reg r_read, c_read;
	reg r_read_d, c_read_d;
	reg r_vm_stall, c_vm_stall;

	reg r_load_trap, c_load_trap;
	reg	  r_addr_done, c_addr_done;
	reg	r_br_ok, c_br_ok;

	assign commit_load_store = r_valid && (r_unit_type == 3 || r_unit_type == 4);

	wire lres_ready = commit_first|!r_control[4];
	wire amod_ready = commit_first|(r_control[5:4]!=2'b01);

    assign valid_out = r_valid;
    assign commit_req = r_commit_req;
    assign commit_store_req = r_commit_store_req;
    assign commit_done_out = r_done;

`ifdef FP
	reg  [3:0]r_fpu_req, c_fpu_req;
	assign fpu_ready = (ready&(r_unit_type==5)&r_valid&!r_read ? r_fpu_req: 4'b0);
`endif
`ifdef COMBINED_BRANCH
	assign alu_ready = ready&(r_unit_type==0 || r_unit_type==6)&r_valid&!r_read;
`else
	assign alu_ready = ready&(r_unit_type==0)&r_valid&!r_read;
	assign branch_ready = ready&(r_unit_type==6)&r_valid&!r_read;
`endif
	assign shift_ready = ready&(r_unit_type==1)&r_valid&!r_read;
	assign load_addr_ready = !r_vm_stall&lres_ready&addr_ready&(r_unit_type==3)&r_valid&!r_read&!r_load_trap;
	assign load_addr_not_ready = ((r_vm_stall|!lres_ready|!addr_ready)&(r_unit_type==3)&r_valid&!r_read&!r_load_trap) || 
						  (commit_vm_stall&&commit_load_done&&(r_unit_type==3)&&r_valid);
	assign store_addr_ready = !r_vm_stall&amod_ready&addr_ready&(r_unit_type==4)&r_valid&!r_read&!r_load_trap;
	assign store_addr_not_ready = ((r_vm_stall|!amod_ready|!addr_ready)&(r_unit_type==4)&r_valid&!r_read&!r_load_trap) ||
						  (commit_vm_stall&&commit_load_done&&(r_unit_type==4)&&r_valid);
	assign store_data_ready = !r_vm_stall&amod_ready&data_ready&(r_unit_type==4)&r_valid&!r_read_d&!r_load_trap;
	assign mul_ready = ready&(r_unit_type==2)&r_valid&!r_read&r_control[0];
	assign div_ready = ready&(r_unit_type==2)&r_valid&!r_read&~r_control[0];
	reg		r_wfi_pause, c_wfi_pause;
	assign csr_ready = ready&(r_unit_type==7||r_load_trap)&r_valid&!r_read&!r_wfi_pause;
	assign csr_wfi_pause = ready&(r_unit_type==7)&r_valid&!r_read&r_wfi_pause;

`ifdef TRACE_CACHE
	assign will_trap_out = r_valid&(r_load_trap || (r_unit_type==7 && r_control[5:4] != 2'b10));
`endif

//always @(c_completed) $display("c_completed=",c_completed);
//always @(c_done) $display("c_done=",c_done);
//always @(c_finished) $display("c_finished=",c_finished);
//always @(commit_req) $display("commit_req=",commit_req);
//always @(commit_ack) $display("commit_ack=",commit_ack);
	reg		clear_immed;	// used to clear immed value when reporting a trap on an amo

	always @(*) begin
		clear_immed = 0;
		c_valid = r_valid&!commit_kill;
		c_commit_req = r_commit_req&!commit_kill;
		c_commit_store_req = r_commit_store_req&!commit_kill;
		c_done = r_done;
		c_busy = r_busy;
		c_read = r_read;
		c_read_d = r_read_d;
		c_addr_done = r_addr_done;
`ifdef FP
		c_rd_fp = r_rd_fp;
		c_fpu_req = r_fpu_req;
`endif
		c_wfi_pause = r_wfi_pause&&!csr_wfi_wake;
		c_completed = r_completed&!commit_kill;
		c_load_trap = r_load_trap;
		c_control = r_control;
		c_busy2 = r_busy2;
		c_busy3 = r_busy3;
		c_unit_type = r_unit_type;
		c_vm_stall = r_vm_stall;
		c_br_ok = r_br_ok;
		c_short = r_short;
		c_start = r_start;
		if (reset) begin
`ifdef FP
			c_rd_fp = 0;
`endif
			c_done = 0;
			c_valid = 0;
			c_read = 0;
			c_read_d = 0;
			c_commit_req = 0;
			c_busy = 0;
			c_busy2 = 0;
			c_busy3 = 0;
			c_completed = 0;
			c_commit_store_req = 0;
			c_load_trap = 0;
			c_vm_stall = 0;
			c_wfi_pause = 0;
			c_br_ok = 0;
			c_addr_done = 0;
		end else
		if (load&!commit_kill) begin
`ifdef FP
			c_rd_fp = rd_fp&makes_rd;
			casez (control[4:0])	// synthesis full_case parallel_case
			5'b1_????,
			5'b0_0010:	c_fpu_req = 4'b0100;		// 3 clocks
			5'b0_000?:	c_fpu_req = 4'b0010;		// 2 clock
			5'b0_0011,
			5'b0_0100:	c_fpu_req = 4'b1000;		// N clocks
			default:	c_fpu_req = 4'b0001;		// 1 clock
			endcase
`endif
			c_short = short;
			c_start = start;
			c_done = 0;
			c_addr_done = 0;
			c_busy = 0;
			c_busy2 = 0;
			c_busy3 = 0;
			c_valid = 1;
			c_read = 0;
			c_read_d = 0;
			c_commit_req = 0;
			c_completed = 0;
			c_load_trap = 0;
			c_control = control;
			c_unit_type = unit_type;
			c_vm_stall = 0;
			c_wfi_pause = (unit_type==7)&&(control==6'b111001)&&!csr_wfi_wake;
			c_br_ok = unit_type==6;
		end else
		if (r_valid&!commit_kill) begin
			if (r_load_trap) begin
				if (schedule) begin
					c_busy = 1;
					c_busy2 = 0;
					c_busy3 = 0;
					c_completed = 1;
				end else
				if (r_busy && !r_busy2) begin
					c_busy2 = 1;
				end else begin
					c_busy = 0;
					c_busy2 = 0;
					c_busy3 = 0;
					if (r_busy && r_busy2) begin
						if (r_makes_rd) begin
							c_commit_req = 1;
						end else begin
							c_done = 1;
						end
					end
				end
				if (r_makes_rd&&commit_ack[ADDR]) begin
					c_commit_req = 0;
					c_done = 1;
				end
				c_vm_stall = 0;
			end else
			case (r_unit_type) // synthesis full_case parallel_case
`ifdef FP
			5:		begin
						if (schedule) begin
							casez (r_fpu_req)	// synthesis full_case parallel_case
							4'b?1??:	begin		// 3 clocks
											c_busy = 0;
											c_busy2 = 1;
											c_busy3 = 1;
										end
							4'b??1?:	begin		// 2 clock
											c_busy = 1;
											c_busy2 = 0;
											c_busy2 = 0;
										end
							4'b1???:	begin		// N clocks
										end
							4'b???1:	begin		// 1 clock
											c_busy = 1;
											c_busy2 = 0;
											c_busy3 = 1;
											c_completed = 1;
										end
							endcase
						end else
						case ({r_busy, r_busy2, r_busy3}) // synthesis full_case parallel_case
						3'b011: begin   c_busy = 1; c_busy2 = 0; c_busy3 = 0; end
						3'b100: begin   c_busy = 1; c_busy2 = 0; c_busy3 = 1; end
						3'b101: begin   c_busy = 1; c_busy2 = 1; c_busy3 = 0; end
						default:
							begin
									c_busy = 0;
									c_busy2 = 0;
									if (r_busy && r_busy2) begin
										if (r_makes_rd) begin
											c_commit_req = 1;
										end else begin
											c_done = 1;
										end
									end
							end
						endcase
						if (r_makes_rd&&commit_ack[ADDR]) begin
							c_commit_req = 0;
							c_done = 1;
						end
					end
`endif
			0,1,7,6: begin		// 1 clock
					if (schedule) begin
						c_busy = 1;
						c_busy2 = 0;
						c_completed = 1;
					end else
					if (r_busy && !r_busy2) begin
						c_busy2 = 1;
					end else begin
						c_busy = 0;
						c_busy2 = 0;
						if (r_busy && r_busy2) begin
							if (r_makes_rd) begin
								c_commit_req = 1;
							end else begin
								c_done = 1;
							end
						end
					end
					if (r_makes_rd&&commit_ack[ADDR]) begin
						c_commit_req = 0;
						c_done = 1;
					end
					if (r_unit_type == 6 && br_in) begin
						c_br_ok = 0;
						if (r_control[0]) begin
							c_control[5] = ~r_control[5];
						end else begin
							c_control[5] = 1;
						end
					end
			   end
			2: begin			// mul 2 clocks
					if (schedule) begin
						c_busy = 1;
						c_busy2 = 0;
					end else
					if (r_control[0]||r_control[5]) begin // mul or B stuff
						case ({r_busy, r_busy2})
						2'b00:	; // waiting for schedule
						2'b10:begin
								c_busy2 = 1;	
								c_completed = 1;
							end 
						2'b11:begin
								c_busy = 0;
							end 
						2'b01:begin
								c_busy2 = 0;
								if (r_makes_rd) begin
									c_commit_req = 1;
								end else begin
									c_done = 1;
								end
							end
						endcase
						if (r_makes_rd&&commit_ack[ADDR]) begin
							c_commit_req = 0;
							c_done = 1;
						end
					end else begin	// divide case
						if (r_busy & !r_busy2) begin	// wait for divide done
							if (!commit_divide_busy) begin
								c_completed = 1;
								c_busy2 = r_makes_rd;
								c_busy = r_makes_rd;
								c_commit_req = r_makes_rd;
								c_done = !r_makes_rd;
							end
						end
						if (r_makes_rd&&commit_ack[ADDR]) begin
							c_commit_req = 0;
							c_busy = 0;
							c_busy2 = 0;
							c_done = 1;
						end
					end
			   end
			3: begin			// load unknown number of clocks
					if (r_load_trap) begin
						if (schedule) begin
							c_busy = 1;
							c_busy2 = 0;
							c_completed = 1;
						end else
						if (r_busy && !r_busy2) begin
							c_busy2 = 1;
						end else begin
							c_busy = 0;
							c_busy2 = 0;
							if (r_busy && r_busy2) begin
								c_done = 1;
							end
						end
					end else
					if (schedule) begin
						c_busy = 1;
						c_busy2 = 0;
					end else
					if (commit_vm_done) begin
						if (commit_vm_done_fail) begin
							c_read = 0;
							c_load_trap = 1;
							clear_immed = r_control[4];
							c_done = 0;
							c_commit_req = 0;
							c_control = (commit_vm_done_pmp?6'b000101:6'b001101);
						end
						c_vm_stall = 0;
						c_busy = 0;
						c_busy2 = 0;
						c_read = 0;
					end else
					if (r_busy & !r_busy2) begin
						if (commit_addr_done&&commit_vm_pause) begin
							c_read = 0;
							c_busy = 0;
							c_vm_stall = 0;
						end else
						if (commit_addr_done&&commit_vm_stall) begin
							c_busy = 0;
							c_busy2 = 0;
							c_read = 0;
							c_vm_stall = 1;
						end else
						if (commit_addr_done) begin	
							if (commit_addr_trap_type == 0) begin
								c_addr_done = 1;
							end else begin
								// something here for traps: commit_addr_trap_type valid here
								c_read = 0;
								c_load_trap = 1;
								c_done = 0;
								c_commit_req = 0;
								clear_immed = r_control[4];
								c_busy = 0;
								casez (commit_addr_trap_type) // synthesis full_case parallel_case
								3: c_control = 6'b001101; // load page fault
								2: c_control = 6'b000101; // load prot fault
								1: c_control = 6'b000100; // load aligned fault
								default: c_control = 6'bx;
								endcase
							end
						end
						if (commit_load_done && r_addr_done) begin
							c_completed = 1;
							c_busy2 = r_makes_rd;
							c_busy = r_makes_rd;
							c_commit_req = r_makes_rd;
							c_done = !r_makes_rd;
						end
					end
					if (r_makes_rd&&commit_ack[ADDR]) begin
						c_commit_req = 0;
						c_busy = 0;
						c_busy2 = 0;
						c_done = 1;
					end
			   end
			4: begin			// store unknown number of clocks (have to wait until no traps can happen)
					if (r_load_trap) begin
						if (schedule) begin
							c_busy = 1;
							c_busy2 = 0;
							c_completed = 1;
						end else
						if (r_busy && !r_busy2) begin
							c_busy2 = 1;
						end else begin
							c_busy = 0;
							c_busy2 = 0;
							if (r_busy && r_busy2) begin
								c_done = 1;
							end
						end
					end else
					if (schedule) begin
						c_busy = 1;
						c_busy2 = 0;
					end else
					if (r_control[5] && r_control[2:0] != 4) begin			// fence
						if (commit_vm_done) begin
							c_vm_stall = 0;
							c_read = 0;
							c_busy = 0;
							c_busy2 = 0;
						end else
						if (r_busy && !r_busy2) begin
							
							// 0		sfence.vma
							// 1		hfence.vvma
							// 2		hfence.gvma
							// 3		fence.i		
							if (commit_addr_done && commit_vm_stall) begin	
		                        if (commit_vm_done) begin
									c_vm_stall = 0;
									c_read = 0;
									c_busy = 0;
									c_busy2 = 0;
								end else begin
									c_read = 0;
									c_busy = 0;
									c_busy2 = 0;
									c_vm_stall = 1;
								end
							end else 
							if (r_control[2:0]==3?commit_load_done:r_read_d) begin // it's been accepted
								c_busy = 0;
								c_control = 6'b111000;		// pipe break
								c_unit_type = 7;
								c_read = 0;
								c_load_trap = 1;
							end
						end
					end else begin					// store and fence
						if (commit_vm_done && !r_control[5]) begin
							if (commit_vm_done_fail) begin
								c_read = 0;
								c_load_trap = 1;
								c_unit_type = 7;
								clear_immed = r_control[4];
								c_commit_req = 0;
								c_control = (commit_vm_done_pmp?6'b000111:6'b001111);
							end
							c_vm_stall = 0;
							c_read = 0;
							c_busy = 0;
							c_busy2 = 0;
						end else
						if (r_busy && !r_busy2) begin
							if (commit_addr_done && commit_vm_pause && !r_control[5]) begin
								c_read = 0;
								c_busy = 0;
								c_vm_stall = 0;
							end else
							if (commit_addr_done) begin	// it's been accepted
								if (commit_vm_stall && !r_control[5]) begin
									if (commit_vm_done) begin
										if (commit_vm_done_fail) begin
											c_read = 0;
											c_load_trap = 1;
											clear_immed = r_control[4];
											c_unit_type = 7;
											c_commit_req = 0;
											c_control = (commit_vm_done_pmp?6'b000111:6'b001111);
										end
										c_vm_stall = 0;
										c_read = 0;
										c_busy = 0;
										c_busy2 = 0;
									end else begin
										c_read = 0;
										c_busy = 0;
										c_busy2 = 0;
										c_vm_stall = 1;
									end
								end else
								if (commit_addr_trap_type == 0 || r_control[5]) begin
									c_addr_done = 1;
									if (r_control[5:4]==2'b01) begin 
										c_commit_store_req = 0;
										c_completed = 0;
									end
									c_busy2 = 1;
									//c_commit_req = !r_makes_rd;
								end else begin
									// something here for traps: commit_addr_trap_type valid here
									c_read = 0;
									c_read_d = 0;
									c_busy = 0;
									c_unit_type = 7;
									clear_immed = r_control[4];
									c_load_trap = 1;
									casez (commit_addr_trap_type) // synthesis full_case parallel_case
									3: c_control = 6'b001111; // store page fault
									2: c_control = 6'b000111; // store prot fault
									1: c_control = 6'b000110; // store aligned fault
									default: c_control = 6'bx;
									endcase
								end
							end else
							if (r_read_d && r_addr_done && (r_control[5:4]!=2'b01 || r_immed[28:27]==2'b11)) begin  // everything not AMO, but also WC
								c_commit_store_req = 1;
								c_completed = r_control[5:4]!=2'b01 || r_immed[28:27]!=2'b11;	// WC has a load as well
								c_busy2 = 1;
							end else
							if (commit_load_done) begin 
								c_commit_store_req = !r_makes_rd;
								c_completed = 1;
								c_busy2 = 1;
								c_commit_req = r_makes_rd;
							end
						end else
						if (commit_load_done&& r_control[5:4]==2'b01) begin 
							c_commit_req = 1;
							c_completed = 1;
						end else
						if (r_read_d && r_addr_done && (r_control[5:4]!=2'b01|| r_immed[28:27]==2'b11) && !r_completed) begin  // everything not AMO, but also WC
							c_commit_store_req = 1;
							c_completed = r_control[5:4]!=2'b01 || r_immed[28:27]!=2'b11;	// WC has a load as well
							c_busy2 = 1;
						end else
						if (commit_store_ack) begin
							c_commit_store_req = 0;
							if ((!r_makes_rd && !r_commit_req) || commit_ack[ADDR]) begin
								c_busy = 0;
								c_busy2 = 0;
								c_done = 1;
							end else
							if (commit_load_done&& r_control[5:4]==2'b01) begin 
								c_commit_req = 1;
								c_completed = 1;
							end
						end else
						if (commit_ack[ADDR]) begin
							c_commit_req = 0;
							if (!r_commit_store_req) begin
								c_busy = 0;
								c_busy2 = 0;
								c_done = 1;
							end
						end
					end
				end
			endcase
			if (schedule)
				c_read = 1;
			if (schedule_d)
				c_read_d = 1;
		end
	end

	reg		r_ready, r_ready_addr;
	assign ready = r_valid&(r_ready|((!r_rs1[RA-1]|commit_completed[r_rs1[LNCOMMIT-1:0]])&
								     ((!r_rs2[RA-1]|commit_completed[r_rs2[LNCOMMIT-1:0]])|!r_needs_rs2)&
								     ((!r_rs3[RA-1]|commit_completed[r_rs3[LNCOMMIT-1:0]])|!r_needs_rs3)));
	assign addr_ready = r_valid&(r_ready_addr|(!r_rs1[RA-1]|commit_completed[r_rs1[LNCOMMIT-1:0]]));
`ifdef FP
	assign data_ready = r_valid&(r_ready|((r_rs2[RA-1]==0&&!r_rs2_fp)|commit_completed[r_rs2[LNCOMMIT-1:0]]));
`else
	assign data_ready = r_valid&(r_ready|((r_rs2[RA-1]==0)|commit_completed[r_rs2[LNCOMMIT-1:0]]));
`endif

	always @(posedge clk) begin
		r_br_ok <= c_br_ok;
		r_vm_stall <= c_vm_stall;
		r_ready <= !reset&r_valid&((ready|r_force_fetch)|r_ready);
		r_ready_addr <= !reset&r_valid&((addr_ready|r_force_fetch)|r_ready_addr);
		r_busy <= c_busy&!commit_kill;
		r_busy2 <= c_busy2&!commit_kill;
		r_busy3 <= c_busy3&!commit_kill;
		r_read <= c_read;
		r_read_d <= c_read_d;
		r_wfi_pause <= c_wfi_pause;
		r_load_trap <= (!commit_ended&!commit_kill?c_load_trap:0);
		r_commit_req <= c_commit_req&!commit_ended&!commit_kill;
		r_commit_store_req <= c_commit_store_req&!commit_ended&!commit_kill&!reset;
		r_done <= c_done&c_valid&&!commit_ended&!commit_kill;
		r_valid <= c_valid&!commit_ended&!commit_kill;
		r_completed <= c_completed&!commit_ended&!commit_kill;
		r_control <= c_control;
		r_addr_done <= c_addr_done;
		r_unit_type <= c_unit_type;
`ifdef FP
		r_rd_fp <= c_rd_fp;
		r_fpu_req <= c_fpu_req;
`endif
		if (load&!commit_kill) begin
			r_force_fetch <= force_fetch;
`ifdef RENAME_OPT
			if (commit_rs1[RA-1] && rs1[RA-1] && commit_completed[commit_rs1[LNCOMMIT-1:0]] && !force_fetch) begin
				if (commit_ack[commit_rs1[LNCOMMIT-1:0]]||commit_done[commit_rs1[LNCOMMIT-1:0]]) begin
					r_rs1 <= real_rs1;
				end else begin
					r_rs1 <= commit_rs1;
				end
				r_commit_rs1 <= {1'b0, {NA-1{1'bx}}};
			end else
			if (rs1[RA-1] && (commit_ack[rs1[LNCOMMIT-1:0]]||commit_done[rs1[LNCOMMIT-1:0]]) && !force_fetch) begin
				if (commit_rs1[RA-1] && !(commit_ack[commit_rs1[LNCOMMIT-1:0]]||commit_done[commit_rs1[LNCOMMIT-1:0]])) begin
					r_rs1 <= commit_rs1;
				end else begin
					r_rs1 <= real_rs1;
				end
				r_commit_rs1 <= {1'b0, {NA-1{1'bx}}};
			end else begin
				r_rs1 <= rs1;
				r_commit_rs1 <= rs1[RA-1] ? commit_rs1 : {1'b0, {NA-1{1'bx}}};
			end

			if (commit_rs2[RA-1] && rs2[RA-1] && commit_completed[commit_rs2[LNCOMMIT-1:0]]) begin
				if (commit_ack[commit_rs2[LNCOMMIT-1:0]]||commit_done[commit_rs2[LNCOMMIT-1:0]]) begin
					r_rs2 <= real_rs2;
				end else begin
					r_rs2 <= commit_rs2;
				end
				r_commit_rs2 <= {1'b0, {NA-1{1'bx}}};
			end else
			if (rs2[RA-1] && (commit_ack[rs2[LNCOMMIT-1:0]]||commit_done[rs2[LNCOMMIT-1:0]])) begin
				if (commit_rs2[RA-1] && !(commit_ack[commit_rs2[LNCOMMIT-1:0]]||commit_done[commit_rs2[LNCOMMIT-1:0]])) begin
					r_rs2 <= commit_rs2;
				end else begin
					r_rs2 <= real_rs2;
				end
				r_commit_rs2 <= {1'b0, {NA-1{1'bx}}};
			end else begin
				r_rs2 <= rs2;
				r_commit_rs2 <= rs2[RA-1] ? commit_rs2 : {1'b0, {NA-1{1'bx}}};
			end

			if (commit_rs3[RA-1] && rs3[RA-1] && commit_completed[commit_rs3[LNCOMMIT-1:0]]) begin
				if (commit_ack[commit_rs3[LNCOMMIT-1:0]]||commit_done[commit_rs3[LNCOMMIT-1:0]]) begin
					r_rs3 <= real_rs3;
				end else begin
					r_rs3 <= commit_rs3;
				end
				r_commit_rs3 <= {1'b0, {NA-1{1'bx}}};
			end else
			if (rs3[RA-1] && (commit_ack[rs3[LNCOMMIT-1:0]]||commit_done[rs3[LNCOMMIT-1:0]])) begin
				if (commit_rs3[RA-1] && !(commit_ack[commit_rs3[LNCOMMIT-1:0]]||commit_done[commit_rs3[LNCOMMIT-1:0]])) begin
					r_rs3 <= commit_rs3;
				end else begin
					r_rs3 <= real_rs3;
				end
				r_commit_rs3 <= {1'b0, {NA-1{1'bx}}};
			end else begin
				r_rs3 <= rs3;
				r_commit_rs3 <= rs3[RA-1] ? commit_rs3 : {1'b0, {NA-1{1'bx}}};
			end
`else
			if (rs1[RA-1] && (commit_ack[rs1[LNCOMMIT-1:0]]||commit_done[rs1[LNCOMMIT-1:0]]) && !force_fetch) begin
                r_rs1 <= real_rs1;
			end else begin
				r_rs1 <= rs1;
			end
			if (rs2[RA-1] && (commit_ack[rs2[LNCOMMIT-1:0]]||commit_done[rs2[LNCOMMIT-1:0]])) begin
                r_rs2 <= real_rs2;
			end else begin
				r_rs2 <= rs2;
			end
			if (rs3[RA-1] && (commit_ack[rs3[LNCOMMIT-1:0]]||commit_done[rs3[LNCOMMIT-1:0]])) begin
                r_rs3 <= real_rs3;
			end else begin
				r_rs3 <= rs3;
			end
`endif
			r_real_rs1 <= real_rs1;
			r_real_rs2 <= real_rs2;
			r_real_rs3 <= real_rs3;
			r_rd <= rd;
			r_immed <= immed;
			r_makes_rd <= makes_rd;
			r_short <= c_short;
			r_start <= c_start;
			r_needs_rs2 <= needs_rs2;
			r_needs_rs3 <= needs_rs3;
`ifdef FP
			r_rs1_fp <= rs1_fp;
			r_rs2_fp <= rs2_fp;
			r_rs3_fp <= rs3_fp;
`endif
			r_pc <= pc;
			r_pc_dest <= pc_dest;
			r_branch_token <= branch_token;
			r_branch_token_ret <= branch_token_ret;
			//if (unit_type == 6 && control[1:0] == 2'b00) begin
				//r_pc_branch_context <= {1'b1, pc_branch_context[2:0]}; // tag it as an indirect unconditional jump
			//end
`ifdef SIMD
if (simd_enable) $display("C %d %x %x %x",$time,ADDR,{pc, 1'b0},unit_type);
`endif
		end else begin
			if (clear_immed)
				r_immed <= 0;
`ifdef TRACE_CACHE
			if (br_in) begin
				if (r_unit_type == 6 && ~r_control[0]) begin	// remember for indirect branches
					r_pc_dest <= commit_br;
				end
				if (r_unit_type == 6 && r_control[0]) begin	// remember for trace
					r_control[5] <= ~r_control[5];
				end
			end
`endif
			if (c_load_trap)
				r_makes_rd <= 0;
`ifdef RENAME_OPT
			if (r_commit_rs1[RA-1] && commit_completed[r_commit_rs1[LNCOMMIT-1:0]]) begin
				if (!(commit_ack[r_commit_rs1[LNCOMMIT-1:0]]||commit_done[r_commit_rs1[LNCOMMIT-1:0]]) && !r_force_fetch) begin
					r_rs1 <= {1'b1, r_commit_rs1[LNCOMMIT-1:0]};
				end else begin
					r_rs1 <= {1'b0, r_real_rs1};
				end
			end else 
			if (r_rs1[RA-1] && (commit_ack[r_rs1[LNCOMMIT-1:0]]||commit_done[r_rs1[LNCOMMIT-1:0]]) && !r_force_fetch) begin
				if (r_commit_rs1[RA-1] && !(commit_ack[r_commit_rs1[LNCOMMIT-1:0]]||commit_done[r_commit_rs1[LNCOMMIT-1:0]]) && !r_force_fetch) begin
					r_rs1 <= {1'b1, r_commit_rs1[LNCOMMIT-1:0]};
				end else begin
					r_rs1 <= {1'b0, r_real_rs1};
				end
			end
			if (r_commit_rs2[RA-1] && commit_completed[r_commit_rs2[LNCOMMIT-1:0]]) begin
				if (!(commit_ack[r_commit_rs2[LNCOMMIT-1:0]]||commit_done[r_commit_rs2[LNCOMMIT-1:0]]) && !r_force_fetch) begin
					r_rs2 <= {1'b1, r_commit_rs2[LNCOMMIT-1:0]};
				end else begin
					r_rs2 <= {1'b0, r_real_rs2};
				end
			end else 
			if (r_rs2[RA-1] && (commit_ack[r_rs2[LNCOMMIT-1:0]]||commit_done[r_rs2[LNCOMMIT-1:0]]) && !r_force_fetch) begin
				if (r_commit_rs2[RA-1] && !(commit_ack[r_commit_rs2[LNCOMMIT-1:0]]||commit_done[r_commit_rs2[LNCOMMIT-1:0]]) && !r_force_fetch) begin
					r_rs2 <= {1'b1, r_commit_rs2[LNCOMMIT-1:0]};
				end else begin
					r_rs2 <= {1'b0, r_real_rs2};
				end
			end
			if (r_commit_rs3[RA-1] && commit_completed[r_commit_rs3[LNCOMMIT-1:0]]) begin
				if (!(commit_ack[r_commit_rs3[LNCOMMIT-1:0]]||commit_done[r_commit_rs3[LNCOMMIT-1:0]]) && !r_force_fetch) begin
					r_rs3 <= {1'b1, r_commit_rs3[LNCOMMIT-1:0]};
				end else begin
					r_rs3 <= {1'b0, r_real_rs3};
				end
			end else 
			if (r_rs3[RA-1] && (commit_ack[r_rs3[LNCOMMIT-1:0]]||commit_done[r_rs3[LNCOMMIT-1:0]]) && !r_force_fetch) begin
				if (r_commit_rs3[RA-1] && !(commit_ack[r_commit_rs3[LNCOMMIT-1:0]]||commit_done[r_commit_rs3[LNCOMMIT-1:0]]) && !r_force_fetch) begin
					r_rs3 <= {1'b1, r_commit_rs3[LNCOMMIT-1:0]};
				end else begin
					r_rs3 <= {1'b0, r_real_rs3};
				end
			end
			if (r_commit_rs1[RA-1] && (commit_completed[r_commit_rs1[LNCOMMIT-1:0]]||commit_done[r_commit_rs1[LNCOMMIT-1:0]]||commit_ack[r_commit_rs1[LNCOMMIT-1:0]])) 
				r_commit_rs1[RA-1] <= 1'b0;
			if (r_commit_rs2[RA-1] && (commit_completed[r_commit_rs2[LNCOMMIT-1:0]]||commit_done[r_commit_rs2[LNCOMMIT-1:0]]||commit_ack[r_commit_rs2[LNCOMMIT-1:0]])) 
				r_commit_rs2[RA-1] <= 1'b0;
			if (r_commit_rs3[RA-1] && (commit_completed[r_commit_rs3[LNCOMMIT-1:0]]||commit_done[r_commit_rs3[LNCOMMIT-1:0]]||commit_ack[r_commit_rs3[LNCOMMIT-1:0]])) 
				r_commit_rs3[RA-1] <= 1'b0;
`else
			if (r_rs1[RA-1] && (commit_ack[r_rs1[LNCOMMIT-1:0]]||commit_done[r_rs1[LNCOMMIT-1:0]]) && !r_force_fetch) 
				r_rs1 <= {1'b0, r_real_rs1};
			if (r_rs2[RA-1] && (commit_ack[r_rs2[LNCOMMIT-1:0]]||commit_done[r_rs2[LNCOMMIT-1:0]])) 
				r_rs2 <= {1'b0, r_real_rs2};
			if (r_rs3[RA-1] && (commit_ack[r_rs3[LNCOMMIT-1:0]]||commit_done[r_rs3[LNCOMMIT-1:0]])) 
				r_rs3 <= {1'b0, r_real_rs3};
`endif
		end
`ifdef SIMD
if (r_valid&&commit_kill && simd_enable) $display("K %d %x %x %x", $time,ADDR,{r_pc,1'b0},r_unit_type);
if (commit_ended && simd_enable) $display("D %d %x %x %x", $time,ADDR,{r_pc,1'b0},r_unit_type);
`endif
	end

`ifdef AWS_DEBUG
`ifdef AWS_DEBUG_COMMIT
    xila_commit ila_commit(.clk(clk),
            .trig_in(trig_in),
            .trig_in_ack(trig_in_ack),
            .trig_out(trig_out),
            .trig_out_ack(trig_out_ack),

            .load(load),
            .valid(r_valid),
            .unit_type(r_unit_type),
            .schedule(schedule),
            .busy(r_busy),
            .busy2(r_busy2),
            .immed(r_immed[7:0]),
            .rs1(r_rs1),
            .rs2(r_rs2),
            .needs_rs2(r_needs_rs2),
            .commit_kill(commit_kill),
            .xxtrig(xxtrig));

    vio_commit vio_commit (.clk(clk),
           .valid(r_valid),
           .typ(r_unit_type),
           .pc({r_pc[31:1],1'b0}),
           .state({3'b0, commit_completed[r_rs1[LNCOMMIT-1:0]], commit_completed[r_rs2[LNCOMMIT-1:0]], load_addr_ready, load_addr_not_ready, commit_load_done}),
           .schedule(schedule),
           .commit_req(commit_req),
           .ready(ready),
           .rs1(r_rs1),
           .rs2(r_rs2),
           .needs_rs2(r_needs_rs2),
	       .commit_load_done(commit_load_done),
           .p0(r_busy),
           .p1(r_busy2),
           .p2(1'b0),
           .p3(1'b0));
`endif

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

