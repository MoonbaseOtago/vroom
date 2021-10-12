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


module bpred(input clk,  input reset,
		input			[3:0]cpu_mode,					// protection state
		input				 clear_user,				// clear user history
		input				 clear_sup,					// clear sup history

		input        [RV-1:1]pc,						// pc we're predicting
		output				 predict_branch_valid,		// we have a valid prediction
		output				 predict_branch_taken,		// predict we're taking this branch
		output		 [RV-1:1]predict_branch_pc,			// predicted destination
	    output [$clog2(2*NDEC)-1:0]predict_branch_decoder,	// predict decoder

		input				 push_enable,				// true if there's one or more branches here
		input		 [RV-1:1]push_pc,					// pc we fetched with
		input				 push_noissue,				// it is an unconditional branch - it wont show up in the 
														// completion stage
	    input [$clog2(2*NDEC)-1:0]push_branch_decoder,	// predict decoder (taken branch offst)
		input		 [RV-1:1]push_dest,					// branch dest (if taken)
		input				 push_taken,				// true if branch was taken
		output [$clog2(NUM_PENDING)-1:0]push_token,		// token for when we fail

		input				 trap_shootdown,			// trap
		input [$clog2(NUM_PENDING)-1:0]trap_shootdown_token,	// latest killed entry
		input				 commit_shootdown,			// commitq break shootdown (branch miss)
		input				 commit_shootdown_taken,	// commitq break shootdown (branch miss)
		input [$clog2(NUM_PENDING)-1:0]commit_shootdown_token,	// latest killed entry
		input        [RV-1:1]commit_shootdown_dest,			// 
		input      [BDEC-1:1]commit_shootdown_dec,

		input [NUM_PENDING-1:0]commit_token,			// bit encoded tokens from the commitQ commit stage

		input				 push_cs_stack, 
		input				 pop_cs_stack,
		output				 pop_available,
		input		 [RV-1:1]ret_addr,
		output				 return_branch_valid,
		output		 [RV-1:1]return_branch_pc,
		

		output	[$clog2(CALL_STACK_SIZE)-1:0]cs_top,
		input				 flush_call_stack,
		input	[$clog2(CALL_STACK_SIZE)-1:0]flush_cs_top
	);

	parameter RV=64;
	parameter NDEC=4;
	parameter BDEC=4;
	parameter CALL_STACK_SIZE=32;
`ifdef PSYNTH
	parameter MCALL_STACK_SIZE = CALL_STACK_SIZE / 2;	// might do this for real chips
`else
	parameter MCALL_STACK_SIZE = CALL_STACK_SIZE; 
`endif

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
	parameter	GLOBAL_HISTORY = 6;		// size of the global history (bits)
	parameter	VTAG_SIZE = 8;			// we don't keep a full tag for gl/bi entries


	reg		[2:0]r_mode;
	always @(posedge clk) begin
		r_mode[2] <= cpu_mode[3];
		r_mode[1] <= cpu_mode[1];
		r_mode[0] <= cpu_mode[0];
	end
	wire [2:0]clear = {1'b0, clear_sup, clear_user};

	//
	//	return stack
	//

	wire [2:0]pop_available_x;
	wire [2:0]return_branch_valid_x;
	wire [RV-1:1]return_branch_pc_x[0:2];
	wire [$clog2(CALL_STACK_SIZE)-1:0]cs_top_x[0:2];

	reg			pop_available_m;
	assign pop_available = pop_available_m;
	reg			return_branch_valid_m;
	assign return_branch_valid = return_branch_valid_m;
	reg [RV-1:1]return_branch_pc_m;
	assign return_branch_pc = return_branch_pc_m;
	reg [$clog2(CALL_STACK_SIZE)-1:0]cs_top_m;
	assign cs_top = cs_top_m;

	always @(*)
	casez (r_mode) // synthesis full_case parallel_case
	3'b??1: begin
				pop_available_m = pop_available_x[0];
				return_branch_valid_m = return_branch_valid_x[0];
				return_branch_pc_m = return_branch_pc_x[0];
				cs_top_m = cs_top_x[0];
			end
	3'b?1?: begin
				pop_available_m = pop_available_x[1];
				return_branch_valid_m = return_branch_valid_x[1];
				return_branch_pc_m = return_branch_pc_x[1];
				cs_top_m = cs_top_x[1];
			end
	3'b1??: begin
				pop_available_m = pop_available_x[2];
				return_branch_valid_m = return_branch_valid_x[2];
				return_branch_pc_m = return_branch_pc_x[2];
				cs_top_m = cs_top_x[2];
			end
	endcase

	genvar M;

	generate
		for (M = 0; M < 3; M=M+1) begin: callstack
			reg [RV-1:1]r_call_stack[0:(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1];
			reg [$clog2((M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE))-1:0]r_cs_top, r_cs_bottom;
			assign cs_top_x[M] = r_cs_top;
			wire [$clog2((M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE))-1:0]cs_top_inc=r_cs_top+1;
			wire [$clog2(M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE)-1:0]cs_top_dec=r_cs_top-1;
			reg			r_empty;
			assign pop_available_x[M] = !r_empty;
			assign return_branch_valid_x[M] = pop_cs_stack&&!r_empty;
			assign return_branch_pc_x[M] = r_call_stack[r_cs_top];
		
			wire		[$clog2((M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE))-1:0]sc_diff = r_cs_top-r_cs_bottom;
			wire		fullish = sc_diff[$clog2((M==2?MCALL_STACK_SIZE:CALL_STACK_SIZE))-1];
		
		
			always @(posedge clk) begin
				casez ({reset||clear[M], flush_call_stack&r_mode[M], push_cs_stack&r_mode[M], pop_cs_stack&!r_empty&r_mode[M]}) // synthesis full_case parallel_case
				4'b1???:begin					
							r_cs_top <= 0;
							r_cs_bottom <= 0;
							r_empty <= 1;
						end
				4'b01??:begin
							if (flush_cs_top == r_cs_bottom) begin
								r_empty <= !fullish;
							end
							r_cs_top <= flush_cs_top;
						end
				4'b0010:begin
							if (r_empty) begin
								r_empty <= 0;
							end else
							if (r_cs_bottom == r_cs_top) begin
								r_cs_bottom <= cs_top_inc;
							end
							r_cs_top <= cs_top_inc;
							r_call_stack[cs_top_inc] <= ret_addr;
						end
				4'b0001:begin
							if (r_cs_bottom == cs_top_dec) begin
								r_empty <= 1;
							end
							r_cs_top <= cs_top_dec;
						end
				4'b0011:begin
							r_call_stack[r_cs_top] <= ret_addr;
						end
				4'b0000: ;
				endcase
			end
		end
	endgenerate

	//
	//	branch predictors - esentially there's a bimodal predictor and a global predictor and a predictor predictor
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
`include "mk20_32_4.inc"
		end
	endgenerate

	//
	// global history
	//

	

	wire	[1:0]global_xprediction[0:2];
	wire	[1:0]global_xprediction_push[0:2];
	wire [2:0]global_tag_hit;
	wire [2:0]global_tag_push_hit;
	wire	[BDEC-1-1:0]global_xdec[0:2];
	wire	[RV-1:1]global_xdest[0:2];
	reg	[$clog2(NUM_PENDING)-1:0]global_pred_index;
	reg	[$clog2(NUM_PENDING)-1:0]global_pred_push_index;
	wire [GLOBAL_HISTORY-1:0]global_xhistory[0:2];

	wire  [NUM_GLOBAL-1:0]global_index_g = pc[BDEC+NUM_GLOBAL-1:BDEC]^{pc[BDEC-1:1],{(NUM_GLOBAL-(BDEC-2)){1'b0}}};
	wire [NUM_GLOBAL-1:0]global_push_index_g = push_pc[BDEC+NUM_GLOBAL-1:BDEC]^{push_pc[BDEC-1:1],{(NUM_GLOBAL-(BDEC-2)){1'b0}}};
	
	generate
		for (M = 0; M < 3; M=M+1) begin : gl
			wire  [NUM_GLOBAL-1:0]global_index;
			wire  [NUM_GLOBAL-1:0]global_push_index;
			reg	 [GLOBAL_HISTORY-1:0]r_global_history;						// actual global history
			assign global_xhistory[M] = r_global_history;
			reg		[2*(1<<NUM_GLOBAL)-1:0]r_global_tables;					// global history tables (counter 0-3 >=2 means taken)
			reg		[RV-1:1]r_global_dest[0:(1<<NUM_GLOBAL)-1];				// dest target
			reg		[VTAG_SIZE-1:0]r_global_tag[0:(1<<NUM_GLOBAL)-1];
			reg		[(1<<NUM_GLOBAL)-1:0]r_global_tag_valid;
			reg		[BDEC-1-1:0]r_global_dec[0:(1<<NUM_GLOBAL)-1];	// global history tables decoder offset
			assign	global_index      = {{(BDEC-1){1'b0}}, r_global_history, {(NUM_GLOBAL-GLOBAL_HISTORY-(BDEC-1)){1'b0}}}^global_index_g;
			assign	global_push_index = {{(BDEC-1){1'b0}}, r_global_history, {(NUM_GLOBAL-GLOBAL_HISTORY-(BDEC-1)){1'b0}}}^global_push_index_g;
			assign	global_xprediction[M]      = {r_global_tables[{global_index, 1'b1}], r_global_tables[{global_index, 1'b0}]};
			assign	global_xprediction_push[M] = {r_global_tables[{global_push_index, 1'b1}], r_global_tables[{global_push_index, 1'b0}]};
			assign	global_tag_hit[M] = r_mode[M] && r_global_tag_valid[global_index] && r_global_tag[global_index] == pc[BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL] && (!r_global_tables[{global_index, 1'b1}] || r_global_dec[global_index] >= pc[BDEC-1:1]);
			assign	global_tag_push_hit[M] = r_global_tag_valid[global_push_index] && r_global_tag[global_push_index] == push_pc[BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL] && (!r_global_tables[{global_push_index, 1'b1}] || r_global_dec[global_push_index] >= push_pc[BDEC-1:1]);

			assign 	global_xdec[M] = r_global_dec[global_index];
			assign 	global_xdest[M] = r_global_dest[global_index];

			always @(posedge clk) begin
				if (reset || clear[M]) begin
					r_global_history <= 0;
				end else 
				if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out] && r_pend_mode[r_pend_out][M]) begin
					r_global_history <= r_pend_global_history[r_pend_out];
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
					if (r_pend_taken[r_pend_out]) begin
						r_global_dec[pend_global_index[r_pend_out]] <= r_pend_dec[r_pend_out];
						r_global_dest[pend_global_index[r_pend_out]] <= r_pend_dest[r_pend_out];
					end
				end
			end
		end

	endgenerate

	reg	[1:0]global_prediction;
	reg	[1:0]global_push_prediction;
	reg	[RV-1:1]global_dest;
	reg	[BDEC-1-1:0]global_dec;
	reg	[GLOBAL_HISTORY-1:0]global_history;
	always @(*) begin
		if (|global_pend_prediction_valid) begin
			global_prediction =  r_pend_global_pred[global_pred_index];
			global_dest = r_pend_dest[global_pred_index];
			global_dec = r_pend_dec[global_pred_index];
			global_history = r_pend_global_history[global_pred_index];
		end else
		casez(r_mode) // synthesis full_case parallel_case
		3'b??1: begin
					global_prediction = global_xprediction[0];
					global_dest = global_xdest[0];
					global_dec = global_xdec[0];
					global_history = global_xhistory[0];
				end
		3'b?1?: begin
					global_prediction = global_xprediction[1];
					global_dest = global_xdest[1];
					global_dec = global_xdec[1];
					global_history = global_xhistory[1];
				end
		3'b1??: begin
					global_prediction = global_xprediction[2];
					global_dest = global_xdest[2];
					global_dec = global_xdec[2];
					global_history = global_xhistory[2];
				end
		endcase
	end
	always @(*) begin
		if (|global_pend_prediction_push_valid) begin
				global_push_prediction = r_pend_global_pred[global_pred_push_index];
		end else
		casez(r_mode) // synthesis full_case parallel_case
		3'b??1: global_push_prediction = global_tag_push_hit[0] ?global_xprediction_push[0] : push_taken ? 2'b01: 2'b10;
		3'b?1?: global_push_prediction = global_tag_push_hit[1] ?global_xprediction_push[1] : push_taken ? 2'b01: 2'b10;
		3'b1??: global_push_prediction = global_tag_push_hit[2] ?global_xprediction_push[2] : push_taken ? 2'b01: 2'b10;
		endcase
	end

	//
	//	bimodal predictor
	//

	wire  [NUM_BIMODAL-1:0]bimodal_index = pc[BDEC+NUM_BIMODAL-1:BDEC]^{pc[BDEC-1:1], {(NUM_BIMODAL-(BDEC-2)){1'b0}}};
	wire  [NUM_BIMODAL-1:0]bimodal_push_index = push_pc[BDEC+NUM_BIMODAL-1:BDEC]^{push_pc[BDEC-1:1], {(NUM_BIMODAL-(BDEC-2)){1'b0}}};
	wire [1:0]bimodal_xprediction[0:2];
	wire [1:0]bimodal_xprediction_push[0:2];
	wire [2:0]bimodal_tag_hit;
	wire [2:0]bimodal_tag_push_hit;
	wire [BDEC-1-1:0]bimodal_xdec[0:2];
	wire  [RV-1:1]bimodal_xdest[0:2];

	reg	[$clog2(NUM_PENDING)-1:0]bimodal_pred_index;
	reg	[$clog2(NUM_PENDING)-1:0]bimodal_pred_push_index;

	generate
		for (M = 0; M < 3; M=M+1) begin : bi
			reg		[2*(1<<NUM_BIMODAL)-1:0]r_bimodal_tables;	// bimodal history tables (counter 0-3 >=2 means taken)
			reg		[BDEC-1-1:0]r_bimodal_dec[0:(1<<NUM_BIMODAL)-1];	// bimodal history tables decoder offset
			reg		[RV-1:1]r_bimodal_dest[0:(1<<NUM_BIMODAL)-1];	
			reg		[VTAG_SIZE-1:0]r_bimodal_tag[0:(1<<NUM_BIMODAL)-1];
			reg		[(1<<NUM_BIMODAL)-1:0]r_bimodal_tag_valid;
			assign bimodal_xprediction[M] = {r_bimodal_tables[{bimodal_index,1'b1}], r_bimodal_tables[{bimodal_index,1'b0}]};
			assign bimodal_xprediction_push[M] = {r_bimodal_tables[{bimodal_push_index,1'b1}], r_bimodal_tables[{bimodal_push_index,1'b0}]};

			assign bimodal_tag_hit[M] = r_mode[M] && r_bimodal_tag_valid[bimodal_index] && r_bimodal_tag[bimodal_index] == pc[BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL] && (!r_bimodal_tables[{bimodal_index, 1'b1}] || r_bimodal_dec[bimodal_index] >= pc[BDEC-1:1]); 
			assign bimodal_tag_push_hit[M] = r_bimodal_tag_valid[bimodal_push_index] && r_bimodal_tag[bimodal_push_index] == push_pc[BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL] && (!r_bimodal_tables[{bimodal_push_index, 1'b1}] || r_bimodal_dec[bimodal_push_index] >= push_pc[BDEC-1:1]); 
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
					if (r_pend_taken[r_pend_out]) begin
						r_bimodal_dec[pend_bimodal_index[r_pend_out]] <= r_pend_dec[r_pend_out];
						r_bimodal_dest[pend_bimodal_index[r_pend_out]] <= r_pend_dest[r_pend_out];
					end
				end
			end
		end
	endgenerate

	reg	[1:0]bimodal_prediction;
	reg	[1:0]bimodal_push_prediction;
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
	always @(*) begin
		if (|bimodal_pend_prediction_push_valid) begin		
			bimodal_push_prediction = r_pend_bimodal_pred[bimodal_pred_push_index];
		end else
		casez (r_mode) // synthesis full_case parallel_case
		3'b??1:	bimodal_push_prediction = bimodal_tag_push_hit[0] ?  bimodal_xprediction_push[0] : push_taken ? 2'b01: 2'b10;
		3'b?1?:	bimodal_push_prediction = bimodal_tag_push_hit[1] ?  bimodal_xprediction_push[1] : push_taken ? 2'b01: 2'b10;
		3'b1??:	bimodal_push_prediction = bimodal_tag_push_hit[2] ?  bimodal_xprediction_push[2] : push_taken ? 2'b01: 2'b10;
		endcase
	end
	
	//
	//	combined predictor
	//

	wire  [NUM_COMBINED-1:0]combined_index = pc[BDEC+NUM_COMBINED-1:BDEC]^{pc[BDEC-1:1], {(NUM_COMBINED-(BDEC-2)){1'b0}}};
	wire  [NUM_COMBINED-1:0]combined_push_index = push_pc[BDEC+NUM_COMBINED-1:BDEC]^{push_pc[BDEC-1:1], {(NUM_COMBINED-(BDEC-2)){1'b0}}};
	reg	[$clog2(NUM_PENDING)-1:0]combined_pred_index;
	reg	[$clog2(NUM_PENDING)-1:0]combined_pred_push_index;
	wire [1:0]combined_xprediction[0:2];
	wire [1:0]combined_xprediction_push[0:2];
	reg		[1:0]combined_prediction;
	reg		[1:0]combined_push_prediction;
	generate

		for (M = 0; M < 3; M = M+1) begin : cmb
			reg		[(2<<NUM_COMBINED)-1:0]r_combined_tables;	// combined history tables (counter 0-3 >=2 means taken)
			assign combined_xprediction[M] = {r_combined_tables[{combined_index, 1'b1}], r_combined_tables[{combined_index, 1'b0}]};
			assign combined_xprediction_push[M] = {r_combined_tables[{combined_push_index, 1'b1}], r_combined_tables[{combined_push_index, 1'b0}]};

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

	always @(*) begin
		if (|combined_pend_prediction_push_valid) begin
			combined_push_prediction = r_pend_combined_pred[combined_pred_push_index];
		end else
		casez (r_mode) // synthesis full_case parallel_case
		3'b??1: combined_push_prediction = combined_xprediction_push[0];
		3'b?1?: combined_push_prediction = combined_xprediction_push[1];
		3'b1??: combined_push_prediction = combined_xprediction_push[2];
		endcase
	end

	wire global_valid = |global_tag_hit | (|global_pend_prediction_valid);
	wire bimodal_valid = |bimodal_tag_hit | (|bimodal_pend_prediction_valid);


	reg				predict_taken;
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

	//
	//	pending state
	//

	reg [$clog2(NUM_PENDING)-1:0]r_pend_in, c_pend_in;	// point to next one to be allocated
	reg [$clog2(NUM_PENDING)-1:0]r_pend_out, c_pend_out;// point to next one to be committed
	reg		[NUM_PENDING-1:0]r_pend_valid;
	reg		[NUM_PENDING-1:0]r_pend_committed;
	reg		[NUM_PENDING-1:0]r_pend_taken;
	reg		[RV-1:1]r_pend_dest[0:NUM_PENDING-1];
	reg		[RV-1:1]r_pend_pc[0:NUM_PENDING-1];
	reg		[GLOBAL_HISTORY-1:0]r_pend_global_history[0:NUM_PENDING-1];
wire	[GLOBAL_HISTORY-1:0]r_pend_global_history0=r_pend_global_history[r_pend_out];
	reg		[1:0]r_pend_global_pred[0:NUM_PENDING-1];
	reg		[1:0]r_pend_global_prev[0:NUM_PENDING-1];
	reg		[BDEC-1-1:0]r_pend_dec[0:NUM_PENDING-1];
	reg		[1:0]r_pend_bimodal_pred[0:NUM_PENDING-1];
	reg		[1:0]r_pend_bimodal_prev[0:NUM_PENDING-1];
	reg		[1:0]r_pend_combined_pred[0:NUM_PENDING-1];
	reg		[1:0]r_pend_combined_prev[0:NUM_PENDING-1];
	reg		[2:0]r_pend_mode[0:NUM_PENDING-1];
	reg		[NUM_PENDING-1:0]global_pend_prediction_valid;
	reg		[NUM_PENDING-1:0]global_pend_prediction_push_valid;
	reg		[NUM_PENDING-1:0]bimodal_pend_prediction_valid;
	reg		[NUM_PENDING-1:0]bimodal_pend_prediction_push_valid;
	reg		[NUM_PENDING-1:0]combined_pend_prediction_valid;
	reg		[NUM_PENDING-1:0]combined_pend_prediction_push_valid;

wire [RV-1:1]r_pend_pc0 = r_pend_pc[r_pend_out];		// this is just debug stuff
wire [RV-1:1]r_pend_dest0 = r_pend_dest[r_pend_out];
wire [BDEC-1:1]r_pend_dec0 = r_pend_dec[r_pend_out];
wire         r_pend_taken0 = r_pend_taken[r_pend_out];
wire pend_writeback = r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out];
wire [1:0]r_pend_combined_pred0 = r_pend_combined_pred[r_pend_out];
wire [1:0]r_pend_bimodal_pred0 = r_pend_bimodal_pred[r_pend_out];
wire [1:0]r_pend_global_pred0 = r_pend_global_pred[r_pend_out];
	wire [NUM_GLOBAL-1:0]pend_global_index[0:NUM_PENDING-1];
	wire [NUM_GLOBAL-1:0]pend_global_index_x[0:NUM_PENDING-1];
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
		if (r_pend_valid[r_pend_out] && r_pend_committed[r_pend_out]) begin
			c_pend_out = r_pend_out+1;
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
		if (commit_shootdown) begin
			c_pend_in = commit_shootdown_token+1;
		end else 
		if (push_enable && (!r_pend_valid[r_pend_out] || r_pend_out != r_pend_in)) begin
			c_pend_in = r_pend_in+1;
		end
	end


	genvar P;
	generate

		for (P = 0; P < NUM_PENDING; P = P+1) begin: pend
			assign pend_global_index_x[P] = r_pend_pc[P][BDEC+NUM_GLOBAL-1:BDEC]^{r_pend_pc[P][BDEC-1:1], {(NUM_GLOBAL-(BDEC-2)){1'b0}}};
			
			assign pend_global_index[P] = {{(BDEC-1){1'b0}}, r_pend_global_history[P], {(NUM_GLOBAL-GLOBAL_HISTORY-(BDEC-1)){1'b0}}}^pend_global_index_x[P];
			assign pend_combined_index[P] = r_pend_pc[P][BDEC+NUM_COMBINED-1:BDEC]^{r_pend_pc[P][BDEC-1:1], {(NUM_COMBINED-(BDEC-2)){1'b0}}};
			assign pend_bimodal_index[P]  = r_pend_pc[P][BDEC+NUM_BIMODAL-1:BDEC]^{r_pend_pc[P][BDEC-1:1], {(NUM_BIMODAL-(BDEC-2)){1'b0}}};

			assign global_pend_prediction_valid[P] = r_pend_valid[P] && (!r_pend_taken[P] || r_pend_dec[P] >= pc[BDEC-1:1]) && pend_global_index_x[P] == global_index_g && r_pend_pc[P][BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL] == pc[BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL];
			assign global_pend_prediction_push_valid[P] = r_pend_valid[P] && (!r_pend_taken[P] || r_pend_dec[P] >= push_pc[BDEC-1:1]) && pend_global_index_x[P] == global_push_index_g && r_pend_pc[P][BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL] == push_pc[BDEC+NUM_GLOBAL+VTAG_SIZE-1:BDEC+NUM_GLOBAL];

			assign bimodal_pend_prediction_valid[P] = r_pend_valid[P] && (!r_pend_taken[P] || r_pend_dec[P] >= pc[BDEC-1:1]) && pend_bimodal_index[P] == bimodal_index && r_pend_pc[P][BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL] == pc[BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL];
			assign bimodal_pend_prediction_push_valid[P] = r_pend_valid[P] && (!r_pend_taken[P] || r_pend_dec[P] >= push_pc[BDEC-1:1]) && pend_bimodal_index[P] == bimodal_push_index && r_pend_pc[P][BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL] == push_pc[BDEC+NUM_BIMODAL+VTAG_SIZE-1:BDEC+NUM_BIMODAL];

			assign combined_pend_prediction_valid[P] = r_pend_valid[P] && pend_combined_index[P] == combined_index;
			assign combined_pend_prediction_push_valid[P] = r_pend_valid[P] && pend_combined_index[P] == combined_push_index;

			assign pend_dest_hit[P] = r_pend_valid[P] && r_pend_pc[P] == pc;

			always @(posedge clk) begin
				if (reset||clear) begin
					r_pend_valid[P] <= 0;
				end else
				if (trap_shootdown && r_pend_valid[P] && !(r_pend_committed[P]||commit_token[P])) begin	// flush unwanted
					r_pend_valid[P] <= 0;
				end else
				if (commit_shootdown && r_pend_valid[P] && ((r_pend_in > P && P > commit_shootdown_token) || (r_pend_in < commit_shootdown_token && (P > commit_shootdown_token || r_pend_in > P)))) begin	// flush unwanted
					r_pend_valid[P] <= 0;
				end else
				if (push_enable && !commit_shootdown && r_pend_in == P && (r_pend_in != r_pend_out || !r_pend_valid[r_pend_out])) begin
					r_pend_valid[P] <= 1;
					r_pend_committed[P] <= push_noissue;
					r_pend_pc[P] <= push_pc;
					r_pend_dest[P] <= push_dest;
					r_pend_dec[P] <= push_branch_decoder;
					r_pend_taken[P] <= push_taken;
					r_pend_mode[P] <= r_mode;
				end else 
				if (r_pend_out == P && r_pend_valid[P] && r_pend_committed[P]) begin	// done
					r_pend_valid[P] <= 0;
				end else begin
					if (r_pend_valid[P] && commit_token[P]) 
						r_pend_committed[P] <= 1;
					if (commit_shootdown && commit_shootdown_token == P) begin   // this branch was mispredicted
						r_pend_dest[P] <= commit_shootdown_dest;
						r_pend_taken[P] <= commit_shootdown_taken;
						r_pend_dec[P] <= commit_shootdown_dec;
					end
				end
				if (!r_pend_valid[P]) begin
					r_pend_bimodal_prev[P] <= bimodal_push_prediction;
					r_pend_bimodal_pred[P] <= (push_taken? (bimodal_push_prediction[1]? 2'b11:bimodal_push_prediction+2'b1) : (!bimodal_push_prediction[1]? 2'b00:bimodal_push_prediction-2'b1));
					r_pend_combined_prev[P] <= combined_push_prediction;
					if (global_push_prediction[1]&&!bimodal_push_prediction[1]&&combined_push_prediction[1]&&combined_push_prediction<3) begin
						r_pend_combined_pred[P] <= combined_push_prediction+1;
					end else
					if (!global_prediction[1]&&bimodal_push_prediction[1]&&!combined_push_prediction[1]&&combined_push_prediction>0) begin
						r_pend_combined_pred[P] <= combined_push_prediction-1;
					end else begin
						r_pend_combined_pred[P] <= combined_push_prediction;
					end
					r_pend_global_prev[P] <= global_push_prediction;
					r_pend_global_pred[P] <= (push_taken? (global_push_prediction[1]? 2'b11:global_push_prediction+2'b1) : (!global_push_prediction[1]? 2'b00:global_push_prediction-2'b1));
					r_pend_global_history[P] <= {global_history[GLOBAL_HISTORY-2:0],push_taken};
				end else 
				if (commit_shootdown && commit_shootdown_token == P) begin   // this branch was mispredicted
					r_pend_dest[P] <= commit_shootdown_dest;
					r_pend_global_history[P] <= {r_pend_global_history[P][GLOBAL_HISTORY-1:1],commit_shootdown_taken};
					if (!r_pend_taken[P] && commit_shootdown_taken) begin	// if branch should have been taken
						r_pend_global_pred[P] <= r_pend_global_prev[P]==2'b11 ? 2'b11 : r_pend_global_prev[P]+1;
						r_pend_bimodal_pred[P] <= r_pend_bimodal_prev[P]==2'b11 ? 2'b11: r_pend_bimodal_prev[P]+1;
						case ({r_pend_bimodal_prev[P][1],r_pend_global_prev[P][1]}) // synthesis full_case parallel_case
						2'b10:	if (r_pend_combined_prev[P]!=2'b11)
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]+1;
						2'b01: if (r_pend_combined_prev[P]!=2'b00) 
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]-1;
						default:;
						endcase
					end else
					if (r_pend_taken[P] && !commit_shootdown_taken) begin
						r_pend_global_pred[P] <= r_pend_global_prev[P]==2'b00 ? 2'b00: r_pend_global_prev[P]-1;
						r_pend_bimodal_pred[P] <= r_pend_bimodal_prev[P]==2'b00 ? 2'b00: r_pend_bimodal_prev[P]-1;
						case ({r_pend_bimodal_prev[P][1],r_pend_global_prev[P][1]}) // synthesis full_case parallel_case
						2'b10: if (r_pend_combined_prev[P]!=2'b11) 
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]+1;
						2'b01: if (r_pend_combined_prev[P]!=2'b00) 
									r_pend_combined_pred[P] <= r_pend_combined_prev[P]-1;
						default:;
						endcase
					end
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

