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

// Trace cache

`include "trc.si"

module trace_cache(input clk, input reset,
	input [VA_SZ-1:1]pc,
	input			 pc_used,
	TRACE_BUNDLE trace_out,
	output [VA_SZ-1:0]pc_next,
	output		 trace_hit,

	input	flush,			// we did a pipe-flush
	input	invalidate,		// invalidate the trace cache
	TRACE_BUNDLE trace_in
	
);

	parameter NRETIRE=8;
	parameter CNTRL_SIZE=7;
	parameter LNCOMMIT=5;
	parameter NUM_TRACE_LINES=64;
	parameter VA_SZ=48;   
	parameter BUNDLE_SIZE=(VA_SZ-1)+4*5+1+1+1+4+CNTRL_SIZE+32+
`ifdef FP
						1+1+1+1+
`endif
						(VA_SZ-1)+1+1;
	// why can't I say? parameter BUNDLE_SIZE=$bits(trace_in.b[0]);


	genvar I, L;

	generate

		// trace cache:
		//
		//		1 read port single address (or 1-hot address access) for (NRETIRE bundles of BUNDLE_SIZE)
		//
		//		1 write port single address but indivitdual write strobes for NRETIRE bundles of BUNDLE_SIZE
		//
		reg [BUNDLE_SIZE-1:0]r_trace_cache[0:NUM_TRACE_LINES-1][0:NRETIRE-1];

		// write port
		reg	[NRETIRE-1:0]trace_write_strobe;
		reg [BUNDLE_SIZE*NRETIRE-1: 0]trace_write_data;
		reg [$clog2(NUM_TRACE_LINES)-1:0]r_fill;	// the entry we're currently filling
		
		for (L = 0; L < NUM_TRACE_LINES; L = L+1) begin
			for (I = 0; I < NRETIRE; I = I+1) begin

				always @(posedge clk)
				if (trace_write_strobe[I] && r_fill == L)
					r_trace_cache[L][I] <= trace_write_data[(BUNDLE_SIZE*(I+1))-1:BUNDLE_SIZE*I];
			end
		end

		//

		// meta data
		reg [NRETIRE-1:0]r_valid[0:NUM_TRACE_LINES-1];
		reg [VA_SZ-1:1]r_pc_tag[0:NUM_TRACE_LINES-1];
		reg [VA_SZ-1:1]r_pc_next[0:NUM_TRACE_LINES-1];
		reg [2:0]r_use[0:NUM_TRACE_LINES-1];
		reg [2:0]c_use[0:NUM_TRACE_LINES-1];
		reg [NRETIRE-1:0]c_meta_valid;
		reg	 [VA_SZ-1:1]c_meta_next, c_meta_pc;
		wire [NUM_TRACE_LINES-1:0]use_free;			// can we use this?
		for (I = 0; I < NUM_TRACE_LINES; I=I+1) begin
			assign use_free[I] = c_use[I]==0;
		end
		reg [NUM_TRACE_LINES-1:0]r_next_use, c_next_use;			// next slot to use
		reg						 r_next_use_valid, c_next_use_valid;	// slot is valid
		always @(posedge clk) begin
			r_next_use <= (reset?1: c_next_use);
			r_next_use_valid <= (reset?1:c_next_use_valid);
		end

		reg [2:0]r_use_counter;
		wire dec_use = r_use_counter == 0;
		always @(posedge clk) 
		if (reset ||  r_use_counter == 0) begin
			r_use_counter <= 7;	// tweak this number
		end else begin
			r_use_counter <= r_use_counter-1;
		end
		
		reg	write_meta, write_meta_update;

		for (I = 0; I < NUM_TRACE_LINES; I=I+1) begin

			always @(posedge clk) begin
				c_use[I] = r_use[I];
				if (reset || invalidate) begin
					c_use[I] = 0;
				end else
				if (write_meta && (write_meta_update ? r_last == I : r_next_use == I)) begin
					if (r_use[I] < 2)
						c_use[I] = 2;
				end else
				if (pc_used && match[I]) begin
					if (!dec_use && r_use[I] < 7)
						c_use[I] = r_use[I]+1;
				end else
				if (dec_use) begin
					if (r_use[I] != 0)
						c_use[I] = r_use[I]-1;
				end
			end

			always @(posedge clk) begin
				r_use[I] <= c_use[I];

				if (reset || invalidate) begin
					r_valid[I] <= 0;
				end else
				if (write_meta && (write_meta_update ? r_last == I : r_next_use == I)) begin
					r_valid[I] <= c_meta_valid | (write_meta_update?r_valid[I]:0);
				end

				if (write_meta && !write_meta_update && r_next_use == I)
					r_pc_tag[I] <= c_meta_pc;
		
				if (write_meta && (write_meta_update ? r_last == I : r_next_use == I))
					r_pc_next[I] <= c_meta_next;

			end
		end
	

		reg [$clog2(NRETIRE)-1:0]r_fill_offset;	// where the fill offset starts
		wire	[NRETIRE-1:0]r_fill_full;		// where we're a

		//
		//	output side
		//

		wire [NUM_TRACE_LINES-1:0]match;
		for (I = 0; I < NUM_TRACE_LINES; I=I+1) begin
			assign match[I] = r_valid[I][0] && pc[VA_SZ-1:1] == r_pc_tag[I];	// associative match
		end
		assign trace_hit = |match;

		
		// one-hit mux cache = r_trace_cache[hit-line]
		reg [NRETIRE*BUNDLE_SIZE-1:0]cache;	
		reg [VA_SZ-1:1]xpc_next;
		assign pc_next = xpc_next;
		reg [NRETIRE-1:0]xbundle_valid;
		for (I = 0; I < NRETIRE; I = I+1)
			assign trace_out.valid[I] = xbundle_valid[I];
		
		if (NRETIRE == 8) begin
			if (NUM_TRACE_LINES == 16) begin
`include "mk22_16_8.inc"
			end else
			if (NUM_TRACE_LINES == 32) begin
`include "mk22_32_8.inc"
			end else
			if (NUM_TRACE_LINES == 48) begin
`include "mk22_48_8.inc"
			end else
			if (NUM_TRACE_LINES == 64) begin
`include "mk22_64_8.inc"
			end 
		end

		for (I = 0; I < NRETIRE; I=I+1) begin
			assign trace_out.b[I] = cache[(I+1)*BUNDLE_SIZE-1:I*BUNDLE_SIZE];
		end

		//
		//	input side
		//

		wire [BUNDLE_SIZE*NRETIRE-1:0]cx;
		for (I = 0; I < NRETIRE; I=I+1) begin
			assign cx[(I+1)*BUNDLE_SIZE-1:I*BUNDLE_SIZE] = trace_in.b[I];	// pack 
		end

		wire [VA_SZ-1:1]next_ins[0:NRETIRE-1];
		for (I = 0; I < NRETIRE; I=I+1) begin
			assign next_ins[I] = (trace_in.branched[I]?trace_in.b[I].pc_dest:trace_in.b[I].pc+{{(VA_SZ-1){1'b0}},~trace_in.b[I].short_ins,trace_in.b[I].short_ins});
		end

wire [NRETIRE-1:0]short_vec;
wire [NRETIRE-1:0]valid_vec=trace_in.valid;
for (I = 0; I < NRETIRE; I=I+1) begin
assign short_vec[I] = trace_in.b[I].short_ins;
end
		wire [NRETIRE-1:0]start_vec;
		for (I = 0; I < NRETIRE; I=I+1) begin
			assign start_vec[I] = trace_in.b[I].start;
		end

		//
		//	incoming policy
		//		if there is waiting data and there is space for it:
		//			1a) if the incoming data can merge with the waiting data write as much of it
		//					as we can and,
		//			1b) put the reset of it in the waiting data
		//		if there is waiting data and no space for it
		//			2a) discard the waiting data
		//			2b) discard incoming data until the next start
		//		if there's no waiting data and incoming data can be added to an existing row
		//			3a) add as much as we can to the existing row
		//			3b) write the rest to the waiting buffer
		//		if there's no waiting data and incoming data can't be added to an existing row but
		//				matches the end of another row and there is a free row
		//			4a) write all the data to a new row
		//		if there's no waiting data and incoming data can't be added to an existing row
		//				and it doesn't match the end of an existing row and there is a free row
		//			5a) discard until we find a start point
		//			5b) write the rest to a new row
		//		otherwise
		//			6) discard the data

		// 1b case
        reg [NRETIRE-1:0]l1b_write_strobe;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l1b_write_data;
        reg [VA_SZ-1:1]l1b_meta_next;
        reg [NRETIRE-1:0]l1b_c_waiting_valid;
        reg [VA_SZ-1:1]l1b_c_waiting_pc;
        reg [VA_SZ-1:1]l1b_c_waiting_next;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l1b_c_waiting;
        reg [$clog2(NRETIRE):0]l1b_c_waiting_offset;

        // 2 case
        reg [NRETIRE-1:0]l2_c_waiting_valid;
        reg [VA_SZ-1:1]l2_c_waiting_pc;
        reg [VA_SZ-1:1]l2_c_waiting_next;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l2_c_waiting;
        reg [$clog2(NRETIRE):0]l2_c_waiting_offset;

        // 4 case
        reg [VA_SZ-1:1]l4_next;

        // 3 case
        reg [NRETIRE-1:0]l3_write_strobe;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l3_write_data;
        reg [VA_SZ-1:1]l3_meta_next;
        reg [NRETIRE-1:0]l3_c_waiting_valid;
        reg [VA_SZ-1:1]l3_c_waiting_pc;
        reg [VA_SZ-1:1]l3_c_waiting_next;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l3_c_waiting;
        reg [$clog2(NRETIRE):0]l3_c_waiting_offset;

		if (NRETIRE == 8) begin		// pull in lots of 8:1 muxes to set the above up
`include "mk23_8.inc"
		end

wire [VA_SZ-1:1]trace_in_pc_0=trace_in.b[0].pc;

		reg [BUNDLE_SIZE*NRETIRE-1:0]r_waiting, c_waiting;
		reg	 [NRETIRE-1:0]r_waiting_valid, c_waiting_valid;	// left over from the last time
		reg	[$clog2(NRETIRE):0]r_waiting_offset, c_waiting_offset; // offset for the next bunch
		reg [VA_SZ-1:1]r_waiting_pc, c_waiting_pc;			// pc to write it to
		reg [VA_SZ-1:1]r_waiting_next, c_waiting_next;			// where it will go next

		always @(posedge clk) begin
			r_waiting_valid <= (reset || invalidate?0:c_waiting_valid);
			r_waiting <= c_waiting;
			r_waiting_offset <= c_waiting_offset;
			r_waiting_pc <= c_waiting_pc;
			r_waiting_next <= c_waiting_next;
		end

		reg [NRETIRE-1:0]r_last_valid, c_last_valid;		// what we last wrote
		reg [VA_SZ-1:1]r_last_next, c_last_next;			// and what will be next
		reg [$clog2(NUM_TRACE_LINES)-1:0]r_last, c_last;	// which entry it was

		always @(posedge clk) begin
			r_last <= c_last;	
			r_last_valid <= (reset || invalidate ?0 : c_last_valid);
			r_last_next <= c_last_next;
		end

		wire [NUM_TRACE_LINES-1:0]match_last;
		for (I = 0; I < NUM_TRACE_LINES; I = I+1)
			assign match_last[I] = r_valid[I][7] && r_pc_next[I] == trace_in.b[0].pc;

		wire [NUM_TRACE_LINES-1:0]match_waiting;
		for (I = 0; I < NUM_TRACE_LINES; I = I+1)
			assign match_waiting[I] = r_valid[I][0] && r_pc_tag[I] == r_waiting_pc;
 

reg [3:0]debug;
		always @(*) begin
debug=0;
			write_meta = 0;
			write_meta_update = 'bx;
			trace_write_strobe = 0;
			trace_write_data = 'bx;
			c_meta_next = 'bx;
			c_meta_pc = 'bx;
			c_last_next = r_last_next;
			c_last_valid = r_last_valid;
			c_last = r_last;
			
			c_waiting_valid = 0;
			c_waiting_pc = 'bx;
			c_waiting_next = 'bx;
			c_waiting_offset = 'bx;
			c_waiting = 'bx;
			if (r_waiting_valid[0]) begin	// data is waiting
				if (r_next_use_valid) begin	// somewhere to put it?
					if (!(trace_in.valid[0] && trace_in.b[0].pc == r_waiting_next)) begin	// l1a
debug=1;
						trace_write_strobe = |match_waiting?0:r_waiting_valid;
						trace_write_data = {{BUNDLE_SIZE{1'bx}}, r_waiting};

						c_meta_valid = {1'b0,r_waiting_valid};
						c_meta_next = r_waiting_next;
						c_meta_pc = r_waiting_pc;
						write_meta = ! |match_waiting;
						write_meta_update = 0;

						if (! |match_waiting) begin
							c_last = r_next_use;
							c_last_next = r_waiting_next;
							c_last_valid = trace_write_strobe;
						end

						c_waiting_valid = 0;
						c_waiting_pc = 'bx;
						c_waiting_next = 'bx;
						c_waiting_offset = 'bx;
					end else begin														// l1b
debug=2;
						trace_write_strobe = |match_waiting?0:l1b_write_strobe;
						trace_write_data = l1b_write_data;

						c_meta_valid = l1b_write_strobe;
						c_meta_next = l1b_meta_next;
						c_meta_pc = r_waiting_pc;
						write_meta = ! |match_waiting;
						write_meta_update = 0;

						if (! |match_waiting) begin
							c_last = r_next_use;
							c_last_next = l1b_meta_next;
							c_last_valid = trace_write_strobe;
						end

						c_waiting_valid = l1b_c_waiting_valid;
						c_waiting = l1b_c_waiting;
						c_waiting_pc = l1b_c_waiting_pc;
						c_waiting_next = l1b_c_waiting_next;	
						c_waiting_offset = l1b_c_waiting_offset;
					end
				end	else begin	// else l2[a/b]		// discard waiting data, fill it with next data
debug=3;
					c_waiting_valid = l2_c_waiting_valid;
					c_waiting = l2_c_waiting;
					c_waiting_pc = l2_c_waiting_pc;
					c_waiting_next = l2_c_waiting_next;	
					c_waiting_offset = l2_c_waiting_offset;
				end
			end else
			if (trace_in.valid[0]) begin
				if (r_next_use_valid) begin	// somewhere to put it?
					if (r_last_valid[0] && !r_last_valid[NRETIRE-1] && trace_in.b[0].pc == r_last_next) begin	// 3
debug=4;
						trace_write_strobe = l3_write_strobe;
						trace_write_data = l3_write_data;

						write_meta = 1;
						write_meta_update = 1;
						c_meta_valid = l3_write_strobe;
						c_meta_next = l3_meta_next;
						c_meta_pc = 'bx;

						c_last_next = l3_meta_next;
						c_last_valid = l3_write_strobe|r_last_valid;

						c_waiting_valid = l3_c_waiting_valid;
						c_waiting = l3_c_waiting;
						c_waiting_pc = l3_c_waiting_pc;
						c_waiting_next = l3_c_waiting_next;	
						c_waiting_offset = l3_c_waiting_offset;
					end else
					if (|match_last && ! |match_waiting) begin // 4
debug=5;
						trace_write_strobe = trace_in.valid;
						trace_write_data = cx;
	
						write_meta = 1;
						write_meta_update = 1;
						c_meta_valid = trace_in.valid;
						c_meta_pc = trace_in.b[0].pc;
						c_meta_next = l4_next;
	
						c_last = r_next_use;
						c_last_valid = trace_in.valid;
						c_last_next = l4_next;

						c_waiting_valid = 0;
					end else begin	// 5
debug=6;
						c_waiting_valid = l2_c_waiting_valid;
						c_waiting = l2_c_waiting;
						c_waiting_pc = l2_c_waiting_pc;
						c_waiting_next = l2_c_waiting_next;	
						c_waiting_offset = l2_c_waiting_offset;
					end
				end else begin	// 5
debug=7;
					c_waiting_valid = l2_c_waiting_valid;
					c_waiting = l2_c_waiting;
					c_waiting_pc = l2_c_waiting_pc;
					c_waiting_next = l2_c_waiting_next;	
					c_waiting_offset = l2_c_waiting_offset;
				end
			end else begin
debug=8;
				// case 6
				trace_write_strobe = 0;
				c_waiting_valid = 0;
			end
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

