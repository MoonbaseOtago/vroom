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

`include "pred_context.si"

module pc(input clk,  input reset,
`ifdef AWS_DEBUG
	input			xxtrig,
`endif

	input	  [3:0]cpu_mode,
	input	 [15:0]asid,

	input	       dec_br_enable,
	input  [RV-1:1]dec_branch,				// predicted branch from decoder (delta of PC)
	input	  [BDEC-1:1]dec_br_offset,			// which section - end of instruction
	input	  [BDEC-1:1]dec_br_start_offset,	// which section - start of instruction

	input	       commit_br_enable,
	input    [RV-1:1]commit_br, 	// unpredicted branch from branch unit
	input  [BDEC-1:1]commit_br_dec,
	input		   commit_br_taken,
	input		   commit_br_short,
	input [$clog2(NUM_PENDING)-1:0]commit_branch_token,
	input [$clog2(NUM_PENDING_RET)-1:0]commit_branch_token_ret,

	input	       interrupt_pending,
	input		   commit_int_force_fetch,
	input	       int_br_enable,
	input	       trap_br_enable,
	input    [RV-1:1]trap_br, 	// trap branch from csr unit
	input [$clog2(NUM_PENDING)-1:0]trap_branch_token,

	input [NUM_PENDING-1:0]commit_token,
	input [NUM_PENDING_RET-1:0]commit_token_ret,

	input [(NDEC*2)-1:0]has_jmp,
	input [(NDEC*2)-1:0]jumping_term,
	input [(NDEC*2)-1:0]jumping_issue,
	input [(NDEC*2)-1:0]has_jmp_back,
	input		   jumping_stall,
	input		   rename_stall,
	input		   fetch_ok,
	input		   fetch_fail,
	input		   subr_push,
	input		   subr_pop,
	input		   subr_inc2,

	output	[(NDEC*2)-1:0]br_predict,
	output			      br_default,
	output				  pop_available,

	output	[VA_SZ-1:1]pc_dest_dec,
	output [$clog2(NUM_PENDING)-1:0]dec_branch_token,
	output [$clog2(NUM_PENDING)-1:0]dec_branch_token_prev,
	output [$clog2(NUM_PENDING_RET)-1:0]dec_branch_token_ret,
	output [$clog2(NUM_PENDING_RET)-1:0]dec_branch_token_ret_prev,

	output		   fetch_branched,

	output		   dec_stall,
	output		   br_stall,
	output		   issue_interrupt,
	output		   issue_fetch_trap,
	output		   pc_stall,
	output [RV-1:1]pc_out,
	output [RV-1:1]pc_fetch);
    parameter BDEC=5;
    parameter HART=0;
	parameter RV=64;
	parameter VA_SZ=64;
	parameter NPHYS=56;
    parameter NHART=1;
    parameter LNHART=0;
	parameter PC_BRANCH_HISTORY=16;
	parameter HISTORY_DEPTH=8;
	parameter NDEC=4;
	parameter CALL_STACK_SIZE=32;
	parameter NCOMMIT_BRANCH=2;
	parameter NUM_PENDING=32;
	parameter NUM_PENDING_RET=8;

	wire clear_sup = 0;	// for the moment FIXME hypervisor
	reg [15:0]r_asid;
	reg  [3:0]r_cpu_mode;
	wire clear_user = (asid != r_asid) && (cpu_mode[0]);
	wire clear_stack = (asid != r_asid) || (cpu_mode!=r_cpu_mode);
	wire clear_q = (cpu_mode!=r_cpu_mode);

	reg	[RV-1:1]r_pc, c_pc;
	assign pc_out = r_pc;

	reg  r_pc_stall, c_pc_stall;	// to stall PC fetch when there's no point (after an unpredicted jump, a trap etc)
	//assign pc_stall = r_pc_stall;
	assign pc_stall = (rename_stall&!r_dec_stall)|r_pc_stall;

	reg	[RV-1:1]r_pc_fetch, c_pc_fetch;
	assign pc_fetch = r_pc_fetch;

	reg [RV-1:1]ret_addr;
	reg	 [BDEC:1]in_v;
	reg  push_cs_stack, pop_cs_stack;
	

	reg	[RV-1:1]r_pc_dest_fetch, c_pc_dest_fetch;
	reg	[RV-1:1]r_pc_dest_dec, c_pc_dest_dec;
	assign pc_dest_dec = r_pc_dest_dec[VA_SZ-1:1];
    reg [$clog2(NUM_PENDING)-1:0]r_dec_branch_token, r_dec_branch_token_prev;
	assign dec_branch_token = r_dec_branch_token;
	assign dec_branch_token_prev = r_dec_branch_token_prev;
    reg [$clog2(NUM_PENDING_RET)-1:0]r_dec_branch_token_ret, r_dec_branch_token_ret_prev;
	assign dec_branch_token_ret = r_dec_branch_token_ret;
	assign dec_branch_token_ret_prev = r_dec_branch_token_ret_prev;

	reg         r_br_stall, c_br_stall;
	assign		br_stall = r_br_stall;
	reg         r_dec_stall, c_dec_stall;
	assign		dec_stall = r_dec_stall;
	always @(posedge clk) begin
		r_asid <= asid;
		r_cpu_mode <= cpu_mode;
	end


	wire				  predict_branch_taken;
	wire	     [VA_SZ-1:1]predict_branch_pc;
	wire				  predict_branch_valid;
	wire  [$clog2(2*NDEC)-1:0]predict_branch_decoder;

	reg					  prediction_used, prediction_taken;	
	reg					  prediction_wrong, prediction_wrong_taken;	
	reg			[BDEC-1:1]prediction_wrong_dec;

	wire	[$clog2(NUM_PENDING)-1:0]push_token;
	wire	[$clog2(NUM_PENDING_RET)-1:0]push_token_ret;

	wire	     [VA_SZ-1:1]return_branch_pc;
	wire				  return_branch_valid;

	reg [$clog2(2*NDEC)-1:0]push_branch_decoder;
	reg					push_enable;
	reg					push_noissue;
	reg					push_taken;
	reg		    [RV-1:1]push_dest;

	PRED_STATE			prediction_context;
	PRED_STATE			r_fetch_prediction_context, c_fetch_prediction_context;
	PRED_STATE			push_context;
	reg					push_force_default = 0;
	reg					push_force_taken = 0;
	
	always @(*) begin
		push_context.global_history = r_fetch_prediction_context.global_history;
		push_context.bimodal_prediction_dec = r_fetch_prediction_context.bimodal_prediction_dec;
		push_context.global_prediction_dec = r_fetch_prediction_context.global_prediction_dec;
		casez({push_force_taken, push_force_default}) // synthesis full_case parallel_case
		2'b1?:	begin
					push_context.global_history[3:0] = {dec_br_offset, 1'b1};
					push_context.bimodal_prediction_prev = 2;		// mispredict use branch dir
					push_context.global_prediction_prev = 2;
					push_context.combined_prediction_prev = 1;
					push_context.global_prediction_dec = dec_br_offset;
					push_context.bimodal_prediction_dec = dec_br_offset;
				end
		2'b?1:	begin
					push_context.global_history[3:0] = 4'b0;
					push_context.bimodal_prediction_prev = 1;
					push_context.global_prediction_prev = 1;
					push_context.combined_prediction_prev = 1;
					push_context.global_prediction_dec = 0;
					push_context.bimodal_prediction_dec = 0;
				end
		2'b00:	begin
					push_context.bimodal_prediction_prev = r_fetch_prediction_context.bimodal_prediction_prev;
					push_context.global_prediction_prev = r_fetch_prediction_context.global_prediction_prev;
					push_context.combined_prediction_prev = r_fetch_prediction_context.combined_prediction_prev;
					push_context.global_prediction_dec = r_fetch_prediction_context.global_prediction_dec;
					push_context.bimodal_prediction_dec = r_fetch_prediction_context.bimodal_prediction_dec;
				end
		endcase
	end

	reg		fixup_dest;
		
	
	bpred #(.VA_SZ(VA_SZ), .NUM_PENDING(NUM_PENDING), .NUM_PENDING_RET(NUM_PENDING_RET), .BDEC(BDEC), .NDEC(NDEC), .CALL_STACK_SIZE(CALL_STACK_SIZE))pred(
		.clk(clk),
`ifdef RAMSYNTH
		.clkX4(clkX4),   // 4x clock for sync dual port ram
		.clkX4_phase(clkX4_phase), // clkX4_phase[0] samples true on rising edge of clk
`endif
		.cpu_mode(cpu_mode),
		.reset(reset),

		.pc(r_pc[VA_SZ-1:1]),
		.predict_branch_taken(predict_branch_taken),
		.predict_branch_pc(predict_branch_pc),
		.predict_branch_valid(predict_branch_valid),
		.predict_branch_decoder(predict_branch_decoder),

		.prediction_used(prediction_used),
		.prediction_taken(prediction_taken),
		.prediction_wrong(prediction_wrong),
		.prediction_wrong_taken(prediction_wrong_taken),
		.prediction_wrong_dec(prediction_wrong_dec),
		.prediction_context(prediction_context),

		.push_enable(push_enable),
		.push_noissue(push_noissue),
		.push_pc(r_pc_fetch[VA_SZ-1:1]),
		.push_dest(push_dest[VA_SZ-1:1]),
		.push_branch_decoder(push_branch_decoder),
		.push_taken(push_taken),
		.push_token(push_token),
		.push_token_ret(push_token_ret),
		.push_context(push_context),

		.fixup_dest(fixup_dest),
		.fixup_dest_pc(dec_branch[VA_SZ-1:1]),
		.fixup_dest_dec(dec_br_offset),

		.trap_shootdown(trap_br_enable),			// trap
		.trap_shootdown_token(trap_branch_token),

		.commit_shootdown(commit_br_enable),		// commitq break shootdown (branch miss)
		.commit_shootdown_token(commit_branch_token),	// latest killed entry
		.commit_shootdown_token_ret(commit_branch_token_ret),	// latest killed entry
		.commit_shootdown_dec(commit_br_dec),
		.commit_shootdown_short(commit_br_short),
		.commit_shootdown_taken(commit_br_taken),
		.commit_shootdown_dest(commit_br[VA_SZ-1:1]),			// 

		.commit_token(commit_token),			// bit encoded tokens from the commitQ commit stage
		.commit_token_ret(commit_token_ret),			

		.push_cs_stack(!rename_stall&&push_cs_stack),
		.pop_cs_stack(!rename_stall&&pop_cs_stack),
		.ret_addr(ret_addr[VA_SZ-1:1]),
		.pop_available(pop_available),
		.return_branch_valid(return_branch_valid),
		.return_branch_pc(return_branch_pc),

		.clear_user(clear_user),
		.clear_sup(clear_sup) );

	//	pipe stage input to icache 
	reg			r_pc_br_default, c_pc_br_default;
	reg			r_pc_br_taken, c_pc_br_taken;
	reg			r_pc_restart, c_pc_restart;
	reg	[$clog2(2*NDEC)-1:0]r_pc_br_predict_dec, c_pc_br_predict_dec;
	wire 	[RV-1:BDEC]inc = r_pc[RV-1:BDEC]+1;
	wire [RV-1:1]branch_next = {inc, {BDEC-1{1'b0}}};
	wire 	[RV-1:BDEC]fetch_inc = r_pc_fetch[RV-1:BDEC]+1;
	wire [RV-1:1]branch_next_fetch = {fetch_inc, {BDEC-1{1'b0}}};
	reg  [2:0]r_fetch_state, c_fetch_state;
	reg		  r_read_stall, c_read_stall;
	reg		  r_pend_int, c_pend_int;
	reg		  r_issue_interrupt, c_issue_interrupt;
	assign		issue_interrupt = r_issue_interrupt;
	reg		  r_interrupt_reloading, c_interrupt_reloading;
	reg		  r_pend_trap, c_pend_trap;
	reg		  r_issue_fetch_trap, c_issue_fetch_trap;
	assign		issue_fetch_trap = r_issue_fetch_trap;
	
	// pipe stage output of icache, input to decode

	reg			r_pc_branched, c_pc_branched;
	reg			r_fetch_branched, c_fetch_branched;
	assign		fetch_branched = r_fetch_branched&&(!r_dec_stall || r_issue_interrupt);
	reg			r_fetch_br_default, c_fetch_br_default;
	reg	[2*NDEC-1:0]r_fetch_br_predict_dec_exp, c_fetch_br_predict_dec_exp;
	reg	[$clog2(2*NDEC)-1:0]r_fetch_br_predict_dec, c_fetch_br_predict_dec;
	reg		    r_fetch_br_valid, c_fetch_br_valid;
	reg		    r_fetch_br_taken, c_fetch_br_taken;
	reg		    r_pc_br_valid, c_pc_br_valid;
	reg [2*NDEC-1:0]expanded_r_pc_br_predict;
	reg			r_fetch_restart, c_fetch_restart;
	always @(*)
	if (!c_fetch_br_valid || !c_fetch_br_taken) begin
		 c_fetch_br_predict_dec_exp = 8'b0000_0000;
	end else
	case (c_fetch_br_predict_dec) // synthesis full_case parallel_case
    0: c_fetch_br_predict_dec_exp = 8'b0000_0001;
    1: c_fetch_br_predict_dec_exp = 8'b0000_0010;
    2: c_fetch_br_predict_dec_exp = 8'b0000_0100;
    3: c_fetch_br_predict_dec_exp = 8'b0000_1000;
    4: c_fetch_br_predict_dec_exp = 8'b0001_0000;
    5: c_fetch_br_predict_dec_exp = 8'b0010_0000;
    6: c_fetch_br_predict_dec_exp = 8'b0100_0000;
    7: c_fetch_br_predict_dec_exp = 8'b1000_0000;
    endcase
	reg [$clog2(NDEC*2)-1:0] decode_has_jmp; 
	always @(*)						// FIXME make size generic
	casez (has_jmp&has_jmp_back)	// synthesis full_case parallel_case
	8'b????_???1: decode_has_jmp = 0;
	8'b????_??10: decode_has_jmp = 1;
	8'b????_?100: decode_has_jmp = 2;
	8'b????_1000: decode_has_jmp = 3;
	8'b???1_0000: decode_has_jmp = 4;
	8'b??10_0000: decode_has_jmp = 5;
	8'b?100_0000: decode_has_jmp = 6;
	8'b1000_0000: decode_has_jmp = 7;
	endcase

	reg [$clog2(NDEC*2)-1:0]unconditional_jmp_offset;	
	reg					    unconditional_jmp;			// unconditional jump
	reg						might_branch;
	always @(*)								// FIXME make size generic
	casez ({r_pc_fetch[BDEC-1:1], jumping_term&~jumping_issue}) // synthesis full_case parallel_case
	11'b000_????_???1:	begin unconditional_jmp = 1; unconditional_jmp_offset = 0; might_branch = 0; end
	11'b000_????_??10:	begin unconditional_jmp = 1; unconditional_jmp_offset = 1; might_branch = |jumping_term[0:0]; end
	11'b000_????_?100:	begin unconditional_jmp = 1; unconditional_jmp_offset = 2; might_branch = |jumping_term[1:0]; end
	11'b000_????_1000:	begin unconditional_jmp = 1; unconditional_jmp_offset = 3; might_branch = |jumping_term[2:0]; end
	11'b000_???1_0000:	begin unconditional_jmp = 1; unconditional_jmp_offset = 4; might_branch = |jumping_term[3:0]; end
	11'b000_??10_0000:	begin unconditional_jmp = 1; unconditional_jmp_offset = 5; might_branch = |jumping_term[4:0]; end
	11'b000_?100_0000:	begin unconditional_jmp = 1; unconditional_jmp_offset = 6; might_branch = |jumping_term[5:0]; end
	11'b000_1000_0000:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = |jumping_term[6:0]; end
	11'b000_0000_0000:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	11'b001_????_??1?:	begin unconditional_jmp = 1; unconditional_jmp_offset = 1; might_branch = 0; end
	11'b001_????_?10?:	begin unconditional_jmp = 1; unconditional_jmp_offset = 2; might_branch = |jumping_term[1:1]; end
	11'b001_????_100?:	begin unconditional_jmp = 1; unconditional_jmp_offset = 3; might_branch = |jumping_term[2:1]; end
	11'b001_???1_000?:	begin unconditional_jmp = 1; unconditional_jmp_offset = 4; might_branch = |jumping_term[3:1]; end
	11'b001_??10_000?:	begin unconditional_jmp = 1; unconditional_jmp_offset = 5; might_branch = |jumping_term[4:1]; end
	11'b001_?100_000?:	begin unconditional_jmp = 1; unconditional_jmp_offset = 6; might_branch = |jumping_term[5:1]; end
	11'b001_1000_000?:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = |jumping_term[6:1]; end
	11'b001_0000_000?:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	11'b010_????_?1??:	begin unconditional_jmp = 1; unconditional_jmp_offset = 2; might_branch = 0; end
	11'b010_????_10??:	begin unconditional_jmp = 1; unconditional_jmp_offset = 3; might_branch = |jumping_term[2:2]; end
	11'b010_???1_00??:	begin unconditional_jmp = 1; unconditional_jmp_offset = 4; might_branch = |jumping_term[3:2]; end
	11'b010_??10_00??:	begin unconditional_jmp = 1; unconditional_jmp_offset = 5; might_branch = |jumping_term[4:2]; end
	11'b010_?100_00??:	begin unconditional_jmp = 1; unconditional_jmp_offset = 6; might_branch = |jumping_term[5:2]; end
	11'b010_1000_00??:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = |jumping_term[6:2]; end
	11'b010_0000_00??:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	11'b011_????_1???:	begin unconditional_jmp = 1; unconditional_jmp_offset = 3; might_branch = 0; end
	11'b011_???1_0???:	begin unconditional_jmp = 1; unconditional_jmp_offset = 4; might_branch = |jumping_term[3:3]; end
	11'b011_??10_0???:	begin unconditional_jmp = 1; unconditional_jmp_offset = 5; might_branch = |jumping_term[4:3]; end
	11'b011_?100_0???:	begin unconditional_jmp = 1; unconditional_jmp_offset = 6; might_branch = |jumping_term[5:3]; end
	11'b011_1000_0???:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = |jumping_term[6:3]; end
	11'b011_0000_0???:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	11'b100_???1_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 4; might_branch = 0; end
	11'b100_??10_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 5; might_branch = |jumping_term[4:4]; end
	11'b100_?100_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 6; might_branch = |jumping_term[5:4]; end
	11'b100_1000_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = |jumping_term[6:4]; end
	11'b100_0000_????:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	11'b101_??1?_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 5; might_branch = 0; end
	11'b101_?10?_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 6; might_branch = |jumping_term[5:5]; end
	11'b101_100?_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = |jumping_term[6:5]; end
	11'b101_000?_????:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	11'b110_?1??_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 6; might_branch = 0; end
	11'b110_10??_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = |jumping_term[6:6]; end
	11'b110_00??_????:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	11'b111_1???_????:	begin unconditional_jmp = 1; unconditional_jmp_offset = 7; might_branch = 0; end
	11'b111_0???_????:	begin unconditional_jmp = 0; unconditional_jmp_offset = 'bx; might_branch = 'bx; end

	default:			begin unconditional_jmp = 'bx; unconditional_jmp_offset = 'bx; might_branch = 'bx; end
	endcase

	always @(*) begin
		in_v = dec_br_start_offset+(subr_inc2?1:2);
		ret_addr = {in_v[BDEC]?fetch_inc:r_pc_fetch[RV-1:BDEC], in_v[BDEC-1:1]};
	end

	always @(posedge clk) begin
		r_fetch_state <= c_fetch_state;
		r_pc <= c_pc;
		r_pc_stall <= c_pc_stall;
		r_pc_fetch <= c_pc_fetch;
		r_dec_stall <= c_dec_stall;
		r_br_stall <= c_br_stall;
		r_pc_br_valid <= c_pc_br_valid;
		r_pc_br_taken <= c_pc_br_taken;
		r_pc_br_default <= c_pc_br_default;
		r_pc_dest_fetch <= c_pc_dest_fetch;
		r_pc_br_predict_dec <= c_pc_br_predict_dec;
		//if (!rename_stall)
		if (!dec_stall&&!rename_stall) begin
			r_pc_dest_dec <= c_pc_dest_dec;
			r_dec_branch_token <= push_token;
			r_dec_branch_token_ret <= push_token_ret;
			r_dec_branch_token_prev <= r_dec_branch_token;
			r_dec_branch_token_ret_prev <= r_dec_branch_token_ret;
		end
		r_pc_branched <= c_pc_branched;
		r_pc_restart <= c_pc_restart;
		r_fetch_branched <= c_fetch_branched;
		r_fetch_br_default <= c_fetch_br_default;
		r_fetch_prediction_context <= c_fetch_prediction_context;
		r_fetch_br_predict_dec <= c_fetch_br_predict_dec;
		r_fetch_br_predict_dec_exp <= c_fetch_br_predict_dec_exp;
		r_fetch_br_taken <= c_fetch_br_taken;
		r_fetch_br_valid <= c_fetch_br_valid;
		r_fetch_restart <= c_fetch_restart;
		r_read_stall <= c_read_stall;
		r_pend_int <= c_pend_int;
		r_issue_interrupt <= c_issue_interrupt;
		r_interrupt_reloading <= c_interrupt_reloading;
		r_pend_trap <= c_pend_trap;
		r_issue_fetch_trap <= c_issue_fetch_trap;
	end

	assign	br_predict = r_fetch_br_predict_dec_exp;
	assign	br_default = r_fetch_br_default;
	
	//
	//			pc ->	----------			r_pc
	//					| icache |
	//			fetch ->----------			r_pc_fetch
	//					| decode |
	//			decode->----------   ->		r_
	//					   ...
	//
	//	
	//	traps take priority
	//		trap_br_enable		- must take trap
	//		trap_br				- where to branch to
	//
	//	missed branches are next
	//		commit_br_enable	- branch miss	
	//		commit_br 
	//		commit_br			- where to branch to
	//
	//	branch history updated - only generated from an instruction that will be commited (in order)
	//	
	//		commit_bt_update	- flag to say this data is valid
	//		commit_br call		- branch was a call
	//		commit_br_ret		- branch was a call ret
	//
	//	branches from decode
	//	fetch gives us:
	//
	//		dec_br_enable		- we should branch
	//		dec_br_offset		- where we got the branch from (index, not PC address)
	//		dec_br				- how much we're branching by
	//
	//	outputs 
	//		br_pred[7:0]		- branches are predicted for this location (no issue past them if taken)
	//		br_taken[7:0]		- branch is taken
	//	
	//	types of branches
	//		j or jal			- taken, j swallowed, jal ra stacks ret addr
	//		jalr x0, 0(ra)		- predicted from stack otherwise stall subsequent ins
	//		jalr rd, xx(r1)		- predicted otherwise stall subsequent ins, if rd==ra stack ret addr
	//		bxx a,b				- predicted, def taken for back, nt for forward
	//		

	always @(*) begin
		fixup_dest = 0;
		prediction_used = 0;
		prediction_taken = 'bx;
		prediction_wrong = 0;
		prediction_wrong_taken = 'bx;
		prediction_wrong_dec = 'bx;
		push_enable = 0;
		push_noissue = 'bx;
		push_branch_decoder = 'bx;
		push_taken = 1'bx;
		push_dest = 'bx;
		push_force_default = 0;
		push_force_taken = 0;
		c_pc_stall = r_pc_stall;
		c_fetch_br_default = r_fetch_br_default;
		c_fetch_prediction_context = r_fetch_prediction_context;
		c_fetch_br_predict_dec = r_fetch_br_predict_dec;
		c_fetch_br_valid = r_fetch_br_valid;
		c_fetch_br_taken = r_fetch_br_taken;
		c_fetch_restart = (reset?0:r_fetch_restart);
		c_pc_br_valid = r_pc_br_valid;
		c_pc_dest_dec = r_pc_dest_fetch;
		c_pc_dest_fetch = r_pc_dest_fetch;
		c_read_stall = 0;
		c_pc_fetch = 63'bx;
		push_cs_stack = subr_push;
		pop_cs_stack = subr_pop;
		c_pc_branched = 0;
		c_fetch_branched = !reset&r_fetch_branched&r_issue_interrupt;
		c_br_stall = 0;
		c_pc_br_default = r_pc_br_default;
		c_pc_br_taken = r_pc_br_taken;
		c_pc_br_predict_dec = r_pc_br_predict_dec;
		c_pc_restart = r_pc_restart;
		c_pend_int = reset?0:int_br_enable|trap_br_enable|commit_br_enable?0:!rename_stall&&r_issue_interrupt&&!r_pend_int?1:r_pend_int;
		c_pend_trap = r_pend_trap&!reset;
		c_interrupt_reloading = !reset && commit_br_enable&r_issue_interrupt;
		c_issue_interrupt = !reset && (!(rename_stall|trap_br_enable|commit_br_enable)&interrupt_pending&!int_br_enable&!r_pend_int || (r_issue_interrupt&&rename_stall) || r_interrupt_reloading);
		c_issue_fetch_trap = !(reset|rename_stall|trap_br_enable|commit_br_enable)&&!interrupt_pending&&!int_br_enable&&!r_pend_trap&&fetch_fail&&r_fetch_state[0] || (!reset&&r_issue_fetch_trap&&rename_stall);
		if (reset || trap_br_enable || commit_br_enable || int_br_enable || (!rename_stall&&interrupt_pending&&!r_pend_int) || fetch_fail&r_fetch_state[0]&!r_pend_trap || commit_int_force_fetch) begin // reset state machine
			c_pc_fetch = 63'bx;
			c_fetch_branched = 0;
			c_pc_dest_fetch = 63'bx;
			c_pc_branched = 1;
			c_fetch_br_default = 1;
			c_pc_br_default = 1;
			c_pc_br_valid = 0;
			c_pc_br_taken = 1'bx;
			c_pc_br_predict_dec = 'bx;
			c_fetch_br_predict_dec = 'bx;
			c_pc_restart = !commit_br_taken;
			casez ({reset, int_br_enable, trap_br_enable, commit_br_enable})	// synthesis full_case parallel_case
			4'b01??,																// interrupt service
			4'b0?1?: c_pc = trap_br;							// trap 
			4'b0001: c_pc = commit_br;							// mispredict
			default: c_pc = ~((1<<(VA_SZ-2))-1);				// reset into ROM;
			endcase
			c_dec_stall = 1; 
			c_pc_stall = c_issue_interrupt|c_issue_fetch_trap|commit_int_force_fetch;
			c_br_stall = !reset&&(trap_br_enable||commit_br_enable);
			c_fetch_state = (commit_int_force_fetch|c_issue_interrupt|c_issue_fetch_trap?3'b100:3'b001);
			c_pend_trap = reset?0:int_br_enable|trap_br_enable|commit_br_enable?0:!(rename_stall|trap_br_enable)&fetch_fail&r_fetch_state[0]&~interrupt_pending&~r_pend_trap?1:r_pend_trap;
			if (!(reset|rename_stall|trap_br_enable|commit_br_enable)&interrupt_pending&!int_br_enable&!r_pend_int || (!reset&&r_issue_interrupt&&rename_stall)) begin
				casez ({reset, trap_br_enable, commit_br_enable})	// synthesis full_case parallel_case
				3'b01?:  begin
							c_pc_fetch = trap_br;			// trap 
							c_fetch_branched = 1;
						 end
				3'b001:  begin
							c_pc_fetch = commit_br;		// mispredict
							c_fetch_branched = 1;
						end
				default: begin
							if (interrupt_pending && r_fetch_state[1]) begin
								c_pc_fetch = (dec_br_enable?(jumping_stall?r_pc:dec_branch):branch_next_fetch);
								c_fetch_branched = dec_br_enable&&jumping_stall?r_pc_branched:dec_br_enable;
							end else begin
								c_pc_fetch = r_pc;
								c_fetch_branched = r_pc_branched;
							end
						 end
				endcase
			end else begin
				c_pc_fetch = r_pc;
			end
		end else
		casez (r_fetch_state)	// synthesis full_case parallel_case
		3'b??1:						// state 0 is "cache read request running, no valid fetched data
			if (fetch_ok) begin		// we will have fetch data in next clock
				c_fetch_state = 3'b010;
				c_dec_stall = 0;
				c_pc_restart = 0;
				c_pc_fetch = r_pc;
				c_fetch_branched = r_pc_branched;
				//c_fetch_br_default = r_pc_br_default&!predict_branch_valid;
				c_fetch_br_default = !predict_branch_valid;
				//c_fetch_br_taken = r_pc_br_taken|(predict_branch_valid && predict_branch_taken && r_pc[3:1] <= predict_branch_decoder);
				c_fetch_br_taken = (predict_branch_valid && predict_branch_taken && r_pc[3:1] <= predict_branch_decoder);
				//c_fetch_br_valid = r_pc_br_valid|predict_branch_valid;
				c_fetch_br_valid = predict_branch_valid;
				c_pc_dest_dec = r_pc_dest_dec;
				c_pc_br_valid = predict_branch_valid;
				prediction_used = !r_pc_restart;
				c_fetch_restart = r_pc_restart;
				c_fetch_prediction_context = prediction_context;
				if (predict_branch_valid) begin
					if (predict_branch_taken && r_pc[3:1] <= predict_branch_decoder) begin
						c_pc = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
						c_pc_branched = 1;
						c_pc_br_default = 0;
						c_pc_br_taken = 1;
						c_pc_dest_fetch = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
						c_fetch_br_predict_dec = predict_branch_decoder;
						c_pc_br_predict_dec = predict_branch_decoder;
						prediction_taken = 1;
					end else begin
						c_pc = branch_next;
						c_pc_branched = 0;
						c_pc_br_default = 0;
						c_pc_br_taken = 0;
						c_pc_dest_fetch = branch_next;
						c_pc_br_predict_dec = 'bx;
						c_fetch_br_predict_dec = 'bx;
						prediction_taken = 0;
					end
				end else begin
					c_pc = branch_next;
					c_pc_branched = 0;
					c_pc_br_default = 1;
					c_pc_br_taken = 0;
					c_pc_dest_fetch = branch_next;
					c_pc_br_predict_dec = 'bx;
					c_fetch_br_predict_dec = 'bx;
					prediction_taken = 0;
				end
			end else begin			// waiting for cache data (probably doing a cache-miss)
				c_fetch_state = 3'b001;	
				c_dec_stall = 1;
				c_pc = r_pc;
				c_pc_branched = r_pc_branched;
				c_pc_dest_fetch = 63'bx;
				c_pc_fetch = 63'bx;
				c_pc_br_predict_dec = 'bx;
				c_fetch_branched = 0;
			end
		3'b?1?:						// state 1 is "cache read request running, valid fetched data
            if (jumping_stall) begin	// stall until trap/mispredict/etc
				if (rename_stall) begin
					c_pc = r_pc;
					c_pc_branched = r_pc_branched;
					c_pc_fetch = r_pc_fetch;
					c_fetch_branched = r_fetch_branched;
					c_fetch_state = 3'b010;
					c_dec_stall = 0;            // invalidate current fetch
					c_fetch_br_default = r_fetch_br_default;
				end else
				if (dec_br_enable && return_branch_valid) begin
					if (r_pc != {{RV-VA_SZ{return_branch_pc[VA_SZ-1]}}, return_branch_pc}) begin
						push_enable = 1;
						push_noissue = unconditional_jmp && !might_branch && (!(r_fetch_br_valid && r_fetch_br_taken) || r_fetch_br_default || unconditional_jmp_offset <= r_fetch_br_predict_dec);
						push_taken = 1; //(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp;
						push_branch_decoder = (unconditional_jmp && (!(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp_offset <= r_fetch_br_predict_dec)) ? unconditional_jmp_offset : r_fetch_br_valid && r_fetch_br_taken ? r_fetch_br_predict_dec : dec_br_offset;
						push_dest = {{RV-VA_SZ{return_branch_pc[VA_SZ-1]}}, return_branch_pc};
					//	c_fetch_br_default = r_pc_br_default;
						c_fetch_br_default = 1;
						c_fetch_br_taken = r_pc_br_taken;
						c_fetch_br_valid = r_pc_br_valid;
						c_fetch_br_predict_dec = r_pc_br_predict_dec;
						c_pc_br_valid = 0;
						c_pc_br_default = 1;
						c_pc_br_taken = 1'bx;
						c_pc_br_predict_dec = dec_br_offset;
						c_pc = {{RV-VA_SZ{return_branch_pc[VA_SZ-1]}}, return_branch_pc};
						c_pc_dest_dec = {{RV-VA_SZ{return_branch_pc[VA_SZ-1]}}, return_branch_pc};
						c_pc_branched = 1;
						c_dec_stall = 1;            // invalidate current fetch
						c_pc_fetch = 63'bx;
						c_fetch_branched = 0;
						c_fetch_state = 3'b001;
					end else begin
						if (!fetch_ok) begin
							c_pc_dest_fetch = r_pc_dest_fetch;
							c_pc = r_pc;
							c_pc_branched = r_pc_branched;
							c_fetch_state = 3'b001;	
							c_dec_stall = 1;
							c_pc_fetch = 64'bx;
							c_fetch_branched = 0;
						end else begin
							push_enable = 1;
							push_noissue = unconditional_jmp && !might_branch && (!(r_fetch_br_valid && r_fetch_br_taken) || r_fetch_br_default || unconditional_jmp_offset <= r_fetch_br_predict_dec);
							push_taken = (r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp;
							push_branch_decoder = (unconditional_jmp && (!(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp_offset <= r_fetch_br_predict_dec)) ? unconditional_jmp_offset : r_fetch_br_default ? dec_br_offset :  r_fetch_br_predict_dec;
							push_dest = r_pc;
							c_fetch_state = 3'b010;
							c_dec_stall = 0;
							c_pc_dest_dec = {{RV-VA_SZ{return_branch_pc[VA_SZ-1]}}, return_branch_pc};
							c_pc_fetch = r_pc;
							c_fetch_branched = 1;
							//c_fetch_br_default = r_pc_br_default&!predict_branch_valid;
							c_fetch_br_default = !predict_branch_valid;
							//c_fetch_br_taken = r_pc_br_taken;
							c_fetch_br_taken = (predict_branch_valid && predict_branch_taken && r_pc[3:1] <= predict_branch_decoder);
							//c_fetch_br_valid = r_pc_br_valid|predict_branch_valid;
							c_fetch_br_valid = predict_branch_valid;
							c_pc_br_valid = predict_branch_valid;
							prediction_used = 1;
							c_fetch_prediction_context = prediction_context;
							if (predict_branch_valid) begin
								if (predict_branch_taken && r_pc[3:1] <= predict_branch_decoder) begin
									c_pc = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
									c_pc_branched = 1;
									c_pc_br_default = 0;
									c_pc_br_taken = 1;
									c_fetch_br_predict_dec = predict_branch_decoder;
									c_pc_br_predict_dec = predict_branch_decoder;
									c_pc_dest_fetch = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
									prediction_taken = 1;
								end else begin
									c_pc = branch_next;
									c_pc_branched = 0;
									c_pc_br_default = 0;
									c_pc_br_taken = 0;
									c_pc_br_predict_dec = 'bx;
									c_fetch_br_predict_dec = 'bx;
									prediction_taken = 0;
								end
							end else begin
								c_pc = branch_next;
								c_pc_branched = 0;
								c_pc_br_default = 1;
								c_pc_br_taken = 0;
								c_pc_dest_fetch = branch_next;
								c_pc_br_predict_dec = 'bx;
								c_fetch_br_predict_dec = 'bx;
								prediction_taken = 0;
							end
						end
					end
				end else
				if (!r_fetch_br_default && |r_fetch_br_predict_dec_exp) begin
					if (fetch_ok) begin
						push_enable = |has_jmp;
						push_noissue = unconditional_jmp && !might_branch && (!(r_fetch_br_valid && r_fetch_br_taken) || r_fetch_br_default || unconditional_jmp_offset <= r_fetch_br_predict_dec);
						push_taken = (r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp;
						push_branch_decoder = (unconditional_jmp && (!(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp_offset <= r_fetch_br_predict_dec)) ? unconditional_jmp_offset : r_fetch_br_default ? dec_br_offset :  r_fetch_br_predict_dec;
						push_dest = r_pc;
						c_fetch_state = 3'b010;
						c_dec_stall = 0;

						c_pc_fetch = r_pc;
						c_fetch_branched = r_pc_branched;
						//c_fetch_br_default = r_pc_br_default&!predict_branch_valid;
						c_fetch_br_default = !predict_branch_valid;
						//c_fetch_br_taken = r_pc_br_taken|(predict_branch_valid && predict_branch_taken && r_pc[3:1] <= predict_branch_decoder);
						c_fetch_br_taken = (predict_branch_valid && predict_branch_taken && r_pc[3:1] <= predict_branch_decoder);
						//c_fetch_br_valid = r_pc_br_valid|predict_branch_valid;
						c_fetch_br_valid = predict_branch_valid;

						c_pc_br_valid = predict_branch_valid;
						prediction_used = 1;
						c_fetch_prediction_context = prediction_context;
						if (predict_branch_valid) begin
							if (predict_branch_taken && r_pc[3:1] <= predict_branch_decoder) begin
								c_pc = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
								c_pc_branched = 1;
								c_pc_br_default = 0;
								c_pc_br_taken = 1;
								c_pc_br_predict_dec = predict_branch_decoder;
								c_fetch_br_predict_dec = predict_branch_decoder;
								c_pc_dest_fetch = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
								prediction_taken = 1;
							end else begin
								c_pc = branch_next;
								c_pc_branched = 0;
								c_pc_br_default = 0;
								c_pc_br_taken = 0;
								c_pc_br_predict_dec = 'bx;
								c_fetch_br_predict_dec = 'bx;
								c_pc_dest_fetch = branch_next;
								prediction_taken = 0;
							end
						end else begin
							c_pc = branch_next;
							c_pc_branched = 0;
							c_pc_br_default = 1;
							c_pc_br_taken = 0;
							c_pc_br_predict_dec = 'bx;
							c_fetch_br_predict_dec = 'bx;
							c_pc_dest_fetch = branch_next;
							prediction_taken = 0;
						end
					end else begin
						c_pc_dest_fetch = r_pc_dest_fetch;
						c_pc = r_pc;
						c_pc_branched = r_pc_branched;
						c_fetch_state = 3'b001;	
						c_dec_stall = 1;
						c_pc_fetch = 64'bx;
						c_fetch_branched = 0;
					end
				end else begin
					if (fetch_ok) begin
						push_enable = |has_jmp;
						push_noissue = 0;
						push_taken = 1;
						push_branch_decoder = unconditional_jmp_offset;
						push_dest = 'bx;
						c_fetch_state = 3'b100;
						c_pc = r_pc;
						c_pc_branched = r_pc_branched;
						c_pc_dest_fetch = 63'bx;
						c_pc_fetch = 63'bx;
						c_fetch_branched = 0;
						c_dec_stall = 1;            // invalidate current fetch
						c_pc_stall = 1;
					end else begin
						c_pc_dest_fetch = r_pc_dest_fetch;
						c_pc = r_pc;
						c_pc_branched = r_pc_branched;
						c_fetch_state = 3'b001;	
						c_dec_stall = 1;
						c_pc_fetch = 64'bx;
						c_fetch_branched = 0;
					end
				end
			end else	/* !jumping_stall */
			if (fetch_ok) begin
				if (!rename_stall) begin
					c_fetch_restart = 0;
					if (r_fetch_restart && dec_br_enable) begin	// fix up pushed entry
						fixup_dest = 1;
					end
				end
				if (dec_br_enable && r_pc != dec_branch) begin	// local mispredict
					c_fetch_br_default = 1;
					c_fetch_br_valid = 0;
					c_pc_dest_dec = dec_branch;
					prediction_wrong = 1;
					prediction_wrong_taken = 1;
					prediction_wrong_dec = dec_br_offset;
					c_fetch_prediction_context.global_history[3:0] = {dec_br_offset, 1'b1};
					if (!rename_stall) begin
						push_enable = !r_fetch_restart;
						push_noissue = unconditional_jmp && !might_branch;
						push_taken = 1;
						push_branch_decoder = (unconditional_jmp && (!(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp_offset <= r_fetch_br_predict_dec)) ? unconditional_jmp_offset : r_fetch_br_default ? dec_br_offset :  r_fetch_br_predict_dec;
						push_dest = dec_branch;
						c_pc_br_valid = 0;
						c_pc = dec_branch;
						c_pc_branched = 1;
						c_pc_br_default = 1;
						c_pc_br_taken = 1;
						c_pc_br_predict_dec = r_pc_br_default ? dec_br_offset :  has_jmp[r_fetch_br_predict_dec] ? r_fetch_br_predict_dec : decode_has_jmp;
						//c_fetch_br_predict_dec = r_pc_br_default ? dec_br_offset :  has_jmp[r_fetch_br_predict_dec] ? r_fetch_br_predict_dec : decode_has_jmp;
						c_pc_dest_fetch = dec_branch;
						c_dec_stall = 1;            // invalidate current fetch
						c_pc_fetch = 63'bx;
						c_fetch_branched = 0;
						c_fetch_state = 3'b001;
					end else begin
						c_pc = dec_branch;
						c_pc_branched = r_pc_branched;
						c_dec_stall = 0;       
						c_pc_fetch = r_pc_fetch;
						c_fetch_branched = r_fetch_branched;
						c_fetch_state = 3'b010;
						c_fetch_br_default = r_fetch_br_default;
						c_pc_br_valid = 0;
					end
				end else
				if (!dec_br_enable && r_pc != branch_next_fetch) begin	// local mispredict
					prediction_wrong = 1;
					prediction_wrong_taken = 0;
					prediction_wrong_dec = 0;
					c_fetch_prediction_context.global_history[3:0] = 4'b0;
					if (!rename_stall) begin
						push_enable = !r_fetch_restart;
						push_noissue = 0;
						push_taken = 0;
						push_branch_decoder = 'bx;
						push_dest = branch_next_fetch;
						c_pc_br_valid = 1;
						c_pc_br_taken = 0;
						c_pc = branch_next_fetch;
						c_pc_dest_fetch = branch_next_fetch;
						c_pc_branched = 0;
						c_dec_stall = 1;
						c_pc_br_predict_dec = 'bx;
						c_fetch_br_predict_dec = 'bx;
						c_pc_fetch = 63'bx;
						c_fetch_branched = 0;
						c_fetch_state = 3'b001;
					end else begin
						c_pc = branch_next_fetch;
						c_pc_dest_fetch = branch_next_fetch;
						c_pc_branched = 0;
						c_dec_stall = 0;            // invalidate current fetch
						c_pc_fetch = r_pc_fetch;
						c_fetch_branched = r_fetch_branched;
						c_fetch_state = 3'b010;
					end
				end else begin		// we will have fetch data in next clock and have predicted correctly
					c_fetch_state = 3'b010;
					if (rename_stall) begin
						c_pc = r_pc;
						c_pc_branched = r_pc_branched;
						c_pc_dest_fetch = r_pc_dest_fetch;
						c_read_stall = 0;
						c_dec_stall = 0;            
						c_pc_fetch = r_pc_fetch;
						c_fetch_branched = r_fetch_branched;
						c_fetch_br_default = r_fetch_br_default;
					end else begin
						push_enable = !r_fetch_restart;
						push_noissue = unconditional_jmp && !might_branch && (r_fetch_br_default || unconditional_jmp_offset <= r_fetch_br_predict_dec);
						push_taken = (r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp;
						push_branch_decoder = (unconditional_jmp && (!(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp_offset <= r_fetch_br_predict_dec)) ? unconditional_jmp_offset : r_fetch_br_default ? dec_br_offset :  r_fetch_br_predict_dec;
						push_dest = r_pc;
						c_dec_stall = 0;
						c_pc_fetch = r_pc;
						c_fetch_branched = dec_br_enable;
						//c_fetch_br_default = r_pc_br_default&!predict_branch_valid;
						c_fetch_br_default = !predict_branch_valid;
						//c_fetch_br_taken = r_pc_br_taken|(predict_branch_valid && predict_branch_taken && r_pc[3:1] <= predict_branch_decoder);
						c_fetch_br_taken = (predict_branch_valid && predict_branch_taken && r_pc[3:1] <= predict_branch_decoder);
						//c_fetch_br_valid = r_pc_br_valid|predict_branch_valid;
						c_fetch_prediction_context = prediction_context;
						c_fetch_br_valid = predict_branch_valid;
						c_pc_br_valid = predict_branch_valid;
						prediction_wrong = r_fetch_br_default || (dec_br_enable && dec_br_offset != r_fetch_br_predict_dec);
						prediction_wrong_taken = dec_br_enable;
						prediction_wrong_dec = (dec_br_enable?dec_br_offset:0);
						if (r_fetch_br_default) begin
							if (dec_br_enable) begin
								c_fetch_prediction_context.global_history[3:0] = {dec_br_offset, 1'b1};
						//		push_force_taken = 1;
							end else begin
								c_fetch_prediction_context.global_history[3:0] = 4'b0;
						//		push_force_default = 1;
							end
						end	else begin
							if (dec_br_enable && dec_br_offset != r_fetch_br_predict_dec) begin
								c_fetch_prediction_context.global_history[3:0] = {dec_br_offset, 1'b1};
							//	push_force_taken = 1;
							end
						end
					
						prediction_used = 1;
						if (predict_branch_valid) begin
							if (predict_branch_taken && r_pc[3:1] <= predict_branch_decoder) begin
								c_pc = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
								c_pc_branched = 1;
								c_pc_br_default = 0;
								c_pc_br_taken = 1;
								c_pc_br_predict_dec = predict_branch_decoder;
								c_fetch_br_predict_dec = predict_branch_decoder;
								c_pc_dest_fetch = {{RV-VA_SZ{predict_branch_pc[VA_SZ-1]}}, predict_branch_pc};
								prediction_taken = 1;
							end else begin
								c_pc = branch_next;
								c_pc_branched = 0;
								c_pc_br_default = 0;
								c_pc_br_taken = 0;
								c_pc_br_predict_dec = 'bx;
								c_pc_dest_fetch = branch_next;
								prediction_taken = 0;
							end
						end else begin
							c_pc = branch_next;
							c_pc_branched = 0;
							c_pc_br_predict_dec = 'bx;
							c_pc_br_default = 1;
							c_pc_br_taken = 0;
							c_pc_dest_fetch = branch_next;
							prediction_taken = 0;
						end
					end
				end
			end else begin	// !fetch_ok
				if (dec_br_enable && r_pc != dec_branch) begin	// local mispredict
					prediction_wrong = r_fetch_br_default;
					prediction_wrong_taken = 1;
					prediction_wrong_dec = dec_br_offset;
					if (r_fetch_br_default) begin
						c_fetch_prediction_context.global_history[3:0] = {dec_br_offset, 1'b1};
					end
					c_pc_dest_dec = dec_branch;
					if (!rename_stall) begin
						push_enable = !r_fetch_restart;
						push_noissue = unconditional_jmp && !might_branch;
						push_taken = 1;
						push_force_taken = r_fetch_br_default;
						push_branch_decoder = (unconditional_jmp && (!(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp_offset <= r_fetch_br_predict_dec)) ? unconditional_jmp_offset : r_fetch_br_default ? dec_br_offset :  r_fetch_br_predict_dec;
						push_dest = dec_branch;
						c_pc_br_valid = 0;
						c_pc = dec_branch;
						c_pc_branched = 1;
						c_pc_br_default = 1;
						c_pc_br_taken = 1;
						c_pc_br_predict_dec = r_pc_br_default ? dec_br_offset :  has_jmp[r_fetch_br_predict_dec] ? r_fetch_br_predict_dec : decode_has_jmp;
						//c_fetch_br_predict_dec = r_pc_br_default ? dec_br_offset :  has_jmp[r_fetch_br_predict_dec] ? r_fetch_br_predict_dec : decode_has_jmp;
						c_pc_dest_fetch = dec_branch;
						c_dec_stall = 1;            // invalidate current fetch
						c_pc_fetch = 63'bx;
						c_fetch_branched = 0;
						c_fetch_state = 3'b001;
					end else begin
						c_pc = dec_branch;
						c_pc_branched = r_pc_branched;
						c_dec_stall = 0;       
						c_pc_fetch = r_pc_fetch;
						c_fetch_branched = r_fetch_branched;
						c_fetch_state = 3'b010;
						c_fetch_br_default = r_fetch_br_default;
						c_pc_br_valid = 0;
					end
				end else
				if (!dec_br_enable && r_pc != branch_next_fetch) begin	// local mispredict
					prediction_wrong = r_fetch_br_default;
					prediction_wrong_taken = 0;
					prediction_wrong_dec = 0;
					if (r_fetch_br_default) begin
						c_fetch_prediction_context.global_history[3:0] = 4'b0;
					end
					if (!rename_stall) begin
						push_enable = !r_fetch_restart;
						push_noissue = 0;
						push_taken = 0;
						push_branch_decoder = 'bx;
						push_dest = branch_next_fetch;
						push_force_default = r_fetch_br_default;
						c_pc = branch_next_fetch;
						c_pc_dest_fetch = branch_next_fetch;
						c_pc_branched = 0;
						c_dec_stall = 1;
						c_pc_br_predict_dec = 'bx;
						c_fetch_br_predict_dec = 'bx;
						c_pc_fetch = 63'bx;
						c_fetch_branched = 0;
						c_fetch_state = 3'b001;	
					end else begin
						c_pc = branch_next_fetch;
						c_pc_dest_fetch = branch_next_fetch;
						c_fetch_state = 3'b010;
						c_dec_stall = 0;            // invalidate current fetch
						c_pc_fetch = r_pc_fetch;
						c_fetch_branched = r_fetch_branched;
					end
				end else begin			// waiting for cache
					c_pc_dest_fetch = r_pc_dest_fetch;
					c_pc = r_pc;
					c_pc_branched = dec_br_enable;	///////
					if (rename_stall) begin
						c_fetch_state = 3'b010;
						c_dec_stall = 0;            // invalidate current fetch
						c_pc_fetch = r_pc_fetch;
						c_fetch_branched = r_fetch_branched;
					end else begin
						push_enable = !r_fetch_restart;
						push_noissue = unconditional_jmp && !might_branch && (r_fetch_br_default || unconditional_jmp_offset <= r_fetch_br_predict_dec);
						push_taken = (r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp;
						push_branch_decoder = (unconditional_jmp && (!(r_fetch_br_valid && r_fetch_br_taken) || unconditional_jmp_offset <= r_fetch_br_predict_dec)) ? unconditional_jmp_offset : r_fetch_br_default ? dec_br_offset :  r_fetch_br_predict_dec;
						push_dest = r_pc;
						prediction_wrong = r_fetch_br_default || (dec_br_enable && dec_br_offset != r_fetch_br_predict_dec);
						prediction_wrong_taken = dec_br_enable;
						prediction_wrong_dec = (dec_br_enable?dec_br_offset:0);
						if (r_fetch_br_default) begin
							if (dec_br_enable) begin
								c_fetch_prediction_context.global_history[3:0] = {dec_br_offset, 1'b1};
							//	push_force_taken = 1;
							end else begin
								c_fetch_prediction_context.global_history[3:0] = 4'b0;
							//	push_force_default = 1;
							end
						end	else begin
							if (dec_br_enable && dec_br_offset != r_fetch_br_predict_dec) begin
								c_fetch_prediction_context.global_history[3:0] = {dec_br_offset, 1'b1};
								//push_force_taken = 1;
							end
						end
						c_fetch_state = 3'b001;	
						c_dec_stall = 1;
						c_pc_fetch = 63'bx;
						c_fetch_branched = 0;
					end
				end
			end
		3'b1??:begin						// waiting for trap
				c_fetch_state = 3'b100;
				c_dec_stall = 1;
				c_pc_fetch = 63'bx;
				c_fetch_branched = r_fetch_branched&&r_issue_interrupt;
				c_pc_dest_fetch = 63'bx;
				c_pc = r_pc;
				c_pc_branched = r_pc_branched;
				c_pc_stall = 1;
				c_pc_br_valid = 0;
			end
		endcase
	end
`ifdef AWS_DEBUG
	ila_pc ila_pc(.clk(clk),
			.xxtrig(xxtrig),
			.reset(reset),
			.trap_br_enable(trap_br_enable),
			.commit_br_enable(commit_br_enable),
			.commit_br({commit_br[23:1],1'b0}),
			.int_br_enable(int_br_enable),
			.rename_stall(rename_stall),
			.jumping_stall(jumping_stall),
			.dec_br_enable(dec_br_enable),
			.r_fetch_br_default(r_fetch_br_default),
			.r_fetch_br_predict(r_fetch_br_predict_dec),
			.return_branch_valid(return_branch_valid),
			.interrupt_pending(interrupt_pending),
			.r_pend_int(r_pend_int),
			.fetch_ok(fetch_ok),
			.r_dec_stall(r_dec_stall),
			.r_fetch_state(r_fetch_state),		// 3
			.predict_branch_valid(predict_branch_valid),
			.predict_branch_taken(predict_branch_taken),
			.predict_branch_pc({predict_branch_pc[23:1],1'b0}),	// 24
			.branch_next({branch_next[23:1],1'b0}),			// 24
			.r_recent_branch_dest(24'b0),		// 24
			.r_pc({r_pc[23:1],1'b0}),				// 24
			.r_pc_fetch({r_pc_fetch[23:1],1'b0}),				// 24
			.return_branch_pc({return_branch_pc[23:1],1'b0}),	// 24
			.branch_next_fetch({branch_next_fetch[23:1],1'b0}),		// 24
			.dec_branch({dec_branch[23:1],1'b0}),			// 24
			.issue_interrupt(issue_interrupt),
			.issue_fetch_trap(issue_fetch_trap),
			.r_pc_branched(r_pc_branched),
			.r_fetch_branched(r_fetch_branched),
            .subr_push(subr_push),
            .subr_pop(subr_pop),
            .r_pc_dest_dec({r_pc_dest_dec[31:1],1'b0}),
            .r_pc_dest_fetch({r_pc_dest_fetch[31:1],1'b0}));
			
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

