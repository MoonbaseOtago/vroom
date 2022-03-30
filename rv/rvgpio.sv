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

//
// gpio interface
//
//
//			0-3:	read pins				- read only
//			8-11:	write pins				- rw of output register
//			16-19:	direction				- 1 output - 0 input
//			24-27:	open collector			- 1 enable
//			32-27:	pullup enable			- 1 on
//			40-43:	interrupt status		- 1 clears, 0 ignored
//			48-51:	interrupt enable		- 1 enabled
//			56-59:	edge/level interrupt	- 0 edge 1 level
//			64-67:	polarity				- 1 pos edge/1 level - 0 neg edge/0 level
//			
//
//
module rv_io_gpio(
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

`ifdef VS2
	input	     [31:0]gpio_pads
`else
`ifdef VERILATOR
	input	     [31:0]gpio_pads
`else
	inout	     [31:0]gpio_pads
`endif
`endif
	);
	parameter RV=64;

	assign addr_ack = addr_req&sel;

	reg [31:0]r_data;
	assign rdata = {32'b0,r_data};

	reg r_data_req;
	assign data_req = r_data_req;

	reg [31:0]r_data_out;
	reg [31:0]r_direction;
	reg [31:0]r_open_collector;
	reg [31:0]r_pullup_enable;
	reg [31:0]r_interrupt_pending;
	reg [31:0]r_interrupt_enable;
	reg [31:0]r_level_edge;
	reg [31:0]r_polarity;


	genvar I;
	generate
		for (I = 0; I < 32; I=I+1) begin: pad
			gpio_pad p(.pad(gpio_pads[I]),
							.clk(clk),
							.in(in[I]),
							.out(r_data_out[I]),
							.direction(r_direction[I]),
							.oc(r_open_collector[I]),
							.pull(r_pullup_enable[I]));
		end
	endgenerate

	wire [31:0]in;
	reg [31:0]r_data_in;
	
	always @(posedge clk) 
		r_data_in <= in;

	assign interrupt = |(r_interrupt_pending&r_interrupt_enable);

	wire [31:0]xint = (r_level_edge&r_polarity&in) |
					  (r_level_edge&~r_polarity&~in) |
					  (~r_level_edge&r_polarity&in&~r_data_in) |
					  (~r_level_edge&~r_polarity&~in&r_data_in);

	wire [31:0]xclr = (sel & addr_req & !read ?
								{mask[3]?wdata[31:24]:8'b0,
								 mask[3]?wdata[23:16]:8'b0,
								 mask[3]?wdata[15: 8]:8'b0,
								 mask[3]?wdata[ 7: 0]:8'b0}:32'b0);

	always @(posedge clk)
	if (reset) begin
		r_interrupt_pending <= 0;
	end else begin
		r_interrupt_pending <= (r_interrupt_pending&~xclr) | xint;	// xint takes priorty so we never miss
	end

	always @(posedge clk)
	if (reset) begin
		r_data_out <= 0;
		r_direction <= 0;
		r_open_collector <= 0;
		r_pullup_enable <= 32'hffffffff;
		r_interrupt_enable <= 0;
		r_level_edge <= 0;
		r_polarity <= 0;
	end else 
	if (sel & addr_req & !read) begin
		case (addr[11:3])	// synthesis full_case parallel_case
		0:	;	//			0-3:	read pins				- read only
		1:		//			8-11:	write pins				- rw of output register
			begin
				if (mask[0]) r_data_out[7:0]   <= wdata[7:0];
				if (mask[1]) r_data_out[15:8]  <= wdata[15:8];
				if (mask[2]) r_data_out[23:16] <= wdata[23:16];
				if (mask[3]) r_data_out[31:24] <= wdata[31:24];
			end
		2:		//			16-19:	direction				- 1 output - 0 input
			begin
				if (mask[0]) r_direction[7:0]   <= wdata[7:0];
				if (mask[1]) r_direction[15:8]  <= wdata[15:8];
				if (mask[2]) r_direction[23:16] <= wdata[23:16];
				if (mask[3]) r_direction[31:24] <= wdata[31:24];
			end
		3:		//			24-27:	open collector			- 1 enable
			begin
				if (mask[0]) r_open_collector[7:0]   <= wdata[7:0];
				if (mask[1]) r_open_collector[15:8]  <= wdata[15:8];
				if (mask[2]) r_open_collector[23:16] <= wdata[23:16];
				if (mask[3]) r_open_collector[31:24] <= wdata[31:24];
			end
		4:		//			32-27:	pullup enable			- 1 on
			begin
				if (mask[0]) r_pullup_enable[7:0]   <= wdata[7:0];
				if (mask[1]) r_pullup_enable[15:8]  <= wdata[15:8];
				if (mask[2]) r_pullup_enable[23:16] <= wdata[23:16];
				if (mask[3]) r_pullup_enable[31:24] <= wdata[31:24];
			end
		5:	;	//			40-43:	interrupt status		- 1 clears, 0 ignored
		6:		//			48-51:	interrupt enable		- 1 enabled
			begin
				if (mask[0]) r_interrupt_enable[7:0]   <= wdata[7:0];
				if (mask[1]) r_interrupt_enable[15:8]  <= wdata[15:8];
				if (mask[2]) r_interrupt_enable[23:16] <= wdata[23:16];
				if (mask[3]) r_interrupt_enable[31:24] <= wdata[31:24];
			end
		7:		//			56-59:	edge/level interrupt	- 0 edge 1 level
			begin
				if (mask[0]) r_level_edge[7:0]   <= wdata[7:0];
				if (mask[1]) r_level_edge[15:8]  <= wdata[15:8];
				if (mask[2]) r_level_edge[23:16] <= wdata[23:16];
				if (mask[3]) r_level_edge[31:24] <= wdata[31:24];
			end
		8:		//			64-67:	polarity				- 1 pos edge/1 level - 0 neg edge/0 level
			begin
				if (mask[0]) r_polarity[7:0]   <= wdata[7:0];
				if (mask[1]) r_polarity[15:8]  <= wdata[15:8];
				if (mask[2]) r_polarity[23:16] <= wdata[23:16];
				if (mask[3]) r_polarity[31:24] <= wdata[31:24];
			end
		default:;
		endcase
	end


	always @(posedge clk) 
	if (reset) begin
		r_data_req <= 0;
	end else
	if (sel&addr_req&read) begin
		r_data_req <= 1;
		case (addr[11:3])	// synthesis full_case parallel_case
		0:		//			0-3:	read pins				- read only
			r_data <= in;
		1:		//			8-11:	write pins				- rw of output register
			r_data <= r_data_out;
		2:		//			16-19:	direction				- 1 output - 0 input
			r_data <= r_direction;
		3:		//			24-27:	open collector			- 1 enable
			r_data <= r_open_collector;
		4:		//			32-27:	pullup enable			- 1 on
			r_data <= r_pullup_enable;
		5:		//			40-43:	interrupt status		- 1 clears, 0 ignored
			r_data <= r_interrupt_pending;
		6:		//			48-51:	interrupt enable		- 1 enabled
			r_data <= r_interrupt_enable;
		7:		//			56-59:	edge/level interrupt	- 0 edge 1 level
			r_data <= r_level_edge;
		8:		//			64-67:	polarity				- 1 pos edge/1 level - 0 neg edge/0 level
			r_data <= r_polarity;
		default:
			r_data <= 0;
		endcase
	end else
	if (data_ack) begin
		r_data_req <= 0;
	end	


endmodule

module gpio_pad(
`ifdef VS2
				input pad,
`else
`ifdef VERILATOR
				input pad,
`else
				inout pad,
`endif
`endif
				input clk,
				output in,
				input out,
				input direction,
				input oc,
				input pull);

	reg	r_synchroniser;		// synchroniser flop (could be more clocking at this freq)
	assign in = r_synchroniser;
	always @(posedge clk)
		r_synchroniser <= pad;
`ifndef VS2
`ifndef VERILATOR
	
	assign pad = (direction?(out?(oc?1'bz:1'b1):1'b0):1'bz);

	wire w=1'b1;
//	rtranif1 r(pad, w, pull);
`endif
`endif
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
