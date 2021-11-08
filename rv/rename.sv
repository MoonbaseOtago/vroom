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

module rename_ctrl(
		input		clk, 
		input		reset,
		input   [2*NDEC-1:0]will_be_valid,
		input	[LNCOMMIT:0]current_available,
		input			    commit_br_enable,
		input				commit_trap_br_enable,
		input				commit_int_force_fetch,

		output				force_fetch_rename,

		input   [RV-1:1]pc_dest,
		output   [RV-1:1]pc_dest_out,

		output  [LNCOMMIT-1:0]count_out,
		output  [3:0]rename_count_out,
		output 	    proceed,
		output		rename_reloading,
		output	    rename_stall);
        parameter CNTRL_SIZE=7;
        parameter NDEC = 4; // number of decode stages
        parameter NHART=1;      
        parameter LNHART=0;      
        parameter BDEC= 4;
		parameter RA=5;
		parameter RV=64;
		parameter HART=0;
		parameter NCOMMIT = 32; // number of commit registers 
        parameter LNCOMMIT = 5; // number of bits to encode that
		parameter CALL_STACK_SIZE=32;
		parameter NUM_PENDING=32;
		parameter NUM_PENDING_RET=8;

	reg [LNCOMMIT-1:0]c_count_out;
	assign proceed = !rename_stall && c_count_out > 0;
	assign count_out = (reset?0:commit_int_force_fetch?2:rename_reloading|| c_count_out > current_available?0:c_count_out);
	assign rename_stall = !reset && c_count_out > current_available;
	wire stall_in = commit_br_enable|commit_trap_br_enable|r_force_fetch_rename;
	reg [1:0]r_stall;
	reg [3:0]r_count_out;
	always @(posedge clk)
		r_count_out <= (reset?0:count_out);
	assign rename_count_out = r_count_out;	// 1 clock later for accounting


	reg		r_force_fetch_rename;
	always @(posedge clk)
		r_force_fetch_rename <= commit_int_force_fetch;
	assign force_fetch_rename = r_force_fetch_rename;

	generate
		if (NDEC==2) begin
`include "mk8_4.inc"
		end else
		if (NDEC==4) begin
`include "mk8_8.inc"
		end else
		if (NDEC==8) begin
`include "mk8_16.inc"
		end 
	endgenerate

	assign rename_reloading = r_stall!=0;
    always @(posedge clk)
		r_stall <= (reset||commit_int_force_fetch?0:{r_stall[0], stall_in});

	reg   [RV-1:1]r_pc_dest_out;
	assign  pc_dest_out = r_pc_dest_out;

	always @(posedge clk)
	if (!rename_stall) begin
		r_pc_dest_out <= pc_dest;
	end

endmodule

module scoreboard(
		input			clk, 
		input			reset,

		input			rename_valid,
		input [LNCOMMIT-1:0]rename_result,


		input [LNCOMMIT-1:0]current_end,
		input [NCOMMIT-1:0] commit_reg,
		input [NCOMMIT-1:0] commit_match,
		input				rename_reloading,
		input				rename_stall,

		output [RA-1:0]scoreboard_latest_rename);
        parameter CNTRL_SIZE=7;
        parameter NDEC = 4; // number of decode stages
        parameter ADDR=0;
        parameter NHART=1;
        parameter LNHART=0;
		parameter HART=0;
		parameter RA=6;
		parameter RV=64;
        parameter BDEC= 4;
		parameter NCOMMIT = 32; // number of commit registers 
        parameter LNCOMMIT = 5; // number of bits to encode that


	wire	[31:1]c_stall;
	wire 	      stall=|c_stall;


	reg [RA-1:0]r_reg;
	reg [RA-1:0]c_reg;

//
//	we have 2 pointers in and out that are inclusive and a flag (not_empty)
//	for each real register (1-31) we have a vector of flags [0:NCOMMIT-1] of the commit stations
//	that say that that commit station generates that register as an output
//
//	In any clock we can:
//		a) either:
//			1) add D new entries to out (dispatch), or
//			2) delete E entries from out (miss prediction/exceptio)
//		b) remove C entries from in (commit)
//
//	So - how do we figure out the latest version of real register X? (pref without creating 31
//	barrel shifters
//
//	1) here we remember the last one put in and where it is:
//		a) when therte's an exception or mis predict there's going to be a 3 clock pipe bubble
//			(fetch, decode rename) - that gives us enough time for a multi clock
//			network to figure it out
//		b) when there's a commit we simply clear it, when there's a commit for it we just clear 
//		   it's valid bit so we start referencing the real register
//	   
//
//

	reg [LNCOMMIT-1:0]na;
	reg         na_valid;
	
	wire [RA-1:0]current;
	wire [RA-1:0]na_v;

	assign scoreboard_latest_rename = r_reg;
					
	generate
		wire [4:0]rr = ADDR;
		wire [RA-1:0]rn_result;
		if (LNCOMMIT < 5) begin
			wire [5-LNCOMMIT-1:0]fill = 0;
			assign current = {1'b0, rr};
			assign na_v = {1'b1, fill, na};
			assign rn_result = {1'b1, fill, rename_result};
		end else
		if (LNCOMMIT == 5) begin
			assign current = {1'b0, rr};
			assign na_v = {1'b1, na};
			assign rn_result = {1'b1, rename_result};
		end else begin
			wire [LNCOMMIT-5-1:0]fill = 0;
			assign current = {1'b0, fill, rr};
			assign na_v = {1'b1, na};
			assign rn_result = {1'b1, rename_result};
		end
	
		always @(*) begin 
			if (reset) begin 
				c_reg = current;
			end else
			if (!rename_reloading&rename_valid&!rename_stall) begin
				c_reg = rn_result;
			end else
			if (r_reg[RA-1] && commit_reg[r_reg[LNCOMMIT-1:0]]) begin
				c_reg = current;
			end else
			if (rename_reloading) begin
				if (na_valid) begin
					c_reg = na_v;
				end else begin
					c_reg = current;
				end
			end else begin
				c_reg = r_reg;
			end
		end

		always @(posedge clk) 
			r_reg <= c_reg;


		if (NCOMMIT == 16) begin
`include "mk4_16.inc"
		end else
		if (NCOMMIT == 32) begin
`include "mk4_32.inc"
		end else
		if (NCOMMIT == 64) begin
`include "mk4_64.inc"
		end 
	endgenerate
endmodule
		
module rename(
		input			clk, 
		input			reset,
		input			rv32,

		input	 [2*NDEC-1:0]valid,
		input    [ 4: 0]rs1,
		input    [ 4: 0]rs2,
		input    [ 4: 0]rs3,
		input    [ 4: 0]rd,
		input    [31: 0]immed,
		input           needs_rs2,
		input           needs_rs3,
		input			rd_fp,
		input			rs1_fp,
		input			rs2_fp,
		input			rs3_fp,
		input           makes_rd,
		input [CNTRL_SIZE-1:0]control,
		input  [3:0]unit_type,
		input   [RV-1:1]pc,
		input    [LNCOMMIT-1: 0]next_start,
		input	[RA-1: 0]renamed_rs1,
		input	[RA-1: 0]renamed_rs2,
		input	[RA-1: 0]renamed_rs3,
		input			 local1,
		input			 local2,
		input			 local3,
		input [$clog2(NUM_PENDING)-1:0]branch_token,
		input [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret,

		input			    commit_br_enable,
		input				commit_trap_br_enable,
		input				rename_reloading,
		input				rename_stall,
		input	[NCOMMIT-1:0]commit_done,
		input				commit_int_force_fetch,
		input[LNCOMMIT-1: 0]commit_trap_br_addr,
		input       [RV-1:1]commit_trap_br,

		output	  [2*NDEC-1:0]sel_out,
		output    [4: 0]next_rd,
		output    [LNCOMMIT-1: 0]next_map_rd,
		output			   next_makes_rd,
`ifdef FP
		output			   next_rd_fp,
`endif
		output    [RA-1: 0]rs1_out,
		output    [RA-1: 0]rs2_out,
		output    [RA-1: 0]rs3_out,
		output    [ 4: 0]real_rs1_out,
		output    [ 4: 0]real_rs2_out,
		output    [ 4: 0]real_rs3_out,
		output    [LNCOMMIT-1: 0]rd_out,
		output    [  4: 0]rd_real_out,
		output    [31: 0]immed_out,
		output           needs_rs2_out,
		output           needs_rs3_out,
		output           makes_rd_out,
		output			 rd_fp_out,
		output			 rs1_fp_out,
		output			 rs2_fp_out,
		output			 rs3_fp_out,
		output [CNTRL_SIZE-1:0]control_out,
		output  [3:0]unit_type_out,
		output   [RV-1:1]pc_out,
		output 		will_be_valid,
		output [$clog2(NUM_PENDING)-1:0]branch_token_out,
		output [$clog2(NUM_PENDING_RET)-1:0]branch_token_ret_out,
		output 		valid_out
		);

	parameter CNTRL_SIZE=7;
	parameter NDEC = 4; // number of decode stages
	parameter ADDR=0;
	parameter HART=0;
	parameter NHART=1;
	parameter LNHART=0;
	parameter BDEC = 4;
	parameter RA=5;
	parameter RV=64;
	parameter NCOMMIT=5;
	parameter LNCOMMIT=5;
	parameter NUM_PENDING=32;
	parameter NUM_PENDING_RET=8;


	reg    [   4: 0]r_real_rs1_out, c_real_rs1_out;
	reg    [   4: 0]r_real_rs2_out, c_real_rs2_out;
	reg    [   4: 0]r_real_rs3_out, c_real_rs3_out;
	assign real_rs1_out = r_real_rs1_out;
	assign real_rs2_out = r_real_rs2_out;
	assign real_rs3_out = r_real_rs3_out;
	reg    [RA-1: 0]r_rs1_out;
	reg    [RA-1: 0]r_rs2_out;
	reg    [RA-1: 0]r_rs3_out;
	reg    [LNCOMMIT-1: 0]r_rd_out;
	reg    [ 4: 0]r_rd_real_out;
	reg    [31: 0]r_immed_out;
	reg [$clog2(NUM_PENDING)-1:0]r_branch_token_out;
	reg [$clog2(NUM_PENDING_RET)-1:0]r_branch_token_ret_out;
	reg           r_needs_rs2_out;
	reg           r_needs_rs3_out;
	reg           r_makes_rd_out;
	reg			  r_rd_fp_out;
	reg			  r_rs1_fp_out;
	reg			  r_rs2_fp_out;
	reg			  r_rs3_fp_out;
	reg [CNTRL_SIZE-1:0]r_control_out;
	reg  [3:0]r_unit_type_out;
	reg   [RV-1:1]r_pc_out;
	reg		r_valid_out;
	assign  rs1_out = r_rs1_out;
	assign  rs2_out = r_rs2_out;
	assign  rs3_out = r_rs3_out;
	assign  rd_out = r_rd_out;
	assign  immed_out = r_immed_out;
	assign  needs_rs2_out = r_needs_rs2_out;
	assign  needs_rs3_out = r_needs_rs3_out;
	assign	rd_fp_out = r_rd_fp_out;
	assign	rs1_fp_out = r_rs1_fp_out;
	assign	rs2_fp_out = r_rs2_fp_out;
	assign	rs3_fp_out = r_rs3_fp_out;
	assign  makes_rd_out = r_makes_rd_out;
	assign  control_out = r_control_out;
	assign  unit_type_out = r_unit_type_out;
	assign  pc_out = r_pc_out;
	assign	valid_out = r_valid_out&!(rename_stall|rename_reloading);
	assign rd_real_out = r_rd_real_out;

	assign next_map_rd = next_start+ADDR;
	assign next_rd = rd;
	assign next_makes_rd = makes_rd&c_valid_out;
`ifdef FP
	assign next_rd_fp = rd_fp&c_valid_out;
`endif
	assign branch_token_out =  r_branch_token_out;
	assign branch_token_ret_out = r_branch_token_ret_out;
	
	reg [2*NDEC-1:0]sel;	// 1-hot
	assign sel_out = sel;
	reg      c_valid_out;

	generate
		if (NDEC==2) begin
`include "mkinc4.inc"
		end else 
		if (NDEC==4) begin
`include "mkinc8.inc"
		end else 
		if (NDEC==8) begin
`include "mkinc16.inc"
		end else begin
			// sel = 1'bx;
			// c_valid_out = 1bx;
		end
	endgenerate

	
	//
	//	the above is essentially:
	//	always @(*) begin : nth
	//		integer i, count;
	//		count = 0;
	//		c_valid_out = 0;
	//		sel = 6'bxxxxxx;
	//		for (i = 0; i < 2*NDEC && !c_valid_out ; i=i+1) 
	//		if (valid[i]) begin
	//			if (count == ADDR) begin
	//				c_valid_out = 1;
	//				sel = 1<<i;
	//			end else begin
	//				count = count+1;
	//			end
	//		end
	//	end
	//	wire [4:0]d = rd[sel];
	//	wire [4:0]s1 = rs1[sel];
	//	wire [4:0]s2 = rs2[sel];
	//	wire [4:0]s3 = rs3[sel];
	

	assign will_be_valid = c_valid_out;
	reg r_local1,r_local2,r_local3;

	always @(posedge clk)
	if (commit_int_force_fetch && ADDR <= 1) begin	// vector fetch
		if (ADDR == 0) begin
			r_local1 <= 1;		// ld tmp, (tmp)
			r_local2 <= 1;
			r_local3 <= 1;
			r_real_rs1_out <= 0;
			r_real_rs2_out <= 0;
			r_real_rs3_out <= 0;
			r_rs1_out <= {1'b1, commit_trap_br_addr};
			r_rs2_out <= 0;
			r_rs3_out <= 0;
			r_rd_out <= commit_trap_br_addr+1;
			r_rd_real_out <= 0;
			r_immed_out <= 0;
			r_needs_rs2_out <= 0;
			r_needs_rs3_out <= 0;
			r_makes_rd_out <= 1;
			r_rd_fp_out <= 0;
			r_rs1_fp_out <= 0;
			r_rs2_fp_out <= 0;
			r_rs3_fp_out <= 0;
			r_control_out <= (rv32?{1'bx, 1'b0, 1'b0, 1'b0, 2'b10} :{1'bx, 1'b0, 1'b0, 1'b0, 2'b11});
			r_unit_type_out <= 3;
			r_pc_out <= commit_trap_br;
			r_valid_out <= 1;
			r_branch_token_out <= 0;
			r_branch_token_ret_out <= 0;
		end else begin
			r_local1 <= 1;		// int  #1, tmp
			r_local2 <= 1;
			r_local3 <= 1;
			r_real_rs1_out <= 0;
			r_real_rs2_out <= 0;
			r_real_rs3_out <= 0;
			r_rd_fp_out <= 0;
			r_rs1_fp_out <= 0;
			r_rs2_fp_out <= 0;
			r_rs3_fp_out <= 0;
			r_rs1_out <= {1'b1, commit_trap_br_addr+1'b1};
			r_rs2_out <= 0;
			r_rs3_out <= 0;
			r_rd_out <= commit_trap_br_addr+2;
			r_rd_real_out <= 0;
			r_immed_out <= 0;
			r_needs_rs2_out <= 0;
			r_needs_rs3_out <= 0;
			r_makes_rd_out <= 0;
			r_control_out <= {2'b01, 4'd1};
			r_unit_type_out <= 7;
			r_pc_out <= commit_trap_br;
			r_valid_out <= 1;
			r_branch_token_out <= 0;
			r_branch_token_ret_out <= 0;
		end
	end else
	if (!rename_stall|commit_br_enable|commit_trap_br_enable) begin
		r_local1 <= local1;
		r_local2 <= local2;
		r_local3 <= local3;
		r_real_rs1_out <= rs1;
		r_real_rs2_out <= rs2;
		r_real_rs3_out <= rs3;
		r_rs1_out <= ((renamed_rs1[RA-1] && commit_done[renamed_rs1[LNCOMMIT-1:0]])?rs1:renamed_rs1);
		r_rs2_out <= ((renamed_rs2[RA-1] && commit_done[renamed_rs2[LNCOMMIT-1:0]])?rs2:renamed_rs2);
		r_rs3_out <= ((renamed_rs3[RA-1] && commit_done[renamed_rs3[LNCOMMIT-1:0]])?rs3:renamed_rs3);
		r_rd_out <= next_map_rd;
		r_rd_real_out <= rd;
		r_immed_out <= immed;
		r_needs_rs2_out <= needs_rs2;
		r_needs_rs3_out <= needs_rs3;
		r_makes_rd_out <= makes_rd;
		r_rd_fp_out <= rd_fp;
		r_rs1_fp_out <= rs1_fp;
		r_rs2_fp_out <= rs2_fp;
		r_rs3_fp_out <= rs3_fp;
		r_control_out <= control;
		r_unit_type_out <= unit_type;
		r_pc_out <= pc;
		r_valid_out <= c_valid_out&!(commit_br_enable|commit_trap_br_enable|rename_reloading);
		r_branch_token_out <= branch_token;
		r_branch_token_ret_out <= branch_token_ret;
	end else begin
		if (!r_local1 && r_rs1_out[RA-1] && commit_done[r_rs1_out[LNCOMMIT-1:0]])
			r_rs1_out <= r_real_rs1_out;
		if (!r_local2 && r_rs2_out[RA-1] && commit_done[r_rs2_out[LNCOMMIT-1:0]])
			r_rs2_out <= r_real_rs2_out;
		if (!r_local3 && r_rs3_out[RA-1] && commit_done[r_rs3_out[LNCOMMIT-1:0]])
			r_rs3_out <= r_real_rs3_out;
	end

`ifdef AWS_DEBUG
`ifdef NOTDEF
	ila_rename ila_rn(.clk(clk),
		.reset(reset),
		.valid(valid_out),
		.pc({pc_out[31:1],1'b0}),
		.unit_type(unit_type_out),
		.rs1(rs1_out),
		.rs2(rs2_out));
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
