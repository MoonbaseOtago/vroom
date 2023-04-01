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
`ifdef SIMD
	input			 simd_enable,
`endif
	input			 trace_enable,
	input	    [3:0]trace_scale,
	input [VA_SZ-1:1]pc,
	input			 pc_used,
	input			 rename_stall,
	TRACE_BUNDLE trace_out,
	output [VA_SZ-1:1]pc_next,
	output	   [1:0]pc_push_pop,
	output [VA_SZ-1:1]pc_ret_addr,
	output			  pc_ret_addr_short,
	output		 trace_hit,

	input	flush,			// we did a pipe-flush
	input	invalidate,		// invalidate the trace cache
	input	 [3:0]cpu_mode,
	input	[NRETIRE-1:0]will_trap,
	TRACE_BUNDLE trace_in
	
);

	parameter NRETIRE=8;
	parameter CNTRL_SIZE=7;
	parameter LNCOMMIT=5;
	parameter NUM_TRACE_LINES=64;
	parameter VA_SZ=48;   
	parameter BUNDLE_SIZE=(VA_SZ-1)+4*5+1+1+1+4+CNTRL_SIZE+32+
`ifdef INSTRUCTION_FUSION
						32+
`endif
`ifdef FP
						1+1+1+1+
`endif
						(VA_SZ-1)+1+1;
	// why can't I say? parameter BUNDLE_SIZE=$bits(trace_in.b[0]);

	reg		 r_invalidate;
	reg [3:0]r_cpu_mode;
	always @(posedge clk)
		r_cpu_mode <= cpu_mode;
	always @(posedge clk)
		r_invalidate <= invalidate || r_cpu_mode != cpu_mode;


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
		
		for (L = 0; L < NUM_TRACE_LINES; L = L+1) begin
			for (I = 0; I < NRETIRE; I = I+1) begin

				always @(posedge clk)
				if (trace_write_strobe[I] && write_meta && (write_meta_update ? r_last == L : r_next_use == L)) begin
					r_trace_cache[L][I] <= trace_write_data[(BUNDLE_SIZE*(I+1))-1:BUNDLE_SIZE*I];
`ifdef SIMD
					if (simd_enable)
					$display("%d	write[%d][%d] strobe=%b pc=%h %h", $time, L, I,trace_write_strobe, {trace_write_data[(BUNDLE_SIZE*(I+1))-1:(BUNDLE_SIZE*(I+1))-1-VA_SZ+2],1'b0},trace_write_data[(BUNDLE_SIZE*(I+1))-1:BUNDLE_SIZE*I]);
`endif
				end
			end
		end

		//

		// meta data
		reg [NRETIRE-1:0]r_valid[0:NUM_TRACE_LINES-1];
		reg [VA_SZ-1:1]r_pc_tag[0:NUM_TRACE_LINES-1];
		reg [VA_SZ-1:1]r_pc_next[0:NUM_TRACE_LINES-1];
		reg [VA_SZ-1:1]c_pc_next[0:NUM_TRACE_LINES-1];
		reg [1:0]r_pc_push_pop[0:NUM_TRACE_LINES-1];
		reg [1:0]c_pc_push_pop[0:NUM_TRACE_LINES-1];
		reg [VA_SZ-1:1]r_pc_ret_addr[0:NUM_TRACE_LINES-1];
		reg [VA_SZ-1:1]c_pc_ret_addr[0:NUM_TRACE_LINES-1];
		reg [NUM_TRACE_LINES-1:0]r_pc_ret_addr_short;
		reg [NUM_TRACE_LINES-1:0]c_pc_ret_addr_short;
		reg [2:0]r_use[0:NUM_TRACE_LINES-1];
		reg [2:0]c_use[0:NUM_TRACE_LINES-1];
		reg [NRETIRE-1:0]c_meta_valid;
		reg	 [VA_SZ-1:1]c_meta_next, c_meta_pc;
		reg	 [VA_SZ-1:1]c_meta_ret_addr;
		reg	            c_meta_ret_addr_short;
		reg  [1:0]c_meta_push_pop;
		wire [NUM_TRACE_LINES-1:0]use_free;			// can we use this?
		for (I = 0; I < NUM_TRACE_LINES; I=I+1) begin
			assign use_free[I] = c_use[I]==0;
		end
		reg [$clog2(NUM_TRACE_LINES)-1:0]r_next_use, c_next_use;			// next slot to use
		reg						 r_next_use_valid, c_next_use_valid;	// slot is valid
		reg [NUM_TRACE_LINES-1:0]r_trace_hit;

		reg [NRETIRE*BUNDLE_SIZE-1:0]r_trace_out;	
		always @(posedge clk)
		if (!rename_stall) begin
			r_trace_out  <= cache;
		end
		always @(posedge clk)
		if (!rename_stall) begin
			r_trace_hit <= match;
		end
		always @(posedge clk) begin
			r_next_use <= (reset?1: c_next_use);
			r_next_use_valid <= (reset?1:c_next_use_valid);
		end

		reg [8:0]r_use_counter;
		wire dec_use = r_use_counter == 0;
		always @(posedge clk) 
		if (reset ||  r_use_counter == 0) begin
			case (trace_scale[3:2]) // synthesis full_case parallel_case
			2'b00: r_use_counter <= {3'b0, trace_scale[1:0],4'hf};	
			2'b01: r_use_counter <= {2'b0, trace_scale[1:0],5'h1f};	
			2'b10: r_use_counter <= {1'b0, trace_scale[1:0],6'h3f};	
			2'b11: r_use_counter <= {trace_scale[1:0],7'h7f};	
			endcase
		end else begin
			r_use_counter <= r_use_counter-1;
		end
		
		reg	write_meta, write_meta_update;

		for (I = 0; I < NUM_TRACE_LINES; I=I+1) begin

			always @(posedge clk) begin
				c_use[I] = r_use[I];
				if (reset || r_invalidate) begin
					c_use[I] = 0;
				end else
				if (write_meta && (write_meta_update ? r_last == I : r_next_use == I) && !match[I]) begin
					if (r_use[I] < 2)
						c_use[I] = 2;
				end else
				if (r_trace_hit[I] && pc_used) begin
					if (!dec_use && r_use[I] < 7)
						c_use[I] = r_use[I]+1;
				end else
				if (dec_use) begin
					if (r_use[I] != 0)
						c_use[I] = r_use[I]-1;
				end
			end


			always @(*) begin
				c_pc_next[I] = r_pc_next[I];
				c_pc_push_pop[I] = r_pc_push_pop[I];
				c_pc_ret_addr[I] = r_pc_ret_addr[I];
				c_pc_ret_addr_short[I] = r_pc_ret_addr_short[I];
				if (write_meta && (write_meta_update ? r_last == I : r_next_use == I)) begin
					c_pc_next[I] = c_meta_next;
					c_pc_push_pop[I] = c_meta_push_pop;
					c_pc_ret_addr[I] = c_meta_ret_addr;
					c_pc_ret_addr_short[I] = c_meta_ret_addr_short;
				end else
				if (r_last_valid[0] && r_last == I && trace_in_valid[0]&~trace_in_will_trap[0] && !flush && r_last_changed) begin
					c_pc_next[I] = trace_in_pc[0];
				end
			end

			always @(posedge clk) begin
				r_use[I] <= c_use[I];

				if (reset || r_invalidate || !trace_enable) begin
					r_valid[I] <= 0;
				end else
				if (write_meta && (write_meta_update ? r_last == I : r_next_use == I)) begin
					r_valid[I] <= c_meta_valid | (write_meta_update?r_valid[I]:0);
				end

				if (write_meta && !write_meta_update && r_next_use == I)
					r_pc_tag[I] <= c_meta_pc;
		
				r_pc_next[I] <= c_pc_next[I];
				r_pc_push_pop[I] <= c_pc_push_pop[I];
				r_pc_ret_addr[I] <= c_pc_ret_addr[I];
				r_pc_ret_addr_short[I] <= c_pc_ret_addr_short[I];

			end
		end

		//
		//	output side
		//

		wire [NUM_TRACE_LINES-1:0]match;
		for (I = 0; I < NUM_TRACE_LINES; I=I+1) begin
			assign match[I] = r_valid[I][0] && pc[VA_SZ-1:1] == r_pc_tag[I];	// associative match
		end
		assign trace_hit = |match;

		
		// one-hot mux cache = r_trace_cache[hit-line]
		reg [NRETIRE*BUNDLE_SIZE-1:0]cache;	
		reg [VA_SZ-1:1]xpc_next;
		assign pc_next = xpc_next;
		reg [1:0]xpc_push_pop;
		assign pc_push_pop = xpc_push_pop;
		reg [VA_SZ-1:1]xpc_ret_addr;
		assign pc_ret_addr = xpc_ret_addr;
		reg   xpc_ret_addr_short;
		assign pc_ret_addr_short = xpc_ret_addr_short;
		reg [NRETIRE-1:0]xbundle_valid;
		reg [NRETIRE-1:0]r_bundle_valid;	// save this so that it matches the r_pc_next that was read in the same lock
		always @(posedge clk)
		if (!rename_stall)
			r_bundle_valid <= xbundle_valid;

		for (I = 0; I < NRETIRE; I = I+1)
			assign trace_out.valid[I] = r_bundle_valid[I];
		
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
			end else
			if (NUM_TRACE_LINES == 96) begin
`include "mk22_96_8.inc"
			end else
			if (NUM_TRACE_LINES == 128) begin
`include "mk22_128_8.inc"
			end 
		end

		for (I = 0; I < NRETIRE; I=I+1) begin
			assign trace_out.b[I] = r_trace_out[(I+1)*BUNDLE_SIZE-1:I*BUNDLE_SIZE];
		end

		//
		//	input side
		//

		reg [BUNDLE_SIZE*NRETIRE-1:0]cx;
//		for (I = 0; I < NRETIRE; I=I+1) begin
//			assign cx[(I+1)*BUNDLE_SIZE-1:I*BUNDLE_SIZE] = trace_in.b[I];	// pack 
//		end

		// skipped input
		reg [NRETIRE-1:0]trace_in_valid;
		reg [VA_SZ-1:1]trace_in_next[0:NRETIRE-1];
		reg [VA_SZ-1:1]trace_in_pc[0:NRETIRE-1];
		reg [1:0]trace_in_push_pop[0:NRETIRE-1];
		reg [NRETIRE-1:0]trace_in_start;
		reg [NRETIRE-1:0]trace_in_will_trap;
		reg [NRETIRE-1:0]trace_in_will_terminate;
		reg [NRETIRE-1:0]trace_in_short_ins;

		wire [NRETIRE-1:0]sub_call;
		wire [NRETIRE-1:0]sub_return;
		wire [NRETIRE-1:0]branched;
		wire [1:0]push_pop_in[0:NRETIRE-1];;

		// unskipped
		wire [VA_SZ-1:1]next_ins[0:NRETIRE-1];
		for (I = 0; I < NRETIRE; I=I+1) begin
			assign next_ins[I] = (branched[I]?(trace_in.b[I].control[0]?(trace_in.b[I].pc+{{(VA_SZ-1-32){trace_in.b[I].immed[31]}},trace_in.b[I].immed}):trace_in.b[I].pc_dest):trace_in.b[I].pc+{{(VA_SZ-1){1'b0}},~trace_in.b[I].short_ins,trace_in.b[I].short_ins});
		end


wire [NRETIRE-1:0]short_vec;
wire [NRETIRE-1:0]valid_vec=trace_in.valid;
wire [NRETIRE-1:0]start_vec;
wire [2:0]unit_type[0:NRETIRE-1];
wire [5:0]control[0:NRETIRE-1];
wire [VA_SZ-1:1]pc_dest[0:NRETIRE-1];
for (I = 0; I < NRETIRE; I=I+1) begin
assign short_vec[I] = trace_in.b[I].short_ins;
assign start_vec[I] = trace_in.b[I].start;
assign unit_type[I] = trace_in.b[I].unit_type;
assign control[I] = trace_in.b[I].control;
assign pc_dest[I] = trace_in.b[I].pc_dest;
end

		// unskipped partial instruction decodes for choosing trace beginning/ends
		for (I = 0; I < NRETIRE; I=I+1) begin
			assign sub_call[I] = trace_in.b[I].unit_type == 6 && trace_in.b[I].makes_rd && (trace_in.b[I].rd==1||trace_in.b[I].rd==5) && !trace_in.b[I].control[0];
			assign sub_return[I] = trace_in.b[I].unit_type == 6 && !trace_in.b[I].makes_rd && (trace_in.b[I].rs1==1||trace_in.b[I].rs1==5) && (trace_in.b[I].control[1:0] == 2'b00);
			assign push_pop_in[I] = {sub_call[I], sub_return[I]};
			assign branched[I] = trace_in.b[I].unit_type == 6 && (!trace_in.b[I].control[0] || trace_in.b[I].control[5]);
		end
		wire	[NRETIRE-1:0]ignore_valid; // mask to ignore instructions at the end of a trace
		wire	[NRETIRE-1:0]will_terminate; // last instruction in a trace
		assign will_terminate = sub_call|sub_return;

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
        reg [VA_SZ-1:1]l1b_meta_ret_addr;
        reg			   l1b_meta_ret_addr_short;
        reg [1:0]l1b_meta_push_pop;
        reg [NRETIRE-1:0]l1b_c_waiting_valid;
        reg [VA_SZ-1:1]l1b_c_waiting_pc;
        reg [VA_SZ-1:1]l1b_c_waiting_next;
        reg [VA_SZ-1:1]l1b_c_waiting_ret_addr;
        reg            l1b_c_waiting_ret_addr_short;
        reg [1:0]l1b_c_waiting_push_pop;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l1b_c_waiting;
        reg [$clog2(NRETIRE):0]l1b_c_waiting_offset;

        // 2 case
        reg [NRETIRE-1:0]l2_c_waiting_valid;
        reg [VA_SZ-1:1]l2_c_waiting_pc;
        reg [VA_SZ-1:1]l2_c_waiting_next;
        reg [VA_SZ-1:1]l2_c_waiting_ret_addr;
        reg            l2_c_waiting_ret_addr_short;
        reg [1:0]l2_c_waiting_push_pop;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l2_c_waiting;
        reg [$clog2(NRETIRE):0]l2_c_waiting_offset;

        // 4 case
        reg [VA_SZ-1:1]l4_next;
        reg [VA_SZ-1:1]l4_ret_addr;
        reg            l4_ret_addr_short;
        reg [1:0]l4_push_pop;

        // 3 case
        reg [NRETIRE-1:0]l3_write_strobe;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l3_write_data;
        reg [VA_SZ-1:1]l3_meta_next;
        reg [VA_SZ-1:1]l3_meta_ret_addr;
        reg            l3_meta_ret_addr_short;
        reg [1:0]l3_meta_push_pop;
        reg [NRETIRE-1:0]l3_c_waiting_valid;
        reg [VA_SZ-1:1]l3_c_waiting_pc;
        reg [VA_SZ-1:1]l3_c_waiting_next;
        reg [VA_SZ-1:1]l3_c_waiting_ret_addr;
        reg            l3_c_waiting_ret_addr_short;
        reg [1:0]l3_c_waiting_push_pop;
        reg [BUNDLE_SIZE*NRETIRE-1:0]l3_c_waiting;
        reg [$clog2(NRETIRE):0]l3_c_waiting_offset;

		if (NRETIRE == 8) begin		// pull in lots of 8:1 muxes to set the above up
`include "mk23_8.inc"
		end

		reg [NRETIRE-1:0]starting_valid;
		reg [$clog2(NRETIRE):0]starting_valid_count;
		reg [$clog2(NRETIRE):0]current_valid_count;
		//reg [$clog2(NRETIRE)-1:0]initial_count;
		reg [$clog2(NRETIRE)-1:0]r_skip, c_skip;
		always @(posedge clk)
			r_skip <= (reset || r_invalidate || !trace_enable ?0 : c_skip);
	

wire [VA_SZ-1:1]trace_in_pc_0=trace_in.b[0].pc;
wire [VA_SZ-1:1]trace_in_pc_1=trace_in.b[1].pc;
wire [VA_SZ-1:1]trace_in_pc_2=trace_in.b[2].pc;
wire [VA_SZ-1:1]trace_in_pc_3=trace_in.b[3].pc;
wire [VA_SZ-1:1]trace_in_pc_4=trace_in.b[4].pc;
wire [VA_SZ-1:1]trace_in_pc_5=trace_in.b[5].pc;
wire [VA_SZ-1:1]trace_in_pc_6=trace_in.b[6].pc;
wire [VA_SZ-1:1]trace_in_pc_7=trace_in.b[7].pc;

		reg [BUNDLE_SIZE*NRETIRE-1:0]r_waiting, c_waiting;
		reg	 [NRETIRE-1:0]r_waiting_valid, c_waiting_valid;	// left over from the last time
		reg	[$clog2(NRETIRE):0]r_waiting_offset, c_waiting_offset; // offset for the next bunch
		reg [VA_SZ-1:1]r_waiting_pc, c_waiting_pc;			// pc to write it to
		reg [VA_SZ-1:1]r_waiting_next, c_waiting_next;			// where it will go next
		reg [VA_SZ-1:1]r_waiting_ret_addr, c_waiting_ret_addr;			// where it will go when we come back from a call
		reg            r_waiting_ret_addr_short, c_waiting_ret_addr_short;// how wide it is
		reg [1:0]r_waiting_push_pop, c_waiting_push_pop;			// call/return

		always @(posedge clk) begin
			r_waiting_valid <= (reset || r_invalidate?0:c_waiting_valid);
			r_waiting <= c_waiting;
			r_waiting_offset <= c_waiting_offset;
			r_waiting_pc <= c_waiting_pc;
			r_waiting_next <= c_waiting_next;
			r_waiting_push_pop <= c_waiting_push_pop;
			r_waiting_ret_addr <= c_waiting_ret_addr;
			r_waiting_ret_addr_short <= c_waiting_ret_addr_short;
		end

		reg [NRETIRE-1:0]r_last_valid, c_last_valid;		// what we last wrote
		reg [$clog2(NUM_TRACE_LINES)-1:0]r_last, c_last;	// which entry it was
		reg			     r_last_changed;

		wire terminate = |((trace_in_will_trap)&trace_in_valid) || (write_meta&& |c_meta_push_pop) ;

		always @(posedge clk) begin
			r_last <= c_last;	
			r_last_valid <= (reset || r_invalidate || flush || terminate ? 0 : c_last_valid);
			r_last_changed <= reset || r_invalidate || flush  || terminate ? 0 :
						      (c_last_valid != r_last_valid || c_last != r_last) && !c_waiting_valid[0] ? 1 :
							  r_last_changed && r_last_valid[0] && trace_in_valid[0]&~ignore_valid[0] ? 0: r_last_changed;
		end

		wire [NUM_TRACE_LINES-1:0]match_last;
		for (I = 0; I < NUM_TRACE_LINES; I = I+1)
			assign match_last[I] = r_valid[I][7] && r_pc_next[I] == trace_in_pc[0];

		wire [NUM_TRACE_LINES-1:0]match_waiting;
		for (I = 0; I < NUM_TRACE_LINES; I = I+1)
			assign match_waiting[I] = r_valid[I][0] && r_pc_tag[I] == r_waiting_pc;

		wire [NUM_TRACE_LINES-1:0]match_starting;
		for (I = 0; I < NUM_TRACE_LINES; I = I+1)
			assign match_starting[I] = r_valid[I][0] && r_pc_tag[I] == trace_in_pc[0];


wire [BUNDLE_SIZE-1:0]bundles[0:NRETIRE-1];
wire [VA_SZ-1:1]pcs[0:NRETIRE-1];
for (I = 0; I < NRETIRE; I = I+1) begin
assign bundles[I] = trace_write_data[BUNDLE_SIZE*(I+1)-1:BUNDLE_SIZE*I];
assign pcs[I] = bundles[I][BUNDLE_SIZE-1:BUNDLE_SIZE-(VA_SZ-1)];
end

reg [3:0]debug;
		always @(*) begin
debug=0;
			write_meta = 0;
			write_meta_update = 'bx;
			trace_write_strobe = 0;
			trace_write_data = 'bx;
			c_meta_next = 'bx;
			c_meta_ret_addr = 'bx;
			c_meta_ret_addr_short = 'bx;
			c_meta_push_pop = 'bx;
			c_meta_pc = 'bx;
			c_last_valid = r_last_valid;
			c_last = r_last;
			
			c_waiting_valid = 0;
			c_waiting_pc = 'bx;
			c_waiting_next = 'bx;
			c_waiting_ret_addr = 'bx;
			c_waiting_ret_addr_short = 'bx;
			c_waiting_push_pop = 'bx;
			c_waiting_offset = 'bx;
			c_waiting = 'bx;

			c_skip = (current_valid_count > r_skip ? 0:r_skip-current_valid_count);
			if (r_waiting_valid[0]) begin	// data is waiting
				if (r_next_use_valid) begin	// somewhere to put it?
					if (!(trace_in_valid[0]&~ignore_valid[0] && trace_in_pc[0] == r_waiting_next)) begin	// l1a
debug=1;
						trace_write_strobe = |match_waiting?0:r_waiting_valid;
						trace_write_data = r_waiting;

						c_meta_valid = r_waiting_valid;
						c_meta_next = r_waiting_next;
						c_meta_ret_addr = r_waiting_ret_addr;
						c_meta_ret_addr_short = r_waiting_ret_addr_short;
						c_meta_push_pop = r_waiting_push_pop;
						c_meta_pc = r_waiting_pc;
						write_meta = ! |match_waiting;
						write_meta_update = 0;

						if (! |match_waiting) begin
							c_last = r_next_use;
							c_last_valid = trace_write_strobe;
						end else begin
							c_last_valid = 0;
						end

						c_waiting_valid = 0;
						c_waiting_pc = 'bx;
						c_waiting_next = 'bx;
						c_waiting_ret_addr = 'bx;
						c_waiting_ret_addr_short = 'bx;
						c_waiting_push_pop = 'bx;
						c_waiting_offset = 'bx;
					end else begin														// l1b
debug=2;
						trace_write_strobe = |match_waiting?0:l1b_write_strobe;
						trace_write_data = l1b_write_data;

						c_meta_valid = l1b_write_strobe;
						c_meta_next = l1b_meta_next;
						c_meta_ret_addr = l1b_meta_ret_addr;
						c_meta_ret_addr_short = l1b_meta_ret_addr_short;
						c_meta_push_pop = l1b_meta_push_pop;
						c_meta_pc = r_waiting_pc;
						write_meta = ! |match_waiting;
						write_meta_update = 0;

						if (! |match_waiting) begin
							c_last = r_next_use;
							c_last_valid = trace_write_strobe;
						end else begin
							c_last_valid = 0;
						end

						c_waiting_valid = l1b_c_waiting_valid;
						c_waiting = l1b_c_waiting;
						c_waiting_pc = l1b_c_waiting_pc;
						c_waiting_next = l1b_c_waiting_next;	
						c_waiting_ret_addr = l1b_c_waiting_ret_addr;	
						c_waiting_ret_addr_short = l1b_c_waiting_ret_addr_short;	
						c_waiting_push_pop = l1b_c_waiting_push_pop;	
						c_waiting_offset = l1b_c_waiting_offset;
					end
				end	else begin	// else l2[a/b]		// discard waiting data, fill it with next data
debug=3;
					c_waiting_valid = l2_c_waiting_valid;
					c_waiting = l2_c_waiting;
					c_waiting_pc = l2_c_waiting_pc;
					c_waiting_next = l2_c_waiting_next;	
					c_waiting_ret_addr = l2_c_waiting_ret_addr;	
					c_waiting_ret_addr_short = l2_c_waiting_ret_addr_short;	
					c_waiting_push_pop = l2_c_waiting_push_pop;	
					c_waiting_offset = l2_c_waiting_offset;
				end
			end else
			if (trace_in_valid[0]&~ignore_valid[0]) begin
				if (r_last_valid[0] && !r_last_valid[NRETIRE-1]) begin	// 3
debug=4;
					trace_write_strobe = l3_write_strobe;
					trace_write_data = l3_write_data;

					write_meta = 1;
					write_meta_update = 1;
					c_meta_valid = l3_write_strobe;
					c_meta_next = l3_meta_next;
					c_meta_ret_addr = l3_meta_ret_addr;
					c_meta_ret_addr_short = l3_meta_ret_addr_short;
					c_meta_push_pop = l3_meta_push_pop;
					c_meta_pc = 'bx;

					c_last_valid = l3_write_strobe|r_last_valid;

					c_waiting_valid = l3_c_waiting_valid;
					c_waiting = l3_c_waiting;
					c_waiting_pc = l3_c_waiting_pc;
					c_waiting_next = l3_c_waiting_next;	
					c_waiting_ret_addr = l3_c_waiting_ret_addr;	
					c_waiting_ret_addr_short = l3_c_waiting_ret_addr_short;	
					c_waiting_push_pop = l3_c_waiting_push_pop;	
					c_waiting_offset = l3_c_waiting_offset;
				end else
				if (r_next_use_valid) begin	// somewhere to put it?
					if (|match_starting) begin	// already got a line in there
						trace_write_strobe = 0;
debug=9;
						write_meta = 0;
						c_last_valid = 0;
						c_waiting_valid = 0;
						c_skip = (current_valid_count > starting_valid_count ? current_valid_count-starting_valid_count:0);
					end else
					if (! |match_last) begin // 4
debug=5;
						trace_write_strobe = trace_in_valid&~ignore_valid;
						trace_write_data = cx;
	
						write_meta = 1;
						write_meta_update = 0;
						c_meta_valid = trace_in_valid&~ignore_valid;
						c_meta_pc = trace_in_pc[0];
						c_meta_next = l4_next;
						c_meta_ret_addr = l4_ret_addr;
						c_meta_ret_addr_short = l4_ret_addr_short;
						c_meta_push_pop = l4_push_pop;
	
						c_last = r_next_use;
						c_last_valid = trace_in_valid&~ignore_valid;

						c_waiting_valid = 0;
					end else begin	// 5
debug=6;
						c_waiting_valid = l2_c_waiting_valid;
						c_waiting = l2_c_waiting;
						c_waiting_pc = l2_c_waiting_pc;
						c_waiting_next = l2_c_waiting_next;	
						c_waiting_ret_addr = l2_c_waiting_ret_addr;	
						c_waiting_ret_addr_short = l2_c_waiting_ret_addr_short;	
						c_waiting_push_pop = l2_c_waiting_push_pop;	
						c_waiting_offset = l2_c_waiting_offset;
					end
				end else begin	// 5
debug=7;
					c_last_valid = 0;

					c_waiting_valid = l2_c_waiting_valid;
					c_waiting = l2_c_waiting;
					c_waiting_pc = l2_c_waiting_pc;
					c_waiting_next = l2_c_waiting_next;	
					c_waiting_ret_addr = l2_c_waiting_ret_addr;	
					c_waiting_ret_addr_short = l2_c_waiting_ret_addr_short;	
					c_waiting_push_pop = l2_c_waiting_push_pop;	
					c_waiting_offset = l2_c_waiting_offset;
				end
			end else begin
debug=8;
				// case 6
				trace_write_strobe = 0;
				c_waiting_valid = (|trace_in_valid?0:r_waiting_valid);
				c_last_valid = (|trace_in_valid?0:r_last_valid);
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

