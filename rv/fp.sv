//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2020-23 Paul Campbell - paul@taniwha.com
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

module fpu(
	input clk,
`ifdef SIMD
    input simd_enable,
`endif

	input reset, 
	input enable,
	input rv32,

	input [CNTRL_SIZE-1:0]control,
	input     [LNCOMMIT-1:0]rd,
	input      [16:12]immed, 
	input	          makes_rd,
	input     [RV-1:0]fr1, fr2, fr3,		// FP ports
	input     [RV-1:0]ir1,				// IP port
	input   [(NHART==1?0:LNHART-1):0]hart,
	input        [2:0]fp_rounding,

	input [NCOMMIT-1:0]commit_kill_0,
	//input [NCOMMIT-1:0]commit_kill_1,

	output [RV-1:0]result,
	output [LNCOMMIT-1:0]res_rd, 
	output			res_makes_fp,			// true if we're writing bask to the FP registers
	output [NHART-1:0]res_makes_rd,
	output     [4:0]res_exceptions,
	output		    fpu_div_done
	);

    parameter CNTRL_SIZE=7;
	parameter RV=64;
    parameter ADDR=0;
    parameter NHART=1;
    parameter LNHART=0;
    parameter NCOMMIT = 32; // number of commit registers
    parameter LNCOMMIT = 5; // number of bits to encode that
 	parameter RA=5;

	//
	//	rounding mode in immed[14:12]
	//  xtra in immed[15]
	//  xtra2 in immed[16]
	//
	//	ctrl:
	//	6:5 size	2=H 1=D 0=S
	//  4 multiple
	//	3:0 - op 
	//    mult=0
	//		0 = fadd
	//		1 = fsub
	//		2 = fmul
	//		3 = fdiv
	//		4 = fsqrt
	//		5 = fsgn
	//		   mode==0 FSGNJ	
	//		   mode==1 FSGNJN
	//		   mode==2 FSGNJX
	//		6 = fmin/max
	//		   mode==0 FMIN	
	//		   mode==1 FMAX
	//		7 = fcvt/s/d
	//		   xtra2==0 FCVT.d.s
	//		   xtra2==1 FCVT.s.d
	//		8 = fcvt.w.
	//		   xtra==0 fcvt.w.*
	//		   xtra==1 fcvt.*.w
	//		9 = fcvt.wu.
	//		   xtra==0 fcvt.wu.*
	//		   xtra==1 fcvt.*.wu
	//		10 = fcvt.l.
	//		   xtra==0 fcvt.l.*
	//		   xtra==1 fcvt.*.l
	//		11 = fcvt.lu.
	//		   xtra==0 fcvt.lu.*
	//		   xtra==1 fcvt.*.lu
	//		12 = fcmp
	//			mode==0 fle
	//			mode==1 flt
	//			mode==2 feq
	//		13 = fclass
	//		14 = fmv
	//			xtra=0 FMV.X.D
	//			xtra=1 FMV.D.X
	//	   mult==1
	//		0 = fmadd	r1*r2+r3
	//		1 = fmsub	r1*r2-r3
	//		2 = fmnsub	-(r1*r2)+r3
	//		3 = fmnadd	-(r1*r2)-r3
	//
	//	rounding modes:
	//
	//		0 - RNE round to nearest, ties to even
	//		1 - RTZ round towards zero
	//		2 - RDN round downwards
	//		3 - RUP round upwards
	//		4 - RMM round to nearest, ties to max
	//		7 - DYN dynamic

	//
	//	32-bit format			64-bit format
	//
	//		31		- sign			63
	//		30:23	- exponent		62-52
	//			
	//		22:0	- fraction		51-0

	reg [RV-1:0]r_res, c_res;
	assign result = r_res;
	reg  [LNCOMMIT-1:0]r_res_rd, c_res_rd;
	assign res_rd = r_res_rd;
	reg  [NHART-1:0]r_res_makes_rd, c_res_makes_rd;
	assign res_makes_rd = r_res_makes_rd;
	reg  [4:0]r_res_exceptions, c_res_exceptions;
	assign res_exceptions = r_res_exceptions;
	reg	r_makes_rd;
	reg r_res_fp, c_res_fp;
	assign res_makes_fp = r_res_fp;

	wire [1:0]size = control[6:5];
	wire multiple = control[4];
	wire [2:0]rounding = (immed[14:12]==3'd7 ? fp_rounding:immed[14:12]);
	wire xtra = immed[15];
	wire [1:0]xtra2 = {immed[17:16]};
	wire [3:0]op = control[3:0];
	reg      r_xtra, r_multiple;
	reg [1:0]r_size;
	reg [1:0]r_xtra2;
	reg [3:0]r_op;
	reg [2:0]r_rounding;
	reg   [(NHART==1?0:LNHART-1):0]r_hart;
	reg  [LNCOMMIT-1:0]r_rd;

	reg r_start;
	always @(posedge clk)
		r_start <= enable;

	reg		fpu_div_done_out;
	wire	fpu_div_cancel;
	assign fpu_div_done = fpu_div_done_out|fpu_div_cancel;

	wire [RV-1:0]res_add;
	wire		valid_add;
	wire [4:0]add_exceptions;
	wire [LNCOMMIT-1:0]add_rd;
	wire [(NHART==1?0:LNHART-1):0]add_hart;
	fp_add_sub	#(.RV(RV), .LNHART(LNHART), .NHART(NHART), .LNCOMMIT(LNCOMMIT))fpadd(.clk(clk), .reset(reset), 
			.start(r_start && !r_multiple && r_op <= 1),
			.sz(r_size),	// double/single
			.sub(r_op[0]),
			.rd(r_rd),
			.hart(r_hart),
			.rnd(r_rounding),
			.in_1(fr1),
			.in_2(fr2),
			.exceptions(add_exceptions),
			.res(res_add),
			.rd_out(add_rd),
			.hart_out(add_hart),
			.valid(valid_add));

	
	wire [RV-1:0]res_mul;
	wire		valid_mul;
	wire [4:0]mul_exceptions;
	wire fmuladd = r_multiple;
	wire fmulsub = r_op[0];
	wire fmulsign = r_op[1];
	wire [LNCOMMIT-1:0]mul_rd;
	wire [(NHART==1?0:LNHART-1):0]mul_hart;
	fp_mul		#(.RV(RV), .LNHART(LNHART), .NHART(NHART), .LNCOMMIT(LNCOMMIT))fpmul(.clk(clk), .reset(reset),
			.start(r_start && (r_multiple || r_op == 2)),
            .sz(r_size),    // double/single
			.rd(r_rd),
			.hart(r_hart),
			.rnd(r_rounding),
			.in_1(fr1),
			.in_2(fr2),
			.in_3(fr3),
			.fmuladd(fmuladd),  // muladd
			.fmulsub(fmulsub),
			.fmulsign(fmulsign),
			.exceptions(mul_exceptions),
			.res(res_mul),
			.rd_out(mul_rd),
			.hart_out(mul_hart),
			.valid(valid_mul));

	wire [RV-1:0]res_div;
	wire		valid_div;
	wire [4:0]div_exceptions;
	wire [LNCOMMIT-1:0]div_rd;
	wire [(NHART==1?0:LNHART-1):0]div_hart;
	fp_div		#(.RV(RV), .LNHART(LNHART), .NHART(NHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT))fpdiv(.clk(clk), .reset(reset),
			.start(r_start&!r_multiple&(r_op == 3 || r_op == 4)),
            .sz(r_size),    // double/single
			.rd(r_rd),
			.hart(r_hart),
			.makes_rd(r_makes_rd),
			.rnd(r_rounding),
			.issqrt(r_op == 4),
			.in_1(fr1),
			.in_2(fr2),
			.commit_kill_0(commit_kill_0),
			//.commit_kill_1(commit_kill_1),
			.exceptions(div_exceptions),
			.res(res_div),
			.rd_out(div_rd),
			.hart_out(div_hart),
			.fpu_cancel(fpu_div_cancel),
			.valid(valid_div),
			.valid_ack(!r_start&!valid_mul&!valid_add));




	always @(posedge clk) begin
		r_xtra <= xtra;
		r_xtra2 <= xtra2;
		r_size <= size;
		r_multiple <= multiple;
		r_op <= op;
		r_hart <= hart;
		r_rounding <= rounding;
		r_rd <= rd;
	end

	reg clk_1;	// 1 clock ops
	reg nv, nx, of, uf;
	always @(*) begin
		nv = 0;
		nx = 0;
		of = 0;
		uf= 0;
		c_res_fp = (reset? 0:1);
		clk_1 = 0;
		casez ({valid_div, r_start, valid_mul, valid_add}) // synthesis full_case parallel_case
		4'b1000:begin
					c_res = res_div;
					c_res_fp = 1;
				end
		4'b??1?:begin
					c_res = res_mul;
					c_res_fp = 1;
				end
		4'b???1:begin
					c_res = res_add;
					c_res_fp = 1;
				end
		4'b?1??:
			case (r_op)	// synthesis full_case parallel_case
			3, //		3 = fdiv
			4: //		4 = fsqrt
				c_res = 0;
			5: //		5 = fsgn
				begin
					clk_1 = 1;
					case (r_rounding[1:0]) //synthesis full_case parallel_case
					0:	// fsgnj.q
						casez (r_size) //synthesis full_case parallel_case
						2'b1?: c_res = {fr1[63:16], fr2[15], fr1[14:0]};
						2'b?1: c_res = {fr2[63], fr1[62:0]};
						2'b00: c_res = {fr1[63:32], fr2[31], fr1[30:0]};
						endcase
					1:	// fsgnjn.q
						casez (r_size) //synthesis full_case parallel_case
						2'b1?: c_res = {fr1[63:16], ~fr2[15], fr1[14:0]};
						2'b?1: c_res = {~fr2[63], fr1[62:0]};
						2'b00: c_res = {fr1[63:32], ~fr2[31], fr1[30:0]};
						endcase
					2:	// fsgnjx.q
						casez (r_size) //synthesis full_case parallel_case
						2'b1?: c_res = {fr1[63:16], fr1[15]^fr2[15], fr1[14:0]};
						2'b?1: c_res = {fr1[63]^fr2[63], fr1[62:0]};
						2'b00: c_res = {fr1[63:32], fr1[31]^fr2[31], fr1[30:0]};
						endcase
					endcase
				end
			7:	//		7 = fcvt/s/d
				begin
					clk_1 = 1;
					// r_xtra2 = {immed[17:16]}
					// r_xtra2 = {immed[21:20]}
					casez ({r_size, r_xtra2}) //synthesis full_case parallel_case
					4'b00_01:	//FCVT.s.d  double->single
						if (fr1[62:52] == 11'h7ff) begin
							c_res = {32'hffff_ffff, fr1[63]&~|fr1[51:0], 8'hff, |fr1[51:0], 22'b0};
							nv = !fr1[51] && |fr1[50:0];
						end else begin :cvt
							reg [2:0]guard;
							reg inc, inc_exp;
							reg [7:0]cvt_exp;
							//
							// exp:     3ff -> 7f
							//			371	-> 01	-7e
							//			47e	-> fe   +7e
							cvt_exp = {fr1[62], fr1[58:52]};
							guard = {fr1[28:27], |fr1[26:0]};   // 51:29
							case (r_rounding) //synthesis full_case parallel_case
							0: inc = (guard > 4) || ((guard==4)&&fr1[29]);
							1: inc = 0;
							2: inc = fr1[63] && (guard!=0);
							3: inc = !fr1[63] && (guard!=0);
							4: inc = guard >= 4;
							endcase
							nx = guard != 0;
							inc_exp = inc && fr1[51:29] == 23'h7fffff;
							if (fr1[62:52] > 11'h47e || (inc_exp && fr1[62:52] == 11'h47e)) begin	// overflow
								of = 1;
								c_res = {32'hffff_ffff, fr1[63], 8'hff, 1'b0, 22'b0}; // inf
							end else
							if (fr1[62:52] < 11'h367) begin // OK
								nx = fr1[62:0]!=0;
								uf = fr1[62:0]!=0;
								c_res = {32'hffff_ffff, fr1[63], 31'b0};
							end else
							if (fr1[62:52] > 11'h380 || (inc_exp && fr1[62:52] == 11'h380)) begin // OK
								if (inc_exp) begin
                                       c_res = {32'hffff_ffff, fr1[63], cvt_exp+8'h1, 23'h0};
                                end else begin
                                       c_res = {32'hffff_ffff, fr1[63], cvt_exp, fr1[51:29]+{22'b0, inc}};
                                end
							end else begin : tx		// denorm
								reg [25:0]t;
								reg ainc;
								case (fr1[62:52])  //synthesis full_case parallel_case
								11'h367:	t = {25'b0, 1'b1};
								11'h368:	t = {24'b0, 1'b1, |fr1[51:0]};
`include "mkf4_d_s.inc"
								11'h380:	t = {1'b1, fr1[51:28], |fr1[27:0]};
								endcase
								case (r_rounding) //synthesis full_case parallel_case
								0: ainc = (t[2:0] > 4) | ((t[2:0]==4)&t[3]);
								1: ainc = 0;
								2: ainc = fr1[63] & (t[2:0]!=0);
								3: ainc = !fr1[63] & (t[2:0]!=0);
								4: ainc = t[2:0]>=4;
								endcase
								nx = nx | (t[2:0] != 0);
								c_res = {32'hffff_ffff, fr1[63], 8'h00, t[25:3]+{22'b0,ainc}};
							end
						end
					4'b01_00:	// FCVT.d.s  single->double
						if (fr1[63:32] != 32'hffff_ffff) begin	// bad
							c_res = {fr1[31], 11'h7ff, 1'b1, 51'h0};
						end else
						if (fr1[30:23] == 8'h00) begin  
							if (fr1[22:0] == 0) begin
								c_res = { fr1[31], 11'b0, 23'b0, 29'b0};
							end else begin	:den // need to un-denorm
								reg [51:0]m;
								reg [10:0]e;
								casez (fr1[22:0]) // synthesis full_case parallel_case
`include "mkf8_s_d.inc"
								endcase
								c_res = { fr1[31], e, m};
							end
						end else
						if (fr1[30:23] == 8'hff) begin  
							c_res = { fr1[31], 11'h7ff, fr1[22:0], 29'b0};
						end else begin
							c_res = { fr1[31], fr1[30], {3{~fr1[30]}}, fr1[29:23], fr1[22:0], 29'b0};
						end
                    4'b00_10:  // fcvt.s.h	half->single
						if (fr1[63:16] != 48'hffff_ffff_ffff) begin	// bad
							c_res = {32'hffff_ffff, fr1[15], 8'hff, 1'b1, 22'h0};
						end else
						if (fr1[14:10] == 5'h0) begin
							if (fr1[9:0] == 0) begin
								c_res = { 32'hffff_ffff,  fr1[15], 8'b0, 23'b0};
							end else begin	:denS // need to un-denorm
								reg [22:0]m;
								reg [7:0]e;
								casez (fr1[9:0]) // synthesis full_case parallel_case
`include "mkf8_h_s.inc"
								endcase
								c_res = { 32'hffff_ffff, fr1[15], e, m};
							end
						end else
						if (fr1[14:10] == 5'h1f) begin
							c_res = {32'hffff_ffff, fr1[15], 8'hff, fr1[9:0], 13'b0};
						end else begin
							c_res = { 32'hffff_ffff, fr1[15], fr1[14], {3{~fr1[14]}}, fr1[13:10], fr1[9:0], 13'b0};
						end
                    4'b01_10:  // fcvt.d.h	half->double
						if (fr1[63:16] != 48'hffff_ffff_ffff) begin	// bad
							c_res = {fr1[15], 11'h7ff, 1'b1, 51'h0};
						end else
						if (fr1[14:10] == 5'h00) begin
							if (fr1[22:0] == 0) begin
								c_res = { fr1[31], 11'b0, 23'b0, 29'b0};
							end else begin	:denH // need to un-denorm
								reg [51:0]m;
								reg [10:0]e;
								casez (fr1[9:0]) // synthesis full_case parallel_case
`include "mkf8_h_d.inc"
								endcase
								c_res = { fr1[15], e, m};
							end
						end else
						if (fr1[14:10] == 5'h1f) begin
							c_res = { fr1[15], 11'h7ff, fr1[9:0], 12'b0, 29'b0};
						end else begin
							c_res = { fr1[15], fr1[14], {6{~fr1[14]}}, fr1[13:10], fr1[9:0], 12'b0, 29'b0};
						end
                    4'b10_00:  // fcvt.h.s	single->half
						if (fr1[30:23] == 8'hff) begin
							c_res = {48'hffff_ffff_ffff, fr1[31]&~|fr1[22:0], 5'h1f, |fr1[22:0], 9'b0};
							nv = !fr1[22] && |fr1[21:0];
						end else begin :cvt_sh
							reg [2:0]guard;
							reg inc, inc_exp;
							reg [4:0]cvt_exp;
							//
							// exp:     3ff -> 7f
							//			371	-> 01	-7e
							//			47e	-> fe   +7e
							cvt_exp = {fr1[30], fr1[26:23]};
							guard = {fr1[12:11], |fr1[10:0]};   // 22:13
							case (r_rounding) //synthesis full_case parallel_case
							0: inc = (guard > 4) || ((guard==4)&&fr1[13]);
							1: inc = 0;
							2: inc = fr1[63] && (guard!=0);
							3: inc = !fr1[63] && (guard!=0);
							4: inc = guard >= 4;
							endcase
							nx = guard != 0;
							inc_exp = inc && fr1[22:13] == 10'h3ff;
							if (fr1[30:23] > (8'h8e) || (inc_exp && fr1[30:23] == 8'h8e)) begin	// overflow
								of = 1;
								c_res = {48'hffff_ffff_ffff, fr1[31], 5'h1f, 1'b0, 9'b0}; // inf
							end else
							if (fr1[30:23] < (8'h80-10)) begin // OK
								nx = fr1[30:0]!=0;
								uf = fr1[30:0]!=0;
								c_res = {48'hffff_ffff_ffff, fr1[31], 15'b0};
							end else
							if (fr1[30:23] > 8'h80 || (inc_exp && fr1[30:23] == 8'h80)) begin // OK
								if (inc_exp) begin
                                       c_res = {48'hffff_ffff_ffff, fr1[31], cvt_exp+5'h1, 10'h0};
                                end else begin
                                       c_res = {48'hffff_ffff_ffff, fr1[31], cvt_exp, fr1[22:13]+{9'b0, inc}};
                                end
							end else begin : tx		// denorm
								reg [12:0]t;
								reg ainc;
								case (fr1[30:23])  //synthesis full_case parallel_case
								8'h67:	t = {11'b0, 1'b1};
								8'h68:	t = {10'b0, 1'b1, |fr1[22:0]};
`include "mkf4_s_h.inc"
								8'h80:	t = {1'b1, fr1[22:14], |fr1[13:0]};
								endcase
								case (r_rounding) //synthesis full_case parallel_case
								0: ainc = (t[2:0] > 4) | ((t[2:0]==4)&t[3]);
								1: ainc = 0;
								2: ainc = fr1[31] & (t[2:0]!=0);
								3: ainc = !fr1[31] & (t[2:0]!=0);
								4: ainc = t[2:0]>=4;
								endcase
								nx = nx | (t[2:0] != 0);
								c_res = {48'hffff_ffff_ffff, fr1[31], 8'h00, t[12:3]+{9'b0,ainc}};
							end
						end
                    4'b10_01:  // fcvt.h.d	double->half
						if (fr1[62:52] == 11'h7ff) begin
							c_res = {48'hffff_ffff_ffff, fr1[63]&~|fr1[51:0], 5'h1f, |fr1[51:0], 9'b0};
							nv = !fr1[51] && |fr1[50:0];
						end else begin :cvt_hd
							reg [2:0]guard;
							reg inc, inc_exp;
							reg [4:0]cvt_exp;
							//
							// exp:     3ff -> 7f
							//			371	-> 01	-7e
							//			47e	-> fe   +7e
							cvt_exp = {fr1[62], fr1[55:52]};
							guard = {fr1[41:40], |fr1[39:0]};   // 51:42
							case (r_rounding) //synthesis full_case parallel_case
							0: inc = (guard > 4) || ((guard==4)&&fr1[42]);
							1: inc = 0;
							2: inc = fr1[63] && (guard!=0);
							3: inc = !fr1[63] && (guard!=0);
							4: inc = guard >= 4;
							endcase
							nx = guard != 0;
							inc_exp = inc && fr1[51:42] == 10'h3ff;
							if (fr1[62:52] > (11'h38e) || (inc_exp && fr1[62:52] == 11'h38e)) begin	// overflow
								of = 1;
								c_res = {48'hffff_ffff_ffff, fr1[63], 5'h1f, 1'b0, 9'b0}; // inf
							end else
							if (fr1[62:52] < (11'h380-10)) begin // OK
								nx = fr1[62:0]!=0;
								uf = fr1[62:0]!=0;
								c_res = {48'hffff_ffff_ffff, fr1[63], 15'b0};
							end else
							if (fr1[62:52] > 11'h380 || (inc_exp && fr1[62:52] == 11'h380)) begin // OK
								if (inc_exp) begin
                                       c_res = {48'hffff_ffff_ffff, fr1[63], cvt_exp+5'h1, 10'h0};
                                end else begin
                                       c_res = {48'hffff_ffff_ffff, fr1[63], cvt_exp, fr1[51:42]+{9'b0, inc}};
                                end
							end else begin : tx		// denorm
								reg [12:0]t;
								reg ainc;
								case (fr1[62:52])  //synthesis full_case parallel_case
								11'h367:	t = {11'b0, 1'b1};
								11'h368:	t = {10'b0, 1'b1, |fr1[51:0]};
`include "mkf4_d_s.inc"
								11'h380:	t = {1'b1, fr1[51:42], |fr1[41:0]};
								endcase
								case (r_rounding) //synthesis full_case parallel_case
								0: ainc = (t[2:0] > 4) | ((t[2:0]==4)&t[3]);
								1: ainc = 0;
								2: ainc = fr1[63] & (t[2:0]!=0);
								3: ainc = !fr1[63] & (t[2:0]!=0);
								4: ainc = t[2:0]>=4;
								endcase
								nx = nx | (t[2:0] != 0);
								c_res = {48'hffff_ffff_ffff, fr1[63], 8'h00, t[12:3]+{9'b0,ainc}};
							end
						end
					endcase
				end
			8, //		8 = fcvt.w.*
			9, //      9 = fcvt.wu.*
			10,//      10 = fcvt.l.*
			11://		11 = fcvt.lu.
				if (r_xtra) begin : s8 //		   xtra==1 fcvt.*.wlu
					reg sign;
					reg [63:0]t1, t2;
					reg [54:0]mantissa;
					reg [10:0]exponent;
					clk_1 = 1;
					case (r_op[1:0]) // synthesis full_case parallel_case
					2'b00:	begin	// w
								sign = ir1[31];
								t1 = {{32{ir1[31]}}, ir1[31:0]};
							end
					2'b01:	begin	// wu
								sign = 0;
								t1 = {32'b0, ir1[31:0]};
							end
					2'b10:	begin	// l
								sign = ir1[63];
								t1 = ir1[63:0];
							end
					2'b11:	begin	// lu
								sign = 0;
								t1 = ir1[63:0];
							end
					endcase
					t2 = (sign? ~t1:t1) + {63'b0, sign};
`include "mkf6.inc"
					casez (r_size) //synthesis full_case parallel_case
					2'b1?:
						begin : ffh
							reg [9:0]m3;
							reg [4:0]e3;
							reg [2:0]m;
							reg [10:0]exp;
							reg inc;
	
							m = {mantissa[47:46], |mantissa[45:0]};
							case (r_rounding) //synthesis full_case parallel_case
							0: inc = (m>4) || ((m==4) && mantissa[48]);
							1: inc = 0;
							2: inc =  sign && (m!=0);
							3: inc = !sign && (m!=0);
							4: inc = m >= 4;
							endcase
							nx = m != 0;
							m3 = (inc?mantissa[54:45]+1:mantissa[54:52]);
							exp = (inc && (mantissa[54:45]==(~10'h0))?exponent+11'b1:exponent);
							e3 = {exp[10], exp[3:0]};
							if (exp > 5'hf) begin
								c_res = {48'hffff_ffff_ffff, sign, 5'h1f, 10'b0};
								of = 1;
							end else begin
								c_res = {48'hffff_ffff_ffff, sign, e3, m3};
							end
						end
					2'b?1: begin :ffd
							reg [51:0]m3;
							reg [10:0]e3;
							reg [10:0]exp;
							reg inc;

							case (r_rounding) //synthesis full_case parallel_case
							0: inc = (mantissa[2:0]>4) || ((mantissa[2:0]==4) && mantissa[3]);
							1: inc = 0;
							2: inc =  sign && (mantissa[2:0]!=0);
							3: inc = !sign && (mantissa[2:0]!=0);
							4: inc = mantissa[2:0]>=4;
							endcase
							nx = mantissa[2:0]!=0;
							m3 = (inc?mantissa[54:3]+1:mantissa[54:3]);
							exp = (inc && (mantissa[54:3]==(~52'h0))?exponent+11'b1:exponent);
							e3 = exp;
							c_res = {sign, e3, m3};
						end
					2'b00:
						begin : ffs
							reg [22:0]m3;
							reg [7:0]e3;
							reg [2:0]m;
							reg [10:0]exp;
							reg inc;
	
							m = {mantissa[31:30], |mantissa[29:0]};
							case (r_rounding) //synthesis full_case parallel_case
							0: inc = (m>4) || ((m==4) && mantissa[32]);
							1: inc = 0;
							2: inc =  sign && (m!=0);
							3: inc = !sign && (m!=0);
							4: inc = m >= 4;
							endcase
							nx = m != 0;
							m3 = (inc?mantissa[54:32]+1:mantissa[54:32]);
							exp = (inc && (mantissa[54:32]==(~23'h0))?exponent+11'b1:exponent);
							e3 = {exp[10], exp[6:0]};
							c_res = {32'hffff_ffff, sign, e3, m3};
						end
					endcase
					c_res_fp = 1;
				end else begin :a8 //		   xtra==0 fcvt.wlu.*
					reg [66:0]t;
					reg sign, inc, nan, inf, xsign;
					reg zz, o, o2, z;
					reg over, under;
					reg [63:0]tt;
					reg [10:0]e;
					reg [52:0]m;

					clk_1 = 1;
					casez (r_size) //synthesis full_case parallel_case
					2'b1?: begin
							z = fr1[14:10]==0 && fr1[9:0]==0;
							sign = fr1[15]&~r_op[0];
							xsign = fr1[15];
							m = {~z, fr1[9:0], 42'b0}; 
							e = {fr1[14], {6{~fr1[14]}}, fr1[13:10]};
							over = ~fr1[15] && &fr1[14:10];
							under = fr1[15]&r_op[0] || (fr1[15] && &fr1[14:10]);
							nan = (fr1[14:10] == ~5'b0 && fr1[9:0] != 10'b00) || fr1[63:16] != ~48'b0;
							inf = fr1[14:10] == ~5'b0 && fr1[9:0] == 10'b00;
						   end
					2'b?1: begin
							z = fr1[62:52]==0 && fr1[51:0]==0;
							sign = fr1[63]&~r_op[0];
							xsign = fr1[63];
							m = {~z, fr1[51:0]};
							e = fr1[62:52];
							over = ~fr1[63] && &fr1[62:52];
							under = fr1[63]&r_op[0] || (fr1[63] && &fr1[62:52]);
							nan = fr1[62:52] == ~11'b0 && fr1[51:0] != 51'b00;
							inf = fr1[62:52] == ~11'b0 && fr1[51:0] == 51'b00;
						end		
					2'b00: begin
							z = fr1[30:23]==0 && fr1[22:0]==0;
							sign = fr1[31]&~r_op[0];
							xsign = fr1[31];
							m = {~z, fr1[22:0], 29'b0};
							e = {fr1[30], {3{~fr1[30]}}, fr1[29:23]};
							over = ~fr1[31] && &fr1[30:23];
							under = fr1[31]&r_op[0] || (fr1[31] && &fr1[30:23]);
							nan = (fr1[30:23] == ~8'b0 && fr1[22:0] != 23'b00) || fr1[63:32] != ~32'b0; 
							inf = fr1[30:23] == ~8'b0 && fr1[22:0] == 23'b00;
						end
					endcase
`include "mkf7.inc"
					case (r_rounding) //synthesis full_case parallel_case
					0: inc = (t[2:0] > 4) | ((t[2:0]==4)&t[3]);
					1: inc = 0;
					2: inc = xsign & (t[2:0]!=0);
					3: inc = !xsign & (t[2:0]!=0);
					4: inc = t[2:0]>=4;
					endcase
					tt = (sign ? ~t[66:3]:t[66:3])+{63'b0, inc^sign};	// convert sign
					// o2 is a prediction of overflow in the above calculation
					casez ({r_op[1:0], sign, inc}) // synthesis full_case parallel_case
					4'b10_00,
					4'b10_11: o2 = t[66]; 
					4'b11_00,
					4'b11_11: o2 = 0; 
					4'b00_00,
					4'b00_11: o2 = |t[65:35] | t[34] | &t[33:3] ; 
					4'b01_00,
					4'b01_11: o2 = |t[66:35]; 
					4'b10_01: o2 = &t[65:3] | t[66];
					4'b10_10: o2 = |t[65:3] & t[66];
					4'b11_01,
					4'b11_10: o2 = &t[66:3];
					4'b00_01: o2 = |t[66:35] | &t[33:3] | t[34];
					4'b00_10: o2 = |t[66:35] | (|t[33:3] & t[34]);
					4'b01_01,
					4'b01_10: o2 = |t[66:35] | &t[34:3];
					endcase
					nv = nan||over||o||o2||(xsign && r_op[0] && (inc || t[66:3]!=64'h0 || inf ));
					nx = t[2:0]!=0 && !nv;
					// 8  = fcvt.w.*
					// 9  = fcvt.wu.*
					// 10 = fcvt.l.*
					// 10 = fcvt.lu.*
					casez ({r_op[0], !nan&(under|((o|o2)&sign)|(inf&sign)), over|((o|o2|inf)&~sign)|nan, zz|z, r_op[1]}) // synthesis full_case parallel_case
					5'b?_000_0: c_res = {{32{tt[31]}}, tt[31:0]};
					//5'b1_000_0: c_res = {32'b0, tt[31:0]};
					5'b?_000_1: c_res = tt;
					5'b0_1??_1: c_res = {1'b1, 63'b0};
					5'b0_1??_0: c_res = {~33'b0, 31'b0};
					5'b1_1??_?: c_res = 64'b0;
					5'b0_?1?_1: c_res = {1'b0, ~63'b0};
					5'b0_?1?_0: c_res = {33'b0, ~31'b0};
					5'b1_?1?_1: c_res = ~64'b0;
					5'b1_?1?_0: c_res = ~64'b0;
					5'b?_??1_?: c_res = 64'b0;
					endcase
					c_res_fp = 0;
				end
			6,	//		6  = fmin/fmax
			12: //		12 = fcmp
				begin : cmp
					reg nan_a, nan_b, inf_a, inf_b, sign_a, sign_b;
					reg snan_a, snan_b, z_a, z_b;
					reg [10:0]exp_a, exp_b;
					reg [51:0]man_a, man_b;
					reg v;
					reg lt; 
					reg eq;

					clk_1 = 1;
					casez (r_size) // synthesis full_case parallel_case
					2'b1?: begin //h
							nan_a = (fr1[63:16] != 48'hffff_ffff_ffff) ||
									(fr1[14:10] == 5'h1f && fr1[9:0] != 10'b0);
							snan_a = !fr1[9] && (fr1[14:10] == 5'h1f && fr1[9:0] != 10'b0);
							nan_b = (fr2[63:16] != 48'hffff_ffff_ffff) ||
									(fr2[14:10] == 5'h1f && fr2[9:0] != 10'b0);
							snan_b = !fr2[9] && (fr2[14:10] == 5'h1f && fr2[9:0] != 10'b0);
							inf_a = (fr1[14:10] == 5'h1f && fr1[9:0] == 10'b0);
							inf_b = (fr2[14:10] == 5'h1f && fr2[9:0] == 10'b0);
							sign_a = fr1[15];
							sign_b = fr2[15];
							exp_a = {fr1[14], {6{~fr1[14]}}, fr1[13:10]};
							exp_b = {fr2[14], {6{~fr2[14]}}, fr2[13:10]};
							man_a = {fr1[9:0], 42'b0};
							man_b = {fr2[9:0], 42'b0};
							z_a = fr1[14:0]==0;
							z_b = fr2[14:0]==0;
						   end
					2'b?1: begin //d
							nan_a = (fr1[62:52] == 11'h7ff && fr1[51:0] != 52'b0);
							snan_a = !fr1[51] && nan_a;
							nan_b = (fr2[62:52] == 11'h7ff && fr2[51:0] != 52'b0);
							snan_b = !fr2[51] && nan_b;
							inf_a = (fr1[62:52] == 11'h7ff && fr1[51:0] == 52'b0);
							inf_b = (fr2[62:52] == 11'h7ff && fr2[51:0] == 52'b0);
							sign_a = fr1[63];
							sign_b = fr2[63];
							exp_a = fr1[62:52];
							exp_b = fr2[62:52];
							man_a = fr1[51:0];
							man_b = fr2[51:0];
							z_a = fr1[62:0]==0;
							z_b = fr2[62:0]==0;
						   end
					2'b00: begin //f
							nan_a = (fr1[63:32] != 32'hffff_ffff) ||
									(fr1[30:23] == 8'hff && fr1[22:0] != 23'b0);
							snan_a = !fr1[22] && (fr1[30:23] == 8'hff && fr1[22:0] != 23'b0);
							nan_b = (fr2[63:32] != 32'hffff_ffff) ||
									(fr2[30:23] == 8'hff && fr2[22:0] != 23'b0);
							snan_b = !fr2[22]&& (fr2[30:23] == 8'hff && fr2[22:0] != 23'b0);
							inf_a = (fr1[30:23] == 8'hff && fr1[22:0] == 23'b0);
							inf_b = (fr2[30:23] == 8'hff && fr2[22:0] == 23'b0);
							sign_a = fr1[31];
							sign_b = fr2[31];
							exp_a = {fr1[30], {3{~fr1[30]}}, fr1[29:23]};
							exp_b = {fr2[30], {3{~fr2[30]}}, fr2[29:23]};
							man_a = {fr1[22:0], 29'b0};
							man_b = {fr2[22:0], 29'b0};
							z_a = fr1[30:0]==0;
							z_b = fr2[30:0]==0;
						   end
					endcase

					if (nan_a || nan_b ) begin
						v = 0;
						eq = 1'bx;
						lt = 1'bx;
						nv = snan_a || snan_b || r_rounding[1:0]!=2;
					end else begin
						if (sign_a != sign_b) begin
							eq = z_a && z_b;
							lt = sign_a && !eq;
						end else
						if (inf_a || inf_b) begin
							if (inf_a && inf_b) begin
								eq = 1;
								lt = 0;
							end else begin
								eq = 0;
								lt = !(inf_a^sign_a);
							end
						end else
						if (exp_a != exp_b) begin
							eq = 0;
							lt = (exp_a < exp_b)^sign_a;
						end else
						if (man_a != man_b) begin
							eq = 0;
							lt = (man_a < man_b)^sign_a;
						end else begin
							eq = 1;
							lt = 0;
						end
						case (r_rounding[1:0]) //synthesis full_case parallel_case
						0: v = eq || lt; // fle
						1: v = lt;		 // flt
						2: v = eq;       // feq
						endcase
					end
					if (!r_op[3]) begin
						nv = snan_a || snan_b;
						case ({nan_a, nan_b})
						2'b01: c_res = fr1;
						2'b10: c_res = fr2;
						2'b11:
							casez (r_size) //synthesis full_case parallel_case
							2'b1?: c_res = 64'hffff_ffff_ffff_7e00;
							2'b?1: c_res = 64'h7FF8_0000_0000_0000;
							2'b00: c_res = 64'hffff_ffff_7Fc0_0000;
							endcase
						2'b00: c_res = ((eq?sign_a:lt)^r_rounding[0] ? fr1:fr2); // r_rounding[0] is fmin/fmax
						endcase
						c_res_fp = 1;
					end else begin
						c_res = {63'b0, v};
						c_res_fp = 0;
					end
				end
			13:	//		13 = fclass
				begin
					clk_1 = 1;
					casez (r_size) // synthesis full_case parallel_case
					2'b1?:
						c_res = {54'b0,
							/*9*/	((fr1[14:10] == 5'h1f) &  fr1[9]) | (fr1[63:16]!=48'hffff_ffff_ffff),
							/*8*/	(fr1[14:10] == 5'h1f) & ~fr1[9] & (fr1[8:0] != 9'b00) & (fr1[63:16]==48'hffff_ffff_ffff),
							/*7*/	~fr1[15] & (fr1[14:10] == 5'h1f) & (fr1[9:0] == 10'b0) & (fr1[63:16]==48'hffff_ffff_ffff),
							/*6*/	~fr1[15] & (fr1[14:10] != 5'h1f) & (fr1[14:10] != 5'h0) & (fr1[63:16]==48'hffff_ffff_ffff),
							/*5*/	~fr1[15] & (fr1[14:10] == 5'h0) & (fr1[63:16]==48'hffff_ffff_ffff) & (fr1[22:0] != 0),
							/*4*/	~fr1[15] & (fr1[14:0] == 15'h0) & (fr1[63:16]==48'hffff_ffff_ffff),
							/*3*/	fr1[15] & (fr1[14:0] == 15'h0) & (fr1[63:16]==48'hffff_ffff_ffff),
							/*2*/	fr1[15] & (fr1[14:10] == 5'h0) & (fr1[63:16]==48'hffff_ffff_ffff) & (fr1[22:0] != 0),
							/*1*/	fr1[15] & (fr1[14:10] != 5'h1f) & (fr1[14:10] != 5'h0) & (fr1[63:16]==48'hffff_ffff_ffff),
							/*0*/	fr1[15] & (fr1[14:10] == 5'h1f) & (fr1[9:0] == 10'b0) & (fr1[63:16]==48'hffff_ffff_ffff)
								};
					2'b?1:
						c_res = {54'b0,
							/*9 +qnan*/	(fr1[62:52] == 11'h7ff) & fr1[51],
							/*8 +snan*/	(fr1[62:52] == 11'h7ff) & ~fr1[51] & (fr1[50:0] != 52'b00),
							/*7 +inf */	~fr1[63] & (fr1[62:52] == 11'h7ff) & (fr1[51:0] == 52'b0),
							/*6 +    */	~fr1[63] & (fr1[62:52] != 11'h7ff) & (fr1[62:52] != 11'h0),
							/*5 +sub */	~fr1[63] & (fr1[62:52] == 11'h0) & (fr1[51:0] != 0),
							/*4 +0   */	~fr1[63] & (fr1[62:0] == 63'h0),
							/*3 -0   */	fr1[63] & (fr1[62:0] == 63'h0),
							/*2 -sub */	fr1[63] & (fr1[62:52] == 11'h0) & (fr1[51:0] != 0),
							/*1 -    */	fr1[63] & (fr1[62:52] != 11'h7ff) & (fr1[62:52] != 11'h0),
							/*0 -inf */	fr1[63] & (fr1[62:52] == 11'h7ff) & (fr1[51:0] == 52'b0)
							};
					2'b00:
						c_res = {54'b0,
							/*9*/	((fr1[30:23] == 8'hff) &  fr1[22]) | (fr1[63:32]!=32'hffff_ffff),
							/*8*/	(fr1[30:23] == 8'hff) & ~fr1[22] & (fr1[21:0] != 22'b00) & (fr1[63:32]==32'hffff_ffff),
							/*7*/	~fr1[31] & (fr1[30:23] == 8'hff) & (fr1[22:0] == 23'b0) & (fr1[63:32]==32'hffff_ffff),
							/*6*/	~fr1[31] & (fr1[30:23] != 8'hff) & (fr1[30:23] != 8'h0) & (fr1[63:32]==32'hffff_ffff),
							/*5*/	~fr1[31] & (fr1[30:23] == 8'h0) & (fr1[63:32]==32'hffff_ffff) & (fr1[22:0] != 0),
							/*4*/	~fr1[31] & (fr1[30:0] == 31'h0) & (fr1[63:32]==32'hffff_ffff),
							/*3*/	fr1[31] & (fr1[30:0] == 31'h0) & (fr1[63:32]==32'hffff_ffff),
							/*2*/	fr1[31] & (fr1[30:23] == 8'h0) & (fr1[63:32]==32'hffff_ffff) & (fr1[22:0] != 0),
							/*1*/	fr1[31] & (fr1[30:23] != 8'hff) & (fr1[30:23] != 8'h0) & (fr1[63:32]==32'hffff_ffff),
							/*0*/	fr1[31] & (fr1[30:23] == 8'hff) & (fr1[22:0] == 23'b0) & (fr1[63:32]==32'hffff_ffff)
								};
					endcase
					c_res_fp = 0;
				end
			14: //		14 = fmv
				if (r_xtra) begin	// FMV.D.X
					clk_1 = 1;
					casez (r_size) // synthesis full_case parallel_case
					2'b1?: c_res = {48'hffff_ffff_ffff, ir1[15:0]};
					2'b?1: c_res = ir1;
					2'b00: c_res = {32'hffff_ffff, ir1[31:0]};
					endcase
				end else begin				// FMV.X.D
					clk_1 = 1;
					casez (r_size) // synthesis full_case parallel_case
					2'b?1: c_res = fr1;
					2'b00: c_res = {{32{fr1[31]}}, fr1[31:0]};
					endcase
					c_res_fp = 0;
				end
			default: begin c_res_fp = 'bx; c_res = 'bx; end
			endcase
		endcase
		c_res_makes_rd = 0;
		fpu_div_done_out = 0;
		casez ({valid_div, r_start&!r_multiple&(r_op>=5), valid_add, valid_mul}) // synthesis full_case parallel_case
		4'b1000:begin
					c_res_makes_rd[div_hart] = 1;
					c_res_rd = div_rd;
					c_res_exceptions = div_exceptions;
					fpu_div_done_out = 1;
			    end
		4'b??1?:begin
					c_res_makes_rd[add_hart] = 1;
					c_res_rd = add_rd;
					c_res_exceptions = add_exceptions;
			    end
		4'b???1:begin
					c_res_makes_rd[mul_hart] = 1;
					c_res_rd = mul_rd;
					c_res_exceptions = mul_exceptions;
			    end
		4'b?1??:begin
					c_res_makes_rd[r_hart] = clk_1&r_start;
					c_res_rd = r_rd;
					c_res_exceptions = {nv, 1'b0, of, uf, nx};
			    end
		4'b0000:begin
					c_res_rd='bx;
					c_res_exceptions = 'bx;
				end
		endcase
	end

	always @(posedge clk) begin
        r_res_makes_rd <= c_res_makes_rd;
		r_res_rd <= c_res_rd;
		r_res_fp <= c_res_fp;
		r_res_exceptions <= c_res_exceptions;
		r_res <= c_res;
`ifdef SIMD
        if (|c_res_makes_rd && simd_enable) $display("F %d @ %x <- %x",$time,c_res_rd,c_res);
`endif
	end

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


