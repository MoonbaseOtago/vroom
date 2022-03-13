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

//module bpred_state(input clk,  input reset,

`include "pred_context.si"

//`define XDEBUG 1
//`define SDEBUG 1
`ifndef VSYNTH2
//`define XDEBUG 1
//`define SDEBUG 1
`endif

module bpred(input clk,  input reset,
		input			[3:0]cpu_mode,					// protection state
		input				 clear_user,				// clear user history
		input				 clear_sup,					// clear sup history

		input        [RV-1:1]pc,						// pc we're predicting
		output				 predict_branch_valid,		// we have a valid prediction
		output				 predict_branch_taken,		// predict we're taking this branch
		output		 [RV-1:1]predict_branch_pc,			// predicted destination
	    output [$clog2(2*NDEC)-1:0]predict_branch_decoder,	// predict decoder

		input				 prediction_used,			// we used a prediction
		input				 prediction_taken,			//   and we took it

		input				 prediction_wrong,		    // that prdiction was wrong
		input				 prediction_wrong_taken,    //   what we did instead
		input	   [BDEC-1:1]prediction_wrong_dec,		//	 and where (only valid if 'taken')
		output PRED_STATE	 prediction_context,

		input				 push_enable,				// true if there's one or more branches here
		input		 [RV-1:1]push_pc,					// pc we fetched with
		input				 push_noissue,				// it is an unconditional branch - it wont show up in the 
														// completion stage
	    input [$clog2(2*NDEC)-1:0]push_branch_decoder,	// predict decoder (taken branch offst)
		input		 [RV-1:1]push_dest,					// branch dest (if taken)
		input				 push_taken,				// true if branch was taken
		output [$clog2(NUM_PENDING)-1:0]push_token,		// token for when we fail
		output [$clog2(NUM_PENDING_RET)-1:0]push_token_ret,
		input PRED_STATE	 push_context,

        input				 fixup_dest,				// fix up prediction
        input	     [RV-1:1]fixup_dest_pc,
        input	   [BDEC-1:1]fixup_dest_dec,


		input				 trap_shootdown,			// trap
		input [$clog2(NUM_PENDING)-1:0]trap_shootdown_token,	// latest killed entry
		input				 commit_shootdown,			// commitq break shootdown (branch miss)
		input				 commit_shootdown_taken,	// commitq break shootdown (branch miss)
		input [$clog2(NUM_PENDING)-1:0]commit_shootdown_token,	// latest killed entry
		input [$clog2(NUM_PENDING_RET)-1:0]commit_shootdown_token_ret,
		input        [RV-1:1]commit_shootdown_dest,			// 
		input      [BDEC-1:1]commit_shootdown_dec,
		input				 commit_shootdown_short,

		input [NUM_PENDING-1:0]commit_token,			// bit encoded tokens from the commitQ commit stage
		input [NUM_PENDING_RET-1:0]commit_token_ret,

		input				 push_cs_stack, 
		input		 [RV-1:1]ret_addr,
		input				 pop_cs_stack,
		output				 pop_available,
		output				 return_branch_valid,
		output		 [RV-1:1]return_branch_pc
		
	);

	parameter RV=64;
	parameter NDEC=4;
	parameter BDEC=4;
	parameter CALL_STACK_SIZE=32;
	parameter MCALL_STACK_SIZE = CALL_STACK_SIZE / 2;	// 32-entries is a waste for M-mode

`ifdef PSYNTH
	parameter	NUM_GLOBAL = 9;			// size of the global history tables (log entries)
	parameter	NUM_BIMODAL = 9;		// size of the bimodal tables (log entries)
	parameter	NUM_COMBINED = 9;		// size of the combined tables (log entries)
`else
	parameter	NUM_GLOBAL = 12;		// size of the global history tables (log entries)
	parameter	NUM_BIMODAL = 12;		// size of the bimodal tables (log entries)
	parameter	NUM_COMBINED = 12;		// size of the combined tables (log entries)
`endif
	parameter	NUM_PENDING = 32;		// probably should be the same size as the commitQ
	parameter   NUM_PENDING_RET = 8;	// number of pending call slots
	parameter	VTAG_SIZE = 8;			// we don't keep a full tag for gl/bi entries

	parameter	GLOBAL_HISTORY = `GH;		// size of the global history (bits)

	reg		[2:0]r_mode;
	always @(posedge clk) begin
		r_mode[2] <= cpu_mode[3];
		r_mode[1] <= cpu_mode[1];
		r_mode[0] <= cpu_mode[0];
	end
	wire [2:0]clear = {1'b0, clear_sup, clear_user};


	reg [BDEC-1:1]shootdown_dec;
	reg			  shootdown_taken;
	reg [$clog2(NUM_PENDING)-1:0]shootdown_token;	// latest killed entry
	
	always @(*) begin
		//shootdown_taken = commit_shootdown_taken&(commit_shootdown_short||commit_shootdown_dec!=7);
		shootdown_taken = commit_shootdown_taken;
		shootdown_dec = commit_shootdown_short ? commit_shootdown_dec : commit_shootdown_dec+1;
		shootdown_token = commit_shootdown_short || (commit_shootdown_dec!=7) ? commit_shootdown_token : commit_shootdown_token+1;
	end

	//
	//	return stack
	//

	wire [2:0]pop_available_x;
	wire [2:0]return_branch_valid_x;
	wire [RV-1:1]return_branch_pc_x[0:2];
	wire [$clog2(CALL_STACK_SIZE)-1:0]cs_top_x[0:2];
	wire [$clog2(CALL_STACK_SIZE)-1:0]cs_top_x_p[0:2];
	wire [$clog2(CALL_STACK_SIZE)-1:0]cs_top_x_n[0:2];

	reg			pop_available_m;
	assign pop_available = pop_available_m;
	assign return_branch_valid = pop_available_m;
	reg [RV-1:1]return_branch_pc_m;
	assign return_branch_pc = return_branch_pc_m;
	reg [$clog2(CALL_STACK_SIZE)-1:0]cs_top_m;
	reg [$clog2(CALL_STACK_SIZE)-1:0]cs_top_m_p;
	reg [$clog2(CALL_STACK_SIZE)-1:0]cs_top_m_n;
	assign cs_top = cs_top_m;

	always @(*)
	casez (r_mode) // synthesis full_case parallel_case
	3'b??1: begin
				cs_top_m = cs_top_x[0];
				cs_top_m_p = cs_top_x_p[0];
				cs_top_m_n = cs_top_x_n[0];
			end
	3'b?1?: begin
				cs_top_m = cs_top_x[1];
				cs_top_m_p = cs_top_x_p[1];
				cs_top_m_n = cs_top_x_n[1];
			end
	3'b1??: begin
				cs_top_m = cs_top_x[2];
				cs_top_m_p = cs_top_x_p[2];
				cs_top_m_n = cs_top_x_n[2];
			end
	endcase

	genvar P, I, M;

	generate
		for (M = 0; M < 3; M=M+1) begin: callstack
			reg [RV-1:1]r_call_stack[0:(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1];
			reg [(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1:0]r_call_stack_valid;
			assign pop_available_x[M] = r_call_stack_valid[r_cs_top];
			assign return_branch_pc_x[M] = r_call_stack[r_cs_top];

			reg [$clog2(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1:0]r_cs_top;
			wire [$clog2(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1:0]cs_top_p = r_cs_top+1;
			wire [$clog2(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1:0]cs_top_n = r_cs_top-1;

			if (MCALL_STACK_SIZE != CALL_STACK_SIZE && M==2) begin
				assign cs_top_x[M] = {1'b0,r_cs_top};
				assign cs_top_x_p[M] = {1'b0,cs_top_p};
				assign cs_top_x_n[M] = {1'b0,cs_top_n};
			end else begin
				assign cs_top_x[M] = r_cs_top;
				assign cs_top_x_p[M] = cs_top_p;
				assign cs_top_x_n[M] = cs_top_n;
			end
		
`ifdef SDEBUG 
			always @(posedge clk) 
			if (r_mode[M] && r_ps_valid[r_ps_out] && r_ps_committed[r_ps_out]) 
			if (r_ps_push[r_ps_out]) begin
				$display("%d: wb ps[%x]->push @%x -> %x", $time, r_ps_out, r_ps_sp[r_ps_out], r_ps_return[r_ps_out]);
			end else begin
				$display("%d: wb ps[%x]->pop @%x", $time, r_ps_out, r_ps_sp[r_ps_out]);
			end
`endif
			wire [$clog2(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1:0]ps_index=r_ps_sp[r_ps_out];
			wire [$clog2(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1:0]ps_index_p=ps_index+1;

			always @(posedge clk) 
			if (reset || clear[M]) begin
				r_call_stack_valid <= 0;
			end else
			if (r_mode[M] && r_ps_valid[r_ps_out] && r_ps_committed[r_ps_out]) begin
				if (r_ps_push[r_ps_out]) begin
					r_call_stack_valid[ps_index] <= 1;
				end else begin
					r_call_stack_valid[ps_index_p] <= 0;
				end
			end
			
			always @(posedge clk) 
			if (r_mode[M] && r_ps_valid[r_ps_out] && r_ps_committed[r_ps_out] && r_ps_push[r_ps_out]) begin
				r_call_stack[r_ps_sp[r_ps_out]] <= r_ps_return[r_ps_out];
			end

			always @(posedge clk) begin
				if (reset) begin
					r_cs_top <= 0;
				end else
				if (r_mode[M]) begin
`ifdef SDEBUG 
					casez ({commit_shootdown, r_ps_valid[commit_shootdown_token_ret], push_cs_stack, pop_cs_stack&pop_available}) // synthesis full_case parallel_case
					4'b11_??: $display("%d: SHOOT SP=%x ind=%x", $time, r_ps_sp[commit_shootdown_token_ret], commit_shootdown_token_ret);
					4'b0?_10: $display("%d: PUSH  SP=%x ret=%x", $time, r_cs_top+1, ret_addr);
					4'b0?_01: $display("%d: POP   SP=%x", $time, r_cs_top-1);
					4'b0?_11: $display("%d: PS/PP SP=%x", $time, r_cs_top);
					endcase
`endif

					casez ({commit_shootdown, r_ps_valid[commit_shootdown_token_ret], push_cs_stack, pop_cs_stack&pop_available}) // synthesis full_case parallel_case
					4'b11_??: r_cs_top <= r_ps_push[commit_shootdown_token_ret]?r_ps_sp[commit_shootdown_token_ret]-1:r_ps_sp[commit_shootdown_token_ret]+1;
					4'b0?_10: r_cs_top <= r_cs_top+1;
					4'b0?_01: r_cs_top <= r_cs_top-1;
					4'b10_??, 
					4'b0?_11, 
					4'b0?_00: ;
					endcase
				end
			end

		end
	endgenerate

	//
	// like the branch prediction below we need to run a speculative front end for the call/return stack
	//		since speculations are are discaded across mode switches we only need one for all modes
	//		we use the 'tokens' from the speculative cache below to manage this one
	//


	reg	        [NUM_PENDING_RET-1:0]r_ps_valid;	
	reg	        [NUM_PENDING_RET-1:0]r_ps_committed;	
	reg	        [NUM_PENDING_RET-1:0]r_ps_push;	
	reg                      [RV-1:1]r_ps_return[0:NUM_PENDING_RET-1];
	reg [$clog2(CALL_STACK_SIZE)-1:0]r_ps_sp[0:NUM_PENDING_RET-1];

	reg [$clog2(NUM_PENDING_RET)-1:0]r_ps_in;
	reg [$clog2(NUM_PENDING_RET)-1:0]r_ps_out;
	assign	push_token_ret = r_ps_in;

	wire [NUM_PENDING_RET-1:0]ps_match;
	reg [$clog2(NUM_PENDING_RET)-1:0]ps_match_ind;
	always @(*)
	if (push_cs_stack) begin			// this case may be a bit iffy - this is the call to instruction bundle with
		return_branch_pc_m = 1;			//	immediate return case, may not be doable for really fast timing
		return_branch_pc_m = ret_addr;
	end else
	if (|ps_match) begin
			pop_available_m = 1;
			return_branch_pc_m = r_ps_return[ps_match_ind];
	end else
	casez (r_mode) // synthesis full_case parallel_case
	3'b??1: begin
				pop_available_m = pop_available_x[0];
				return_branch_pc_m = return_branch_pc_x[0];
			end
	3'b?1?: begin
				pop_available_m = pop_available_x[1];
				return_branch_pc_m = return_branch_pc_x[1];
			end
	3'b1??: begin
				pop_available_m = pop_available_x[2];
				return_branch_pc_m = return_branch_pc_x[2];
			end
	endcase

	always @(posedge clk) begin
		if (reset) begin
			r_ps_in <= 0;
		end else
		if (commit_shootdown) begin
			//if (r_ps_valid[commit_shootdown_token_ret]) begin
			r_ps_in <= commit_shootdown_token_ret;
			//end
		end else
		if (push_cs_stack || (pop_cs_stack&pop_available)) begin
			r_ps_in <= r_ps_in+1;
		end
	end

	always @(posedge clk) begin
		if (reset) begin
			r_ps_out <= 0;
		end else
		if (r_ps_valid[r_ps_out] && r_ps_committed[r_ps_out]) begin
			r_ps_out <= r_ps_out+1;
		end
	end

	wire [NUM_PENDING_RET-1:0]commit_token_ret_done;
	assign commit_token_ret_done = {commit_token_ret[0], commit_token_ret[NUM_PENDING_RET-1:1]}| // because multiple may signal we
	                               {commit_token_ret[1:0], commit_token_ret[NUM_PENDING_RET-1:2]}; 
																					// wait until all are done

	generate
		for (P = 0; P < NUM_PENDING_RET; P=P+1) begin :ps
			assign  ps_match[P] = r_ps_valid[P] && r_ps_sp[P] == cs_top_m && r_ps_push[P];
			always @(posedge clk)
			if (reset) begin
				r_ps_valid[P] <= 0;
			end else
			if (r_ps_out == P && r_ps_valid[P] && r_ps_committed[P]) begin
				r_ps_valid[P] <= 0;
			end else
			if (r_ps_in == P && !r_ps_valid[P] && (push_cs_stack|(pop_cs_stack&pop_available)) && !commit_shootdown) begin
				r_ps_valid[P] <= 1;
				r_ps_committed[P] <= 0;
			end else
			if (r_ps_valid[P] && commit_token_ret_done[P]) begin
				r_ps_committed[P] <= 1;
`ifdef SDEBUG 
				if (!r_ps_committed[P])$display("%d: committed ps[%d]", $time, P);
`endif
			end else
			if (commit_shootdown && r_ps_valid[P] && ((r_ps_in > P && P >= commit_shootdown_token_ret) || (r_ps_in < commit_shootdown_token_ret && (P >= commit_shootdown_token_ret || r_ps_in > P)))) begin	// flush unwanted
`ifdef SDEBUG 
				$display("%d: kill ps[%d]", $time, P);
`endif
				r_ps_valid[P] <= 0;
			end else
			if (trap_shootdown) begin
				r_ps_valid[P] <= 0;
			end 

			always @(posedge clk)
			if (r_ps_in == P && !r_ps_valid[P] && (push_cs_stack|(pop_cs_stack&pop_available)) && !commit_shootdown) begin
				r_ps_return[P] <= ret_addr;
				r_ps_sp[P] <= (push_cs_stack?cs_top_m_p:cs_top_m_n);
				r_ps_push[P] <= push_cs_stack;
			end
		end
	endgenerate

`ifdef SDEBUG
	always @(posedge clk)
	if ((push_cs_stack|(pop_cs_stack&pop_available)) && !commit_shootdown) begin
		if (push_cs_stack) begin
			$display("%d: ps[%x] sp=%x push=%x", $time, r_ps_in, cs_top_m_p, ret_addr);
		end else begin
			$display("%d: ps[%x] sp=%x pop", $time, r_ps_in, cs_top_m_n);
		end
	end
`endif

	//
	//	branch predictors - essentially there's a bimodal predictor and a global predictor and a predictor predictor
	//		as per McFarling's "Combining Branch Predictors" - they share a single target cache.
	//
	//	Because we decode so many instructions per clock we have an interesting problem - with up to 8 instructions
	//		per bundle being decoded we may worst case need to predict up to 8 branches (we only need to predict the
	//		target of the first predicted taken one starting from the nth instruction in the bundle - bottom 3 bits of
	//		the pc) - this means that we need to keep multiple destinations from each bundle 
	//
	//	Having said that let's restate the problem - we just started fetching daat from the icache at pc - we won't 
	//		know what's in it for a clock and a bit - can we predict one of two things?:
	//
	//		- there will be no branches
	//		- there will be a branch to X
	//
	//		also where in the instruction will the branch source be? (so we can validate the target)
	//
	//	we're a heavily pipelined/out-of-order/speculative machine - when a branch prediction fails (or a trap occurs)
	//		we may have already collected a whole bunch of successive predictions that we need to back out of to
	//		handle this we have a push down stack of pending prediction states - we access these in parallel with the
	//		main state - we prune the stack when a misprediction or a trap occurs - predcitions associated with committed
	//		branches are retired into the global state from the bottom of the stack
	//		
	//


	generate
		// all the guts are in here:
		if (NUM_PENDING == 32) begin
			if (NUM_PENDING_RET == 8 ) begin
`include "mk20_32_8.inc"
			end else
			if (NUM_PENDING_RET == 16 ) begin
`include "mk20_32_16.inc"
			end 
		end
	endgenerate


	wire [NUM_PENDING-1:0]commit_token_done;
	assign commit_token_done = {commit_token[0], commit_token[NUM_PENDING-1:1]}|	
							   {commit_token[1:0], commit_token[NUM_PENDING-1:2]};	// because multiple may signal we
																					// wait until all are done

	//
	// global history
	//

	

	wire	[1:0]global_xprediction[0:2];
	wire [2:0]global_tag_hit;
	wire	[BDEC-1-1:0]global_xdec[0:2];
	wire	[RV-1:1]global_xdest[0:2];
	reg	[$clog2(NUM_PENDING)-1:0]global_pred_index;
	wire [GLOBAL_HISTORY*4-1:0]global_xhistory[0:2];

	wire  [NUM_GLOBAL-1:0]global_index_g = pc[BDEC+NUM_GLOBAL-1:BDEC]^{pc[BDEC-1:1],{(NUM_GLOBAL-(BDEC-1)){1'b0}}};
	wire  [NUM_GLOBAL-1:0]global_xindex[0:2];
	
	generate
		for (M = 0; M < 3; M=M+1) begin : gl
			reg	 [GLOBAL_HISTORY*4-1:0]r_global_history;						// actual global history
			wire [NUM_GLOBAL-1:0]xindex;
			if (GLOBAL_HISTORY == 6) begin		// 24 bits - hand built mappings of history to hashes
				if (NUM_GLOBAL == 12) begin
					assign xindex = r_global_history[11:0]^{3'b0, r_global_history[18:12], 2'b0}^{2'b0, r_global_history[23:19], 5'b0};
				end else
				if (NUM_GLOBAL == 10) begin
					assign xindex = r_global_history[10:0]^{2'b0, r_global_history[18:11], 2'b0}^{2'b0, r_global_history[23:19], 5'b0};
				end else
				if (NUM_GLOBAL == 9) begin
					assign xindex = r_global_history[8:0]^{r_global_history[16:9], 1'b0}^{r_global_history[23:17], 2'b0};
				end else begin
					assign xindex = 'bx;
				end
			end else
			if (GLOBAL_HISTORY == 8) begin		// 32 bits
				if (NUM_GLOBAL == 12) begin
					assign xindex = r_global_history[11:0]^{r_global_history[21:12], 2'b0}^{r_global_history[31:22], 2'b0};
				end else
				if (NUM_GLOBAL == 13) begin
					assign xindex = r_global_history[12:0]^{r_global_history[23:13], 2'b0}^{1'b0, r_global_history[31:24], 5'b0};
				end 
			end else begin
				assign xindex = 'bx;
			end
			assign global_xhistory[M] = r_global_history;
			reg		[2*(1<<NUM_GLOBAL)-1:0]r_global_tables;					// global history tables (counter 0-3 >=2 means taken)
			reg		[RV-1:1]r_global_dest[0:(1<<NUM_GLOBAL)-1];				// dest target
			reg		[VTAG_SIZE-1:0]r_global_tag[0:(1<<NUM_GLOBAL)-1];
			reg		[(1<<NUM_GLOBAL)-1:0]r_global_tag_valid;
			reg		[BDEC-1-1:0]r_global_dec[0:(1<<NUM_GLOBAL)-1];			// global history tables decoder offset
			assign	global_xindex[M]		   = xindex^global_index_g;
			assign	global_xprediction[M]      = {r_global_tables[{global_xindex[M], 1'b1}], r_global_tables[{global_xindex[M], 1'b0}]};
			assign	global_tag_hit[M] = r_mode[M] && r_global_tag_valid[global_xindex[M]] && r_global_tag[global_xindex[M]] == pc[BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL] && (!r_global_tables[{global_xindex[M], 1'b1}] || r_global_dec[global_xindex[M]] >= pc[BDEC-1:1]);

			assign 	global_xdec[M] = r_global_dec[global_xindex[M]];
			assign 	global_xdest[M] = r_global_dest[global_xindex[M]];

			always @(posedge clk) begin
				if (reset || clear[M]) begin
					r_global_history <= 0;
				end else	
				if (r_mode[M]) begin
					if (commit_shootdown) begin
						r_global_history <= {r_pend_global_history[shootdown_token][GLOBAL_HISTORY*4-4-1:0], (shootdown_taken?shootdown_dec:3'b0), shootdown_taken}; 
					end else
					case ({prediction_used, prediction_wrong}) // synthesis full_case parallel_case
					2'b11: r_global_history <= {r_global_history[GLOBAL_HISTORY*4-4-1:4], prediction_wrong_dec, prediction_wrong_taken, (prediction_taken?predict_branch_decoder:3'b0), prediction_taken};
					2'b10: r_global_history <= {r_global_history[GLOBAL_HISTORY*4-4-1:0], (prediction_taken?predict_branch_decoder:3'b0), prediction_taken};
					2'b01: r_global_history <= {r_global_history[GLOBAL_HISTORY*4-1:4], prediction_wrong_dec, prediction_wrong_taken};
					2'b00: ;
					endcase
				end
			end

			always @(posedge clk) begin
				if (reset || clear[M]) begin
					r_global_tables <= {(1<<NUM_GLOBAL){2'b01}};
					r_global_tag_valid <= 0;
				end else
				if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out] && r_pend_mode[r_pend_out][M]) begin
					r_global_tag_valid[pend_global_index[r_pend_out]] <= 1;
					r_global_tables[{pend_global_index[r_pend_out], 1'b1}] <= r_pend_global_pred[r_pend_out][1];
					r_global_tables[{pend_global_index[r_pend_out], 1'b0}] <= r_pend_global_pred[r_pend_out][0];
				end
			end

			always @(posedge clk) begin
				if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out] && r_pend_mode[r_pend_out][M]) begin
					r_global_tag[pend_global_index[r_pend_out]] <= r_pend_pc[r_pend_out][BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL];
					if (r_pend_taken[r_pend_out] && r_pend_global_pred[r_pend_out][1]) begin
						r_global_dec[pend_global_index[r_pend_out]] <= r_pend_dec[r_pend_out];
						r_global_dest[pend_global_index[r_pend_out]] <= r_pend_dest[r_pend_out];
					end
				end
			end

`ifdef XDEBUG
			always @(posedge clk) begin
				if (prediction_used && r_mode[M]) begin
					if (prediction_wrong) begin
						$display("%d: pc=%h->%h dec=%d prediction_used taken=%d c/g/b=%d@%h/%d@%h/%d@%h history=%h->%h", $time, pc, predict_branch_pc, predict_branch_decoder, prediction_taken, combined_prediction, combined_index, global_prediction, global_xindex[M], bimodal_prediction, bimodal_index, r_global_history,  {r_global_history[GLOBAL_HISTORY*4-4-1:4], prediction_wrong_dec, prediction_wrong_taken, (prediction_taken?predict_branch_decoder:3'b0), prediction_taken});
					end else begin
						$display("%d: pc=%h->%h dec=%d prediction_used taken=%d c/g/b=%d@%h/%d@%h/%d@%h history=%h->%h", $time, pc, predict_branch_pc, predict_branch_decoder, prediction_taken, combined_prediction, combined_index, global_prediction, global_xindex[M], bimodal_prediction, bimodal_index, r_global_history,  {r_global_history[GLOBAL_HISTORY*4-4-1:0], (prediction_taken?predict_branch_decoder:3'b0), prediction_taken});
					end
				end
				if (prediction_wrong && r_mode[M]) begin
					if (prediction_taken) begin
						$display("%d: prediction_wrong taken=%d dec=%d history->%h", $time, prediction_wrong_taken, prediction_wrong_dec, {r_global_history[GLOBAL_HISTORY*4-4-1:4], prediction_wrong_dec, prediction_wrong_taken, (prediction_taken?predict_branch_decoder:3'b0), prediction_taken});
					end else begin
						$display("%d: prediction_wrong taken=%d dec=%d history->%h", $time, prediction_wrong_taken, prediction_wrong_dec, {r_global_history[GLOBAL_HISTORY*4-1:4], prediction_wrong_dec,  prediction_wrong_taken});
					end
				end
				if (commit_shootdown && r_mode[M])
					$display("%d:@prediction_shootdown taken=%d token=%h dest=%h hist=%h gl=%h", $time, shootdown_taken, shootdown_token, commit_shootdown_dest, r_pend_global_history[shootdown_token], {r_pend_global_history[shootdown_token][GLOBAL_HISTORY*4-4-1:0], shootdown_dec, shootdown_taken});
			end
`endif

		end

	endgenerate


	reg	               [1:0]global_prediction;
	reg	            [RV-1:1]global_dest;
	reg	        [BDEC-1-1:0]global_dec;
	reg	[GLOBAL_HISTORY*4-1:0]global_history;
	reg     [NUM_GLOBAL-1:0]global_index;
	always @(*) begin
		if (|global_pend_prediction_valid) begin
			global_prediction =  r_pend_global_pred[global_pred_index];
			global_dest = r_pend_dest[global_pred_index];
			global_dec = r_pend_dec[global_pred_index];
		end else
		casez(r_mode) // synthesis full_case parallel_case
		3'b??1: begin
					global_prediction = global_xprediction[0];
					global_dest = global_xdest[0];
					global_dec = global_xdec[0];
				end
		3'b?1?: begin
					global_prediction = global_xprediction[1];
					global_dest = global_xdest[1];
					global_dec = global_xdec[1];
				end
		3'b1??: begin
					global_prediction = global_xprediction[2];
					global_dest = global_xdest[2];
					global_dec = global_xdec[2];
				end
		endcase
	end
	always @(*) begin
		casez(r_mode) // synthesis full_case parallel_case
		3'b??1: begin
					global_history = global_xhistory[0];
					global_index = global_xindex[0];
				end
		3'b?1?: begin
					global_history = global_xhistory[1];
					global_index = global_xindex[1];
				end
		3'b1??: begin
					global_history = global_xhistory[2];
					global_index = global_xindex[2];
				end
		endcase
	end

	//
	//	bimodal predictor
	//

	wire  [NUM_BIMODAL-1:0]bimodal_index = pc[BDEC+NUM_BIMODAL-1:BDEC]^{pc[BDEC-1:1], {(NUM_BIMODAL-(BDEC-1)){1'b0}}};
	wire [1:0]bimodal_xprediction[0:2];
	wire [2:0]bimodal_tag_hit;
	wire [BDEC-1-1:0]bimodal_xdec[0:2];
	wire  [RV-1:1]bimodal_xdest[0:2];

	reg	[$clog2(NUM_PENDING)-1:0]bimodal_pred_index;

	generate
		for (M = 0; M < 3; M=M+1) begin : bi
			reg		[2*(1<<NUM_BIMODAL)-1:0]r_bimodal_tables;	// bimodal history tables (counter 0-3 >=2 means taken)
			reg		[BDEC-1-1:0]r_bimodal_dec[0:(1<<NUM_BIMODAL)-1];	// bimodal history tables decoder offset
			reg		[RV-1:1]r_bimodal_dest[0:(1<<NUM_BIMODAL)-1];	
			reg		[VTAG_SIZE-1:0]r_bimodal_tag[0:(1<<NUM_BIMODAL)-1];
			reg		[(1<<NUM_BIMODAL)-1:0]r_bimodal_tag_valid;
			assign bimodal_xprediction[M] = {r_bimodal_tables[{bimodal_index,1'b1}], r_bimodal_tables[{bimodal_index,1'b0}]};

			assign bimodal_tag_hit[M] = r_mode[M] && r_bimodal_tag_valid[bimodal_index] && r_bimodal_tag[bimodal_index] == pc[BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL] && (!r_bimodal_tables[{bimodal_index, 1'b1}] || r_bimodal_dec[bimodal_index] >= pc[BDEC-1:1]); 
			assign bimodal_xdec[M] = r_bimodal_dec[bimodal_index];
			assign bimodal_xdest[M] = r_bimodal_dest[bimodal_index];

			always @(posedge clk) begin
				if (reset || clear[M]) begin
					r_bimodal_tables <= {(1<<NUM_BIMODAL){2'b01}};
					r_bimodal_tag_valid <= 0;
				end else
				if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out] && r_pend_mode[r_pend_out][M]) begin
					r_bimodal_tag_valid[pend_bimodal_index[r_pend_out]] <= 1;
					r_bimodal_tables[{pend_bimodal_index[r_pend_out], 1'b1}] <= r_pend_bimodal_pred[r_pend_out][1];
					r_bimodal_tables[{pend_bimodal_index[r_pend_out], 1'b0}] <= r_pend_bimodal_pred[r_pend_out][0];
				end
			end

			always @(posedge clk) begin
				if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out] && r_pend_mode[r_pend_out][M]) begin
					r_bimodal_tag[pend_bimodal_index[r_pend_out]] <= r_pend_pc[r_pend_out][BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL];
					if (r_pend_taken[r_pend_out] && r_pend_bimodal_pred[r_pend_out][1]) begin
						r_bimodal_dest[pend_bimodal_index[r_pend_out]] <= r_pend_dest[r_pend_out];
						r_bimodal_dec[pend_bimodal_index[r_pend_out]] <= r_pend_dec[r_pend_out];
					end
				end
			end
		end
	endgenerate

	reg	[1:0]bimodal_prediction;
	reg	[BDEC-1-1:0]bimodal_dec;
	reg	[RV-1:1]bimodal_dest;
	always @(*) begin
		if (|bimodal_pend_prediction_valid) begin		
			bimodal_prediction = r_pend_bimodal_pred[bimodal_pred_index];
			bimodal_dec = r_pend_dec[bimodal_pred_index];
			bimodal_dest = r_pend_dest[bimodal_pred_index];
		end else
		casez (r_mode) // synthesis full_case parallel_case
		3'b??1:	begin
					bimodal_prediction = bimodal_xprediction[0];
					bimodal_dec = bimodal_xdec[0];
					bimodal_dest = bimodal_xdest[0];
				end
		3'b?1?:	begin
					bimodal_prediction = bimodal_xprediction[1];
					bimodal_dec = bimodal_xdec[1];
					bimodal_dest = bimodal_xdest[1];
				end
		3'b1??:	begin
					bimodal_prediction = bimodal_xprediction[2];
					bimodal_dec = bimodal_xdec[2];
					bimodal_dest = bimodal_xdest[2];
				end
		endcase
	end
	
	//
	//	combined predictor
	//

	wire  [NUM_COMBINED-1:0]combined_index = pc[BDEC+NUM_COMBINED-1:BDEC]^{pc[BDEC-1:1], {(NUM_COMBINED-(BDEC-1)){1'b0}}};
	reg	[$clog2(NUM_PENDING)-1:0]combined_pred_index;
	wire [1:0]combined_xprediction[0:2];
	reg		[1:0]combined_prediction;
	generate

		for (M = 0; M < 3; M = M+1) begin : cmb
			reg		[(2<<NUM_COMBINED)-1:0]r_combined_tables;	// combined history tables (counter 0-3 >=2 means taken)
			assign combined_xprediction[M] = {r_combined_tables[{combined_index, 1'b1}], r_combined_tables[{combined_index, 1'b0}]};
			always @(posedge clk) begin
				if (reset || clear[M]) begin
					r_combined_tables <= {{(1<<NUM_COMBINED){2'b01}}};
				end else 
				if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out] && r_pend_mode[r_pend_out][M]) begin
					r_combined_tables[{pend_combined_index[r_pend_out], 1'b1}] <= r_pend_combined_pred[r_pend_out][1];
					r_combined_tables[{pend_combined_index[r_pend_out], 1'b0}] <= r_pend_combined_pred[r_pend_out][0];
				end
			end
		end
	endgenerate

	always @(*) begin
		if (|combined_pend_prediction_valid) begin
			combined_prediction = r_pend_combined_pred[combined_pred_index];
		end else
		casez (r_mode) // synthesis full_case parallel_case
		3'b??1: combined_prediction = combined_xprediction[0];
		3'b?1?: combined_prediction = combined_xprediction[1];
		3'b1??: combined_prediction = combined_xprediction[2];
		endcase
	end

	wire global_valid  = |global_tag_hit  | (|global_pend_prediction_valid);
	wire bimodal_valid = |bimodal_tag_hit | (|bimodal_pend_prediction_valid);


	reg [BDEC-1-1:0]predict_dec;
	reg     [RV-1:1]predict_dest;
	reg				predict_valid;

	always @(*) 
	casez ({global_valid, bimodal_valid, combined_prediction[1]}) // synthesis full_case parallel_case
	3'b111,
	3'b10?: begin
				predict_valid = 1;
				predict_taken = global_prediction[1];
				predict_dec = global_dec;
				predict_dest = global_dest;
			end
	3'b110,
	3'b01?:	begin
				predict_valid = 1;
				predict_taken = bimodal_prediction[1];
				predict_dec = bimodal_dec;
				predict_dest = bimodal_dest;
			end
	3'b00?:	begin
				predict_valid = 0;
				predict_taken = 0;
				predict_dec = 'bx;
				predict_dest = 'bx;
			end
	endcase

	assign predict_branch_taken = predict_taken;
	assign predict_branch_valid = predict_valid;
	assign predict_branch_decoder = predict_dec;
	assign predict_branch_pc = predict_dest;

	assign prediction_context.bimodal_prediction_dec = bimodal_dec;
	assign prediction_context.global_prediction_dec = global_dec;
	assign prediction_context.combined_prediction_prev = combined_prediction;
	assign prediction_context.bimodal_prediction_prev = bimodal_prediction;
	assign prediction_context.global_prediction_prev = global_prediction;
	assign prediction_context.global_history = global_history;

`ifdef XDEBUG
	always @(posedge clk) begin
		if (push_enable) begin
			$display("%d: push pc=%h->%h token=%h taken=%d dec=%d noissue=%d c/g/b=%d/%d/%d hist=%h", $time, push_pc, push_dest, r_pend_in, push_taken, push_branch_decoder, push_noissue, push_context.combined_prediction_prev, push_context.global_prediction_prev, push_context.bimodal_prediction_prev, push_context.global_history );
		end
		if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out]) begin
			$display("%d: write-back token=%h %h->%h dec=%d hist=%h c/g/b=%d@%h/%d@%h/%d@%h", $time, r_pend_out, r_pend_pc[r_pend_out], r_pend_dest[r_pend_out], r_pend_dec[r_pend_out], r_pend_global_history[r_pend_out], r_pend_combined_pred[r_pend_out], pend_combined_index[r_pend_out], r_pend_global_pred[r_pend_out], pend_global_index[r_pend_out], r_pend_bimodal_pred[r_pend_out], pend_bimodal_index[r_pend_out]);
        end
	end
//	always @(posedge clk) begin
//		$display("%d:		%b%b %b%b %b %b %h", $time, predict_branch_valid,predict_branch_taken, push_enable, push_taken, r_pend_valid[r_pend_out]&r_pend_committed[r_pend_out], commit_shootdown, global_xhistory[2]);
//	end
`endif

	reg				predict_taken;

	//
	//	pending state
	//

	reg [$clog2(NUM_PENDING)-1:0]r_pend_in, c_pend_in;	// point to next one to be allocated
	reg [$clog2(NUM_PENDING)-1:0]r_pend_out, c_pend_out;// point to next one to be committed
	wire [$clog2(NUM_PENDING)-1:0]last_pushed = r_pend_in+(NUM_PENDING-1);
	reg		[NUM_PENDING-1:0]r_pend_valid;
	reg		[NUM_PENDING-1:0]r_pend_committed;
	reg		[NUM_PENDING-1:0]r_pend_taken;
	reg		[RV-1:1]r_pend_dest[0:NUM_PENDING-1];
	reg		[RV-1:1]r_pend_pc[0:NUM_PENDING-1];
	reg		[GLOBAL_HISTORY*4-1:0]r_pend_global_history[0:NUM_PENDING-1];
wire	[GLOBAL_HISTORY*4-1:0]r_pend_global_history0=r_pend_global_history[r_pend_out];
	reg		[1:0]r_pend_global_pred[0:NUM_PENDING-1];
	reg		[1:0]r_pend_global_prev[0:NUM_PENDING-1];
	reg		[BDEC-1-1:0]r_pend_global_dec[0:NUM_PENDING-1];
	reg		[BDEC-1-1:0]r_pend_dec[0:NUM_PENDING-1];
	reg		[1:0]r_pend_bimodal_pred[0:NUM_PENDING-1];
	reg		[1:0]r_pend_bimodal_prev[0:NUM_PENDING-1];
	reg		[BDEC-1-1:0]r_pend_bimodal_dec[0:NUM_PENDING-1];
	reg		[1:0]r_pend_combined_pred[0:NUM_PENDING-1];
	reg		[1:0]r_pend_combined_prev[0:NUM_PENDING-1];
	reg		[2:0]r_pend_mode[0:NUM_PENDING-1];
	reg		[NUM_PENDING-1:0]global_pend_prediction_valid;
	reg		[NUM_PENDING-1:0]bimodal_pend_prediction_valid;
	reg		[NUM_PENDING-1:0]combined_pend_prediction_valid;

wire [RV-1:1]r_pend_pc0 = r_pend_pc[r_pend_out];		// this is just debug stuff
wire [RV-1:1]r_pend_dest0 = r_pend_dest[r_pend_out];
wire [BDEC-1:1]r_pend_dec0 = r_pend_dec[r_pend_out];
wire         r_pend_taken0 = r_pend_taken[r_pend_out];
wire pend_writeback = r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out];
wire [1:0]r_pend_combined_pred0 = r_pend_combined_pred[r_pend_out];
wire [1:0]r_pend_bimodal_pred0 = r_pend_bimodal_pred[r_pend_out];
wire [1:0]r_pend_global_pred0 = r_pend_global_pred[r_pend_out];
	wire [NUM_GLOBAL-1:0]pend_global_index[0:NUM_PENDING-1];
wire [NUM_GLOBAL-1:0]pend_global_index0=pend_global_index[r_pend_out];
	wire [NUM_BIMODAL-1:0]pend_bimodal_index[0:NUM_PENDING-1];
wire [NUM_BIMODAL-1:0]pend_bimodal_index0=pend_bimodal_index[r_pend_out];
	wire [NUM_COMBINED-1:0]pend_combined_index[0:NUM_PENDING-1];
wire [NUM_COMBINED-1:0]pend_combined_index0=pend_combined_index[r_pend_out];

	assign push_token = r_pend_in;
	wire [NUM_PENDING-1:0]pend_dest_hit;
	reg [$clog2(NUM_PENDING)-1:0]trap_shootdown_index;

	always @(posedge clk) 
		r_pend_in <= c_pend_in;
	always @(posedge clk) 
		r_pend_out <= c_pend_out;

	always @(*) begin
		c_pend_out = r_pend_out;
		if (reset || clear) begin
			c_pend_out = 0;
		end else
		if (r_pend_valid[r_pend_out]) begin
			if (r_pend_committed[r_pend_out]) begin
				c_pend_out = r_pend_out+1;
			end
		end else begin
			if (r_pend_out != r_pend_in) begin
				c_pend_out = r_pend_out+1;
			end
		end
	end

	always @(*) begin
		c_pend_in = r_pend_in;
		if (reset || clear) begin
			c_pend_in = 0;
		end else
		if (trap_shootdown) begin
			c_pend_in = trap_shootdown_index;
		end else
		if (commit_shootdown && r_pend_valid[shootdown_token]) begin
			c_pend_in = shootdown_token+1;
		end else 
		if (push_enable && (!r_pend_valid[r_pend_out] || r_pend_out != r_pend_in)) begin
			c_pend_in = r_pend_in+1;
		end
	end

	generate

		for (P = 0; P < NUM_PENDING; P = P+1) begin: pend
			wire [NUM_GLOBAL-1:0]pend_global_index_x;
			assign pend_global_index_x = r_pend_pc[P][BDEC+NUM_GLOBAL-1:BDEC]^{r_pend_pc[P][BDEC-1:1], {(NUM_GLOBAL-(BDEC-1)){1'b0}}};
			
			wire [NUM_GLOBAL-1:0]xindex;
			if (GLOBAL_HISTORY == 6) begin		// hand built mappings of history to hashes	 (must be the same as above)
				if (NUM_GLOBAL == 12) begin
					assign xindex = r_pend_global_history[P][11:0]^{3'b0, r_pend_global_history[P][18:12], 2'b0}^{2'b0, r_pend_global_history[P][23:19], 5'b0};
				end else
				if (NUM_GLOBAL == 10) begin
					assign xindex = r_pend_global_history[P][10:0]^{2'b0, r_pend_global_history[P][18:11], 2'b0}^{2'b0, r_pend_global_history[P][23:19], 5'b0};
				end else
				if (NUM_GLOBAL == 9) begin
					assign xindex = r_pend_global_history[P][8:0]^{r_pend_global_history[P][16:9], 1'b0}^{r_pend_global_history[P][23:17], 2'b0};
				end else begin
					assign xindex = 'bx;
				end
			end else
			if (GLOBAL_HISTORY == 8) begin		// 32 bits
				if (NUM_GLOBAL == 12) begin
					assign xindex = r_pend_global_history[P][11:0]^{r_pend_global_history[P][21:12], 2'b0}^{r_pend_global_history[P][31:22], 2'b0};
				end else
				if (NUM_GLOBAL == 13) begin
					assign xindex = r_pend_global_history[P][12:0]^{r_pend_global_history[P][23:13], 2'b0}^{1'b0, r_pend_global_history[P][31:24], 5'b0};
				end 
			end else begin
				assign xindex = 'bx;
			end
			assign pend_global_index[P] = xindex^pend_global_index_x;
			assign pend_combined_index[P] = r_pend_pc[P][BDEC+NUM_COMBINED-1:BDEC]^{r_pend_pc[P][BDEC-1:1], {(NUM_COMBINED-(BDEC-1)){1'b0}}};
			assign pend_bimodal_index[P]  = r_pend_pc[P][BDEC+NUM_BIMODAL-1:BDEC]^{r_pend_pc[P][BDEC-1:1], {(NUM_BIMODAL-(BDEC-1)){1'b0}}};

			assign global_pend_prediction_valid[P] = r_pend_valid[P] && (!r_pend_taken[P] || r_pend_dec[P] >= pc[BDEC-1:1]) && pend_global_index[P] == global_index && r_pend_pc[P][BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL] == pc[BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL];

			assign bimodal_pend_prediction_valid[P] = r_pend_valid[P] && (!r_pend_taken[P] || r_pend_dec[P] >= pc[BDEC-1:1]) && pend_bimodal_index[P] == bimodal_index && r_pend_pc[P][BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL] == pc[BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL];

			assign combined_pend_prediction_valid[P] = r_pend_valid[P] && pend_combined_index[P] == combined_index;

			assign pend_dest_hit[P] = r_pend_valid[P] && r_pend_pc[P] == pc;

			always @(posedge clk) begin
				if (reset||clear) begin
					r_pend_valid[P] <= 0;
				end else
				if (trap_shootdown && r_pend_valid[P] && !(r_pend_committed[P]||commit_token_done[P])) begin	// flush unwanted
					r_pend_valid[P] <= 0;
				end else
				if (commit_shootdown && r_pend_valid[P] &&
						((r_pend_in > P && P > shootdown_token) ||
						 (r_pend_in < shootdown_token &&
							(P > shootdown_token || r_pend_in >= P)))) begin	// flush unwanted
					r_pend_valid[P] <= 0;
				end else
				if (push_enable && !commit_shootdown && r_pend_in == P && (r_pend_in != r_pend_out || !r_pend_valid[r_pend_out])) begin
					r_pend_valid[P] <= 1;
					r_pend_committed[P] <= push_noissue&&(push_pc[BDEC-1]==push_branch_decoder); // no matching entry to commit us
					r_pend_pc[P] <= push_pc;
					r_pend_dest[P] <= push_dest;
					r_pend_dec[P] <= push_branch_decoder;
					r_pend_taken[P] <= push_taken;
					r_pend_mode[P] <= r_mode;
				end else 
				if (r_pend_out == P && r_pend_valid[P] && r_pend_committed[P]) begin	// done
					r_pend_valid[P] <= 0;
				end else begin
					if (r_pend_valid[P] && commit_token_done[P]) 
						r_pend_committed[P] <= 1;
					if (commit_shootdown && shootdown_token == P) begin   // this branch was mispredicted
						r_pend_taken[P] <= shootdown_taken;
						if (shootdown_taken) begin
							r_pend_dest[P] <= commit_shootdown_dest;
							r_pend_dec[P] <= shootdown_dec;
						end
					end else
					if (fixup_dest && last_pushed == P) begin   // this branch was mispredicted
						r_pend_dest[P] <= fixup_dest_pc;
						r_pend_dec[P] <= fixup_dest_dec;
						r_pend_taken[P] <= 1;
					end
				end
				if (!r_pend_valid[P]) begin
					r_pend_bimodal_dec[P] <= push_context.bimodal_prediction_dec;
					r_pend_global_dec[P] <= push_context.global_prediction_dec;
					r_pend_bimodal_prev[P] <= push_context.bimodal_prediction_prev;
					r_pend_bimodal_pred[P] <= (push_taken? (push_context.bimodal_prediction_prev[1]? 2'b11:push_context.bimodal_prediction_prev+2'b1) : (!push_context.bimodal_prediction_prev[1]? 2'b00:push_context.bimodal_prediction_prev-2'b1));
					r_pend_combined_prev[P] <= push_context.combined_prediction_prev;
					casez ({push_taken, push_context.global_prediction_prev[1], push_context.bimodal_prediction_prev[1],
							push_context.global_prediction_dec==push_branch_decoder,
							push_context.bimodal_prediction_dec==push_branch_decoder}) // synthesis full_case parallel_case
5'b1_11_11,
					5'b1_11_10,
					5'b1_10_1?,
					5'b0_01_??:	if (push_context.combined_prediction_prev!=3) begin
									r_pend_combined_pred[P] <= push_context.combined_prediction_prev+1;
								end else begin
									r_pend_combined_pred[P] <= push_context.combined_prediction_prev;
								end
					5'b1_11_01,
					5'b1_01_?1,
					5'b0_10_??:	if (push_context.combined_prediction_prev!=0) begin
									r_pend_combined_pred[P] <= push_context.combined_prediction_prev-1;
								end else begin
									r_pend_combined_pred[P] <= push_context.combined_prediction_prev;
								end 
					default:	r_pend_combined_pred[P] <= push_context.combined_prediction_prev;
					endcase
					r_pend_global_prev[P] <= push_context.global_prediction_prev;
					r_pend_global_pred[P] <= (push_taken? (push_context.global_prediction_prev[1]? 2'b11:push_context.global_prediction_prev+2'b1) : (!push_context.global_prediction_prev[1]? 2'b00:push_context.global_prediction_prev-2'b1));
					r_pend_global_history[P] <= push_context.global_history;
				end else 
				if (commit_shootdown && shootdown_token == P) begin   // this branch was mispredicted
`ifdef SDEBUG 
$display("%d: SHOOT %d taken=%d dec=%d gl=%d bi=%d comb-prev=%b %b/%b %b/%b", $time, P, shootdown_taken, shootdown_dec, r_pend_global_dec[P], r_pend_bimodal_dec[P], r_pend_combined_prev[P], r_pend_global_prev[P], r_pend_global_pred[P], r_pend_bimodal_prev[P], r_pend_bimodal_pred[P]);
`endif
					casez ({shootdown_taken, r_pend_global_prev[P][1], r_pend_bimodal_prev[P][1],
							r_pend_global_dec[P]==shootdown_dec,
							r_pend_bimodal_dec[P]==shootdown_dec}) // synthesis full_case parallel_case
					5'b1_11_10,
					5'b1_10_1?,
					5'b0_01_??:if (r_pend_combined_prev[P]!=3) begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]+1;
								end else begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P];
								end
					5'b1_11_01,
					5'b1_01_?1,
					5'b0_10_??:if (r_pend_combined_prev[P]!=0) begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]-1;
								end else begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P];
								end
					default:	r_pend_combined_pred[P] <= r_pend_combined_prev[P];
					endcase
					if (shootdown_taken) begin
						r_pend_global_pred[P] <= r_pend_global_prev[P][1]   ? 2'b11 : r_pend_global_prev[P]+1;
						r_pend_bimodal_pred[P] <= r_pend_bimodal_prev[P][1] ? 2'b11: r_pend_bimodal_prev[P]+1;
					end else begin
						r_pend_global_pred[P] <= !r_pend_global_prev[P][1]   ? 2'b00: r_pend_global_prev[P]-1;
						r_pend_bimodal_pred[P] <= !r_pend_bimodal_prev[P][1] ? 2'b00: r_pend_bimodal_prev[P]-1;
					end
				end else
				if (fixup_dest && last_pushed == P) begin   // this branch was mispredicted (twice)
`ifdef XDEBUG
$display("FIXUP#%h %b dec=%d c=%d g/b=%d/%d",P, {r_pend_global_prev[P][1], r_pend_bimodal_prev[P][1], r_pend_global_dec[P]==fixup_dest_dec, r_pend_bimodal_dec[P]==fixup_dest_dec}, fixup_dest_dec,r_pend_combined_prev[P],  r_pend_global_dec[P], r_pend_bimodal_dec[P]);
`endif
					casez ({r_pend_global_prev[P][1], r_pend_bimodal_prev[P][1],
							r_pend_global_dec[P]==fixup_dest_dec,
							r_pend_bimodal_dec[P]==fixup_dest_dec}) // synthesis full_case parallel_case
					4'b11_10,
					4'b10_1?: if (r_pend_combined_prev[P]!=3) begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]+1;
								end else begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P];
								end
					4'b11_01,
					4'b01_?1: if (r_pend_combined_prev[P]!=0) begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]-1;
								end else begin
									r_pend_combined_pred[P] <= r_pend_combined_prev[P];
								end
					default:	r_pend_combined_pred[P] <= r_pend_combined_prev[P];
					endcase
					r_pend_global_pred[P] <= r_pend_global_prev[P][1]   ? 2'b11 : r_pend_global_prev[P]+1;
					r_pend_bimodal_pred[P] <= r_pend_bimodal_prev[P][1] ? 2'b11 : r_pend_bimodal_prev[P]+1;
				end
			end
		end
	endgenerate

	

	//
	//	unconditional jump predictor
	//
	
	// currently MIA

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

