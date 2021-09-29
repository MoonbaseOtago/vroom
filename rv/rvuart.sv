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


// multi-CPU IO switch
module rv_io_uart(
    input clk,
    input reset,

    input              addr_req,
    output             addr_ack,
	input			   sel,
    input        [11:0]addr,
    input              read,
    input         [7:0]mask,
    input      [RV-1:0]wdata,

    output             data_req,
    input              data_ack,
    output     [RV-1:0]rdata,

	output			   interrupt,

	output			   tx,
	input			   rx,
	output			   rts,
	input			   cts
	);

	parameter RV=64;

	wire [7:0]xrdata;

	wire ack;
	reg [7:0]r_data;
	assign rdata = {56'b0, r_data};

	reg r_data_req;
	reg r_backoff;
	assign data_req = r_data_req;

	always @(posedge clk) begin
		if (reset) begin
			r_data_req <= 0;
		end else
		if (addr_ack&read) begin
			r_data <= xrdata;
			r_data_req <= 1;
		end else
		if (data_ack)
			r_data_req <= 0;
	end	


	always @(posedge clk) 
		r_backoff <= !reset && addr_req &&addr_ack; 

	wire dtr;
	uart_top uart(
				.wb_clk_i(clk),
				// Wishbone signals
				.wb_rst_i(reset),
				.wb_adr_i(addr[5:3]),
				.wb_dat_i(wdata[7:0]),
				.wb_dat_o(xrdata), 
				.wb_we_i(!read), 
				.wb_sel_i(mask[3:0]),
				.wb_stb_i(addr_req&!r_backoff&sel), 
				.wb_cyc_i(addr_req&!r_backoff&sel), 
				.wb_ack_o(addr_ack), 
				.int_o(interrupt), // interrupt request

				// UART signals
				// serial input/output
				.stx_pad_o(tx), 
				.srx_pad_i(rx),

		        // modem signals
				.rts_pad_o(rts),
				.cts_pad_i(cts),
				//dtr_pad_o,
				.dsr_pad_i(1'b0),
				.ri_pad_i(1'b0),
				.dcd_pad_i(1'b0),
				.dtr_pad_o(dtr)
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
