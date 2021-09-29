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

module   spi(
	input		clk,
	input		reset,
    input		addr_req,
	output		addr_ack,
    input		sel,
    input  [7:0]addr,
	input		read,
	input  [7:0]mask,
    input  [7:0]wdata,

    output		data_req,
    input		data_ack,
    output [63:0]rdata,

	output		spiCS_n,
	output		spiClkOut,
	input		spiDataIn,
	output		spiDataOut
            );

	wire [7:0]data_o;

	reg [7:0]r_data;
	assign rdata = {56'b0, r_data};
	reg		 r_data_req;
	assign data_req = r_data_req;

	always @(posedge clk)
	if (addr_ack)
		r_data <=data_o;
	always @(posedge clk)
	if (reset) r_data_req <= 0; else
	if (read && addr_ack) r_data_req <= 1; else
	if (data_ack) r_data_req <= 0;

	spiMaster spi(
		.rst_i(reset),
		.clk_i(clk),
		.address_i(addr),
		.data_i(wdata),
		.data_o(data_o),
		.strobe_i(addr_req&&sel&&mask[0]),
		.we_i(~read),
		.ack_o(addr_ack),

		.spiCS_n(spiCS_n),
		.spiClkOut(spiClkOut),
		.spiDataIn(spiDataIn),
		.spiDataOut(spiDataOut),

		.spiSysClk(clk)
		);

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

