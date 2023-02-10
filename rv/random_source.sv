//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-23 Paul Campbell - paul@taniwha.com
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

// replace this with your real random source
module rand_source(input clk, input reset, output out);

	reg [15:0]r_lfsr;
	assign out = r_lfsr[0];
	always @(posedge clk)
	if (reset) r_lfsr <= 1; else
		   r_lfsr <= {r_lfsr[14:0], r_lfsr[15]^r_lfsr[14]^r_lfsr[12]^r_lfsr[3]};

endmodule

//
// replace this with your real conditioner (probably some variation on SHA2/3)
// note Moonbase actually sells something like this (OneRNG), but we reccomend cusomers run the
// output through AES/etc as shown here this will not pass NIST
//
module rand_conditioner(input clk, input reset, input in, input ok, output out, output valid, output dead);

	parameter NBITS = 5;	// how many input bits make good output

	// simple stream sanity checker do not use this, you need something smarter
	reg r_dead, r_last;
	reg [7:0]r_dead_count;
	assign dead = r_dead;	// need some sensible way to accumulate this state, at the moment just look for stuck 0/1s
	always @(posedge clk) begin
		if (reset) r_dead <= 0;
		if (r_last == in && ~r_dead_count == 0) r_dead <= 1; 
	end
	always @(posedge clk)
		r_last <= in;
	always @(posedge clk) 
		if (reset || r_last == in) r_dead_count <= 0; else
		if (r_valid) r_dead_count <= r_dead_count+1;

	
	// simple stream whitener - again this is too simple, choose something smarter
	reg [15:0]r_lfsr;
	assign out = r_lfsr[0];
	always @(posedge clk)
	if (reset) r_lfsr <= 1; else
		   r_lfsr <= {r_lfsr[14:0], r_lfsr[15]^r_lfsr[14]^r_lfsr[12]^r_lfsr[3]^in};
	
	// accumulate N bits of data
	reg r_valid;
	assign valid = r_valid;
	reg [7:0]r_count;
	always @(posedge clk)
	if (reset) begin
		r_valid <= 0;
		r_count <= 0;
	end else
	if (ok&in) begin // note we accumulate N changes, but the lfsr is grabbing all bits in time
		if (r_count == (NBITS-1)) begin
			r_count <= 0;
			r_valid <= 1;	
		end else begin
			r_count <= r_count+1;
			r_valid <= 0;
		end
	end else begin
		r_valid <= 0;
	end

endmodule


//
//	Randome source makes data for all the HARTS, 
//	output data is sent on rand_data, we run it all the time accumulating non-valid
//	data in all harts, but also the rand_valid bit in each hart in turn
//
module random_source(
	input	clk,
	input	reset,
	output	[NRAND-1:0]rand_valid,
	output	rand_data,
	output	rand_dead);


	parameter NRAND=1;

	//
	//	random source is some external/internal
	//	random data source 
	//
	wire in, valid;
	rand_source rs(.clk(clk), .reset(reset), .out(in));

	//
	// we detect 0/1 1/0 crossings to get some idea of the incoming data rate that
	//		we're sampling, but we feed all the data into the conditioner/whitener on
	//		every clock because the width of pulses is a big part of the random  for
	//		a lot of sources
	//
	reg r_in;
	always @(posedge clk)
		r_in <= in;
	rand_conditioner conditioner(.clk(clk), .reset(reset), .in(r_in), .ok(r_in != in), .valid(valid), .out(out), .dead(rand_dead));

	reg 		   r_rand_data;
	reg	[NRAND-1:0]r_rand_valid;
	assign rand_valid = r_rand_valid;
	assign rand_data = r_rand_data;
	always @(posedge clk)
		r_rand_data <= out;

	// distribute to different HARTs
	reg	[$clog2(NRAND):0]r_rand_index;
	always @(posedge clk)
	if (reset) begin
		r_rand_index <= 0;
	end else
	if (valid) begin
		if (r_rand_index == (NRAND-1)) begin
			r_rand_index <= 0;
		end else begin
			r_rand_index <= r_rand_index+1;
		end
	end
	genvar I;
	generate
		for (I = 0; I < NRAND; I=I+1) begin
			always @(posedge clk)
				r_rand_valid[I] <= !reset&out&valid&(r_rand_index==I);
		end
	endgenerate

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

