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

module decode_partial(input clk,
        input reset,

        input rename_stall,
		input valid_fetch,

		input		partial_nuke,
		input		partial_nuke_now,

		input		save_partial,
		input [15:0]partial_ins,
		input [VA_SZ-1:BDEC]decode_pc,
		input		partial_start,

		output [15:0]last_partial,
		output		 partial_valid_out,
		output		 partial_valid_out_int,
		output		 partial_start_out,
		output [VA_SZ-1:1] partial_pc);

    parameter NDEC = 4; // number of decode stages
    parameter NHART=1;
    parameter LNHART=0;
    parameter BDEC=4;
    parameter RV=64;
    parameter VA_SZ=48;

	reg [15:0]r_ins;
	assign last_partial = r_ins;

	reg [VA_SZ-1:BDEC]r_pc;
	wire [BDEC-1:1]nd = (NDEC-1+NDEC);
	assign partial_pc = {r_pc, nd};

	reg r_valid, r_valid_int, r_start;
	assign partial_valid_out=r_valid&!partial_nuke_now;
	assign partial_valid_out_int = r_valid;
	assign partial_start_out = r_start;

	always @(posedge clk)
	if (!rename_stall && valid_fetch) begin
		r_ins <= partial_ins;
		r_pc <= decode_pc;
		r_start <= partial_start;
	end

	always @(posedge clk)
	if (reset || partial_nuke ) begin
		r_valid <= 0;
	end else
	if (!rename_stall && valid_fetch)
		r_valid <= save_partial;
		
endmodule


module decode_trap(input reset, input clk,
			input [(2*NDEC)-1:0]trap,
			input  [(32*NDEC)-1:0]trap_ins_in,
			output [31:0]trap_ins_out
		);
	parameter NDEC = 4;

	reg [31:0]r_trap_ins;
	assign trap_ins_out = r_trap_ins;

	generate
		if (NDEC == 4) begin
			always @(posedge clk) begin
				if (reset) begin
					r_trap_ins <= 0;
				end else
				casez (trap)	// synthesis full_case parallel_case
				8'b????_??1?,
				8'b????_???1:	r_trap_ins <= trap_ins_in[31:0];
				8'b????_1?00,
				8'b????_?100:	r_trap_ins <= trap_ins_in[63:32];
				8'b??1?_0000,
				8'b???1_0000:	r_trap_ins <= trap_ins_in[95:64];
				8'b1?00_0000,
				8'b?100_0000:	r_trap_ins <= trap_ins_in[127:96];
				8'b0000_0000:	;
				endcase
			end
		end
	endgenerate

endmodule
module decode(input clk,
		input reset,
`ifdef AWS_DEBUG
		input xxtrig,
`endif
		input rename_stall,
		input [3:0]cpu_mode,  // 0 user, 1 sup, 3 machine
		input [5:0]timer_prot,
		input [31:0]ins,
		input [VA_SZ-1:1]pc,

		input	[15:0]partial_ins_in,
		output	[15:0]partial_ins_out,
		input [VA_SZ-1:1]partial_pc_in,
		output[VA_SZ-1:1]partial_pc_out,
		input		  partial_valid_in,
		input		  partial_valid_int_in,
		output		  partial_valid_out,
		input		  pop_available,

		input	valid,
		input	valid_in,
		input	issue_interrupt,
		input	issue_fetch_trap,
		input	fetch_trap_type,
		input	fetch_branched,
	
		input	rv32,
		input	tvm,
		input	tsr,
		input	hyper,

		output	jumping_stall,	// stall PC until woken

		output  valid_next,

		input	partial_nuke,

		//
		//	default		predict
		//	  1			-			use default prediction
		//	  0			0			predict no branch
		//	  0			1			predict branch			
		//
		input	br_default,

		input   br_predict_1,	
		output	valid_out_1,
		output [ 4:0]rs1_1,
		output [ 4:0]rs2_1,
		output [ 4:0]rs3_1,
		output [ 4:0]rd_1,
		output		 rs1_fp_1,
		output		 rs2_fp_1,
		output		 rs3_fp_1,
		output		 rd_fp_1,
		output [31:0]immed_1,
		output		start_1,
		output		short_1,
		output		makes_rd_1,
		output		needs_rs2_1,
		output		needs_rs3_1,
		output [CNTRL_SIZE-1:0]control_1,
		output [VA_SZ-1:1]pc_1,
		output  [3:0]unit_type_1,	// 0 ALU, 1 shift, 2 mul/div, 3 ld, 4 st, 5 fp, 6 jmp, 7 trap
		output	     jumping_rel_jmp_1,
		output	     jumping_rel_jmp_end_1,
		output [RV-1:1]pc_br_fetch_1,
		output		   jumping_term_1,
		output		   jumping_issue_1,
		output		   jumping_push_1,
		output		   jumping_pop_1,
		output		   jumping_inc2_1,
		output		   has_jmp_1,
		output		   has_jmp_back_1,

		input   br_predict_2,
		output	valid_out_2,
		output [ 4:0]rs1_2,
		output [ 4:0]rs2_2,
		output [ 4:0]rs3_2,
		output [ 4:0]rd_2,
		output		 rs1_fp_2,
		output		 rs2_fp_2,
		output		 rs3_fp_2,
		output		 rd_fp_2,
		output [31:0]immed_2,
		output		start_2,
		output		short_2,
		output		makes_rd_2,
		output		needs_rs2_2,
		output		needs_rs3_2,
		output [CNTRL_SIZE-1:0]control_2,
		output [VA_SZ-1:1]pc_2,
		output  [3:0]unit_type_2,	// 0 ALU, 1 shift, 2 mul/div, 3 ld, 4 st, 5 fp, 6 jmp, 7 trap
		output	     jumping_rel_jmp_2,
		output	     jumping_rel_jmp_end_2,
		output [RV-1:1]pc_br_fetch_2,
		output		   jumping_term_2,
		output		   jumping_issue_2,
		output		   jumping_push_2,
		output		   jumping_pop_2,
		output		   jumping_inc2_2,
		output		   has_jmp_2,
		output		   has_jmp_back_2,

		output [1:0]trap_out,
		output [31:0]trap_ins
		);

    parameter VA_SZ=48;
	parameter RV=64;
	parameter RN=7;
	parameter CNTRL_SIZE=7;
	parameter NDEC = 4; // number of decode stages
	parameter ADDR=0;
	parameter NHART=1;
	parameter LNHART=0;
	parameter BDEC=4;

`ifdef B
	wire b = 1;
`else
	wire b = 0;
`endif

	reg [VA_SZ-1:1]r_pc_1;
	wire [VA_SZ-1:1]c_pc_1;
	reg [VA_SZ-1:BDEC]r_pc_2;

	wire [BDEC-1:1]pc_1_lo = {ADDR[BDEC-2:0], 1'b0};
	wire [BDEC-1:1]pc_2_lo = {ADDR[BDEC-2:0], 1'b1};
	assign c_pc_1 = (issue_fetch_trap|(issue_interrupt&fetch_branched)?pc:partial_valid_in||issue_interrupt&partial_valid_int_in?partial_pc_in:{pc[VA_SZ-1:BDEC],pc_1_lo});
	assign pc_1 = r_pc_1;
	assign pc_2 = {r_pc_2,pc_2_lo};
	assign partial_ins_out = ins[31:16];
	assign partial_pc_out = {pc[VA_SZ-1:BDEC],pc_2_lo};
	reg	partial_out;
	assign partial_valid_out = partial_out;


	wire first = pc[BDEC-1:2] == ADDR;
	wire after = pc[BDEC-1:2] < ADDR;

	reg r_start_out_1, r_start_out_2;
	assign start_out_1 = r_start_out_1;
	assign start_out_2 = r_start_out_2;
	reg r_short_out_1, r_short_out_2;
	assign short_out_1 = r_short_out_1;
	assign short_out_2 = r_short_out_2;
	reg r_valid_out_1, r_valid_out_2;
	reg c_valid_out_1, c_valid_out_2;
	assign valid_out_1 = r_valid_out_1;
	assign valid_out_2 = r_valid_out_2;

	reg c_valid_next;
	assign valid_next = c_valid_next;
	always @(*)
	if (partial_valid_in&& (after&valid_in || first&!pc[1])) begin
		if (ins[17:16] == 3) begin
			c_valid_next = (first || after&valid_in) && !c_trap_1 && !c_jumping_term_1;	
		end else begin
			c_valid_next = (first || after&valid_in) && !c_trap_1 && !c_jumping_term_1 &&
							     !c_trap_2 && !c_jumping_term_2;
		end
	end else
	if (first && pc[1]) begin
		c_valid_next = (first || after&valid_in) && (ins[17:16]==3 || (!c_trap_2 && !c_jumping_term_2));
	end else
	if (ins[1:0] == 3) begin
		c_valid_next = (first || after&valid_in) && !c_trap_1 && !c_jumping_term_1;
	end else begin
		c_valid_next = (first || after&valid_in) && !c_trap_1 && !c_jumping_term_1 &&
							     !((ins[17:16] != 3) && (c_trap_2 || c_jumping_term_2));
	end

	
	always @(*) 
	if (reset) begin
		c_valid_out_1 = 0;
		c_valid_out_2 = 0;
		partial_out = 0;
	end else
	if (issue_interrupt|issue_fetch_trap) begin
		c_valid_out_1 = ADDR==0;
		c_valid_out_2 = 0;
		partial_out = 0;
	end else
	if (partial_valid_in && (after&valid_in || first&!pc[1]) ) begin
		c_valid_out_1 = (first ||  after&valid_in);
		c_valid_out_2 = (first ||  after&valid_in) && !c_trap_1 && !c_jumping_term_1 && (ins[17:16]!=3);
		partial_out = (first ||  after&valid_in) && !c_trap_1 && !c_jumping_term_1 && (ins[17:16]==3);
	end else
	if (ins[1:0] == 3 && !(first&pc[1])) begin	// 32-bit ins
		c_valid_out_1 = (first ||  after&valid_in);
		c_valid_out_2 = 0;
		partial_out = 0;
	end else begin
		c_valid_out_1 = ((first&!pc[1]) || (after&valid_in)); 
		c_valid_out_2 = ((first&pc[1]) || ((first || after&valid_in) && !c_trap_1 && !c_jumping_term_1)) && (ins[17:16]!=3);
		partial_out =  ((first&pc[1]) || ((first || after&valid_in) && !c_trap_1 && !c_jumping_term_1)) && (ins[17:16]==3);
	end

	always @(posedge clk)
	if (partial_nuke) begin
		r_valid_out_1 <= 0;
		r_valid_out_2 <= 0;
	end else
	if (!rename_stall) begin
		r_valid_out_1 <= c_valid_out_1&c_issue_1&valid;
		r_valid_out_2 <= c_valid_out_2&c_issue_2&valid;
	end

	reg		c_short_pc;

	reg		c_load_1, c_store_1, c_lf_1, c_lsgn_1, c_amo_1;
	reg	   [1:0]c_lsize_1;
	reg		c_fence_1;
	reg	[2:0]c_fence_type_1;
	reg		c_trap_1, c_break_1, c_env_call_1;
	reg		c_jmp_1, c_cjmp_1, c_has_jmp_1, c_has_jmp_back_1;
	reg		c_br_inv_1;
	reg	 [ 1: 0]c_br_type_1;
	reg		c_add_1, c_addw_1, c_xor_1, c_and_1, c_or_1, c_slt_1, c_sltu_1, c_min_1, c_max_1, c_inv_1, c_sl_1, c_sr_1, c_clz_1, c_in_pc_1;
	reg	 [ 2: 0]c_sh_add_1;
	reg  [ 2: 0]c_bsh_1;
	reg		c_mul_1, c_div_1, c_xmul_1;
	reg	 [ 1: 0]c_sgn_1;
	reg	 [31: 0]c_imm_1;
	reg  [19: 0]c_br_imm_1;
	reg       [4:0]c_rd_1, c_rs1_1, c_rs2_1, c_rs3_1;
	reg		c_csr_1;
	reg		c_csr_immed_1;
	reg		c_csr_write_1;
	reg		c_csr_iret_1;
	reg		c_csr_pipe_1;
	reg	   [1:0]c_csr_type_1, c_csr_iret_type_1;
	reg		  c_fp_1;
	reg		  c_fpm_1;
	reg  [3:0]c_fp_op_1;
	reg  [1:0]c_fp_sz_1;
	reg		  c_sub_push_1;
	reg		  c_sub_pop_1;
	reg		  c_inc2_1;

	reg		c_load_2, c_store_2, c_lf_2, c_lsgn_2;
	reg	   [1:0]c_lsize_2;
	reg		c_jmp_2, c_cjmp_2, c_has_jmp_2, c_has_jmp_back_2;
	reg		c_trap_2, c_break_2;
	reg		c_br_inv_2;
	reg	 [ 1: 0]c_br_type_2;
	reg		c_add_2, c_addw_2, c_xor_2, c_and_2, c_or_2, c_slt_2, c_sltu_2, c_inv_2, c_sl_2, c_sr_2, c_in_pc_2;
	reg		c_mul_2, c_div_2;
	reg	 [ 1: 0]c_sgn_2;
	reg	 [31: 0]c_imm_2;
	reg  [19: 0]c_br_imm_2;
	reg       [4:0]c_rd_2, c_rs1_2, c_rs2_2;
	reg		  c_sub_push_2;
	reg		  c_sub_pop_2;
	reg		  c_inc2_2;

	reg 	 [3:0]c_unit_type_1, c_unit_type_2; // 0 ALU, 1 shift, 2 mul/div, 3 ld, 4 st, 5 fp, 6 jmp, 7 trap
	reg [CNTRL_SIZE-1:0]c_control_1, c_control_2;
	reg		c_jumping_term_1, c_jumping_term_2;		// decode no instructions in this cycle after this one
	reg		c_jumping_stall_1, c_jumping_stall_2;	// stall fetch until this resolves in commit
	reg		c_issue_1, c_issue_2;					// do we need to issue this instruction at all?
	reg		c_issue_jmp_1, c_issue_jmp_2;			// do we need to issue this jmp at all?
	reg		c_jumping_rel_jmp_1, c_jumping_rel_jmp_2;	// tell PC to rel jmp

	assign jumping_stall = ((c_jumping_stall_1&c_valid_out_1)|(c_jumping_stall_2&c_valid_out_2))&valid;
	assign jumping_rel_jmp_1 = (c_jumping_stall_1|c_jumping_rel_jmp_1)&c_valid_out_1&valid;
	assign jumping_rel_jmp_end_1 = !partial_valid_in && ins[1:0]==3 ? 1'b0:
									(c_jumping_stall_1|c_jumping_rel_jmp_1)&c_valid_out_1&valid;
	assign jumping_rel_jmp_2 = (c_jumping_stall_2|c_jumping_rel_jmp_2)&c_valid_out_2&valid;
	assign jumping_rel_jmp_end_2 =	!partial_valid_in && ins[1:0]==3 ? 
									(c_jumping_stall_1|c_jumping_rel_jmp_1)&c_valid_out_1&valid:
									(c_jumping_stall_2|c_jumping_rel_jmp_2)&c_valid_out_2&valid;
	wire x_br_predict_1 = !partial_valid_in && ins[1:0]==3 ? br_predict_2 : br_predict_1;
	wire x_br_predict_2 = !partial_valid_in && ins[1:0]==3 ? 1'b0: br_predict_2;
	assign has_jmp_1 = c_has_jmp_1&c_valid_out_1&valid;
	assign has_jmp_2 = c_has_jmp_2&c_valid_out_2&valid;
	assign has_jmp_back_1 = c_has_jmp_back_1;
	assign has_jmp_back_2 = c_has_jmp_back_2;
	assign jumping_term_1 = c_jumping_term_1;
	assign jumping_issue_1 = c_issue_jmp_1;
	assign jumping_push_1 = c_sub_push_1;
	assign jumping_pop_1 = c_sub_pop_1;
	assign jumping_term_2 = c_jumping_term_2;
	assign jumping_issue_2 = c_issue_jmp_2;
	assign jumping_push_2 = c_sub_push_2;
	assign jumping_pop_2 = c_sub_pop_2;
	assign jumping_inc2_1 = c_inc2_1;
	assign jumping_inc2_2 = c_inc2_2;

	reg [1:0]enc_cpu_mode;
	always @(*)
	casez (cpu_mode)	// synthesis full_case parallel_case
	4'b1???: enc_cpu_mode = 3;
	4'b??1?: enc_cpu_mode = 1;
	4'b???1: enc_cpu_mode = 0;
	endcase


	always @(*) begin			// this is pulled out of the always@ below to keep some tools happy
		c_jumping_term_1 = 0;
		c_jumping_term_2 = 0;
		if (!(issue_interrupt|issue_fetch_trap) && !c_trap_1) begin
			if (c_jmp_1) begin
				c_jumping_term_1 = 1;
			end else
			if (c_cjmp_1) begin
				c_jumping_term_1 = br_default?c_br_imm_1[19]:x_br_predict_1;
			end
		end
		if (!(issue_interrupt|issue_fetch_trap) && !c_trap_2) begin
			if (c_jmp_2) begin // jmp
				c_jumping_term_2 = 1;				// decode no instructions in this cycle after this one
			end else
			if (c_cjmp_2) begin
				c_jumping_term_2 = br_default?c_br_imm_2[19]:x_br_predict_2;
			end
		end
	end

	always @(*) begin
		c_unit_type_1 = 4'bxxxx;
		c_unit_type_2 = 4'bxxxx;
		c_control_1 = 6'bxxxxxx;
		c_control_2 = 6'bxxxxxx;
		c_jumping_stall_1 = 0;
		c_jumping_stall_2 = 0;
		c_issue_1 = 1;
		c_issue_2 = 1;
		c_issue_jmp_1 = 1'bx;
		c_issue_jmp_2 = 1'bx;
		c_jumping_rel_jmp_1 = 0;
		c_jumping_rel_jmp_2 = 0;
		c_has_jmp_1 = 0;
		c_has_jmp_2 = 0;
		c_has_jmp_back_1 = 0;
		c_has_jmp_back_2 = 0;
		casez ({issue_interrupt|issue_fetch_trap, c_trap_1, c_load_1, c_store_1, c_fence_1, c_jmp_1, c_cjmp_1, c_add_1, c_xor_1, c_and_1, c_or_1, c_slt_1, c_sltu_1, c_min_1, c_max_1, c_clz_1, c_sl_1, c_sr_1, c_mul_1, c_div_1, c_csr_1, c_fp_1}) // synthesis full_case parallel_case
		22'b1?_???_??_?????????_??_??_?_?: begin // interrupt
					c_unit_type_1 = 7;
					if (issue_interrupt) begin
						c_control_1 = {2'b01, 4'd0};
					end else begin
						c_control_1 = {2'b00, fetch_trap_type? 4'd12:4'd1};
					end
					c_jumping_stall_1 = 1;
				end
		22'b01_???_??_?????????_??_??_?_?: begin // trap
					c_unit_type_1 = 7;
					casez ({c_env_call_1, c_break_1}) // synthesis full_case parallel_case
					2'b00:	c_control_1 = {2'b00, 4'd2};
					2'b?1:	c_control_1 = {2'b00, 4'd3};
					2'b1?:	c_control_1 = {2'b00, 4'd8+enc_cpu_mode};
					endcase
					c_jumping_stall_1 = 1;
				end
		22'b00_???_??_?????????_??_??_1_?: begin // csr
					c_unit_type_1 = 7;
					casez ({c_csr_pipe_1, c_csr_iret_1}) // synthesis full_case parallel_case
					2'b1?:begin
							c_control_1 = {1'b1, 1'b1, 1'b1, 1'b0, c_csr_iret_type_1};	// pipe
						  end
					2'b?1:begin
							c_control_1 = {1'b1, 1'b1, 1'b0, 1'b0, c_csr_iret_type_1};	// iret
							c_jumping_stall_1 = 1; //don't speculate past an iret
						  end
					2'b00:begin
							c_control_1 = {1'b1, 1'b0, c_csr_write_1, c_csr_type_1, c_csr_immed_1};
						  end
					endcase
				end
		22'b00_1??_??_?????????_??_??_?_?: begin // load
				c_unit_type_1 = 3;
				c_control_1 = {1'bx, c_amo_1, c_lf_1, c_lsgn_1, c_lsize_1};
			end
		22'b00_?1?_??_?????????_??_??_?_?: begin // store
				c_unit_type_1 = 4;
				c_control_1 = {1'b0, c_amo_1, c_lf_1, 1'bx, c_lsize_1};
			end
		22'b00_??1_??_?????????_??_??_?_?: begin // fence
				c_unit_type_1 = 4;
				c_control_1 = {1'b1, c_rs1_1==0, ~c_needs_rs2_1, c_fence_type_1};
			end
		22'b00_???_1?_?????????_??_??_?_?: begin // jmp
				c_unit_type_1 = 6;
				c_jumping_stall_1 = !c_in_pc_1;			// stall fetch until this resolves in commit
				c_issue_1 = !c_in_pc_1|(c_rd_1 != 0);	// do we need to issue this instruction at all?
				c_issue_jmp_1 = !c_in_pc_1|(c_rd_1 != 0);
				c_jumping_rel_jmp_1 = c_in_pc_1;
				c_control_1 = {(~br_default&x_br_predict_1) || (c_sub_pop_1&pop_available) || c_in_pc_1, c_short_pc, 2'bxx, c_in_pc_1, 1'b0};
				c_has_jmp_1 = 1;
			end
		22'b00_???_?1_?????????_??_??_?_?: begin // cjmp
				c_unit_type_1 = 6;
				c_issue_1 = 1;	// do we need to issue this instruction at all?
				c_jumping_rel_jmp_1 = c_jumping_term_1;
				c_jumping_stall_1 = 0;
				c_control_1 = {c_jumping_term_1, c_short_pc, c_br_inv_1, c_br_type_1, 1'b1};
				c_has_jmp_1 = 1;
				c_has_jmp_back_1 = c_br_imm_1[19];
				c_issue_jmp_1 = 1;
			end
		22'b00_???_??_1????????_??_??_?_?,
		22'b00_???_??_?1???????_??_??_?_?,
		22'b00_???_??_??1??????_??_??_?_?,
		22'b00_???_??_???1?????_??_??_?_?,
		22'b00_???_??_????1????_??_??_?_?,
		22'b00_???_??_?????1???_??_??_?_?,
		22'b00_???_??_??????1??_??_??_?_?,
		22'b00_???_??_???????1?_??_??_?_?,
		22'b00_???_??_????????1_??_??_?_?: begin // alu
				c_unit_type_1 = 0;
				casez ({c_add_1, c_xor_1, c_and_1, c_or_1, c_slt_1, c_sltu_1, c_min_1, c_max_1, c_clz_1}) // synthesis full_case parallel_case
				9'b1????????: case (c_sh_add_1) // synthesis full_case parallel_case
							 0: c_control_1 = {c_in_pc_1, c_addw_1, c_inv_1,3'h0};	// add	
							 1: c_control_1 = {1'b1, c_addw_1, 1'b0,3'h1};	// sh1add1	
							 2: c_control_1 = {1'b1, c_addw_1, 1'b0,3'h2};	// sh1add2
							 3: c_control_1 = {1'b1, c_addw_1, 1'b0,3'h3};	// sh1add3	
							 4: c_control_1 = {1'b1, c_addw_1, c_inv_1,3'h4};	// add/subwu	
							 default: c_control_1 = 7'bx;
							 endcase
				9'b?1???????: c_control_1 = {2'b0x, c_inv_1, 3'h1};	// xor
				9'b??1??????: c_control_1 = {2'b0x, c_inv_1, 3'h2};	// and
				9'b???1?????: c_control_1 = {2'b0x, c_inv_1, 3'h3};	// or
				9'b????1????: c_control_1 = {2'b00, 1'b1, 3'h4};	// slt
				9'b?????1???: c_control_1 = {2'b00, 1'b1, 3'h5};	// sltu
				9'b??????1??: c_control_1 = {2'b00, c_inv_1, 3'h6};	// min/minu
				9'b???????1?: c_control_1 = {2'b00, c_inv_1, 3'h7};	// max/maxu
				9'b????????1: c_control_1 = {2'b10, 1'b0, 3'h5};	// clz/etc
				endcase
				c_issue_1 = c_makes_rd_1;
			end
		22'b00_???_??_?????????_1?_??_?_?: begin // sl
				c_unit_type_1 = 1;
				c_control_1 = {c_bsh_1, c_addw_1, c_inv_1, 1'b0};
				c_issue_1 = c_makes_rd_1;
			end
		22'b00_???_??_?????????_?1_??_?_?: begin // sr
				c_unit_type_1 = 1;
				c_control_1 = {c_bsh_1, c_addw_1, c_inv_1, 1'b1};
				c_issue_1 = c_makes_rd_1;
			end
		22'b00_???_??_?????????_??_?1_?_?,
		22'b00_???_??_?????????_??_1?_?_?: begin // mul/div
				c_unit_type_1 = 2;
				c_control_1 = {c_xmul_1, c_addw_1, c_inv_1,c_sgn_1, c_mul_1};
				c_issue_1 = c_makes_rd_1;
			end
		22'b00_???_??_?????????_??_??_?_1: begin // fp
				c_unit_type_1 = 5;
				c_control_1 = {c_fp_sz_1[0], c_fpm_1, c_fp_op_1};
				c_issue_1 = 1;
			end
		endcase
		casez ({c_trap_2, c_load_2, c_store_2, c_jmp_2, c_cjmp_2, c_add_2, c_xor_2, c_and_2, c_or_2, c_slt_2, c_sltu_2, c_sl_2, c_sr_2}) // synthesis full_case parallel_case
		13'b1_??_??_??????_??: begin // trap
						c_unit_type_2 = 7;
						case ({1'b0, c_break_2}) // synthesis full_case parallel_case
						2'b00:	c_control_2 = {2'b00, 4'd2};
						2'b01:	c_control_2 = {2'b00, 4'd3};
						default: c_control_2 = 6'bx;
						endcase
						c_jumping_stall_2 = 1;
				   end
		13'b0_1?_??_??????_??: begin // load
				c_unit_type_2 = 3;
				c_control_2 = {1'bx, 1'b0, c_lf_2, c_lsgn_2, c_lsize_2};
			end
		13'b0_?1_??_??????_??: begin // store
				c_unit_type_2 = 4;
				c_control_2 = {1'b0, 1'b0, c_lf_2, 1'bx, c_lsize_2};
			end
		13'b0_??_1?_??????_??: begin // jmp
				c_unit_type_2 = 6;
				c_jumping_stall_2 = !c_in_pc_2;	// stall fetch until this resolves in commit
				c_issue_2 = !c_in_pc_2|(c_rd_2 != 0);	// do we need to issue this instruction at all?
				c_issue_jmp_2 = !c_in_pc_2|(c_rd_2 != 0);
				c_jumping_rel_jmp_2 = c_in_pc_2;
				c_control_2 = {(~br_default&x_br_predict_2) || (c_sub_pop_2&pop_available) || c_in_pc_2, 1'b1, 2'bxx, c_in_pc_2, 1'b0};
				c_has_jmp_2 = 1;
			end
		13'b0_??_?1_??????_??: begin // cjmp
				c_unit_type_2 = 6;
				c_issue_2 = 1;	// do we need to issue this instruction at all?
				c_issue_jmp_2 = 1;
				c_jumping_rel_jmp_2 = c_jumping_term_2;
				c_jumping_stall_2 = 0;
				c_control_2 = {c_jumping_term_2, 1'b1, c_br_inv_2, c_br_type_2, 1'b1};
				c_has_jmp_2 = 1;
				c_has_jmp_back_2 = c_br_imm_2[19];
			end
		13'b0_??_??_1?????_??,
		13'b0_??_??_?1????_??,
		13'b0_??_??_??1???_??,
		13'b0_??_??_???1??_??,
		13'b0_??_??_????1?_??,
		13'b0_??_??_?????1_??: begin // alu
				c_unit_type_2 = 0;
				casez ({c_add_2, c_xor_2, c_and_2, c_or_2, c_slt_2, c_sltu_2}) // synthesis full_case parallel_case
				6'b1?????: c_control_2 = {c_in_pc_2, c_addw_2, c_inv_2,3'h0};	// add
				6'b?1????: c_control_2 = {2'b0x, c_inv_2, 3'h1};	// xor
				6'b??1???: c_control_2 = {2'b0x, c_inv_2, 3'h2};	// and
				6'b???1??: c_control_2 = {2'b0x, c_inv_2, 3'h3};	// or
				6'b????1?: c_control_2 = {2'b00, 1'b1, 3'h4};	// slt
				6'b?????1: c_control_2 = {2'b00, 1'b1, 3'h5};	// sltu
				endcase
				c_issue_2 = c_makes_rd_2;
			end
		13'b0_??_??_??????_1?: begin // sl
				c_unit_type_2 = 1;
				c_control_2 = {3'b000, c_addw_2, 1'bx, 1'b0};
				c_issue_2 = c_makes_rd_2;
			end
		13'b0_??_??_??????_?1: begin // sr
				c_unit_type_2 = 1;
				c_control_2 = {3'b000, c_addw_2,  c_inv_2, 1'b1};
				c_issue_2 = c_makes_rd_2;
			end
		endcase
	end

	reg  [3:0]r_unit_type_1, r_unit_type_2;
	reg [CNTRL_SIZE-1:0]r_control_1, r_control_2;
	assign unit_type_1 = r_unit_type_1;
	assign unit_type_2 = r_unit_type_2;
	assign control_1 = r_control_1;
	assign control_2 = r_control_2;

	reg [4:0]r_rd_1, r_rd_2;
	reg [4:0]r_rs1_1, r_rs1_2;
	reg [4:0]r_rs2_1, r_rs2_2;
	reg [4:0]r_rs3_1;
	assign rd_1 = r_rd_1;
	assign rd_2 = r_rd_2;
	assign rs1_1 = r_rs1_1;
	assign rs1_2 = r_rs1_2;
	assign rs2_1 = r_rs2_1;
	assign rs2_2 = r_rs2_2;
	assign rs3_1 = r_rs3_1;
	assign rs3_2 = 0;

	reg [31:0]r_imm_1, r_imm_2;
	reg	  r_needs_rs2_1, r_needs_rs2_2;
	reg	  c_needs_rs2_1, c_needs_rs2_2;
	reg	  r_needs_rs3_1;
	reg	  c_needs_rs3_1;
	reg	  r_makes_rd_1, r_makes_rd_2;
	reg	  c_makes_rd_1, c_makes_rd_2;
	assign immed_1 = r_imm_1;
	assign immed_2 = r_imm_2;
	assign needs_rs2_1 = r_needs_rs2_1;
	assign needs_rs2_2 = r_needs_rs2_2;
	assign needs_rs3_1 = r_needs_rs3_1;
	assign needs_rs3_2 = 0;
	assign makes_rd_1 = r_makes_rd_1;
	assign makes_rd_2 = r_makes_rd_2;
	reg	  r_rs1_fp_1, r_rs1_fp_2, c_rs1_fp_1, c_rs1_fp_2;
	reg	  r_rs2_fp_1, r_rs2_fp_2, c_rs2_fp_1, c_rs2_fp_2;
	reg	  r_rs3_fp_1, r_rs3_fp_2, c_rs3_fp_1, c_rs3_fp_2;
	reg	  r_rd_fp_1, r_rd_fp_2, c_rd_fp_1, c_rd_fp_2;
	assign rs1_fp_1 = r_rs1_fp_1;
	assign rs2_fp_1 = r_rs2_fp_1;
	assign rs3_fp_1 = r_rs3_fp_1;
	assign rd_fp_1 = r_rd_fp_1;
	assign rs1_fp_2 = r_rs1_fp_2;
	assign rs2_fp_2 = r_rs2_fp_2;
	assign rs3_fp_2 = r_rs3_fp_2;
	assign rd_fp_2 = r_rd_fp_2;

	assign pc_br_fetch_1 = {{RV-VA_SZ{c_pc_1[VA_SZ-1]}}, c_pc_1}+{{RV-1-20{c_br_imm_1[19]}}, c_br_imm_1};
	assign pc_br_fetch_2 = {{RV-VA_SZ{pc[VA_SZ-1]}}, pc[VA_SZ-1:BDEC], pc_2_lo}+{{RV-1-20{c_br_imm_2[19]}}, c_br_imm_2};

	always @(posedge clk)
	if (!rename_stall) begin
		r_start_out_1 <= (fetch_branched && first && !pc[1])||(partial_valid_in && ADDR==0);
		r_start_out_2 <= first && pc[1];
		r_short_out_1 <= !partial_valid_in && ins[1:0] != 3;
		r_short_out_2 <= ins[17:16] != 3;
		r_pc_1 <= c_pc_1;
		r_pc_2 <= pc[VA_SZ-1:BDEC];
		r_unit_type_1 <= c_unit_type_1;
		r_unit_type_2 <= c_unit_type_2;
		r_control_1 <= c_control_1;
		r_control_2 <= c_control_2;
		r_rd_1 <= (issue_interrupt|issue_fetch_trap)&&ADDR==0?0:c_rd_1;
		r_rd_2 <= c_rd_2;
		r_rs1_1 <= ((issue_interrupt|issue_fetch_trap)&&ADDR==0)||c_trap_1?5'b0:c_rs1_1;
		r_rs1_2 <= c_trap_2?5'b0:c_rs1_2;
		r_rs2_1 <= c_rs2_1;
		r_rs2_2 <= c_rs2_2;
		r_rs3_1 <= c_rs3_1;
		r_imm_1 <= c_imm_1;
		r_imm_2 <= c_imm_2;
		r_needs_rs2_1 <= (issue_interrupt|issue_fetch_trap)&&ADDR==0?0:c_trap_1?1:c_needs_rs2_1;
		r_needs_rs2_2 <= c_trap_2?1:c_needs_rs2_2;
		r_needs_rs3_1 <= (issue_interrupt|issue_fetch_trap)&&ADDR==0?0:c_trap_1?0:c_needs_rs3_1;
		r_makes_rd_1 <= (issue_interrupt|issue_fetch_trap)&&ADDR==0?1:c_trap_1?0:c_makes_rd_1;
		r_makes_rd_2 <= c_trap_2?0:c_makes_rd_2;
		r_rs1_fp_1 <= c_rs1_fp_1;
		r_rs2_fp_1 <= c_rs2_fp_1;
		r_rs3_fp_1 <= c_rs3_fp_1;
		r_rd_fp_1 <= c_rd_fp_1;
		r_rs1_fp_2 <= c_rs1_fp_2;
		r_rs2_fp_2 <= c_rs2_fp_2;
		r_rs3_fp_2 <= c_rs3_fp_2;
		r_rd_fp_2 <= c_rd_fp_2;
	end

	function badcsr;
		input [11:0]addr;
		input rv32;
		input tvm;
		input hyper;
		begin
			casez (addr) // synthesis full_case parallel_case
			// user mode
			12'b00_00_0000_0000,		//	user status register
			12'b00_00_0000_0001,		//  FP accrued exceptions
			12'b00_00_0000_0010,		//  FP dynamic rounding mode
			12'b00_00_0000_0011,		//  FP dynamic CS reg
			12'b00_00_0000_0100,		//  user interrupt enable register
			12'b00_00_0000_0101,		//  user trap handler base address

			12'b00_00_0100_0000,		//  scratch reg for trap handlers
			12'b00_00_0100_0001,		//  user UEPC
			12'b00_00_0100_0010,		//  user trap cause
			12'b00_00_0100_0011,		//  user bad address or instruction 
			12'b00_00_0100_0100,		//  user interrupt pending
			12'b00_00_0000_0111,		//  user tvt 

			12'b00_00_0100_0101,		//  user nxti
			12'b00_00_0100_0110,		//  user current interrupt levels FIXME address
			12'b00_00_0100_1000,		//  user scratchsw
			12'b00_00_0100_1001,		//  user scratchswl
			12'b00_00_0100_1010,		//  user int threshold  FIXME address
			12'b00_00_0100_1011,		//  user clic base  FIXME address

			12'b11_00_0000_0000,		//  cycle counter for RDCYCLE
			12'b11_00_0000_0001,		//  timer for RDTime
			12'b11_00_0000_0010,		//  instructions retired for RDINSTRET
			12'b11_00_0000_0011,		//  performance monitoring counter
			12'b11_00_0000_01??,		//  performance monitoring counter
			12'b11_00_0000_1???,		//  performance monitoring counter
			12'b11_00_0001_????,		//  performance monitoring counter
			
			12'b10_11_0000_0000,		//  cycle counter for RDCYCLE
			12'b10_11_0000_0001,		//  timer for RDTime
			12'b10_11_0000_0010,		//  instructions retired for RDINSTRET
			12'b10_11_0000_0011,		//  performance monitoring counter
			12'b10_11_0000_01??,		//  performance monitoring counter
			12'b10_11_0000_1???,		//  performance monitoring counter
			12'b10_11_0001_????,		//  performance monitoring counter
			
			// sup mode
			12'b00_01_0000_0000,		//	sup status register
			12'b00_01_0000_0010,		//  sup exception delegation reg
			12'b00_01_0000_0011,		//  sup interrupt delegation reg
			12'b00_01_0000_0100,		//  sup interrupt enable register
			12'b00_01_0000_0101,		//  sup trap handler base address
			12'b00_01_0000_0110,		//  sup counter en
			12'b00_01_0000_0111,		//  sup tvt 

			12'b00_01_0100_0000,		//  scratch reg for sup trap handlers
			12'b00_01_0100_0001,		//  sup SEPC
			12'b00_01_0100_0010,		//  sup trap cause
			12'b00_01_0100_0011,		//  sup bad address or instruction 
			12'b00_01_0100_0100,		//  sup interrupt pending

			12'b00_01_0100_0101,		//  sup nxti
			12'b00_01_0100_0110,		//  sup current interrupt levels FIXME address
			12'b00_01_0100_1000,		//  sup scratchsw
			12'b00_01_0100_1001,		//  sup scratchswl
			12'b00_01_0100_1010,		//  sup int threshold  FIXME address
			12'b00_01_0100_1011,		//  sup clic base  FIXME address


			// machine mode
			12'b00_11_0000_0000,		//	mach status register
			12'b00_11_0000_0001,		//	ISA and extensions
			12'b00_11_0000_0010,		//  mach exception delegation reg
			12'b00_11_0000_0011,		//  mach interrupt delegation reg
			12'b00_11_0000_0100,		//  mach interrupt enable register
			12'b00_11_0000_0101,		//  mach trap handler base address
			12'b00_11_0000_0110,		//  mach counter enable
			12'b00_11_0000_0111,		//  mach tvt 

			12'b00_11_0010_0000,		//  mach counter inhibit 

			12'b00_11_0100_0000,		//  scratch reg for mach trap handlers
			12'b00_11_0100_0001,		//  mach MEPC
			12'b00_11_0100_0010,		//  mach trap cause
			12'b00_11_0100_0011,		//  mach bad address or instruction 
			12'b00_11_0100_0100,		//  mach interrupt pending

			12'b00_11_0100_0101,      // mach nxti
			12'b00_11_0100_0110,      // mach current interrupt levels FIXME address
			12'b00_11_0100_1000,      //  mach scratchsw
			12'b00_11_0100_1001,      //  mach scratchswl
			12'b00_11_0100_1010,      //  mach int threshold  FIXME address
			12'b00_11_0100_1011,      //  mach clic base  FIXME address

			12'b00_11_1010_00??,		//  Physical memory config
			12'b00_11_1011_????,		//  Physical memory protection address reg
`ifdef SIMV
			12'b10_00_1111_0000,	// simulator putchar
			12'b10_00_1111_0001,	// simulator write word
			12'b10_00_1111_0010,	// simulator write dword
			12'b10_00_1111_0011,	// simulator fail
			12'b10_00_1111_0100,	// simulator finish
`endif

			12'b11_11_0001_0001,		//	vendor ID
			12'b11_11_0001_0010,		//	architecture ID
			12'b11_11_0001_0011,		//	implemention ID
			12'b11_11_0001_0100,		//	HART ID

			12'b11_11_1100_0000,		//	CLNT addr 
			12'b11_11_1100_0001:		//	PLIC addr 
						badcsr = 0;
			12'b11_00_1000_0000,		//  cycle counter for RDCYCLE
			12'b11_00_1000_0001,		//  timer for RDTime
			12'b11_00_1000_0010,		//  instructions retired for RDINSTRET
			12'b11_00_1000_0011,		//  performance monitoring counter
			12'b11_00_1000_01??,		//  performance monitoring counter
			12'b11_00_1000_1???,		//  performance monitoring counter
			12'b11_00_1001_????:		//  performance monitoring counter
						badcsr = 0;
			12'b00_11_0001_0000,
			12'b10_11_1000_0000,		//  cycle counter for RDCYCLE
			12'b10_11_1000_0001,		//  timer for RDTime
			12'b10_11_1000_0010,		//  instructions retired for RDINSTRET
			12'b10_11_1000_0011,		//  performance monitoring counter
			12'b10_11_1000_01??,		//  performance monitoring counter
			12'b10_11_1000_1???,		//  performance monitoring counter
			12'b10_11_1001_????:		//  performance monitoring counter
						badcsr = !rv32;
			12'b00_01_1000_0000:		//  sup address translation and protection
						badcsr = tvm;
			// hypervisor
			12'b01_10_0000_0000,        //  hypervisor status register
			12'b01_10_0000_0010,        //  hypervisor exception delegation reg
			12'b01_10_0000_0011,        //  hypervisor interrupt delegation reg
			12'b01_10_0000_0101,        //  hypervisor delta for VS/VU mode timer
			12'b01_10_0000_0110,        //  hypervisor counter enable
			12'b01_10_0001_0101,        //  upper bits of delta for VS/VU mode timer for RV32
			12'b01_10_1000_0000:        //  hypervisor guest address translation/protection
						badcsr = !hyper;

			// virtual supervisor registers
			12'b00_10_0000_0000,        //  virt sup status register
			12'b00_10_0000_0010,        //  virt sup exception delegation reg
			12'b00_10_0000_0011,        //  virt sup interrupt delegation reg
			12'b00_10_0000_0100,        //  virt sup interrupt enable register
			12'b00_10_0000_0101,        //  virt sup trap handler base address
			12'b00_10_0000_0110,        //  virt sup counter enable

			12'b00_10_0100_0000,        //  virt scratch reg for sup trap handlers
			12'b00_10_0100_0001,        //  virt sup SEPC
			12'b00_10_0100_0010,        //  virt sup trap cause
			12'b00_10_0100_0011,        //  virt sup bad address or instruction
			12'b00_10_0100_0100,        //  virt sup interrupt pending

			12'b00_10_0100_1000:        //  virt sup address translation and protection
						badcsr = !hyper;
       
			//
			//  Moonbase specific registers
			//


			12'b01_00_1000_0000,	  // debug
			12'b10_11_1111_1000,      //  pseudo random 
			12'b10_11_1111_1001,      //  misc reset
			12'b10_11_1111_1010:      //  system reset
						badcsr = 0;

			//
			//

			default:	badcsr = 1;
			endcase
		end
	endfunction

	task decode_32;
	input [31:0]ins;
	input       b;
	output [4:0]rd, rs1, rs2, rs3;
	output	trap, brk, env_call;
	output  jmp, cjmp;
	output br_inv;
	output [1:0]br_type;
	output [31:0]imm;
	output [19:0]br_imm;
	output   f_store, f_load, lf, f_amo;
	output  [1:0]lsize;
	output   lsgn;
	output   f_fence;
	output [2:0]fence_type;
	output makes_rd, needs_rs2, needs_rs3, f_add;
	output [2:0]f_sh_add;
	output f_addw, f_xor, f_and, f_or, f_slt, f_sltu, f_min, f_max, f_inv, f_sl, f_sr, f_clz;
	output [2:0]f_bsh;
	output      in_pc; 
	output	f_mul, f_div, f_xmul;
	output  [1:0]f_sgn;
	output 		csr, csr_iret, csr_pipe, csr_immed, csr_write;
	output  [1:0]csr_type, csr_iret_type;
	output		 f_fp;
	output		 f_fpm;
	output  [3:0]f_fp_op;
	output  [1:0]f_fp_sz;
	output sub_push, sub_pop;
	output rs1_fp, rs2_fp, rs3_fp, rd_fp;
	begin
		f_fp = 0;
		f_fpm = 1'bx;
		f_fp_op = 4'bxxxx;
		f_fp_sz = 2'bxx;
		br_imm = 20'bx;
		rd = ins[11:7];
		rs1 = ins[19:15];
		rs2 = ins[24:20];
		rs3 = ins[31:27];
		needs_rs3 = 0;
		trap = 0; 
		brk = 0;
		csr = 0;
		csr_immed = 1'bx; csr_write = 1'bx; csr_type = 2'bx;
		csr_pipe = 1'bx;
		csr_iret = 1'bx;
		csr_iret_type = 2'bx;
		env_call = 0;
		br_inv = 1'bx;
		br_type = 2'bx;
		lsize = 2'bx;
		lsgn = 1'bx;
		f_load = 0;
		in_pc = 0;
		f_store = 0;
		f_amo = 1'bx;
		f_fence = 0;
		fence_type = 3'bx;
		lf = 1'bx;
		makes_rd = 0;
		needs_rs2 = 0;
		f_xmul = 1'bx;
		f_add = 0;
		f_sh_add = 3'bx;
		f_addw = 0;
		f_xor = 0;
		f_and = 0;
		f_or = 0;
		f_slt = 0;
		f_sltu = 0;
		f_min = 0;
		f_max = 0;
		f_inv = 0;
		f_sgn = 2'bx;
		f_mul = 0;
		f_div = 0;
		f_sl = 0;
		f_sr = 0;
		f_bsh = 3'bx;
		f_clz = 0;
		sub_push = 0;
		sub_pop = 0;
		jmp = 0;
		cjmp = 0;
		imm = 32'bx;
		rs1_fp = 0; rs2_fp = 0; rs3_fp = 0; rd_fp = 0;
		case (ins[6:2]) // synthesis full_case parallel_case
		5'b00000:begin	// loads
					imm = {{20{ins[31]}},ins[31:20]};
					f_load = 1;
					f_amo = 0;
					makes_rd = rd != 0;
					case (ins[14:12]) // synthesis full_case parallel_case
					3'b000: begin	// lb
								lsize = 0;
								lsgn = 0;
								lf = 0;
							end
					3'b001: begin	// lh
								lsize = 1;
								lsgn = 0;
								lf = 0;
							end
					3'b010: begin	// lw
								lsize = 2;
								lsgn = 0;
								lf = 0;
							end
					3'b011: begin	// ld
								trap = rv32;
								lsize = 3;
								lsgn = 0;
								lf = 0;
							end
					3'b100: begin	// lbu
								lsize = 0;
								lsgn = 1;
								lf = 0;
							end
					3'b101: begin	// lhu
								lsize = 1;
								lsgn = 1;
								lf = 0;
							end
					3'b110: begin	// lwu
								trap = rv32;
								lsize = 2;
								lsgn = 1;
								lf = 0;
							end
					default: trap = 1;
					endcase
				end
		5'b00001:begin	// fld
					imm = {{20{ins[31]}},ins[31:20]};
					f_load = 1;
					f_amo = 0;
					makes_rd = rd != 0;
					case (ins[14:12])   // synthesis full_case parallel_case
					3'b010: begin		// flw
								lsize = 2;
								lf = 1;
							end
					3'b011: begin		// fld
								lsize = 3;
								lf = 1;
							end
					default: trap = 1;
					endcase
				 end
		5'b00011:begin	// fence etc
					case (ins[14:12]) // synthesis full_case parallel_case
					3'b000:  begin
									f_fence = 1;
									fence_type = 4;
									needs_rs2 = 0;
									makes_rd = 0;
									imm = {ins[31], ins[27:20],23'bx};
							 end
					3'b001:  begin // fence.i
									f_fence = 1;
									fence_type = 3;
									needs_rs2 = 0;
									makes_rd = 0;
									imm = {ins[31],ins[27:20], 23'bx};
							 end
					default: trap = 1;
					endcase
				end
		5'b00100:begin	// immed alu ops
					imm = {{20{ins[31]}},ins[31:20]};
					makes_rd = rd !=0;
					case (ins[14:12]) // synthesis full_case parallel_case
					3'b000: begin	// addi
							f_add = 1;
							f_sh_add = 0;
							f_inv = 0;
						end
					3'b001:if (b && ins[31:26] == 6'b000001) begin	// slliu	FIXME - as specd this collides with shfl
							imm = {26'b0, ins[25:20]};
							f_sl = 1;
							f_inv = 0;
							f_bsh = 4;
						   end else begin	
							trap = {ins[31], ins[28], ins[26]} != 0;
							imm = {26'b0, ins[25:20]};
							casez ({ins[27], ins[29], ins[30]}) // synthesis full_case parallel_case
							3'b000:begin
										f_sl = 1;	// slli
										f_inv = 0;
										f_bsh = 0;
									end
							3'b100:if (b) begin // shfl
										f_bsh = 2;
										f_inv = 1;
										f_sl = 1;	
									end else begin
										trap = 1;
									end
							3'b101:if (b) begin // sbclr
										f_bsh = 3;
										f_inv = 0;
										f_sl = 1;	
									end else begin
										trap = 1;
									end
							3'b110:if (b) begin // sbset
										f_bsh = 3;
										f_inv = 0;
										f_sr = 1;	
									end else begin
										trap = 1;
									end
							3'b111:if (b) begin // sbinv	
										f_bsh = 3;
										f_inv = 1;
										f_sl = 1;	
									end else begin
										trap = 1;
									end
							3'b011:if (b) begin // crc.*	
										f_mul = 1;
										f_xmul = 1;
										f_inv = 1;	// div/rem
										f_sgn = 0;	// signed
										f_addw = 0;
								   end else begin
										trap = 1;
								   end
							default: trap = 1;
							endcase
						end
					3'b010: begin	// slti
							f_slt = 1;
						end
					3'b011: begin	// sltiu
							f_sltu = 1;
						end
					3'b100: begin	// xori
							f_xor = 1;
						end
					3'b101: begin
							imm = {26'b0, ins[25:20]};
							casez (ins[31:26]) // synthesis full_case parallel_case
							6'b0??000:
								    if ((rv32 && ins[25])||(!b && ins[29])) begin
										trap = 1;
									end else begin
										f_sr = 1;
										if (ins[30]) begin
											f_inv = 1;
											// srai
										end else begin
											// srli
											f_inv = 0;
										end
										f_bsh = {2'b0, ins[29]&b};
									end
							6'b000010:
									if (b) begin // unshfli
										f_bsh = 2;
										f_inv = 1;
										f_sr = 1;	
									end else begin
										trap = 1;
									end
							6'b010010:
									if (b) begin // sbexti
										f_bsh = 3;
										f_inv = 1;
										f_sr = 1;	
									end else begin
										trap = 1;
									end
						
							6'b001010:
									if (b) begin // gorci
										f_bsh = 2;
										f_inv = 0;
										f_sl = 1;	
									end else begin
										trap = 1;
									end
							6'b011010:
									if (b) begin // grevi
										f_bsh = 2;
										f_inv = 0;
										f_sr = 1;	
									end else begin
										trap = 1;
									end
							6'b?????1:
									if (b) begin	// fsri
										f_sr = 1;	
										f_inv = 0;
										f_bsh = 7;
										needs_rs3 = 1;
									end else begin
										trap = 1;
									end
							default: trap = 1;
							endcase
						end
					3'b110: begin	// ori
							f_or = 1;
						end
					3'b111: begin	// andi
							f_and = 1;
						end
					endcase
				end
		5'b00101:begin	// auipc
					makes_rd = rd !=0;
					in_pc = 1;
					rs1 = 0;
					f_add = 1;
					f_sh_add = 0;
					f_addw = 0;
					f_inv = 0;
					imm = {ins[31:12], 12'b0};
				end
		5'b00110:begin	// W alu ops immed
					makes_rd = rd !=0;
					needs_rs2 = 0;
					f_addw = 1;
					case (ins[14:12]) // synthesis full_case parallel_case
					3'b000: begin	// addiw
								f_add = 1;
								f_sh_add = 0;
								f_inv = 0;
								trap = rv32;
								imm = {{20{ins[31]}},ins[31:20]};
							end
					3'b001:	begin	
								trap = {ins[31],ins[28], ins[26]} != 0 || !b&ins[29] || !b&ins[27];
								imm = {{27{1'b0}}, ins[24:20]};
								casez ({ins[27], ins[29], ins[30], ins[25]}) // synthesis full_case parallel_case
								4'b0000: begin // sliw
										f_sl = 1;	
										f_bsh = {2'b0, b&ins[29]};
										f_inv = b&ins[29]&ins[30];	
									end
								4'b0110:if (b && ins[24:20] <= 2) begin	// clzw/ctzw/pcntw
											f_clz = 1;
											f_inv = 1'bx;
											// opcode fully encoded in LSBs of immed
										end else begin
											trap = 1;
										end
								4'b1000:begin // shfl
											f_bsh = 2;
											f_inv = 1;
											f_sl = 1;	
										end
								4'b1010: begin // sbclr
										f_bsh = 3;
										f_inv = 0;
										f_sl = 1;	
									end
								4'b1100: begin // sbset
										f_bsh = 3;
										f_inv = 0;
										f_sr = 1;	
									end
								4'b1110: begin // sbinv	
										f_bsh = 3;
										f_inv = 1;
										f_sl = 1;	
									end
								default: trap = 1;
								endcase
							end
					3'b100: if (b) begin	// addiwu
								f_add = 1;
								f_sh_add = 4;
								f_inv = 0;
								trap = rv32;
								imm = {{20{ins[31]}},ins[31:20]};
							end else begin
								trap = 1;
							end
					3'b101:	begin	// sraiw/srliw
								trap = {ins[31],ins[28], ins[26]} != 0 || !b&ins[29] || !b&ins[27];
								imm = {{27{1'b0}}, ins[24:20]};
								casez ({ins[27], ins[29], ins[30], ins[25]}) // synthesis full_case parallel_case
								4'b0??0: begin
										f_sr = 1;	
										f_bsh = {2'b0, b&ins[29]};
										if (ins[30]) begin
											f_inv = 1;
										end else begin
											f_inv = 0;	
										end	
									end
								4'b1000: begin // unshfl
										f_bsh = 2;
										f_inv = 1;
										f_sr = 1;	
									end
								4'b1010: begin // sbext
										f_bsh = 3;
										f_inv = 1;
										f_sr = 1;	
									end
								4'b1100: begin // gorc
										f_bsh = 2;
										f_inv = 0;
										f_sl = 1;	
									end
								4'b1110: begin // grev	
										f_bsh = 2;
										f_inv = 0;
										f_sr = 1;	
									end
								default: trap = 1;
								endcase
							end
					default:trap = 1;
					endcase
				 end
		5'b01100:begin	// alu ops
					makes_rd = rd !=0;
					needs_rs2 = 1;
					case (ins[14:12]) // synthesis full_case parallel_case
					3'b000: begin
							trap = {ins[31],ins[29:26]} != 0;
							case ({ins[30], ins[25]}) // synthesis full_case parallel_case
							2'b01: begin
									// mul
									f_mul = 1;
									f_xmul = 0;
									f_inv = 0;	// lo bits
									f_addw = 0;
								end
							2'b10: begin
									// sub
									f_add = 1;
									f_sh_add = 0;
									f_inv = 1;
								end
							2'b00:	begin
										// add
										f_add = 1;
										f_sh_add = 0;
										f_inv = 0;
									end
							default: trap = 1;
							endcase
						end
					3'b001: begin	
							casez (ins[31:25]) // synthesis full_case parallel_case
							7'b?????10:
									 if (b) begin	// fsl
										f_sl = 1;	
										f_inv = 0;
										f_bsh = 7;
										needs_rs3 = 1;
									 end else begin
										trap = 1;
									 end
							7'b?????11:
									 if (b) begin	// cmix
										f_sl = 1;	
										f_inv = 1;
										f_bsh = 7;
										needs_rs3 = 1;
									 end else begin
										trap = 1;
									 end
							7'b00?0000:
									begin
										f_sl = 1;	// sll
										f_inv = 0;
										if (ins[29]) begin
											if (!b)
												trap = 1;
											f_bsh = 1;	// sol
										end else begin
											f_bsh = 0;
										end
									end
							7'b0000001:
									begin
										// mulh
										f_mul = 1;
										f_xmul = 0;
										f_inv = 1; // hi bits
										f_sgn = 0; // mullh
										f_addw = 0;
									end
							7'b0110000:
									if (b && ins[24:23] == 0) begin
										case (ins[22:20]) // synthesis full_case parallel_case
										0, 1, 2:	// clz/ctz/pcnt
											begin
												f_clz = 1;
												f_inv = 1'bx;
												// opcode fully encoded in LSBs of immed
											end
										3:  begin	// bmatflp
												f_bsh = 1;
												f_sr = 1;
												f_inv = 0;
												if (rv32)
													trap = 1;
											end
										4:  begin	// sext.b
												f_bsh = 1;
												f_sl = 1;
												f_inv = 1;
											end
										5:  begin	// sext.h
												f_bsh = 1;
												f_sr = 1;
												f_inv = 1;
											end
										default: trap = 1;
										endcase
									end else begin
										trap = 1;
									end
							7'b0000101:
									if (b) begin // clmul
										f_mul = 1;
										f_xmul = 1;
										f_inv = 0; // hi bits
										f_sgn = 0; 
										f_addw = 0;
									end else begin
										trap = 1;
									end
							7'b0100100:
									if (b) begin // sbclr
										f_bsh = 3;
										f_inv = 0;
										f_sl = 1;	
									end else begin
										trap = 1;
									end
							7'b0010100:
									if (b) begin // sbset
										f_bsh = 3;
										f_inv = 0;
										f_sr = 1;	
									end else begin
										trap = 1;
									end
							7'b0110100:
									if (b) begin // sbinv	
										f_bsh = 3;
										f_inv = 1;
										f_sl = 1;	
									end else begin
										trap = 1;
									end
							default: trap = 1;
							endcase
						end
					3'b010: begin	
							trap = {ins[31],ins[28], ins[26]} != 0;
							case ({ins[27], ins[29], ins[30], ins[25]}) // synthesis full_case parallel_case
							4'b0000: begin
										f_slt = 1; // slt
									end
							4'b0001: begin
										// mulhsu
										f_mul = 1;
										f_xmul = 0;
										f_inv = 1; // hi bits
										f_sgn = 1; // mullhsu
										f_addw = 0;
									end
							4'b0100:if (b) begin // sh1add
										f_add = 1;
										f_inv = 1'bx;
										f_sh_add = 1;
										f_addw = 0;
									end else begin
										trap = 1;
									end
							4'b1001:if (b) begin // clmulr
										f_div = 1;
										f_xmul = 1;
										f_inv = 0; // hi bits
										f_sgn = 0; 
										f_addw = 0;
									end else begin
										trap = 1;
									end
							default: trap = 1;
							endcase
						end
					3'b011: begin
							trap = {ins[31],ins[29:28], ins[26]} != 0;
							case ({ins[27], ins[30], ins[25]}) // synthesis full_case parallel_case
							3'b000: begin
									f_sltu = 1;	// sltu
						       end
							3'b001: begin
									// mulhu
									f_mul = 1;
									f_xmul = 0;
									f_inv = 1; // hi bits
									f_sgn = 2; // mullhu
									f_addw = 0;
								end
							3'b100: if (b&!rv32) begin //bmator
										f_sl = 1;
										f_inv = 0;
										f_bsh = 5;
									end else begin
										trap = 1;
									end
							3'b110: if (b&!rv32) begin //bmatxor
										f_sr = 1;
										f_inv = 0;
										f_bsh = 5;
									end else begin
										trap = 1;
									end
							3'b101:if (b) begin // clmulh
										f_mul = 1;
										f_xmul = 1;
										f_inv = 1; // hi bits
										f_sgn = 0; 
										f_addw = 0;
									end else begin
										trap = 1;
									end
							default: trap = 1;
							endcase
						end
					3'b100: begin
							trap = {ins[31],ins[28], ins[26]} != 0;
							case ({ins[29], ins[27], ins[30], ins[25]}) // synthesis full_case parallel_case
							4'b0000: begin
										f_xor = 1; // xor
										f_inv = 0;
						       		end
							4'b0001: begin	// div
									f_div = 1;	// div
									f_xmul = 0;
									f_inv = 0;	// div/rem
									f_sgn = 1;	// signed
									f_addw = 0;
								end
							4'b0010: if (b) begin
										f_xor = 1; // xnor
										f_inv = 1;
						       		end else begin
										trap = 1;
									end
							4'b0101: if (b) begin		// min
										f_min = 1;
										f_inv = 0;
									end else begin
										trap = 1;
									end
							4'b1000:if (b) begin // sh2add
										f_add = 1;
										f_inv = 1'bx;
										f_sh_add = 2;
										f_addw = 0;
									end else begin
										trap = 1;
									end
							4'b0100: if (b) begin //pack
										f_sl = 1;
										f_inv = 1;
										f_bsh = 6;
									end else begin
										trap = 1;
									end
							4'b0110: if (b) begin //packu
										f_sr = 1;
										f_inv = 1;
										f_bsh = 6;
									end else begin
										trap = 1;
									end
							default: trap = 1;
							endcase
						end
					3'b101: begin
							casez (ins[31:25]) // synthesis full_case parallel_case
							7'b?????10:
									if (b) begin	// fsr
										f_sr = 1;	
										f_inv = 0;
										f_bsh = 7;
										needs_rs3 = 1;
									end else begin
										trap = 1;
									end
							7'b?????11:
									if (b) begin	// cmov
										f_sr = 1;	
										f_inv = 1;
										f_bsh = 7;
										needs_rs3 = 1;
									end else begin
										trap = 1;
									end
							7'b01?0000:
									begin
										// sra
										f_sr = 1;
										f_inv = 1;
										if (ins[29]) begin
											if (!b)
												trap = 1;
											f_bsh = 3'b001;
										end else begin
											f_bsh = 3'b000;
										end
									end 
							7'b00?0000:
									begin // srl
										f_sr = 1;
										f_inv = 0;
										if (ins[29]) begin
											if (!b)
												trap = 1;
											f_bsh = 3'b001;
										end else begin
											f_bsh = 3'b000;
										end
							       end
							7'b0000001:	
									begin // divu
										f_div = 1;	// div
										f_xmul = 0;
										f_inv = 0;	// div/rem
										f_sgn = 0;	// signed
										f_addw = 0;
									end
							7'b000100:
									if (b) begin // unshfl
										f_bsh = 2;
										f_inv = 1;
										f_sr = 1;	
									 end else begin
										trap = 1;
									 end
							7'b0000101:
									 if (b) begin // minu
										f_min = 1;
										f_inv = 1;
									 end else begin
										trap = 1;
									 end
							7'b0100100:
									 if (b) begin // sbext
										f_bsh = 3;
										f_inv = 1;
										f_sr = 1;	
									 end else begin
										trap = 1;
									 end
							7'b0010100:
									 if (b) begin // gorc
										f_bsh = 2;
										f_inv = 0;
										f_sl = 1;	
									 end else begin
										trap = 1;
									 end
							7'b0110100:
									 if (b) begin // grev	
										f_bsh = 2;
										f_inv = 0;
										f_sr = 1;	
									 end else begin
										trap = 1;
									end
							default:trap = 1;
							endcase
						end
					3'b110: begin	// or
							trap = {ins[31],ins[29:28], ins[26]} != 0;
							case ({ins[27], ins[30], ins[25]}) // synthesis full_case parallel_case
							3'b000: begin
										f_or = 1;// or
										f_inv = 0;
									end
							3'b001: begin
										// rem
										f_div = 1;	// div
										f_xmul = 0;
										f_inv = 1;	// div/rem
										f_sgn = 1;	// signed
										f_addw = 0;
									end
							3'b010: if (b) begin
										f_or = 1;// orn
										f_inv = 1;
									end else begin
										trap = 1;
									end
							3'b101: if (b) begin // max
										f_max = 1;
										f_inv = 0;
									end else begin
										trap = 1;
									end
							3'b100: if (b) begin //bdep
										f_div = 1;
										f_xmul = 0;
										f_inv = 0;	// div/rem
										f_sgn = 1;	// signed
										f_addw = 0;
									end else begin
										trap = 1;
									end
							3'b110: if (b) begin //bext
										f_mul = 1;
										f_xmul = 0;
										f_inv = 0;	// div/rem
										f_sgn = 1;	// signed
										f_addw = 0;
									end else begin
										trap = 1;
									end
							default:trap = 1;
							endcase
						end
					3'b111: begin	
							trap = {ins[31],ins[28], ins[26]} != 0;
							case ({ins[29], ins[27], ins[30], ins[25]}) // synthesis full_case parallel_case
							4'b0000: begin
										f_and = 1; // and
										f_inv = 0;
									end
							4'b0001:begin
										// remu
										f_div = 1;	// div
										f_xmul = 0;
										f_inv = 1;	// div/rem
										f_sgn = 0;	// signed
										f_addw = 0;
									end
							4'b0010:if (b) begin
										f_and = 1; // andn
										f_inv = 1;
									end else begin
										trap = 1;
									end
							4'b0101:if (b) begin // max
										f_max = 1;
										f_inv = 0;
									end else begin
										trap = 1;
									end
							4'b1000:if (b) begin // sh3add
										f_add = 1;
										f_inv = 1'bx;
										f_sh_add = 3;
										f_addw = 0;
									end else begin
										trap = 1;
									end
							4'b0100: if (b) begin //packh
										f_sl = 1;
										f_inv = 1;
										f_bsh = 5;
									end else begin
										trap = 1;
									end
							4'b0110: if (b) begin //bfp
										f_sr = 1;
										f_inv = 1;
										f_bsh = 5;
									end else begin
										trap = 1;
									end
							default:trap = 1;
							endcase
						end
					default:trap = 1;
					endcase
				end
		5'b01101:begin	// lui
					makes_rd = rd !=0;
					in_pc = 0;
					rs1 = 0;
					f_add = 1;
					f_sh_add = 0;
					f_addw = 0;
					f_inv = 0;
					imm = {ins[31:12], 12'b0};
				end
		5'b01110:begin	// mult64 alu ops	/  W alu ops 
					makes_rd = rd !=0;
					needs_rs2 = 1;
					if (ins[25]) begin
						case (ins[14:12]) // synthesis full_case parallel_case
						3'b000:if (b && ins[27]) begin	// addwu/subwu
									trap = rv32|({ins[31],ins[29:28],ins[26]}!=0);
									f_add = 1;
									f_addw = 1;
									f_inv = ins[30];
									f_sh_add = 4;
							   end else begin
									trap = rv32|(ins[31:26] != 6'b000000);
									// mulw
									f_mul = 1;
									f_xmul = 0;
									f_inv = 0;	// lo bits
									f_addw = 1;
								end
						3'b001: begin
								casez ({ins[31:25]}) // synthesis full_case parallel_case
								7'b?????10:
									 if (b) begin	// fslw
										f_sl = 1;	
										f_inv = 0;
										f_bsh = 7;
										needs_rs3 = 1;
										f_addw = 1;
									 end else begin
										trap = 1;
									 end
								7'b0000100:
									if (b) begin // shfl
										f_bsh = 2;
										f_inv = 1;
										f_sl = 1;	
										f_addw = 1;
									end else begin
										trap = 1;
									end
								7'b0000101:
									if (b) begin // clmul
										f_mul = 1;
										f_xmul = 1;
										f_inv = 0; // hi bits
										f_sgn = 0; 
										f_addw = 1;
									end else begin
										trap = 1;
									end
								7'b0100100:
									if (b) begin // sbclr
										f_bsh = 3;
										f_inv = 0;
										f_sl = 1;	
										f_addw = 1;
									end else begin
										trap = 1;
									end
								7'b0010100:
									if (b) begin // sbset
										f_bsh = 3;
										f_inv = 0;
										f_sr = 1;	
										f_addw = 1;
									end else begin
										trap = 1;
									end
								7'b0110100:
									if (b) begin // sbinv	
										f_bsh = 3;
										f_inv = 1;
										f_sl = 1;	
										f_addw = 1;
									end else begin
										trap = 1;
									end
								default: trap = 1;
								endcase
							end
						3'b010:begin
								casez ({ins[31:25]}) // synthesis full_case parallel_case
								7'b0000101:
									if (b) begin // clmulrw
										f_div = 1;
										f_xmul = 1;
										f_inv = 0; // hi bits
										f_sgn = 0; 
										f_addw = 1;
									end else begin
										trap = 1;
									end
								default: trap = 1;
								endcase
							   end
						3'b011:begin
								casez ({ins[31:25]}) // synthesis full_case parallel_case
								7'b0000101:
									if (b) begin // clmulhw
										f_mul = 1;
										f_xmul = 1;
										f_inv = 1; // hi bits
										f_sgn = 0; 
										f_addw = 1;
									end else begin
										trap = 1;
									end
								default: trap = 1;
								endcase
							   end
						3'b100:begin
								trap = {ins[31],ins[28], ins[26]} != 0;
								casez ({ins[27], ins[29], ins[30], ins[25]}) // synthesis full_case parallel_case
								4'b0001: if (!rv32) begin
											// divw
											f_div = 1;
											f_xmul = 0;
											f_inv = 0;	// div/rem
											f_addw = 1;
											f_sgn = 1; 	// signed
										end else begin
											trap = 1;
										end
								4'b1000:if (b) begin	// packw
											f_sl = 1;
											f_inv = 1;
											f_bsh = 6;
											f_addw = 1;
										end else begin
											trap = 1;
										end
								4'b1010:if (b) begin	// packuw
											f_sr = 1;
											f_inv = 1;
											f_bsh = 6;
											f_addw = 1;
										end else begin
											trap = 1;
										end
								default: trap = 1;
								endcase
							end
						3'b101: begin
								casez (ins[31:25]) // synthesis full_case parallel_case
								7'b?????10:
										if (b) begin	// fsrw
											f_sr = 1;	
											f_inv = 0;
											f_bsh = 7;
											needs_rs3 = 1;
											f_addw = 1;
										end else begin
											trap = 1;
										end
								7'b0000001:
										begin
											// divuw
											f_div = 1;
											f_xmul = 0;
											f_inv = 0;	// div/rem
											f_addw = 1;
											f_sgn = 0; 	// signed
										end
								7'b0000100:
										if (b) begin // unshfl
											f_bsh = 2;
											f_inv = 1;
											f_sr = 1;	
											f_addw = 1;
										end else begin
											trap = 1;
										end
								7'b0100100:
										if (b) begin // sbext
											f_bsh = 3;
											f_inv = 1;
											f_sr = 1;	
											f_addw = 1;
										end else begin
											trap = 1;
										end
								7'b0010100:
										if (b) begin // gorc
											f_bsh = 2;
											f_inv = 0;
											f_sl = 1;	
											f_addw = 1;
										end else begin
											trap = 1;
										end
								7'b0110100:
										if (b) begin // grev	
											f_bsh = 2;
											f_inv = 0;
											f_sr = 1;	
											f_addw = 1;
										end else begin
											trap = 1;
										end
								default: trap = 1;
								endcase
							end
						3'b110:begin
								casez ({ins[27], ins[29], ins[30], ins[25]}) // synthesis full_case parallel_case
								4'b0001: if (!rv32) begin // remw
											f_div = 1;
											f_xmul = 0;
											f_inv = 1;	// div/rem
											f_addw = 1;
											f_sgn = 1; 	// signed
										 end else begin
											trap = 1;
										 end
								4'b1000:if (b) begin	// bdepw
											f_div = 1;
											f_xmul = 0;
											f_inv = 0;	// div/rem
											f_sgn = 1;	// signed
											f_addw = 1;
										end else begin
											trap = 1;
										end
								4'b1010:if (b) begin	// bextw
											f_mul = 1;
											f_xmul = 0;
											f_inv = 0;	// div/rem
											f_sgn = 1;	// signed
											f_addw = 1;
										end else begin
											trap = 1;
										end
								default:trap = 1;
								endcase
							   end
						3'b111:begin
								trap = {ins[31],ins[28], ins[26]} != 0;
								casez ({ins[27], ins[29], ins[30], ins[25]}) // synthesis full_case parallel_case
								4'b0001: if (!rv32) begin // remuw
											f_div = 1;
											f_xmul = 0;
											f_inv = 1;	// div/rem
											f_addw = 1;
											f_sgn = 0; 	// signed
										end else begin
											trap = 1;
										end
								4'b1010:if (b) begin	// bfpw
											f_sl = 1;
											f_inv = 1;
											f_bsh = 5;
											f_addw = 1;
										end else begin
											trap = 1;
										end
								default:trap = 1;
								endcase
							  end
						default:trap = 1;
						endcase
					end else begin
						f_addw = 1;
						case (ins[14:12]) // synthesis full_case parallel_case
						3'b000: begin	// addw/subw
									trap = rv32|({ins[31],ins[29:26]} != 0);
									f_add = 1;
									f_sh_add = 0;
									trap = rv32;
									if (ins[30]) begin
										f_inv = 1;
									end else begin
										f_inv = 0;	
									end
								end
						3'b001:	begin	// slw
									trap = rv32|({ins[31],ins[28:26]} != 0)|(b?(ins[30:29]!=2'b10):(ins[30:29]!=2'b00));
									f_sl = 1;	
									f_bsh = {2'b00, b&ins[29]};
									f_inv = b&ins[29]&ins[30];	
								end
						3'b010:	begin	// sh1addw
									trap = rv32|!b|(ins[31:25] != 7'b0010000);
									f_add = 1;
									f_inv = 1'bx;
									f_sh_add = 1;
								end
						3'b101:	begin	// sraw/srlw
									trap = rv32|({ins[31],ins[28:26]} != 0)|(!b&ins[29]);
									f_sr = 1;	
									f_bsh = {2'b00, b&ins[29]};
									if (ins[30]) begin
										f_inv = 1;
									end else begin
										f_inv = 0;	
									end
								end
						3'b100:	begin	// sh2addw
									trap = rv32|!b|(ins[31:25] != 7'b0010000);
									f_add = 1;
									f_inv = 1'bx;
									f_sh_add = 2;
								end
						3'b110:	begin	// sh3addw
									trap = rv32|!b|(ins[31:25] != 7'b0010000);
									f_add = 1;
									f_inv = 1'bx;
									f_sh_add = 3;
								end
						default:	trap = 1;
						endcase
					end
				 end
		5'b01000:begin	// stores	
					imm = {{20{ins[31]}},ins[31:25],ins[11:7]};
					f_store = 1;
					f_amo = 0;
					makes_rd = 0;
					needs_rs2 = 1;
					case (ins[14:12]) // synthesis full_case parallel_case
					3'b000: begin	// sb
							lsize = 0;
							lf = 0;
						end
					3'b001: begin	// sh
							lsize = 1;
							lf = 0;
						end
					3'b010: begin	// sw
							lsize = 2;
							lf = 0;
						end
					3'b011: begin	// sd
							trap = rv32;
							lsize = 3;
							lf = 0;
						end
					default: trap = 1;
					endcase
				end
		5'b01001:begin	// fst
					imm = {{20{ins[31]}},ins[31:25],ins[11:7]};
					f_store = 1;
					f_amo = 0;
					needs_rs2 = 1;
					makes_rd = 0;
					case (ins[14:12])  // synthesis full_case parallel_case
					3'b010: begin		// fsw
								lsize = 2;
								lf = 1;
							end
					3'b011: begin		// fsd
								lsize = 3;
								lf = 1;
							end
					default: trap = 1;
					endcase
				 end
		5'b01011:begin	// amo/etc
					lsize = ins[13:12];
					f_store = ins[31:27] != 2;
					f_load = ins[31:27] == 2;
					lf = 0;
					f_amo = 1;
					needs_rs2 = !f_load;
					makes_rd = rd != 0;
					imm = 0;
					lsgn = 0;	
					trap = ins[14] || !ins[13] || (f_load && rs2 != 0);
					case (ins[31:27]) // synthesis full_case parallel_case
					5'b00010: imm = {5'bx,ins[26:25],25'bx};	// lw
					5'b00011,			// sc
					5'b00001,			// amoswap
					5'b00000,			// amoadd
					5'b00100,			// amoxor
					5'b01100,			// amoand
					5'b01000,			// amoor
					5'b10000,			// amomin
					5'b10100,			// amomax
					5'b11000,			// amominu
					5'b11100:			// amomaxu
							 imm = {ins[31:25], 25'bx};
					default: begin trap = 1; imm = 32'bx; end
					endcase
				 end
		5'b10000:begin	// fmadd*
					f_fp = 1;
					f_fpm = 1;
					trap = ins[14:12] == 5 || ins[14:12] == 6; // invalid rounding modes
					f_fp_sz = ins[26:25];
					trap = trap | ins[26];
					f_fp_op = 0;	// fadd
					needs_rs2 = 1;
					needs_rs3 = 1;
					imm = {17'bxxxxxxxx, ins[14:12], 5'bxxxxx, 2'bxx, 5'bxxxxx};	// encode RM here
					rs1_fp = 1;
					rs2_fp = 1;
					rs3_fp = 1;
					rd_fp = 1;
`ifndef FP
					trap = 1; 
`endif
				 end
		5'b10001:begin	// fmsub*
					f_fp = 1;
					f_fpm = 1;
					trap = ins[14:12] == 5 || ins[14:12] == 6; // invalid rounding modes
					f_fp_sz = ins[26:25];
					trap = trap | ins[26];
					f_fp_op = 1;	// fsub
					needs_rs3 = 1;
					needs_rs2 = 1;
					imm = {17'bxxxxxxxx, ins[14:12], 5'bxxxxx, 2'bxx, 5'bxxxxx};	// encode RM here
					rs1_fp = 1;
					rs2_fp = 1;
					rs3_fp = 1;
					rd_fp = 1;
`ifndef FP
					trap = 1; 
`endif
				 end
		5'b10010:begin	// fnmsub*
					f_fp = 1;
					f_fpm = 1;
					trap = ins[14:12] == 5 || ins[14:12] == 6; // invalid rounding modes
					f_fp_sz = ins[26:25];
					trap = trap | ins[26];
					f_fp_op = 2;	// fnmsub
					needs_rs2 = 1;
					needs_rs3 = 1;
					imm = {17'bxxxxxxxx, ins[14:12], 5'bxxxxx, 2'bxx, 5'bxxxxx};	// encode RM here
					rs1_fp = 1;
					rs2_fp = 1;
					rs3_fp = 1;
					rd_fp = 1;
`ifndef FP
					trap = 1; 
`endif
				 end
		5'b10011:begin	// fnmadd*
					f_fp = 1;
					f_fpm = 1;
					trap = ins[14:12] == 5 || ins[14:12] == 6; // invalid rounding modes
					f_fp_sz = ins[26:25];
					trap = trap | ins[26];
					f_fp_op = 3;	// fnmadd
					needs_rs2 = 1;
					needs_rs3 = 1;
					imm = {17'bxxxxxxxx, ins[14:12], 5'bxxxxx, 2'bxx, 5'bxxxxx};	// encode RM here
					rs1_fp = 1;
					rs2_fp = 1;
					rs3_fp = 1;
					rd_fp = 1;
`ifndef FP
					trap = 1; 
`endif
				 end
		5'b10100:begin	// fp
					makes_rd = 0;
					f_fp = 1;
					f_fp_op = 4'bx;
					f_fpm = 0;
					needs_rs2 = 1;
					trap = ins[14:12] == 5 || ins[14:12] == 6; // invalid rounding modes
					f_fp_sz = ins[26:25];
					trap = trap | ins[26];
					imm = {15'bxxxxx, ins[20], ins[28], ins[14:12], 5'bxxxxx, 2'bxx, 5'bxxxxx};	// encode RM here
					rs1_fp = 1;
					rd_fp = 1;
					case (ins[31:27]) // synthesis full_case parallel_case
					5'b00000:	begin	// fadd.*
									rs2_fp = 1;
									f_fp_op = 0;	// fadd
								end
					5'b00001:	begin	// fsub.*
									rs2_fp = 1;
									f_fp_op = 1;	// fsub
								end
					5'b00010:	begin	// fmul.*
									f_fp_op = 2;	// fmul
								end
					5'b00011:	begin	// fdiv.*
									rs2_fp = 1;
									f_fp_op = 3;	// fdiv
								end
					5'b01011:	begin	// fsqrt.*
									f_fp_op = 4;	// fsqrt
									needs_rs2 = 0;
									trap = trap | rs2!=0;
								end
					5'b00100:	begin	// fsgn*.*
									f_fp_op = 5;	// fsgn*
									trap = ins[14] | ins[26] | (ins[13:12]==2'h3);
								end
					5'b00101:	begin	// fmin/max.*
									rs2_fp = 1;
									f_fp_op = 6;	// fmin/max
									trap = ins[14:13]!=0 || ins[26];
								end
					5'b01000:	begin	// fcvt.sd/ds
									rs2_fp = 1;
									needs_rs2 = 0;
									f_fp_op = 7;			// fcvt.s.d/d.s 
									trap = trap || rs2[4:1]!=0 || (rs2[0]&ins[25]) || (~rs2[0]&~ins[25]);
								end
					5'b10100:	begin	// fcmp
									rd_fp = 0;
									rs2_fp = 1;
									f_fp_op = 12;
									trap = trap || imm[14:12]>2;
								end
					5'b11000:	begin	// fcvt.w
									needs_rs2 = 0;
									rs1_fp = 0;
									case (rs2[1:0])// synthesis full_case parallel_case
									0: f_fp_op = 8;			// fcvt.w.*
									1: f_fp_op = 9;			// fcvt.wu.*
									2: f_fp_op = 10;		// fcvt.l.*
									3: f_fp_op = 11;		// fcvt.lu.*
									default:f_fp_op = 4'bx;
									endcase
									trap = trap || rs2[4:2]!=0;
								end
					5'b11010:	begin	// fcvt.s
									rs1_fp = 0;
									needs_rs2 = 0;
									case (rs2[1:0])// synthesis full_case parallel_case
									0: f_fp_op = 8;			// fcvt.*.w
									1: f_fp_op = 9;			// fcvt.*.wu
									2: f_fp_op = 10;		// fcvt.*.l
									3: f_fp_op = 11;		// fcvt.*.lu
									default:f_fp_op = 4'bx;
									endcase
									trap = trap || rs2[4:2]!=0;
								end
					5'b11100:	begin	// fclass
									rd_fp = 0;
									needs_rs2 = 0;
									f_fp_op = 13;		// fclass.*
									trap = trap || rs2[4:1] != 0 || (rs2[0] == f_fp_sz[0]) || ins[14:12] != 3'b001;
								end
					5'b11110:	begin	// fmv
									f_fp_op = 14;	// fmv.*.x
									needs_rs2 = 0;
									trap = trap || rs2 != 0 || ins[14:12] != 0;
								end
					default:	trap = 1;
					endcase
`ifndef FP
					trap = 1;
`endif
				 end
		5'b11000:begin	// branches
					cjmp = 1;
					makes_rd = 0;
					needs_rs2 = 1;
					br_inv = ins[12];
					br_type = ins[14:13];
					trap = ins[14:13] == 2'b01;
					br_imm = {{9{ins[31]}},ins[7],ins[30:25],ins[11:8]};
					imm = {{12{br_imm[19]}}, br_imm};
				 end
		5'b11001:begin	// jalr
					jmp = 1;
					makes_rd = rd !=0;
					in_pc = 0;
					imm = {{20{ins[31]}},ins[31:20]};
					trap = ins[14:12] != 3'b000;
					sub_push = makes_rd && (rd==1 || rd==5); 
					sub_pop = (rs1==1 || rs1==5) && (!sub_push || rs1!=rd); 
				end
		5'b11011:begin	// jal
					jmp = 1;
					in_pc = 1;
					makes_rd = rd !=0;
					rs1 = 0;
					br_imm = {ins[31],ins[19:12],ins[20],ins[30:21]};
					imm = {{12{br_imm[19]}},br_imm};
					sub_push = makes_rd && (rd==1 || rd==5); 
				end
		5'b11100:begin	// sys stuff
					case (ins[14:12]) // synthesis full_case parallel_case
					3'b000: begin
							trap = ins[14:7] != 0;
							casez ({ins[31:15], ins[11:7]}) // synthesis full_case parallel_case
							22'b0000000_00000_00000_00000:begin
									// ecall
									trap = 1;
									env_call = 1;
									rs1 = 0;
								end
							22'b0000000_00001_00000_00000:begin
									// ebreak
									trap = 1;
									brk = 1;
									rs1 = 0;
								end
							22'b0000000_00010_00000_00000:begin
									// uret
									csr = 1;
									csr_iret = 1;
									csr_pipe = 0;
									csr_iret_type = 0;
									rs1 = 0;
								end
							22'b0001000_00010_00000_00000:begin
									// sret
									if (cpu_mode[0] || tsr&cpu_mode[1]) 
										trap = 1;
									csr = 1;
									csr_iret = 1;
									csr_pipe = 0;
									csr_iret_type = 1;
									rs1 = 0;
								end
							22'b0011000_00010_00000_00000:begin
									// mret
									if (!cpu_mode[3])
										trap = 1;
									csr = 1;
									csr_iret = 1;
									csr_pipe = 0;
									csr_iret_type = 3;
									rs1 = 0;
								end
							22'b0001000_00101_00000_00000:begin
									// wfi
									trap = 0;
									csr = 1;
									csr_iret = 0;
									csr_pipe = 1;
									csr_iret_type = 1;
									rs1 = 0;
								end
							22'b0001001_?????_?????_00000:begin // sfence.vma
									trap = (tvm && cpu_mode[1]) || cpu_mode[0];	// FIXME
									f_fence = 1;
									fence_type = 0;
									needs_rs2 = rs2!=0;
									makes_rd = 0;
									imm = 0;
								end
							22'b0010001_?????_?????_00000:begin // hfence.vvma
									trap = tvm && cpu_mode[1];	// FIXME
									f_fence = 1;
									fence_type = 1;
									needs_rs2 = rs2!=0;
									makes_rd = 0;
									imm = 0;
								end
							22'b0110001_?????_?????_00000:begin // hfence.gvma
									trap = tvm && cpu_mode[1];	// FIXME
									f_fence = 1;
									fence_type = 2;
									needs_rs2 = rs2!=0;
									makes_rd = 0;
									imm = 0;
								end
							default:	trap = 1;
							endcase
						end
					3'b001: begin	// csrrw
							csr = 1;
							csr_iret = 0;
							csr_pipe = 0;
							csr_immed = 0;
							csr_write = 1;
							csr_type = 0;
							imm = {20'bx,ins[31:20]};
							makes_rd = rd !=0;
							// cpu_mode 0 usr 1 sup 3 mach
							trap = (enc_cpu_mode < imm[9:8]) | (imm[11:10]==2'b11) | badcsr(imm[11:0], rv32, tvm&(cpu_mode[1]), hyper) |
								((imm[11:2] == 10'b11_00_0000_00) & 
									(((imm[1:0]==0) & (((cpu_mode[0]) & (~timer_prot[3]|~timer_prot[0])) |
													   ((cpu_mode[1]) & (~timer_prot[3])) )) |
									 ((imm[1:0]==1) & (((cpu_mode[0]) & (~timer_prot[4]|~timer_prot[1])) |
													   ((cpu_mode[1]) & (~timer_prot[4])) )) |
									 ((imm[1:0]==2) & (((cpu_mode[0]) & (~timer_prot[5]|~timer_prot[2])) |
													   ((cpu_mode[1]) & (~timer_prot[5])) ))  ) );
						end
					3'b010: begin	// csrrs
							csr = 1;
							csr_iret = 0;
							csr_pipe = 0;
							csr_immed = 0;
							csr_write = rs1!=0;
							csr_type = 1;
							imm = {20'bx,ins[31:20]};
							makes_rd = rd !=0;
							// cpu_mode 0 usr 1 sup 3 mach
							trap = (enc_cpu_mode < imm[9:8]) | (csr_write & (imm[11:10]==2'b11)) | badcsr(imm[11:0], rv32, tvm&(cpu_mode[1]), hyper) |
								((imm[11:2] == 10'b11_00_0000_00) & 
									(((imm[1:0]==0) & (((cpu_mode[0]) & (~timer_prot[3]|~timer_prot[0])) |
													   ((cpu_mode[1]) & (~timer_prot[3])) )) |
									 ((imm[1:0]==1) & (((cpu_mode[0]) & (~timer_prot[4]|~timer_prot[1])) |
													   ((cpu_mode[1]) & (~timer_prot[4])) )) |
									 ((imm[1:0]==2) & (((cpu_mode[0]) & (~timer_prot[5]|~timer_prot[2])) |
													   ((cpu_mode[1]) & (~timer_prot[5])) ))  ) );
						end
					3'b011: begin	// csrrc
							csr = 1;
							csr_iret = 0;
							csr_pipe = 0;
							csr_immed = 0;
							csr_write = 1;
							csr_type = 2;
							imm = {20'bx,ins[31:20]};
							makes_rd = rd !=0;
							// cpu_mode 0 usr 1 sup 3 mach
							trap = (enc_cpu_mode < imm[9:8]) | (csr_write & (imm[11:10]==2'b11)) | badcsr(imm[11:0], rv32, tvm&(cpu_mode[1]), hyper) |
								((imm[11:2] == 10'b11_00_0000_00) & 
									(((imm[1:0]==0) & (((cpu_mode[0]) & (~timer_prot[3]|~timer_prot[0])) |
													   ((cpu_mode[1]) & (~timer_prot[3])) )) |
									 ((imm[1:0]==1) & (((cpu_mode[0]) & (~timer_prot[4]|~timer_prot[1])) |
													   ((cpu_mode[1]) & (~timer_prot[4])) )) |
									 ((imm[1:0]==2) & (((cpu_mode[0]) & (~timer_prot[5]|~timer_prot[2])) |
													   ((cpu_mode[1]) & (~timer_prot[5])) ))  ) );
						end
					3'b101: begin	// csrrwi
							csr = 1;
							csr_iret = 0;
							csr_pipe = 0;
							csr_immed = 1;
							csr_write = 1;
							csr_type = 0;
							imm = {15'bx, rs1, ins[31:20]};
							makes_rd = rd !=0;
							// cpu_mode 0 usr 1 sup 3 mach
							trap = (enc_cpu_mode < imm[9:8]) | (imm[11:10]==2'b11) | badcsr(imm[12:0], rv32, tvm&(cpu_mode[1]), hyper) |
								((imm[11:2] == 10'b11_00_0000_00) & 
									(((imm[1:0]==0) & (((cpu_mode[0]) & (~timer_prot[3]|~timer_prot[0])) |
													   ((cpu_mode[1]) & (~timer_prot[3])) )) |
									 ((imm[1:0]==1) & (((cpu_mode[0]) & (~timer_prot[4]|~timer_prot[1])) |
													   ((cpu_mode[1]) & (~timer_prot[4])) )) |
									 ((imm[1:0]==2) & (((cpu_mode[0]) & (~timer_prot[5]|~timer_prot[2])) |
													   ((cpu_mode[1]) & (~timer_prot[5])) ))  ) );
						end
					3'b110: begin	// csrrsi
							csr = 1;
							csr_iret = 0;
							csr_pipe = 0;
							csr_immed = 1;
							csr_write = rs1!=0;
							csr_type = 1;
							imm = {15'bx, rs1, ins[31:20]};
							makes_rd = rd !=0;
							// cpu_mode 0 usr 1 sup 3 mach
							trap = (enc_cpu_mode < imm[9:8]) | (csr_write&(imm[11:10]==2'b11)) | badcsr(imm[11:0], rv32, tvm&(cpu_mode[1]), hyper) |
								((imm[11:2] == 10'b11_00_0000_00) & 
									(((imm[1:0]==0) & (((cpu_mode[0]) & (~timer_prot[3]|~timer_prot[0])) |
													   ((cpu_mode[1]) & (~timer_prot[3])) )) |
									 ((imm[1:0]==1) & (((cpu_mode[0]) & (~timer_prot[4]|~timer_prot[1])) |
													   ((cpu_mode[1]) & (~timer_prot[4])) )) |
									 ((imm[1:0]==2) & (((cpu_mode[0]) & (~timer_prot[5]|~timer_prot[2])) |
													   ((cpu_mode[1]) & (~timer_prot[5])) ))  ) );
						end
					3'b111: begin	// csrrci
							csr = 1;
							csr_iret = 0;
							csr_pipe = 0;
							csr_immed = 1;
							csr_write = 1;
							csr_type = 2;
							imm = {15'bx, rs1, ins[31:20]};
							makes_rd = rd !=0;
							// cpu_mode 0 usr 1 sup 3 mach
							trap = (enc_cpu_mode < imm[9:8]) | (csr_write &(imm[11:10]==2'b11)) | badcsr(imm[11:0], rv32, tvm&(cpu_mode[1]), hyper) |
								((imm[11:2] == 10'b11_00_0000_00) & 
									(((imm[1:0]==0) & (((cpu_mode[0]) & (~timer_prot[3]|~timer_prot[0])) |
													   ((cpu_mode[1]) & (~timer_prot[3])) )) |
									 ((imm[1:0]==1) & (((cpu_mode[0]) & (~timer_prot[4]|~timer_prot[1])) |
													   ((cpu_mode[1]) & (~timer_prot[4])) )) |
									 ((imm[1:0]==2) & (((cpu_mode[0]) & (~timer_prot[5]|~timer_prot[2])) |
													   ((cpu_mode[1]) & (~timer_prot[5])) ))  ) );
						end
					default: trap = 1;
					endcase
				end
		default: trap = 1;
		endcase
	end
	endtask


	task decode_16;
	input [15:0]ins;
	output [4:0]rd, rs1, rs2;
	output	trap, brk;
	output  jmp, cjmp;
	output br_inv;
	output [1:0]br_type;
	output [31:0]imm;
	output [19:0]br_imm;
	output   f_store, f_load, lf;
	output  [1:0]lsize;
	output   lsgn;
	output makes_rd, needs_rs2, f_add, f_addw, f_xor, f_and, f_or, f_slt, f_sltu, f_inv, f_sl, f_sr, in_pc; 
	output sub_push, sub_pop;
	begin
		rd = 5'bx;
		rs1 = 5'bx;
		rs2 = 5'bx;
		trap = 0; 
		brk = 0;
		jmp = 0;
		br_imm = 20'bx;
		cjmp = 0;
		br_inv = 1'bx;
		br_type = 2'bx;
		lsize = 2'bx;
		lsgn = 1'bx;
		lf = 1'bx;
		f_load = 0;
		in_pc = 0;
		f_store = 0;
		needs_rs2 = 0;
		makes_rd = 0;
		f_add = 0;
		f_addw = 0;
		f_xor = 0;
		f_and = 0;
		f_or = 0;
		f_slt = 0;
		f_sltu = 0;
		f_inv = 0;
		f_sl = 0;
		f_sr = 0;
		sub_push = 0;
		sub_pop = 0;
		imm = 32'bx;
		case (ins[1:0]) // synthesis full_case parallel_case
		2'b00:	begin	// compressed C0
					rd = {2'b01, ins[4:2]};
					rs1 = {2'b01, ins[9:7]};
					rs2 = {2'b01, ins[4:2]};
					case (ins[15:13]) // synthesis full_case parallel_case
					3'b000: begin
							if (ins[15:2] == 0) begin
								trap = 1;	// illegal instruction
							end else begin
								// c.addi4spn
								makes_rd = 1;
								rs1 = 2;
								f_add = 1;
								f_addw = 0;
								f_inv = 0;
								imm = {22'b0,ins[10:7],ins[12:11],ins[5],ins[6],2'b0};
							end
						end
					3'b001: begin
							// c.fld
							f_load = 1;
							makes_rd = 1;
							imm = {24'b0,ins[6:5],ins[12:10],3'b0};
							lf = 1;
							lsize = 3;
							lsgn = 0;
`ifndef FP
							trap = 1;
`endif
						end
					3'b010: begin
							// c.lw
							f_load = 1;
							makes_rd = 1;
							imm = {25'b0,ins[5],ins[12:10],ins[6],2'b0};
							lsize = 2;
							lsgn = 0;
						end
					3'b011: if (rv32) begin
								// c.flw
								f_load = 1;
								makes_rd = 1;
								imm = {24'b0,ins[5],ins[12:10], ins[6],2'b0};
								lf = 1;
								lsize = 2;
								lsgn = 0;
`ifndef FP
								trap = 1;
`endif
							end else begin
								// c.ld
								f_load = 1;
								makes_rd = 1;
								imm = {24'b0,ins[6:5],ins[12:10],3'b0};
								lsize = 3;
								lsgn = 0;
							end
					3'b100: begin
							trap = 1;
						end
					3'b101: begin
							// c.fsd
`ifndef FP
							trap = 1;
`endif
							f_store = 1;
							needs_rs2 = 1;
							imm = {24'b0,ins[6:5],ins[12:10],3'b0};
							lf = 1;
							lsize = 3;
							lsgn = 0;
						end
					3'b110: begin
							// c.sw
							f_store = 1;
							needs_rs2 = 1;
							imm = {25'b0,ins[5],ins[12:10],ins[6],2'b0};
							lsize = 2;
							lsgn = 0;
						end
					3'b111: if (rv32) begin
								// c.fsw
`ifndef FP
								trap = 1;
`endif
								f_store = 1;
								needs_rs2 = 1;
								imm = {25'b0,ins[5],ins[12:10],ins[6],2'b0};
								lf = 1;
								lsize = 2;
								lsgn = 0;
							end else begin
									// c.sd
								f_store = 1;
								needs_rs2 = 1;
								imm = {24'b0,ins[6:5],ins[12:10],3'b0};
								lsize = 3;
								lsgn = 0;
						end
					endcase
				end
		2'b01:	begin	// compressed C1
				rd = {2'b01, ins[9:7]};
				rs1 = {2'b01, ins[9:7]};
				rs2 = {2'b01, ins[4:2]};
				casez (ins[15:13]) // synthesis full_case parallel_case
				3'b000: begin	// c.addi
						rd = ins[11:7];
						rs1 = ins[11:7];
						makes_rd = rd!=0;
						f_add = 1;
						f_addw = 0;
						f_inv = 0;
						imm = {{26{ins[12]}},ins[12],ins[6:2]};
					end
				3'b001: if (rv32) begin // jal
							makes_rd = 1;
							rd = 1;
							jmp = 1;
							rs1 = 0;
							in_pc = 1;
							br_imm = {{9{ins[12]}},ins[12], ins[8],ins[10:9],ins[6],ins[7],ins[2],ins[11],ins[5:3]};
							imm = {{12{br_imm[19]}}, br_imm};
							sub_push = 1;
						end else begin	// c.addiw
							rd = ins[11:7];
							rs1 = ins[11:7];
							f_add = 1;
							makes_rd = 1;
							f_addw = 1;
							f_inv = 0;
							imm = {{26{ins[12]}},ins[12],ins[6:2]};
						end
				3'b010: begin	// c.li
						rd = ins[11:7];
						rs1 = 0;
						makes_rd = rd!=0;
						f_add = 1;
						f_addw = 0;
						f_inv = 0;
						imm = {{26{ins[12]}},ins[12],ins[6:2]};
					end
				3'b011: begin	// c.lui/c.addi16sp
						rd = ins[11:7];
						rs1 = (rd==2?2:0);
						makes_rd = rd!=0;
						f_add = 1;
						f_addw = 0;
						f_inv = 0;
						if (rd==2) begin
							imm = {{23{ins[12]}},ins[12],ins[4:3], ins[5], ins[2],ins[6],4'b0};
						end else begin
							imm = {{14{ins[12]}},ins[12],ins[6:2], 12'b0};
						end
					end
				3'b100: begin	
						f_xor = 0;
						f_and = 0;
						f_or = 0;
						f_slt = 0;
						f_sltu = 0;
						f_add = 0;
						f_addw = 0;
						f_inv = 0;
						makes_rd = 1;
						casez ({ins[12:10], ins[6:5]})// synthesis full_case parallel_case
						5'b?_00_??:	begin	// c.srli
								f_sr = 1;
								f_inv = 0;
								imm = {26'b0,ins[12],ins[6:2]};
							end
						5'b?_01_??:	begin	// c.srai
								f_sr = 1;
								f_inv = 1;
								imm = {26'b0,ins[12],ins[6:2]};
							end
						5'b?_10_??:	begin	// c.andi
								f_and = 1;
								imm = {{26{ins[12]}},ins[12],ins[6:2]};
							end
						5'b0_11_00:	begin	// c.sub
								needs_rs2 = 1;
								f_add = 1;
								f_inv = 1;
							end
						5'b0_11_01:	begin	// c.xor
								needs_rs2 = 1;
								f_xor = 1;
							end
						5'b0_11_10:	begin	// c.or
								needs_rs2 = 1;
								f_or = 1;
							end
						5'b0_11_11:	begin	// c.and
								needs_rs2 = 1;
								f_and = 1;
							end
						5'b1_11_00:	begin	// c.subw
								trap = rv32;
								needs_rs2 = 1;
								f_add = 1;
								f_addw = 1;
								f_inv = 1;
							end
						5'b1_11_01:	begin	// c.addw
								trap = rv32;
								needs_rs2 = 1;
								f_add = 1;
								f_addw = 1;
							end
						default: trap = 1;
						endcase
					end
				3'b101: begin	// c.j
						jmp = 1;
						makes_rd = 0;
						rd = 0;
						rs1 = 0;
						in_pc = 1;
						br_imm = {{9{ins[12]}},ins[12], ins[8],ins[10:9],ins[6],ins[7],ins[2],ins[11],ins[5:3]};
						imm = {{12{br_imm[19]}}, br_imm};
					end
				3'b11?: begin	// c.beqz/c.bnez
						cjmp = 1;
						makes_rd = 0;
						br_inv = ins[13];
						br_type = 0;
						needs_rs2 = 1;
						rs2 = 0;
						br_imm = {{13{ins[12]}},ins[6:5],ins[2],ins[11:10],ins[4:3]};
						imm = {{12{br_imm[19]}}, br_imm};
					end
				endcase
			end
		2'b10:	begin	// compressed C2
				rd = ins[11:7];
				rs1 = ins[11:7];
				rs2 = ins[6:2];
				case (ins[15:13]) // synthesis full_case parallel_case
				3'b000:	begin
						f_sl = 1;
						makes_rd = rd!=0;
						imm = {26'b0,ins[12],ins[6:2]};
					end
				3'b001:	begin	// c.fldsp/c.lqsp
						imm = {23'b0,ins[4:2],ins[12],ins[6:5], 3'b00};
						f_load = 1;
						makes_rd = rd !=0;
						rs1 = 2;
						lf = 1;
						lsize = 3;
						lsgn = 0;
					end
				3'b010:	begin	// c.lwsp
						imm = {24'b0,ins[3:2],ins[12],ins[6:4], 2'b00};
						f_load = 1;
						makes_rd = rd !=0;
						rs1 = 2;
						lsize = 2;
						lsgn = 0;
					end
				3'b011:	if (rv32) begin	// c.flwsp
							imm = {24'b0,ins[3:2],ins[12],ins[6:4], 2'b00};
							f_load = 1;
							makes_rd = rd !=0;
							rs1 = 2;
							lf = 1;
							lsize = 2;
							lsgn = 0;
						end else begin	// c.ldsp
							imm = {23'b0,ins[4:2],ins[12],ins[6:5], 3'b00};
							f_load = 1;
							makes_rd = rd !=0;
							rs1 = 2;
							lsize = 3;
							lsgn = 0;
						end
				3'b100:	begin
						if (ins[6:2] != 0) begin	//	c.add/c.mv
							if (!ins[12])
								rs1 = 0;	// c.mv
							f_add = 1;
							makes_rd = rd !=0;
							f_inv = 0;
							needs_rs2 = 1;
						end else begin
							if (ins[12]) begin
								if (rd == 0 ) begin	
									//	c.ebreak
									trap = 1;
									brk = 1;
								end else begin
									// c.jalr
									makes_rd = 1;
									in_pc = 0;
									jmp = 1;
									imm = 0;
									rd = 1;
									makes_rd = 1;
									sub_push = 1;
									sub_pop = (rs1==1 || rs1==5) && (rs1!=1); 
								end
							end else begin
								// c.jr
								makes_rd = 0;
								in_pc = 0;
								rd = 0;
								jmp = 1;
								imm = 0;
								trap = rs1==0;
								sub_pop = (rs1==1 || rs1==5);
							end
								
						end
					end
				3'b101:	begin
						// c.fsdsp
						imm = {22'b0,ins[9:7],ins[12:10], 3'b00};
						f_store = 1;
						needs_rs2 = 1;
						rs1 = 2;
						lf = 1;
						lsize = 3;
						lsgn = 0;
					end
				3'b110:	begin
						// c.swsp
						imm = {22'b0,ins[8:7],ins[12:9], 2'b00};
						f_store = 1;
						needs_rs2 = 1;
						rs1 = 2;
						lsize = 2;
						lsgn = 0;
					end
				3'b111:	if (rv32) begin
							// c.fswsp
							imm = {22'b0,ins[8:7],ins[12:9], 2'b00};
							f_store = 1;
							needs_rs2 = 1;
							rs1 = 2;
							lf = 1;
							lsize = 2;
							lsgn = 0;
						end else begin
							// c.sdsp
							imm = {22'b0,ins[9:7],ins[12:10], 3'b00};
							f_store = 1;
							needs_rs2 = 1;
							rs1 = 2;
							lsize = 3;
							lsgn = 0;
					end
				endcase
			end
		endcase
	end
	endtask

	always @(*) begin 
		if ((!first || !pc[1]) && (partial_valid_in || (ins[1:0] == 3))) begin
			c_short_pc = 0;
			c_inc2_1 = partial_valid_in;
			decode_32((partial_valid_in?{ins[15:0],partial_ins_in}:ins), b,
				c_rd_1, c_rs1_1, c_rs2_1, c_rs3_1,
				c_trap_1, c_break_1, c_env_call_1, 
				c_jmp_1, c_cjmp_1,
				c_br_inv_1,
				c_br_type_1,
				c_imm_1,
				c_br_imm_1,
				c_store_1, c_load_1, c_lf_1, c_amo_1, 
				c_lsize_1,
				c_lsgn_1,
				c_fence_1, c_fence_type_1,
				c_makes_rd_1, c_needs_rs2_1, c_needs_rs3_1, c_add_1, c_sh_add_1, c_addw_1, c_xor_1, c_and_1, c_or_1, c_slt_1, c_sltu_1, c_min_1, c_max_1,
				c_inv_1, c_sl_1, c_sr_1, c_clz_1, c_bsh_1, c_in_pc_1,
				c_mul_1, c_div_1, c_xmul_1, c_sgn_1,
				c_csr_1, c_csr_iret_1, c_csr_pipe_1, 
				c_csr_immed_1, c_csr_write_1,
				c_csr_type_1, c_csr_iret_type_1, 
				c_fp_1, c_fpm_1, c_fp_op_1, c_fp_sz_1,
				c_sub_push_1, c_sub_pop_1,
				c_rs1_fp_1, c_rs2_fp_1, c_rs3_fp_1, c_rd_fp_1);

			if (partial_valid_in && (ins[17:16] != 3)) begin
				decode_16(ins[31:16], 
					c_rd_2, c_rs1_2, c_rs2_2,
					c_trap_2, c_break_2,
					c_jmp_2, c_cjmp_2,
					c_br_inv_2,
					c_br_type_2,
					c_imm_2,
					c_br_imm_2,
					c_store_2, c_load_2, c_lf_2,
					c_lsize_2,
					c_lsgn_2,
					c_makes_rd_2, c_needs_rs2_2, c_add_2, c_addw_2, c_xor_2, c_and_2, c_or_2, c_slt_2, c_sltu_2,
					c_inv_2, c_sl_2, c_sr_2, c_in_pc_2, 
					c_sub_push_2, c_sub_pop_2);
				c_rs1_fp_2 = 0; c_rs2_fp_2 = 0; c_rs3_fp_2 = 0; c_rd_fp_2 = 0;
				c_mul_2 = 0; c_div_2 = 0;
				c_sgn_2 = 2'bxx;
				c_inc2_2 = 1;
			end else begin
				c_rd_2 = 5'bx; c_rs1_2 = 5'bx; c_rs2_2 = 5'bx;
				c_trap_2 = 1'bx; c_break_2 = 1'bx;
				c_jmp_2 = 1'bx; c_cjmp_2 = 1'bx;
				c_br_inv_2 = 1'bx;
				c_br_type_2 = 2'bx;
				c_imm_2 = 'bx;
				c_br_imm_2 = 'bx;
				c_store_2 = 1'bx; c_load_2 = 1'bx; c_lf_2 = 1'bx;
				c_lsize_2 = 3'bx;
				c_lsgn_2 = 1'bx;
				c_makes_rd_2 = 1'bx; c_needs_rs2_2 = 1'bx; c_add_2 = 1'bx; c_addw_2 = 1'bx; c_xor_2 = 1'bx; c_and_2 = 1'bx; c_or_2 = 1'bx; c_slt_2 = 1'bx; c_sltu_2 = 1'bx;
				c_inv_2 = 1'bx; c_sl_2 = 1'bx; c_sr_2 = 1'bx; c_in_pc_2 = 0; 
				c_mul_2 = 0; c_div_2 = 0;
				c_sgn_2 = 2'bxx;
				c_sub_push_2 = 0;
				c_sub_pop_2 = 0;
				c_inc2_2 = 1'bx;
				c_rs1_fp_2 = 0;  c_rs2_fp_2 = 0;  c_rs3_fp_2 = 0;  c_rd_fp_2 = 0;
			end
		end else begin
			c_fp_1 = 0;
			c_fpm_1 = 1'bx;
			c_fp_op_1 = 4'bxxxx;
			c_fp_sz_1 = 2'bx;
			c_short_pc = 1;
			c_env_call_1 = 0;
			c_csr_1 = 0;
			c_csr_pipe_1 = 'bx;
			c_csr_iret_1 = 'bx;
			c_csr_iret_type_1 = 'bx;
			c_csr_immed_1 = 'bx;
			c_csr_write_1 = 'bx;
			c_csr_type_1 = 'bx; 
			c_fence_1 = 0;
			c_fence_type_1 = 3'bx;
			c_amo_1 = 0;
			c_inc2_1 = 1;
			c_min_1 = 0;
			c_max_1 = 0;
			decode_16(ins[15:0], 
				c_rd_1, c_rs1_1, c_rs2_1,
				c_trap_1, c_break_1,
				c_jmp_1, c_cjmp_1,
				c_br_inv_1,
				c_br_type_1,
				c_imm_1,
				c_br_imm_1,
				c_store_1, c_load_1, c_lf_1,
				c_lsize_1,
				c_lsgn_1,
				c_makes_rd_1, c_needs_rs2_1, c_add_1, c_addw_1, c_xor_1, c_and_1, c_or_1, c_slt_1, c_sltu_1,
				c_inv_1, c_sl_1, c_sr_1, c_in_pc_1,
				c_sub_push_1, c_sub_pop_1);
			c_rs1_fp_1 = 0; c_rs2_fp_1 = 0; c_rs3_fp_1 = 0; c_rd_fp_1 = 0;
			c_rs3_1 = 5'bx;
			c_needs_rs3_1 = 0;
			c_bsh_1 = 0;
			c_clz_1 = 0;
			c_sh_add_1 = 0;
			c_mul_1 = 0; c_div_1 = 0;
			c_xmul_1 = 0;
			c_sgn_1 = 2'bxx;
			if (ins[31:16] != 3) begin
				decode_16(ins[31:16], 
					c_rd_2, c_rs1_2, c_rs2_2,
					c_trap_2, c_break_2,
					c_jmp_2, c_cjmp_2,
					c_br_inv_2,
					c_br_type_2,
					c_imm_2,
					c_br_imm_2,
					c_store_2, c_load_2, c_lf_2,
					c_lsize_2,
					c_lsgn_2,
					c_makes_rd_2, c_needs_rs2_2, c_add_2, c_addw_2, c_xor_2, c_and_2, c_or_2, c_slt_2, c_sltu_2,
					c_inv_2, c_sl_2, c_sr_2, c_in_pc_2, 
					c_sub_push_2, c_sub_pop_2);
				c_rs1_fp_2 = 0; c_rs2_fp_2 = 0; c_rs3_fp_2 = 0; c_rd_fp_2 = 0;
				c_mul_2 = 0; c_div_2 = 0;
				c_sgn_2 = 2'bxx;
				c_inc2_2 = 1;
			end else begin
				c_rd_2 = 5'bx; c_rs1_2 = 5'bx; c_rs2_2 = 5'bx;
				c_trap_2 = 1'bx; c_break_2 = 1'bx;
				c_jmp_2 = 1'bx; c_cjmp_2 = 1'bx;
				c_br_inv_2 = 1'bx;
				c_br_type_2 = 2'bx;
				c_imm_2 = 'bx;
				c_br_imm_2 = 'bx;
				c_store_2 = 1'bx; c_load_2 = 1'bx; c_lf_2 = 1'bx;
				c_lsize_2 = 3'bx;
				c_lsgn_2 = 1'bx;
				c_makes_rd_2 = 1'bx; c_needs_rs2_2 = 1'bx; c_add_2 = 1'bx; c_addw_2 = 1'bx; c_xor_2 = 1'bx; c_and_2 = 1'bx; c_or_2 = 1'bx; c_slt_2 = 1'bx; c_sltu_2 = 1'bx;
				c_inv_2 = 1'bx; c_sl_2 = 1'bx; c_sr_2 = 1'bx; c_in_pc_2 = 0; 
				c_mul_2 = 0; c_div_2 = 0;
				c_sgn_2 = 2'bxx;
				c_sub_push_2 = 0;
				c_sub_pop_2 = 0;
				c_inc2_2 = 1'bx;
				c_rs1_fp_2 = 0;  c_rs2_fp_2 = 0;  c_rs3_fp_2 = 0;  c_rd_fp_2 = 0;
			end
		end
	end

	reg [31:0]c_trap_ins;
	reg  [1:0]c_trap_out;
	assign trap_out = c_trap_out;
	assign trap_ins = c_trap_ins;

	always @(*) begin
		if (c_trap_1) begin
			if (partial_valid_in) begin
				c_trap_ins = {ins[15:0], partial_ins_in};
			end else begin
				c_trap_ins = {(ins[1:0]==3?ins[31:16]:16'b0), ins[15:0]};
			end
			c_trap_out = c_valid_out_1&!rename_stall?2'b01:2'b00;
		end else begin
			c_trap_ins = {16'b0, ins[31:16]};
			c_trap_out = c_trap_2&c_valid_out_2&!rename_stall?2'b10:2'b00;
		end
	end

`ifdef AWS_DEBUG
`ifdef NOTDEF
    ila_decode ila_decode(.clk(clk),
        .reset(reset),
		.xxtrig(xxtrig),
        .ins(ins),
        .valid(valid),
        .valid_in(valid_in),
        .c_trap_1(c_trap_1),
        .c_trap_2(c_trap_2),
        .valid_out_1(valid_out_1),
        .valid_out_2(valid_out_2),
		.valid_next(valid_next),
		.partial_valid_in(partial_valid_in),
		.first(first),
		.afterx(after), 
		.pc({pc[23:1],1'b0}),
		.c_jumping_term_1(c_jumping_term_1),
		.c_jumping_term_2(c_jumping_term_2),
		.pop_available(pop_available),
		.br_predict_1(x_br_predict_1),
		.br_predict_2(x_br_predict_2),
		.br_default(br_default));
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
