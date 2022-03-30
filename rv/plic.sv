//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2021-22 Paul Campbell - paul@taniwha.com
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

module plic(
	input	clk,
	input	reset,

	input		addr_req,
	output		addr_ack,
	input 		sel,
	input [21:0]addr,
	input 		read,
	input  [7:0]mask,
	input[RV-1:0]wdata,
	
	output		data_req,
	input		data_ack,
	output[RV-1:0]rdata,

	input  [NPLICINT-1:1]irq,
	output  [NHART-1:0]interrupt_pending
		);

	parameter NPLICINT=16;
	parameter NHART=1;
	parameter RV=64;


	reg [RV-1:0]r_rdata, c_rdata;
	assign rdata = r_rdata;
	reg         r_dreq;
    assign data_req = r_dreq;

    always @(posedge clk) begin
        if (addr_req && sel && read)
            r_rdata <= c_rdata;
        if (reset || data_ack) begin
            r_dreq <= 0;
        end else
        if (addr_req && sel && read) begin
            r_dreq <= 1;
        end
    end

	wire lock = 0;		// FIXME - as we scale do something here to enable multiple clock timing paths by locking the arbiter

	assign addr_ack = addr_req&sel;

	reg [10:0]r_priority_0[1:(NPLICINT/2)-1];
	reg [10:0]r_priority_1[0:(NPLICINT/2)-1];

	genvar I, H;
	generate 
		for (I=0; I < (NPLICINT/2); I=I+1) begin
			if (I != 0) begin
				always @(posedge clk)
				if (reset) begin
					r_priority_0[I] <= 0;
				end else
				if (addr_req && sel && !read && addr[21:12] == 0 && addr[11:3] == I && mask[1:0]==2'b11) begin
					r_priority_0[I] <= wdata[10:0];
				end
			end

			always @(posedge clk)
			if (reset) begin
				r_priority_1[I] <= 0;
			end else
			if (addr_req && sel && !read && addr[21:12] == 0 && addr[11:3] == I && mask[5:4]==2'b11) begin
				r_priority_1[I] <= wdata[42:32];
			end
		end

		wire [63:0]c_pending_mux, c_enabled_mux;

		wire	[NPLICINT-1:0]pending;
		assign pending[0]=0;
		wire	[NHART-1:0]enabled[0:NPLICINT-1];
		assign enabled[0]=0;
		if (NPLICINT < 64) begin
			assign   c_pending_mux = (addr[11:3]!=0?64'b0: {1'b0,pending});

			reg		[NPLICINT-1:1]r_int_enable[0:NHART-1];

			for (H = 0; H < NHART; H=H+1) begin 
				wire [63:1]t = {1'b0,r_int_enable[H]};
				wire [63:1]w = {mask[7]?wdata[63:56]:t[63:56],
								mask[6]?wdata[55:48]:t[55:48],
								mask[5]?wdata[47:40]:t[47:40],
								mask[4]?wdata[39:32]:t[39:32],
								mask[3]?wdata[31:24]:t[31:24],
								mask[2]?wdata[23:16]:t[23:16],
								mask[1]?wdata[15:8]:t[15:8],
								mask[0]?wdata[7:1]:t[7:1]};
				always @(posedge clk)
				if (reset) begin
					r_int_enable[H] <= 0;
				end else 
				if (addr_req && sel && !read && addr[21:7] == (32'h40+H) && addr[7:3] == 0) begin
					r_int_enable[H] <= w;
				end 
				for (I = 1; I < NPLICINT; I=I+1) begin
					assign enabled[I][H] = r_int_enable[H][I];
				end
			end

			assign    c_enabled_mux = (addr[11:7] >= (NHART) || addr[6:3]!=0?64'b0: {1'b0,r_int_enable[addr[11:7]]});
		end else begin
			wire	[63:0]int_pending[0:(NPLICINT>>6)-1];
			for (I = 0; I < (NPLICINT>>6)-1; I=I+1) begin
				assign int_pending[I] = pending[(I<<6)+63:(I<<6)]; 
			end
			
			reg	[63:0]r_int_enable[0:NHART-1][0:(NPLICINT>>6)-1];
			for (H = 0; H < NHART; H=H+1) begin
				for (I = 1; I < NPLICINT-1; I=I+1) begin
					assign enabled[I][H] = r_int_enable[H][I];
				end
				for (I = 0; I < (NPLICINT>>6)-1; I=I+1) begin
					wire [63:0]t = r_int_enable[H][I];
					wire [63:0]w = {mask[7]?wdata[63:56]:t[63:56],
									mask[6]?wdata[55:48]:t[55:48],
									mask[5]?wdata[47:40]:t[47:40],
									mask[4]?wdata[39:32]:t[39:32],
									mask[3]?wdata[31:24]:t[31:24],
									mask[2]?wdata[23:16]:t[23:16],
									mask[1]?wdata[15:8]:t[15:8],
									mask[0]?wdata[7:0]:t[7:0]};

					always @(posedge clk) 
					if (reset) begin
						r_int_enable[H][I] <= 0;
					end else 
					if (addr_req && sel && !read && addr[21:7] == (32'h400+H) && addr[6:3] == I) begin
						r_int_enable[H][I] <= w;
					end
				end
			end
			assign  c_pending_mux = (addr[11:3] >= (NPLICINT>>6)?64'b0: int_pending[addr[11:3]]);
			assign  c_enabled_mux = (addr[20:7] >= (NHART+2) || addr[6:3]>=(NPLICINT>>6)?64'b0: {1'b0,r_int_enable[addr[20:7]][addr[6:3]]});
		end

		reg [10:0]r_threshold[0:NHART-1];
		for (H = 0; H < NHART; H=H+1) begin
			wire [22-12-1:0]h=H;
			always @(posedge clk) 
			if (reset) begin
				r_threshold[H] <= 11'h7ff;
			end else
			if (addr_req && sel && !read && addr[21:0] == (22'h200000+{h, 12'h000}) && mask[3:0]==4'b1111) begin
				r_threshold[H] <= wdata[10:0];
			end
		end

		reg claiming;
		reg r_claiming;
		reg [7:0]r_claim;
		wire [7:0]c_claim = addr[20:12] < NHART ?int_id_1[addr[20:12]]: 8'b0;
		always @(posedge clk)
		if (addr_req&&addr_ack) begin
			r_claiming <= claiming;
			r_claim <= c_claim;
		end
		wire claimed = r_claiming&data_req&data_ack;
		wire freed = addr_req && sel && !read && addr[21]&&mask[7:4]==4'b1111&&addr[20:12]<NHART&&enabled[wdata[39:32]][addr[20:12]];

		wire [9:0]hh=NHART;
		always @(*) begin
			claiming = 0;
			case (addr[21:12]) // synthesis full_case parallel_case
			0:	if (addr[11:3] >= (NPLICINT/2)) begin
					c_rdata = 64'b0;
				end else 
				if (addr[11:3] == 0) begin
					c_rdata = {21'b0,r_priority_1[addr[11:3]], 32'b0};
				end else begin
					c_rdata = {21'b0,r_priority_1[addr[11:3]], 21'b0,r_priority_0[addr[11:3]]};
				end
			1:	c_rdata = c_pending_mux;
			default:
				if (addr[21:7] >= 2 && {addr[21:7],7'b0} < 22'h200000) begin
					c_rdata = c_enabled_mux;
				end else
				if ({addr[21:12],12'b0} >= 22'h200000 && {addr[21:12],12'b0} < (22'h200000|{hh,12'b0}) && addr[11:4]==0) begin
					claiming = addr[2];
					c_rdata = {24'b0,c_claim, 21'b0,r_threshold[addr[20:12]]};
				end else begin
					c_rdata = 64'b0;
				end
			endcase
		end

		//wire [7:0]int_id[0:NHART-1][1:NPLICINT];
		//wire [10:0]int_prio[0:NHART-1][1:NPLICINT];

		//for (H=0; H<NHART; H=H+1) begin
			//assign int_id[H][NPLICINT]=0;
			//assign int_prio[H][NPLICINT]=0;
		//end
		wire [7:0]free = addr[20:12] < NHART ?wdata[39:32]: 8'b0;


		//for (I=1; I < NPLICINT; I=I+1) begin	// sadly verilator is broken in and around arrays so we can't generate here
				wire [7:0]int_id_15[0:NHART-1];
				wire [10:0]int_prio_15[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(15))slice15(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[15]),
					.pending(pending[15]),
					.claimed(claimed&&r_claim==15),
					.freed(freed&&free==15),
					.ie(enabled[15]),
					.prio(r_priority_1[15>>1]),
					.prio_in_0(11'b0),	// FIXME scale for multiple harts
					.id_in_0(8'b0),
					.prio_out_0(int_prio_15[0]),
					.id_out_0(int_id_15[0])
					);
				wire [7:0]int_id_14[0:NHART-1];
				wire [10:0]int_prio_14[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(14))slice14(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[14]),
					.pending(pending[14]),
					.claimed(claimed&&r_claim==14),
					.freed(freed&&free==14),
					.ie(enabled[14]),
					.prio(r_priority_0[14>>1]),
					.prio_in_0(int_prio_15[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_15[0]),
					.prio_out_0(int_prio_14[0]),
					.id_out_0(int_id_14[0])
					);
				wire [7:0]int_id_13[0:NHART-1];
				wire [10:0]int_prio_13[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(13))slice13(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[13]),
					.pending(pending[13]),
					.claimed(claimed&&r_claim==13),
					.freed(freed&&free==13),
					.ie(enabled[13]),
					.prio(r_priority_1[13>>1]),
					.prio_in_0(int_prio_14[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_14[0]),
					.prio_out_0(int_prio_13[0]),
					.id_out_0(int_id_13[0])
					);
				wire [7:0]int_id_12[0:NHART-1];
				wire [10:0]int_prio_12[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(12))slice12(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[12]),
					.pending(pending[12]),
					.claimed(claimed&&r_claim==12),
					.freed(freed&&free==12),
					.ie(enabled[12]),
					.prio(r_priority_0[12>>1]),
					.prio_in_0(int_prio_13[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_13[0]),
					.prio_out_0(int_prio_12[0]),
					.id_out_0(int_id_12[0])
					);
				wire [7:0]int_id_11[0:NHART-1];
				wire [10:0]int_prio_11[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(11))slice11(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[11]),
					.pending(pending[11]),
					.claimed(claimed&&r_claim==11),
					.freed(freed&&free==11),
					.ie(enabled[11]),
					.prio(r_priority_1[11>>1]),
					.prio_in_0(int_prio_12[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_12[0]),
					.prio_out_0(int_prio_11[0]),
					.id_out_0(int_id_11[0])
					);
				wire [7:0]int_id_10[0:NHART-1];
				wire [10:0]int_prio_10[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(10))slice10(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[10]),
					.pending(pending[10]),
					.claimed(claimed&&r_claim==10),
					.freed(freed&&free==10),
					.ie(enabled[10]),
					.prio(r_priority_0[10>>1]),
					.prio_in_0(int_prio_11[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_11[0]),
					.prio_out_0(int_prio_10[0]),
					.id_out_0(int_id_10[0])
					);
				wire [7:0]int_id_9[0:NHART-1];
				wire [10:0]int_prio_9[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(9))slice9(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[9]),
					.pending(pending[9]),
					.claimed(claimed&&r_claim==9),
					.freed(freed&&free==9),
					.ie(enabled[9]),
					.prio(r_priority_1[9>>1]),
					.prio_in_0(int_prio_10[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_10[0]),
					.prio_out_0(int_prio_9[0]),
					.id_out_0(int_id_9[0])
					);
				wire [7:0]int_id_8[0:NHART-1];
				wire [10:0]int_prio_8[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(8))slice8(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[8]),
					.pending(pending[8]),
					.claimed(claimed&&r_claim==8),
					.freed(freed&&free==8),
					.ie(enabled[8]),
					.prio(r_priority_0[8>>1]),
					.prio_in_0(int_prio_9[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_9[0]),
					.prio_out_0(int_prio_8[0]),
					.id_out_0(int_id_8[0])
					);
				wire [7:0]int_id_7[0:NHART-1];
				wire [10:0]int_prio_7[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(7))slice7(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[7]),
					.pending(pending[7]),
					.claimed(claimed&&r_claim==7),
					.freed(freed&&free==7),
					.ie(enabled[7]),
					.prio(r_priority_1[7>>1]),
					.prio_in_0(int_prio_8[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_8[0]),
					.prio_out_0(int_prio_7[0]),
					.id_out_0(int_id_7[0])
					);
				wire [7:0]int_id_6[0:NHART-1];
				wire [10:0]int_prio_6[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(6))slice6(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[6]),
					.pending(pending[6]),
					.claimed(claimed&&r_claim==6),
					.freed(freed&&free==6),
					.ie(enabled[6]),
					.prio(r_priority_0[6>>1]),
					.prio_in_0(int_prio_7[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_7[0]),
					.prio_out_0(int_prio_6[0]),
					.id_out_0(int_id_6[0])
					);
				wire [7:0]int_id_5[0:NHART-1];
				wire [10:0]int_prio_5[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(5))slice5(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[5]),
					.pending(pending[5]),
					.claimed(claimed&&r_claim==5),
					.freed(freed&&free==5),
					.ie(enabled[5]),
					.prio(r_priority_1[5>>1]),
					.prio_in_0(int_prio_6[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_6[0]),
					.prio_out_0(int_prio_5[0]),
					.id_out_0(int_id_5[0])
					);
				wire [7:0]int_id_4[0:NHART-1];
				wire [10:0]int_prio_4[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(4))slice4(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[4]),
					.pending(pending[4]),
					.claimed(claimed&&r_claim==4),
					.freed(freed&&free==4),
					.ie(enabled[4]),
					.prio(r_priority_0[4>>1]),
					.prio_in_0(int_prio_5[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_5[0]),
					.prio_out_0(int_prio_4[0]),
					.id_out_0(int_id_4[0])
					);
				wire [7:0]int_id_3[0:NHART-1];
				wire [10:0]int_prio_3[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(3))slice3(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[3]),
					.pending(pending[3]),
					.claimed(claimed&&r_claim==3),
					.freed(freed&&free==3),
					.ie(enabled[3]),
					.prio(r_priority_1[3>>1]),
					.prio_in_0(int_prio_4[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_4[0]),
					.prio_out_0(int_prio_3[0]),
					.id_out_0(int_id_3[0])
					);
				wire [7:0]int_id_2[0:NHART-1];
				wire [10:0]int_prio_2[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(2))slice2(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[2]),
					.pending(pending[2]),
					.claimed(claimed&&r_claim==2),
					.freed(freed&&free==2),
					.ie(enabled[2]),
					.prio(r_priority_0[2>>1]),
					.prio_in_0(int_prio_3[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_3[0]),
					.prio_out_0(int_prio_2[0]),
					.id_out_0(int_id_2[0])
					);
				wire [7:0]int_id_1[0:NHART-1];
				wire [10:0]int_prio_1[0:NHART-1];
				plic_slice	#(.NHART(NHART), .ID(1))slice1(
					.clk(clk),
					.reset(reset),
					.lock(lock),
					.irq(irq[1]),
					.pending(pending[1]),
					.claimed(claimed&&r_claim==1),
					.freed(freed&&free==1),
					.ie(enabled[1]),
					.prio(r_priority_1[1>>1]),
					.prio_in_0(int_prio_2[0]),	// FIXME scale for multiple harts
					.id_in_0(int_id_2[0]),
					.prio_out_0(int_prio_1[0]),
					.id_out_0(int_id_1[0])
					);
		//end
		for (H = 0; H < NHART; H=H+1) begin
			assign interrupt_pending[H] = int_prio_1[H] > r_threshold[H];
		end
	endgenerate

endmodule

module plic_slice(
		input		clk,
		input		reset,
		input		lock,
		input		irq,
		input		claimed,
		input		freed,
		output		pending,
		input [NHART-1:0]ie,
		input [10:0]prio,
		input	[10:0]prio_in_0,
		input  [7:0]id_in_0,

		output  [10:0]prio_out_0,
		output  [7:0]id_out_0
		);

	parameter ID=0;
	parameter NHART=1;

	reg r_claim;
	reg r_irq;
	assign pending = r_irq && !r_claim && prio != 0;
	always @(posedge clk) 
	if (reset||claimed) begin
		r_irq <= 0;
	end else
	if (!lock) begin	// lock is so we can build arbitrality large plics
		r_irq <= irq;
	end

	always @(posedge clk)
	if (reset || freed) begin
		r_claim <= 0;
	end else
	if (claimed) begin
		r_claim <= 1;
	end

	wire [7:0]id_out[0:NHART-1];
	wire [10:0]prio_out[0:NHART-1];
	wire [7:0]id_in[0:NHART-1];
	wire [10:0]prio_in[0:NHART-1];
	assign prio_out_0 = prio_out[0];	// FIXME scale for multiple harts
	assign id_out_0 = id_out[0];
	assign prio_in[0] = prio_in_0;
	assign id_in[0] = id_in_0;

	genvar H;
	generate

		for (H=0; H < NHART; H=H+1) begin
			wire win = ie[H] && pending  && prio >= prio_in[H];
			assign id_out[H]   = (win ? ID   : id_in[H]);
			assign prio_out[H] = (win ? prio : prio_in[H]);
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

