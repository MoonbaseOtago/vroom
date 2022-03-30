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


// multi-CPU IO switch
module rv_io_dtb(
    input clk,
    input reset,

    input              addr_req,
    output             addr_ack,
    input			   sel,
    input        [11:0]addr,
    input              read,

    output             data_req,
    input              data_ack,
    output     [RV-1:0]rdata);

	
	parameter RV=64;

	reg [11:3]r_addr;
	reg		  r_req;
	assign data_req = r_req;

	dtbrom dtbrom(.addr(r_addr), .data(rdata));

	assign addr_ack = addr_req&&sel;

	always @(posedge clk) begin
		if (sel && read)
			r_addr <= addr[11:3];
		if (reset) begin
			r_req <= 0;
		end else
		if (addr_req && sel && read) begin
			r_req <= 1;
		end else
		if (data_ack)
			r_req <= 0;
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

