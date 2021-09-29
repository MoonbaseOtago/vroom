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
module clic(
    input clk,
    input reset,

    input              addr_req,
    output             addr_ack,
	input			   sel_m,
	input			   sel_s,
	input			   sel_u,
    input        [15:0]addr,
    input              read,
    input         [7:0]mask,
    input      [RV-1:0]wdata,

    output             data_req,
    input              data_ack,
    output     [RV-1:0]rdata,

	input				timer_interrupt,
	input				ip_interrupt,
	input		[3:0]interrupt,
	input		[3:0]plic_interrupt,

	input			clic_m_enable,
	input			clic_h_enable,
	input			clic_s_enable,
	input			clic_u_enable,
	output	   [7:0]clic_m_il,
	output	  [$clog2(NINTERRUPTS)-1:0]clic_m_int,
	output			clic_m_pending,
	output			clic_m_vec,
	output	   [7:0]clic_h_il,
	output	  [$clog2(NINTERRUPTS)-1:0]clic_h_int,
	output			clic_h_pending,
	output			clic_h_vec,
	output	   [7:0]clic_s_il,
	output	  [$clog2(NINTERRUPTS)-1:0]clic_s_int,
	output			clic_s_pending,
	output			clic_s_vec,
	output	   [7:0]clic_u_il,
	output	  [$clog2(NINTERRUPTS)-1:0]clic_u_int,
	output			clic_u_pending,
	output			clic_u_vec,
	input			clic_ack,
	input	  [$clog2(NINTERRUPTS)-1:0]clic_ack_int,

	output [NINTERRUPTS-1:0]io_interrupts
	);

	parameter RV=64;
	parameter CLICINTCTLBITS = 4'h5;
	parameter CLIC_VERSION = {4'b0, 4'h9};
	parameter NINTERRUPTS=20;

	assign addr_ack = addr_req&(sel_u|sel_s|sel_m);

	wire [NINTERRUPTS-1:0]int_in = {interrupt, 3'b000, 1'b0, plic_interrupt, timer_interrupt, timer_interrupt, timer_interrupt, timer_interrupt, ip_interrupt, ip_interrupt, ip_interrupt, ip_interrupt};
	assign io_interrupts = int_in;

	reg [RV-1:0]r;
	reg [RV-1:0]r_data;
	assign rdata = r_data;
	reg			r_dreq;
	assign data_req = r_dreq;

	reg	r_nvbits;
	reg	[3:0]r_nlbits;
	reg [1:0]r_nmbits;
	wire [31:0]cliccfg = {24'b0, 1'b0, r_nmbits, r_nlbits, r_nvbits};
	wire [12:0]num_interrupt=NINTERRUPTS;
	wire [31:0]clicinfo = {7'b0, CLICINTCTLBITS, CLIC_VERSION, num_interrupt};

	wire [NINTERRUPTS-1:0]mxm, mxs, mxu;

	reg [NINTERRUPTS-1:0]r_clicintip;
	reg [NINTERRUPTS-1:0]r_clicintie;
wire r_clicintie_1 = r_clicintie[1];
wire r_clicintie_3 = r_clicintie[3];

	reg [1:0]r_mode[0:NINTERRUPTS-1];
wire [1:0]r_mode_1=r_mode[1];
wire [1:0]r_mode_3=r_mode[3];
	reg [1:0]r_trig[0:NINTERRUPTS-1];
	reg [NINTERRUPTS-1:0]r_shv;

	reg [CLICINTCTLBITS-1:0]r_clicintctl[0:NINTERRUPTS-1];
wire [4:0]r_clicintctl_1=r_clicintctl[1];


	wire [31:0]reg_data[0:NINTERRUPTS-1];

	always @(posedge clk)
	if (reset) begin
		r_nvbits <= 0;
		r_nlbits <= 0;
		r_nmbits <= 0;
	end else
	if (sel_m && !read && addr[14:(RV==64?3:2)] == 0 && mask[0]) begin
		r_nvbits <= wdata[0];
		r_nlbits <= wdata[4:1] > CLICINTCTLBITS ? r_nlbits:wdata[4:1];
		r_nmbits <= wdata[6:5];
	end
	reg [CLICINTCTLBITS-1:0]prio_mask;
	always @(*) begin
		case (r_nlbits) // synthesis full_case parallel_case
		0: prio_mask = 5'b11111;
		1: prio_mask = 5'b01111;
		2: prio_mask = 5'b00111;
		3: prio_mask = 5'b00011;
		4: prio_mask = 5'b00001;
		5: prio_mask = 5'b00000;
		endcase
	end

	reg [1:0]this_mode;

	always @(*) begin
		casez ({sel_m, sel_s, sel_u})	// synthesis full_case parallel_case
		3'b??1: this_mode = 0;
		3'b?1?: this_mode = 1;
		3'b1??: this_mode = 3;
		3'b000: this_mode = 0;
		endcase
	end

	genvar I, J;

	generate
		for (I = 0; I < NINTERRUPTS; I=I+1) begin : i
			wire triggered, triggervalue;
			wire [3:0]this_mask;
			wire this_addr;
			wire write_valid;
			wire cleared;
			if (I == 2 || I == 6 || I == 10 || I >= 13 && I < 15) begin
				assign reg_data[I] = 0;
				assign triggered = 0;
				assign write_valid = 0;
				assign cleared = 0;
				assign triggervalue = 0;
			end else begin :n

				reg this_valid, tr, tv;
				reg r_prev;

				always @(*) begin
					casez ({sel_m, sel_s, sel_u})	// synthesis full_case parallel_case
					3'b??1: this_valid = r_nmbits == 2 && r_mode[I] == 0;
					3'b?1?: this_valid = r_nmbits != 0 && r_mode[I][1] == 0;
					3'b1??: this_valid = 1;
					3'b000: this_valid = 0;
					endcase
				end

				assign reg_data[I] = !this_valid?32'b0:{r_clicintctl[I], {8-CLICINTCTLBITS{1'b1}}, r_mode[I], 3'b0, r_trig[I], r_shv[I], 7'b0, r_clicintie[I], 7'b0, r_clicintip[I]};
	
				always @(posedge clk)
					r_prev <= int_in[I];

				always @(*) begin
					case (r_trig[I])
					2'b00:	tr = 1;							// positive level-triggered
					2'b01:	tr = 1;							// negative level-triggered
					2'b10:	tr = int_in[I]&!r_prev;			// positive edge-triggered
					2'b11:	tr = !int_in[I]&r_prev;			// negative edge-triggered
					endcase
					case (r_trig[I])
					2'b00:	tv = int_in[I];					// positive level-triggered
					2'b01:	tv = ~int_in[I];				// negative level-triggered
					2'b10:	tv = 1;							// positive edge-triggered
					2'b11:	tv = 1;							// negative edge-triggered
					endcase
				end

				assign cleared = clic_ack&&(clic_ack_int==I);
				assign triggered = tr;
				assign triggervalue = tv;
				assign write_valid = this_addr && addr_req && !read && this_valid;
			end

	 		if (RV == 64) begin
				assign this_addr = addr[15:12]==4'b0001 && (addr[11:3] == (I>>1));
				if (I == 2 || I == 6 || I == 10 || I >= 13 && I < 15) begin
					always @(posedge clk) begin
						r_clicintip[I] <= 0;
						r_clicintie[I] <= 0; 
						r_mode[I] <= 0;
						r_shv[I] <= 0;
						r_trig[I] <= 0;
						r_clicintctl[I] <= 0;
					end
				end else
				if ((I&1)!=0) begin
					assign this_mask = mask[7:4];

					always @(posedge clk)
					if (reset) begin
						r_clicintip[I] <= 0;
					end else
					if (write_valid) begin
						if (this_mask[0])
							r_clicintip[I] <= wdata[32];
					end else
					if (triggered) begin
						r_clicintip[I] <= triggervalue;
					end else
					if (cleared) begin
						r_clicintip[I] <= 0;
					end
					
					always @(posedge clk)
					if (reset) begin
						r_clicintie[I] <= 0; 
						r_mode[I] <= 0;
						r_shv[I] <= 0;
						r_trig[I] <= 0;
						r_clicintctl[I] <= 0;
					end else
					if (write_valid) begin
						if (this_mask[1])
							r_clicintie[I] <= wdata[40];
						if (this_mask[2]) begin
							r_shv[I] <= wdata[48];
							r_trig[I] <= wdata[50:49];
							if (wdata[55:54] <= this_mode)
								r_mode[I] <= wdata[55:54];
						end
						if (this_mask[3])
							r_clicintctl[I] <= wdata[63:63-CLICINTCTLBITS+1];
					end
				end else begin
					assign this_mask = mask[3:0];

					always @(posedge clk)
					if (reset) begin
						r_clicintip[I] <= 0;
					end else
					if (write_valid) begin
						if (this_mask[0])
							r_clicintip[I] <= wdata[0];
					end else
					if (triggered) begin
						r_clicintip[I] <= 1;
					end else
					if (cleared) begin
						r_clicintip[I] <= 0;
					end
					
					always @(posedge clk)
					if (reset) begin
						r_clicintie[I] <= 0; 
						r_mode[I] <= 0;
						r_shv[I] <= 0;
						r_trig[I] <= 0;
						r_clicintctl[I] <= 0;
					end else 
					if (write_valid) begin
						if (this_mask[1])
							r_clicintie[I] <= wdata[8];
						if (this_mask[2]) begin
							r_shv[I] <= wdata[16];
							r_trig[I] <= wdata[18:17];
							if (wdata[23:22] <= this_mode)
								r_mode[I] <= wdata[23:22];
						end
						if (this_mask[3])
							r_clicintctl[I] <= wdata[31:31-CLICINTCTLBITS+1];
					end
				end
			end else begin
				assign this_mask = mask;
				assign this_addr = addr[15:12]==4'b0001 && addr[11:2] == I;

				always @(posedge clk)
				if (reset) begin
					r_clicintip[I] <= 0;
				end else
				if (write_valid) begin
					if (this_mask[0])
						r_clicintip[I] <= wdata[0];
				end else
				if (triggered) begin
					r_clicintip[I] <= 1;
				end else
				if (cleared) begin
					r_clicintip[I] <= 0;
				end
					
				always @(posedge clk)
				if (reset) begin
					r_clicintie[I] <= 0; 
					r_mode[I] <= 0;
					r_shv[I] <= 0;
					r_trig[I] <= 0;
					r_clicintctl[I] <= 0;
				end else 
				if (write_valid) begin
					if (this_mask[1])
						r_clicintie[I] <= wdata[8];
					if (this_mask[2]) begin
						r_shv[I] <= wdata[16];
						r_trig[I] <= wdata[18:17];
						r_mode[I] <= wdata[23:22];
					end
					if (this_mask[3])
						r_clicintctl[I] <= wdata[31:31-CLICINTCTLBITS+1];
				end
			end


			if (I == 2 || I == 6 || I == 10 || I >= 13 && I < 15) begin
				assign mxu[I] = 0;
				assign mxs[I] = 0;
				assign mxm[I] = 0;
			end else begin :m
				wire [NINTERRUPTS-1:0]mm, ms, mu;
	
				for (J = 0; J < NINTERRUPTS; J=J+1)
				if (J == 2 || J == 6 || J == 10 || (J >= 13 && J < 15)) begin
					assign mu[J] = 1;
					assign ms[J] = 1;
					assign mm[J] = 1;
				end else
				if (J == I) begin
					assign mm[J] = (r_mode[I]==3)&r_clicintip[I]&r_clicintie[I];
					assign ms[J] = (r_mode[I]==1)&r_clicintip[I]&r_clicintie[I];
					assign mu[J] = (r_mode[I]==0)&r_clicintip[I]&r_clicintie[I];
				end else begin
					assign mm[J] = !(r_clicintip[J]&r_clicintie[J]) || (r_clicintctl[J] <= r_clicintctl[I]) || r_mode[J] != 3;
					assign ms[J] = !(r_clicintip[J]&r_clicintie[J]) || (r_clicintctl[J] <= r_clicintctl[I]) || r_mode[J] != 1;
					assign mu[J] = !(r_clicintip[J]&r_clicintie[J]) || (r_clicintctl[J] <= r_clicintctl[I]) || r_mode[J] != 0;
				end
				assign mxu[I] = &mu;
				assign mxs[I] = &ms;
				assign mxm[I] = &mm;
			end
		end

		if (RV == 64) begin
			always @(*) begin
				if (addr[14:3] == 0) begin
					r = {clicinfo, cliccfg};
				end else
				if (addr[14:3] >= 15'h200 && addr[14:3] < (15'h200 + NINTERRUPTS/2)) begin
					r = {reg_data[({addr[14:4], 1'b0}-15'h200)|1], reg_data[{addr[14:4], 1'b0}-15'h200]};
				end else begin
					r = 0;
				end
			end
		end else begin
			always @(*) begin
				if (addr[14:3] == 0) begin
					r = cliccfg;
				end else
				if (addr[14:3] == 1) begin
					r = clicinfo;
				end else
				if (addr[14:3] >= 15'h200 && addr[14:3] < (15'h200 + NINTERRUPTS/2)) begin
					r = reg_data[addr[14:3]-15'h200];
				end else begin
					r = 0;
				end
			end
		end

	endgenerate

	
	reg [$clog2(NINTERRUPTS)-1:0]intr_m, intr_s, intr_u;
	wire intr_active_m = |mxm;
	wire intr_active_s = |mxs;
	wire intr_active_u = |mxu;
	assign clic_m_pending = intr_active_m;
	assign clic_h_pending = 0;
	assign clic_s_pending = intr_active_s;
	assign clic_u_pending = intr_active_u;
	assign clic_m_int = intr_m;
	assign clic_h_int = 0;
	assign clic_s_int = intr_s;
	assign clic_u_int = intr_u;

	always @(*) begin
		casez (mxm)	// synthesis full_case parallel_case
		20'b0000_???0_0?00_0?00_0?01: intr_m = 0;			// usip
		20'b0000_???0_0?00_0?00_0?1?: intr_m = 1;			// ssip
		20'b0000_???0_0?00_0?00_1???: intr_m = 3;			// msip
		20'b0000_???0_0?00_0?01_????: intr_m = 4;			// utip
		20'b0000_???0_0?00_0?1?_????: intr_m = 5;			// stip
		20'b0000_???0_0?00_1???_????: intr_m = 7;			// mtip
		20'b0000_???0_0?01_????_????: intr_m = 8;			// ueip
		20'b0000_???0_0?1?_????_????: intr_m = 9;			// seip
		20'b0000_???0_1???_????_????: intr_m = 11;			// meip
		20'b0000_???1_????_????_????: intr_m = 12;			// csip
		20'b0001_????_????_????_????: intr_m = 16;			// int16
		20'b001?_????_????_????_????: intr_m = 17;			// int17
		20'b01??_????_????_????_????: intr_m = 18;			// int18
		20'b1???_????_????_????_????: intr_m = 19;			// int19
		endcase
	end

	always @(*) begin
		casez (mxs)	// synthesis full_case parallel_case
		20'b0000_???0_0?00_0?00_0?01: intr_s = 0;			// usip
		20'b0000_???0_0?00_0?00_0?1?: intr_s = 1;			// ssip
		20'b0000_???0_0?00_0?00_1???: intr_s = 3;			// msip
		20'b0000_???0_0?00_0?01_????: intr_s = 4;			// utip
		20'b0000_???0_0?00_0?1?_????: intr_s = 5;			// stip
		20'b0000_???0_0?00_1???_????: intr_s = 7;			// mtip
		20'b0000_???0_0?01_????_????: intr_s = 8;			// ueip
		20'b0000_???0_0?1?_????_????: intr_s = 9;			// seip
		20'b0000_???0_1???_????_????: intr_s = 11;			// meip
		20'b0000_???1_????_????_????: intr_s = 12;			// csip
		20'b0001_????_????_????_????: intr_s = 16;			// int16
		20'b001?_????_????_????_????: intr_s = 17;			// int17
		20'b01??_????_????_????_????: intr_s = 18;			// int18
		20'b1???_????_????_????_????: intr_s = 19;			// int19
		endcase
	end

	always @(*) begin
		casez (mxu)	// synthesis full_case parallel_case
		20'b0000_???0_0?00_0?00_0?01: intr_u = 0;			// usip
		20'b0000_???0_0?00_0?00_0?1?: intr_u = 1;			// ssip
		20'b0000_???0_0?00_0?00_1???: intr_u = 3;			// msip
		20'b0000_???0_0?00_0?01_????: intr_u = 4;			// utip
		20'b0000_???0_0?00_0?1?_????: intr_u = 5;			// stip
		20'b0000_???0_0?00_1???_????: intr_u = 7;			// mtip
		20'b0000_???0_0?01_????_????: intr_u = 8;			// ueip
		20'b0000_???0_0?1?_????_????: intr_u = 9;			// seip
		20'b0000_???0_1???_????_????: intr_u = 11;			// meip
		20'b0000_???1_????_????_????: intr_u = 12;			// csip
		20'b0001_????_????_????_????: intr_u = 16;			// int16
		20'b001?_????_????_????_????: intr_u = 17;			// int17
		20'b01??_????_????_????_????: intr_u = 18;			// int18
		20'b1???_????_????_????_????: intr_u = 19;			// int19
		endcase
	end

	assign clic_m_vec = r_nvbits&&r_shv[intr_m];
	assign clic_h_vec = 0;
	assign clic_s_vec = r_nvbits&&r_shv[intr_s];
	assign clic_u_vec = r_nvbits&&r_shv[intr_u];

	assign clic_m_il = {r_clicintctl[intr_m]|prio_mask, {8-CLICINTCTLBITS{1'b1}}};
	assign clic_h_il = 0;
	assign clic_s_il = {r_clicintctl[intr_s]|prio_mask, {8-CLICINTCTLBITS{1'b1}}};
	assign clic_u_il = {r_clicintctl[intr_u]|prio_mask, {8-CLICINTCTLBITS{1'b1}}};

	always @(posedge clk) begin
		if (addr_req && (sel_m|sel_s|sel_u) && read)
			r_data <= r;
		if (reset || data_ack) begin
			r_dreq <= 0;
		end else
		if (addr_req && (sel_m|sel_s|sel_u) && read) begin
			r_dreq <= 1;
		end
	end

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
