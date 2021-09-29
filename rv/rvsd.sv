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

//
// proto sd card interface
//
//
//		- this is a prototypical SD card interface - no DMA, but enough to get us booted
//
//			0-7:	read fifo/write fifo
//			8:		read fifo/write fifo	 - 1 byte
//			16:		status:
//					0 - interrupt pending  (writing a 1 clears is
//					1 - busy
//					2 - read data available
//					3 - write data space available
//					4 - can command
//					8 - read-only media
//			24:		control
//					0 - interrupt enable
//					1 - interrupt when read data available 
//					2 - interrupt when write space available 
//					3 - interrupt when can command
//					8 - flush write buffer
//					9 - flush read buffer
//					10 - full reset
//			32:		command			- writing starts command
//			40:		simple command  - writing 1 starts read, 0 starts write 256 bytes only
//			48:		address
//			56:		parameters
//					4:0		- read latency
//
//
//		commands supported (initially):
//
//		- initially just simple commands
//
//
module rv_io_sd(
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

	output			   interrupt
`ifndef VS2
	,
	input        [31:0]block_count_0,
	input        [31:0]block_addr_0,
	input        [31:0]block_count_1,
	input        [31:0]block_addr_1
`endif
`ifdef VS2
		,
	// AWS interface
	output			 sd_clk,
	output			 sd_reset,
	output			 sd_command_start,
	input			 sd_command_done,
	output			 sd_read,
	output		[39:8]sd_address,
	output			 sd_out_write,
	output	   [63:0]sd_out,
	input			 sd_out_full,
	output			 sd_in_read,
	input	   [63:0]sd_in,
	input			 sd_in_empty
`endif

	);
	parameter RV=64;

`ifdef VS2
	assign sd_clk = clk;
	assign sd_reset = reset;
`endif

	assign addr_ack = addr_req&sel;

	wire ack;
	reg [63:0]r_data;
	assign rdata = r_data;

	reg r_data_req;
	reg r_backoff;
	assign data_req = r_data_req;

	wire	read_empty, write_full;
	reg		r_int_can_command, r_int_write, r_int_read, r_int_enable;
	reg		r_busy;

	wire interrupt_pending = (r_int_can_command&~r_busy) |
							 (r_int_read & ~read_empty) |
							 (r_int_write & ~write_full);

	assign interrupt = interrupt_pending & r_int_enable;

	reg		flush_read_fifo, flush_write_fifo;

	reg	[39:0]r_address;
	reg	[7:0]r_command;
	reg [7:0]r_cs;

	always @(*)
	if (reset) begin
		flush_read_fifo = 1;
		flush_write_fifo = 1;
	end else begin
		flush_read_fifo = 0;
		flush_write_fifo = 0;
		if (sel && addr_req && !read && addr[11:3] == 3 && mask[1]) begin
			if (wdata[8])
				flush_write_fifo = 1;
			if (wdata[9])
				flush_read_fifo = 1;
		end
	end

	reg				 r_read;
`ifdef VS2
	assign		sd_address = r_address[39:8];
	reg				 r_command_start;
	assign			 sd_command_start = r_command_start;
	assign sd_read = r_read;
	reg				r_out_write;
	assign			sd_out_write = r_out_write;
	reg		[63:0]r_wdata;
	assign sd_out = r_wdata;
	reg				r_in_read;
	assign			sd_in_read = r_in_read;
`else
	logic [63:0]disk[0:4*1024*1024-1];
`ifndef VERILATOR
	int f,res;
	initial begin
		f = $fopenr("x.bin");
		res = $fread(disk, f);
		$fclose(f);
		for (res = 0;res < (4*1024*1024);res=res+1) begin :rr
			reg [63:0]t;

            t = disk[res];
            t = {t[7:0],t[15:8],t[23:16],t[31:24],t[39:32],t[47:40],t[55:48], t[63:56]};
            disk[res] = t;
        end
	end
`endif
		
`endif

	always @(posedge clk)
	if (reset) begin
		r_busy <= 0;
`ifdef VS2
		r_command_start <= 0;
`endif
	end else
	if (sel & addr_req & !read && addr[11:3]==5 && mask[0] && !r_busy) begin
`ifdef VS2
		r_busy <= 1;
		r_command_start <= 1;
`else
		r_busy <= 0;
`endif
`ifdef VS2
	end else begin
		if (sd_command_done && !r_command_start) 
			r_busy <= 0;
		r_command_start <= 0;
`endif
	end

	always @(posedge clk)
	if (reset) begin
		r_int_can_command <= 0;
		r_int_write <= 0;
		r_int_read <= 0;
		r_int_enable <= 0;
		r_cs <= ~0;
`ifdef VS2
		r_out_write <= 0;
`endif
	end else 
	if (sel & addr_req & !read) begin
		case (addr[11:3])	// synthesis full_case parallel_case
			0:		// write fifo
				begin
`ifdef VS2
					r_wdata <= wdata;
					r_out_write <= !sd_out_full;
`else
					disk[r_address[39:3]] <= wdata;

					r_address <= r_address+8;
`endif
				end
			1:;		// write fifo 1-byte
			3:		// control
				begin
					if (mask[0]) begin
						r_int_can_command <= wdata[3];
						r_int_write <=wdata[2];
						r_int_read <= wdata[1];
						r_int_enable <= wdata[0];
					end
					if (mask[2]) begin
						r_cs <= wdata[23:16];
					end
				end
			4:		// command
				begin
					if (mask[0] && !r_busy) begin
						r_command <= wdata[7:0];
						// start command
					end
				end
			5:		// simple command
				begin
					if (mask[0] && !r_busy) begin
						r_read <= wdata[0];
					
						// start command
					end
				end
			6:		// address
				begin
					r_address[7:0] <= 0;
					if (mask[0]) begin
						r_address[15:8] <= wdata[7:0];
					end
					if (mask[1]) begin
						r_address[23:16] <= wdata[15:8];
					end
					if (mask[2]) begin
						r_address[31:24] <= wdata[23:16];
					end
					if (mask[3]) begin
						r_address[39:32] <= wdata[31:24];
					end
				end
		default: ;
		endcase
	end else begin
`ifdef VS2
		r_out_write <= 0;
`endif
	end


	always @(posedge clk) begin
		if (reset) begin
			r_data_req <= 0;
`ifdef VS2
			r_in_read <= 0;
`endif
		end else
		if (sel&addr_req&read) begin
			case (addr[11:3])	// synthesis full_case parallel_case
			0:		// read fifo
				begin
`ifdef VS2
					r_data <= sd_in;
					r_in_read <= !sd_in_empty;
`else
					if (r_address[39:8] == 32'hffff_ffff) begin
						case (r_address[7:3])
						0: r_data <= block_addr_0;
						1: r_data <= block_count_0;
						2: r_data <= block_addr_1;
						3: r_data <= block_count_1;
						default: r_data <= 0;
						endcase
					end else begin
						r_data <= disk[r_address[31:3]];
					end
					r_address <= r_address+8;
`endif
				end
			1:;		// read fifo 1-byte
			2:		// read status
					r_data <= { 47'b0,
						1'b0,
						4'b0,
						~r_busy,
						~write_full,
						~read_empty,
						r_busy,
						interrupt_pending};
			3:		// control
					r_data <= {53'b0,
						3'b0,
						4'b0,
						r_int_can_command,
						r_int_write,
						r_int_read,
						r_int_enable};
			4:		// command
					r_data <= {48'b0, r_command};
			5:		// address
					r_data <= {32'b0,r_address};
			default:
				r_data <= 0;
			endcase
			r_data_req <= 1;
		end else begin
`ifdef VS2
			r_in_read <= 0;
`endif
			if (data_ack)
				r_data_req <= 0;
		end
	end	

`ifdef AWS_DEBUG
`ifdef NOTDEF

    ila_mb ila_sd(.clk(clk),
            .probe0_0(reset),
            .probe1_0(sd_command_start),
            .probe2_0(sd_command_done),
            .probe3_0(sd_out_write),
            .probe4_0(sd_out_full),
            .probe5_0(sd_in_read),
            .probe6_0(sd_in_empty),
            .probe7_0(r_busy),
            .probe8_0(1'b0),
            .probe9_0(1'b0),
            .probe10_0(sel),
            .probe11_0(addr_req),
            .probe12_0(addr_ack),
            .probe13_0(read),
            .probe14_0(data_ack),
            .probe15_0(r_data_req),
            .probe16_0(r_data[7:0]),
            .probe17_0(addr[10:3]),
            .probe18_0(8'b0),
            .probe19_0(8'b0),
            .probe20_0(8'b0),
            .probe21_0(8'b0),
            .probe22_0(8'b0),
            .probe23_0(8'b0)
            );
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
