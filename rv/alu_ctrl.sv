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

// NCOMMIT sized barrel shifter
module rot(input [NCOMMIT-1:0]in, output [NCOMMIT-1:0]out, input [LNCOMMIT-1:0]r);
       	parameter NCOMMIT = 32; // number of commit registers
        parameter LNCOMMIT = $clog2(NCOMMIT); // number of bits to encode that

	reg [NCOMMIT-1:0]o;
	assign out = o;
	always @(*) begin :u
		int i;
		for (i = 0; i < NCOMMIT; i++)
			o[i] = in[(r+i)&(NCOMMIT-1)];
	end

endmodule


//
//	alu scheduler - largely made from C code
//
module alu_ctrl(
	input clk,
	input reset, 
	
`ifdef AWS_DEBUG
	input trig_in,
	output trig_in_ack,
	output trig_out,
	input trig_out_ack,
	input xxtrig,
`endif
`ifdef FP
`ifdef NSTORE2
`include "alu_ctrl_hdr_4_1_32_2_1_1_1_2_2_1.inc"
`else
`include "alu_ctrl_hdr_4_1_32_2_1_1_1_2_1_1.inc"
`endif
`else
`ifdef NALU3
`include "alu_ctrl_hdr_4_1_32_3_1_1_1_2_1_0.inc"
`else
`ifdef NSTORE2
`include "alu_ctrl_hdr_4_1_32_2_1_1_1_2_2_0.inc"
`else
`include "alu_ctrl_hdr_4_1_32_2_1_1_1_2_1_0.inc"
`endif
`endif
`endif
	input dummy);

        parameter ADDR=0;
        parameter NHART=1;
        parameter LNHART=0;
       	parameter NCOMMIT = 32; // number of commit registers
        parameter LNCOMMIT = 5; // number of bits to encode that
 	parameter RA=5;
 	parameter RV=64;
	parameter NSHIFT = 1;
	parameter NMUL = 1;
	parameter NLOAD = 1;
	parameter NSTORE=1;
	parameter NLDSTQ=4;
	parameter NALU = 2;
	parameter NFPU = 0;
	parameter NBRANCH = 1;

	generate
`ifdef FP
		if (NFPU==1 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 2 && NSTORE == 1 && NALU == 2 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_2_1_1_1_2_1_1.inc"
`ifdef NALU3
		end else
		if (NFPU==1 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 2 && NSTORE == 1 && NALU == 3 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_2_1_1_1_2_1_1.inc"
`endif
		end else
		if (NFPU==1 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 3 && NSTORE == 2 && NALU == 2 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_2_1_1_1_3_2_1.inc"
		end else
		if (NFPU==1 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 2 && NSTORE == 2 && NALU == 2 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_2_1_1_1_2_2_1.inc"
		end
`endif
		if (NFPU==0 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 2 && NSTORE == 1 && NALU == 2 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_2_1_1_1_2_1_0.inc"
`ifdef NALU3
		end else
		if (NFPU==0 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 2 && NSTORE == 1 && NALU == 3 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_3_1_1_1_2_1_0.inc"
`endif
		end else
		if (NFPU==0 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 3 && NSTORE == 2 && NALU == 2 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_2_1_1_1_3_2_0.inc"
		end else
		if (NFPU==0 && NHART == 1 && NCOMMIT == 32 && NSHIFT == 1 && NMUL == 1 && NLOAD == 2 && NSTORE == 2 && NALU == 2 && NBRANCH == 1) begin
`include "alu_ctrl_core_4_1_32_2_1_1_1_2_2_0.inc"
		end
`ifdef AWS_DEBUG
	ila_sched ila_sched(.clk(clk),
		.xxtrig(xxtrig),
		.trig_in(trig_in),
		.trig_in_ack(trig_in_ack),
		.trig_out(trig_out),
		.trig_out_ack(trig_out_ack),

		.load_ready_0(load_ready_0),
		.load_not_ready_0(load_not_ready_0),
		.load_r0(load_r0),
		.load_not_r0(load_not_r0),
		.lsm(lsm),
		.start_commit_0(start_commit_0),
		.load_ready0(load_enable_0),
		.load_out0(load_addr_0),
		.load_ready1(load_enable_1),
		.load_out1(load_addr_1),
		.store_ready0(store_enable_0),
		.store_out0(store_addr_0),
		.ge1(ge1),
		.ge2(ge2));
`endif
	endgenerate

	

endmodule
