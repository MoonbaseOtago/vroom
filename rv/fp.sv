//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2020-21 Paul Campbell - paul@taniwha.com
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
	output [NHART-1:0]res_makes_rd
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
	//	5 size	1=D 0=S
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
	//			mode==0 fle
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
	reg	r_makes_rd;
	reg r_res_fp, c_res_fp;
	assign res_makes_fp = r_res_fp;

	wire size = control[5];
	wire multiple = control[4];
	wire [2:0]rounding = (immed[14:12]==3'd7 ? fp_rounding:immed[14:12]);
	wire xtra = immed[15];
	wire xtra2 = immed[16];
	wire [3:0]op = control[3:0];
	reg r_xtra, r_xtra2, r_size, r_multiple;
	reg [3:0]r_op;
	reg [2:0]r_rounding;
	reg   [(NHART==1?0:LNHART-1):0]r_hart;
	reg  [LNCOMMIT-1:0]r_rd;

	reg r_start;
	always @(posedge clk)
		r_start <= enable;
	

	wire [RV-1:0]res_add;
	wire		valid_add;
	fp_add_sub	#(.RV(RV))fpadd(.clk(clk), .reset(reset), 
			.start(r_start && !r_multiple && r_op <= 1),
			.sz(r_size),	// double/single
			.sub(r_op[0]),
			.rnd(r_rounding),
			.in_1(fr1),
			.in_2(fr2),
			.exception(add_exception),
			.res(res_add),
			.valid(valid_add));

	
	wire [RV-1:0]res_mul;
	wire		valid_mul;
	//wire fmuladd = 
	fp_mul		#(.RV(RV))fpmul(.clk(clk), .reset(reset),
			.start(start_mul),
            .sz(r_size),    // double/single
			.rnd(r_rounding),
			.in_1(fr1),
			.in_2(fr2),
			.in_3(fr3),
			.fmuladd(fmuladd),  // muladd
			.fmulsub(fmulsub),
			.fmulsign(fmulsign),
			.exception(mul_exception),
			.res(res_mul),
			.valid(valid_mul));




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
	always @(*) begin
		c_res_fp = (reset? 0:1);
		clk_1 = 0;
		if (r_multiple) begin
		end else begin
			casez ({valid_mul, valid_add}) // synthesis full_case parallel_case
			2'b1?:	c_res = res_mul;
			2'b?1:	c_res = res_add;
			2'b00:
				case (r_op)	// synthesis full_case parallel_case
				3, //		3 = fdiv
				4: //		4 = fsqrt
					c_res = 0;
				5: //		5 = fsgn
					begin
						clk_1 = 1;
						case (r_rounding[1:0]) //synthesis full_case parallel_case
						0:	// fsgnj.q
							c_res = r_size? {fr2[63], fr1[62:0]}         : {fr1[63:32], fr2[31], fr1[30:0]};
						1:	// fsgnjn.q
							c_res = r_size? {~fr2[63], fr1[62:0]}        : {fr1[63:32], ~fr2[31], fr1[30:0]};
						2:	// fsgnjx.q
							c_res = r_size? {fr1[63]^fr2[63], fr1[62:0]} : {fr1[63:32], fr1[31]^fr2[31], fr1[30:0]};
						endcase
					end
				6: //		6 = fmin/max
					begin
						clk_1 = 1;
						if (r_rounding[0]) begin	// FMAX
						end else begin				// FMIN
						end
					end
				7:	//		7 = fcvt/s/d
					begin
						clk_1 = 1;
						if (r_xtra2) begin //		   xtra2==1 FCVT.s.d  double->single
							if (fr1[62:52] == 11'h7ff) begin
								c_res = {32'hffff_ffff, fr1[63], 8'hff, fr1[51], fr1[50:0]==51'b0 ? 51'b0:51'b01};
							end else begin :cvt
								reg [2:0]guard;
								reg inc, inc_exp;
								reg [7:0]cvt_exp;
								reg [10:0]cvt_expl;
								//
								// exp:     3ff -> 7f
								//			371	-> 01	-7e
								//			47e	-> fe   +7e
								cvt_expl = fr1[62:52]-(11'h3ff-11'h7f);
								cvt_exp = cvt_expl[7:0];
								guard = {fr1[28:27], |fr1[26:0]};   // 51:29
								case (r_rounding) //synthesis full_case parallel_case
								0: inc = (guard > 4) || ((guard==4)&&fr1[29]);
								1: inc = 0;
								2: inc = fr1[63] && (guard!=0);
								3: inc = !fr1[63] && (guard!=0);
								4: inc = guard >= 4;
								endcase
								inc_exp = inc && fr1[51:29] == 23'h7fffff;
								
								if (fr1[62:52] == 11'h7ff) begin
									c_res = {32'hffff_ffff, fr1[63], 8'hff, fr1[51], fr1[50:0]==51'b0 ? 51'b0:51'b01};
								end else 
								if (fr1[62:52] > 11'h47e || (inc_exp && fr1[62:52] == 11'h47e)) begin	// overflow
									c_res = {32'hffff_ffff, fr1[63], 8'hff, 1'b1, 51'b01};
								end else 
								if (fr1[62:52] >= 11'h371 || inc_exp && fr1[62:52] == 11'h370 ) begin // OK
									if (inc_exp) begin
										c_res = {32'hffff_ffff, fr1[63], cvt_exp+8'h1, 23'h0};
									end else begin
										c_res = {32'hffff_ffff, fr1[63], cvt_exp, fr1[51:29]+{22'b0, inc}};
									end
								end else begin : tx
									reg [25:0]t;
									reg ainc;
									case (fr1[62:52])  //synthesis full_case parallel_case
									11'h370:	t = {fr1[51:27], |fr1[26:0]}; 
`include "mkf4.inc"
									default:	t = {25'b0, |fr1[51:0]};
									endcase
									case (r_rounding) //synthesis full_case parallel_case
									0: ainc = (t[2:0] > 4) | ((t[2:0]==4)&t[3]);
									1: ainc = 0;
									2: ainc = fr1[63] & (t[2:0]!=0);
									3: ainc = !fr1[63] & (t[2:0]!=0);
									4: ainc = t[2:0]>=4;
									endcase
									c_res = {32'hffff_ffff, fr1[63], 8'h00, t[25:3]+{22'b0,ainc}};
								end
							end
						end else begin	 //		   xtra2==0 FCVT.d.s  single->double
							if (fr1[63:32] != 32'hffff_ffff) begin	// bad
								c_res = {fr1[31], 11'h7ff, 52'h1};
							end else begin
								c_res = { fr1[31], {3{fr1[30]}}, fr1[30:23], fr1[22:0], 29'b0};
							end
						end
					end
				8, //		8 = fcvt.w.*
				9, //      9 = fcvt.wu.*
				10,//      10 = fcvt.l.*
				11://		11 = fcvt.lu.
					if (r_xtra) begin : s8 //		   xtra==1 fcvt.*.wlu
						reg sign;
						reg [63:0]m1, m2;
						clk_1 = 1;
						sign = (r_op[1]?ir1[63]:ir1[31])&r_op[0];
						m1 = (r_op[1] ? ir1[63:0] : {ir1[31:0], 32'h0});
						if (sign) begin
							m2 = (~m1)+64'b1;
						end else begin
							m2 = m1;
						end
`include "mkf6.inc"
						c_res_fp = 1;
					end else begin :a8 //		   xtra==0 fcvt.wlu.*
						reg [66:0]t;
						reg sign, inc;
						reg u, o, o2, z;
						reg over, under;
						reg [63:0]tt;
						reg [10:0]e;
						reg [52:0]m;

						clk_1 = 1;
						if (r_size) begin
							sign = fr1[63]&~r_op[0];
							m = {1'b1, fr1[51:0]};
							e = fr1[62:52];
							z = fr1[62:52]==0 && m[51:0]==0;
							over = ~fr1[63] && &fr1[62:52];
							under = fr1[63]&r_op[0] || (fr1[63] && &fr1[62:52]);
						end else begin
							sign = fr1[31]&~r_op[0];
							m = {1'b1, fr1[22:0], 29'b0};
							e = {fr1[30], {2{fr1[30]}}, fr1[29:23]};
							z = fr1[30:23]==0 && m[22:0]==0;
							over = ~fr1[31] && &fr1[30:23];
							under = fr1[31]&r_op[0] || (fr1[31] && &fr1[30:23]);
						end
`include "mkf7.inc"
						case (r_rounding) //synthesis full_case parallel_case
						0: inc = (t[2:0] > 4) | ((t[2:0]==4)&t[3]);
						1: inc = 0;
						2: inc = fr1[63] & (t[2:0]!=0);
						3: inc = !fr1[63] & (t[2:0]!=0);
						4: inc = t[2:0]>=4;
						endcase
						tt = (sign ? ~t[66:3]:t[66:3])+{63'b0, inc^sign};	// convert sign
						// o2 is a prediction of overflow in then above calculation
						casez ({r_op[1:0], sign, inc}) // synthesis full_case parallel_case
						4'b10_00,
						4'b10_11: o2 = t[66]; 
						4'b11_00,
						4'b11_11: o2 = 0; 
						4'b00_00,
						4'b00_11: o2 = &t[65:66-32]|t[34]; 
						4'b01_00,
						4'b01_11: o2 = &t[66:66-32]; 
						4'b10_01: o2 = ~|t[65:3]|t[66];
						4'b10_10: o2 = &t[65:3]|t[66];
						4'b11_01: o2 = ~|t[66:3];
						4'b11_10: o2 = &t[66:3];
						4'b00_01: o2 = ~|t[33:3] | t[34];
						4'b00_10: o2 = &t[33:3]  | t[34];
						4'b01_01: o2 = ~|t[34:3];
						4'b01_10: o2 = &t[34:3];
						endcase
						casez ({r_op[0], u|under|((o|o2)&sign), over|((o|o2)&~sign), z, r_op[1]}) // synthesis full_case parallel_case
						5'b?_000_?: c_res = tt;
						5'b0_1??_1: c_res = {1'b1, 63'b0};
						5'b0_1??_0: c_res = {~33'b0, 31'b0};
						5'b1_1??_?: c_res = 64'b0;
						5'b0_?1?_1: c_res = {1'b0, ~63'b0};
						5'b0_?1?_0: c_res = {33'b0, ~31'b0};
						5'b1_?1?_?: c_res = ~64'b0;
						5'b?_??1_?: c_res = 64'b0;
						endcase
						c_res_fp = 0;
					end
				12: //		12 = fcmp
					begin : cmp
						reg v;
						reg nan_a, nan_b, inf_a, inf_b, sign_a, sign_b;
						reg [10:0]exp_a, exp_b;
						reg [51:0]man_a, man_b;
						clk_1 = 1;
						nan_a = (r_size? (fr1[62:52] == 11'h7ff && fr1[51:0] != 52'b0) :
									   (fr1[63:32] != 32'hffff_ffff) ||
										(fr1[30:23] == 8'hff && fr1[22:0] != 23'b0));
						nan_b = (r_size? (fr2[62:52] == 11'h7ff && fr2[51:0] != 52'b0) :
									   (fr2[63:32] != 32'hffff_ffff) ||
										(fr2[30:23] == 8'hff && fr2[22:0] != 23'b0));
						inf_a = (r_size? (fr1[62:52] == 11'h7ff && fr1[51:0] == 52'b0) :
									   (fr1[30:23] == 8'hff && fr1[22:0] == 23'b0));
						inf_b = (r_size? (fr2[62:52] == 11'h7ff && fr2[51:0] == 52'b0) :
									   (fr2[30:23] == 8'hff && fr2[22:0] == 23'b0));
						sign_a = (r_size ? fr1[63] : fr1[31]);
						sign_b = (r_size ? fr2[63] : fr2[31]);
						exp_a = (r_size? fr1[62:52] : {fr1[30:23], 3'b0});
						exp_b = (r_size? fr2[62:52] : {fr2[30:23], 3'b0});
						man_a = (r_size ? fr1[51:0] : {fr1[22:0], 29'b0});
						man_b = (r_size ? fr2[51:0] : {fr2[22:0], 29'b0});
						if (nan_a || nan_b ) begin
							v = 0;
						end else begin
							reg eq, lt; 
							
							if (sign_a != sign_b) begin
								lt = sign_a;
								eq = 0;
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
							0: v = eq && lt; // fle
							1: v = lt;		 // flt
							2: v = eq;       // feq
							endcase
						end
						c_res = {63'b0, v};
						c_res_fp = 0;
					end
				13:	//		13 = fclass
					begin
						clk_1 = 1;
						if (r_size) begin
							c_res = {54'b0,
								/*9*/	(fr1[62:52] == 11'h7ff) & fr1[22] & (fr1[50:0] != 51'b0),
								/*8*/	(fr1[62:52] == 11'h7ff) & ~fr1[22] & (fr1[50:0] != 51'b0),
								/*7*/	~fr1[63] & (fr1[62:52] == 11'h7ff) & (fr1[51:0] == 52'b0),
								/*6*/	~fr1[63] & (fr1[62:52] != 11'h7ff) & (fr1[62:52] != 11'h0),
								/*5*/	~fr1[63] & (fr1[62:52] == 11'h0),
								/*4*/	~fr1[63] & (fr1[62:0] == 63'h0),
								/*3*/	fr1[63] & (fr1[62:0] == 63'h0),
								/*2*/	fr1[63] & (fr1[62:52] == 11'h0),
								/*1*/	fr1[63] & (fr1[62:52] != 11'h7ff) & (fr1[62:52] != 11'h0),
								/*0*/	fr1[63] & (fr1[62:52] == 11'h7ff) & (fr1[51:0] == 52'b0)
								};
						end else begin
							c_res = {54'b0,
								/*9*/	(fr1[30:23] == 8'hff) & fr1[22] & (fr1[21:0] != 23'b0) & (fr1[63:32]==32'hffff_ffff),
								/*8*/	(fr1[30:23] == 8'hff) & ~fr1[22] & (fr1[21:0] != 23'b0) | (fr1[63:32]==32'hffff_ffff),
								/*7*/	~fr1[31] & (fr1[30:23] == 8'hff) & (fr1[22:0] == 23'b0) & (fr1[63:32]==32'hffff_ffff),
								/*6*/	~fr1[31] & (fr1[30:23] != 8'hff) & (fr1[30:23] != 8'h0) & (fr1[63:32]==32'hffff_ffff),
								/*5*/	~fr1[31] & (fr1[30:23] == 8'h0) & (fr1[63:32]==32'hffff_ffff),
								/*4*/	~fr1[31] & (fr1[30:0] == 31'h0) & (fr1[63:32]==32'hffff_ffff),
								/*3*/	fr1[31] & (fr1[30:0] == 31'h0) & (fr1[63:32]==32'hffff_ffff),
								/*2*/	fr1[31] & (fr1[30:23] == 8'h0) & (fr1[63:32]==32'hffff_ffff),
								/*1*/	fr1[31] & (fr1[30:23] != 8'hff) & (fr1[30:23] != 8'h0) & (fr1[63:32]==32'hffff_ffff),
								/*0*/	fr1[31] & (fr1[30:23] == 8'hff) & (fr1[22:0] == 23'b0) & (fr1[63:32]==32'hffff_ffff)
									};
						end
						c_res_fp = 0;
					end
				14: //		14 = fmv
					if (r_xtra) begin	// FMV.D.X
						clk_1 = 1;
						if (r_size) begin
							c_res = ir1;
						end else begin
							c_res = {32'hffff_ffff, ir1[31:0]};
						end
					end else begin				// FMV.X.D
						clk_1 = 1;
						if (r_size) begin
							c_res = fr1;
						end else begin
							c_res = {{32{fr1[31]}}, fr1[31:0]};
						end
						c_res_fp = 0;
					end
				default: begin c_res_fp = 'bx; c_res = 'bx; end
				endcase
			endcase
		end
		c_res_rd = r_rd;
		c_res_makes_rd = 0;
		c_res_makes_rd[r_hart] = clk_1&r_start;
	end

	always @(posedge clk) begin
        r_res_makes_rd <= c_res_makes_rd;
		r_res_rd <= c_res_rd;
		r_res_fp <= c_res_fp;
		r_res <= c_res;
`ifdef SIMD
        if (|c_res_makes_rd && simd_enable) $display("F %d @ %x <- %x",$time,r_rd,c_res);
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


