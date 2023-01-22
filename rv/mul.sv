//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-22 Paul Campbell - paul@taniwha.com
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

module mul(
	input clk,
	input reset, 
	input enable,
	input rv32,

	input [CNTRL_SIZE-1:0]control,
	input     [LNCOMMIT-1:0]rd,
	input	          makes_rd,
	input [RV-1:0]r1, r2,
	input   [(NHART==1?0:LNHART-1):0]hart,

	input [NCOMMIT-1:0]commit_kill_0,
	//input [NCOMMIT-1:0]commit_kill_1,

	output [RV-1:0]result,
	output [LNCOMMIT-1:0]res_rd, 
	output [NHART-1:0]res_makes_rd,
	output		   divide_busy,
	output [(NHART==1?0:LNHART-1):0]divide_hart,
	output [LNCOMMIT-1:0]divide_rd
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
	//	ctrl:  bit 5 == 0
	//	4 - mulw/divw
	//	3 - inv 
	//	2:1 - sgn
	//	0 - 0 rem/div 1 mul
	//
	//	4  3  2:1  0
	//	0  0    -  1	mul
	//	0  1    0  1	mulh
	//	0  1    1  1	mulhsu
	//	0  1    2  1	mulhu
	//	1  0    -  1	mulw
	//	0  0    1  0	div
	//	0  0    0  0	divu
	//	0  1    1  0	rem
	//	0  1    0  0	remu
	//	1  0    1  0	divw
	//	1  0    0  0	divuw
	//	1  1    1  0	remw
	//	1  1    0  0	remuw

	// bit 5 == 1
	//
	//	0  0    0  0	clmulr
	//	0  0    0  1	clmul
	//	0  1    0  0	clmulh
	//
	//	1  0    0  0	clmulrw
	//	1  0    0  1	clmulw
	//	1  1    0  0	clmulhw
	//	1  1    0  1	crc.*    type in immed[24:20]

	//	0  0    1  0	bdep
	//	0  0    1  1	bext
	//	1  0    1  0	bdepw
	//	1  0    1  1	bextw

	reg [RV-1:0]r_res, c_res;
	assign result = r_res;
	reg  [LNCOMMIT-1:0]r_res_rd, c_res_rd;
	assign res_rd = r_res_rd;
	reg  [NHART-1:0]r_res_makes_rd, c_res_makes_rd;
	assign res_makes_rd = r_res_makes_rd;
	reg	r_makes_rd;
	wire     mul;
	wire	inv;
	wire [1:0]sgn;
	wire	addw;
	assign bopt = control[5];
	assign addw = control[4];
	assign inv = control[3];
	assign mul = control[0];
	assign sgn = control[2:1];


	reg    [5:0]r_div_count, c_div_count;
	reg [RV-1:0]r_div_res, c_div_res;
	reg			r_div_start, c_div_start;
	reg			r_div_next, c_div_next;
	reg			r_div_last, c_div_last;
	reg			r_div_sign_last, c_div_sign_last;
	reg			r_div_rem_sign, c_div_rem_sign;
	reg			r_div_busy, c_div_busy;
	reg [2*RV-1:0]r_remainder, c_remainder;
	reg [RV-1:0]r_quotient, c_quotient;
	reg [RV-1:0]r_divisor, c_divisor;
	reg [RV+1:0]r_divisor3, c_divisor3;
	reg [LNCOMMIT-1:0]r_div_rd, c_div_rd;
	reg			r_div_makes_rd, c_div_makes_rd;
	reg  [(NHART==0?0:LNHART-1):0]r_div_hart, c_div_hart;
	reg			r_dividing, c_dividing;
	reg			r_div_addw, c_div_addw;
	reg			r_div_rem, c_div_rem;
	reg			r_div_sign, c_div_sign;
	assign divide_hart = c_div_hart;
	assign divide_rd = c_div_rd;

	reg			r_mul_busy_1, c_mul_busy_1;
	reg			r_mul_busy_2, c_mul_busy_2;
	reg			r_mul_makes_rd, c_mul_makes_rd;
	reg			r_mul_makes_rd2, c_mul_makes_rd2;
	reg  [(NHART==0?0:LNHART-1):0]r_mul_hart, c_mul_hart;
	reg  [(NHART==0?0:LNHART-1):0]r_mul_hart2, c_mul_hart2;
	reg [LNCOMMIT-1:0]r_mul_rd, c_mul_rd;
	reg [LNCOMMIT-1:0]r_mul_rd2, c_mul_rd2;
	reg [RV-1:0]r_mul_res, c_mul_res;
	reg			r_mul_addw, c_mul_addw;
	reg	   [1:0]r_mul_sgn, c_mul_sgn;
	reg			r_mul_inv, c_mul_inv;
`ifdef VSYNTH
	reg			r_mul_addw2, c_mul_addw2;
	reg	   [1:0]r_mul_sgn2, c_mul_sgn2;
	reg			r_mul_inv2, c_mul_inv2;
	wire [127:0]sp;
	wire [127:0]p, sup;
	smul64	smul(.clk(clk), .a(r1), .b(r2), .p(sp));
	sumul64	sumul(.clk(clk), .a(r1), .b(r2), .p(sup));
	mul64	umul(.clk(clk), .a(r1), .b(r2), .p(p));
`endif

	assign divide_busy = r_div_busy;

	reg		div_ack;
`ifdef B
	reg [63:0]c_res_clmul;
	reg		r_b_busy_2;
`else
	wire r_b_busy_2 = 0;
`endif

	always @(*) begin
		c_mul_busy_1 = 0;
		c_mul_busy_2 = 0;
		c_res_rd = 'bx;
		c_res = 'bx;
		div_ack = 0;
		c_res_makes_rd = 0;
		c_mul_makes_rd = 0;
		c_mul_makes_rd2 = r_mul_makes_rd && !commit_kill_0[r_mul_rd];
		c_mul_hart2 = r_mul_hart;
		c_mul_rd2 = r_mul_rd;
		c_mul_rd = r_mul_rd;
		c_mul_res = 64'bx;
		c_mul_sgn = r_mul_sgn;
		c_mul_hart = r_mul_hart;
		c_mul_inv = r_mul_inv;
		c_mul_addw = r_mul_addw;
`ifdef VSYNTH
		c_mul_addw2 = r_mul_addw;
		c_mul_inv2 = r_mul_inv;
		c_mul_sgn2 = r_mul_sgn;
`endif
		if (enable && (mul || bopt)) begin
			c_mul_hart = hart;
		end
		if (enable && mul && !bopt) begin
			c_mul_busy_1 = !commit_kill_0[rd];
			c_mul_rd = rd;
			c_mul_makes_rd = makes_rd && !commit_kill_0[rd];
			c_mul_addw = addw;
			c_mul_sgn = sgn;
			c_mul_inv = inv;
		end
		if (r_mul_busy_1) begin 
`ifndef VSYNTH
			if (rv32) begin :mm32
				reg [63:0] u1, u2;
				reg signed [63:0] s1, s2;
				reg signed [63:0]tmp;
				u1 = {32'b0, r1};
				u2 = {32'b0, r2};
				s1 = {{32{r1[31]}}, r1};
				s2 = {{32{r2[31]}}, r2};
				casez  ({r_mul_inv, r_mul_sgn})		// synthesis full_case parallel_case
				3'b0_??:begin						// mul
							tmp = s1*s2;
							c_mul_res = tmp[31:0];
						end 
				3'b1_00:begin						// mulh
							tmp = s1*s2;
							c_mul_res = tmp[63:32];
						end
				3'b1_01:begin						// mulhsu
							tmp = s1*r2;
							c_mul_res = tmp[63:32];
						end
				3'b1_10:begin						// mulhu
							tmp = r1*r2;
							c_mul_res = tmp[63:32];
						end
				default: c_mul_res = 'bx;
				endcase
			end else begin :mm64
				reg [127:0] u1, u2;
				reg signed [127:0] s1, s2;
				reg signed [127:0]tmp;
				u1 = {64'b0, r1};
				u2 = {64'b0, r2};
				s1 = {{64{r1[63]}},r1};
				s2 = {{64{r2[63]}},r2};

				casez  ({r_mul_addw, r_mul_inv, r_mul_sgn})		// synthesis full_case parallel_case
				4'b0_0_??:begin						// mul
							tmp = s1*s2;
							c_mul_res = tmp[63:0];
						end 
				4'b0_1_00:begin						// mulh
							tmp = s1*s2;
							c_mul_res = tmp[127:64];
						end
				4'b0_1_01:begin						// mulhsu
							tmp = s1*u2;
							c_mul_res = tmp[127:64];
						end
				4'b0_1_10:begin						// mulhu
							tmp = u1*u2;
							c_mul_res = tmp[127:64];
						end
				4'b1_0_??:begin						// mulw
							tmp = s1*s2;
							c_mul_res = {{32{tmp[31]}}, tmp[31:0]};
						end
				default: c_mul_res = 'bx;
				endcase
			end 
`endif
			c_mul_busy_2 = !commit_kill_0[r_mul_rd];
		end
		casez ({r_div_last, !commit_kill_0[r_mul_rd2], r_b_busy_2, r_mul_busy_2}) // synthesis full_case parallel_case
		4'b?0?1,
		4'b?01?: c_res = 'bx;
		4'b?1?1:begin
`ifdef VSYNTH
				casez  ({r_mul_addw2, r_mul_inv2, r_mul_sgn2})		// synthesis full_case parallel_case
				4'b0_0_??:begin						// mul
							c_res = sp[63:0];
						end 
				4'b0_1_00:begin						// mulh
							c_res = rv32?sp[63:32]:sp[127:64];
						end
				4'b0_1_01:begin						// mulhsu
							c_res = rv32?sup[63:32]:sup[127:64];
						end
				4'b0_1_10:begin						// mulhu
							c_res = rv32?p[63:32]:p[127:64];
						end
				4'b1_0_??:begin						// mulw
							c_res = {{32{sp[31]}}, sp[31:0]};
						end
				default: c_res = 'bx;
				endcase
`else
				c_res = r_mul_res;
`endif
				c_res_rd = r_mul_rd2;
				c_res_makes_rd[r_mul_hart2] = r_mul_makes_rd2 && !commit_kill_0[r_mul_rd2];
			end 
`ifdef B
		4'b?1?1:begin
				c_res = c_res_clmul;
				c_res_rd = r_mul_rd2;
				c_res_makes_rd[r_mul_hart2] = r_mul_makes_rd2 && !commit_kill_0[r_mul_rd2];
			end
`endif
		4'b1?00:begin
				div_ack = 1;
				if (r_div_addw) begin
					c_res = {{32{r_div_res[31]}},r_div_res[31:0]};
				end else begin
					c_res = r_div_res;
				end
				c_res_rd = r_div_rd;
				c_res_makes_rd[r_div_hart] = r_div_makes_rd && !commit_kill_0[r_div_rd];
			end
		default:
			c_res = 'bx;
		endcase
	end

	always @(*) begin
		c_div_res = r_div_res;
		c_quotient = 64'bx;
		c_remainder = 128'bx;
		c_div_sign_last = r_div_sign_last&!reset;
		c_div_last = r_div_last&!reset;
		c_dividing = r_dividing&!reset;
		c_div_addw = r_div_addw;
		c_div_rem = r_div_rem;
		c_div_rd = r_div_rd;
		c_div_hart = r_div_hart;
		c_div_rd = r_div_rd;
		c_div_start = r_div_start&!reset;
		c_div_next = r_div_next&!reset;
		c_div_sign = r_div_sign;
		c_div_busy = r_div_busy&!reset;
		c_div_makes_rd = r_div_makes_rd&&!commit_kill_0[r_div_rd];
		c_divisor = r_divisor;
		c_divisor3 = r_divisor3;
		c_div_count = r_div_count;
		c_div_rem_sign = r_div_rem_sign;
		if (enable && !mul && !bopt) begin
			c_div_busy = !commit_kill_0[rd];
			c_div_addw = addw;
			c_div_rem = inv;
			c_div_hart = hart;
			c_div_rd = rd;
			c_div_makes_rd = makes_rd &&!commit_kill_0[rd];
			c_div_sign = sgn[0];
			c_div_start = !commit_kill_0[rd];
		end else 
		casez ({commit_kill_0[r_div_rd], r_div_start, r_div_next, r_dividing, r_div_sign_last, r_div_last})// synthesis full_case parallel_case
		6'b1?????:begin			// abort 
					c_div_start = 0;
					c_div_next = 0;
					c_dividing = 0;
					c_div_sign_last = 0;
					c_div_last = 0;
					c_div_busy = 0;
					c_div_makes_rd = 0;
				  end
		6'b01????:begin			// save RF data, set up registers
					if (r_div_addw || rv32) begin
						c_div_sign = r_div_sign&(r1[31]^r2[31]);
						c_divisor = {32'b0, r_div_sign&r2[31]?(~r2[31:0])+32'b1:r2[31:0]};
						c_remainder = {63'b0, (r_div_sign&r1[31]?(~r1[31:0])+32'b1:r1[31:0]), 33'b0};
						c_div_count = 15;
						c_div_last = r2[31:0]==0;
						c_div_rem_sign = r_div_sign&r1[31];
					end else begin
						c_div_sign = r_div_sign&(r1[63]^r2[63]);
						c_divisor = r_div_sign&r2[63]?(~r2)+64'b1:r2;
						c_remainder = {63'b0, (r_div_sign&r1[63]?(~r1)+64'b1:r1), 1'b0};
						c_div_count = 31;
						c_div_last = r2==0;
						c_div_rem_sign = r_div_sign&r1[63];
					end
					c_div_next = !c_div_last;
					c_dividing = !c_div_last;
					c_div_res = r_div_rem?r1:~0;	// divide by 0 value
					c_div_start = 0;
				end
		6'b0?1???: begin			// short circuit early 0s
					c_divisor3 = {2'b0, r_divisor} + {1'b0, r_divisor, 1'b0};
					if (r_div_count >= 16 && r_remainder[127:96] == 32'h0 && r_divisor >= r_remainder[95:32]) begin
						c_div_count = r_div_count-16;
						c_remainder = {r_remainder[95:0], 32'h0};
					end else
					if (r_div_count >= 8 && r_remainder[127:112] == 16'h0 && r_divisor >= r_remainder[111:48]) begin
						c_div_count = r_div_count-8;
						c_remainder = {r_remainder[111:0], 16'h0};
					end else
					if (r_div_count >= 4 && r_remainder[127:120] == 8'h0 && r_divisor >= r_remainder[119:56]) begin
						c_div_count = r_div_count-4;
						c_remainder = {r_remainder[119:0], 8'h0};
					end else
					if (r_div_count >= 2 && r_remainder[127:124] == 4'h0 && r_divisor >= r_remainder[123:60]) begin
						c_div_count = r_div_count-2;
						c_remainder = {r_remainder[123:0], 4'h0};
						c_div_next = 0;
					end else begin
						c_remainder = r_remainder;
						c_div_next = 0;
					end
					c_quotient = 0;
				  end 
		6'b000100: begin: dd		// core of divider
					reg [66:0]c_new_remainder3;
					reg [66:0]c_new_remainder2;
					reg [66:0]c_new_remainder1;
					reg [63:0]c_rem;

					// 2 bits/clock
					c_new_remainder3 = {2'b0, r_remainder[127:63]}-{1'b0, r_divisor3};
					c_new_remainder2 = {2'b0, r_remainder[127:63]}-{2'b0, r_divisor, 1'b0};
					c_new_remainder1 = {2'b0, r_remainder[127:63]}-{3'b0, r_divisor};
					casez ({c_new_remainder3[66], c_new_remainder2[66], c_new_remainder1[66]}) // synthesis full_case parallel_case
					3'b0??:	begin
								c_quotient = {r_quotient[61:0], 2'b11};
								c_remainder = {c_new_remainder3[62:0], r_remainder[62:0], 2'b0};
								c_rem = c_new_remainder3[63:0];
							end
					3'b10?:	begin
								c_quotient = {r_quotient[61:0], 2'b10};
								c_remainder = {c_new_remainder2[62:0], r_remainder[62:0], 2'b0};
								c_rem = c_new_remainder2[63:0];
							end
					3'b110:	begin
								c_quotient = {r_quotient[61:0], 2'b01};
								c_remainder = {c_new_remainder1[62:0], r_remainder[62:0], 2'b0};
								c_rem = c_new_remainder1[63:0];
							end
					3'b111:	begin
								c_quotient = {r_quotient[61:0], 2'b00};
								c_remainder = {r_remainder[125:0], 2'b00};
								c_rem = r_remainder[126:63];
							end
					endcase
					c_div_count = r_div_count-1;
					if (r_div_count == 0) begin
						c_dividing = 0;
						c_div_res = r_div_rem?c_rem:c_quotient;
						if (!r_div_rem? r_div_sign:r_div_rem_sign) begin
							c_div_sign_last = 1;
						end else begin
							c_div_last = 1;
						end
					end 
				  end
		6'b0???1?: begin		// invert the output
					c_div_res = (~r_div_res)+1;
					c_div_sign_last = 0;
					c_div_last = 1;
				  end 
		6'b0????1: begin		// waiting for the write port
					if (div_ack) begin 
						c_div_busy = 0;
						c_div_last = 0;
					end
			      end 
		6'b000000: ;	// idle
		default:  begin
					c_div_start = 'bx;
					c_div_next = 'bx;
					c_dividing = 'bx;
					c_div_sign_last = 'bx;
					c_div_last = 'bx;
					c_div_busy = 'bx;
					c_remainder = 'bx;
					c_quotient = 'bx;
					c_div_count = 'bx;
					c_div_res = 'bx;
				  end
		endcase
	end

	always @(posedge clk) begin
        r_res_makes_rd <= c_res_makes_rd;
		r_res_rd <= c_res_rd;
		r_res <= c_res;

		r_div_count <= c_div_count;
		r_div_res <= c_div_res;
		r_div_start <= c_div_start;
		r_div_next <= c_div_next;
		r_div_last <= c_div_last;
		r_div_sign_last <= c_div_sign_last;
		r_div_rem_sign <= c_div_rem_sign;
		r_div_busy <= c_div_busy;
		r_remainder <= c_remainder;
		r_quotient <= c_quotient;
		r_div_rd <= c_div_rd;
		r_div_sign <= c_div_sign;
		r_div_hart <= c_div_hart;
		r_div_makes_rd <= c_div_makes_rd;
		r_dividing <= c_dividing;
		r_div_addw <= c_div_addw;
		r_div_rem <= c_div_rem;
		r_divisor <= c_divisor;
		r_divisor3 <= c_divisor3;

		r_mul_busy_1 <= c_mul_busy_1;
		r_mul_busy_2 <= c_mul_busy_2;
		r_mul_makes_rd <= c_mul_makes_rd;
		r_mul_makes_rd2 <= c_mul_makes_rd2;
		r_mul_hart <= c_mul_hart;
		r_mul_hart2 <= c_mul_hart2;
		r_mul_rd <= c_mul_rd;
		r_mul_rd2 <= c_mul_rd2;
		r_mul_res <= c_mul_res;
		r_mul_addw <= c_mul_addw;
		r_mul_sgn <= c_mul_sgn;
		r_mul_inv <= c_mul_inv;
`ifdef VSYNTH
		r_mul_addw2 <= c_mul_addw2;
		r_mul_sgn2 <= c_mul_sgn2;
		r_mul_inv2 <= c_mul_inv2;
`endif
	end

`ifdef B
	reg r_b_busy_1, c_b_busy_1;
	reg             c_b_busy_2;
	reg r_b_addw_1, c_b_addw_1;
	reg r_b_addw_2;

	always @(*) begin
		c_b_busy_1 = 0;
		c_b_busy_2 = 0;
		
		if (enable && bopt) begin
			c_b_busy_1 = 1;
			c_b_addw_1 = addw;
		end
		if (r_b_busy_1) begin
			c_b_busy_2 = 1;
		end
	end
		
	always @(posedge clk) begin
		r_b_addw_1 <= c_b_addw_1;
		r_b_addw_2 <= r_b_addw_1;
		r_b_busy_1 <= c_b_busy_1;
		r_b_busy_2 <= c_b_busy_2;
	end

`include "mk19_64.inc"

	reg [3:0]r_clm_ctrl_1, r_clm_ctrl_2;
	always @(posedge clk) begin
		r_clm_ctrl_1 <= {sgn[0], addw, inv, mul};
		r_clm_ctrl_2 <= r_clm_ctrl_1;
	end

	wire [63:0]ext_dep_res;

	always @(*)
	casez (r_clm_ctrl_2) // synthesis full_case parallel_case
	4'b0_0_00: c_res_clmul = clmul_res[126:63];        // clrmulr 
	4'b0_0_01: c_res_clmul = clmul_res[63:0];         // clrmul 
	4'b0_0_10: c_res_clmul = {1'b0, clmul_res[126:64]};// clrmulh 
	4'b0_1_00: c_res_clmul = {{32{clmul_res[62]}}, clmul_res[62:30]}; // clrmulrw 
	4'b0_1_01: c_res_clmul = {{32{clmul_res[31]}}, clmul_res[31:0]};          // clrmulw 
	4'b0_1_10: c_res_clmul = {33'b0, clmul_res[62:32]};// clrmulhw 
	4'b1_0_??: c_res_clmul = ext_dep_res;
	4'b1_1_??: c_res_clmul = {{32{ext_dep_res[31]}}, ext_dep_res[31:0]};
	default: c_res_clmul = 'bx;
	endcase


	bextdep64p2	bextdep(.clock(clk),
			.reset(reset),
			.din_value(r1),
			.din_mode({1'b0, ~r_clm_ctrl_1[0]}),
			.din_valid(r_b_busy_1&r_clm_ctrl_1[3]),
			.din_mask(r2),
			.dout_ready(1'b1),
			.dout_result(ext_dep_res));

`endif


endmodule

`ifdef B
`include "bextdep.v"
`include "bextdep_pps.v"
`endif

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


