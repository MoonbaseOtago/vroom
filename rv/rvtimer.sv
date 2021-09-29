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


// CLNT
module rv_io_timer(
    input clk,
    input reset,
`ifdef AWS_DEBUG
    input xxtrig,
`endif

    input              addr_req,
    output             addr_ack,
	input			   sel,
    input        [15:0]addr,
    input              read,
    input         [7:0]mask,
    input      [RV-1:0]wdata,

    output             data_req,
    input              data_ack,
    output     [RV-1:0]rdata,

	output	   [63:0]timer,

	output	   [NCPU-1:0]timer_interrupt,
	output	   [NCPU-1:0]ip_interrupt);
	
	parameter RV=64;
	parameter NCPU=1;
//
//	Registers:	
//			write		read
//	   00:	timer
//	   08:	timercmp0
//	   10:	timer
//	   18:	timercmp1
//		......
//

	reg [63:0]r_timer, c_timer;
	assign timer = r_timer;
	reg [63:0]r_timer_cmp[0:NCPU-1];
wire [63:0]r_timer_cmp_0=r_timer_cmp[0];
	reg [63:0]c_timer_cmp[0:NCPU-1];

	reg [15:3]r_rd_addr, c_rd_addr;
	reg      r_rd_pending, c_rd_pending;
	assign data_req = r_rd_pending;

	always @(*) begin
		c_rd_pending = r_rd_pending&!reset&!data_ack;
		c_rd_addr = r_rd_addr;
		if (addr_req && read && sel) begin
			c_rd_addr = addr[15:3];
			c_rd_pending = 1;
		end
	end

	assign addr_ack = addr_req&sel;

	reg [63:0]d;
	assign rdata=d;

	reg	[NCPU-1:0]r_timer_int;
	assign timer_interrupt = r_timer_int;
	reg	[NCPU-1:0]r_msip, c_msip;
	assign ip_interrupt = r_msip;

	always @(*) begin
		case (r_rd_addr[15:14]) // synthesis full_case parallel_case
		2'b00:
			if (NCPU == 1 && r_rd_addr[13:3] == 0) begin
				d = {63'b0, r_msip[0]};
//			end else
//			if (NCPU == 2 && r_rd_addr[13:3] < (NCPU/2)) begin
//				d = {31'b0, r_msip[1], 31'b0, r_msip[0]};
//			end else
//			if (NCPU > 2 && NCPU <= 4 && r_rd_addr[13:3] < (NCPU/2)) begin
//				d = {31'b0, r_msip[{r_rd_addr[3], 1'b1}], 31'b0, r_msip[{r_rd_addr[3], 1'b0}]};
//			end else
//			if (NCPU > 4 && NCPU <= 8 && r_rd_addr[13:3] < (NCPU/2)) begin
//				d = {31'b0, r_msip[{r_rd_addr[4:3], 1'b1}], 31'b0, r_msip[{r_rd_addr[4:3], 1'b0}]};
//			end else
//			if (NCPU > 8 && NCPU <= 16 && r_rd_addr[13:3] < (NCPU/2)) begin
//				d = {31'b0, r_msip[{r_rd_addr[5:3], 1'b1}], 31'b0, r_msip[{r_rd_addr[5:3], 1'b0}]};
			end else begin
				d = 0;
			end
		2'b01:
			if (r_rd_addr[13:3] < NCPU) begin
				d = r_timer_cmp[r_rd_addr[13:3]];
			end else begin
				d = 0;
			end
		2'b10:
			if (r_rd_addr[13:3] == 13'b11_1111_1111_1) begin
				d = r_timer;
			end else begin
				d = 0;
			end
		default:
			d = 0;
		endcase
	end

	reg [4:0]r_prescale;
	//reg [11:0]r_prescale;
	wire	timer_inc = r_prescale==0;
	
	always @(posedge clk) begin
		r_prescale <= (reset?0:r_prescale+1);
		r_rd_addr <= c_rd_addr;
		r_rd_pending <= c_rd_pending;
		r_timer <= c_timer;
	end

	always @(*) begin
		c_timer = r_timer;
		if (reset) begin
			c_timer = 0;
		end else begin
			if (timer_inc) 
				c_timer = r_timer+1;
			if (addr_req && addr_ack && sel && !read && addr[15:3] == 13'b1101_1111_1111_1) begin		// io cycle to us
				if (mask[7])
					c_timer[63:56] = wdata[63:56];
				if (mask[6])
					c_timer[55:48] = wdata[55:48];
				if (mask[5])
					c_timer[47:40] = wdata[47:40];
				if (mask[4])
					c_timer[39:32] = wdata[39:32];
				if (mask[3])
					c_timer[31:24] = wdata[31:24];
				if (mask[2])
					c_timer[23:16] = wdata[23:16];
				if (mask[1])
					c_timer[15:8] = wdata[15:8];
				if (mask[0])
					c_timer[7:0] = wdata[7:0];
			end
		end
	end

	genvar I;
	generate
		for (I=0; I < NCPU; I=I+1) begin
			always @(*) begin
				c_timer_cmp[I] = r_timer_cmp[I];
				c_msip[I] = r_msip[I];
				if (reset) begin
					c_timer_cmp[I] = 0;
					c_msip[I] = 0;
				end else begin
					if (NCPU == 0) begin
						if (addr_req && addr_ack && sel && !read && addr[15:14] == 2'b0 && addr[13:3]==0) begin		// io cycle to us
							if (mask[0])
								c_msip[I] = wdata[0];
						end
					end else begin
						if (addr_req && addr_ack && sel && !read && addr[15:14] == 2'b0 && addr[13:3]<=NCPU/2) begin		// io cycle to us
							if (((I&1)==1) && mask[4])
								c_msip[I] = wdata[32];
							if (((I&1)==0) && mask[0])
								c_msip[I] = wdata[0];
						end
					end
					if (addr_req && addr_ack && sel && !read && addr[15:14] == 2'b01 && addr[13:3]==I) begin		// io cycle to us
						if (mask[7])
							c_timer_cmp[I][63:56] = wdata[63:56];
						if (mask[6])
							c_timer_cmp[I][55:48] = wdata[55:48];
						if (mask[5])
							c_timer_cmp[I][47:40] = wdata[47:40];
						if (mask[4])
							c_timer_cmp[I][39:32] = wdata[39:32];
						if (mask[3])
							c_timer_cmp[I][31:24] = wdata[31:24];
						if (mask[2])
							c_timer_cmp[I][23:16] = wdata[23:16];
						if (mask[1])
							c_timer_cmp[I][15:8] = wdata[15:8];
						if (mask[0])
							c_timer_cmp[I][7:0] = wdata[7:0];
					end
				end
			end

			always @(posedge clk) begin
				r_timer_cmp[I] <= c_timer_cmp[I];
				r_msip[I] <= c_msip[I];
				r_timer_int[I] <= r_timer_cmp[I] <= r_timer;
			end
		end
	endgenerate

`ifdef AWS_DEBUG
`ifdef NOTDEF
ila_timer ila_timer(.clk(clk),
	.xxtrig(xxtrig),
    .addr_req(addr_req&addr_ack&sel),
	.addr(addr),		// 16
	.read(read),
	.mask(mask),		// 8
	.wdata(wdata[31:0]),	// 32
	.data_req(data_req&data_ack),
	.rdata(wdata[31:0]),	// 32
	.r_timer(r_timer[31:0]),	// 32
	.r_timer_cmp_0(r_timer_cmp[0][31:0]));	// 32
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

