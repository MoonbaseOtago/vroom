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

//
//	add - while this is synthesisable the intent here is to sketch out a 
//	2 clock FP add block that makes the correct bits - the intent is that
//	a real implementation will involve a real hand built data path for 
//	speed 
//

module fp_add_sub(input reset, input clk, 
		input [1:0]sz,
		input sub,
		input start,
		input [2:0]rnd,
		input [RV-1:0]in_1,
		input [RV-1:0]in_2,
		input [LNCOMMIT-1:0]rd,
		input [(NHART==1?0:LNHART-1):0]hart,
		output valid,
		output [4:0]exceptions,
		output [RV-1:0]res,
		output [LNCOMMIT-1:0]rd_out,
		output [(NHART==1?0:LNHART-1):0]hart_out
	);
	parameter RV=64;
	parameter LNCOMMIT=6;
	parameter NHART=1;
	parameter LNHART=1;

	reg r_start;
	assign valid = r_start;
	always @(posedge clk)
	if (reset) begin
		r_start <= 0;
	end else begin
		r_start <= start;
	end

	reg is_nan_1, is_nan_2, is_nan_signalling_1, is_nan_signalling_2, is_infinity_1, is_infinity_2;
	reg	sign_1, sign_2;
	reg [10:0]exp_1, rexp_1;
	reg [10:0]exp_2, rexp_2;
	reg	boxed_nan_1, boxed_nan_2;
	

	always @(*)
	casez (sz)  // synthesis full_case parallel_case
	2'b1?:	begin
				boxed_nan_1 = (in_1[63:16]!=~48'b0);
				boxed_nan_2 = (in_2[63:16]!=~48'b0);
				is_nan_1 = ((in_1[14:10] == 5'h1f) && (in_1[9:0] != 0)) || boxed_nan_1;
				is_nan_2 = ((in_2[14:10] == 5'h1f) && (in_2[9:0] != 0)) || boxed_nan_2;
				is_nan_signalling_1 = !in_1[9] || boxed_nan_1;
				is_nan_signalling_2 = !in_2[9] || boxed_nan_2;
				is_infinity_1 = (in_1[14:10] == 5'h1f) && (in_1[9:0] == 0);
				is_infinity_2 = (in_2[14:10] == 5'h1f) && (in_2[9:0] == 0);
				sign_1 = in_1[15];
				sign_2 = in_2[15]^(sub&~is_nan_2);
				exp_1 = {in_1[14:10],6'b0};
				rexp_1 = in_1[14:10]==0? {5'h1, 6'b0} : {in_1[14:10],6'b0};
				exp_2 = {in_2[14:10],6'b0};
				rexp_2 = in_2[14:10]==0? {5'h1, 6'b0} : {in_2[14:10],6'b0};
			end
	2'b?1:	begin
				boxed_nan_1 = 0;
				boxed_nan_2 = 0;
				is_nan_1 = ((in_1[62:52] == 11'h7ff) && (in_1[51:0] != 0));
				is_nan_2 = ((in_2[62:52] == 11'h7ff) && (in_2[51:0] != 0));
				is_nan_signalling_1 = !in_1[51] || boxed_nan_1;
				is_nan_signalling_2 = !in_2[51] || boxed_nan_2;
				is_infinity_1 = (in_1[62:52] == 11'h7ff) && (in_1[51:0] == 0);
				is_infinity_2 = (in_2[62:52] == 11'h7ff) && (in_2[51:0] == 0);
				sign_1 = in_1[63];
				sign_2 = in_2[63]^(sub&~is_nan_2);
				exp_1 = in_1[62:52];
				rexp_1 = in_1[62:52]==0? 11'h1 : in_1[62:52];
				exp_2 = in_2[62:52];
				rexp_2 = in_2[62:52]==0? 11'h1 : in_2[62:52];
			end
	2'b00:	begin
				boxed_nan_1 = (in_1[63:32]!=~32'b0);
				boxed_nan_2 = (in_2[63:32]!=~32'b0);
				is_nan_1 = ((in_1[30:23] == 8'hff) && (in_1[22:0] != 0)) || boxed_nan_1;
				is_nan_2 = ((in_2[30:23] == 8'hff) && (in_2[22:0] != 0)) || boxed_nan_2;
				is_nan_signalling_1 = !in_1[22] || boxed_nan_1;
				is_nan_signalling_2 = !in_2[22] || boxed_nan_2;
				is_infinity_1 = (in_1[30:23] == 8'hff) && (in_1[22:0] == 0);
				is_infinity_2 = (in_2[30:23] == 8'hff) && (in_2[22:0] == 0);
				sign_1 = in_1[31];
				sign_2 = in_2[31]^(sub&~is_nan_2);
				exp_1 = {in_1[30:23],3'b0};
				rexp_1 = in_1[30:23]==0? {8'h1, 3'b0} : {in_1[30:23],3'b0};
				exp_2 = {in_2[30:23],3'b0};
				rexp_2 = in_2[30:23]==0? {8'h1, 3'b0} : {in_2[30:23],3'b0};
			end
	endcase

	assign bad_infinity = (is_infinity_1&&is_infinity_2&&(sign_1!=sign_2));
	
	assign a_nan_quiet = !(is_nan_1&is_nan_signalling_1 || is_nan_2&is_nan_signalling_2 || bad_infinity);
	wire nan = is_nan_1 || is_nan_2 || bad_infinity;
	wire infinity = is_infinity_1 || is_infinity_2;
	wire infinity_sign = (is_infinity_1&sign_1) || (is_infinity_2&sign_2);



	wire exp_gt = rexp_1 > rexp_2;
	wire exp_eq = rexp_1 == rexp_2;
	wire [10:0]exp_diff = rexp_1-rexp_2;
	
	// mantissa's:
	//
	//  integer .    fraction - guard bits
	//	57-55   .      54-3       2-0			64-bit
	//	57-55   .      54-32      31-29			32-bit
	// 
	reg [55:0]mantissa_1;
	reg [55:0]mantissa_2;
	reg	      mantissa_1_0, mantissa_2_0;

	always @(*)
	casez (sz)  // synthesis full_case parallel_case
	2'b1?:	begin
				mantissa_1 = {exp_1==0?1'b0:1'b1, in_1[9:0], 3'b0, 42'bx};
				mantissa_1_0 = in_1[9:0]==10'b0;
				mantissa_2 = {exp_2==0?1'b0:1'b1, in_2[9:0], 3'b0, 42'bx};
				mantissa_2_0 = in_2[9:0]==10'b0;
			end
	2'b?1:	begin
				mantissa_1 = {exp_1==0?1'b0:1'b1, in_1[51:0], 3'b0};
				mantissa_1_0 = in_1[51:0]==52'b0;
				mantissa_2 = {exp_2==0?1'b0:1'b1, in_2[51:0], 3'b0};
				mantissa_2_0 = in_2[51:0]==52'b0;
			end
	2'b00:	begin
				mantissa_1 = {exp_1==0?1'b0:1'b1, in_1[22:0], 3'b0, 29'bx};
				mantissa_1_0 = in_1[22:0]==23'b0;
				mantissa_2 = {exp_2==0?1'b0:1'b1, in_2[22:0], 3'b0, 29'bx};
				mantissa_2_0 = in_2[22:0]==23'b0;
			end
	endcase

	// these are for debug, tossed by synthesis
	wire [22:0]m32_1= in_1[22:0];
	wire [22:0]m32_2= in_2[22:0];
	wire [7:0]e32_1 = in_1[30:23];
	wire [7:0]e32_2 = in_2[30:23];
	wire [7:0]e32_d = exp_diff[10:3];

	reg [51+3+1:0]shifted_mantissa_1;
	reg [51+3+1:0]shifted_mantissa_2;
	reg [10:0]exponent_x;

	wire in_is_0 = mantissa_1_0 && mantissa_2_0 && exp_1 == 0 && exp_2 == 0;
	wire in_eq_sign = in_is_0 && sign_1 == sign_2;

	// pull in denormalisation mux
	//	makes shifted_mantissa_1, shifted_mantissa_2, exponent
`include "mkf1.inc"	

	reg	cin;
	reg sign_x;
	reg [56:0]c_a_mantissa_1, c_a_mantissa_2;

	always @(*) begin
		c_a_mantissa_1 = {1'b0,shifted_mantissa_1};
		c_a_mantissa_2 = {1'b0,shifted_mantissa_2};
		if (sign_1) begin
			//if (sub?!sign_2:sign_2) begin
			if (sign_2) begin
				sign_x = 1;
				cin = 0;
			end else begin
				sign_x = 0;
				cin = 1;
				c_a_mantissa_1 = ~{1'b0, shifted_mantissa_1};
			end
		end else begin
			sign_x = 0;
			//if (sub?!sign_2:sign_2) begin
			if (sign_2) begin
				cin = 1;
				c_a_mantissa_2 = ~{1'b0, shifted_mantissa_2};
			end else begin
				cin = 0;
			end
		end
	end

	reg [57:0]c_mantissa_x;
	always @(*) 
	casez (sz) // synthesis full_case parallel_case
	2'b1?: c_mantissa_x = {{c_a_mantissa_1[56], c_a_mantissa_1[56:42]} + {c_a_mantissa_2[56], c_a_mantissa_2[56:42]} + {27'b0, cin}, 42'bx};
	2'b?1: c_mantissa_x = {c_a_mantissa_1[56], c_a_mantissa_1} + {c_a_mantissa_2[56], c_a_mantissa_2} + {57'b0, cin};
	2'b00: c_mantissa_x = {{c_a_mantissa_1[56], c_a_mantissa_1[56:29]} + {c_a_mantissa_2[56], c_a_mantissa_2[56:29]} + {27'b0, cin}, 29'bx};
	endcase

	wire c_sign = sign_x ^ c_mantissa_x[57];

	reg [57:0]r_b_mantissa;
	reg  [1:0]r_b_sz;
	reg		  r_b_nan, r_b_infinity, r_b_infinity_sign, r_b_sign, r_b_eq_sign, r_b_nan_quiet;
	reg [10:0]r_b_exponent;
	reg  [2:0]r_b_rnd;
	reg [LNCOMMIT-1:0]r_b_rd;
	assign rd_out = r_b_rd;
	reg  [(NHART==1?0:LNHART-1):0]r_b_hart;
	assign hart_out=r_b_hart;
	
	always @(posedge clk) begin
		r_b_mantissa <= c_mantissa_x;
		r_b_sz <= sz;
        r_b_nan_quiet <= a_nan_quiet;
        r_b_nan <= nan;
        r_b_infinity <= infinity;
        r_b_infinity_sign <= infinity_sign;
        r_b_sign <= c_sign;
		r_b_exponent <= exponent_x;
		r_b_rnd <= rnd;
		r_b_rd <= rd;
		r_b_eq_sign <= in_eq_sign;
	end

	reg [56:0]mantissa_y;
	always @(*) 
	casez (r_b_sz) // synthesis full_case parallel_case
	2'b1?: mantissa_y = ({r_b_mantissa[57]? ((~r_b_mantissa[56:42])+13'b1):r_b_mantissa[56:42], 42'bx});
	2'b?1: mantissa_y = ( r_b_mantissa[57]? ((~r_b_mantissa[56:0])+57'b1) :r_b_mantissa[56:0]);
	2'b00: mantissa_y = ({r_b_mantissa[57]? ((~r_b_mantissa[56:29])+28'b1):r_b_mantissa[56:29], 29'bx});
	endcase
	
	reg [5:0]shl_x;
	reg [5:0]shl;
	reg      calc_infinity;
	reg		 shr;
	reg [55:0]mantissa_z;
	// renorm - shr/shl_x give us how to move

`include "mkf2.inc"	

	// but we need to adjust the exponent too 

	reg [10:0]exponent;
	reg [10:0]exponent_t;
	reg inc;
	reg calc_infinity_t;
	always @(*) begin
		calc_infinity_t = 0;
		shl ='bx;
		if (shr) begin
			casez (r_b_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (r_b_exponent[10:6] >= 5'h1e)
							calc_infinity_t = 1;
						exponent_t = r_b_exponent+64;
				   end
			2'b?1: begin
						if (r_b_exponent >= 11'h7fe)
							calc_infinity_t = 1;
						exponent_t = r_b_exponent+1;
				   end
			2'b00: begin
						if (r_b_exponent[10:3] >= 8'hfe)
							calc_infinity_t = 1;
						exponent_t = r_b_exponent+8;
			       end
			endcase
		end else begin
			casez (r_b_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (shl_x < r_b_exponent[10:6]) begin
							shl = shl_x;
							exponent_t = r_b_exponent-{shl_x, 6'b0};
						end else begin
							shl = r_b_exponent[10:6]==0?0:r_b_exponent[10:6]-1;
							exponent_t = 0;
						end
				   end
			2'b?1: begin
						if (shl_x < r_b_exponent) begin
							shl = shl_x;
							exponent_t = r_b_exponent-shl_x;
						end else begin
							shl = r_b_exponent==0?0:r_b_exponent-1;
							exponent_t = 0;
						end
				   end
			2'b00: begin
						if (shl_x < r_b_exponent[10:3]) begin
							shl = shl_x;
							exponent_t = r_b_exponent-{shl_x, 3'b0};
						end else begin
							shl = r_b_exponent[10:3]==0?0:r_b_exponent[10:3]-1;
							exponent_t = 0;
						end
			       end
			endcase
		end
	end

	reg		  is_zero, rsign, incx;
	always @(*) begin
		incx = 0;
		if (mantissa_z[55]) begin
			casez (r_b_sz) // synthesis full_case parallel_case
			2'b1?: incx = exponent_t[10:7]==4'h0;
			2'b?1: incx = exponent_t==11'h0;
			2'b00: incx = exponent_t[10:3]==8'h0;
			endcase
		end
	end

	always @(*) begin
		if (is_zero) begin
			exponent = 0;
			calc_infinity = calc_infinity_t;
			rsign = r_b_eq_sign?r_b_sign :(r_b_rnd==2 || r_b_sign);
		end else
		if (inc || incx) begin
			rsign = r_b_sign;
			casez (r_b_sz) // synthesis full_case parallel_case
			2'b1?: begin
						exponent = exponent_t+11'h40;
						calc_infinity = calc_infinity_t || (~exponent_t[10:6]==0);
			       end
			2'b?1: begin
						exponent = exponent_t+11'b1;
						calc_infinity = calc_infinity_t || (~exponent_t==0);
			       end
			2'b00: begin
						exponent = exponent_t+11'h8;
						calc_infinity = calc_infinity_t || (~exponent_t[10:3]==0);
			       end
			endcase
		end else begin
			rsign = r_b_sign;
			exponent = exponent_t;
			calc_infinity = calc_infinity_t;
		end
	end

	reg [54:3]mantissa;
	reg		  roverflow;
	reg		  nx;
	always @(*) begin
		mantissa = mantissa_z[54:3];
		inc = 0;
		roverflow = 0;	// true if 
		case (r_b_rnd) // synthesis full_case parallel_case
		0:	//      0 - RNE round to nearest, ties to even
			casez (r_b_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (mantissa_z[44:42] > 4 || (mantissa_z[44:42]==4 && mantissa_z[45])) begin
							mantissa = {mantissa_z[54:45]+10'h1,42'bx};
							inc =  (~mantissa_z[54:45]) == 10'h0;
						end
				   end
			2'b?1: begin
						if (mantissa_z[2:0] > 4 || (mantissa_z[2:0]==4 && mantissa_z[3])) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  (~mantissa_z[54:3]) == 52'h0;
						end
				   end
			2'b00: begin
						if (mantissa_z[31:29] > 4 || (mantissa_z[31:29]==4 && mantissa_z[32])) begin
							mantissa = {mantissa_z[54:32]+24'h1,29'bx};
							inc =  (~mantissa_z[54:32]) == 23'h0;
						end
				   end
			endcase
		1:	//      1 - RTZ round towards zero
			roverflow = 1;
		2:	//      2 - RDN round downwards
			begin
				roverflow = !r_b_sign;
				casez (r_b_sz) // synthesis full_case parallel_case
				2'b1?: begin
						if (mantissa_z[44:42] && r_b_sign) begin
							mantissa = {mantissa_z[54:45]+10'h1,42'bx};
							inc =  (~mantissa_z[54:45]) == 10'h0;
						end
					   end
				2'b?1: begin
						if (mantissa_z[2:0] && r_b_sign) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  (~mantissa_z[54:3]) == 52'h0;
						end
		               end
				2'b00: begin
						if (mantissa_z[31:29] && r_b_sign) begin
							mantissa = {mantissa_z[54:32]+24'h1,29'bx};
							inc =  (~mantissa_z[54:32]) == 23'h0;
						end
		               end
				endcase
			end
		3:	//      3 - RUP round upwards
			begin
				roverflow = r_b_sign;
				casez (r_b_sz) // synthesis full_case parallel_case
				2'b1?: begin
						if (mantissa_z[44:42] && !r_b_sign) begin
							mantissa = {mantissa_z[54:45]+10'h1,42'bx};
							inc =  (~mantissa_z[54:45]) == 10'h0;
						end
					   end
				2'b?1: begin
						if (mantissa_z[2:0] && !r_b_sign) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  (~mantissa_z[54:3]) == 52'h0;
						end
		               end
				2'b00: begin
						if (mantissa_z[31:29] && !r_b_sign) begin
							mantissa = {mantissa_z[54:32]+24'h1,29'bx};
							inc =  (~mantissa_z[54:32]) == 23'h0;
						end
		               end
				endcase
			end
		4:	//      4 - RMM round to nearest, ties to max
			casez (r_b_sz) // synthesis full_case parallel_case
			2'b1?: begin
						if (mantissa_z[44:42] >= 4) begin
							mantissa = {mantissa_z[54:45]+10'h1, 42'bx};
							inc =  (~mantissa_z[54:45]) == 10'h0;
						end
		           end
			2'b?1: begin
						if (mantissa_z[2:0] >= 4) begin
							mantissa = mantissa_z[54:3]+53'h1;
							inc =  (~mantissa_z[54:3]) == 52'h0;
						end
		           end
			2'b00: begin
						if (mantissa_z[31:29] >= 4) begin
							mantissa = {mantissa_z[54:32]+24'h1, 29'bx};
							inc =  (~mantissa_z[54:32]) == 23'h0;
						end
		           end
			endcase
		default: begin inc = 'bx; mantissa = 'bx; end
		endcase
		nx = 'bx;
		casez (r_b_sz) // synthesis full_case parallel_case
		2'b1?: nx = (calc_infinity || mantissa_z[44:42]!=0) && !r_b_infinity && !r_b_nan; 
		2'b?1: nx = (calc_infinity || mantissa_z[2:0]!=0)   && !r_b_infinity && !r_b_nan;
		2'b00: nx = (calc_infinity || mantissa_z[31:29]!=0) && !r_b_infinity && !r_b_nan;
		endcase	
		casez (r_b_sz) // synthesis full_case parallel_case
		2'b1?: is_zero = mantissa_z[55:45] == 0;
		2'b?1: is_zero = mantissa_z[55:3] == 0;
		2'b00: is_zero = mantissa_z[55:32] == 0;
		endcase
	end

	reg [63:0]out;
	reg uf, of, nv;
	always @(*) begin
		of = 0;
		nv = 0;
		uf = 0;
		casez (r_b_sz) // synthesis full_case parallel_case
		2'b1?: begin
					if (r_b_nan) begin
						nv = !r_b_nan_quiet;
						out = {48'hffff_ffff_ffff, 6'h1f, 1'b1, 9'h0};	// quiet nan
					end else
					if (!r_b_infinity&calc_infinity&roverflow) begin
						of = 1;
						out = {48'hffff_ffff_ffff, r_b_sign, 5'h1e, ~10'h0};	
					end else
					if (r_b_infinity|calc_infinity) begin
						of = calc_infinity&!r_b_infinity;
						out = {48'hffff_ffff_ffff, r_b_infinity?r_b_infinity_sign:r_b_sign, 5'h1f, 10'h0};	
					end else begin
						out = {48'hffff_ffff_ffff, rsign, exponent[10:6], mantissa[54:45]};
					end
			   end
		2'b?1: begin
					if (r_b_nan) begin
						nv = !r_b_nan_quiet;
						out = {12'h7ff, 1'b1, 51'h0};	// quiet nan
					end else
					if (!r_b_infinity&calc_infinity&roverflow) begin
						of = 1;
						out = {r_b_sign, 11'h7fe, ~52'h0};	
					end else
					if (r_b_infinity|calc_infinity) begin
						of = calc_infinity&!r_b_infinity;
						out = {r_b_infinity?r_b_infinity_sign:r_b_sign, 11'h7ff, 52'h0};	
					end else begin
						out = {rsign, exponent[10:0], mantissa[54:3]};
					end
			   end
		2'b00: begin
					if (r_b_nan) begin
						nv = !r_b_nan_quiet;
						out = {32'hffff_ffff, 9'h0ff, 1'b1, 22'h0};	// quiet nan
					end else
					if (!r_b_infinity&calc_infinity&roverflow) begin
						of = 1;
						out = {32'hffff_ffff, r_b_sign, 8'hfe, ~23'h0};
					end else
					if (r_b_infinity|calc_infinity) begin
						of = calc_infinity&!r_b_infinity;
						out = {32'hffff_ffff, r_b_infinity?r_b_infinity_sign:r_b_sign, 8'hff, 23'h0};	
					end else begin
						out = {32'hffff_ffff, rsign, exponent[10:3], mantissa[54:32]};
					end
			   end
		endcase
	end 
	assign res = out;
	assign exceptions = {nv, 1'b0, of, uf, nx};
	
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


