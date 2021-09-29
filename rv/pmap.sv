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

module pmp_checker(
	input		m,
	input		su,
	input		mprv,
	input	[NPHYS-1:2]addr,
	input	[1:0]sz,			// 0: 1-4, 1: 8, 2: 16
	
	input		 check_x,
	input		 check_r,
	input		 check_w,

	output		 fail,

	input [NUM_PMP-1:0]pmp_valid,		// sadly arrays of buses aren't well supported 
	input [NUM_PMP-1:0]pmp_locked,		// so we need to get verbose - unused wires will be optimised
	input [NPHYS-1:2]pmp_start_0,		// out during synthesis
	input [NPHYS-1:2]pmp_start_1,
	input [NPHYS-1:2]pmp_start_2,
	input [NPHYS-1:2]pmp_start_3,
	input [NPHYS-1:2]pmp_start_4,
	input [NPHYS-1:2]pmp_start_5,
	input [NPHYS-1:2]pmp_start_6,
	input [NPHYS-1:2]pmp_start_7,
	input [NPHYS-1:2]pmp_start_8,
	input [NPHYS-1:2]pmp_start_9,
	input [NPHYS-1:2]pmp_start_10,
	input [NPHYS-1:2]pmp_start_11,
	input [NPHYS-1:2]pmp_start_12,
	input [NPHYS-1:2]pmp_start_13,
	input [NPHYS-1:2]pmp_start_14,
	input [NPHYS-1:2]pmp_start_15,
	input [NPHYS-1:2]pmp_end_0,
	input [NPHYS-1:2]pmp_end_1,
	input [NPHYS-1:2]pmp_end_2,
	input [NPHYS-1:2]pmp_end_3,
	input [NPHYS-1:2]pmp_end_4,
	input [NPHYS-1:2]pmp_end_5,
	input [NPHYS-1:2]pmp_end_6,
	input [NPHYS-1:2]pmp_end_7,
	input [NPHYS-1:2]pmp_end_8,
	input [NPHYS-1:2]pmp_end_9,
	input [NPHYS-1:2]pmp_end_10,
	input [NPHYS-1:2]pmp_end_11,
	input [NPHYS-1:2]pmp_end_12,
	input [NPHYS-1:2]pmp_end_13,
	input [NPHYS-1:2]pmp_end_14,
	input [NPHYS-1:2]pmp_end_15,
	input	[2:0]pmp_prot_0,
	input	[2:0]pmp_prot_1,
	input	[2:0]pmp_prot_2,
	input	[2:0]pmp_prot_3,
	input	[2:0]pmp_prot_4,
	input	[2:0]pmp_prot_5,
	input	[2:0]pmp_prot_6,
	input	[2:0]pmp_prot_7,
	input	[2:0]pmp_prot_8,
	input	[2:0]pmp_prot_9,
	input	[2:0]pmp_prot_10,
	input	[2:0]pmp_prot_11,
	input	[2:0]pmp_prot_12,
	input	[2:0]pmp_prot_13,
	input	[2:0]pmp_prot_14,
	input	[2:0]pmp_prot_15

        );      
    parameter NPHYS=56;
	parameter NUM_PMP = 5;

	genvar I;

	wire [NPHYS-1:2]pmp_start[0:NUM_PMP-1];
	wire [NPHYS-1:2]pmp_end[0:NUM_PMP-1];
	wire [2:0]pmp_prot[0:NUM_PMP-1];

	wire su_default = ~|pmp_valid;

	reg		[NUM_PMP-1:0]match;
	reg		[NUM_PMP-1:0]bad;
	wire		[15:0]b, mx;
	generate
		for (I=0; I<16; I=I+1) begin : cmp

			if (I < NUM_PMP) begin
				always @(*) begin : a
					reg lo1, lo2, hi1, hi2;
					reg [NPHYS-1:2]nd;
	
					case (sz)	// synthesis full_case parallel_case
					0:	begin	// 1-4 bytes
							nd = addr;
						end
					1:	begin	// 8 bytes
							nd = {addr[NPHYS-1:3], 1'b1};
						end
					2:	begin	// 16 bytes
							nd = {addr[NPHYS-1:4], 2'b11};
						end
					default: nd = 'bx;
					endcase
					lo1 = pmp_start[I] <= addr;
					lo2 = pmp_start[I] <= nd;
					hi1 = addr <= pmp_end[I];
					hi2 = nd <= pmp_end[I];
					match[I] = pmp_valid[I] && !((!lo1&&!lo2) || (!hi1&&!hi2));	// neither enclosed 
					bad[I] = (!(lo1&&hi2) || ((pmp_prot[I]&{check_x, check_w, check_r}) == 0)) && (pmp_locked[I] || su || m&mprv);
					//          1         ||         1                                                0              1
				end
				assign mx[I] = match[I];
				assign b[I] = bad[I];
			end else begin
				assign mx[I] = 0;
				assign b[I] = 0;
			end
		end

		if (NUM_PMP >= 1) begin
			assign pmp_start[0] = pmp_start_0;
			assign pmp_end[0] = pmp_end_0;
			assign pmp_prot[0] = pmp_prot_0;
		end
		if (NUM_PMP >= 2) begin
			assign pmp_start[1] = pmp_start_1;
			assign pmp_end[1] = pmp_end_1;
			assign pmp_prot[1] = pmp_prot_1;
		end
		if (NUM_PMP >= 3) begin
			assign pmp_start[2] = pmp_start_2;
			assign pmp_end[2] = pmp_end_2;
			assign pmp_prot[2] = pmp_prot_2;
		end
		if (NUM_PMP >= 4) begin
			assign pmp_start[3] = pmp_start_3;
			assign pmp_end[3] = pmp_end_3;
			assign pmp_prot[3] = pmp_prot_3;
		end
		if (NUM_PMP >= 5) begin
			assign pmp_start[4] = pmp_start_4;
			assign pmp_end[4] = pmp_end_4;
			assign pmp_prot[4] = pmp_prot_4;
		end
		if (NUM_PMP >= 6) begin
			assign pmp_start[5] = pmp_start_5;
			assign pmp_end[5] = pmp_end_5;
			assign pmp_prot[5] = pmp_prot_5;
		end
		if (NUM_PMP >= 7) begin
			assign pmp_start[6] = pmp_start_6;
			assign pmp_end[6] = pmp_end_6;
			assign pmp_prot[6] = pmp_prot_6;
		end
		if (NUM_PMP >= 8) begin
			assign pmp_start[7] = pmp_start_7;
			assign pmp_end[7] = pmp_end_7;
			assign pmp_prot[7] = pmp_prot_7;
		end
		if (NUM_PMP >= 9) begin
			assign pmp_start[8] = pmp_start_8;
			assign pmp_end[8] = pmp_end_8;
			assign pmp_prot[8] = pmp_prot_8;
		end
		if (NUM_PMP >= 10) begin
			assign pmp_start[9] = pmp_start_9;
			assign pmp_end[9] = pmp_end_9;
			assign pmp_prot[9] = pmp_prot_9;
		end
		if (NUM_PMP >= 11) begin
			assign pmp_start[10] = pmp_start_10;
			assign pmp_end[10] = pmp_end_10;
			assign pmp_prot[10] = pmp_prot_10;
		end
		if (NUM_PMP >= 12) begin
			assign pmp_start[11] = pmp_start_11;
			assign pmp_end[11] = pmp_end_11;
			assign pmp_prot[11] = pmp_prot_11;
		end
		if (NUM_PMP >= 13) begin
			assign pmp_start[12] = pmp_start_12;
			assign pmp_end[12] = pmp_end_12;
			assign pmp_prot[12] = pmp_prot_12;
		end
		if (NUM_PMP >= 14) begin
			assign pmp_start[13] = pmp_start_13;
			assign pmp_end[13] = pmp_end_13;
			assign pmp_prot[13] = pmp_prot_13;
		end
		if (NUM_PMP >= 15) begin
			assign pmp_start[14] = pmp_start_14;
			assign pmp_end[14] = pmp_end_14;
			assign pmp_prot[14] = pmp_prot_14;
		end
		if (NUM_PMP >= 16) begin
			assign pmp_start[15] = pmp_start_15;
			assign pmp_end[15] = pmp_end_15;
			assign pmp_prot[15] = pmp_prot_15;
		end

	endgenerate

	reg	f;
	always @(*) begin
		casez (mx) // synthesis full_case parallel_case
		16'b????_????_????_???1: f = b[0];
		16'b????_????_????_??10: f = b[1];
		16'b????_????_????_?100: f = b[2];
		16'b????_????_????_1000: f = b[3];
		16'b????_????_???1_0000: f = b[4];
		16'b????_????_??10_0000: f = b[5];
		16'b????_????_?100_0000: f = b[6];
		16'b????_????_1000_0000: f = b[7];
		16'b????_???1_0000_0000: f = b[8];
		16'b????_??10_0000_0000: f = b[9];
		16'b????_?100_0000_0000: f = b[10];
		16'b????_1000_0000_0000: f = b[11];
		16'b???1_0000_0000_0000: f = b[12];
		16'b??10_0000_0000_0000: f = b[13];
		16'b?100_0000_0000_0000: f = b[14];
		16'b1000_0000_0000_0000: f = b[15];
		16'b0000_0000_0000_0000: f = su&!su_default;
		endcase
	end

	assign fail = f;


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

