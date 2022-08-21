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

module fp_add_sub(input reset, input clk, 
		input sz,
		input sub,
		input start,
		input [2:0]rnd,
		input [RV-1:0]in_1,
		input [RV-1:0]in_2,
		output valid,
		output exception,
		output [RV-1:0]res
	);
	parameter RV=64;

	reg [1:0]r_start;
	assign valid = r_start[1];
	always @(posedge clk)
	if (reset) begin
		r_start <= 0;
	end else begin
		r_start <= {r_start[0], start};
	end

	wire is_nan_1 = (!sz ? (in_1[63:32]!=~32'b0) || ((in_1[30:23] == 8'hff) && (in_1[22:0] != 0)) : ((in_1[62:52] == 11'h7ff) && (in_1[51:0] != 0)));
	wire is_nan_2 = (!sz ? (in_2[63:32]!=~32'b0) || ((in_2[30:23] == 8'hff) && (in_2[22:0] != 0)) : ((in_2[62:52] == 11'h7ff) && (in_2[51:0] != 0)));
	wire is_nan_signalling_1 = (!sz ? in_1[22] : in_1[51]);
	wire is_nan_signalling_2 = (!sz ? in_2[22] : in_2[51]);
	wire is_infinity_1 = (!sz ? (in_1[30:23] == 8'hff) && (in_1[22:0] != 0) : (in_1[62:52] == 11'h7ff) && (in_1[51:0] != 0));
	wire is_infinity_2 = (!sz ? (in_2[30:23] == 8'hff) && (in_2[22:0] != 0) : (in_2[62:52] == 11'h7ff) && (in_2[51:0] != 0));


	wire sign_1 = (sz ? in_1[63]:in_1[31]);
	wire sign_2 = (sz ? in_2[63]:in_2[31]);
	
	assign exception = is_nan_1&is_nan_signalling_1 || is_nan_2&is_nan_signalling_2;
	wire nan = is_nan_1 || is_nan_2 || (is_infinity_1&&is_infinity_2&&(sub ?sign_1==sign_2:sign_1!=sign_2));
	wire infinity = is_infinity_1 || is_infinity_2;
	wire infinity_sign = (is_infinity_1&sign_1) || (is_infinity_2&sign_2);


	wire [10:0]exp_1 = (sz?in_1[62:52] : {in_1[30:23],3'b0});
	wire [10:0]exp_2 = (sz?in_2[62:52] : {in_2[30:23],3'b0});

	wire exp_gt = exp_1 > exp_2;
	wire exp_eq = exp_1 == exp_2;
	wire [10:0]exp_diff = exp_1-exp_2;
	
	// mantissa's:
	//
	//  integer .    fraction - guard bits
	//	57-55   .      54-3       2-0			64-bit
	//	57-55   .      54-32      31-29			32-bit
	// 
	wire [55:0]mantissa_1 = {exp_1==0?1'b0:1'b1, (sz?{in_1[51:0], 3'b0} : {in_1[22:0], 3'b0, 29'bx})};
	wire [55:0]mantissa_2 = {exp_2==0?1'b0:1'b1, (sz?{in_2[51:0], 3'b0} : {in_2[22:0], 3'b0, 29'bx})};

	// these are for debug, tossed by synthesis
	wire [22:0]m32_1= in_1[22:0];
	wire [22:0]m32_2= in_2[22:0];
	wire [7:0]e32_1 = in_1[30:23];
	wire [7:0]e32_2 = in_2[30:23];
	wire [7:0]e32_d = exp_diff[10:3];

	reg [51+3+1:0]shifted_mantissa_1;
	reg [51+3+1:0]shifted_mantissa_2;
	reg [10:0]exponent_x;


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
			if (sub?!sign_2:sign_2) begin
				sign_x = 1;
				cin = 0;
			end else begin
				sign_x = 0;
				cin = 1;
				c_a_mantissa_1 = ~{1'b0, shifted_mantissa_1};
			end
		end else begin
			sign_x = 0;
			if (sub?!sign_2:sign_2) begin
				cin = 1;
				c_a_mantissa_2 = ~{1'b0, shifted_mantissa_2};
			end else begin
				cin = 0;
			end
		end
	end

	reg [56:0]r_a_mantissa_1, r_a_mantissa_2;
	reg		  r_a_cin, r_a_exception, r_a_nan, r_a_infinity, r_a_infinity_sign;
	reg [10:0]r_a_exponent;
	reg  [2:0]r_a_rnd;
	reg		  r_a_sz;
	reg		  r_a_signx;

	always @(posedge clk) begin
		r_a_mantissa_1 <= c_a_mantissa_1;
		r_a_mantissa_2 <= c_a_mantissa_2;
		r_a_sz <= sz;
		r_a_exception <= exception;
		r_a_nan <= nan;
		r_a_infinity <= infinity;
		r_a_infinity_sign <= infinity_sign;
		r_a_signx <= sign_x;
		r_a_cin <= cin;
		r_a_exponent <= exponent_x;
		r_a_rnd <= rnd;
	end
		

	reg [57:0]c_mantissa_x;
	always @(*) 
	if (r_a_sz) begin
		c_mantissa_x = {r_a_mantissa_1[56], r_a_mantissa_1} + {r_a_mantissa_2[56], r_a_mantissa_2} + {57'b0, r_a_cin};
	end else begin
		c_mantissa_x = {{r_a_mantissa_1[56], r_a_mantissa_1[56:29]} + {r_a_mantissa_2[56], r_a_mantissa_2[56:29]} + {27'b0, r_a_cin}, 29'bx};
	end

	wire c_sign = r_a_signx | c_mantissa_x[57];

	reg [57:0]r_b_mantissa;
	reg		  r_b_sz, r_b_exception, r_b_nan, r_b_infinity, r_b_infinity_sign, r_b_sign;
	reg [10:0]r_b_exponent;
	reg  [2:0]r_b_rnd;
	
	always @(posedge clk) begin
		r_b_mantissa <= c_mantissa_x;
		r_b_sz <= r_a_sz;
        r_b_exception <= r_a_exception;
        r_b_nan <= r_a_nan;
        r_b_infinity <= r_a_infinity;
        r_b_infinity_sign <= r_a_infinity_sign;
        r_b_sign <= c_sign;
		r_b_exponent <= r_a_exponent;
		r_b_rnd <= r_a_rnd;
	end

	wire [56:0]mantissa_y = (sz? (r_b_mantissa[57]? -r_b_mantissa[56:0]:r_b_mantissa[56:0]) :
								({r_b_mantissa[57]? -r_b_mantissa[56:29]:r_b_mantissa[56:29], 29'bx}));
	
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
			if (r_b_sz) begin
				if (r_b_exponent >= 11'h7fe)
					calc_infinity_t = 1;
				exponent_t = r_b_exponent+1;
			end else begin
				if (r_b_exponent[10:3] >= 8'hfe)
					calc_infinity_t = 1;
				exponent_t = r_b_exponent+8;
			end
		end else begin
			if (r_b_sz) begin
				if (shl_x < r_b_exponent) begin
					shl = shl_x;
					exponent_t = r_b_exponent-shl_x;
				end else begin
					shl = r_b_exponent-1;
					exponent_t = 0;
				end
			end else begin
				if (shl_x < r_b_exponent[10:3]) begin
					shl = shl_x;
					exponent_t = r_b_exponent-{shl_x, 3'b0};
				end else begin
					shl = r_b_exponent-8;
					exponent_t = 0;
				end
			end
		end
	end

	reg		  is_zero, rsign;
	always @(*) begin
		if (is_zero) begin
			exponent = 0;
			calc_infinity = calc_infinity_t;
			rsign = r_b_rnd == 2 || r_b_sign;
		end else
		if (inc) begin
			rsign = r_b_sign;
			if (r_b_sz) begin
				exponent = exponent_t+11'b1;
				calc_infinity = calc_infinity_t || (~exponent_t==0);
			end else begin
				exponent = exponent_t+11'h8;
				calc_infinity = calc_infinity_t || (~exponent_t[10:3]==0);
			end
		end else begin
			rsign = r_b_sign;
			exponent = exponent_t;
			calc_infinity = calc_infinity_t;
		end
	end

	reg [54:3]mantissa;
	always @(*) begin
		mantissa = mantissa_z[54:3];
		if (r_b_sz) begin
			is_zero = mantissa_z[55:3] == 0;
		end else begin
			is_zero = mantissa_z[55:32] == 0;
		end
		inc = 0;
		case (r_b_rnd) // synthesis full_case parallel_case
		0:	//      0 - RNE round to nearest, ties to even
			if (r_b_sz) begin
				if (mantissa_z[2:0] > 4 || (mantissa_z[2:0]==4 && mantissa_z[3])) begin
					mantissa = mantissa_z[54:3]+53'h1;
					inc =  (~mantissa_z[54:3]) == 52'h0;
				end
			end else begin
				if (mantissa_z[31:29] > 4 || (mantissa_z[31:29]==4 && mantissa_z[32])) begin
					mantissa = {mantissa_z[54:32]+24'h1,29'bx};
					inc =  ~mantissa_z[54:32] == 23'h0;
				end
			end
		1:	//      1 - RTZ round towards zero
			;
		2:	//      2 - RDN round downwards
			if (r_b_sz) begin
				if (mantissa_z[2:0] && r_b_sign) begin
					mantissa = mantissa_z[54:3]+53'h1;
					inc =  (~mantissa_z[54:3]) == 52'h0;
				end
			end else begin
				if (mantissa_z[31:29] && r_b_sign) begin
					mantissa = {mantissa_z[54:32]+24'h1,29'bx};
					inc =  (~mantissa_z[54:32]) == 23'h0;
				end
			end
		3:	//      3 - RUP round upwards
			if (r_b_sz) begin
				if (mantissa_z[2:0] && !r_b_sign) begin
					mantissa = mantissa_z[54:3]+53'h1;
					inc =  (~mantissa_z[54:3]) == 52'h0;
				end
			end else begin
				if (mantissa_z[31:29] && !r_b_sign) begin
					mantissa = {mantissa_z[54:32]+24'h1,29'bx};
					inc =  (~mantissa_z[54:32]) == 23'h0;
				end
			end
		4:	//      4 - RMM round to nearest, ties to max
			if (r_b_sz) begin
				if (mantissa_z[2:0] >= 4) begin
					mantissa = mantissa_z[54:3]+53'h1;
					inc =  (~mantissa_z[54:3]) == 52'h0;
				end
			end else begin
				if (mantissa_z[31:29] >= 4) begin
					mantissa = {mantissa_z[54:32]+24'h1, 29'bx};
					inc =  (~mantissa_z[54:32]) == 23'h0;
				end
			end
		default: begin inc = 'bx; mantissa = 'bx; end
		endcase
	end

	reg [63:0]out;
	always @(*) begin
		if (r_b_sz) begin
			if (r_b_nan) begin
				out = {12'hfff, 52'h1};	// quiet nan
			end else
			if (r_b_infinity|calc_infinity) begin
				out = {r_b_infinity?r_b_infinity_sign:r_b_sign, 11'h7ff, 52'h0};	
			end else begin
				out = {rsign, exponent[10:0], mantissa[54:3]};
			end
		end else begin
			if (r_b_nan) begin
				out = {32'hffff_ffff, 9'h1ff, 23'h1};	// quiet nan
			end else
			if (r_b_infinity|calc_infinity) begin
				out = {32'hffff_ffff, r_b_infinity?r_b_infinity_sign:r_b_sign, 8'hff, 23'h0};	
			end else begin
				out = {32'hffff_ffff, rsign, exponent[10:3], mantissa[54:32]};
			end
		end
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


