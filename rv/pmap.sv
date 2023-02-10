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

`include "lstypes.si"

module pmp_checker(
	input		m,				// machine mode
	input		su,				// supervisor/user modes
	input		mmwp,			// machine mode whitelist policy
	input		mml,			// machine mode lockdown
	input		mprv,		
	input	[NPHYS-1:2]addr,
	input	[1:0]sz,			// 0: 1-4, 1: 8, 2: 16
	
	input		 check_x,
	input		 check_r,
	input		 check_w,

	output		 fail,

	PMP			 pmp
        );      
    parameter NPHYS=56;
	parameter NUM_PMP = 5;

	genvar I;

	wire su_default = ~|pmp.valid;

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
					lo1 = pmp.start[I] <= addr;
					lo2 = pmp.start[I] <= nd;
					hi1 = addr <= pmp.aend[I];
					hi2 = nd <= pmp.aend[I];
					match[I] = pmp.valid[I] && !((!lo1&&!lo2) || (!hi1&&!hi2));	// neither enclosed 
					casez({mml, pmp.locked[I], pmp.prot[I]}) // synthesis full_case parallel_case
					5'b1_1111:	bad[I] = !(lo1&&hi2) || check_w || check_x;
					5'b1_??10:	bad[I] = (!(lo1&&hi2) ||
										(pmp.locked[I] ? (check_w || check_r&!m) : check_x || check_w&!m&pmp.prot[I][1]));
											
					default:	bad[I] = (!(lo1&&hi2) || 
										((pmp.prot[I]&{check_x, check_w, check_r}) == 0)) &&
										(mml? (pmp.locked[I]? !m : !su) : (pmp.locked[I] || su || m&mprv));
					endcase
				end
				assign mx[I] = match[I];
				assign b[I] = bad[I];
			end else begin
				assign mx[I] = 0;
				assign b[I] = 0;
			end
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
		16'b0000_0000_0000_0000: f = m ? mmwp : su&!su_default;
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

