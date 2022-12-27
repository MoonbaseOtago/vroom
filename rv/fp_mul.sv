//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2020-22 Paul Campbell - paul@taniwha.com
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

//
//	Mul/muladd - while this is synthesisable the intent here is to sketch out a 
//	3 clock FP mul-add block that makes the correct bits - the intent is that
//	a real implementation will involve a real hand built data path for 
//	speed 
//

module fp_mul(input reset, input clk, 
		input start, 
		input [1:0]sz,
		input [2:0]rnd,
		input [RV-1:0]in_1,
		input [RV-1:0]in_2,
		input [RV-1:0]in_3,
		input fmuladd,	// muladd
		input fmulsub,
		input fmulsign,
        input [LNCOMMIT-1:0]rd,
        input [(NHART==1?0:LNHART-1):0]hart,
		output exception,
		output valid,
		output [RV-1:0]res,
		output [LNCOMMIT-1:0]rd_out,
        output [(NHART==1?0:LNHART-1):0]hart_out
	);
	parameter RV=64;
	parameter LNCOMMIT=6;
	parameter NHART=1;
	parameter LNHART=1;

	reg [1:0]r_start;
	assign valid = r_start[1];
	always @(posedge clk)
	if (reset) begin
		r_start <= 0;
	end else begin
		r_start <= {r_start[0], start};
	end
	
	reg [4:0]r_b_rd;
	reg [4:0]r_c_rd;
	reg [(NHART==1?0:LNHART-1):0]r_b_hart;
	reg [(NHART==1?0:LNHART-1):0]r_c_hart;
	assign rd_out = r_c_rd;
	assign hart_out = r_c_hart;
	always @ (posedge clk) begin
		r_b_rd <= rd;
		r_c_rd <= r_b_rd;
		r_b_hart <= hart;
		r_c_hart <= r_b_hart;
	end
		

	
	reg is_nan_1, is_nan_2, is_nan_3;
	reg is_nan_signalling_1, is_nan_signalling_2, is_nan_signalling_3;
	reg is_infinity_1, is_infinity_2, is_infinity_3;
	reg sign_1, sign_2, sign_3;
	reg z_1, z_2, z_3;

	always @(*)
	casez (sz) // synthesis full_case parallel_case
	2'b1?: begin	// 16-bit
			is_nan_1 = (in_1[63:16]!=~48'b0) || ((in_1[14:10] == 5'h1f) && (in_1[9:0] != 0));
			is_nan_2 = (in_2[63:16]!=~48'b0) || ((in_2[14:10] == 5'h1f) && (in_2[9:0] != 0));
			is_nan_3 = (in_3[63:16]!=~48'b0) || ((in_3[14:10] == 5'h1f) && (in_3[9:0] != 0));
			is_nan_signalling_1 = in_1[9];
			is_nan_signalling_2 = in_2[9];
			is_nan_signalling_3 = in_3[9];
			is_infinity_1 = (in_1[14:10] == 5'h1f) && (in_1[9:0] == 0);
			is_infinity_2 = (in_2[14:10] == 5'h1f) && (in_2[9:0] == 0);
			is_infinity_3 = (in_3[14:10] == 5'h1f) && (in_3[9:0] == 0) && fmuladd;
			sign_1 = in_1[15];
			sign_2 = in_2[15];
			sign_3 = (in_3[15]^fmulsub) && fmuladd;
			z_1 = in_1[14:10]==8'b0;
			z_2 = in_2[14:10]==8'b0;
			z_3 = in_3[14:10]==8'b0 || !fmuladd;
		   end
	2'b?1: begin	// 64-bit
			is_nan_1 = ((in_1[62:52] == 11'h7ff) && (in_1[51:0] != 0));
			is_nan_2 = ((in_2[62:52] == 11'h7ff) && (in_2[51:0] != 0));
			is_nan_3 = ((in_3[62:52] == 11'h7ff) && (in_3[51:0] != 0)) && fmuladd;
			is_nan_signalling_1 = in_1[51];
			is_nan_signalling_2 = in_2[51];
			is_nan_signalling_3 = in_3[51] && fmuladd;
			is_infinity_1 = (in_1[62:52] == 11'h7ff) && (in_1[51:0] == 0);
			is_infinity_2 = (in_2[62:52] == 11'h7ff) && (in_2[51:0] == 0);
			is_infinity_3 = (in_3[62:52] == 11'h7ff) && (in_3[51:0] == 0) && fmuladd;
			sign_1 = in_1[63];
			sign_2 = in_2[63];
			sign_3 = (in_3[63]^fmulsub) && fmuladd;
			z_1 = in_1[62:52]==11'b0;
			z_2 = in_2[62:52]==11'b0;
			z_3 = in_3[62:52]==11'b0  || !fmuladd;
		   end
	2'b00: begin	// 32-bit
			is_nan_1 = (in_1[63:32]!=~32'b0) || ((in_1[30:23] == 8'hff) && (in_1[22:0] != 0));
			is_nan_2 = (in_2[63:32]!=~32'b0) || ((in_2[30:23] == 8'hff) && (in_2[22:0] != 0));
			is_nan_3 = (in_3[63:32]!=~32'b0) || ((in_3[30:23] == 8'hff) && (in_3[22:0] != 0));
			is_nan_signalling_1 = in_1[22];
			is_nan_signalling_2 = in_2[22];
			is_nan_signalling_3 = in_3[22];
			is_infinity_1 = (in_1[30:23] == 8'hff) && (in_1[22:0] == 0);
			is_infinity_2 = (in_2[30:23] == 8'hff) && (in_2[22:0] == 0);
			is_infinity_3 = (in_3[30:23] == 8'hff) && (in_3[22:0] == 0) && fmuladd;
			sign_1 = in_1[31];
			sign_2 = in_2[31];
			sign_3 = (in_3[31]^fmulsub) && fmuladd;
			z_1 = in_1[30:23]==8'b0;
			z_2 = in_2[30:23]==8'b0;
			z_3 = in_3[30:23]==8'b0 || !fmuladd;
		   end
	endcase

	wire in_eq_sign_3 = fmuladd && (sign_1^sign_2)==sign_3 && mantissa_3==0;
	
	assign exception = is_nan_1&is_nan_signalling_1 || is_nan_2&is_nan_signalling_2 || fmuladd&&is_nan_3&is_nan_signalling_3;
	wire nan = is_nan_1 ||
			   is_nan_2 ||
			   //(is_infinity_1&&is_infinity_2&&sign_1!=sign_2) ||
			   (is_nan_3 && fmuladd) ||
			   (is_infinity_2 && z_1 && (mantissa_1==0)) ||
			   (is_infinity_1 && z_2 && (mantissa_2==0)) ||
			   (infinity&is_infinity_3&((sign_1^sign_2) != sign_3));
	wire infinity = is_infinity_1 || is_infinity_2;
	wire infinity_sign = (infinity&(sign_1)^(sign_2))|(is_infinity_3&sign_3);

	assign sign = sign_1^sign_2^(fmuladd&fmulsign);


	reg signed [11:0]exps_1;
	reg signed [11:0]exps_2;
	reg signed [11:0]exps_3;

	wire signed [11:0]exp_sum = (exps_1+exps_2+12'h1);
	
	// mantissa's:
	//
	//  integer .    fraction - guard bits
	//	57-55   .      54-3       2-0			64-bit
	//	57-55   .      54-32      31-29			32-bit
	// 
	reg [52:0]mantissa_1;
	reg [52:0]mantissa_2;
	reg [52:0]mantissa_3;
	always @(*)
	casez (sz) // synthesis full_case parallel_case
	2'b1?: begin
			mantissa_1 = {z_1?1'b0:1'b1, in_1[9:0], 42'b0};
			mantissa_2 = {z_2?1'b0:1'b1, in_2[9:0], 42'b0};
			mantissa_3 = {z_3?1'b0:1'b1, in_3[9:0], 42'b0};
			exps_1 = z_1?{~8'b0, 4'b1} : {{8{~in_1[14]}}, in_1[13:10]}; 
			exps_2 = z_2?{~8'b0, 4'b1} : {{8{~in_2[14]}}, in_2[13:10]}; 
			exps_3 = z_3?{~8'b0, 4'b1} : {{8{~in_3[14]}}, in_3[13:10]};
		   end
	2'b?1: begin
			mantissa_1 = {z_1?1'b0:1'b1, in_1[51:0]};
			mantissa_2 = {z_2?1'b0:1'b1, in_2[51:0]};
			mantissa_3 = {z_3?1'b0:1'b1, in_3[51:0]};
			exps_1 = z_1?{2'b11, 10'h1}:{{2{~in_1[62]}}, in_1[61:52]};
			exps_2 = z_2?{2'b11, 10'h1}:{{2{~in_2[62]}}, in_2[61:52]};
			exps_3 = z_3?{2'b11, 10'h1}:{{2{~in_3[62]}}, in_3[61:52]};
		   end
	2'b00: begin
			mantissa_1 = {z_1?1'b0:1'b1, in_1[22:0], 29'b0};
			mantissa_2 = {z_2?1'b0:1'b1, in_2[22:0], 29'b0};
			mantissa_3 = {z_3?1'b0:1'b1, in_3[22:0], 29'b0};
			exps_1 = z_1?{~5'b0, 7'b1}:{{5{~in_1[30]}}, in_1[29:23]}; 
			exps_2 = z_2?{~5'b0, 7'b1}:{{5{~in_2[30]}}, in_2[29:23]}; 
			exps_3 = z_3?{~5'b0, 7'b1}:{{5{~in_3[30]}}, in_3[29:23]};
		   end
	endcase

	// these are for debug, tossed by synthesis
	wire [22:0]m32_1= in_1[22:0];
	wire [22:0]m32_2= in_2[22:0];
	wire [7:0]e32_1 = in_1[30:23];
	wire [7:0]e32_2 = in_2[30:23];
	wire [7:0]e32_s = exp_sum[10:3];

`ifdef NOTDEF
	reg r_a_sign;
	reg [11:0]r_a_exp_sum;
	reg [52:0]r_a_mantissa_1, r_a_mantissa_2;
	reg [2:0]r_a_rnd;
	reg r_a_nan;
	reg [1:0]r_a_sz;
	reg r_a_exception;
	reg r_a_infinity;
	reg r_a_infinity_sign;
	always @(posedge clk) begin
		r_a_rnd <= rnd;
		r_a_sign <= sign;
		r_a_exp_sum <= exp_sum;
		r_a_mantissa_1 <= mantissa_1;
		r_a_mantissa_2 <= mantissa_2;
		r_a_nan <= nan;
		r_a_sz <= sz;
		r_a_exception <= exception;
		r_a_infinity <= infinity;
		r_a_infinity_sign <= infinity_sign;
	end
`endif

	// here we have a 2-clock 53-bit unsigned multiplier
	// actual instances will replace it with an appropriate macro bock
	reg	      r_b_sign;
	reg	      r_b_sign_3;
	reg signed [11:0]r_b_exp_sum;
	reg [52:0]r_b_mantissa_1;
	reg [52:0]r_b_mantissa_2;
	reg [56:0]r_b_mantissa_3;
	reg signed [11:0]r_b_exp_3;
	reg  [2:0]r_b_rnd;
	reg	 [1:0]r_b_sz;
	reg		  r_b_nan;
	reg		  r_b_exception;
	reg		  r_b_infinity_3;
	reg		  r_b_infinity;
	reg		  r_b_infinity_sign;
	reg		  r_b_muladd;
	reg		  r_b_eq_sign_3;

	always @(posedge clk) begin
		r_b_sign <= sign;
		r_b_sign_3 <= sign_3;
		r_b_exp_sum <= exp_sum;
		r_b_mantissa_1 <= mantissa_1;
		r_b_mantissa_2 <= mantissa_2;
		r_b_mantissa_3 <= (sign_3^sign? (~{1'b0, mantissa_3, 3'b0})+57'b1 : {1'b0, mantissa_3, 3'b0});
		r_b_exp_3  <= fmuladd ? exps_3:exp_sum;
		r_b_nan <= nan;
		r_b_sz <= sz;
		r_b_rnd <= rnd;
		r_b_exception <= exception;
		r_b_infinity <= infinity;
		r_b_infinity_3 <= is_infinity_3;
		r_b_infinity_sign <= infinity_sign;
		r_b_muladd <= fmuladd;
		r_b_eq_sign_3 <= in_eq_sign_3;
	end


	reg		  r_c_sign;
	reg		  r_c_sign_3;
	reg signed [11:0]r_c_exp_sum;
	reg [110:0]r_c_mantissa;
	reg		  r_c_nan;
	reg	 [1:0]r_c_sz;
	reg  [2:0]r_c_rnd;
	reg		  r_c_exception;
	reg		  r_c_infinity;
	reg		  r_c_infinity_3;
	reg		  r_c_infinity_sign;
	reg		  r_c_muladd;
	reg		  r_c_eq_sign_3;

	wire [105:0]mantissa_m = {53'b0,r_b_mantissa_1}*{53'b0,r_b_mantissa_2};
	wire	   m_0 = r_b_mantissa_1==53'b0 || r_b_mantissa_2==53'b0;
	reg signed [11:0]b_exp_sum;

	always @(*)
	casez (r_b_sz) // synthesis full_case parallel_case
	2'b1?:	b_exp_sum = m_0 ? 12'hfe1 : r_b_exp_sum;
	2'b?1:  b_exp_sum = m_0 ? 12'hc01 : r_b_exp_sum;
	2'b00:	b_exp_sum = m_0 ? 12'hf01 : r_b_exp_sum;
	endcase

	reg [109:0]mantissa_s;
	reg [109:0]mantissa_s_3;
	
	wire signed [11:0]mdiff = r_b_exp_3-b_exp_sum;
	// some verilogs don;t do signed math correctly
	//wire gt = r_b_exp_3 > b_exp_sum;
	wire gt = r_b_exp_3[11]==b_exp_sum[11] ? r_b_exp_3[10:0] > b_exp_sum[10:0] : !r_b_exp_3[11];
	wire eq = r_b_exp_3 == b_exp_sum;

`include "mkf9.inc"	


	always @(posedge clk) begin
		r_c_sign <= r_b_sign;
		r_c_sign_3 <= r_b_sign_3;
		r_c_exp_sum <= gt ?r_b_exp_3:b_exp_sum;
		r_c_mantissa <= {1'b0, mantissa_s}+{mantissa_s_3[109], mantissa_s_3};
		r_c_rnd <= r_b_rnd;
		r_c_nan <= r_b_nan;
		r_c_sz <= r_b_sz;
		r_c_exception <= r_b_exception;
		r_c_infinity <= r_b_infinity;
		r_c_infinity_3 <= r_b_infinity_3;
		r_c_infinity_sign <= r_b_infinity_sign;
		r_c_muladd <= r_b_muladd;
		r_c_eq_sign_3 <= r_b_eq_sign_3;
;
	end
	/// end custom core


	wire [109:0]mantissa_n = r_c_mantissa[110] ? (~r_c_mantissa[109:0])+110'b1 : r_c_mantissa[109:0];

	reg [7:0]shl, shl_x;
	reg [9:0]shr;
	reg [55:0]mantissa_zz;
	reg [55:0]mantissa_z;
	reg [1:0]shr_x;

`include "mkf3.inc"	

	always @(*)
	casez (r_c_sz) // synthesis full_case parallel_case
	2'b1?: mantissa_z = {mantissa_zz[55:43], |mantissa_zz[42:0],  42'bx};
	2'b?1: mantissa_z = mantissa_zz;
	2'b00: mantissa_z = {mantissa_zz[55:30], |mantissa_zz[29:0],  29'bx};
	endcase
	

	// but we need to adjust the exponent too 

	reg signed [11:0]exponent;
	reg signed [11:0]exponent_t;
	reg inc;
	reg calc_infinity, calc_infinity_t;
	reg under;
reg [3:0]debug;
	always @(*) begin
		calc_infinity_t = 0;
		shl ='bx;
		shr = 0;
		under = 0;
		underflow = 0;
debug=0;
		
		casez (r_c_sz) // synthesis full_case parallel_case
		2'b1?: under = r_c_exp_sum[11] && r_c_exp_sum[10:4]!=7'b111_1111;
		2'b?1: under = r_c_exp_sum[11] && r_c_exp_sum[10]!=1'b1;
		2'b00: under = r_c_exp_sum[11] && r_c_exp_sum[10:7]!=4'b1111;
		endcase
		if (under) begin 
debug=1;
			casez (r_c_sz) // synthesis full_case parallel_case
			2'b1?: begin
						//shr = {8'h01,shr_x}-{{3{r_c_exp_sum[11]}},r_c_exp_sum[11:3]};
						shr = ({6'b0, ~r_c_exp_sum[3:0]})+2;
						underflow = shr > 12;
				   end
			2'b?1: begin 
						//shr = {11'b01,shr_x}-r_c_exp_sum[11:0];
						shr = (~r_c_exp_sum[9:0])+2;
						underflow = shr > 54;
debug=2;
				   end
			2'b00: begin
						//shr = {8'h01,shr_x}-{{3{r_c_exp_sum[11]}},r_c_exp_sum[11:3]};
						shr = ({3'b0, ~r_c_exp_sum[6:0]})+2;
						underflow = shr > 25;
				   end
			endcase
			exponent_t = 12'hc00;
		end else
		casez (shr_x) // synthesis full_case parallel_case
		2'b1?: begin
					shr = 2;
					if (!r_c_exp_sum[11] && r_c_exp_sum[10:0] >= 12'h7fd)
						calc_infinity_t = 1;
					exponent_t = r_c_exp_sum+2;
debug=7;
			   end
		2'b?1: begin
					shr = 1;
					if (!r_c_exp_sum[11] && r_c_exp_sum[10:0] >= 12'h7fe)
						calc_infinity_t = 1;
					exponent_t = r_c_exp_sum+1;
debug=3;
			   end
		2'b00: begin
				casez (r_c_sz) // synthesis full_case parallel_case
				2'b1?: begin : x
						reg [11:0]tmp;
						tmp = r_c_exp_sum+16;
						if (shl_x < tmp) begin
debug=4;
							shl = shl_x;
							exponent_t = r_c_exp_sum-shl_x;
						end else begin
debug=5;
							shl = r_c_exp_sum == 12'hff0 ? 0:r_c_exp_sum+15;
							shr = r_c_exp_sum == 12'hff0;
							exponent_t = 12'hff0;
						end
					   end
				2'b?1: begin
						if (r_c_exp_sum[11:10] != 2'b11 || shl_x < r_c_exp_sum[9:0]) begin
debug=4;
							shl = shl_x;
							exponent_t = r_c_exp_sum-shl_x;
						end else begin
debug=5;
							shl = r_c_exp_sum[9:0]==0 ? 0:r_c_exp_sum[9:0]-1;
							shr = r_c_exp_sum[9:0]==0;
							exponent_t = 12'h800;
						end
				       end
				2'b00: begin
						if (r_c_exp_sum[11:7] != 5'h1f || shl_x < r_c_exp_sum[6:0]) begin
debug=4;
							shl = shl_x;
							exponent_t = r_c_exp_sum-shl_x;
						end else begin
debug=5;
							shl = r_c_exp_sum[6:0]==0 ? 0:r_c_exp_sum[6:0]-1;
							shr = r_c_exp_sum[6:0]==0;
							exponent_t = 12'hf80;
						end
				       end
				endcase
			   end
		endcase
	end

	wire c_sign = r_c_mantissa[110]^r_c_sign;

	reg		  is_zero, rsign, underflow;
	always @(*) begin
		rsign = c_sign;
		if (is_zero) begin
			// some underflow signalling needed here
			exponent = 12'hc00;
			calc_infinity = calc_infinity_t;
			rsign = !r_c_muladd ? c_sign :
				                  r_c_mantissa == 111'b0 ? (r_c_eq_sign_3 ? r_c_sign_3 : (r_c_rnd==2)&(r_c_sign_3^c_sign)) :
																      ((r_c_rnd==2)?(x_underflow ||c_sign) : c_sign);
		end else
		if (exponent_t[11:10] == 2'b01) begin
			exponent = 'bx;
			calc_infinity = 1;
		end else
		if (inc) begin
			casez (r_c_sz) // synthesis full_case parallel_case
			2'b1?: begin
						exponent = exponent_t+12'h1;
						calc_infinity = calc_infinity_t || (!exponent_t[11] && exponent_t[10:0] >= 12'h00e);
				   end
			2'b?1: begin
						exponent = exponent_t+12'b1;
						calc_infinity = calc_infinity_t || (!exponent_t[11] && exponent_t[10:0] >= 12'h3fe );
				   end
			2'b00: begin
						exponent = exponent_t+12'h1;
						calc_infinity = calc_infinity_t || (!exponent_t[11] && exponent_t[10:0] >= 12'h07e);
				   end
			endcase
		end else begin
			exponent = exponent_t;
			calc_infinity = calc_infinity_t;
			casez (r_c_sz) // synthesis full_case parallel_case
			2'b1?: begin
						calc_infinity = calc_infinity_t || (!exponent_t[11] && exponent_t[10:0] >= 12'h00f);
				   end
			2'b?1: begin
						calc_infinity = calc_infinity_t || (!exponent_t[11] && exponent_t[10:0] >= 12'h3ff);
				   end
			2'b00: begin
						calc_infinity = calc_infinity_t || (!exponent_t[11] && exponent_t[10:0] >= 12'h07f);
				   end
			endcase
		end
	end


	reg [54:3]mantissa;
	reg x_underflow;
	always @(*) begin
		mantissa = mantissa_z[54:3];
		inc = 0;
		x_underflow = 0;
		case (r_c_rnd) // synthesis full_case parallel_case
		0:	//      0 - RNE round to nearest, ties to even
			casez (r_c_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (mantissa_z[44:42] > 4 || (mantissa_z[44:42]==4 && mantissa_z[45])) begin
							mantissa = {mantissa_z[54:45]+10'h1,42'bx};
							inc =  mantissa_z[54:45] == ~10'h0;
						end
				   end
			2'b?1: begin
						if (mantissa_z[2:0] > 4 || (mantissa_z[2:0]==4 && mantissa_z[3])) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  mantissa_z[54:3] == ~52'h0;
						end
				   end
			2'b00: begin
						if (mantissa_z[31:29] > 4 || (mantissa_z[31:29]==4 && mantissa_z[32])) begin
							mantissa = {mantissa_z[54:32]+24'h1,29'bx};
							inc =  mantissa_z[54:32] == ~23'h0;
						end
				   end
			endcase
		1:	//      1 - RTZ round towards zero
			;
		2:	//      2 - RDN round downwards
			casez (r_c_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (mantissa_z[44:42]!=0 && c_sign) begin
							mantissa = {mantissa_z[54:45]+10'h1,42'bx};
							inc =  mantissa_z[54:45] == ~10'h0;
							x_underflow = 1;
						end
				   end
			2'b?1: begin
						if (mantissa_z[2:0]!=0 && c_sign) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  mantissa_z[54:3] == ~52'h0;
							x_underflow = 1;
						end
				   end
			2'b00: begin
						if (mantissa_z[31:29]!=0 && c_sign) begin
							mantissa = {mantissa_z[54:32]+24'h1,29'bx};
							inc =  mantissa_z[54:32] == ~23'h0;
							x_underflow = 1;
						end
				   end
			endcase
		3:	//      3 - RUP round upwards
			casez (r_c_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (mantissa_z[44:42]!=0 && !c_sign) begin
							mantissa = {mantissa_z[54:45]+19'h1,42'bx};
							inc =  mantissa_z[54:45] == ~10'h0;
							x_underflow = 1;
						end
				   end
			2'b?1: begin
						if (mantissa_z[2:0]!=0 && !c_sign) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  mantissa_z[54:3] == ~52'h0;
							x_underflow = 1;
						end
				   end
			2'b00: begin
						if (mantissa_z[31:29]!=0 && !c_sign) begin
							mantissa = {mantissa_z[54:32]+24'h1,29'bx};
							inc =  mantissa_z[54:32] == ~23'h0;
							x_underflow = 1;
						end
				   end
			endcase
		4:	//      4 - RMM round to nearest, ties to max
			casez (r_c_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (mantissa_z[44:42] >= 4) begin
							mantissa = {mantissa_z[54:45]+10'h1, 42'bx};
							inc =  mantissa_z[54:45] == ~10'h0;
						end
				   end
			2'b?1: begin
						if (mantissa_z[2:0] >= 4) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  mantissa_z[54:3] == ~52'h0;
						end
				   end
			2'b00: begin
						if (mantissa_z[31:29] >= 4) begin
							mantissa = {mantissa_z[54:32]+24'h1, 29'bx};
							inc =  mantissa_z[54:32] == ~23'h0;
						end
				   end
			endcase
		default: begin inc = 'bx; mantissa = 'bx; end
		endcase
		casez (r_c_sz) // synthesis full_case parallel_case
		2'b1?: is_zero = mantissa_z[55:45] == 0 && !inc;
		2'b?1: is_zero = mantissa_z[55:3] == 0 && !inc;
		2'b00: is_zero = mantissa_z[55:32] == 0 && !inc;
		endcase
	end

	wire round_down_from_infinity = (r_c_rnd==1)||(r_c_rnd==2&&!c_sign)||(r_c_rnd==3&&c_sign);

	reg [63:0]out;
	always @(*) begin
		casez (r_c_sz) // synthesis full_case parallel_case
		2'b1?: begin
					if (r_c_nan) begin
						out = {48'hffff_ffff_ffff, 6'h1f, 10'h200};	// quiet nan
					end else
					if (r_c_infinity|calc_infinity|r_c_infinity_3) begin
						if (round_down_from_infinity&!r_c_infinity&!r_c_infinity_3) begin
							out = {48'hffff_ffff_ffff, c_sign, 5'h1e, 10'h3ff};	
						end else begin
							out = {48'hffff_ffff_ffff, r_c_infinity?r_c_infinity_sign:r_c_infinity_3?r_c_sign_3:c_sign, 5'h1f, 10'h0};	
						end
					end else
					if (underflow&!x_underflow) begin
						out = {48'hffff_ffff_ffff, rsign, 5'b0, 10'h0};
					end else begin
						out = {48'hffff_ffff_ffff, rsign, ~exponent[11], exponent[3:0], mantissa[54:45]};
					end
			   end
		2'b?1: begin
					if (r_c_nan) begin
						out = {12'h7ff, 52'h8000000000000};	// quiet nan
					end else
					if (r_c_infinity|calc_infinity|r_c_infinity_3) begin
						if (round_down_from_infinity&!r_c_infinity&!r_c_infinity_3) begin
							out = {c_sign, 11'h7fe, 52'hf_ffff_ffff_ffff};	
						end else begin
							out = {r_c_infinity?r_c_infinity_sign:r_c_infinity_3?r_c_sign_3:c_sign, 11'h7ff, 52'h0};	
						end
					end else
					if (underflow&!x_underflow) begin
						out = {rsign, 11'b0, 52'h0};
					end else begin
						out = {rsign, ~exponent[11], exponent[9:0], mantissa[54:3]};
					end
			   end
		2'b00: begin
					if (r_c_nan) begin
						out = {32'hffff_ffff, 9'h0ff, 23'h400000};	// quiet nan
					end else
					if (r_c_infinity|calc_infinity|r_c_infinity_3) begin
						if (round_down_from_infinity&!r_c_infinity&!r_c_infinity_3) begin
							out = {32'hffff_ffff, c_sign, 8'hfe, 23'h7fffff};	
						end else begin
							out = {32'hffff_ffff, r_c_infinity?r_c_infinity_sign:r_c_infinity_3?r_c_sign_3:c_sign, 8'hff, 23'h0};	
						end
					end else
					if (underflow&!x_underflow) begin
						out = {32'hffff_ffff, rsign, 8'b0, 23'h0};
					end else begin
						out = {32'hffff_ffff, rsign, ~exponent[11], exponent[6:0], mantissa[54:32]};
					end
			   end
		endcase
	end 
	assign res = out;
	
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


