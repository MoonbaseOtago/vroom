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
//	FP div/sqrt - while this is synthesisable the intent here is to sketch out a 
//	FP div-sqrt block that makes the correct bits - the intent is that
//	a real implementation will involve a real hand built data path for 
//	speed 
//

module fp_div(input reset, input clk, 
		input start, 
		input [1:0]sz,
		input [2:0]rnd,
		input [RV-1:0]in_1,
		input [RV-1:0]in_2,
		input issqrt,	// is it a sqrt?
        input [NCOMMIT-1:0]commit_kill_0,
        //input [NCOMMIT-1:0]commit_kill_1,
        input [LNCOMMIT-1:0]rd,
        input [(NHART==1?0:LNHART-1):0]hart,
		input 	makes_rd,
		output [4:0]exceptions,
		output valid,
		input valid_ack,
		output fpu_cancel, 
		output [RV-1:0]res,
		output [LNCOMMIT-1:0]rd_out,
        output [(NHART==1?0:LNHART-1):0]hart_out
	);
	parameter RV=64;
	parameter LNCOMMIT=6;
	parameter NCOMMIT=64;
	parameter NHART=1;
	parameter LNHART=1;

	reg is_nan_1, is_nan_2;
	reg is_nan_signalling_1, is_nan_signalling_2;
	reg is_infinity_1, is_infinity_2;
	reg sign_1, sign_2;
	reg z_1, z_2;
	reg boxed_nan_1, boxed_nan_2;

	always @(*)
	casez (sz) // synthesis full_case parallel_case
	2'b1?: begin	// 16-bit
			boxed_nan_1 = (in_1[63:16]!=~48'b0);
            boxed_nan_2 = (in_2[63:16]!=~48'b0);
			is_nan_1 = boxed_nan_1 || ((in_1[14:10] == 5'h1f) && (in_1[9:0] != 0));
			is_nan_2 = boxed_nan_2 || ((in_2[14:10] == 5'h1f) && (in_2[9:0] != 0));
			is_nan_signalling_1 = !in_1[9] || boxed_nan_1;
			is_nan_signalling_2 = !in_2[9] || boxed_nan_2;
			is_infinity_1 = (in_1[14:10] == 5'h1f) && (in_1[9:0] == 0);
			is_infinity_2 = (in_2[14:10] == 5'h1f) && (in_2[9:0] == 0);
			sign_1 = in_1[15];
			sign_2 = in_2[15];
			z_1 = in_1[14:10]==8'b0;
			z_2 = in_2[14:10]==8'b0;
		   end
	2'b?1: begin	// 64-bit
            boxed_nan_1 = 1'bx;
            boxed_nan_2 = 1'bx;
			is_nan_1 = ((in_1[62:52] == 11'h7ff) && (in_1[51:0] != 0));
			is_nan_2 = ((in_2[62:52] == 11'h7ff) && (in_2[51:0] != 0));
			is_nan_signalling_1 = !in_1[51];
			is_nan_signalling_2 = !in_2[51];
			is_infinity_1 = (in_1[62:52] == 11'h7ff) && (in_1[51:0] == 0);
			is_infinity_2 = (in_2[62:52] == 11'h7ff) && (in_2[51:0] == 0);
			sign_1 = in_1[63];
			sign_2 = in_2[63];
			z_1 = in_1[62:52]==11'b0;
			z_2 = in_2[62:52]==11'b0;
		   end
	2'b00: begin	// 32-bit
            boxed_nan_1 = (in_1[63:32]!=~32'b0);
            boxed_nan_2 = (in_2[63:32]!=~32'b0);
			is_nan_1 = boxed_nan_1 || ((in_1[30:23] == 8'hff) && (in_1[22:0] != 0));
			is_nan_2 = boxed_nan_2 || ((in_2[30:23] == 8'hff) && (in_2[22:0] != 0));
			is_nan_signalling_1 = !in_1[22] || boxed_nan_1;
			is_nan_signalling_2 = !in_2[22] || boxed_nan_2;
			is_infinity_1 = (in_1[30:23] == 8'hff) && (in_1[22:0] == 0);
			is_infinity_2 = (in_2[30:23] == 8'hff) && (in_2[22:0] == 0);
			sign_1 = in_1[31];
			sign_2 = in_2[31];
			z_1 = in_1[30:23]==8'b0;
			z_2 = in_2[30:23]==8'b0;
		   end
	endcase

//	assign exception = is_nan_1&is_nan_signalling_1 ||
//						(issqrt ? sign_1 : is_nan_2&is_nan_signalling_2):
	assign exception = 0;
								   
	wire nan = is_nan_1 ||
			   ((is_infinity_1&&is_infinity_2&&!issqrt) || (is_nan_2 || (z_1 && mantissa_1 == 53'b0 && z_2 && mantissa_2 == 53'b0))  && !issqrt) ||
			   (issqrt && sign_1 && mantissa_1 !=0);

	wire quiet_nan = !(is_nan_1&is_nan_signalling_1 || !issqrt&is_nan_2&is_nan_signalling_2 ||
					   (issqrt && sign_1 && mantissa_1 !=0 && !is_nan_1) ||
					   (!issqrt && is_infinity_1 && is_infinity_2) ||
					   ((z_1 && mantissa_1 == 53'b0 && z_2 && mantissa_2 == 53'b0) && !issqrt));

	wire infinity = is_infinity_1 || (!issqrt && ((z_2 && mantissa_2 == 53'b0))) ;
	wire infinity_sign = (infinity&(sign_1^sign_2));

	assign sign = !issqrt&&(sign_1^sign_2);


	reg signed [11:0]exps_1;
	reg signed [11:0]exps_2;

	
	// mantissa's:
	//
	//  integer .    fraction - guard bits
	//	57-55   .      54-3       2-0			64-bit
	//	57-55   .      54-32      31-29			32-bit
	// 
	reg [52:0]mantissa_1;
	reg [52:0]mantissa_2;
	always @(*)
	casez (sz) // synthesis full_case parallel_case
	2'b1?: begin
			mantissa_1 = {z_1?1'b0:1'b1, in_1[9:0], 42'b0};
			mantissa_2 = {z_2?1'b0:1'b1, in_2[9:0], 42'b0};
			exps_1 = z_1?{~8'b0, 4'b1} : {{8{~in_1[14]}}, in_1[13:10]}; 
			exps_2 = z_2?{~8'b0, 4'b1} : {{8{~in_2[14]}}, in_2[13:10]}; 
		   end
	2'b?1: begin
			mantissa_1 = {z_1?1'b0:1'b1, in_1[51:0]};
			mantissa_2 = {z_2?1'b0:1'b1, in_2[51:0]};
			exps_1 = z_1?{2'b11, 10'h1}:{{2{~in_1[62]}}, in_1[61:52]};
			exps_2 = z_2?{2'b11, 10'h1}:{{2{~in_2[62]}}, in_2[61:52]};
		   end
	2'b00: begin
			mantissa_1 = {z_1?1'b0:1'b1, in_1[22:0], 29'b0};
			mantissa_2 = {z_2?1'b0:1'b1, in_2[22:0], 29'b0};
			exps_1 = z_1?{~5'b0, 7'b1}:{{5{~in_1[30]}}, in_1[29:23]}; 
			exps_2 = z_2?{~5'b0, 7'b1}:{{5{~in_2[30]}}, in_2[29:23]}; 
		   end
	endcase

    reg    [5:0]r_div_count, c_div_count;
    reg    [1:0]r_div_sz, c_div_sz;
    reg    [2:0]r_div_rnd, c_div_rnd;
	reg [56:0]r_sqrt_b, c_sqrt_b;
    reg         r_sqrting, c_sqrting;
    reg [RV-1:0]c_div_res;
    reg [57:0]r_remainder, c_remainder;	// 53:0
    reg [56:0]r_quotient, c_quotient;
    reg [57:0]r_divisor, c_divisor;
    reg [52+2:0]r_divisor3, c_divisor3;
    reg [LNCOMMIT-1:0]r_div_rd, c_div_rd;
    reg         r_div_makes_rd, c_div_makes_rd;
    reg  [(NHART==0?0:LNHART-1):0]r_div_hart, c_div_hart;
    reg         r_dividing, c_dividing;
    reg         r_div_sign, c_div_sign;
    reg         r_div_final, c_div_final;
	reg			r_div_nan, c_div_nan;
	reg			r_div_infinity, c_div_infinity;
	reg			r_div_zero, c_div_zero;
	reg			r_div_by_zero, c_div_by_zero;
	reg			r_div_nz, c_div_nz;
	reg			r_div_quiet_nan, c_div_quiet_nan;
	reg signed [12:0]r_div_exponent, c_div_exponent;
    assign divide_hart = c_div_hart;
    assign divide_rd = c_div_rd;
	reg			fpu_cancel_out;
	assign fpu_cancel = fpu_cancel_out;

	reg	[52:0]mantissa_sh_1;
	reg	[52:0]mantissa_sh_2;
	reg	[5:0]m1_shl, m2_shl;
    reg [7:0]shl, shl_x;
	reg	[10:0]shr;

	
	

	wire signed [12:0]exp_sum_div = {exps_1[11], exps_1}-{exps_2[11], exps_2}-12'h1-m1_shl+m2_shl;
	wire signed [12:0]exp_sqrt = {exps_1[11], exps_1[11:0]}-m1_shl;
	wire signed [12:0]exp_sum_sqrt = {exp_sqrt[11], exp_sqrt[11], exp_sqrt[11:1]}+(m1_shrx? 13'd1 :0);

	wire [5:0]m1_shlx = issqrt&!exp_sqrt[0] && m1_shl != 0 ?  m1_shl-1 : m1_shl;
	wire	  m1_shrx = issqrt&!exp_sqrt[0] && m1_shl == 0;

`include "mkf10.inc"


    wire [56:0]mantissa_n = {r_quotient[56:1], r_quotient[0] | (|r_remainder)};
    reg [55:0]mantissa_z;

`include "mkf11.inc"

    reg [11:0]exponent;
    reg [12:0]exponent_t;
    reg inc;
    reg calc_infinity_t, calc_infinity;
	reg	under, underflow;
    always @(*) begin
		underflow = 0;
        calc_infinity_t = 0;
		exponent_t = 'bx;
        shl ='bx;
		shr = 0;
        casez (r_div_sz) // synthesis full_case parallel_case
        2'b1?: under = r_div_exponent[12] && (r_div_exponent[11:4]!=8'b1111_1111 || r_div_exponent[3:0]==0);
        2'b?1: under = r_div_exponent[12] && (r_div_exponent[11:10]!=2'b11 || r_div_exponent[9:0]==0);
        2'b00: under = r_div_exponent[12] && (r_div_exponent[11:7]!=5'b1_1111 || r_div_exponent[6:0]==0);
        endcase
        if (under) begin
            casez (r_div_sz) // synthesis full_case parallel_case
            2'b1?: begin
                        shr = r_div_exponent[4:0]==5'h10 ? 1:(11'h7f0 - r_div_exponent[10:0])+1;
                        underflow = shr > 12 || r_div_exponent[11:5]!=7'b111_1111;
                   end
            2'b?1: begin
                        shr = (11'h400 - r_div_exponent[10:0])+1;
                        underflow = shr > 54;
                   end
            2'b00: begin
                        shr = r_div_exponent[7:0]==8'h80 ? 1:(11'h780 - r_div_exponent[10:0])+1;
                        underflow = shr > 25 || r_div_exponent[11:8]!=4'b1111;
                   end
            endcase
            exponent_t = 13'h1c00;
        end else
        casez (r_div_sz) // synthesis full_case parallel_case
        2'b1?: begin
					reg [11:0]tmp;
                    tmp = r_div_exponent+16;
                    if (shl_x < tmp) begin
                        shl = shl_x;
                        exponent_t = r_div_exponent-shl_x;
                    end else begin
                        shl = r_div_exponent==13'h1ff0 ? 0:r_div_exponent+15;
                        exponent_t = 13'h1ff0;
                    end
               end
        2'b?1: begin
                    if (r_div_exponent[12:10] != 3'b111 || shl_x < r_div_exponent[9:0]) begin
                        shl = shl_x;
                        exponent_t = r_div_exponent-shl_x;
                    end else begin
                        shl = r_div_exponent[9:0]==0?0:r_div_exponent[9:0]-1;
                        exponent_t = 13'h1800;
                    end
               end
        2'b00: begin
                    if (r_div_exponent[12:7] != 6'h3f || shl_x < r_div_exponent[6:0]) begin
                        shl = shl_x;
                        exponent_t = r_div_exponent-shl_x;
                    end else begin
                        shl = r_div_exponent[6:0]==0?0:r_div_exponent[6:0]-1;
                        exponent_t = 13'h1f80;
                   end
               end
        endcase
	end

    reg       is_zero, rsign;

    always @(*) begin
        if (is_zero) begin
            exponent = 12'h800;
            calc_infinity = calc_infinity_t;
            rsign = r_div_sign; // (r_div_rnd==2 || r_div_sign);
        end else
		if (!exponent_t[12] && exponent_t[11:10] >= 2'b01) begin
            exponent = 'bx;
            calc_infinity = 1;
        end else
        if (inc) begin
            rsign = r_div_sign;
            exponent = exponent_t+1;
            casez (r_div_sz) // synthesis full_case parallel_case
            2'b1?: begin
                        calc_infinity = calc_infinity_t || (!exponent_t[12] && exponent_t[11:0] >= 12'h00e);
                   end
            2'b?1: begin
                        calc_infinity = calc_infinity_t ||  (!exponent_t[12] && exponent_t[11:0] >= 12'h3fe);
                   end
            2'b00: begin
                        calc_infinity = calc_infinity_t || (!exponent_t[12] && exponent_t[11:0] >= 12'h07e);
                   end
            endcase
        end else begin
            rsign = r_div_sign;
            exponent = exponent_t;
            casez (r_div_sz) // synthesis full_case parallel_case
            2'b1?: begin
                        calc_infinity = calc_infinity_t || (!exponent_t[12] && exponent_t[11:0] >= 12'h00f);
                   end
            2'b?1: begin
                        calc_infinity = calc_infinity_t ||  (!exponent_t[12] && exponent_t[11:0] >= 12'h3ff);
                   end
            2'b00: begin
                        calc_infinity = calc_infinity_t || (!exponent_t[12] && exponent_t[11:0] >= 12'h07f);
                   end
            endcase
        end
    end

    reg [54:3]mantissa;
    reg       roverflow;
	reg		  x_underflow;
	reg [2:0]rem;

	always @(*)
    casez (r_div_sz) // synthesis full_case parallel_case
    2'b1?: rem = {mantissa_z[44:43], |mantissa_z[42:0]};
    2'b?1: rem = mantissa_z[2:0];
    2'b00: rem = {mantissa_z[31:30], |mantissa_z[29:0]};
	endcase 

	reg nx;
	reg dinc;
    always @(*) begin
        mantissa = mantissa_z[54:3];
        inc = 0;
        roverflow = 0;  // true if 
		x_underflow = 0;
		nx = (calc_infinity || rem!=0) && !r_div_infinity && !r_div_nan && !r_div_zero;;
		dinc = 0;
        case (r_div_rnd) // synthesis full_case parallel_case
        0:  //      0 - RNE round to nearest, ties to even
            casez (r_div_sz) // synthesis full_case parallel_case
            2'b1?: begin
                        if (rem > 4 || (rem==4 && mantissa_z[45])) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:45]+10'h1,42'bx};
                            inc =  (~mantissa_z[54:45]) == 10'h0;
                        end
                   end
            2'b?1: begin
                        if (rem > 4 || (rem==4 && mantissa_z[3])) begin
							dinc = 1;
                            mantissa = mantissa_z[54:3]+53'h1;
                            inc =  (~mantissa_z[54:3]) == 52'h0;
                        end
                   end
            2'b00: begin
                        if (rem > 4 || (rem==4 && mantissa_z[32])) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:32]+24'h1,29'bx};
                            inc =  (~mantissa_z[54:32]) == 23'h0;
                        end
                   end
            endcase
        1:  //      1 - RTZ round towards zero
            roverflow = 1;
        2:  //      2 - RDN round downwards
            begin
                roverflow = !r_div_sign;
                casez (r_div_sz) // synthesis full_case parallel_case
                2'b1?: begin
                        if (rem!=0 && r_div_sign) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:45]+10'h1,42'bx};
                            inc =  (~mantissa_z[54:45]) == 10'h0;
							x_underflow = 1;
                        end
                       end
                2'b?1: begin
                        if (rem != 0 && r_div_sign) begin
							dinc = 1;
                            mantissa = mantissa_z[54:3]+53'h1;
                            inc =  (~mantissa_z[54:3]) == 52'h0;
							x_underflow = 1;
                        end
                       end
                2'b00: begin
                        if (rem != 0 && r_div_sign) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:32]+24'h1,29'bx};
                            inc =  (~mantissa_z[54:32]) == 23'h0;
							x_underflow = 1;
                        end
                       end
                endcase
            end
        3:  //      3 - RUP round upwards
            begin
                roverflow = r_div_sign;
                casez (r_div_sz) // synthesis full_case parallel_case
                2'b1?: begin
                        if (rem != 0 && !r_div_sign) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:45]+10'h1,42'bx};
                            inc =  (~mantissa_z[54:45]) == 10'h0;
							x_underflow = 1;
                        end
                       end
                2'b?1: begin
                        if (rem != 0 && !r_div_sign) begin
							dinc = 1;
                            mantissa = mantissa_z[54:3]+53'h1;
                            inc =  (~mantissa_z[54:3]) == 52'h0;
							x_underflow = 1;
                        end
                       end
                2'b00: begin
                        if (rem != 0 && !r_div_sign) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:32]+24'h1,29'bx};
                            inc =  (~mantissa_z[54:32]) == 23'h0;
							x_underflow = 1;
                        end
                       end
                endcase
            end
        4:  //      4 - RMM round to nearest, ties to max
            casez (r_div_sz) // synthesis full_case parallel_case
            2'b1?: begin
                        if (rem >= 4) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:45]+10'h1, 42'bx};
                            inc =  (~mantissa_z[54:45]) == 10'h0;
                        end
                   end
            2'b?1: begin
                        if (rem >= 4) begin
							dinc = 1;
                            mantissa = mantissa_z[54:3]+53'h1;
                            inc =  (~mantissa_z[54:3]) == 52'h0;
                        end
                   end
            2'b00: begin
                        if (rem >= 4) begin
							dinc = 1;
                            mantissa = {mantissa_z[54:32]+24'h1, 29'bx};
                            inc =  (~mantissa_z[54:32]) == 23'h0;
                        end
                   end
            endcase
        default: begin inc = 'bx; mantissa = 'bx; end
        endcase
        casez (r_div_sz) // synthesis full_case parallel_case
        2'b1?: is_zero = r_div_zero || (mantissa_z[55:45] == 0 && !dinc);
        2'b?1: is_zero = r_div_zero || (mantissa_z[55:3] == 0 && !dinc);
        2'b00: is_zero = r_div_zero || (mantissa_z[55:32] == 0 && !dinc);
        endcase
    end

	reg cancel, cancel_now;
	always @(*) begin
		cancel = 0;
		case (r_div_hart)	// synthesis full_case parallel_case
		0: cancel = commit_kill_0[r_div_rd];
		//1: cancel = commit_kill_1[r_div_rd]
		endcase
		cancel_now = 0;
		case (hart)	// synthesis full_case parallel_case
		0: cancel_now = commit_kill_0[rd];
		//1: cancel_now = commit_kill_1[rd]
		endcase
	end

    reg [55:0]c_new_remainder3;
    reg [55:0]c_new_remainder2;
    reg [55:0]c_new_remainder1;
    reg [57:0]c_sqrt_tmp;

	
	always @(*) begin
		// 2 bits/clock
       c_new_remainder3 = r_remainder-{1'b0, r_divisor3};
       c_new_remainder2 = r_remainder-{2'b0, r_divisor[52:0], 1'b0};
       c_new_remainder1 = r_remainder-{3'b0, r_divisor[52:0]};
	   c_sqrt_tmp = r_remainder - (r_divisor|{1'b0,r_sqrt_b});	
	end

	always @(*) begin
        c_sqrting = r_sqrting;
        c_sqrt_b = 'bx;
        c_div_sz = r_div_sz;
        c_div_rnd = r_div_rnd;
        c_quotient = r_quotient;
        c_remainder = r_remainder;
        c_div_final = r_div_final;
        c_dividing = r_dividing;
        c_div_rd = r_div_rd;
        c_div_hart = r_div_hart;
        c_div_rd = r_div_rd;
        c_div_sign = r_div_sign;
        c_div_makes_rd = r_div_makes_rd&&!commit_kill_0[r_div_rd];
        c_divisor = r_divisor;
        c_divisor3 = r_divisor3;
        c_div_count = r_div_count;
		c_div_exponent = r_div_exponent;
		c_div_nan = r_div_nan;
		c_div_infinity = r_div_infinity;
		c_div_zero = r_div_zero;
		c_div_by_zero = r_div_by_zero;
		c_div_nz = r_div_nz;
		c_div_quiet_nan = r_div_quiet_nan;
		fpu_cancel_out = start&cancel_now;
		casez ({cancel, start&!cancel_now, r_dividing, r_sqrting, r_div_final})// synthesis full_case parallel_case
        5'b11???,
        5'b1?1??,
        5'b1??1?,
        5'b1???1:begin         // abort 
                    c_dividing = 0;
                    c_sqrting = 0;
                    c_div_final = 0;
					fpu_cancel_out = 1;
                end
        5'b01???:begin         // save RF data, set up registers
					c_div_hart = hart;
					c_div_rd = rd;
					c_div_makes_rd = makes_rd;
                    c_div_sign = issqrt?(mantissa_1==0&&sign_1):sign_1^sign_2;
                    c_divisor = (issqrt?55'b0:{3'b0, mantissa_sh_2});
					c_divisor3 = {1'b0, mantissa_sh_2}+{mantissa_sh_2, 1'b0};
                    c_remainder = (issqrt? (m1_shrx ? {1'b0, mantissa_1, 2'b0} : {mantissa_sh_1, 3'b0}):{2'b0, mantissa_sh_1});
					c_div_sz = sz;
					c_div_rnd = rnd;
					if (issqrt) begin
						casez (sz) // synthesis full_case parallel_case
						2'b1?: c_div_count = 10+3+1;
						2'b?1: c_div_count = 52+3+1;
						2'b00: c_div_count = 23+3+0;
						endcase
						if (m1_shrx|m1_shlx[0])
							c_div_count = c_div_count-1;
					end else begin
						casez (sz) // synthesis full_case parallel_case
						2'b1?: c_div_count = (10+3+1)/2;
						2'b?1: c_div_count = (52+3+1)/2;
						2'b00: c_div_count = (23+3+1)/2;
						endcase
					end
                    c_div_final = nan || infinity || mantissa_1 == 0 || (!issqrt&&(is_infinity_2 || mantissa_2 == 0));
                    c_dividing = !c_div_final && !issqrt;
					c_sqrting = !c_div_final && issqrt;
					c_div_exponent = issqrt?exp_sum_sqrt:exp_sum_div;
					c_div_nan = nan;
					c_div_infinity = infinity;
					c_div_zero = mantissa_1 == 0 || (is_infinity_2&&!issqrt);
					c_div_by_zero = mantissa_2 == 0 && !issqrt && !is_infinity_1;
					c_div_nz = !c_div_zero;
					c_div_quiet_nan = quiet_nan;
                    c_quotient = 0;
					c_sqrt_b = {1'b1, 55'b0};
                end
        5'b0?1??: begin: dd        // core of divider
                    casez ({c_new_remainder3[55], c_new_remainder2[55], c_new_remainder1[55]}) // synthesis full_case parallel_case
                    3'b0??: begin
								casez (r_div_sz) // synthesis full_case parallel_case
								2'b1?: c_quotient = {r_quotient[54:42], 2'b11, 42'b0};
                                2'b?1: c_quotient = {r_quotient[54: 0], 2'b11};
								2'b00: c_quotient = {r_quotient[54:30], 2'b11, 30'b0};
								endcase
                                c_remainder = {1'b0,c_new_remainder3[53:0], 2'b0};
                            end
                    3'b10?: begin
								casez (r_div_sz) // synthesis full_case parallel_case
								2'b1?: c_quotient = {r_quotient[54:42], 2'b10, 42'b0};
                                2'b?1: c_quotient = {r_quotient[54: 0], 2'b10};
								2'b00: c_quotient = {r_quotient[54:30], 2'b10, 30'b0};
								endcase
                                c_remainder = {1'b0,c_new_remainder2[53:0], 2'b0};
                            end
                    3'b110: begin
								casez (r_div_sz) // synthesis full_case parallel_case
								2'b1?: c_quotient = {r_quotient[54:42], 2'b01, 42'b0};
                                2'b?1: c_quotient = {r_quotient[54: 0], 2'b01};
								2'b00: c_quotient = {r_quotient[54:30], 2'b01, 30'b0};
								endcase
                                c_remainder = {1'b0,c_new_remainder1[53:0], 2'b0};
                            end
                    3'b111: begin
								casez (r_div_sz) // synthesis full_case parallel_case
								2'b1?: c_quotient = {r_quotient[54:42], 2'b00, 42'b0};
                                2'b?1: c_quotient = {r_quotient[54: 0], 2'b00};
								2'b00: c_quotient = {r_quotient[54:30], 2'b00, 30'b0};
								endcase
                                c_remainder = {1'b0,r_remainder[53:0], 2'b00};
                            end
                    endcase
                    c_div_count = r_div_count-1;
                    if (r_div_count == 0) begin
                        c_dividing = 0;
                        c_div_final = 1;
                    end
                  end
        5'b0??1?: begin: sq        // core of sqrt
					if (!c_sqrt_tmp[57]) begin
						c_remainder = {c_sqrt_tmp, 1'b0};
						c_divisor = r_divisor|{r_sqrt_b, 1'b0};
						casez (r_div_sz) // synthesis full_case parallel_case
						2'b1?: c_quotient = {r_quotient[55:42], 1'b1, 42'b0};
                        2'b?1: c_quotient = {r_quotient[55: 0], 1'b1};
						2'b00: c_quotient = {r_quotient[55:30], 1'b1, 30'b0};
						endcase
					end else begin
						c_remainder = {r_remainder, 1'b0};
						c_divisor = r_divisor;
						casez (r_div_sz) // synthesis full_case parallel_case
						2'b1?: c_quotient = {r_quotient[55:42], 1'b0, 42'b0};
                        2'b?1: c_quotient = {r_quotient[55: 0], 1'b0};
						2'b00: c_quotient = {r_quotient[55:30], 1'b0, 30'b0};
						endcase
					end
					c_sqrt_b = {1'b0, r_sqrt_b[56:1]};
                    c_div_count = r_div_count-1;
                    if (r_div_count == 0) begin
                        c_sqrting = 0;
                        c_div_final = 1;
                    end
				  end
        5'b00??1: begin        // final format
                        c_div_final = !valid_ack;
                  end
        5'b00000: ;    // idle
        default:  begin
                    c_dividing = 'bx;
                    c_remainder = 'bx;
                    c_quotient = 'bx;
                    c_div_count = 'bx;
                    c_div_res = 'bx;
					c_div_final = 'bx;
					c_div_exponent = 'bx;
					c_sqrting = 'bx;
                  end
        endcase
    end
	reg nv, uf, of;
	always @(*) begin
		c_div_res = 64'bx;
		nv = 0;
		uf = 0;
		casez (r_div_sz) // synthesis full_case parallel_case
		2'b1?:	begin
					if (r_div_nan) begin
						nv = !r_div_quiet_nan;
						c_div_res = {48'hffff_ffff_ffff, 6'h1f, 1'b1, 9'h0};  // quiet nan
					end else
					if (!r_div_infinity&calc_infinity&roverflow) begin
						c_div_res = {48'hffff_ffff_ffff, r_div_sign, 5'h1e, ~10'h0};  
					end else
					if (r_div_infinity|calc_infinity|r_div_by_zero) begin
						c_div_res = {48'hffff_ffff_ffff, r_div_sign, 5'h1f, 10'h0};  
					end else
					if (underflow&!x_underflow || is_zero) begin
						uf = r_div_nz;
						c_div_res = {48'hffff_ffff_ffff, rsign, 5'b0, 10'h0};
					end else begin
						uf = ((exponent[11] && exponent[3:0]==0 && mantissa[54:45]!=0) || (is_zero&&r_div_nz)) && nx;
						c_div_res = {48'hffff_ffff_ffff, rsign, ~exponent[11], exponent[3:0], mantissa[54:45]};
					end
				end
		2'b?1:	begin
					if (r_div_nan) begin
						nv = !r_div_quiet_nan;
						c_div_res = {12'h7ff, 1'b1, 51'h0};   // quiet nan
					end else
					if (!r_div_infinity&calc_infinity&roverflow) begin
						c_div_res = {r_div_sign, 11'h7fe, ~52'h0};
					end else
					if (r_div_infinity|calc_infinity|r_div_by_zero) begin
						c_div_res = {r_div_sign, 11'h7ff, 52'h0};
					end else
					if (underflow&!x_underflow || is_zero) begin
						uf = r_div_nz;
						c_div_res = {rsign, 11'b0, 52'h0};
					end else begin
						uf = ((exponent[11] && exponent[9:0]==0 && mantissa[54:3]!=0) || (is_zero&&r_div_nz)) && nx;
						c_div_res = {rsign, ~exponent[11], exponent[9:0], mantissa[54:3]};
					end
				end
		2'b00:	begin
					if (r_div_nan) begin
						nv = !r_div_quiet_nan;
						c_div_res = {32'hffff_ffff, 9'h0ff, 1'b1, 22'h0}; // quiet nan
					end else
					if (!r_div_infinity&calc_infinity&roverflow) begin
						c_div_res = {32'hffff_ffff, r_div_sign, 8'hfe, ~23'h0};
					end else
					if (r_div_infinity|calc_infinity|r_div_by_zero) begin
						c_div_res = {32'hffff_ffff, r_div_sign, 8'hff, 23'h0};
					end else
					if (underflow&!x_underflow || is_zero) begin
						uf = r_div_nz;
						c_div_res = {32'hffff_ffff, rsign, 8'b0, 23'h0};
					end else begin
						 uf = ((exponent[11] && exponent[6:0]==0 && mantissa[54:32]!=0) || (is_zero&&r_div_nz)) && nx;

						c_div_res = {32'hffff_ffff, rsign, ~exponent[11], exponent[6:0], mantissa[54:32]};
					end
				end
		endcase
		of = calc_infinity&!r_div_infinity&!nv&!r_div_nan;
	end

	assign exceptions = {nv, r_div_by_zero&~nv&!r_div_nan, of, uf, nx&~nv};

	assign rd_out = r_div_rd;
	assign hart_out = r_div_hart;
	assign res = c_div_res;
	assign valid = r_div_final;
    always @(posedge clk) begin
        r_div_count <= c_div_count;
        r_div_final <= c_div_final&!reset;
        r_remainder <= c_remainder;
        r_quotient <= c_quotient;
        r_div_rd <= c_div_rd;
        r_div_sign <= c_div_sign;
        r_div_hart <= c_div_hart;
        r_div_makes_rd <= c_div_makes_rd;
        r_dividing <= c_dividing&!reset;
        r_divisor <= c_divisor;
        r_divisor3 <= c_divisor3;
		r_div_exponent <= c_div_exponent;
		r_div_sz <= c_div_sz;
		r_div_rnd <= c_div_rnd;
		r_div_nan <= c_div_nan;
		r_div_infinity <= c_div_infinity;
		r_div_zero <= c_div_zero;
		r_div_by_zero <= c_div_by_zero;
		r_div_nz <= c_div_nz;
		r_sqrting <= c_sqrting;
		r_sqrt_b <= c_sqrt_b;
		r_div_quiet_nan <= c_div_quiet_nan;
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


