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

module shift(
    input clk,
    input reset,
	input enable,
`ifdef SIMD
	input simd_enable,
`endif

    input [CNTRL_SIZE-1:0]control,
    input     [LNCOMMIT-1:0]rd,
    input             makes_rd,
    input             needs_rs2,
    input [RV-1:0]r1, r2, r3,
    input [31:0]immed,
	input   [(NHART==1?0:LNHART-1):0]hart,
	input   rv32,

    output [RV-1:0]result,
    output [LNCOMMIT-1:0]res_rd,
    output [NHART-1:0]res_makes_rd
    );

    parameter CNTRL_SIZE=7;
    parameter NDEC = 4; // number of decode stages
    parameter ADDR=0;
    parameter NHART=1;
    parameter LNHART=0;
	parameter RV=64;
    parameter NCOMMIT = 32; // number of commit registers
    parameter LNCOMMIT = 5; // number of bits to encode that
    parameter RA=5;

    // 
    //      ctrl:
	//  5:3: == 000
	//	2:	32-bit
	//	1:	arithmetic=1, logical=0
	//	0: 	0=sl, 1=sr
	//
	//  5:3:  == 001		B extensions
	//	2:  32-bit
	//	1:	rol=1, SxO=0
	//	0: 	0=sl, 1=sr
	//
	//	5:3:  == 010
	//	2:  32-bit
	//  1-0: 00 - orc
	//		 01 - rev8
	//		 10 - zip
	//		 11 - unzip
	//
	//	5:3:  == 011
	//	2:  32-bit
	//  1-0: 00 - bclr
	//		 01 - bset
	//		 10 - binv
	//		 11 - bext
	//
	//	5:3:  == 100
	//	2:  32-bit
	//  1-0: 00 - slliu bit 2==1
	//	     //01 - bmatflp
	//		 10 - sext.b
	//		 11 - sext.h
	//
	//	5:3:  == 101
	//	2:  32-bit
	//  1-0: 00 - xperm8
	//		 01 - xperm4
	//		 //10 - bfp
	//		 //11 - ??
	//
	//	5:3:  == 110
	//	2:  32-bit
	//  1-0: //00 - bdep
	//		 01 - brev8
	//		 10 - pack/packw / zext
	//		 11 - packh
	//
	//	5:3:  == 111
	//	2:  32-bit
	//  1-0: //00 - fsl
	//		 //01 - fsr
	//		 //10 - cmix
	//		 //11 - cmov 
	//
	

    reg [RV-1:0]r_res, c_res;
    assign result = r_res;                          
    reg  [LNCOMMIT-1:0]r_res_rd, r_rd;                     
    assign res_rd = r_res_rd;               
	reg  [NHART-1:0]r_res_makes_rd;
	reg		r_makes_rd;
    assign res_makes_rd = r_res_makes_rd;            
	wire    right, arith;
	wire	addw;
	reg [2:0] r_op, op;
	assign addw = rv32|control[2];
	assign right = control[0];
	assign arith = control[1];
	assign op = control[5:3];
	reg    r_right, r_arith;
	reg	r_addw, r_needs_rs2;
	reg [5:0]r_immed;

    wire [5:0]sr2 = (r_needs_rs2?r2[5:0]:r_immed[5:0])&{~rv32,5'b11111};


    always @(posedge clk) begin                     
		r_op <= op;
		r_needs_rs2 <= needs_rs2;
		r_right <= right;
		r_arith <= arith;
		r_addw <= addw;
		r_makes_rd <= makes_rd&enable;
		r_immed <= immed[5:0];
        r_rd <= rd;
        r_res_rd <= r_rd;
        r_res <= c_res;
`ifdef SIMD
		if (r_makes_rd && simd_enable) $display("s %d @%x<=%x",$time,r_rd,c_res);
`endif
    end
	genvar H;
	generate
		if (NHART == 1) begin
        		always @(posedge clk) 
                		r_res_makes_rd <= r_makes_rd;
		end else begin
			reg [NHART-1:0]r_hart;
			for (H = 0; H < NHART; H=H+1) begin
				always @(posedge clk)
					r_hart[H] <= hart == H;
			end
			always @(posedge clk)
				r_res_makes_rd <= (r_makes_rd?r_hart:0);
		end
	endgenerate

	wire fill = r_arith&r1[63];
	wire fill32 = r_arith&r1[31];
`include "mk6_64.inc"

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


