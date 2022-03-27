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


module branch(
    input clk,
    input reset,
	input enable,
`ifdef SIMD
	input simd_enable,
`endif

    input [CNTRL_SIZE-1:0]control,
    input [RV-1:0]r1, r2,
    input [31:0]immed,
    input [VA_SZ-1:1]pc,
    input [VA_SZ-1:1]branch_dest,
	input [LNCOMMIT-1:0]rd,
    input         makes_rd,
	input [NCOMMIT-1:0]commit_kill,

    output [LNCOMMIT-1:0]res_rd,
    output       res_makes_rd,
	output	     commit_br_enable, // not true if predicted correctly
	output [RV-1:1]commit_br,
    output [LNCOMMIT-1:0]commit_br_addr,
	output       commit_br_short,
	output [BDEC-1:1]commit_br_dec,
	output [RV-1:0]result
    );

    parameter CNTRL_SIZE=7;
    parameter NDEC = 4; // number of decode stages
    parameter ADDR=0;
 	parameter RV=64;
 	parameter VA_SZ=48;
    parameter NHART=1;
    parameter HART=0;
    parameter LNHART=0;
    parameter BDEC=4;
    parameter NCOMMIT = 32; // number of commit registers
    parameter LNCOMMIT = 5; // number of bits to encode that
    parameter RA=5;

	//
	//	ctrl:
	//	5	predicted
	//	4	short_pc (1= add 2 to get nextaddress othewise 4
	//	3	invert test (cjmp only)
	//	2:1	branch type (cjmp only) 0=eq, 1=lt, 2=ltu
	//	1       1=pc_rel 0 = r1_rel (jmp only)  
	//	0 	0=jmp, 1=cjmp
	//
	//	for cjmp predicted means "was predicted and taken"
	//	for !cjmp predicted means "we continued on, please check that our actual destination matches",
	//									not predicted means "we stalled waiting to be woken by the branch unit")
	//	

	reg [RV-1:0]r_res, c_res;
    assign result = r_res;
    reg  [LNCOMMIT-1:0]r_res_rd, r_rd;
	assign commit_br_addr = r_rd;
    assign res_rd = r_res_rd;
	reg [NHART-1:0]r_res_makes_rd;
    assign res_makes_rd = r_res_makes_rd;
	reg	[VA_SZ-1:1]r_pc, r_branch_dest;
	reg	[RV-1:1]new_address;
	assign commit_br_dec = r_pc[BDEC-1:1];
	reg	      need_jmp;
	assign commit_br = new_address;
	reg		short_pc, predicted;
	reg		make_jmp;
	assign commit_br_enable = make_jmp;

    wire     	inv, cjmp;
	wire	[1:0]tp;
	assign short_pc = control[4];
	assign predicted = control[5];
	assign inv = control[3];
	assign tp = control[2:1];
	assign cjmp = control[0];
    reg     r_inv, r_cjmp;
	reg	[1:0]r_tp;
	reg		r_enable;
	reg		r_makes_rd;
	reg		r_short_pc;
	assign commit_br_short = r_short_pc;
	reg		r_predicted;
	reg	[31:0]r_immed;

	reg		match;

	always @(posedge clk) begin
		r_res_rd <= r_rd;
		r_rd <= rd;
		r_enable <= !reset&enable&!commit_kill[rd];
        r_inv <= inv;
		r_cjmp <= cjmp;
		r_tp <= tp;
		r_makes_rd <= enable&makes_rd;
		r_short_pc <= short_pc;
		r_predicted <= predicted;
		r_pc <= pc;
		r_immed <= immed;
		r_branch_dest <= branch_dest;
`ifdef SIMD
if (commit_br_enable && simd_enable) $display("B %d %x %x->%x", $time,r_rd,{{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc,1'b0},{commit_br,1'b0});
`endif
	end

	wire signed [RV-1:0]s1 = r1;
	wire signed [RV-1:0]s2 = r2;
	always @(*) begin
		need_jmp = 1'bx;
		// note: check that only 1 adder is used here
		case (r_tp) // synthesis full_case parallel_case
		0: need_jmp = r1==r2;	// eq
		2: need_jmp = s1 < s2;		// signed lt
		3: need_jmp = r1 < r2;	// unsigned lt
		default: need_jmp = 1'bx;
		endcase
		make_jmp = r_enable&(r_cjmp?r_predicted^r_inv^need_jmp:!r_tp[0]&(!r_predicted|!match));
	end
	
	if (RV==64) begin

		always @(*) begin
			if (r_cjmp) begin
				new_address = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}+(r_predicted?(r_short_pc?63'd1:63'd2):{{31{r_immed[31]}}, r_immed[31:0]});
				match = 1'bx;
			end else begin :xt
				reg [63:0]t;
				t = r1[63:0]+{{32{r_immed[31]}},r_immed[31:0]};
				match = t[RV-1:1] == {{RV-VA_SZ{r_branch_dest[VA_SZ-1]}}, r_branch_dest};
				new_address = t[63:1];
			end
		end

		always @(posedge clk) 
			r_res <= {({{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}+(r_short_pc?63'd1:63'd2)), 1'b0};

	end else begin

		always @(*) begin
			if (r_cjmp) begin
				new_address = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}+(r_predicted?(r_short_pc?31'd1:31'd2):r_immed[30:0]);
			end else begin : xy
				reg [31:0]t;
				t = r1[31:0]+r_immed[31:0];
				match = t[RV-1:1] == branch_dest;
				new_address = t[31:1];
			end
		end

		always @(posedge clk) 
			r_res <= {({{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}+(r_short_pc?31'd1:31'd2)), 1'b0};

	end

	generate
		if (NHART == 1) begin
        		always @(posedge clk) 
                		r_res_makes_rd <= r_makes_rd;
		end else begin
			always @(posedge clk)
				r_res_makes_rd <= (r_makes_rd?1<<HART:0);
		end
	endgenerate


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


