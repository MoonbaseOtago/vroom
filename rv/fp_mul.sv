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

module fp_mul(input reset, input clk, 
		input start, 
		input sz,
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
		

	wire is_nan_1 = (!sz ? (in_1[63:32]!=~32'b0) || ((in_1[30:23] == 8'hff) && (in_1[22:0] != 0)) : ((in_1[62:52] == 11'h7ff) && (in_1[51:0] != 0)));
	wire is_nan_2 = (!sz ? (in_2[63:32]!=~32'b0) || ((in_2[30:23] == 8'hff) && (in_2[22:0] != 0)) : ((in_2[62:52] == 11'h7ff) && (in_2[51:0] != 0)));
	wire is_nan_3 = (!sz ? (in_3[63:32]!=~32'b0) || ((in_3[30:23] == 8'hff) && (in_3[22:0] != 0)) : ((in_3[62:52] == 11'h7ff) && (in_3[51:0] != 0)));
	wire is_nan_signalling_1 = (!sz ? in_1[22] : in_1[51]);
	wire is_nan_signalling_2 = (!sz ? in_2[22] : in_2[51]);
	wire is_nan_signalling_3 = (!sz ? in_3[22] : in_3[51]);
	wire is_infinity_1 = (!sz ? (in_1[30:23] == 8'hff) && (in_1[22:0] != 0) : (in_1[62:52] == 11'h7ff) && (in_1[51:0] != 0));
	wire is_infinity_2 = (!sz ? (in_2[30:23] == 8'hff) && (in_2[22:0] != 0) : (in_2[62:52] == 11'h7ff) && (in_2[51:0] != 0));
	wire is_infinity_3 = (!sz ? (in_3[30:23] == 8'hff) && (in_3[22:0] != 0) : (in_3[62:52] == 11'h7ff) && (in_3[51:0] != 0));


	wire sign_1 = (sz ? in_1[63]:in_1[31]);
	wire sign_2 = (sz ? in_2[63]:in_2[31]);
	wire sign_3 = (sz ? in_3[63]:in_3[31]);
	
	assign exception = is_nan_1&is_nan_signalling_1 || is_nan_2&is_nan_signalling_2 || fmuladd&is_nan_3&is_nan_signalling_3;
	wire nan = is_nan_1 || is_nan_2 || (is_infinity_1&&is_infinity_2&&sign_1!=sign_2) || fmuladd&is_nan_3;
	wire infinity = is_infinity_1 || is_infinity_2 || fmuladd&is_infinity_3;
	wire infinity_sign = (is_infinity_1&sign_1)^(is_infinity_2&sign_2);

	assign sign = sign_1^sign_2^(fmuladd&fmulsign);


	wire z_1 = (sz?in_1[62:52]==11'b0 : in_1[30:23]==8'b0);
	wire z_2 = (sz?in_2[62:52]==11'b0 : in_2[30:23]==8'b0);
	wire signed [11:0]exps_1 = (sz?{1'b0, in_1[62:52]} : {{1'b0,in_1[30:23]},3'b0}); 
	wire signed [11:0]exps_2 = (sz?{1'b0, in_2[62:52]} : {{1'b0,in_2[30:23]},3'b0});

	wire signed [11:0]exp_s = exps_1+exps_2;
	wire signed [11:0]exp_sum = exp_s-(sz?12'h3ff:12'h3f8);
	
	// mantissa's:
	//
	//  integer .    fraction - guard bits
	//	57-55   .      54-3       2-0			64-bit
	//	57-55   .      54-32      31-29			32-bit
	// 
	wire [52:0]mantissa_1 = {z_1?1'b0:1'b1, (sz?{in_1[51:0]} : {in_1[22:0], 29'b0})};
	wire [52:0]mantissa_2 = {z_2?1'b0:1'b1, (sz?{in_2[51:0]} : {in_2[22:0], 29'b0})};

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
	reg [1:0]r_a_rnd;
	reg r_a_nan;
	reg r_a_sz;
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
	reg r_b_sign;
	reg [11:0]r_b_exp_sum;
	reg [105:0]r_b_mantissa;
	reg [1:0]r_b_rnd;
	reg r_b_sz;
	reg r_b_nan;
	reg r_b_exception;
	reg r_b_infinity;
	reg r_b_infinity_sign;
	always @(posedge clk) begin
		r_b_sign <= sign;
		r_b_exp_sum <= exp_sum;
		r_b_mantissa <= {53'b0,mantissa_1}*{53'b0,mantissa_2};
		r_b_nan <= nan;
		r_b_sz <= sz;
		r_b_rnd <= rnd;
		r_b_exception <= exception;
		r_b_infinity <= infinity;
		r_b_infinity_sign <= infinity_sign;
	end


	reg r_c_sign;
	reg [11:0]r_c_exp_sum;
	reg [105:0]r_c_mantissa;
	reg r_c_nan;
	reg r_c_sz;
	reg [1:0]r_c_rnd;
	reg r_c_exception;
	reg r_c_infinity;
	reg r_c_infinity_sign;
	always @(posedge clk) begin
		r_c_sign <= r_b_sign;
		r_c_exp_sum <= r_b_exp_sum;
		r_c_mantissa <= r_b_mantissa;
		r_c_rnd <= r_b_rnd;
		r_c_nan <= r_b_nan;
		r_c_sz <= r_b_sz;
		r_c_exception <= r_b_exception;
		r_c_infinity <= r_b_infinity;
		r_c_infinity_sign <= r_b_infinity_sign;
	end
	/// end custom core

	reg [6:0]shl, shl_x;
	reg [11:0]shr;
	reg [55:0]mantissa_z;
	reg shr_x;

`include "mkf3.inc"	

	// but we need to adjust the exponent too 

	reg [10:0]exponent;
	reg [11:0]exponent_t;
	reg inc;
	reg calc_infinity, calc_infinity_t;
	always @(*) begin
		calc_infinity_t = 0;
		shl ='bx;
		shr = 0;
		underflow = 0;
		
		if (r_c_exp_sum[11:10]==2'b11) begin 
            if (r_c_sz) begin 
				//shr = {11'b01,shr_x}-r_c_exp_sum[11:0];
				//shr = {11'b0,shr_x}-r_c_exp_sum[11:0];
				shr = {11'b0,1'b1}-r_c_exp_sum[11:0];
				underflow = shr > 54;
				exponent_t = 0;
			end else begin
				//shr = {8'h01,shr_x}-{{3{r_c_exp_sum[11]}},r_c_exp_sum[11:3]};
				shr = {8'h0,1'b1}-{{3{r_c_exp_sum[11]}},r_c_exp_sum[11:3]};
				underflow = shr > 24;
				exponent_t = 0;
			end
		end else
		if (shr_x) begin
			shr = 1;
            if (r_c_sz) begin
                if (r_c_exp_sum[10:0] >= 11'h7fe)
                    calc_infinity_t = 1;
                exponent_t = r_c_exp_sum+1;
            end else begin
                if (r_c_exp_sum[10:3] >= 8'hfe)
                    calc_infinity_t = 1;
                exponent_t = r_c_exp_sum+8;
            end
		end else begin
			if (r_c_sz) begin
				if (shl_x < r_c_exp_sum) begin
					shl = shl_x;
					exponent_t = r_c_exp_sum-shl_x;
				end else begin
					shl = r_c_exp_sum-1;
					exponent_t = 0;
				end
			end else begin
				if (shl_x < r_c_exp_sum[11:3]) begin
					shl = shl_x;
					exponent_t = r_c_exp_sum-{shl_x, 3'b0};
				end else begin
					shl = r_c_exp_sum-8;
					exponent_t = 0;
				end
			end
		end
	end

	reg		  is_zero, rsign, underflow;
	always @(*) begin
		rsign = r_c_sign;
		if (is_zero) begin
			// some underflow signalling needed here
			exponent = 0;
			calc_infinity = calc_infinity_t;
		end else
		if (exponent_t[11:10] == 2'b10) begin
			exponent = 'bx;
			calc_infinity = 1;
		end else
		if (inc) begin
			if (r_c_sz) begin
				exponent = exponent_t+11'b1;
				calc_infinity = calc_infinity_t || (exponent_t[10:0] >= 11'h7fe );
			end else begin
				exponent = exponent_t+11'h8;
				calc_infinity = calc_infinity_t || (exponent_t[10:3] >= 8'hfe);
			end
		end else begin
			exponent = exponent_t;
			calc_infinity = calc_infinity_t;
			if (r_c_sz) begin
				calc_infinity = calc_infinity_t || (exponent_t[10:0] == 11'h7ff);
			end else begin
				calc_infinity = calc_infinity_t || (exponent_t[10:3] == 8'hff);
			end
		end
	end


	reg [54:3]mantissa;
	reg x_underflow;
	always @(*) begin
		mantissa = mantissa_z[54:3];
		if (r_c_sz) begin
			is_zero = mantissa_z[55:3] == 0;
		end else begin
			is_zero = mantissa_z[55:32] == 0;
		end
		inc = 0;
		x_underflow = 0;
		case (r_c_rnd) // synthesis full_case parallel_case
		0:	//      0 - RNE round to nearest, ties to even
			if (r_c_sz) begin
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
			if (r_c_sz) begin
				if (mantissa_z[2:0]!=0 && r_c_sign) begin
					mantissa = mantissa_z[54:3]+53'h1;
					inc =  (~mantissa_z[54:3]) == 52'h0;
					x_underflow = 1;
				end
			end else begin
				if (mantissa_z[31:29]!=0 && r_c_sign) begin
					mantissa = {mantissa_z[54:32]+24'h1,29'bx};
					inc =  (~mantissa_z[54:32]) == 23'h0;
					x_underflow = 1;
				end
			end
		3:	//      3 - RUP round upwards
			if (r_c_sz) begin
				if (mantissa_z[2:0]!=0 && !r_c_sign) begin
					mantissa = mantissa_z[54:3]+53'h1;
					inc =  (~mantissa_z[54:3]) == 52'h0;
					x_underflow = 1;
				end
			end else begin
				if (mantissa_z[31:29]!=0 && !r_c_sign) begin
					mantissa = {mantissa_z[54:32]+24'h1,29'bx};
					inc =  (~mantissa_z[54:32]) == 23'h0;
					x_underflow = 1;
				end
			end
		4:	//      4 - RMM round to nearest, ties to max
			if (r_c_sz) begin
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

	wire round_down_from_infinity = (r_c_rnd==1)||(r_c_rnd==2&&!r_c_sign)||(r_c_rnd==3&&r_c_sign);

	reg [63:0]out;
	always @(*) begin
		if (r_c_sz) begin
			if (r_c_nan) begin
				out = {12'hfff, 52'h1};	// quiet nan
			end else
			if (r_c_infinity|calc_infinity) begin
				if (round_down_from_infinity) begin
					out = {r_c_infinity?r_c_infinity_sign:r_c_sign, 11'h7fe, 52'hf_ffff_ffff_ffff};	
				end else begin
					out = {r_c_infinity?r_c_infinity_sign:r_c_sign, 11'h7ff, 52'h0};	
				end
			end else
			if (underflow&!x_underflow) begin
				out = {rsign, 11'b0, 52'h0};
			end else begin
				out = {rsign, exponent[10:0], mantissa[54:3]};
			end
		end else begin
			if (r_c_nan) begin
				out = {32'hffff_ffff, 9'h1ff, 23'h1};	// quiet nan
			end else
			if (r_c_infinity|calc_infinity) begin
				if (round_down_from_infinity) begin
					out = {32'hffff_ffff, r_c_infinity?r_c_infinity_sign:r_c_sign, 8'hfe, 23'h7fffff};	
				end else begin
					out = {32'hffff_ffff, r_c_infinity?r_c_infinity_sign:r_c_sign, 8'hff, 23'h0};	
				end
			end else
			if (underflow&!x_underflow) begin
				out = {32'hffff_ffff, rsign, 8'b0, 23'h0};
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


