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
module ioi(
    input clk,
    input reset,
`ifdef AWS_DEBUG
	input xxtrig,
`endif

	input	           io_cpu_addr_req_0,
	output	           io_cpu_addr_ack_0,
	input	[NPHYS-1:0]io_cpu_addr_0,
	input			   io_cpu_read_0,
	input			   io_cpu_lock_0,
	input	      [7:0]io_cpu_mask_0,
	input	   [RV-1:0]io_cpu_wdata_0,

	output			   io_cpu_data_req_0,
	input			   io_cpu_data_ack_0,
	output	   [RV-1:0]io_cpu_rdata_0,
	output		       io_cpu_data_err_0,
	
	input			   io_clic_m_enable_0,
	input			   io_clic_h_enable_0,
	input			   io_clic_s_enable_0,
	input			   io_clic_u_enable_0,
	output	      [7:0]io_clic_m_il_0,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_m_int_0,
	output			   io_clic_m_pending_0,
	output			   io_clic_m_vec_0,
	output	      [7:0]io_clic_h_il_0,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_h_int_0,
	output			   io_clic_h_pending_0,
	output			   io_clic_h_vec_0,
	output	      [7:0]io_clic_s_il_0,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_s_int_0,
	output			   io_clic_s_pending_0,
	output			   io_clic_s_vec_0,
	output	      [7:0]io_clic_u_il_0,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_u_int_0,
	output			   io_clic_u_pending_0,
	output			   io_clic_u_vec_0,
	output [NINTERRUPTS-1:0]io_interrupts_0,
	input			   io_clic_ack_0,
	input	     [$clog2(NINTERRUPTS)-1:0]io_clic_ack_int_0,

	input	           io_cpu_addr_req_1,
	output	           io_cpu_addr_ack_1,
	input	[NPHYS-1:0]io_cpu_addr_1,
	input			   io_cpu_read_1,
	input			   io_cpu_lock_1,
	input	      [7:0]io_cpu_mask_1,
	input	   [RV-1:0]io_cpu_wdata_1,

	output			   io_cpu_data_req_1,
	input			   io_cpu_data_ack_1,
	output	   [RV-1:0]io_cpu_rdata_1,
	output		       io_cpu_data_err_1,

	input			   io_clic_m_enable_1,
	input			   io_clic_h_enable_1,
	input			   io_clic_s_enable_1,
	input			   io_clic_u_enable_1,
	output	      [7:0]io_clic_m_il_1,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_m_int_1,
	output			   io_clic_m_pending_1,
	output			   io_clic_m_vec_1,
	output	      [7:0]io_clic_h_il_1,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_h_int_1,
	output			   io_clic_h_pending_1,
	output			   io_clic_h_vec_1,
	output	      [7:0]io_clic_s_il_1,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_s_int_1,
	output			   io_clic_s_pending_1,
	output			   io_clic_s_vec_1,
	output	      [7:0]io_clic_u_il_1,
	output	     [$clog2(NINTERRUPTS)-1:0]io_clic_u_int_1,
	output			   io_clic_u_pending_1,
	output			   io_clic_u_vec_1,
	output [NINTERRUPTS-1:0]io_interrupts_1,
	input			   io_clic_ack_1,
	input	     [$clog2(NINTERRUPTS)-1:0]io_clic_ack_int_1,
	
	output	           io_addr_req,
	input[NIOCLIENTS-1:0]io_addr_ack,
	output	[NPHYS-1:0]io_addr,
	output			   io_read,
	output	      [7:0]io_mask,
	output	   [RV-1:0]io_wdata,

	input[NIOCLIENTS-1:0]io_data_req,
	output			   io_data_ack,
	input	   [RV-1:0]io_rdata,
	input[NIOCLIENTS-1:0]io_data_err,

	output		[63:0]io_timer,

	output			   uart_tx,
	input			   uart_rx,
	output			   uart_rts,
	input			   uart_cts,

`ifdef VS2
    // AWS SD interface
	output			 sd_clk,
	output			 sd_reset,
    output           sd_command_start,
    input            sd_command_done,
    output           sd_read,
    output      [39:8]sd_address,
    output           sd_out_write,
    output     [63:0]sd_out,
    input            sd_out_full,
    output           sd_in_read,
    input      [63:0]sd_in,
    input            sd_in_empty,
`endif

`ifndef VS2
	input      [31:0]block_count_0,
	input      [31:0]block_addr_0,
	input      [31:0]block_count_1,
	input      [31:0]block_addr_1,
`endif
`ifdef VS2
	input	   [31:0]gpio_pads,
`else
`ifdef VERILATOR
	input	   [31:0]gpio_pads,
`else
	inout	   [31:0]gpio_pads,
`endif
`endif
	input dummy);

	parameter RV=64;
	parameter NPHYS=56;
	parameter NCPU=1;
	parameter NHART=1;
	parameter NIOCLIENTS=1;
	parameter NINTERRUPTS=20;
	parameter NPLICINT=16;

	reg	force_addr_ack;

	wire	  [NCPU-1:0]io_clic_m_enable;
	wire	  [NCPU-1:0]io_clic_h_enable;
	wire	  [NCPU-1:0]io_clic_s_enable;
	wire	  [NCPU-1:0]io_clic_u_enable;
	wire	       [7:0]io_clic_m_il[0:NCPU-1];
	wire	      [$clog2(NINTERRUPTS)-1:0]io_clic_m_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_m_pending;
	wire	  [NCPU-1:0]io_clic_m_vec;
	wire	       [7:0]io_clic_h_il[0:NCPU-1];
	wire	      [$clog2(NINTERRUPTS)-1:0]io_clic_h_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_h_pending;
	wire	  [NCPU-1:0]io_clic_h_vec;
	wire	       [7:0]io_clic_s_il[0:NCPU-1];
	wire	      [$clog2(NINTERRUPTS)-1:0]io_clic_s_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_s_pending;
	wire	  [NCPU-1:0]io_clic_s_vec;
	wire	       [7:0]io_clic_u_il[0:NCPU-1];
	wire	      [$clog2(NINTERRUPTS)-1:0]io_clic_u_int[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_u_pending;
	wire	  [NCPU-1:0]io_clic_u_vec;
	wire [NINTERRUPTS-1:0]io_interrupts[0:NCPU-1];
	wire	  [NCPU-1:0]io_clic_ack;
	wire[$clog2(NINTERRUPTS)-1:0]io_clic_ack_int[0:NCPU-1];

	assign		io_clic_m_enable[0] = io_clic_m_enable_0;
	assign		io_clic_h_enable[0] = io_clic_h_enable_0;
	assign		io_clic_s_enable[0] = io_clic_s_enable_0;
	assign		io_clic_u_enable[0] = io_clic_u_enable_0;
	assign		io_clic_m_il_0 = io_clic_m_il[0];
	assign		io_clic_m_int_0 = io_clic_m_int[0];
	assign		io_clic_m_pending_0 = io_clic_m_pending[0];
	assign		io_clic_m_vec_0 = io_clic_m_vec[0];
	assign		io_clic_h_il_0 = io_clic_h_il[0];
	assign		io_clic_h_int_0 = io_clic_h_int[0];
	assign		io_clic_h_pending_0 = io_clic_h_pending[0];
	assign		io_clic_h_vec_0 = io_clic_h_vec[0];
	assign		io_clic_s_il_0 = io_clic_s_il[0];
	assign		io_clic_s_int_0 = io_clic_s_int[0];
	assign		io_clic_s_pending_0 = io_clic_s_pending[0];
	assign		io_clic_s_vec_0 = io_clic_s_vec[0];
	assign		io_clic_u_il_0 = io_clic_u_il[0];
	assign		io_clic_u_int_0 = io_clic_u_int[0];
	assign		io_clic_u_pending_0 = io_clic_u_pending[0];
	assign		io_clic_u_vec_0 = io_clic_u_vec[0];
	assign	    io_interrupts_0 = io_interrupts[0];
	assign		io_clic_ack[0] = io_clic_ack_0; 
	assign		io_clic_ack_int[0] = io_clic_ack_int_0; 

	generate
		if (NCPU == 1) begin
			assign io_addr_req = io_cpu_addr_req_0;
			assign io_cpu_addr_ack_0 = |io_addr_ack || local_addr_ack|| force_addr_ack;
			assign io_addr = io_cpu_addr_0;
			assign io_read = io_cpu_read_0;
			assign io_mask = io_cpu_mask_0;
			assign io_wdata = io_cpu_wdata_0;
		
			assign io_cpu_data_req_0 = io_data_req || local_data_req != 0 || r_force_data_req;
			assign io_data_ack = io_cpu_data_ack_0;
			assign io_cpu_rdata_0 = local_data_req?local_rdata:io_rdata;
			assign io_cpu_data_err_0 = |(io_data_err&io_data_req) | r_fake_data_read;
		end else begin
			reg r_locked, c_locked;
			reg r_next, c_next;
			reg r_chosen, c_chosen;
			reg [NCPU-1:0]r_read_locked, c_read_locked;	// 1 bit for each CPU interface

			reg c_io_addr_req;
			assign io_addr_req = c_io_addr_req;
			reg c_io_cpu_addr_ack_0, c_io_cpu_addr_ack_1;
			assign io_cpu_addr_ack_0 = c_io_cpu_addr_ack_0;
			assign io_cpu_addr_ack_1 = c_io_cpu_addr_ack_1;
			reg c_io_cpu_data_req_0, c_io_cpu_data_req_1;
			assign io_cpu_data_req_0 = c_io_cpu_data_req_0;
			assign io_cpu_data_req_1 = c_io_cpu_data_req_1;
			reg	c_io_data_ack;
			assign io_data_ack = c_io_data_ack;

			always @(*) begin
				c_next = r_next;
				c_locked = r_locked;
				c_chosen = r_chosen;
				c_read_locked = r_read_locked;
		
				c_io_addr_req = 0;
				c_io_data_ack = 0;
				c_io_cpu_addr_ack_0 = 0;
				c_io_cpu_addr_ack_1 = 0;
				c_io_cpu_data_req_0 = 0;
				c_io_cpu_data_req_1 = 0;
				casez ({|local_data_req| (|io_data_req)|r_fake_data_read, r_chosen, local_addr_ack|(|io_addr_ack)|force_addr_ack, r_next, r_locked, io_cpu_data_ack_1, io_cpu_data_ack_0, io_cpu_read_1,io_cpu_read_0, r_read_locked, io_cpu_addr_req_1, io_cpu_addr_req_0}) // synthesis full_case parallel_case
				13'b??_0_?0_??_??_??_01:	;
				13'b??_1_?0_??_?0_0?_01:begin
									c_locked = 0;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_0 = 1;
									c_next = 1;
									c_chosen = 0;
									c_read_locked[0] = 0;
								end
				13'b??_1_?0_??_?1_0?_01:begin
									c_locked = 1;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_0 = 1;
									c_next = 1;
									c_chosen = 0;
									c_read_locked[0] = io_cpu_lock_0;
								end
				13'b00_?_?1_??_??_??_??:;
				13'b10_?_?1_?0_??_??_??:begin
									c_io_cpu_data_req_0 = 1;
								end
				13'b10_?_?1_?1_??_??_??:begin
									c_locked = 0;
									c_io_cpu_data_req_0 = 1;
									c_io_data_ack = 1;
								end

				13'b??_0_?0_??_??_??_10:	;
				13'b??_1_?0_??_0?_?0_10:begin
									c_locked = 0;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_1 = 1;
									c_next = 0;
									c_chosen = 1;
									c_read_locked[1] = 0;
								end
				13'b??_1_?0_??_1?_?0_10:begin
									c_locked = 1;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_1 = 1;
									c_chosen = 1;
									c_next = 0;
									c_read_locked[1] = io_cpu_lock_1;
								end
				13'b01_?_?1_??_??_??_??:;
				13'b11_?_?1_0?_??_??_??:begin
									c_io_cpu_data_req_1 = 1;
								end
				13'b11_?_?1_1?_??_??_??:begin
									c_locked = 0;
									c_io_cpu_data_req_1 = 1;
									c_io_data_ack = 1;
								end
									
									
				13'b??_0_?0_??_??_??_11:	;
				13'b??_1_?0_0?_?1_?1_?1,
				13'b??_1_?0_0?_?0_0?_11:begin
									c_locked = 0;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_0 = 1;
									c_next = 1;
									c_chosen = 0;
									c_read_locked[0] = 0;
								end
				13'b??_1_?0_1?_1?_?1_?1,
				13'b??_1_?0_1?_0?_0?_11:begin
									c_locked = 0;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_1 = 1;
									c_next = 0;
									c_chosen = 1;
									c_read_locked[0] = io_cpu_lock_0;
								end
				13'b??_1_?0_0?_?0_1?_1?,
				13'b??_1_?0_0?_?1_?0_11:begin
									c_locked = 1;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_0 = 1;
									c_chosen = 0;
									c_next = 1;
									c_read_locked[1] = 0;
								end
				13'b??_1_?0_1?_0?_1?_1?,
				13'b??_1_?0_1?_1?_?0_11:begin
									c_locked = 1;
									c_io_addr_req = 1;
									c_io_cpu_addr_ack_1 = 1;
									c_chosen = 1;
									c_read_locked[1] = io_cpu_lock_1;
									c_next = 0;
								end
				13'b??_0_??_??_??_??_00:;
				default: begin 
							c_locked = 1'bx;
                             c_io_addr_req = 1'bx;
                             c_io_cpu_addr_ack_1 = 1'bx;
                             c_chosen = 1'bx;
                             c_read_locked[1] = 1'bx;
                             c_next = 1'bx;
                         end

				endcase
			end

			always @(posedge clk) begin
				r_read_locked <= (reset?0:c_read_locked);
				r_locked <= (reset?0:c_locked);
				r_next <= (reset?0:c_next);
				r_chosen <= c_chosen;
			end

			assign io_addr = c_chosen?io_cpu_addr_1:io_cpu_addr_0;
			assign io_mask = c_chosen?io_cpu_mask_1:io_cpu_mask_0;
			assign io_wdata = c_chosen?io_cpu_wdata_1:io_cpu_wdata_0;
			assign io_read = c_chosen?io_cpu_read_1:io_cpu_read_0;
			

			wire [RV-1:0]rd;
			assign rd = (local_data_req?local_rdata:io_rdata);
			assign io_cpu_rdata_0 = rd;
			assign io_cpu_data_err_0 = |(io_data_err&io_data_req)|r_fake_data_read;
			assign io_cpu_rdata_1 = rd;
			assign io_cpu_data_err_1 = |(io_data_err&io_data_req)|r_fake_data_read;
			// FIXME for NCPU>2
		end
		if (NCPU > 1) begin
			assign		io_clic_m_enable[1] = io_clic_m_enable_1;
			assign		io_clic_h_enable[1] = io_clic_h_enable_1;
			assign		io_clic_s_enable[1] = io_clic_s_enable_1;
			assign		io_clic_u_enable[1] = io_clic_u_enable_1;
			assign		io_clic_m_il_1 = io_clic_m_il[1];
			assign		io_clic_m_int_1 = io_clic_m_int[1];
			assign		io_clic_m_pending_1 = io_clic_m_pending[1];
			assign		io_clic_m_vec_1 = io_clic_m_vec[1];
			assign		io_clic_h_il_1 = io_clic_h_il[1];
			assign		io_clic_h_int_1 = io_clic_h_int[1];
			assign		io_clic_h_pending_1 = io_clic_h_pending[1];
			assign		io_clic_h_vec_1 = io_clic_h_vec[1];
			assign		io_clic_s_il_1 = io_clic_s_il[1];
			assign		io_clic_s_int_1 = io_clic_s_int[1];
			assign		io_clic_s_pending_1 = io_clic_s_pending[1];
			assign		io_clic_s_vec_1 = io_clic_s_vec[1];
			assign		io_clic_u_il_1 = io_clic_u_il[1];
			assign		io_clic_u_int_1 = io_clic_u_int[1];
			assign		io_clic_u_pending_1 = io_clic_u_pending[1];
			assign		io_clic_u_vec_1 = io_clic_u_vec[1];
			assign	    io_interrupts_1 = io_interrupts[1];
			assign		io_clic_ack[1] = io_clic_ack_1; 
			assign		io_clic_ack_int[1] = io_clic_ack_int_1; 
		end
	endgenerate


	//
	//	bus timer makes sure all transactions complete
	//
	reg      r_fake_data_read, c_fake_data_read;
	reg [3:0]r_addr_timer, c_addr_timer;
	reg [11:0]r_data_timer, c_data_timer;
	reg		  r_io_reading, c_io_reading;
	reg		  r_force_data_req, c_force_data_req;

	always @(*) begin
		c_force_data_req = 0;
		c_addr_timer = 4'hf;
		c_fake_data_read = !reset && r_fake_data_read;
		c_io_reading = !reset & r_io_reading;
		if (io_addr_req && !((|io_addr_ack) && !local_addr_ack)) begin
			c_addr_timer = r_addr_timer-1;
		end
		if (r_fake_data_read && (io_data_ack||local_addr_ack)) begin
			c_fake_data_read = 0;
		end else
		if (r_io_reading && r_addr_timer == 0) begin
			c_fake_data_read = 1;
		end else
		if (r_addr_timer == 0 && io_addr_req && !(|io_addr_ack) && !local_addr_ack ) begin
			if (io_read) begin
				c_fake_data_read = 1;
			end
		end

		force_addr_ack = r_addr_timer == 0 && io_addr_req && !(|io_addr_ack) && !local_addr_ack;

		if (io_addr_req && (|io_addr_ack || local_addr_ack) && io_read) begin
			c_io_reading = 1;
		end else
		if (r_io_reading && (io_data_req || local_data_req || r_data_timer==0 || r_force_data_req)) begin
			c_io_reading = 0;
		end
		if (!reset && r_force_data_req || r_fake_data_read) begin
			c_force_data_req = !io_data_ack;
		end else
		if (!reset && r_data_timer==0 && !io_data_req && !local_data_req) begin
			c_force_data_req = 1;
		end
		if (reset || !r_io_reading) begin 
			c_data_timer = 4095;
		end else begin
			c_data_timer = r_data_timer-1;
		end
	end

	always @(posedge clk) begin
		r_force_data_req <= c_force_data_req;
		r_addr_timer <= c_addr_timer;
		r_data_timer <= c_data_timer;
		r_fake_data_read <= c_fake_data_read;
		r_io_reading <= c_io_reading;
	end
			

	//
	//	local clients:
	//
	//		- UART
	//		- interrupt controller
	//		- timer control
	//
	
	wire dtb_match =io_addr[NPHYS-1:16] == 40'hff_ff_ff_ff_fe;			  // 0xfffffffffffe0000 - 0xfffffffffffeffff
	wire hi_match = io_addr[NPHYS-1:16] == 40'hff_ff_ff_ff_ff;			  // 0xffffffffffff0000 - 0xffffffffffffffff
																		  // 0xffffffffffffc000 - 0xffffffffffffcfff -uart
																		  // 0xffffffffffffd000 - 0xffffffffffffdfff -sd
																		  // 0xffffffffffffe000 - 0xffffffffffffefff -gpio

	wire plic_base =   (io_addr[NPHYS-1:24]==32'hff_ff_ff_f4)&&(io_addr[23:22]==0);// 0xfffffffff4000000 - 0xfffffffff43fffff

	wire		 plic_addr_ack;
	wire [RV-1:0]plic_rdata;
	wire		 plic_data_req;

	wire clnt_base =   (io_addr[NPHYS-1:24]==32'hff_ff_ff_ff)&&(io_addr[23:20]==0);// 0xffffffffff000000 - 0xffffffffff0fffff
	wire clic_base_m = (io_addr[NPHYS-1:24]==32'hff_ff_ff_ff)&&(io_addr[23:20]==1);// 0xffffffffff100000 - 0xffffffffff1fffff
	wire clic_base_s = (io_addr[NPHYS-1:24]==32'hff_ff_ff_ff)&&(io_addr[23:20]==3);// 0xffffffffff200000 - 0xffffffffff2fffff
	wire clic_base_u = (io_addr[NPHYS-1:24]==32'hff_ff_ff_ff)&&(io_addr[23:20]==4);// 0xffffffffff400000 - 0xffffffffff4fffff

	wire [NCPU-1:0]clic_addr_ack;
	wire [RV-1:0]clic_rdata[0:NCPU-1];
	reg [RV-1:0]clic_data;
	wire [NCPU-1:0]clic_data_req;

	wire local_addr_ack = dtb_addr_ack|uart_addr_ack|timer_addr_ack|intr_addr_ack|(|clic_addr_ack)|sd_addr_ack|gpio_addr_ack|plic_addr_ack; // ored with other locals
	wire local_data_req = dtb_data_req|uart_data_req|timer_data_req|intr_data_req| (|clic_data_req)|sd_data_req|gpio_data_req|plic_data_req; // ored with other locals
	reg  [RV-1:0]local_rdata;

	generate
		if (NCPU == 1) begin
			always @(*) clic_data = clic_rdata[0];
		end else
		if (NCPU == 2) begin
			always @(*) begin
				casez(clic_data_req) // synthesis full_case parallel_case
				2'b?1: clic_data = clic_rdata[0];
				2'b1?: clic_data = clic_rdata[1];
				default: clic_data = 'bx;
				endcase
			end
		end
	endgenerate
	always @(*) begin
		casez({plic_data_req, gpio_data_req, sd_data_req, |clic_data_req, dtb_data_req, intr_data_req,timer_data_req,uart_data_req}) // synthesis full_case parallel_case
		8'b???????1: local_rdata = uart_rdata;
		8'b??????1?: local_rdata = timer_rdata;
		8'b?????1??: local_rdata = intr_rdata;
		8'b????1???: local_rdata = dtb_rdata;
		8'b???1????: local_rdata = clic_data;
		8'b??1?????: local_rdata = sd_rdata;
		8'b?1??????: local_rdata = gpio_rdata;
		8'b1???????: local_rdata = plic_rdata;
		default: local_rdata ='bx;
		endcase
	end

	wire uart_interrupt;
	wire[RV-1:0]uart_rdata;
	wire		uart_addr_ack;
	wire		uart_data_req;
	rv_io_uart	#(.RV(RV))uart(.clk(clk), .reset(reset),
				.addr_req(io_addr_req),
				.addr_ack(uart_addr_ack),
				.sel(hi_match && io_addr[15:12] == 4'b1100),
				.addr(io_addr[11:0]),
				.mask(io_mask),
				.read(io_read),
				.wdata(io_wdata),

				.rdata(uart_rdata),
				.data_req(uart_data_req),
				.data_ack(io_data_ack),

				.interrupt(uart_interrupt),
				.tx(uart_tx),
				.rx(uart_rx),
				.rts(uart_rts),
				.cts(uart_cts));


	
	wire[RV-1:0]timer_rdata;
	wire		timer_addr_ack;
	wire		timer_data_req;
	
	wire [NCPU-1:0]timer_interrupt;
	wire [NCPU-1:0]ip_interrupt;

	rv_io_timer	#(.NCPU(NCPU), .RV(RV))timer(.clk(clk), .reset(reset),
`ifdef AWS_DEBUG
				.xxtrig(xxtrig),
`endif
				.addr_req(io_addr_req),
				.addr_ack(timer_addr_ack),
				.sel(clnt_base && io_addr[19:16]==0),
				.addr(io_addr[15:0]),
				.mask(io_mask),
				.read(io_read),
				.wdata(io_wdata),

				.rdata(timer_rdata),
				.data_req(timer_data_req),
				.data_ack(io_data_ack),

				.timer(io_timer),

				.timer_interrupt(timer_interrupt),
				.ip_interrupt(ip_interrupt)
				);
	

	wire[RV-1:0]intr_rdata;
	wire		intr_addr_ack;
	wire		intr_data_req;
	assign		intr_addr_ack=0;
	assign		intr_data_req=0;

	wire[RV-1:0]dtb_rdata;
	wire		dtb_addr_ack;
	wire		dtb_data_req;
	rv_io_dtb	#(.RV(RV))dtb(.clk(clk), .reset(reset),
				.addr_req(io_addr_req),
				.addr_ack(dtb_addr_ack),
				.sel(dtb_match),
				.addr(io_addr[11:0]),
				.read(io_read),

				.rdata(dtb_rdata),
				.data_req(dtb_data_req),
				.data_ack(io_data_ack));

	wire [RV-1:0]sd_rdata;
	wire		 sd_data_req;
	wire		 sd_addr_ack;
	wire		 sd_interrupt;

	rv_io_sd	#(.RV(RV))sd(.clk(clk), .reset(reset),
				.addr_req(io_addr_req),
                .addr_ack(sd_addr_ack),
                .sel(hi_match && io_addr[15:12] == 4'b1101),
                .addr(io_addr[11:0]),
				.mask(io_mask),
				.read(io_read),
				.wdata(io_wdata),

`ifndef VS2
				.block_count_0(block_count_0),
				.block_addr_0(block_addr_0),
				.block_count_1(block_count_1),
				.block_addr_1(block_addr_1),
`endif
                .rdata(sd_rdata),
                .data_req(sd_data_req),
                .data_ack(io_data_ack),

				.interrupt(sd_interrupt)
`ifdef VS2
				,
				// AWS SD interface
				.sd_clk(sd_clk),
				.sd_reset(sd_reset),
				.sd_command_start(sd_command_start),
				.sd_command_done(sd_command_done),
				.sd_read(sd_read),
				.sd_address(sd_address),
				.sd_out_write(sd_out_write),
				.sd_out(sd_out),
				.sd_out_full(sd_out_full),
				.sd_in_read(sd_in_read),
				.sd_in(sd_in),
				.sd_in_empty(sd_in_empty)
`endif
				);

	wire [RV-1:0]gpio_rdata;
	wire		 gpio_data_req;
	wire		 gpio_addr_ack;
	wire		 gpio_interrupt;

	rv_io_gpio	#(.RV(RV))gpio(.clk(clk), .reset(reset),
				.addr_req(io_addr_req),
                .addr_ack(gpio_addr_ack),
                .sel(hi_match && io_addr[15:12] == 4'b1110),
                .addr(io_addr[11:0]),
				.mask(io_mask),
				.read(io_read),
				.wdata(io_wdata),

                .rdata(gpio_rdata),
                .data_req(gpio_data_req),
                .data_ack(io_data_ack),

				.interrupt(gpio_interrupt),

				.gpio_pads(gpio_pads));

	genvar C;

	wire [NCPU*NHART-1:0]plic_pending;
	generate 
		for (C = 0; C < NCPU; C=C+1) begin:clic
			clic   #(.RV(RV), .NINTERRUPTS(NINTERRUPTS))c(.clk(clk), .reset(reset),
                .addr_req(io_addr_req),
                .addr_ack(clic_addr_ack[C]),
                .sel_m(clic_base_m && io_addr[19:16] == C),
                .sel_s(clic_base_s && io_addr[19:16] == C),
                .sel_u(clic_base_u && io_addr[19:16] == C),
                .addr(io_addr[15:0]),
                .mask(io_mask),
                .read(io_read),
                .wdata(io_wdata),
				
				.timer_interrupt(timer_interrupt[C]),
				.ip_interrupt(ip_interrupt[C]),
				.interrupt({1'b0,gpio_interrupt, sd_interrupt,uart_interrupt}),
				.plic_interrupt({plic_pending[C],plic_pending[C],plic_pending[C],plic_pending[C]}),

                .rdata(clic_rdata[C]),
                .data_req(clic_data_req[C]),
                .data_ack(io_data_ack),

				.clic_m_enable(io_clic_m_enable[C]),
				.clic_h_enable(io_clic_h_enable[C]),
				.clic_s_enable(io_clic_s_enable[C]),
				.clic_u_enable(io_clic_u_enable[C]),
				.clic_m_il(io_clic_m_il[C]),
				.clic_m_int(io_clic_m_int[C]),
				.clic_m_pending(io_clic_m_pending[C]),
				.clic_m_vec(io_clic_m_vec[C]),
				.clic_h_il(io_clic_h_il[C]),
				.clic_h_int(io_clic_h_int[C]),
				.clic_h_pending(io_clic_h_pending[C]),
				.clic_h_vec(io_clic_h_vec[C]),
				.clic_s_il(io_clic_s_il[C]),
				.clic_s_int(io_clic_s_int[C]),
				.clic_s_pending(io_clic_s_pending[C]),
				.clic_s_vec(io_clic_s_vec[C]),
				.clic_u_il(io_clic_u_il[C]),
				.clic_u_int(io_clic_u_int[C]),
				.clic_u_pending(io_clic_u_pending[C]),
				.clic_u_vec(io_clic_u_vec[C]),
				.clic_ack(io_clic_ack[C]),
				.clic_ack_int(io_clic_ack_int[C]),
				.io_interrupts(io_interrupts[C])
			);


		end
	endgenerate


	plic	#(.RV(RV), .NHART(NCPU*NHART), .NPLICINT(NPLICINT))plic(
		    .clk(clk),
			.reset(reset),
            .addr_req(io_addr_req),
            .addr_ack(plic_addr_ack),
            .sel(plic_base),
            .addr(io_addr[21:0]),
            .mask(io_mask),
            .read(io_read),
            .wdata(io_wdata),
				
            .rdata(plic_rdata),
            .data_req(plic_data_req),
            .data_ack(io_data_ack),
			//                      6                  5                4            3          2              1
			.irq({8'b0,1'b0,timer_interrupt[0], ip_interrupt[0], gpio_interrupt, sd_interrupt,uart_interrupt, 1'b0}),
			.interrupt_pending(plic_pending)
        );


`ifdef AWS_DEBUG
    ila_ioi ila_ioi(.clk(clk),
            .xxtrig(xxtrig),
            .reset(reset),
            .io_addr_req(io_addr_req),
            .io_addr_ack(local_addr_ack),
            .hi_match(hi_match),
            .io_read(io_read),
            .io_addr(io_addr[23:0]),    // 24
            .io_wdata(io_wdata[7:0]),   //8
            .io_mask(io_mask),      // 8
            .io_data_req(local_data_req),
            .io_data_ack(io_data_ack),
            .io_rdata(local_rdata[7:0]),    //8
            .uart_rx(uart_rx),
            .uart_tx(uart_tx)
            );

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

