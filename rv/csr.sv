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


`include "lstypes.si"

module csr(input clk, input reset, 
`ifdef SIMD
		input simd_enable,
		input simd_trace_enable,
`endif
`ifdef AWS_DEBUG
        input       xxtrig,
		output		csr_trig,
`endif
        input [CNTRL_SIZE-1:0]control,
		input		enable,
        input [LNCOMMIT-1:0]rd,
        input       makes_rd,
        input [VA_SZ-1:1]pc,
        input [RV-1:0]r1,
        input [31:0]immed,
		input [LNCOMMIT-1:0]num_retired,
		input [3:0]num_branches_retired,
		input [3:0]num_branches_predicted,
		input [3:0]count_out_rename,

`ifdef FP
		input		update_fp_state,
		input  [4:0]fp_exceptions,
		input		fp_written,
		output [2:0]fp_rounding,
		output		fp_off,
`endif
		
                
        output [RV-1:0]result,    
        output [LNCOMMIT-1:0]res_rd, 
        output         res_makes_rd ,
		output	 [3: 0]cpu_mode,
		output	 [5:0]timer_prot,

		output     [43:0]sup_ppn,
		output      [3:0]sup_vm_mode,
		output     [15:0]sup_asid,
		output			 unified_asid,
`ifdef TRACE_CACHE
		output			 trace_enable,
		output	    [3:0]trace_scale,
`endif
		output			sup_vm_sum,
		output			mxr,
		output	        trap_br_enable,
		output	        int_br_enable,
		output	        int_force_fetch,
		output	        interrupt_pending,
		output	 [LNCOMMIT-1:0]trap_br_addr,
		output	 [RV-1:1]trap_br,
		output			rv32,
		output			tvm,
		output	   [3:0]mprv,
		output			tsr,
		output			hyper,
		output			v,
		input     [31:0]trap_ins,
		input      [7:0]cpu_id,
		output			orand,
		output			reset_out,
		output	  [31:0]u_debug,

		input			csr_wfi_pause,
		output			csr_wfi_wake,

		PMP			pmp,
		output [NUM_PMP-1:0]pmp_valid,		// sadly arrays of buses aren't well supported 
		output [NUM_PMP-1:0]pmp_locked,		// so we need to get verbose - unused wires will be optimised
		output [NPHYS-1:2]pmp_start_0,		// out during synthesis
		output [NPHYS-1:2]pmp_start_1,
		output [NPHYS-1:2]pmp_start_2,
		output [NPHYS-1:2]pmp_start_3,
		output [NPHYS-1:2]pmp_start_4,
		output [NPHYS-1:2]pmp_start_5,
		output [NPHYS-1:2]pmp_start_6,
		output [NPHYS-1:2]pmp_start_7,
		output [NPHYS-1:2]pmp_start_8,
		output [NPHYS-1:2]pmp_start_9,
		output [NPHYS-1:2]pmp_start_10,
		output [NPHYS-1:2]pmp_start_11,
		output [NPHYS-1:2]pmp_start_12,
		output [NPHYS-1:2]pmp_start_13,
		output [NPHYS-1:2]pmp_start_14,
		output [NPHYS-1:2]pmp_start_15,
		output [NPHYS-1:2]pmp_end_0,
		output [NPHYS-1:2]pmp_end_1,
		output [NPHYS-1:2]pmp_end_2,
		output [NPHYS-1:2]pmp_end_3,
		output [NPHYS-1:2]pmp_end_4,
		output [NPHYS-1:2]pmp_end_5,
		output [NPHYS-1:2]pmp_end_6,
		output [NPHYS-1:2]pmp_end_7,
		output [NPHYS-1:2]pmp_end_8,
		output [NPHYS-1:2]pmp_end_9,
		output [NPHYS-1:2]pmp_end_10,
		output [NPHYS-1:2]pmp_end_11,
		output [NPHYS-1:2]pmp_end_12,
		output [NPHYS-1:2]pmp_end_13,
		output [NPHYS-1:2]pmp_end_14,
		output [NPHYS-1:2]pmp_end_15,
		output	[2:0]pmp_prot_0,
		output	[2:0]pmp_prot_1,
		output	[2:0]pmp_prot_2,
		output	[2:0]pmp_prot_3,
		output	[2:0]pmp_prot_4,
		output	[2:0]pmp_prot_5,
		output	[2:0]pmp_prot_6,
		output	[2:0]pmp_prot_7,
		output	[2:0]pmp_prot_8,
		output	[2:0]pmp_prot_9,
		output	[2:0]pmp_prot_10,
		output	[2:0]pmp_prot_11,
		output	[2:0]pmp_prot_12,
		output	[2:0]pmp_prot_13,
		output	[2:0]pmp_prot_14,
		output	[2:0]pmp_prot_15,

		output			clic_m_enable,
		output			clic_h_enable,
		output			clic_s_enable,
		output			clic_u_enable,
		input	   [7:0]clic_m_il,
		input[$clog2(NINTERRUPTS)-1:0]clic_m_int,
		input			clic_m_pending,
		input			clic_m_vec,
		input	   [7:0]clic_h_il,
		input[$clog2(NINTERRUPTS)-1:0]clic_h_int,
		input			clic_h_pending,
		input			clic_h_vec,
		input	   [7:0]clic_s_il,
		input[$clog2(NINTERRUPTS)-1:0]clic_s_int,
		input			clic_s_pending,
		input			clic_s_vec,
		input	   [7:0]clic_u_il,
		input[$clog2(NINTERRUPTS)-1:0]clic_u_int,
		input			clic_u_pending,
		input			clic_u_vec,
		output			clic_ack,
		output[$clog2(NINTERRUPTS)-1:0]clic_ack_int,
		input	  [63:0]io_timer,
		input [NINTERRUPTS-1:0]io_interrupts
        );      
	parameter VA_SZ=48;
	parameter RV=64;
    parameter CNTRL_SIZE=7;
    parameter HART=0;
    parameter NHART=1;
    parameter LNHART=0;
    parameter NPHYS=56;
	parameter NINTERRUPTS=20;
	parameter NUM_TRANSFER_PORTS=0;
    parameter NCOMMIT = 32; // number of commit registers
    parameter LNCOMMIT = 5; // number of bits to encode that
    parameter RA=5;

	parameter M_CLIC_BASE  =     64'hffffffffff100000;
	parameter VS_CLIC_BASE = M_CLIC_BASE + 64'h100000;
	parameter S_CLIC_BASE  = M_CLIC_BASE + 64'h200000;
	parameter U_CLIC_BASE  = M_CLIC_BASE + 64'h300000;

	parameter NUM_PMP = 5;

	wire [(NHART==1?0:LNHART-1):0]hart = HART;

`ifdef B
	wire b = 1;
`else
	wire b = 0;
`endif

    //      
    //      control:
	//
	//		ctrl[5 4 3]
	//	         0 0 x	illegal ins/align/call/break
	//			 0 1 x	interrupt
	//			 1 0 x  csr read/write
	//			 1 1 x	iret
	//			
	//		for csr read/write
    //      3 - write
    //      2:1 - type 0 read/write 1 read/set 2 read/clear
    //      0 - immed
	//
	//		for iret
	//			2	- 0		iret
    //			0	1:0 - 0=u, 1=s, 3=m
	//
	//			2:0	- 100	pipe-break
	//			2:0	- 101	wfi
	//
	//		for illegal ins/align/call/break - synchronous traps from the instruction stream
	//		3:0
	//			0: alignment
	//			1: instruction access fault
	//			2: illegal instruction
	//			3: breakpoint
	//			4: load addresss misaligned
	//			5: load access fault
	//			6: store/AMO misaligned
	//			7: stote/AMO access fault
	//			8: env call U
	//			9: env call S
	//			11: env call M
	//			12: instruction PF
	//			13: load PF
	//			15: store/AMO PF
	//			
	//		if interrupt pending
	//		  3:0
	//			0 is start interrupt
	//			1 is vector fetch done
	//

	wire	   csr_write = r_enable && r_control[5:3] == 3'b101;
	wire	   xiret = r_enable && r_control[5:4] == 2'b11;
	reg		   iret;
	wire	   xtrap = r_enable && r_control[5:4] == 2'b00;
	reg		   trap;
	wire	   interrupt = r_enable && r_control[5:4] == 2'b01;

	wire [15:0]m_trap_deleg, h_trap_deleg, s_trap_deleg;
	wire [RV-1:0]mem_addr = r1 + {{(RV-32){r_immed[31]}},r_immed};
	wire [RV-1:0]in = (r_control[0]?{{RV-5{1'b0}},r_immed[16:12]}:r1);

	wire trap_m = trap && (cpu_mode[3]||!m_trap_deleg[r_control[3:0]]);
	wire trap_vs = trap && v && m_trap_deleg[r_control[3:0]] && (cpu_mode[1]||!s_trap_deleg[r_control[3:0]]);	// FIXME vm
	wire trap_s = trap && !v && m_trap_deleg[r_control[3:0]] && (cpu_mode[1]||!s_trap_deleg[r_control[3:0]]);
	wire trap_u = trap && m_trap_deleg[r_control[3:0]] && s_trap_deleg[r_control[3:0]] && cpu_mode[0];

	wire null_write = r_control[0] && r_control[1] &&r_immed[16:12]==0;

	reg	   [LNCOMMIT-1:0]r_rd, r_res_rd;
	reg [31:0]r_immed;
	reg [CNTRL_SIZE-1:0]r_control;
	reg		   r_enable;
	reg  [RV-1:0]r_res, c_res;
	reg			r_res_makes_rd, r_makes_rd;
	
	assign result = r_res;
	assign res_rd = r_rd;
	assign res_makes_rd = r_res_makes_rd;
	reg	 [RV-1:1]r_next_pc, c_next_pc;
	reg	 [VA_SZ-1:1]r_pc;
	reg	 [RV-1:1]r_r1;
	always @(posedge clk)
		r_r1 <= r1;

	reg			r_trap_br_enable, c_trap_br_enable;
	reg			r_int_br_enable, c_int_br_enable;
	reg			r_int_force_fetch, c_int_force_fetch;
	reg			fast_int_m, fast_int_s, fast_int_vs, fast_int_u;

	always @(posedge clk) begin
		r_trap_br_enable <= c_trap_br_enable;
		r_int_br_enable <= c_int_br_enable;
		r_int_force_fetch <= c_int_force_fetch;
		if (enable) begin
			r_control <= control;
			r_immed <= immed;
			r_rd <= rd;
			r_makes_rd <= makes_rd;
			r_pc <= pc;
		end
		r_enable <= enable;
		r_res_rd <= r_rd;
		r_res_makes_rd <= (r_makes_rd|fast_int_m|fast_int_vs|fast_int_s|fast_int_u)&r_enable;
		r_res <= c_res;
		r_next_pc <= c_next_pc;
	end
	

	reg  [3:0]r_cpu_mode, c_cpu_mode;	// 0 user, 1 sup, 3 machine  = encoded one-hot
	assign cpu_mode = r_cpu_mode;

	reg		  r_hs;			// enable hypervisor mode
	reg		  r_v, c_v;		// virtualisation
	assign	  v = r_v;


	assign trap_br_enable = r_trap_br_enable;	
	assign int_br_enable = r_int_br_enable;	
	assign int_force_fetch = r_int_force_fetch;	
	assign trap_br = r_next_pc;
	assign trap_br_addr = r_res_rd;

	reg [RV-1:0]tval;		// trap mtval

	wire m_pending = r_m_ie&int_m_pending;
	wire h_pending = r_vs_ie&int_h_pending;	// FIXME
	wire s_pending = r_s_ie&int_s_pending && !(r_m_ie&int_m_pending) && (cpu_mode[1:0] != 0);
	wire u_pending = r_u_ie&int_u_pending && !(r_s_ie&int_s_pending || r_m_ie&int_m_pending) && (cpu_mode[0]);
		
	reg							 reg_clic_ack;
	reg [$clog2(NINTERRUPTS)-1:0]reg_clic_ack_int;
	reg							 int_clic_ack;
	reg							 int_clic_ack_save;
	reg [$clog2(NINTERRUPTS)-1:0]int_clic_ack_int;
	reg							 r_clic_ack;
	reg [$clog2(NINTERRUPTS)-1:0]r_clic_ack_int;
	assign		clic_ack = r_clic_ack;
	assign		clic_ack_int = r_clic_ack_int;
	always @(posedge clk)
	if (reset) begin
		r_clic_ack <= 0;
	end else begin
		r_clic_ack <= reg_clic_ack|int_clic_ack;
		if (reg_clic_ack|int_clic_ack_save)
			r_clic_ack_int <= int_clic_ack_save?int_clic_ack_int:reg_clic_ack_int;
	end

	wire	wfi_timeout;
	reg		wfi_trap;

	always @(*) begin
		c_next_pc = 63'bx;
		fast_int_m = 0;
		fast_int_vs = 0;
		fast_int_s = 0;
		fast_int_u = 0;
		c_trap_br_enable = 0;
		c_int_br_enable = 0;
		c_int_force_fetch = 0;
		c_cpu_mode = r_cpu_mode;
		c_v = r_v;
		tval = 0;
		int_clic_ack = 0;
		int_clic_ack_save = 0;
		int_clic_ack_int = 12'bx;
		trap = 0;
		iret = 0;
		wfi_trap = 0;
		casez ({reset, xiret, r_control[3], xtrap, interrupt, csr_write&~null_write}) //synthesis full_case parallel_case
		6'b1_??_?_?_?:
			begin
				c_trap_br_enable = 0;
				c_cpu_mode = 4'b1000;
				c_v = 0;
			end
		6'b0_10_?_?_?:	//	iret
			begin
				iret = 1;
				case (r_control[1:0]) // synthesis full_case parallel_case
				0:	begin
						if (r_u_pie&int_u_pending) begin
							if (clic_u_enable) begin
								int_clic_ack_save = 1;
								int_clic_ack_int = clic_u_int;
								if (clic_u_vec) begin
									c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
									c_int_force_fetch = 1;
								end else begin
									c_next_pc = {r_u_trap_base[RV-1:6], 4'b0000, 1'b0};
									c_int_br_enable = 1;
									int_clic_ack = 1;
								end
							end else begin
								if (r_u_trap_type[0]) begin
									c_next_pc = {r_u_trap_base, 1'b0}+{uvec, 1'b0};
									c_int_br_enable = 1;
								end else begin
									c_next_pc = {r_u_trap_base, 1'b0};
									c_int_br_enable = 1;
								end
							end
							c_cpu_mode = 4'b0001;
							fast_int_u = 1;
						end else begin
							c_next_pc = r_u_epc;
							c_cpu_mode = 4'b0001;
						end
					end
				1:	begin
						casez ({r_s_pp == 1'b1 && r_s_pie&int_s_pending, r_s_pp == 1'b0 && r_u_ie&int_u_pending}) 
						2'b1?:
							begin
								if (clic_s_enable) begin
									int_clic_ack_save = 1;
									int_clic_ack_int = clic_s_int;
									if (clic_s_vec) begin
										c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
										c_int_force_fetch = 1;
									end else begin
										c_next_pc = {r_s_trap_base[RV-1:6], 4'b0000, 1'b0};
										c_int_br_enable = 1;
										int_clic_ack = 1;
									end
								end else begin
									if (r_s_trap_type[0]) begin
										c_next_pc = {r_s_trap_base, 1'b0}+{svec, 1'b0};
										c_int_br_enable = 1;
									end else begin
										c_next_pc = {r_s_trap_base, 1'b0};
										c_int_br_enable = 1;
									end
								end
								c_cpu_mode = 4'b0010;
								fast_int_s = 1;
							end
						2'b01:
							begin
								if (clic_u_enable) begin
									int_clic_ack_save = 1;
									int_clic_ack_int = clic_u_int;
									if (clic_u_vec) begin
										c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
										c_int_force_fetch = 1;
									end else begin
										c_next_pc = {r_u_trap_base[RV-1:6], 4'b0000, 1'b0};
										c_int_br_enable = 1;
										int_clic_ack = 1;
									end
								end else begin
									if (r_u_trap_type[0]) begin
										c_next_pc = {r_u_trap_base, 1'b0}+{uvec, 1'b0};
										c_int_br_enable = 1;
									end else begin
										c_next_pc = {r_u_trap_base, 1'b0};
										c_int_br_enable = 1;
									end
								end
								c_cpu_mode = 4'b0001;
								fast_int_u = 1;
							end
						2'b00:
							begin
								c_next_pc = (r_v?r_vs_epc:r_s_epc);
								c_cpu_mode = {2'b00, r_s_pp, ~r_s_pp};
							end
						endcase
					end
				3:	begin
						casez ({r_m_pp[1:0] == 2'h3 && r_m_pie&int_m_pending, r_m_pp[1:0] == 2'h1 && r_s_ie&int_s_pending, r_m_pp[1:0] == 2'h0 && r_u_ie&int_u_pending}) 
						3'b1??:
							begin
								if (clic_m_enable) begin
									int_clic_ack_save = 1;
									int_clic_ack_int = clic_m_int;
									if (clic_m_vec) begin
										c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
										c_int_force_fetch = 1;
									end else begin
										c_next_pc = {r_m_trap_base[RV-1:6], 4'b0000, 1'b0};
										c_int_br_enable = 1;
										int_clic_ack = 1;
									end
								end else begin
									if (r_m_trap_type[0]) begin
										c_next_pc = {r_m_trap_base, 1'b0}+{mvec, 1'b0};
										c_int_br_enable = 1;
									end else begin
										c_next_pc = {r_m_trap_base, 1'b0};
										c_int_br_enable = 1;
									end
								end
								c_cpu_mode = 4'b1000;
								fast_int_m = 1;
							end
						3'b01?:
							begin
								if (clic_s_enable) begin
									int_clic_ack_save = 1;
									int_clic_ack_int = clic_s_int;
									if (clic_s_vec) begin
										c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
										c_int_force_fetch = 1;
									end else begin
										c_next_pc = {r_s_trap_base[RV-1:6], 4'b0000, 1'b0};
										c_int_br_enable = 1;
										int_clic_ack = 1;
									end
								end else begin
									if (r_s_trap_type[0]) begin
										c_next_pc = {r_s_trap_base, 1'b0}+{svec, 1'b0};
										c_int_br_enable = 1;
									end else begin
										c_next_pc = {r_s_trap_base, 1'b0};
										c_int_br_enable = 1;
									end
								end
								c_cpu_mode = 4'b0010;
								fast_int_s = 1;
							end
						3'b001:
							begin
								if (clic_u_enable) begin
									int_clic_ack_save = 1;
									int_clic_ack_int = clic_u_int;
									if (clic_u_vec) begin
										c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
										c_int_force_fetch = 1;
									end else begin
										c_next_pc = {r_u_trap_base[RV-1:6], 4'b0000, 1'b0};
										c_int_br_enable = 1;
										int_clic_ack = 1;
									end
								end else begin
									if (r_u_trap_type[0]) begin
										c_next_pc = {r_u_trap_base, 1'b0}+{uvec, 1'b0};
										c_int_br_enable = 1;
									end else begin
										c_next_pc = {r_u_trap_base, 1'b0};
										c_int_br_enable = 1;
									end
								end
								c_cpu_mode = 4'b0001;
								fast_int_u = 1;
							end
						3'b000:
							begin
								c_next_pc = r_m_epc;
								c_cpu_mode = {r_m_pp[1], 1'b0, ~r_m_pp[1]&r_m_pp[0], ~r_m_pp[1]&~r_m_pp[0]};
								c_v = (r_m_pp!=3?r_mpv:0);
							end
						endcase
					end
				endcase
				c_trap_br_enable = 1;
			end
		6'b0_11_?_?_?:	//	pipe break
			begin
				case (r_control[1:0]) // synthesis full_case parallel_case
				0:	begin	// pipe break
						c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}+2;
						c_trap_br_enable = 1;
					end
				1:	begin	// wfi
						if (int_m_pending|int_s_pending|int_u_pending) begin	// pipe_flush
							c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}+2;
							c_trap_br_enable = 1;
						end else
						if (cpu_mode[1:0] != 0 && wfi_timeout) begin
							c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_illegal_inst?4'b1000:(r_cpu_mode[1]||!r_s_deleg_illegal_inst?4'b0010:4'b0001);
							c_v = !r_m_deleg_illegal_inst&r_v&r_h_deleg_illegal_inst;
							tval = 32'h10500073;
							casez ({c_v, c_cpu_mode}) // synthesis full_case parallel_case
							5'b?_1???: c_next_pc = {r_m_trap_base, 1'b0};
							5'b0_??1?: c_next_pc = {r_s_trap_base, 1'b0};
							5'b1_??1?: c_next_pc = {r_vs_trap_base, 1'b0};
							5'b?_???1: c_next_pc = {r_u_trap_base, 1'b0};
							default:   c_next_pc = 63'bx;
							endcase
							c_trap_br_enable = 1;
							trap = 1;
							wfi_trap = 1;
						end
					end
				endcase
			end
		6'b0_??_1_?_?:	// trap
			begin
				trap = 1;
				case (r_control[3:0]) // synthesis full_case parallel_case
				0:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_inst_align?4'b1000:(r_cpu_mode[1]||!r_s_deleg_inst_align?4'b0010:4'b0001);
						c_v = !r_m_deleg_inst_align&r_v&r_h_deleg_inst_align;
						tval = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc, 1'b0};
					end
				1:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_inst_access?4'b1000:(r_cpu_mode[1]||!r_s_deleg_inst_access?4'b0010:4'b0001);
						c_v = !r_m_deleg_inst_access&r_v&r_h_deleg_inst_access;
						tval = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc, 1'b0};
					end
				2:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_illegal_inst?4'b1000:(r_cpu_mode[1]||!r_s_deleg_illegal_inst?4'b0010:4'b0001);
						c_v = !r_m_deleg_illegal_inst&r_v&r_h_deleg_illegal_inst;
						tval = trap_ins;	
					end
				3:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_break?4'b1000:(r_cpu_mode[1]||!r_s_deleg_break?4'b0010:4'b0001);
						c_v = !r_m_deleg_break&r_v&r_h_deleg_break;
						tval = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc, 1'b0};
					end
				4:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_load_align?4'b1000:(r_cpu_mode[1]||!r_s_deleg_load_align?4'b0010:4'b0001);
						c_v = !r_m_deleg_load_align&r_v&r_h_deleg_load_align;
						tval = mem_addr;
					end
				5:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_load_access?4'b1000:(r_cpu_mode[1]||!r_s_deleg_load_access?4'b0010:4'b0001);
						c_v = !r_m_deleg_load_access&r_v&r_h_deleg_load_access;
						tval = mem_addr;
					end
				6:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_storeamo_align?4'b1000:(r_cpu_mode[1]||!r_s_deleg_storeamo_align?4'b0010:4'b0001);
						c_v = !r_m_deleg_storeamo_align&r_v&r_h_deleg_storeamo_align;
						tval = mem_addr;
					end
				7:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_storeamo_access?4'b1000:(r_cpu_mode[1]||!r_s_deleg_storeamo_access?4'b0010:4'b0001);
						c_v = !r_m_deleg_storeamo_access&r_v&r_h_deleg_storeamo_access;
						tval = mem_addr;
					end
				8:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_env_u?4'b1000:(r_cpu_mode[1]||!r_s_deleg_env_u?4'b0010:4'b0001);
						c_v = !r_m_deleg_env_u&r_v;
						tval = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc, 1'b0};
					end
				9:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_env_s?4'b1000:4'b0010;
						c_v = !r_m_deleg_env_s&r_v&r_h_deleg_env_s;
						tval = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc, 1'b0};
					end
				11:	begin
						c_cpu_mode = 4'b1000;
						c_v = 0;
					end
				12:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_ins_pf?4'b1000:(r_cpu_mode[1]||!r_s_deleg_ins_pf?4'b0010:4'b0001);
						c_v = !r_m_deleg_ins_pf&r_v&r_h_deleg_ins_pf;
						tval = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc, 1'b0};
					end
				13:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_load_pf?4'b1000:(r_cpu_mode[1]||!r_s_deleg_load_pf?4'b0010:4'b0001);
						c_v = !r_m_deleg_load_pf&r_v&r_h_deleg_load_pf;
						tval = mem_addr;
					end
				15:	begin
						c_cpu_mode = r_cpu_mode[3]||!r_m_deleg_storeamo_pf?4'b1000:(r_cpu_mode[1]||!r_s_deleg_storeamo_pf?4'b0010:4'b0001);
						c_v = !r_m_deleg_storeamo_pf&r_v&r_h_deleg_storeamo_pf;
						tval = mem_addr;
					end
				endcase
				casez ({c_v, c_cpu_mode}) // synthesis full_case parallel_case
				5'b?_1???: c_next_pc = {r_m_trap_base, 1'b0};
				5'b0_??1?: c_next_pc = {r_s_trap_base, 1'b0};
				5'b1_??1?: c_next_pc = {r_vs_trap_base, 1'b0};
				5'b?_???1: c_next_pc = {r_u_trap_base, 1'b0};
				default:   c_next_pc = 63'bx;
				endcase
				c_trap_br_enable = 1;
			end
		6'b0_??_?_1_?:	// interrupt
			begin
				if (r_control[0]) begin		// clic vector fetch
						int_clic_ack = 1;
						c_int_br_enable = 1;
						c_next_pc = r1[RV-1:1];
				end else begin
					casez ({int_m_pending&r_m_ie, int_s_pending&r_s_ie&(cpu_mode[1:0]!=0), int_u_pending&r_u_ie&cpu_mode[0]}) // synthesis full_case parallel_case
					3'b1??: if (clic_m_enable) begin
								int_clic_ack_save = 1;
								int_clic_ack_int = clic_m_int;
								if (clic_m_vec) begin
									c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
									c_int_force_fetch = 1;
								end else begin
									c_next_pc = {r_m_trap_base[RV-1:6], 4'b0000, 1'b0};
									c_int_br_enable = 1;
									int_clic_ack = 1;
								end
								c_cpu_mode = 4'b1000;
							end else begin
								if (r_m_trap_type[0]) begin
									c_next_pc = {r_m_trap_base, 1'b0}+{mvec, 1'b0};
									c_int_br_enable = 1;
								end else begin
									c_next_pc = {r_m_trap_base, 1'b0};
									c_int_br_enable = 1;
								end
								c_cpu_mode = 4'b1000;
							end
					3'b01?: if (clic_s_enable) begin
								int_clic_ack_save = 1;
								int_clic_ack_int = clic_s_int;
								if (clic_s_vec) begin
									c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
									c_int_force_fetch = 1;
								end else begin
									c_next_pc = {r_s_trap_base[RV-1:6], 4'b0000, 1'b0};
									c_int_br_enable = 1;
									int_clic_ack = 1;
								end
								c_cpu_mode = 4'b0010;
							end else begin
								if (r_s_trap_type[0]) begin
									c_next_pc = {r_s_trap_base, 1'b0}+{svec, 1'b0};
									c_int_br_enable = 1;
								end else begin
									c_next_pc = {r_s_trap_base, 1'b0};
									c_int_br_enable = 1;
								end
								c_cpu_mode = 4'b0010;
							end
					3'b001: if (clic_u_enable) begin
								int_clic_ack_save = 1;
								int_clic_ack_int = clic_u_int;
								if (clic_u_vec) begin
									c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
									c_int_force_fetch = 1;
								end else begin
									c_next_pc = {r_u_trap_base[RV-1:6], 4'b0000, 1'b0};
									c_int_br_enable = 1;
									int_clic_ack = 1;
								end
								c_cpu_mode = 4'b0001;
							end else begin
								if (r_u_trap_type[0]) begin
									c_next_pc = {r_u_trap_base, 1'b0}+{uvec, 1'b0};
									c_int_br_enable = 1;
								end else begin
									c_next_pc = {r_u_trap_base, 1'b0};
									c_int_br_enable = 1;
								end
								c_cpu_mode = 4'b0001;
							end
					3'b000:		// there's a timing hole where an interrupt request has been shoved into the pipe
								//		but meantime interrupts have been turned off ... in that case just continue
								//		with a pipe flush 
						begin
							c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc};
							c_trap_br_enable = 1;
						end
					endcase
				end
			end
		6'b0_??_?_?_1:	// csr write
			begin
				c_next_pc = {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}+2; // when do we need to flush
				casez (r_immed[11:0]) // synthesis full_case parallel_case
				12'b00_11_0000_0000,
				12'b00_11_0100_0101:
								begin
									reg xprv, xmxr, xprv2, nint, mint, sint, uint;
									xprv = 0;
									xmxr = 0;
									xprv2 = 0;
									nint = 0;
									mint = 0;
									sint = 0;
									uint = 0;
									if (!r_mprv) begin
										if (!r_control[2])
											xprv = in[17];
									end else begin
										casez(r_control[2:1]) // synthesis full_case parallel_case
										2'b1?:	xprv = in[17];
										2'b?1:	xprv = 0;
										2'b00:	xprv = ~in[17];
										endcase
										casez (r_control[2:1]) // synthesis full_case parallel_case
										2'b1?: xprv2 = r_m_pp != (r_m_pp&~in[12:11]);
										2'b?1: xprv2 = r_m_pp != (r_m_pp|in[12:11]);
										2'b00: xprv2 = r_m_pp != in[12:11];
										endcase
									end
									if (!r_m_mxr) begin
										if (!r_control[2])
											xmxr = in[19];
									end else begin
										casez(r_control[2:1]) // synthesis full_case parallel_case
										2'b1?:	xmxr = in[19];
										2'b?1:	xmxr = 0;
										2'b00:	xmxr = ~in[19];
										endcase
									end
									casez(r_control[2:1]) // synthesis full_case parallel_case
									2'b?1:	mint = 0;
									default:mint = ~r_m_ie&int_m_pending&in[3];
									endcase
									casez(r_control[2:1]) // synthesis full_case parallel_case
									2'b?1:	sint = 0;
									default:sint = ~r_s_ie&int_s_pending&in[1];
									endcase
									casez(r_control[2:1]) // synthesis full_case parallel_case
									2'b?1:	uint = 0;
									default:uint = ~r_u_ie&int_u_pending&in[0];
									endcase
									casez (cpu_mode) // synthesis full_case parallel_case
									4'b1???: nint = mint;
									4'b??1?: nint = mint|sint;
									4'b???1: nint = mint|sint|uint;
									endcase
									c_trap_br_enable = xmxr|xprv|xprv2|nint;
								end
				12'b00_01_1000_0000,	// satp
				12'b01_10_1000_0000,	// vsatp
				12'b00_11_1010_00??,	// pmap
				12'b00_11_1011_????:
								c_trap_br_enable = 1;
`ifdef FP
				12'b00_00_0000_0010,
				12'b00_00_0000_0011:
								c_trap_br_enable = r_frm != new_rm;
`endif
				default: ;
				endcase
			end
		6'b0_0?_0_0_0:
			;
		endcase
	end

	always @(posedge clk) begin
		r_cpu_mode <= c_cpu_mode;
		r_v <= c_v;
		r_trap_br_enable <= c_trap_br_enable;
		r_next_pc <= c_next_pc;
	end

	reg [RV-1:1]r_u_epc, r_s_epc, r_m_epc, r_vs_epc;


	always @(posedge clk)
	if (trap_s ||
		(interrupt && s_pending && !r_control[0]) && !fast_int_s)  r_s_epc <= {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}; else	// FIXME virt
	if (iret && r_control[1:0] == 3 && fast_int_s) r_s_epc <= r_m_epc; else
	if (csr_write && (!r_v||cpu_mode[3]) && r_immed[11:0] == 12'h141)
	if (r_control[1]) r_s_epc <= r_s_epc|in[RV-1:1]; else
	if (r_control[2]) r_s_epc <= r_s_epc&~in[RV-1:1]; else
					r_s_epc <= in[RV-1:1];

	always @(posedge clk)
	if (csr_write && r_immed[11:0] == (r_v?12'h141:12'h241))	 // FIXME virt	// something about fast ints
	if (r_control[1]) r_vs_epc <= r_vs_epc|in[RV-1:1]; else
	if (r_control[2]) r_vs_epc <= r_vs_epc&~in[RV-1:1]; else
					r_vs_epc <= in[RV-1:1];

	always @(posedge clk)
	if (trap_m ||
		(interrupt && m_pending && !r_control[0] && !fast_int_m)) r_m_epc <= {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}; else
	if (csr_write && r_immed[11:0] == 12'h341)
	if (r_control[1]) r_m_epc <= r_m_epc|in[RV-1:1]; else
	if (r_control[2]) r_m_epc <= r_m_epc&~in[RV-1:1]; else
					r_m_epc <= in[RV-1:1];

	always @(posedge clk)
	if (trap_u ||
		(interrupt && u_pending && !r_control[0]) && !fast_int_u) r_u_epc <= {{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc}; else	// FIXME virt
	if (iret && r_control[1:0] == 3 && fast_int_u) r_u_epc <= r_m_epc; else
	if (iret && r_control[1:0] == 1 && fast_int_u) r_u_epc <= r_s_epc; else
	if (csr_write && r_immed[11:0] == 12'h041)
	if (r_control[1]) r_u_epc <= r_u_epc|in[RV-1:1]; else
	if (r_control[2]) r_u_epc <= r_u_epc&~in[RV-1:1]; else
					r_u_epc <= in[RV-1:1];

	reg [RV-1:0]r_u_scratch, r_s_scratch, r_m_scratch, r_vs_scratch;
	always @(posedge clk)
	if (csr_write && r_immed[11:0] == 12'h040) begin
		if (r_control[1]) r_u_scratch <= r_u_scratch|in; else
		if (r_control[2]) r_u_scratch <= r_u_scratch&~in; else
					r_u_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == 12'h048 && r_m_pp == 0 ) begin
		if (r_control[1]) r_u_scratch <= r_u_scratch|in; else
		if (r_control[2]) r_u_scratch <= r_u_scratch&~in; else
					      r_u_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == 12'h049 && (r_u_pil == 0) != (clic_u_il != 0)) begin
		if (r_control[1]) r_u_scratch <= r_u_scratch|in; else
		if (r_control[2]) r_u_scratch <= r_u_scratch&~in; else
					      r_u_scratch <= in;
	end 

	always @(posedge clk)
	if (csr_write && (!r_v||cpu_mode[3]) && r_immed[11:0] == 12'h140) begin
		if (r_control[1]) r_s_scratch <= r_s_scratch|in; else
		if (r_control[2]) r_s_scratch <= r_s_scratch&~in; else
						r_s_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == 12'h148 && r_m_pp == 1 ) begin
		if (r_control[1]) r_s_scratch <= r_s_scratch|in; else
		if (r_control[2]) r_s_scratch <= r_s_scratch&~in; else
					      r_s_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == 12'h149 && (r_s_pil == 0) != (clic_s_il != 0)) begin
		if (r_control[1]) r_s_scratch <= r_s_scratch|in; else
		if (r_control[2]) r_s_scratch <= r_s_scratch&~in; else
					      r_s_scratch <= in;
	end 

	always @(posedge clk)
	if (csr_write && r_immed[11:0] == (r_v?12'h140:12'h240)) begin
		if (r_control[1]) r_vs_scratch <= r_vs_scratch|in; else
		if (r_control[2]) r_vs_scratch <= r_vs_scratch&~in; else
					r_vs_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == (r_v?12'h148:12'h248) && r_m_pp == 2 ) begin
		if (r_control[1]) r_vs_scratch <= r_vs_scratch|in; else
		if (r_control[2]) r_vs_scratch <= r_vs_scratch&~in; else
					      r_vs_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == (r_v?12'h149:12'h249) && (r_vs_pil == 0) != (clic_h_il != 0)) begin
		if (r_control[1]) r_vs_scratch <= r_vs_scratch|in; else
		if (r_control[2]) r_vs_scratch <= r_vs_scratch&~in; else
					      r_vs_scratch <= in;
	end

	always @(posedge clk)
	if (csr_write && r_immed[11:0] == 12'h340) begin
		if (r_control[1]) r_m_scratch <= r_m_scratch|in; else
		if (r_control[2]) r_m_scratch <= r_m_scratch&~in; else
					      r_m_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == 12'h348 && r_m_pp == 3 ) begin
		if (r_control[1]) r_m_scratch <= r_m_scratch|in; else
		if (r_control[2]) r_m_scratch <= r_m_scratch&~in; else
					      r_m_scratch <= in;
	end else
	if (csr_write && r_immed[11:0] == 12'h349 && (r_m_pil == 0) != (clic_m_il != 0)) begin
		if (r_control[1]) r_m_scratch <= r_m_scratch|in; else
		if (r_control[2]) r_m_scratch <= r_m_scratch&~in; else
					      r_m_scratch <= in;
	end 

	reg [RV-1:2]r_u_trap_base, r_s_trap_base, r_m_trap_base, r_vs_trap_base;
	reg [1:0]r_u_trap_type, r_s_trap_type, r_m_trap_type, r_vs_trap_type;
	always @(posedge clk)
	if (reset) r_u_trap_type <= 0; else
	if (csr_write && r_immed[11:0] == 12'h005)
	if (r_control[1]) begin
			r_u_trap_base <= r_u_trap_base|in[RV-1:2];
			r_u_trap_type <= r_u_trap_type|in[1:0];
	end else
	if (r_control[2]) begin
			r_u_trap_base <= r_u_trap_base&~in[RV-1:2];
			r_u_trap_type <= r_u_trap_type&~in[1:0];
	end else begin
			r_u_trap_base <= in[RV-1:2];
			r_u_trap_type <= in[1:0];
	end
	assign clic_u_enable = r_u_trap_type == 3;

	always @(posedge clk)
	if (reset) r_s_trap_type <= 0; else
	if (csr_write && (!r_v||cpu_mode[3]) && r_immed[11:0] == 12'h105)
	if (r_control[1])begin
			r_s_trap_base <= r_s_trap_base|in[RV-1:2];
			r_s_trap_type <= r_s_trap_type|in[1:0];
	end else
	if (r_control[2])begin
			r_s_trap_base <= r_s_trap_base&~in[RV-1:2];
			r_s_trap_type <= r_s_trap_type&~in[1:0];
	end else begin
			r_s_trap_base <= in[RV-1:2];
			r_s_trap_type <= in[1:0];
	end
	assign clic_s_enable = r_s_trap_type == 3;

	always @(posedge clk)
	if (reset) r_vs_trap_type <= 0; else
	if (csr_write && r_immed[11:0] == (r_v?12'h105:12'h205))
	if (r_control[1])begin
			r_vs_trap_base <= r_vs_trap_base|in[RV-1:2];
			r_vs_trap_type <= r_vs_trap_type|in[1:0];
	end else
	if (r_control[2])begin
			r_vs_trap_base <= r_vs_trap_base&~in[RV-1:2];
			r_vs_trap_type <= r_vs_trap_type&~in[1:0];
	end else begin
			r_vs_trap_base <= in[RV-1:2];
			r_vs_trap_type <= in[1:0];
	end
	assign clic_h_enable = r_vs_trap_type == 3;

	always @(posedge clk)
	if (reset) r_m_trap_type <= 0; else
	if (csr_write && r_immed[11:0] == 12'h305)
	if (r_control[1])begin
			r_m_trap_base <= r_m_trap_base|in[RV-1:2];
			r_m_trap_type <= r_m_trap_type|in[1:0];
	end else
	if (r_control[2])begin
			r_m_trap_base <= r_m_trap_base&~in[RV-1:2];
			r_m_trap_type <= r_m_trap_type&~in[1:0];
	end else begin
			r_m_trap_base <= in[RV-1:2];
			r_m_trap_type <= in[1:0];
	end

	assign clic_m_enable = r_m_trap_type == 3;

	reg		[RV-1:2+$clog2(NINTERRUPTS)]r_m_tvt;
	always @(posedge clk)
	if (csr_write && (r_immed[11:0] == 12'h307))
	if (r_control[1]) r_m_tvt <= r_m_tvt|in[RV-1:2+$clog2(NINTERRUPTS)]; else
	if (r_control[2]) r_m_tvt <= r_m_tvt&~in[RV-1:2+$clog2(NINTERRUPTS)]; else r_m_tvt <= in[RV-1:2+$clog2(NINTERRUPTS)];

	reg		[RV-1:2+$clog2(NINTERRUPTS)]r_s_tvt;
	always @(posedge clk)
	if (csr_write && (r_immed[11:0] == 12'h107))
	if (r_control[1]) r_s_tvt <= r_s_tvt|in[RV-1:2+$clog2(NINTERRUPTS)]; else
	if (r_control[2]) r_s_tvt <= r_s_tvt&~in[RV-1:2+$clog2(NINTERRUPTS)]; else r_s_tvt <= in[RV-1:2+$clog2(NINTERRUPTS)];

	reg		[RV-1:2+$clog2(NINTERRUPTS)]r_vs_tvt;
	always @(posedge clk)
	if (csr_write && (r_immed[11:0] == 12'h207))
	if (r_control[1]) r_vs_tvt <= r_vs_tvt|in[RV-1:2+$clog2(NINTERRUPTS)]; else
	if (r_control[2]) r_vs_tvt <= r_vs_tvt&~in[RV-1:2+$clog2(NINTERRUPTS)]; else r_vs_tvt <= in[RV-1:2+$clog2(NINTERRUPTS)];

	reg		[RV-1:2+$clog2(NINTERRUPTS)]r_u_tvt;
	always @(posedge clk)
	if (csr_write && (r_immed[11:0] == 12'h007))
	if (r_control[1]) r_u_tvt <= r_u_tvt|in[RV-1:2+$clog2(NINTERRUPTS)]; else
	if (r_control[2]) r_u_tvt <= r_u_tvt&~in[RV-1:2+$clog2(NINTERRUPTS)]; else r_u_tvt <= in[RV-1:2+$clog2(NINTERRUPTS)];

	



	reg		r_tsr;					// trap sret	
	always @(posedge clk)
	if (reset) r_tsr <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345))
	if (r_control[1]) r_tsr <= r_tsr|in[22]; else
	if (r_control[2]) r_tsr <= r_tsr&~in[22]; else r_tsr <= in[22];
	assign tsr = r_tsr;

	reg		r_tw;					// timeout wait
	always @(posedge clk)
	if (reset) r_tw <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345))
	if (r_control[1]) r_tw <= r_tw|in[21]; else
	if (r_control[2]) r_tw <= r_tw&~in[21]; else r_tw <= in[21];

	reg		r_wfi_timeout;
	assign wfi_timeout=r_wfi_timeout;
	reg		[7:0]r_wfi_timer;
	assign	csr_wfi_wake = (int_m_pending|int_s_pending|int_u_pending) || r_wfi_timeout;
	always @(posedge clk) begin
		if (reset || cpu_mode[3] || !r_tw || c_trap_br_enable) begin
			r_wfi_timeout <= 0;
		end else
		if (r_wfi_timer == 0) begin
			r_wfi_timeout <= 1;
		end
	end
	always @(posedge clk) begin
		if (reset || cpu_mode[3] || !r_tw || !csr_wfi_pause) begin
			r_wfi_timer <= 8'hff;
		end else
		if (r_wfi_timer != 0) begin
			r_wfi_timer <= r_wfi_timer-1;
		end
	end

	reg		r_tvm;					// trap virtual memory
	always @(posedge clk)
	if (reset) r_tvm <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h345))
	if (r_control[1]) r_tvm <= r_tvm|in[20]; else
	if (r_control[2]) r_tvm <= r_tvm&~in[20]; else r_tvm <= in[20];
	assign tvm = r_tvm;

	reg		r_m_mxr;					// make executable readable
	always @(posedge clk)
	if (reset) r_m_mxr <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345))
	if (r_control[1]) r_m_mxr <= r_m_mxr|in[19]; else
	if (r_control[2]) r_m_mxr <= r_m_mxr&~in[19]; else r_m_mxr <= in[19];
	reg		r_s_mxr;					// make executable readable
	assign mxr = (r_m_mxr&r_cpu_mode[3]) | (r_s_mxr&r_cpu_mode[1]);
	always @(posedge clk)
	if (reset) r_s_mxr <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145))
	if (r_control[1]) r_s_mxr <= r_s_mxr|in[19]; else
	if (r_control[2]) r_s_mxr <= r_s_mxr&~in[19]; else r_s_mxr <= in[19];

	assign sup_vm_sum = (hyper?r_vs_sum:r_s_sum);
	reg		r_s_sum, r_vs_sum;					// sup user memory access
	always @(posedge clk)
	if (reset) r_s_sum <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145))
	if (r_control[1]) r_s_sum <= r_s_sum|in[18]; else
	if (r_control[2]) r_s_sum <= r_s_sum&~in[18]; else r_s_sum <= in[18];

	always @(posedge clk)
	if (reset) r_vs_sum <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h200 || r_immed[11:0] == 12'h245))
	if (r_control[1]) r_vs_sum <= r_vs_sum|in[18]; else
	if (r_control[2]) r_vs_sum <= r_vs_sum&~in[18]; else r_vs_sum <= in[18];

	reg		r_mprv;					// memory priv
	always @(posedge clk)
	if (reset) r_mprv <= 0; else
	if (iret && r_control[1:0] == 3 && !c_cpu_mode[3]) r_mprv <= 0; else	// iret
	if (iret && r_control[1:0] == 1 && c_cpu_mode[0]) r_mprv <= 0; else	// iret
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345))
	if (r_control[1]) r_mprv <= r_mprv|in[17]; else
	if (r_control[2]) r_mprv <= r_mprv&~in[17]; else r_mprv <= in[17];


	reg	[1:0]r_xs;					// fp context - read-only
	always @(posedge clk)
	if (reset) r_xs <= 0;

`ifdef FP
	reg [4:0]r_fflags;
	reg [2:0]r_frm;
	reg	[1:0]r_fs;					// fp context

	reg	[2:0]new_rm;
	assign fp_rounding = r_frm;
	assign fp_off = r_fs == 0;

	always @(posedge clk)
		r_frm <= new_rm;
	always @(*) begin :rmmx
		reg [2:0]xrm;
		xrm = r_frm;
		if (reset) xrm = 0; else
		if (csr_write && (r_immed[11:0] == 12'h002)) begin
			if (r_control[1]) xrm = r_frm|in[2:0]; else
			if (r_control[2]) xrm = r_frm&~in[2:0]; else xrm = in[2:0];
		end else
		if (csr_write && (r_immed[11:0] == 12'h003)) begin
			if (r_control[1]) xrm = r_frm|in[7:5]; else
			if (r_control[2]) xrm = r_frm&~in[7:5]; else xrm = in[7:5];
		end 
		new_rm = xrm > 4 ? r_frm : xrm;
	end

	always @(posedge clk)
	if (reset) r_fflags <= 0; else
	if (update_fp_state) r_fflags <= r_fflags|fp_exceptions; else
	if (csr_write && (r_immed[11:0] == 12'h001 || r_immed[11:0] == 12'h003)) 
	if (r_control[1]) r_fflags <= r_fflags|in[4:0]; else
	if (r_control[2]) r_fflags <= r_fflags&~in[4:0]; else r_fflags <= in[4:0];

	always @(posedge clk)
	if (reset) r_fs <= 1; else
	if (update_fp_state & (fp_written ||  |(fp_exceptions&~r_fflags))) r_fs <= 3; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145))
	if (r_control[1]) r_fs <= r_fs|in[14:13]; else
	if (r_control[2]) r_fs <= r_fs&~in[14:13]; else r_fs <= in[14:13];

`else
	wire [1:0]r_fs = 0;
`endif

	reg		 r_mpv, r_mtl;
	always @(posedge clk)
	if (reset) r_mpv <= 0; else
	if (!rv32 && csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345)) begin
		if (r_control[1]) r_mpv <= r_mpv|in[39]; else
		if (r_control[2]) r_mpv <= r_mpv&~in[39]; else r_mpv <= in[39];
	end else
	if (rv32 && csr_write && r_immed[11:0] == 12'h310) begin
		if (r_control[1]) r_mpv <= r_mpv|in[7]; else
		if (r_control[2]) r_mpv <= r_mpv&~in[7]; else r_mpv <= in[7];
	end

	always @(posedge clk)
	if (reset) r_mtl <= 0; else
	if (!rv32 && csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345)) begin
		if (r_control[1]) r_mtl <= r_mtl|in[38]; else
		if (r_control[2]) r_mtl <= r_mtl&~in[38]; else r_mtl <= in[38];
	end else
	if (rv32 && csr_write && r_immed[11:0] == 12'h310) begin
		if (r_control[1]) r_mtl <= r_mtl|in[6]; else
		if (r_control[2]) r_mtl <= r_mtl&~in[6]; else r_mtl <= in[6];
	end

	reg [1:0]enc_cpu_mode;
	always @(*)
	casez (cpu_mode) // synthesis full_case parallel_case
	4'b1???: enc_cpu_mode = 3;
	4'b??1?: enc_cpu_mode = 1;
	4'b???1: enc_cpu_mode = 0;
	endcase

	reg	[1:0]r_m_pp;					// previous priv modes
	reg [3:0]mpp_mode;
	assign  mprv = r_mprv?mpp_mode:cpu_mode;
	always @(*) 
	casez (r_m_pp) // synthesis full_case parallel_case
	0: mpp_mode = 4'b0001;
	1: mpp_mode = 4'b0010;
	3: mpp_mode = 4'b1000;
	endcase
	
	always @(posedge clk)
	if (reset) r_m_pp <= 0; else
	if (trap_m ||
		(interrupt && m_pending && !r_control[0])&&!fast_int_m)  r_m_pp <= enc_cpu_mode; else
	if (iret && !fast_int_m && r_control[1:0] == 3) r_m_pp <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345)) begin:t
		reg [1:0]tmp;
		if (r_control[1]) tmp = r_m_pp|in[12:11]; else
		if (r_control[2]) tmp = r_m_pp&~in[12:11]; else tmp = in[12:11];
		r_m_pp <= (tmp==2?r_m_pp:tmp);
	end else
	if (csr_write && clic_m_enable && r_immed[11:0] == 12'h342) begin :t1
		reg [1:0]tmp;
		if (r_control[1]) tmp = r_m_pp|in[29:28]; else
		if (r_control[2]) tmp = r_m_pp&~in[29:28]; else tmp = in[29:28];
		r_m_pp <= (tmp==2?r_m_pp:tmp);
	end 

	reg		r_s_pp;
	always @(posedge clk)
	if (reset) r_s_pp <= 0; else
	if (trap_s || (interrupt && s_pending && !r_control[0] && !fast_int_s)) r_s_pp <= cpu_mode[1]; else
	if (iret && r_control[1:0] == 1 && !fast_int_s) r_s_pp <= 0; else
	if (iret && r_control[1:0] == 3 && fast_int_s) r_s_pp <= r_m_pp[0]; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145)) begin
		if (r_control[1]) r_s_pp <= r_s_pp|in[8]; else
		if (r_control[2]) r_s_pp <= r_s_pp&~in[8]; else r_s_pp <= in[8];
	end else
	if (csr_write && clic_s_enable && r_immed[11:0] == 12'h142) begin
		if (r_control[1]) r_s_pp <= r_s_pp|in[28]; else
		if (r_control[2]) r_s_pp <= r_s_pp&~in[28]; else r_s_pp <= in[28];
	end 

	reg	    r_m_inhv;
	always @(posedge clk)
	if (reset) r_m_inhv <= 0; else
	if (trap_m) r_m_inhv <= 0; else
	if (fast_int_m || (interrupt && m_pending && !r_control[0] && !fast_int_m)) r_m_inhv <= int_m_vec; else
	if (csr_write && clic_m_enable && r_immed[11:0] == 12'h342) begin
		if (r_control[1]) r_m_inhv <= r_m_inhv|in[30]; else
		if (r_control[2]) r_m_inhv <= r_m_inhv&~in[30]; else r_m_inhv <= in[30];
	end 

	reg	    r_vs_inhv;
	always @(posedge clk)
	if (reset) r_vs_inhv <= 0; else
	if (trap_vs) r_vs_inhv <= 0; else
	if (fast_int_vs || (interrupt && h_pending && !r_control[0])) r_vs_inhv <= int_h_vec; else
	if (csr_write && clic_h_enable && r_immed[11:0] == 12'h242) begin
		if (r_control[1]) r_vs_inhv <= r_vs_inhv|in[30]; else
		if (r_control[2]) r_vs_inhv <= r_vs_inhv&~in[30]; else r_vs_inhv <= in[30];
	end 

	reg	    r_s_inhv;
	always @(posedge clk)
	if (reset) r_s_inhv <= 0; else
	if (trap_s) r_s_inhv <= 0; else
	if (fast_int_s || (interrupt && s_pending && !r_control[0] && !fast_int_s)) r_s_inhv <= int_s_vec; else
	if (iret && r_control[1:0] == 3 && fast_int_s) r_s_inhv <= r_m_inhv; else
	if (csr_write && clic_s_enable && r_immed[11:0] == 12'h142) begin
		if (r_control[1]) r_s_inhv <= r_s_inhv|in[30]; else
		if (r_control[2]) r_s_inhv <= r_s_inhv&~in[30]; else r_s_inhv <= in[30];
	end 

	reg	    r_u_inhv;
	always @(posedge clk)
	if (reset) r_u_inhv <= 0; else
	if (trap_u) r_u_inhv <= 0; else
	if (fast_int_u || (interrupt && u_pending && !r_control[0] && !fast_int_u)) r_u_inhv <= int_u_vec; else
	if (iret && r_control[1:0] == 3 && fast_int_u) r_u_inhv <= r_m_inhv; else
	if (iret && r_control[1:0] == 1 && fast_int_u) r_u_inhv <= r_s_inhv; else
	if (csr_write && clic_u_enable && r_immed[11:0] == 12'h042) begin
		if (r_control[1]) r_u_inhv <= r_u_inhv|in[30]; else
		if (r_control[2]) r_u_inhv <= r_u_inhv&~in[30]; else r_u_inhv <= in[30];
	end 

	reg	[7:0]r_m_pil;
	always @(posedge clk)
	if (reset) r_m_pil <= 0; else
	if (interrupt && m_pending && !r_control[0] && clic_m_enable) r_m_pil <= r_m_il; else
	if (csr_write && clic_m_enable && r_immed[11:0] == 12'h342) begin
		if (r_control[1]) r_m_pil <= r_m_pil|in[23:16]; else
		if (r_control[2]) r_m_pil <= r_m_pil&~in[23:16]; else r_m_pil <= in[23:16];
	end else
	if (csr_write && clic_m_enable && r_immed[11:0] == 12'h345 && !(r_control[1] && in != 0) &&
			clic_m_enable && cpu_mode[3] && clic_m_il > r_m_pil && clic_m_il > r_m_intthresh && clic_m_vec) begin
		r_m_pil <= clic_m_il;
	end 

	reg	[7:0]r_vs_pil;
	always @(posedge clk)
	if (reset) r_vs_pil <= 0; else
	if (interrupt && r_vs_ie&int_h_pending && !r_control[0] && clic_h_enable) r_vs_pil <= r_vs_il; else
	if (csr_write && clic_h_enable && r_immed[11:0] == 12'h242) begin
		if (r_control[1]) r_vs_pil <= r_vs_pil|in[23:16]; else
		if (r_control[2]) r_vs_pil <= r_vs_pil&~in[23:16]; else r_vs_pil <= in[23:16];
	end else
	if (csr_write && clic_h_enable && r_immed[11:0] == 12'h245 && !(r_control[1] && in != 0) &&
			clic_h_enable && cpu_mode[1] && clic_h_il > r_vs_pil && clic_h_il > r_vs_intthresh && clic_h_vec) begin
		r_vs_pil <= clic_h_il;
	end 

	reg	[7:0]r_s_pil;
	always @(posedge clk)
	if (reset) r_s_pil <= 0; else
	if (interrupt && s_pending && !r_control[0] && clic_s_enable) r_s_pil <= r_s_il; else
	if (csr_write && clic_s_enable && r_immed[11:0] == 12'h142) begin
		if (r_control[1]) r_s_pil <= r_s_pil|in[23:16]; else
		if (r_control[2]) r_s_pil <= r_s_pil&~in[23:16]; else r_s_pil <= in[23:16];
	end else
	if (csr_write && clic_s_enable && r_immed[11:0] == 12'h145 && !(r_control[1] && in != 0) &&
			clic_s_enable && cpu_mode[1] && clic_s_il > r_s_pil && clic_s_il > r_s_intthresh && clic_s_vec) begin
		r_s_pil <= clic_s_il;
	end

	reg	[7:0]r_u_pil;
	always @(posedge clk)
	if (reset) r_u_pil <= 0; else
	if (interrupt && u_pending && !r_control[0] && clic_u_enable) r_u_pil <= r_u_il; else
	if (csr_write && clic_u_enable && r_immed[11:0] == 12'h042) begin
		if (r_control[1]) r_u_pil <= r_u_pil|in[23:16]; else
		if (r_control[2]) r_u_pil <= r_u_pil&~in[23:16]; else r_u_pil <= in[23:16];
	end else
	if (csr_write && clic_u_enable && r_immed[11:0] == 12'h045 && !(r_control[1] && in != 0) &&
			clic_u_enable && cpu_mode[0] && clic_u_il > r_u_pil && clic_u_il > r_u_intthresh && clic_u_vec) begin
		r_u_pil <= clic_u_il;
	end

	reg		r_m_pie, r_s_pie, r_vs_pie, r_u_pie; // saved intterupt bits prior to trap
	always @(posedge clk)
	if (reset) r_m_pie <= 0; else
	if (iret && !fast_int_m && r_control[1:0] == 3) r_m_pie <= 1; else	// iret
	if (trap_m || (interrupt && m_pending && !r_control[0]))  r_m_pie <= r_m_ie; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345)) begin
		if (r_control[1]) r_m_pie <= r_m_pie|in[7]; else
		if (r_control[2]) r_m_pie <= r_m_pie&~in[7]; else r_m_pie <= in[7];
	end else
	if (csr_write && clic_m_enable && r_immed[11:0] == 12'h342) begin
		if (r_control[1]) r_m_pie <= r_m_pie|in[27]; else
		if (r_control[2]) r_m_pie <= r_m_pie&~in[27]; else r_m_pie <= in[27];
	end 

	always @(posedge clk)
	if (reset) r_vs_pie <= 0; else
	if (iret && !fast_int_vs && r_control[1:0] == 1) r_vs_pie <= 1; else	// iret - BUG - FIXME
	if (interrupt && h_pending && !(m_pending) && !r_control[0])  r_vs_pie <= r_vs_ie; else
	if (csr_write && (r_immed[11:0] == (r_v?12'h100:12'h200 || r_immed[11:0] == 12'h245))) begin
		if (r_control[1]) r_vs_pie <= r_vs_pie|in[5]; else
		if (r_control[2]) r_vs_pie <= r_vs_pie&~in[5]; else r_vs_pie <= in[5];
	end else
	if (csr_write && clic_h_enable && r_immed[11:0] == 12'h242) begin
		if (r_control[1]) r_vs_pie <= r_vs_pie|in[27]; else
		if (r_control[2]) r_vs_pie <= r_vs_pie&~in[27]; else r_vs_pie <= in[27];
	end 

	always @(posedge clk)
	if (reset) r_s_pie <= 0; else
	if (iret && !fast_int_s && r_control[1:0] == 1) r_s_pie <= 1; else	// iret
	if (trap_s || (interrupt && s_pending && !r_control[0]))  r_s_pie <= r_s_ie; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || (!r_v && (r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145)))) begin
		if (r_control[1]) r_s_pie <= r_s_pie|in[5]; else
		if (r_control[2]) r_s_pie <= r_s_pie&~in[5]; else r_s_pie <= in[5];
	end else
	if (csr_write && clic_s_enable && r_immed[11:0] == 12'h142) begin
		if (r_control[1]) r_s_pie <= r_s_pie|in[27]; else
		if (r_control[2]) r_s_pie <= r_s_pie&~in[27]; else r_s_pie <= in[27];
	end 

	always @(posedge clk)
	if (reset) r_u_pie <= 0; else
	if (iret && !fast_int_u && r_control[1:0] == 0) r_u_pie <= 1; else	// iret
	if (trap_u || (interrupt && u_pending && !r_control[0]))  r_u_pie <= r_u_ie; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145 || r_immed[11:0] == 12'h000 || r_immed[11:0] == 12'h045)) begin
		if (r_control[1]) r_u_pie <= r_u_pie|in[4]; else
		if (r_control[2]) r_u_pie <= r_u_pie&~in[4]; else r_u_pie <= in[4];
	end else
	if (csr_write && clic_u_enable && r_immed[11:0] == 12'h042) begin
		if (r_control[1]) r_u_pie <= r_u_pie|in[27]; else
		if (r_control[2]) r_u_pie <= r_u_pie&~in[27]; else r_u_pie <= in[27];
	end 

	reg		r_m_ie, r_s_ie, r_vs_ie, r_u_ie;	// interrupt enable bits
	always @(posedge clk)
	if (reset) r_m_ie <= 0; else
	if (iret && !fast_int_m && r_control[1:0] == 3) r_m_ie <= r_m_pie; else	// iret
	if (fast_int_m || trap_m || (interrupt && m_pending && !r_control[0])) r_m_ie <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345))
	if (r_control[1]) r_m_ie <= r_m_ie|in[3]; else
	if (r_control[2]) r_m_ie <= r_m_ie&~in[3]; else r_m_ie <= in[3];

	always @(posedge clk)
	if (reset) r_vs_ie <= 0; else
	if (iret && !fast_int_vs && r_control[1:0] == 1) r_vs_ie <= r_vs_pie; else	// iret - BUG
	if (fast_int_vs || interrupt && h_pending && !r_control[0]) r_vs_ie <= 0; else
	if (csr_write && (r_immed[11:0] == (r_v?12'h200:12'h100) || r_immed[11:0] == (r_v?12'h245:12'h145)))
	if (r_control[1]) r_vs_ie <= r_vs_ie|in[1]; else
	if (r_control[2]) r_vs_ie <= r_vs_ie&~in[1]; else r_vs_ie <= in[1];

	always @(posedge clk)
	if (reset) r_s_ie <= 0; else
	if (iret && !fast_int_s && r_control[1:0] == 1) r_s_ie <= r_s_pie; else	// iret
	if (fast_int_s || trap_s || (interrupt && s_pending && !r_control[0])) r_s_ie <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || (!r_v && (r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145))))
	if (r_control[1]) r_s_ie <= r_s_ie|in[1]; else
	if (r_control[2]) r_s_ie <= r_s_ie&~in[1]; else r_s_ie <= in[1];

	always @(posedge clk)
	if (reset) r_u_ie <= 0; else
	if (iret && !fast_int_u && r_control[1:0] == 0) r_u_ie <= r_u_pie; else	// iret
	if (fast_int_u || trap_u ||  (interrupt && u_pending && !r_control[0])) r_u_ie <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145 || r_immed[11:0] == 12'h000 || r_immed[11:0] == 12'h045))
	if (r_control[1]) r_u_ie <= r_u_ie|in[0]; else
	if (r_control[2]) r_u_ie <= r_u_ie&~in[0]; else r_u_ie <= in[0];

	reg	 [1:0]r_sxl, r_uxl;
	always @(posedge clk)
	if (reset) r_sxl <= 2; else
	if (csr_write && (r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345)) 
	if (!r_control[1]&&!r_control[2]&&((in[35:34]==1)||(in[35:34]==2))) r_sxl <= in[35:34]; 

	always @(posedge clk)
	if (reset) r_uxl <= 2; else
	if (csr_write && r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145) 
	if (!r_control[1]&&!r_control[2]&&((in[33:32]==1)||(in[33:32]==2))) r_uxl <= in[33:32]; 

	reg [1:0]r_mxl;
	always @(posedge clk)
	if (reset) r_mxl <= (RV==64?2:1); else
	if (csr_write && r_immed[11:0] == 12'h300 || r_immed[11:0] == 12'h345 || r_immed[11:0] == 12'h100 || r_immed[11:0] == 12'h145)
	if (RV==64) begin
		if (r_mxl == 2) begin
			if (!r_control[1]&&!r_control[2]&&((in[63:62]==1)||(in[63:62]==2))) r_mxl <= in[63:62]; 
		end else begin
			if (!r_control[1]&&!r_control[2]&&((in[31:30]==1)||(in[31:30]==2))) r_mxl <= in[31:30]; 
		end
	end

	assign rv32 = (RV==32?1:(cpu_mode[0]&&r_uxl==1)||(cpu_mode[1]&&r_sxl==1)||(cpu_mode[3]&&r_mxl==3));

	always @(posedge clk)
		r_hs <= 0; 
`ifdef NOTDEF	// enable when we think we have a working hypervisor
	if (reset) r_hs <= 0; else
	if (csr_write && r_immed[11:0] == 12'h301)
	if (r_control[1]) r_hs <= r_hs|in[7]; else
	if (r_control[2]) r_hs <= r_hs&~in[7]; else r_hs <= in[7];
`endif
	assign hyper = r_hs;

	reg		r_u_trap_interrupt, r_s_trap_interrupt, r_m_trap_interrupt;
	reg [11:0]r_u_trap_cause, r_s_trap_cause, r_m_trap_cause;

	always @(posedge clk)
	if (trap_m) r_m_trap_interrupt <= 0; else
	if (fast_int_m || (interrupt && m_pending && !r_control[0])) r_m_trap_interrupt <= 1; else
	if (csr_write && r_immed[11:0] == 12'h342)
	if (RV==64) begin
		if (rv32) begin
			if (r_control[1]) r_m_trap_interrupt <= r_m_trap_interrupt|in[31]; else
			if (r_control[2]) r_m_trap_interrupt <= r_m_trap_interrupt&~in[31]; else r_m_trap_interrupt <= in[31];
		end else begin
			if (r_control[1]) r_m_trap_interrupt <= r_m_trap_interrupt|in[63]; else
			if (r_control[2]) r_m_trap_interrupt <= r_m_trap_interrupt&~in[63]; else r_m_trap_interrupt <= in[63];
		end
	end else begin
		if (r_control[1]) r_m_trap_interrupt <= r_m_trap_interrupt|in[31]; else
		if (r_control[2]) r_m_trap_interrupt <= r_m_trap_interrupt&~in[31]; else r_m_trap_interrupt <= in[31];
	end

	always @(posedge clk)
	if (trap_m) r_m_trap_cause <= wfi_trap?2:r_control[3:0]; else
	if (fast_int_m || (interrupt && m_pending && !r_control[0])) r_m_trap_cause <= mvec; else
	if (csr_write && r_immed[11:0] == 12'h342) begin
		if (r_control[1]) r_m_trap_cause <= r_m_trap_cause|in[11:0]; else
		if (r_control[2]) r_m_trap_cause <= r_m_trap_cause&~in[11:0]; else r_m_trap_cause <= in[11:0];
	end else
	if (csr_write && clic_m_enable && r_immed[11:0] == 12'h345 && !(r_control[1] && in != 0) &&
			clic_m_enable && cpu_mode[3] && clic_m_il > r_m_pil && clic_m_il > r_m_intthresh && clic_m_vec) begin
		r_m_trap_cause <= clic_m_int;
	end

	always @(posedge clk)
	if (trap_s) r_s_trap_interrupt <= 0; else
	if (fast_int_s || (interrupt && s_pending && !r_control[0])) r_s_trap_interrupt <= 1; else
	if (csr_write && r_immed[11:0] == 12'h142)
	if (RV==64) begin
		if (rv32) begin
			if (r_control[1]) r_s_trap_interrupt <= r_s_trap_interrupt|in[31]; else
			if (r_control[2]) r_s_trap_interrupt <= r_s_trap_interrupt&~in[31]; else r_s_trap_interrupt <= in[31];
		end else begin
			if (r_control[1]) r_s_trap_interrupt <= r_s_trap_interrupt|in[63]; else
			if (r_control[2]) r_s_trap_interrupt <= r_s_trap_interrupt&~in[63]; else r_s_trap_interrupt <= in[63];
		end
	end else begin
		if (r_control[1]) r_s_trap_interrupt <= r_s_trap_interrupt|in[31]; else
		if (r_control[2]) r_s_trap_interrupt <= r_s_trap_interrupt&~in[31]; else r_s_trap_interrupt <= in[31];
	end

	always @(posedge clk)
	if (trap_s) r_s_trap_cause <= wfi_trap?2:r_control[3:0]; else // FIXME virt
	if (fast_int_s || (interrupt && s_pending && !r_control[0])) r_s_trap_cause <= svec; else
	if (csr_write && r_immed[11:0] == 12'h142) begin
		if (r_control[1]) r_s_trap_cause <= r_s_trap_cause|in[11:0]; else
		if (r_control[2]) r_s_trap_cause <= r_s_trap_cause&~in[11:0]; else r_s_trap_cause <= in[11:0];
	end else
	if (csr_write && clic_s_enable && r_immed[11:0] == 12'h145 && !(r_control[1] && in != 0) &&
			clic_s_enable && cpu_mode[1] && clic_s_il > r_s_pil && clic_s_il > r_s_intthresh && clic_s_vec) begin
		r_s_trap_cause <= clic_s_int;
	end

	always @(posedge clk)
	if (trap_u) r_u_trap_interrupt <= 0; else
	if (fast_int_u || (interrupt && u_pending && !r_control[0])) r_u_trap_interrupt <= 1; else
	if (csr_write && r_immed[11:0] == 12'h042)
	if (RV==64) begin
		if (rv32) begin
			if (r_control[1]) r_u_trap_interrupt <= r_u_trap_interrupt|in[31]; else
			if (r_control[2]) r_u_trap_interrupt <= r_u_trap_interrupt&~in[31]; else r_u_trap_interrupt <= in[31];
		end else begin
			if (r_control[1]) r_u_trap_interrupt <= r_u_trap_interrupt|in[63]; else
			if (r_control[2]) r_u_trap_interrupt <= r_u_trap_interrupt&~in[63]; else r_u_trap_interrupt <= in[63];
		end
	end else begin
		if (r_control[1]) r_u_trap_interrupt <= r_u_trap_interrupt|in[31]; else
		if (r_control[2]) r_u_trap_interrupt <= r_u_trap_interrupt&~in[31]; else r_u_trap_interrupt <= in[31];
	end

	always @(posedge clk)
	if (trap_u) r_u_trap_cause <= wfi_trap?2:r_control[3:0]; else // FIXME virt
	if (fast_int_u || (interrupt && u_pending && !r_control[0])) r_u_trap_cause <= uvec; else
	if (csr_write && r_immed[11:0] == 12'h042) begin
		if (r_control[1]) r_u_trap_cause <= r_u_trap_cause|in[11:0]; else
		if (r_control[2]) r_u_trap_cause <= r_u_trap_cause&~in[11:0]; else r_u_trap_cause <= in[11:0];
	end else
	if (csr_write && clic_u_enable && r_immed[11:0] == 12'h045 && !(r_control[1] && in != 0) &&
			clic_u_enable && cpu_mode[0] && clic_u_il > r_u_pil && clic_u_il > r_u_intthresh && clic_u_vec) begin
		r_u_trap_cause <= clic_u_int;
	end



	reg [7:0]r_u_il, r_s_il, r_vs_il, r_m_il;

	always @(posedge clk)
	if (reset) r_m_il <= 0; else
	if (iret && !fast_int_m && r_control[1:0] == 3) r_m_il <= r_m_pil; else	// iret
	if (fast_int_m || (interrupt && m_pending && !r_control[0] && clic_m_enable)) r_m_il <= clic_m_il; else
	if (csr_write && r_immed[11:0] == 12'h346)															// FIXME address
	if (r_control[1]) r_m_il <= r_m_il|in[31:24]; else
	if (r_control[2]) r_m_il <= r_m_il&~in[31:24]; else r_m_il <= in[31:24];

	always @(posedge clk)
	if (reset) r_s_il <= 0; else
	if (iret && !fast_int_s && r_control[1:0] == 1) r_s_il <= r_s_pil; else	// iret
	if (fast_int_s || (interrupt && s_pending && !r_control[0] && clic_s_enable)) r_s_il <= clic_s_il; else
	if (csr_write && (r_immed[11:0] == 12'h146 || r_immed[11:0] == 12'h346))							// FIXME address
	if (r_control[1]) r_s_il <= r_s_il|in[15:8]; else
	if (r_control[2]) r_s_il <= r_s_il&~in[15:8]; else r_s_il <= in[15:8];

	always @(posedge clk)
	if (reset) r_u_il <= 0; else
	if (iret && !fast_int_u && r_control[1:0] == 0) r_u_il <= r_u_pil; else	// iret
	if (fast_int_u || (interrupt && u_pending && !r_control[0] && clic_u_enable)) r_u_il <= clic_u_il; else
	if (csr_write && (r_immed[11:0] == 12'h046 || r_immed[11:0] == 12'h146 || r_immed[11:0] == 12'h346))// FIXME address
	if (r_control[1]) r_u_il <= r_u_il|in[7:0]; else
	if (r_control[2]) r_u_il <= r_u_il&~in[7:0]; else r_u_il <= in[7:0];


	reg [7:0]r_u_intthresh, r_s_intthresh, r_vs_intthresh, r_m_intthresh;

	always @(posedge clk)
	if (reset) r_m_intthresh <= 0; else
	if (csr_write && r_immed[11:0] == 12'h34a)
	if (r_control[1]) r_m_intthresh <= r_m_intthresh|in[7:0]; else
	if (r_control[2]) r_m_intthresh <= r_m_intthresh&~in[7:0]; else r_m_intthresh <= in[7:0];

	always @(posedge clk)
	if (reset) r_vs_intthresh <= 0; else
	if (csr_write && r_immed[11:0] == 12'h24a)
	if (r_control[1]) r_vs_intthresh <= r_vs_intthresh|in[7:0]; else
	if (r_control[2]) r_vs_intthresh <= r_vs_intthresh&~in[7:0]; else r_vs_intthresh <= in[7:0];

	always @(posedge clk)
	if (reset) r_s_intthresh <= 0; else
	if (csr_write && r_immed[11:0] == 12'h14a)
	if (r_control[1]) r_s_intthresh <= r_s_intthresh|in[7:0]; else
	if (r_control[2]) r_s_intthresh <= r_s_intthresh&~in[7:0]; else r_s_intthresh <= in[7:0];

	always @(posedge clk)
	if (reset) r_u_intthresh <= 0; else
	if (csr_write && r_immed[11:0] == 12'h04a)
	if (r_control[1]) r_u_intthresh <= r_u_intthresh|in[7:0]; else
	if (r_control[2]) r_u_intthresh <= r_u_intthresh&~in[7:0]; else r_u_intthresh <= in[7:0];

	reg [RV-1:0]r_u_mtval, r_s_mtval, r_m_mtval;

	always @(posedge clk)
	if (trap_m) r_m_mtval <= tval; else
	if (csr_write && r_immed[11:0] == 12'h343)
	if (r_control[1]) r_m_mtval <= r_m_mtval|in; else
	if (r_control[2]) r_m_mtval <= r_m_mtval&~in; else r_m_mtval <= in;

	always @(posedge clk)
	if (trap_s) r_s_mtval <= tval; else
	if (csr_write && r_immed[11:0] == 12'h143)
	if (r_control[1]) r_s_mtval <= r_s_mtval|in; else
	if (r_control[2]) r_s_mtval <= r_s_mtval&~in; else r_s_mtval <= in;

	always @(posedge clk)
	if (trap_u) r_u_mtval <= tval; else
	if (csr_write && r_immed[11:0] == 12'h043)
	if (r_control[1]) r_u_mtval <= r_u_mtval|in; else
	if (r_control[2]) r_u_mtval <= r_u_mtval&~in; else r_u_mtval <= in;

	

	
	reg [NINTERRUPTS-1:12]m_ext, h_ext, s_ext, u_ext;
	reg		m_eip, s_eip, h_eip, u_eip;				// external interrupt pending
	reg		m_tip, s_tip, h_tip, u_tip;				// timer interrupt pending
	reg		m_sip, s_sip, h_sip, u_sip;				// software interrupt pending

	
	reg [NINTERRUPTS-1:12]r_m_exte, r_vs_exte, r_s_exte, r_u_exte;
	reg		r_m_eie, r_s_eie, r_vs_eie, r_u_eie;		// external interrupt enable
	reg		r_m_tie, r_s_tie, r_vs_tie, r_u_tie;		// timer interrupt enables
	reg		r_m_sie, r_s_sie, r_vs_sie, r_u_sie;		// software interrupt enables

	always @(posedge clk)
	if (reset) r_m_exte <= 0; else
	if (csr_write && !clic_m_enable && r_immed[11:0] == 12'h304)
	if (r_control[1]) r_m_exte <= r_m_exte|in[NINTERRUPTS-1:12]; else
	if (r_control[2]) r_m_exte <= r_m_exte&~in[NINTERRUPTS-1:12]; else r_m_exte <= in[NINTERRUPTS-1:12];

	always @(posedge clk)
	if (reset) r_s_exte <= 0; else
	if (csr_write && !clic_s_enable && (r_immed[11:0] == 12'h104))
	if (r_control[1]) r_s_exte <= r_s_exte|in[NINTERRUPTS-1:12]; else
	if (r_control[2]) r_s_exte <= r_s_exte&~in[NINTERRUPTS-1:12]; else r_s_exte <= in[NINTERRUPTS-1:12];

	always @(posedge clk)
	if (reset) r_vs_exte <= 0; else
	if (csr_write && !clic_h_enable && (r_immed[11:0] == (r_v?12'h104:12'h204)))
	if (r_control[1]) r_vs_exte <= r_vs_exte|in[NINTERRUPTS-1:12]; else
	if (r_control[2]) r_vs_exte <= r_vs_exte&~in[NINTERRUPTS-1:12]; else r_vs_exte <= in[NINTERRUPTS-1:12];

	always @(posedge clk)
	if (reset) r_u_exte <= 0; else
	if (csr_write && !clic_u_enable && (r_immed[11:0] == 12'h004))
	if (r_control[1]) r_u_exte <= r_u_exte|in[NINTERRUPTS-1:12]; else
	if (r_control[2]) r_u_exte <= r_u_exte&~in[NINTERRUPTS-1:12]; else r_u_exte <= in[NINTERRUPTS-1:12];

	always @(posedge clk)
	if (reset) r_m_eie <= 0; else
	if (csr_write && !clic_m_enable && r_immed[11:0] == 12'h304)
	if (r_control[1]) r_m_eie <= r_m_eie|in[11]; else
	if (r_control[2]) r_m_eie <= r_m_eie&~in[11]; else r_m_eie <= in[11];

	always @(posedge clk)
	if (reset) r_s_eie <= 0; else
	if (csr_write && !clic_s_enable && (r_immed[11:0] == 12'h304 || r_immed[11:0] == 12'h104))
	if (r_control[1]) r_s_eie <= r_s_eie|in[9]; else
	if (r_control[2]) r_s_eie <= r_s_eie&~in[9]; else r_s_eie <= in[9];

	always @(posedge clk)
	if (reset) r_vs_eie <= 0; else
	if (csr_write && !clic_h_enable && (r_immed[11:0] == (r_v?12'h104:12'h204)))
	if (r_control[1]) r_vs_eie <= r_vs_eie|in[9]; else
	if (r_control[2]) r_vs_eie <= r_vs_eie&~in[9]; else r_vs_eie <= in[9];

	always @(posedge clk)
	if (reset) r_u_eie <= 0; else
	if (csr_write && !clic_u_enable && (r_immed[11:0] == 12'h304 || (!r_v && r_immed[11:0] == 12'h104) || r_immed[11:0] == 12'h004))
	if (r_control[1]) r_u_eie <= r_u_eie|in[8]; else
	if (r_control[2]) r_u_eie <= r_u_eie&~in[8]; else r_u_eie <= in[8];

	always @(posedge clk)
	if (reset) r_m_tie <= 0; else
	if (csr_write && !clic_m_enable && r_immed[11:0] == 12'h304)
	if (r_control[1]) r_m_tie <= r_m_tie|in[7]; else
	if (r_control[2]) r_m_tie <= r_m_tie&~in[7]; else r_m_tie <= in[7];

	always @(posedge clk)
	if (reset) r_s_tie <= 0; else
	if (csr_write && !clic_s_enable && (r_immed[11:0] == 12'h304 || (!r_v && r_immed[11:0] == 12'h104)))
	if (r_control[1]) r_s_tie <= r_s_tie|in[5]; else
	if (r_control[2]) r_s_tie <= r_s_tie&~in[5]; else r_s_tie <= in[5];

	always @(posedge clk)
	if (reset) r_vs_tie <= 0; else
	if (csr_write && !clic_h_enable && (r_immed[11:0] == (r_v?12'h104:12'h204)))
	if (r_control[1]) r_vs_tie <= r_vs_tie|in[5]; else
	if (r_control[2]) r_vs_tie <= r_vs_tie&~in[5]; else r_vs_tie <= in[5];

	always @(posedge clk)
	if (reset) r_u_tie <= 0; else
	if (csr_write && !clic_u_enable && (r_immed[11:0] == 12'h304 || r_immed[11:0] == 12'h104 || r_immed[11:0] == 12'h004))
	if (r_control[1]) r_u_tie <= r_u_tie|in[4]; else
	if (r_control[2]) r_u_tie <= r_u_tie&~in[4]; else r_u_tie <= in[4];

	always @(posedge clk)
	if (reset) r_m_sie <= 0; else
	if (csr_write && !clic_s_enable && r_immed[11:0] == 12'h304)
	if (r_control[1]) r_m_sie <= r_m_sie|in[3]; else
	if (r_control[2]) r_m_sie <= r_m_sie&~in[3]; else r_m_sie <= in[3];

	always @(posedge clk)
	if (reset) r_s_sie <= 0; else
	if (csr_write && !clic_s_enable && (r_immed[11:0] == 12'h304 || (!r_v && r_immed[11:0] == 12'h104)))
	if (r_control[1]) r_s_sie <= r_s_sie|in[1]; else
	if (r_control[2]) r_s_sie <= r_s_sie&~in[1]; else r_s_sie <= in[1];

	always @(posedge clk)
	if (reset) r_vs_sie <= 0; else
	if (csr_write && !clic_h_enable && (r_immed[11:0] == (r_v?12'h104:12'h204)))
	if (r_control[1]) r_vs_sie <= r_vs_sie|in[1]; else
	if (r_control[2]) r_vs_sie <= r_vs_sie&~in[1]; else r_vs_sie <= in[1];

	always @(posedge clk)
	if (reset) r_u_sie <= 0; else
	if (csr_write && !clic_u_enable && (r_immed[11:0] == 12'h304 || r_immed[11:0] == 12'h104 || r_immed[11:0] == 12'h004))
	if (r_control[1]) r_u_sie <= r_u_sie|in[0]; else
	if (r_control[2]) r_u_sie <= r_u_sie&~in[0]; else r_u_sie <= in[0];


	reg		r_h_ir, r_h_tm, r_h_cy;			

	always @(posedge clk)
	if (reset) r_h_ir <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h606))
	if (r_control[1]) r_h_ir <= r_h_ir|in[2]; else
	if (r_control[2]) r_h_ir <= r_h_ir&~in[2]; else r_h_ir <= in[2];

	always @(posedge clk)
	if (reset) r_h_tm <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h606))
	if (r_control[1]) r_h_tm <= r_h_tm|in[1]; else
	if (r_control[2]) r_h_tm <= r_h_tm&~in[1]; else r_h_tm <= in[1];

	always @(posedge clk)
	if (reset) r_h_cy <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h606))
	if (r_control[1]) r_h_cy <= r_h_cy|in[0]; else
	if (r_control[2]) r_h_cy <= r_h_cy&~in[0]; else r_h_cy <= in[0];

	reg		r_s_ir, r_s_tm, r_s_cy;			// sup counter timer enables for user mode

	always @(posedge clk)
	if (reset) r_s_ir <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h106))
	if (r_control[1]) r_s_ir <= r_s_ir|in[2]; else
	if (r_control[2]) r_s_ir <= r_s_ir&~in[2]; else r_s_ir <= in[2];

	always @(posedge clk)
	if (reset) r_s_tm <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h106))
	if (r_control[1]) r_s_tm <= r_s_tm|in[1]; else
	if (r_control[2]) r_s_tm <= r_s_tm&~in[1]; else r_s_tm <= in[1];

	always @(posedge clk)
	if (reset) r_s_cy <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h106))
	if (r_control[1]) r_s_cy <= r_s_cy|in[0]; else
	if (r_control[2]) r_s_cy <= r_s_cy&~in[0]; else r_s_cy <= in[0];

	reg		r_m_ir, r_m_tm, r_m_cy;			// mach counter timer enables for sup/user mode

	always @(posedge clk)
	if (reset) r_m_ir <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h306))
	if (r_control[1]) r_m_ir <= r_m_ir|in[2]; else
	if (r_control[2]) r_m_ir <= r_m_ir&~in[2]; else r_m_ir <= in[2];

	always @(posedge clk)
	if (reset) r_m_tm <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h306))
	if (r_control[1]) r_m_tm <= r_m_tm|in[1]; else
	if (r_control[2]) r_m_tm <= r_m_tm&~in[1]; else r_m_tm <= in[1];

	always @(posedge clk)
	if (reset) r_m_cy <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h306))
	if (r_control[1]) r_m_cy <= r_m_cy|in[0]; else
	if (r_control[2]) r_m_cy <= r_m_cy&~in[0]; else r_m_cy <= in[0];

	assign timer_prot = {r_m_ir, r_m_tm, r_m_cy, r_s_ir, r_s_tm, r_s_cy};



	reg		r_i_ir, r_i_cy;			// mach counter timer inhibits

	always @(posedge clk)
	if (reset) r_i_ir <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h320))
	if (r_control[1]) r_i_ir <= r_i_ir|in[2]; else
	if (r_control[2]) r_i_ir <= r_i_ir&~in[2]; else r_i_ir <= in[2];

	always @(posedge clk)
	if (reset) r_i_cy <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h320))
	if (r_control[1]) r_i_cy <= r_i_cy|in[0]; else
	if (r_control[2]) r_i_cy <= r_i_cy&~in[0]; else r_i_cy <= in[0];


	reg	 [3:0]r_s_vm_mode, r_vs_vm_mode, r_h_vm_mode;		// TLB r_control
	reg  [15:0]r_s_asid, r_vs_asid;
	reg  [15:0]r_h_asid;
	reg  [43:0]r_s_ppn, r_vs_ppn, r_h_ppn;
	assign sup_ppn = r_s_ppn;	// do hyper stuff here
	assign sup_vm_mode = r_s_vm_mode;
	wire hh = HART;
	assign sup_asid = r_unified_asid?r_s_asid:{hh, r_s_asid[14:0]};

	always @(posedge clk)
	if (reset) begin
		r_s_vm_mode <= 4'b0001; 
		r_s_asid <= 0; 
	end else 
	if (csr_write && (!r_v && r_immed[11:0] == 12'h180)) 
	if (!rv32 && (in[63:60]==0 || in[63:60] == 8 || in[63:60] == 9)) begin 
		r_s_vm_mode <= in[63:60]==0?4'b0001:in[63:60]==8?4'b0100:4'b1000;
		r_s_asid <= in[59:44]; 
		r_s_ppn <= in[43:0];
		// something to poke TLB world
	end else
	if (rv32) begin 
		r_s_vm_mode <= {2'b0,in[31],1'b0}; 
		r_s_asid <= {7'b0, in[30:22]}; 
		r_s_ppn <= in[21:0];
		// something to poke TLB world
	end

	always @(posedge clk)
	if (reset) begin
		r_vs_vm_mode <= 0; 
		r_vs_asid <= 0; 
	end else 
	if (csr_write && (r_immed[11:0] == (r_v?12'h180:12'h280)))
	if (!rv32 && (in[63:60]==0 || in[63:60] == 8 || in[63:60] == 9)) begin 
		r_vs_vm_mode <= in[63:60]==0?4'b0001:in[63:60]==8?4'b0100:4'b1000;
		r_vs_asid <= in[59:44]; 
		r_vs_ppn <= in[43:0];
		// something to poke TLB world
	end else
	if (rv32) begin 
		r_vs_vm_mode <= {2'b0,in[31], 1'b0}; 
		r_vs_asid <= {7'b0, in[30:22]}; 
		r_vs_ppn <= in[21:0];
		// something to poke TLB world
	end

	always @(posedge clk)
	if (reset) begin
		r_h_vm_mode <= 0; 
		r_h_asid <= 0;
	end else // something for rv32
	if (csr_write && (r_immed[11:0] == 12'h680))
	if (!rv32 && (in[63:60]==0 || in[63:60] == 8 || in[63:60] == 9)) begin 
		r_h_vm_mode <= in[63:60]==0?4'b0001:in[63:60]==8?4'b0100:4'b1000;
		r_h_asid <= in[59:44]; 
		r_h_ppn <= in[43:0];
		// something to poke TLB world
	end else
	if (rv32) begin 
		r_h_vm_mode <= {2'b0,in[31], 1'b0}; 
		r_h_asid <= {7'b0, in[30:22]}; 
		r_h_ppn <= in[21:0];
		// something to poke TLB world
	end


	reg [NINTERRUPTS-1:12]r_m_deleg_ext, r_s_deleg_ext;
	reg			r_m_deleg_mei, r_m_deleg_sei, r_m_deleg_uei;
	reg			r_m_deleg_mti, r_m_deleg_sti, r_m_deleg_uti;
	reg			r_m_deleg_msi, r_m_deleg_ssi, r_m_deleg_usi;

	reg			r_s_deleg_mei, r_s_deleg_sei, r_s_deleg_uei;
	reg			r_s_deleg_mti, r_s_deleg_sti, r_s_deleg_uti;
	reg			r_s_deleg_msi, r_s_deleg_ssi, r_s_deleg_usi;

	always @(posedge clk)
	if (reset) r_m_deleg_ext <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_ext <= r_m_deleg_ext|in[NINTERRUPTS-1:12]; else
	if (r_control[2]) r_m_deleg_ext <= r_m_deleg_ext&~in[NINTERRUPTS-1:12]; else r_m_deleg_ext <= in[NINTERRUPTS-1:12];

	always @(posedge clk)
	if (reset) r_s_deleg_ext <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_ext <= (r_s_deleg_ext|in[NINTERRUPTS-1:12])&r_m_deleg_ext; else
	if (r_control[2]) r_s_deleg_ext <= (r_s_deleg_ext&~in[NINTERRUPTS-1:12])&r_m_deleg_ext; else r_s_deleg_ext <= in[NINTERRUPTS-1:12]&r_m_deleg_ext;

	always @(posedge clk)
	if (reset) r_s_deleg_mei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_mei <= (r_s_deleg_mei|in[11])&(r_m_deleg_mei&(~r_v|r_h_deleg_mei)); else
	if (r_control[2]) r_s_deleg_mei <= (r_s_deleg_mei&~in[11])&(r_m_deleg_mei&(~r_v|r_h_deleg_mei)); else r_s_deleg_mei <= in[11]&(r_m_deleg_mei&(~r_v|r_h_deleg_mei));

	always @(posedge clk)
	if (reset) r_m_deleg_mei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_mei <= r_m_deleg_mei|in[11]; else
	if (r_control[2]) r_m_deleg_mei <= r_m_deleg_mei&~in[11]; else r_m_deleg_mei <= in[11];

	always @(posedge clk)
	if (reset) r_s_deleg_uei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_uei <= (r_s_deleg_uei|in[8])&(r_m_deleg_uei&(~r_v|r_h_deleg_uei)); else
	if (r_control[2]) r_s_deleg_uei <= (r_s_deleg_uei&~in[8])&(r_m_deleg_uei&(~r_v|r_h_deleg_uei)); else r_s_deleg_uei <= in[8]&(r_m_deleg_uei&(~r_v|r_h_deleg_uei));

	always @(posedge clk)
	if (reset) r_m_deleg_uei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_uei <= r_m_deleg_uei|in[8]; else
	if (r_control[2]) r_m_deleg_uei <= r_m_deleg_uei&~in[8]; else r_m_deleg_uei <= in[8];

	always @(posedge clk)
	if (reset) r_s_deleg_sei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_sei <= (r_s_deleg_sei|in[9])&(r_m_deleg_sei&(~r_v|r_h_deleg_sei)); else
	if (r_control[2]) r_s_deleg_sei <= (r_s_deleg_sei&~in[9])&(r_m_deleg_sei&(~r_v|r_h_deleg_sei)); else r_s_deleg_sei <= in[9]&(r_m_deleg_sei&(~r_v|r_h_deleg_sei));

	always @(posedge clk)
	if (reset) r_m_deleg_sei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_sei <= r_m_deleg_sei|in[9]; else
	if (r_control[2]) r_m_deleg_sei <= r_m_deleg_sei&~in[9]; else r_m_deleg_sei <= in[9];

	always @(posedge clk)
	if (reset) r_m_deleg_mti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_mti <= r_m_deleg_mti|in[7]; else
	if (r_control[2]) r_m_deleg_mti <= r_m_deleg_mti&~in[7]; else r_m_deleg_mti <= in[7];

	always @(posedge clk)
	if (reset) r_s_deleg_mti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_mti <= (r_s_deleg_mti|in[7])&(r_m_deleg_mti&(~r_v|r_h_deleg_mti)); else
	if (r_control[2]) r_s_deleg_mti <= (r_s_deleg_mti&~in[7])&(r_m_deleg_mti&(~r_v|r_h_deleg_mti)); else r_s_deleg_mti <= in[7]&(r_m_deleg_mti&(~r_v|r_h_deleg_mti));

	always @(posedge clk)
	if (reset) r_s_deleg_sti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_sti <= (r_s_deleg_sti|in[5])&(r_m_deleg_sti&(~r_v|r_h_deleg_sti)); else
	if (r_control[2]) r_s_deleg_sti <= (r_s_deleg_sti&~in[5])&(r_m_deleg_sti&(~r_v|r_h_deleg_sti)); else r_s_deleg_sti <= in[5]&(r_m_deleg_sti&(~r_v|r_h_deleg_sti));

	always @(posedge clk)
	if (reset) r_m_deleg_sti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_sti <= r_m_deleg_sti|in[5]; else
	if (r_control[2]) r_m_deleg_sti <= r_m_deleg_sti&~in[5]; else r_m_deleg_sti <= in[5];

	always @(posedge clk)
	if (reset) r_s_deleg_uti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_uti <= (r_s_deleg_uti|in[4])&(r_m_deleg_uti&(~r_v|r_h_deleg_uti)); else
	if (r_control[2]) r_s_deleg_uti <= (r_s_deleg_uti&~in[4])&(r_m_deleg_uti&(~r_v|r_h_deleg_uti)); else r_s_deleg_uti <= in[4]&(r_m_deleg_uti&(~r_v|r_h_deleg_uti));

	always @(posedge clk)
	if (reset) r_m_deleg_uti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_uti <= r_m_deleg_uti|in[4]; else
	if (r_control[2]) r_m_deleg_uti <= r_m_deleg_uti&~in[4]; else r_m_deleg_uti <= in[4];

	always @(posedge clk)
	if (reset) r_m_deleg_msi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_msi <= r_m_deleg_msi|in[3]; else
	if (r_control[2]) r_m_deleg_msi <= r_m_deleg_msi&~in[3]; else r_m_deleg_msi <= in[3];

	always @(posedge clk)
	if (reset) r_s_deleg_msi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_msi <= (r_s_deleg_msi|in[3])&(r_m_deleg_msi&(~r_v|r_h_deleg_msi)); else
	if (r_control[2]) r_s_deleg_msi <= (r_s_deleg_msi&~in[3])&(r_m_deleg_msi&(~r_v|r_h_deleg_msi)); else r_s_deleg_msi <= in[3]&(r_m_deleg_msi&(~r_v|r_h_deleg_msi));

	always @(posedge clk)
	if (reset) r_s_deleg_ssi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_ssi <= (r_s_deleg_ssi|in[1])&(r_m_deleg_ssi&(~r_v|r_h_deleg_ssi)); else
	if (r_control[2]) r_s_deleg_ssi <= (r_s_deleg_ssi&~in[1])&(r_m_deleg_ssi&(~r_v|r_h_deleg_ssi)); else r_s_deleg_ssi <= in[1]&(r_m_deleg_ssi&(~r_v|r_h_deleg_ssi));

	always @(posedge clk)
	if (reset) r_m_deleg_ssi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_ssi <= r_m_deleg_ssi|in[1]; else
	if (r_control[2]) r_m_deleg_ssi <= r_m_deleg_ssi&~in[1]; else r_m_deleg_ssi <= in[1];

	always @(posedge clk)
	if (reset) r_s_deleg_usi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h103))
	if (r_control[1]) r_s_deleg_usi <= (r_s_deleg_usi|in[0])&(r_m_deleg_usi&(~r_v|r_h_deleg_usi)); else
	if (r_control[2]) r_s_deleg_usi <= (r_s_deleg_usi&~in[0])&(r_m_deleg_usi&(~r_v|r_h_deleg_usi)); else r_s_deleg_usi <= in[0]&(r_m_deleg_usi&(~r_v|r_h_deleg_usi));

	always @(posedge clk)
	if (reset) r_m_deleg_usi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h303))
	if (r_control[1]) r_m_deleg_usi <= r_m_deleg_usi|in[0]; else
	if (r_control[2]) r_m_deleg_usi <= r_m_deleg_usi&~in[0]; else r_m_deleg_usi <= in[0];


	reg [NINTERRUPTS-1:12]r_h_deleg_ext;
	reg			r_h_deleg_mei, r_h_deleg_sei, r_h_deleg_uei;
	reg			r_h_deleg_mti, r_h_deleg_sti, r_h_deleg_uti;
	reg			r_h_deleg_msi, r_h_deleg_ssi, r_h_deleg_usi;

	always @(posedge clk)
	if (reset) r_h_deleg_ext <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_ext <= r_h_deleg_ext|in[NINTERRUPTS-1:12]&r_m_deleg_ext; else
	if (r_control[2]) r_h_deleg_ext <= r_h_deleg_ext&~in[NINTERRUPTS-1:12]&r_m_deleg_ext; else r_h_deleg_ext <= in[NINTERRUPTS-1:12]&r_m_deleg_ext;

	always @(posedge clk)
	if (reset) r_h_deleg_mei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_mei <= (r_h_deleg_mei|in[11])&r_m_deleg_mei; else
	if (r_control[2]) r_h_deleg_mei <= (r_h_deleg_mei&~in[11])&r_m_deleg_mei; else r_h_deleg_mei <= in[11]&r_m_deleg_mei;

	always @(posedge clk)
	if (reset) r_h_deleg_sei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_sei <= (r_h_deleg_sei|in[9])&r_m_deleg_sei; else
	if (r_control[2]) r_h_deleg_sei <= (r_h_deleg_sei&~in[9])&r_m_deleg_sei; else r_h_deleg_sei <= in[9]&r_m_deleg_sei;

	always @(posedge clk)
	if (reset) r_h_deleg_uei <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_uei <= (r_h_deleg_uei|in[8])&r_m_deleg_uei; else
	if (r_control[2]) r_h_deleg_uei <= (r_h_deleg_uei&~in[8])&r_m_deleg_uei; else r_h_deleg_uei <= in[8]&r_m_deleg_uei;

	always @(posedge clk)
	if (reset) r_h_deleg_mti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_mti <= (r_h_deleg_mti|in[7])&r_m_deleg_mti; else
	if (r_control[2]) r_h_deleg_mti <= (r_h_deleg_mti&~in[7])&r_m_deleg_mti; else r_h_deleg_mti <= in[7]&r_m_deleg_mti;

	always @(posedge clk)
	if (reset) r_h_deleg_sti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_sti <= (r_h_deleg_sti|in[5])&r_m_deleg_sti; else
	if (r_control[2]) r_h_deleg_sti <= (r_h_deleg_sti&~in[5])&r_m_deleg_sti; else r_h_deleg_sti <= in[5]&r_m_deleg_sti;

	always @(posedge clk)
	if (reset) r_h_deleg_uti <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_uti <= (r_h_deleg_uti|in[4])&r_m_deleg_uti; else
	if (r_control[2]) r_h_deleg_uti <= (r_h_deleg_uti&~in[4])&r_m_deleg_uti; else r_h_deleg_uti <= in[4]&r_m_deleg_uti;

	always @(posedge clk)
	if (reset) r_h_deleg_msi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_msi <= (r_h_deleg_msi|in[3])&r_m_deleg_msi; else
	if (r_control[2]) r_h_deleg_msi <= (r_h_deleg_msi&~in[3])&r_m_deleg_msi; else r_h_deleg_msi <= in[3]&r_m_deleg_msi;

	always @(posedge clk)
	if (reset) r_h_deleg_ssi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_ssi <= (r_h_deleg_ssi|in[1])&r_m_deleg_ssi; else
	if (r_control[2]) r_h_deleg_ssi <= (r_h_deleg_ssi&~in[1])&r_m_deleg_ssi; else r_h_deleg_ssi <= in[1]&r_m_deleg_ssi;

	always @(posedge clk)
	if (reset) r_h_deleg_usi <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h603))
	if (r_control[1]) r_h_deleg_usi <= (r_h_deleg_usi|in[0])&r_m_deleg_usi; else
	if (r_control[2]) r_h_deleg_usi <= (r_h_deleg_usi&~in[0])&r_h_deleg_usi; else r_h_deleg_usi <= in[0]&r_m_deleg_usi;

	reg			r_m_deleg_storeamo_pf, r_m_deleg_load_pf, r_m_deleg_ins_pf, r_m_deleg_env_s, r_m_deleg_env_u,
				r_m_deleg_storeamo_access, r_m_deleg_storeamo_align, r_m_deleg_load_access,
				r_m_deleg_load_align, r_m_deleg_break, r_m_deleg_illegal_inst,
				r_m_deleg_inst_access, r_m_deleg_inst_align;
	assign m_trap_deleg = {r_m_deleg_storeamo_pf, 1'bx, r_m_deleg_load_pf, r_m_deleg_ins_pf, 1'b0, 1'bx, r_m_deleg_env_s, r_m_deleg_env_u, r_m_deleg_storeamo_access, r_m_deleg_storeamo_align, r_m_deleg_load_access, r_m_deleg_storeamo_access, r_m_deleg_break, r_m_deleg_illegal_inst, r_m_deleg_inst_access, r_m_deleg_inst_align};

	always @(posedge clk)
	if (reset) r_m_deleg_storeamo_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_storeamo_pf <= r_m_deleg_storeamo_pf|in[15]; else
	if (r_control[2]) r_m_deleg_storeamo_pf <= r_m_deleg_storeamo_pf&~in[15]; else r_m_deleg_storeamo_pf <= in[15];

	always @(posedge clk)
	if (reset) r_m_deleg_load_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_load_pf <= r_m_deleg_load_pf|in[13]; else
	if (r_control[2]) r_m_deleg_load_pf <= r_m_deleg_load_pf&~in[13]; else r_m_deleg_load_pf <= in[13];

	always @(posedge clk)
	if (reset) r_m_deleg_ins_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_ins_pf <= r_m_deleg_ins_pf|in[12]; else
	if (r_control[2]) r_m_deleg_ins_pf <= r_m_deleg_ins_pf&~in[12]; else r_m_deleg_ins_pf <= in[12];

	always @(posedge clk)
	if (reset) r_m_deleg_env_s <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_env_s <= r_m_deleg_env_s|in[9]; else
	if (r_control[2]) r_m_deleg_env_s <= r_m_deleg_env_s&~in[9]; else r_m_deleg_env_s <= in[9];

	always @(posedge clk)
	if (reset) r_m_deleg_env_u <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_env_u <= r_m_deleg_env_u|in[8]; else
	if (r_control[2]) r_m_deleg_env_u <= r_m_deleg_env_u&~in[8]; else r_m_deleg_env_u <= in[8];

	always @(posedge clk)
	if (reset) r_m_deleg_storeamo_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_storeamo_access <= r_m_deleg_storeamo_access|in[7]; else
	if (r_control[2]) r_m_deleg_storeamo_access <= r_m_deleg_storeamo_access&~in[7]; else r_m_deleg_storeamo_access <= in[7];

	always @(posedge clk)
	if (reset) r_m_deleg_storeamo_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_storeamo_align <= r_m_deleg_storeamo_align|in[6]; else
	if (r_control[2]) r_m_deleg_storeamo_align <= r_m_deleg_storeamo_align&~in[6]; else r_m_deleg_storeamo_align <= in[6];

	always @(posedge clk)
	if (reset) r_m_deleg_load_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_load_access <= r_m_deleg_load_access|in[5]; else
	if (r_control[2]) r_m_deleg_load_access <= r_m_deleg_load_access&~in[5]; else r_m_deleg_load_access <= in[5];

	always @(posedge clk)
	if (reset) r_m_deleg_load_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_load_align <= r_m_deleg_load_align|in[4]; else
	if (r_control[2]) r_m_deleg_load_align <= r_m_deleg_load_align&~in[4]; else r_m_deleg_load_align <= in[4];

	always @(posedge clk)
	if (reset) r_m_deleg_break <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_break <= r_m_deleg_break|in[3]; else
	if (r_control[2]) r_m_deleg_break <= r_m_deleg_break&~in[3]; else r_m_deleg_break <= in[3];

	always @(posedge clk)
	if (reset) r_m_deleg_illegal_inst <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_illegal_inst <= r_m_deleg_illegal_inst|in[2]; else
	if (r_control[2]) r_m_deleg_illegal_inst <= r_m_deleg_illegal_inst&~in[2]; else r_m_deleg_illegal_inst <= in[2];

	always @(posedge clk)
	if (reset) r_m_deleg_inst_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_inst_access <= r_m_deleg_inst_access|in[1]; else
	if (r_control[2]) r_m_deleg_inst_access <= r_m_deleg_inst_access&~in[1]; else r_m_deleg_inst_access <= in[1];

	always @(posedge clk)
	if (reset) r_m_deleg_inst_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h302))
	if (r_control[1]) r_m_deleg_inst_align <= r_m_deleg_inst_align|in[0]; else
	if (r_control[2]) r_m_deleg_inst_align <= r_m_deleg_inst_align&~in[0]; else r_m_deleg_inst_align <= in[0];

	reg			r_h_deleg_storeamo_pf, r_h_deleg_load_pf, r_h_deleg_ins_pf, r_h_deleg_env_s, r_h_deleg_env_u,
				r_h_deleg_storeamo_access, r_h_deleg_storeamo_align, r_h_deleg_load_access,
				r_h_deleg_load_align, r_h_deleg_break, r_h_deleg_illegal_inst,
				r_h_deleg_inst_access, r_h_deleg_inst_align;
	assign h_trap_deleg = {r_h_deleg_storeamo_pf, 1'bx, r_h_deleg_load_pf, r_h_deleg_ins_pf, 2'bx, r_h_deleg_env_s, r_h_deleg_env_u, r_h_deleg_storeamo_access, r_h_deleg_storeamo_align, r_h_deleg_load_access, r_h_deleg_storeamo_access, r_h_deleg_break, r_h_deleg_illegal_inst, r_h_deleg_inst_access, r_h_deleg_inst_align};

	always @(posedge clk)
	if (reset) r_h_deleg_storeamo_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_storeamo_pf <= (r_h_deleg_storeamo_pf|in[15])&r_m_deleg_storeamo_pf; else
	if (r_control[2]) r_h_deleg_storeamo_pf <= (r_h_deleg_storeamo_pf&~in[15])&r_m_deleg_storeamo_pf; else r_h_deleg_storeamo_pf <= in[15]&r_m_deleg_storeamo_pf;

	always @(posedge clk)
	if (reset) r_h_deleg_load_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_load_pf <= (r_h_deleg_load_pf|in[13])&r_m_deleg_load_pf; else
	if (r_control[2]) r_h_deleg_load_pf <= (r_h_deleg_load_pf&~in[13])&r_m_deleg_load_pf; else r_h_deleg_load_pf <= in[13]&r_m_deleg_load_pf;

	always @(posedge clk)
	if (reset) r_h_deleg_ins_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_ins_pf <= (r_h_deleg_ins_pf|in[12])&r_m_deleg_ins_pf; else
	if (r_control[2]) r_h_deleg_ins_pf <= (r_h_deleg_ins_pf&~in[12])&r_m_deleg_ins_pf; else r_h_deleg_ins_pf <= in[12]&r_m_deleg_ins_pf;

	always @(posedge clk)
	if (reset) r_h_deleg_env_s <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_env_s <= (r_h_deleg_env_s|in[9])&r_m_deleg_env_s; else
	if (r_control[2]) r_h_deleg_env_s <= (r_h_deleg_env_s&~in[9])&r_m_deleg_env_s; else r_h_deleg_env_s <= in[9]&r_m_deleg_env_s;

	always @(posedge clk)
	if (reset) r_h_deleg_env_u <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_env_u <= (r_h_deleg_env_u|in[8])&r_m_deleg_env_u; else
	if (r_control[2]) r_h_deleg_env_u <= (r_h_deleg_env_u&~in[8])&r_m_deleg_env_u; else r_h_deleg_env_u <= in[8]&r_m_deleg_env_u;

	always @(posedge clk)
	if (reset) r_h_deleg_storeamo_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_storeamo_access <= (r_h_deleg_storeamo_access|in[7])&r_m_deleg_storeamo_access; else
	if (r_control[2]) r_h_deleg_storeamo_access <= (r_h_deleg_storeamo_access&~in[7])&r_m_deleg_storeamo_access; else r_h_deleg_storeamo_access <= in[7]&r_m_deleg_storeamo_access;

	always @(posedge clk)
	if (reset) r_h_deleg_storeamo_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_storeamo_align <= (r_h_deleg_storeamo_align|in[6])&r_m_deleg_storeamo_align; else
	if (r_control[2]) r_h_deleg_storeamo_align <= (r_h_deleg_storeamo_align&~in[6])&r_m_deleg_storeamo_align; else r_h_deleg_storeamo_align <= in[6]&r_m_deleg_storeamo_align;

	always @(posedge clk)
	if (reset) r_h_deleg_load_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_load_access <= (r_h_deleg_load_access|in[5])&r_m_deleg_load_access; else
	if (r_control[2]) r_h_deleg_load_access <= (r_h_deleg_load_access&~in[5])&r_m_deleg_load_access; else r_h_deleg_load_access <= in[5]&r_m_deleg_load_access;

	always @(posedge clk)
	if (reset) r_h_deleg_load_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_load_align <= (r_h_deleg_load_align|in[4])&r_m_deleg_load_align; else
	if (r_control[2]) r_h_deleg_load_align <= (r_h_deleg_load_align&~in[4])&r_m_deleg_load_align; else r_h_deleg_load_align <= in[4]&r_m_deleg_load_align;

	always @(posedge clk)
	if (reset) r_h_deleg_break <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_break <= (r_h_deleg_break|in[3])&r_m_deleg_break; else
	if (r_control[2]) r_h_deleg_break <= (r_h_deleg_break&~in[3])&r_m_deleg_break; else r_h_deleg_break <= in[3]&r_m_deleg_break;

	always @(posedge clk)
	if (reset) r_h_deleg_illegal_inst <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_illegal_inst <= (r_h_deleg_illegal_inst|in[2])&r_m_deleg_illegal_inst; else
	if (r_control[2]) r_h_deleg_illegal_inst <= (r_h_deleg_illegal_inst&~in[2])&r_m_deleg_illegal_inst; else r_h_deleg_illegal_inst <= in[2]&r_m_deleg_illegal_inst;

	always @(posedge clk)
	if (reset) r_h_deleg_inst_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_inst_access <= (r_h_deleg_inst_access|in[1])&r_m_deleg_inst_access; else
	if (r_control[2]) r_h_deleg_inst_access <= (r_h_deleg_inst_access&~in[1])&r_m_deleg_inst_access; else r_h_deleg_inst_access <= in[1]&r_m_deleg_inst_access;

	always @(posedge clk)
	if (reset) r_h_deleg_inst_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h602))
	if (r_control[1]) r_h_deleg_inst_align <= (r_h_deleg_inst_align|in[0])&r_m_deleg_inst_align; else
	if (r_control[2]) r_h_deleg_inst_align <= (r_h_deleg_inst_align&~in[0])&r_m_deleg_inst_align; else r_h_deleg_inst_align <= in[0]&r_m_deleg_inst_align;

	reg			r_s_deleg_storeamo_pf, r_s_deleg_load_pf, r_s_deleg_ins_pf, r_s_deleg_env_u,
				r_s_deleg_storeamo_access, r_s_deleg_storeamo_align, r_s_deleg_load_access,
				r_s_deleg_load_align, r_s_deleg_break, r_s_deleg_illegal_inst,
				r_s_deleg_inst_access, r_s_deleg_inst_align;
	assign s_trap_deleg = {r_s_deleg_storeamo_pf, 1'bx, r_s_deleg_load_pf, r_s_deleg_ins_pf, 3'b0x0, r_s_deleg_env_u, r_s_deleg_storeamo_access, r_s_deleg_storeamo_align, r_s_deleg_load_access, r_s_deleg_storeamo_access, r_s_deleg_break, r_s_deleg_illegal_inst, r_s_deleg_inst_access, r_s_deleg_inst_align};

	always @(posedge clk)
	if (reset) r_s_deleg_storeamo_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_storeamo_pf <= (r_s_deleg_storeamo_pf|in[15])&(r_m_deleg_storeamo_pf&(~r_v|r_h_deleg_storeamo_pf)); else
	if (r_control[2]) r_s_deleg_storeamo_pf <= (r_s_deleg_storeamo_pf&~in[15])&(r_m_deleg_storeamo_pf&(~r_v|r_h_deleg_storeamo_pf)); else r_s_deleg_storeamo_pf <= in[15]&(r_m_deleg_storeamo_pf&(~r_v|r_h_deleg_storeamo_pf));

	always @(posedge clk)
	if (reset) r_s_deleg_load_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_load_pf <= (r_s_deleg_load_pf|in[13])&(r_m_deleg_load_pf&(~r_v|r_h_deleg_load_pf)); else
	if (r_control[2]) r_s_deleg_load_pf <= (r_s_deleg_load_pf&~in[13])&(r_m_deleg_load_pf&(~r_v|r_h_deleg_load_pf)); else r_s_deleg_load_pf <= in[13]&(r_m_deleg_load_pf&(~r_v|r_h_deleg_load_pf));

	always @(posedge clk)
	if (reset) r_s_deleg_ins_pf <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_ins_pf <= (r_s_deleg_ins_pf|in[12])&(r_m_deleg_ins_pf&(~r_v|r_h_deleg_ins_pf)); else
	if (r_control[2]) r_s_deleg_ins_pf <= (r_s_deleg_ins_pf&~in[12])&(r_m_deleg_ins_pf&(~r_v|r_h_deleg_ins_pf)); else r_s_deleg_ins_pf <= in[12]&(r_m_deleg_ins_pf&(~r_v|r_h_deleg_ins_pf));

	always @(posedge clk)
	if (reset) r_s_deleg_env_u <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_env_u <= (r_s_deleg_env_u|in[8])&(r_m_deleg_env_u&(~r_v|r_h_deleg_env_u)); else
	if (r_control[2]) r_s_deleg_env_u <= (r_s_deleg_env_u&~in[8])&(r_m_deleg_env_u&(~r_v|r_h_deleg_env_u)); else r_s_deleg_env_u <= in[8]&(r_m_deleg_env_u&(~r_v|r_h_deleg_env_u));

	always @(posedge clk)
	if (reset) r_s_deleg_storeamo_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_storeamo_access <= (r_s_deleg_storeamo_access|in[7])&(r_m_deleg_storeamo_access&(~r_v|r_h_deleg_storeamo_access)); else
	if (r_control[2]) r_s_deleg_storeamo_access <= (r_s_deleg_storeamo_access&~in[7])&(r_m_deleg_storeamo_access&(~r_v|r_h_deleg_storeamo_access)); else r_s_deleg_storeamo_access <= in[7]&(r_m_deleg_storeamo_access&(~r_v|r_h_deleg_storeamo_access));

	always @(posedge clk)
	if (reset) r_s_deleg_storeamo_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_storeamo_align <= (r_s_deleg_storeamo_align|in[6])&(r_m_deleg_storeamo_align&(~r_v|r_h_deleg_storeamo_align)); else
	if (r_control[2]) r_s_deleg_storeamo_align <= (r_s_deleg_storeamo_align&~in[6])&(r_m_deleg_storeamo_align&(~r_v|r_h_deleg_storeamo_align)); else r_s_deleg_storeamo_align <= in[6]&(r_m_deleg_storeamo_align&(~r_v|r_h_deleg_storeamo_align));

	always @(posedge clk)
	if (reset) r_s_deleg_load_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_load_access <= (r_s_deleg_load_access|in[5])&(r_m_deleg_load_access&(~r_v|r_h_deleg_load_access)); else
	if (r_control[2]) r_s_deleg_load_access <= (r_s_deleg_load_access&~in[5])&(r_m_deleg_load_access&(~r_v|r_h_deleg_load_access)); else r_s_deleg_load_access <= in[5]&(r_m_deleg_load_access&(~r_v|r_h_deleg_load_access));

	always @(posedge clk)
	if (reset) r_s_deleg_load_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_load_align <= (r_s_deleg_load_align|in[4])&(r_m_deleg_load_align&(~r_v|r_h_deleg_load_align)); else
	if (r_control[2]) r_s_deleg_load_align <= (r_s_deleg_load_align&~in[4])&(r_m_deleg_load_align&(~r_v|r_h_deleg_load_align)); else r_s_deleg_load_align <= in[4]&(r_m_deleg_load_align&(~r_v|r_h_deleg_load_align));

	always @(posedge clk)
	if (reset) r_s_deleg_break <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_break <= (r_s_deleg_break|in[3])&(r_m_deleg_break&(~r_v|r_h_deleg_break)); else
	if (r_control[2]) r_s_deleg_break <= (r_s_deleg_break&~in[3])&(r_m_deleg_break&(~r_v|r_h_deleg_break)); else r_s_deleg_break <= in[3]&(r_m_deleg_break&(~r_v|r_h_deleg_break));

	always @(posedge clk)
	if (reset) r_s_deleg_illegal_inst <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_illegal_inst <= (r_s_deleg_illegal_inst|in[2])&(r_m_deleg_illegal_inst&(~r_v|r_h_deleg_illegal_inst)); else
	if (r_control[2]) r_s_deleg_illegal_inst <= (r_s_deleg_illegal_inst&~in[2])&(r_m_deleg_illegal_inst&(~r_v|r_h_deleg_illegal_inst)); else r_s_deleg_illegal_inst <= in[2]&(r_m_deleg_illegal_inst&(~r_v|r_h_deleg_illegal_inst));

	always @(posedge clk)
	if (reset) r_s_deleg_inst_access <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_inst_access <= (r_s_deleg_inst_access|in[1])&(r_m_deleg_inst_access&(~r_v|r_h_deleg_inst_access)); else
	if (r_control[2]) r_s_deleg_inst_access <= (r_s_deleg_inst_access&~in[1])&(r_m_deleg_inst_access&(~r_v|r_h_deleg_inst_access)); else r_s_deleg_inst_access <= in[1]&(r_m_deleg_inst_access&(~r_v|r_h_deleg_inst_access));

	always @(posedge clk)
	if (reset) r_s_deleg_inst_align <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h102))
	if (r_control[1]) r_s_deleg_inst_align <= (r_s_deleg_inst_align|in[0])&(r_m_deleg_inst_align&(~r_v|r_h_deleg_inst_align)); else
	if (r_control[2]) r_s_deleg_inst_align <= (r_s_deleg_inst_align&~in[0])&(r_m_deleg_inst_align&(~r_v|r_h_deleg_inst_align)); else r_s_deleg_inst_align <= in[0]&(r_m_deleg_inst_align&(~r_v|r_h_deleg_inst_align));

	reg	 [1:0]r_vsxl;
	reg		r_vtsr, r_vtvm, r_sp2v, r_sp2p, r_spv, r_stl, r_vsbe, r_sprv;

	always @(posedge clk)
	if (reset) r_vsxl <= 0; else
	if (RV==64 && csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_vsxl <= r_vsxl|in[33:32]; else
	if (r_control[2]) r_vsxl <= r_vsxl&~in[33:32]; else r_vsxl <= in[33:32];

	always @(posedge clk)
	if (reset) r_vtsr <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_vtsr <= r_vtsr|in[22]; else
	if (r_control[2]) r_vtsr <= r_vtsr&~in[22]; else r_vtsr <= in[22];

	always @(posedge clk)
	if (reset) r_vtvm <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_vtvm <= r_vtvm|in[20]; else
	if (r_control[2]) r_vtvm <= r_vtvm&~in[20]; else r_vtvm <= in[20];

	always @(posedge clk)
	if (reset) r_sp2v <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_sp2v <= r_sp2v|in[9]; else
	if (r_control[2]) r_sp2v <= r_sp2v&~in[9]; else r_sp2v <= in[9];

	always @(posedge clk)
	if (reset) r_sp2p <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_sp2p <= r_sp2p|in[8]; else
	if (r_control[2]) r_sp2p <= r_sp2p&~in[8]; else r_sp2p <= in[8];

	always @(posedge clk)
	if (reset) r_spv <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_spv <= r_spv|in[7]; else
	if (r_control[2]) r_spv <= r_spv&~in[7]; else r_spv <= in[7];

	always @(posedge clk)
	if (reset) r_stl <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_stl <= r_stl|in[6]; else
	if (r_control[2]) r_stl <= r_stl&~in[6]; else r_stl <= in[6];

	always @(posedge clk)
	if (reset) r_vsbe <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_vsbe <= r_vsbe|in[5]; else
	if (r_control[2]) r_vsbe <= r_vsbe&~in[5]; else r_vsbe <= in[5];

	always @(posedge clk)
	if (reset) r_sprv <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h600))
	if (r_control[1]) r_sprv <= r_sprv|in[0]; else
	if (r_control[2]) r_sprv <= r_sprv&~in[0]; else r_sprv <= in[0];

	reg	r_inh_branches_predicted, r_inh_branches_retired, r_inh_retired, r_inh_cycle;

	always @(posedge clk)
	if (reset) r_inh_cycle <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h320))
	if (r_control[1]) r_inh_cycle <= r_inh_cycle|in[0]; else
	if (r_control[2]) r_inh_cycle <= r_inh_cycle&~in[0]; else r_inh_cycle <= in[0];

	always @(posedge clk)
	if (reset) r_inh_retired <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h320))
	if (r_control[1]) r_inh_retired <= r_inh_retired|in[2]; else
	if (r_control[2]) r_inh_retired <= r_inh_retired&~in[2]; else r_inh_retired <= in[2];

	always @(posedge clk)
	if (reset) r_inh_branches_retired <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h320))
	if (r_control[1]) r_inh_branches_retired <= r_inh_branches_retired|in[3]; else
	if (r_control[2]) r_inh_branches_retired <= r_inh_branches_retired&~in[3]; else r_inh_branches_retired <= in[3];

	always @(posedge clk)
	if (reset) r_inh_branches_predicted  <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h320))
	if (r_control[1]) r_inh_branches_predicted <= r_inh_branches_predicted|in[4]; else
	if (r_control[2]) r_inh_branches_predicted <= r_inh_branches_predicted&~in[4]; else r_inh_branches_predicted <= in[4];

	reg	[63:0]r_cycle, r_retired, r_htimedelta;	
	always @(posedge clk) 
	if (reset) r_cycle <= 0; else
	if (csr_write && (r_immed[11:0] == 12'hb00)) r_cycle <= in; else
	if (!r_inh_cycle)
		r_cycle <= r_cycle+1;
		
	always @(posedge clk) 
	if (reset) r_retired <= 0; else 
	if (csr_write && (r_immed[11:0] == 12'hb02)) r_retired <= in; else
	if (!r_inh_retired)
		r_retired <= r_retired+num_retired;

	reg [31:0]r_branches_retired, r_branches_predicted, r_instructions_decoded, r_bundles_decoded;
	always @(posedge clk) 
	if (reset) r_branches_retired <= 0; else 
	if (csr_write && (r_immed[11:0] == 12'hb04)) r_branches_retired <= in; else
	if (!r_inh_branches_retired)
		r_branches_retired <= r_branches_retired+num_branches_retired;

	always @(posedge clk) 
	if (reset) r_branches_predicted <= 0; else 
	if (csr_write && (r_immed[11:0] == 12'hb05)) r_branches_predicted <= in; else
	if (!r_inh_branches_predicted)
		r_branches_predicted <= r_branches_predicted+num_branches_predicted;

	always @(posedge clk) 
	if (reset) r_instructions_decoded <= 0; else 
	if (csr_write && (r_immed[11:0] == 12'hb06)) r_instructions_decoded <= in; else
	if (!r_inh_branches_predicted)
		r_instructions_decoded <= r_instructions_decoded+count_out_rename;

	always @(posedge clk) 
	if (reset) r_bundles_decoded <= 0; else 
	if (csr_write && (r_immed[11:0] == 12'hb07)) r_bundles_decoded <= in; else
	if (!r_inh_branches_predicted && count_out_rename != 0)
		r_bundles_decoded <= r_bundles_decoded+1;

	always @(posedge clk) 
	if (reset) r_htimedelta <= 0; else
	if (csr_write && (r_immed[11:0] == 12'h605)) begin
		if (RV == 64) begin
			r_htimedelta <= in; 
		end else begin
			r_htimedelta[31:0] <= in; 
		end
	end else 
	if (csr_write && (r_immed[11:0] == 12'h615)) begin
			r_htimedelta[63:32] <= in; 
	end

	//
	//	PMP registers

	reg [NPHYS-1:2]r_pmp_addr[0:NUM_PMP-1];
wire [NPHYS-1:2]r_pmp_addr_0=r_pmp_addr[0];
	reg [NUM_PMP-1:0]r_pmp_locked;
	reg [1:0]r_pmp_a[0:NUM_PMP-1];
	reg [2:0]r_pmp_prot[0:NUM_PMP-1];

	reg		[NPHYS-1:2]c_pmp_start[0:NUM_PMP-1];
	reg		[NPHYS-1:2]c_pmp_end[0:NUM_PMP-1];
	reg		[NUM_PMP-1:0]c_pmp_valid;

	assign pmp.valid = c_pmp_valid;

	wire	[RV-1:0]pmp_data_0a;
	wire	[31:0]pmp_data_0b;
	wire	[31:0]pmp_data_1;
	wire	[RV-1:0]pmp_data_2a;
	wire	[31:0]pmp_data_2b;
	wire	[31:0]pmp_data_3;

	wire [NPHYS-1:2]x_pmp_addr[0:15];

	genvar I;
	generate 
		for (I = 0; I < 16; I=I+1) begin
			if (NUM_PMP >= (I+1)) begin
					assign x_pmp_addr[I] = r_pmp_addr[I];
			end else begin
					assign x_pmp_addr[I] = 0;
			end
		end
		if (NUM_PMP == 1) begin
			assign pmp_data_0a = {56'b0,
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {24'b0,
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = 32'b0;
		end else
		if (NUM_PMP == 2) begin
			assign pmp_data_0a = {48'b0,
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {16'b0,
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = 32'b0;
		end else
		if (NUM_PMP == 3) begin
			assign pmp_data_0a = {40'b0,
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {8'b0,
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = 32'b0;
		end else
		if (NUM_PMP == 4) begin
			assign pmp_data_0a = {32'b0,
								  r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = 32'b0;
		end else
		if (NUM_PMP == 5) begin
			assign pmp_data_0a = {24'b0,
								  r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4],
								  r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = {24'b0,
								 r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4]};
		end else
		if (NUM_PMP == 6) begin
			assign pmp_data_0a = {16'b0,
								  r_pmp_locked[5], 2'b0, r_pmp_a[5], r_pmp_prot[5],
								  r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4],
								  r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = {16'b0,
								 r_pmp_locked[5], 2'b0, r_pmp_a[5], r_pmp_prot[5],
								 r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4]};
		end else
		if (NUM_PMP == 7) begin
			assign pmp_data_0a = {8'b0,
								  r_pmp_locked[6], 2'b0, r_pmp_a[6], r_pmp_prot[6],
								  r_pmp_locked[5], 2'b0, r_pmp_a[5], r_pmp_prot[5],
								  r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4],
								  r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = {8'b0,
								 r_pmp_locked[6], 2'b0, r_pmp_a[6], r_pmp_prot[6],
								 r_pmp_locked[5], 2'b0, r_pmp_a[5], r_pmp_prot[5],
								 r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4]};
		end else begin
			assign pmp_data_0a = {r_pmp_locked[7], 2'b0, r_pmp_a[7], r_pmp_prot[7],
								  r_pmp_locked[6], 2'b0, r_pmp_a[6], r_pmp_prot[6],
								  r_pmp_locked[5], 2'b0, r_pmp_a[5], r_pmp_prot[5],
								  r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4],
								  r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_0b = {r_pmp_locked[3], 2'b0, r_pmp_a[3], r_pmp_prot[3],
								  r_pmp_locked[2], 2'b0, r_pmp_a[2], r_pmp_prot[2],
								  r_pmp_locked[1], 2'b0, r_pmp_a[1], r_pmp_prot[1],
								  r_pmp_locked[0], 2'b0, r_pmp_a[0], r_pmp_prot[0]};
			assign pmp_data_1 = {r_pmp_locked[7], 2'b0, r_pmp_a[7], r_pmp_prot[7],
								 r_pmp_locked[6], 2'b0, r_pmp_a[6], r_pmp_prot[6],
								 r_pmp_locked[5], 2'b0, r_pmp_a[5], r_pmp_prot[5],
								 r_pmp_locked[4], 2'b0, r_pmp_a[4], r_pmp_prot[4]};
		end

		if (NUM_PMP < 9) begin
			assign pmp_data_2a = 0;
			assign pmp_data_2b = 0;
			assign pmp_data_3 = 0;
		end else
		if (NUM_PMP == 9) begin
			assign pmp_data_2a = {56'b0,
								  r_pmp_locked[8], 2'b0, r_pmp_a[8], r_pmp_prot[8]};
			assign pmp_data_2b = {24'b0,
								  r_pmp_locked[8], 2'b0, r_pmp_a[8], r_pmp_prot[8]};
			assign pmp_data_3 = 32'b0;
		end else
		if (NUM_PMP == 10) begin
			assign pmp_data_2a = {48'b0,
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_2b = {16'b0,
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_3 = 32'b0;
		end else
		if (NUM_PMP == 11) begin
			assign pmp_data_2a = {40'b0,
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_2b = {8'b0,
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_3 = 32'b0;
		end else
		if (NUM_PMP == 12) begin
			assign pmp_data_2a = {32'b0,
								  r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_2b = {r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_3 = 32'b0;
		end else
		if (NUM_PMP == 13) begin
			assign pmp_data_2a = {24'b0,
								  r_pmp_locked[12], 2'b0, r_pmp_a[12], r_pmp_prot[12],
								  r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_2b = {r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_3 = {24'b0,
								 r_pmp_locked[12], 2'b0,  r_pmp_a[12], r_pmp_prot[12]};
		end else
		if (NUM_PMP == 14) begin
			assign pmp_data_2a = {16'b0,
								  r_pmp_locked[13], 2'b0, r_pmp_a[13], r_pmp_prot[13],
								  r_pmp_locked[12], 2'b0, r_pmp_a[12], r_pmp_prot[12],
								  r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_2b = {r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_3 = {16'b0,
								 r_pmp_locked[13], 2'b0,  r_pmp_a[13], r_pmp_prot[13],
								 r_pmp_locked[12], 2'b0,  r_pmp_a[12], r_pmp_prot[12]};
		end else
		if (NUM_PMP == 15) begin
			assign pmp_data_2a = {8'b0,
								  r_pmp_locked[14], 2'b0, r_pmp_a[14], r_pmp_prot[14],
								  r_pmp_locked[13], 2'b0, r_pmp_a[13], r_pmp_prot[13],
								  r_pmp_locked[12], 2'b0, r_pmp_a[12], r_pmp_prot[12],
								  r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_2b = {r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_3 = {8'b0,
								 r_pmp_locked[14], 2'b0,  r_pmp_a[14], r_pmp_prot[14],
								 r_pmp_locked[13], 2'b0,  r_pmp_a[13], r_pmp_prot[13],
								 r_pmp_locked[12], 2'b0,  r_pmp_a[12], r_pmp_prot[12]};
		end else
		if (NUM_PMP == 16) begin
			assign pmp_data_2a = {r_pmp_locked[15], 2'b0, r_pmp_a[15], r_pmp_prot[15],
								  r_pmp_locked[14], 2'b0, r_pmp_a[14], r_pmp_prot[14],
								  r_pmp_locked[13], 2'b0, r_pmp_a[13], r_pmp_prot[13],
								  r_pmp_locked[12], 2'b0, r_pmp_a[12], r_pmp_prot[12],
								  r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_2b = {r_pmp_locked[11], 2'b0, r_pmp_a[11], r_pmp_prot[11],
								  r_pmp_locked[10], 2'b0, r_pmp_a[10], r_pmp_prot[10],
								  r_pmp_locked[9],  2'b0, r_pmp_a[9],  r_pmp_prot[9],
								  r_pmp_locked[8], 2'b0,  r_pmp_a[8],  r_pmp_prot[8]};
			assign pmp_data_3 = {r_pmp_locked[15], 2'b0,  r_pmp_a[15], r_pmp_prot[15],
								 r_pmp_locked[14], 2'b0,  r_pmp_a[14], r_pmp_prot[14],
								 r_pmp_locked[13], 2'b0,  r_pmp_a[13], r_pmp_prot[13],
								 r_pmp_locked[12], 2'b0,  r_pmp_a[12], r_pmp_prot[12]};
		end 


		for (I = 0; I < NUM_PMP; I=I+1) begin
			assign pmp.start[I]  = c_pmp_start[I];
			assign pmp.aend[I]  = c_pmp_end[I];
			assign pmp.prot[I]  = r_pmp_prot[I];	
		end
		
		for (I = 0; I < NUM_PMP; I=I+1) begin: pmps
			wire locked;
			if (I == (NUM_PMP-1)) begin
				assign locked = r_pmp_locked[I];
			end else begin
				assign locked = r_pmp_locked[I]|(r_pmp_locked[I+1]&(r_pmp_a[I+1]==2'b01));
			end
			if ((I&8)!=0) begin
				if ((I&4)!=0) begin
					always @(posedge clk) 
					if (reset) r_pmp_locked[I] <= 0; else 
					if (csr_write && !locked)
					if (!rv32) begin
						if (r_immed[11:0] == 12'h3a2) 
						if (r_control[1]) r_pmp_locked[I] <= r_pmp_locked[I]|in[((I&7)*8)+7]; else
						if (r_control[2]) r_pmp_locked[I] <= r_pmp_locked[I]&~in[((I&7)*8)+7]; else r_pmp_locked[I] <= in[((I&7)*8)+7];
					end else begin
						if (r_immed[11:0] == 12'h3a3) 
						if (r_control[1]) r_pmp_locked[I] <= r_pmp_locked[I]|in[((I&3)*8)+7]; else
						if (r_control[2]) r_pmp_locked[I] <= r_pmp_locked[I]&~in[((I&3)*8)+7]; else r_pmp_locked[I] <= in[((I&3)*8)+7];
					end

					always @(posedge clk) 
					if (reset) r_pmp_a[I] <= 0; else 
					if (csr_write && !locked)
					if (!rv32) begin
						if (r_immed[11:0] == 12'h3a2) 
						if (r_control[1]) r_pmp_a[I] <= r_pmp_a[I]|in[((I&7)*8)+4:((I&7)*8)+3]; else
						if (r_control[2]) r_pmp_a[I] <= r_pmp_a[I]&~in[((I&7)*8)+4:((I&7)*8)+3]; else r_pmp_a[I] <= in[((I&7)*8)+4:((I&7)*8)+3];
					end else begin
						if (r_immed[11:0] == 12'h3a3) 
						if (r_control[1]) r_pmp_a[I] <= r_pmp_a[I]|in[((I&3)*8)+4:((I&3)*8)+3]; else
						if (r_control[2]) r_pmp_a[I] <= r_pmp_a[I]&~in[((I&3)*8)+4:((I&3)*8)+3]; else r_pmp_a[I] <= in[((I&3)*8)+4:((I&3)*8)+3];
					end

					always @(posedge clk) 
					if (csr_write && !locked)
					if (!rv32) begin
						if (r_immed[11:0] == 12'h3a2) 
						if (r_control[1]) r_pmp_prot[I] <= r_pmp_prot[I]|in[((I&7)*8)+2:((I&7)*8)+0]; else
						if (r_control[2]) r_pmp_prot[I] <= r_pmp_prot[I]&~in[((I&7)*8)+2:((I&7)*8)+0]; else r_pmp_prot[I] <= in[((I&7)*8)+2:((I&7)*8)+0];
					end else begin
						if (r_immed[11:0] == 12'h3a3) 
						if (r_control[1]) r_pmp_prot[I] <= r_pmp_prot[I]|in[((I&3)*8)+2:((I&3)*8)+0]; else
						if (r_control[2]) r_pmp_prot[I] <= r_pmp_prot[I]&~in[((I&3)*8)+2:((I&3)*8)+0]; else r_pmp_prot[I] <= in[((I&3)*8)+2:((I&3)*8)+0];
					end

				end else begin
					always @(posedge clk) 
					if (reset) r_pmp_locked[I] <= 0; else 
					if (csr_write && !locked && (r_immed[11:0] == 12'h3a2)) 
					if (r_control[1]) r_pmp_locked[I] <= r_pmp_locked[I]|in[((I&3)*8)+7]; else
					if (r_control[2]) r_pmp_locked[I] <= r_pmp_locked[I]&~in[((I&3)*8)+7]; else r_pmp_locked[I] <= in[((I&3)*8)+7];

					always @(posedge clk) 
					if (reset) r_pmp_a[I] <= 0; else 
					if (csr_write && !locked && (r_immed[11:0] == 12'h3a2)) 
					if (r_control[1]) r_pmp_a[I] <= r_pmp_a[I]|in[((I&3)*8)+4:((I&3)*8)+3]; else
					if (r_control[2]) r_pmp_a[I] <= r_pmp_a[I]&~in[((I&3)*8)+4:((I&3)*8)+3]; else r_pmp_a[I] <= in[((I&3)*8)+4:((I&3)*8)+3];
					always @(posedge clk) 
					if (csr_write && !locked && (r_immed[11:0] == 12'h3a2)) 
					if (r_control[1]) r_pmp_prot[I] <= r_pmp_prot[I]|in[((I&3)*8)+2:((I&3)*8)+0]; else
					if (r_control[2]) r_pmp_prot[I] <= r_pmp_prot[I]&~in[((I&3)*8)+2:((I&3)*8)+0]; else r_pmp_prot[I] <= in[((I&3)*8)+2:((I&3)*8)+0];
				end
			end else begin
				if ((I&4)!=0) begin
					always @(posedge clk) 
					if (reset) r_pmp_locked[I] <= 0; else 
					if (csr_write && !locked)
					if (!rv32) begin
						if (r_immed[11:0] == 12'h3a0) 
						if (r_control[1]) r_pmp_locked[I] <= r_pmp_locked[I]|in[((I&7)*8)+7]; else
						if (r_control[2]) r_pmp_locked[I] <= r_pmp_locked[I]&~in[((I&7)*8)+7]; else r_pmp_locked[I] <= in[((I&7)*8)+7];
					end else begin
						if (r_immed[11:0] == 12'h3a1) 
						if (r_control[1]) r_pmp_locked[I] <= r_pmp_locked[I]|in[((I&3)*8)+7]; else
						if (r_control[2]) r_pmp_locked[I] <= r_pmp_locked[I]&~in[((I&3)*8)+7]; else r_pmp_locked[I] <= in[((I&3)*8)+7];
					end

					always @(posedge clk) 
					if (reset) r_pmp_a[I] <= 0; else 
					if (csr_write && !locked)
					if (!rv32) begin
						if (r_immed[11:0] == 12'h3a0) 
						if (r_control[1]) r_pmp_a[I] <= r_pmp_a[I]|in[((I&7)*8)+4:((I&7)*8)+3]; else
						if (r_control[2]) r_pmp_a[I] <= r_pmp_a[I]&~in[((I&7)*8)+4:((I&7)*8)+3]; else r_pmp_a[I] <= in[((I&7)*8)+4:((I&7)*8)+3];
					end else begin
						if (r_immed[11:0] == 12'h3a1) 
						if (r_control[1]) r_pmp_a[I] <= r_pmp_a[I]|in[((I&3)*8)+4:((I&3)*8)+3]; else
						if (r_control[2]) r_pmp_a[I] <= r_pmp_a[I]&~in[((I&3)*8)+4:((I&3)*8)+3]; else r_pmp_a[I] <= in[((I&3)*8)+4:((I&3)*8)+3];
					end

					always @(posedge clk) 
					if (csr_write && !locked)
					if (!rv32) begin
						if (r_immed[11:0] == 12'h3a0) 
						if (r_control[1]) r_pmp_prot[I] <= r_pmp_prot[I]|in[((I&7)*8)+2:((I&7)*8)+0]; else
						if (r_control[2]) r_pmp_prot[I] <= r_pmp_prot[I]&~in[((I&7)*8)+2:((I&7)*8)+0]; else r_pmp_prot[I] <= in[((I&7)*8)+2:((I&7)*8)+0];
					end else begin
						if (r_immed[11:0] == 12'h3a1) 
						if (r_control[1]) r_pmp_prot[I] <= r_pmp_prot[I]|in[((I&3)*8)+2:((I&3)*8)+0]; else
						if (r_control[2]) r_pmp_prot[I] <= r_pmp_prot[I]&~in[((I&3)*8)+2:((I&3)*8)+0]; else r_pmp_prot[I] <= in[((I&3)*8)+2:((I&3)*8)+0];
					end

				end else begin
					always @(posedge clk) 
					if (reset) r_pmp_locked[I] <= 0; else 
					if (csr_write && !locked && (r_immed[11:0] == 12'h3a0)) 
					if (r_control[1]) r_pmp_locked[I] <= r_pmp_locked[I]|in[((I&3)*8)+7]; else
					if (r_control[2]) r_pmp_locked[I] <= r_pmp_locked[I]&~in[((I&3)*8)+7]; else r_pmp_locked[I] <= in[((I&3)*8)+7];
					always @(posedge clk) 
					if (reset) r_pmp_a[I] <= 0; else 
					if (csr_write && !locked && (r_immed[11:0] == 12'h3a0)) 
					if (r_control[1]) r_pmp_a[I] <= r_pmp_a[I]|in[((I&3)*8)+4:((I&3)*8)+3]; else
					if (r_control[2]) r_pmp_a[I] <= r_pmp_a[I]&~in[((I&3)*8)+4:((I&3)*8)+3]; else r_pmp_a[I] <= in[((I&3)*8)+4:((I&3)*8)+3];
					always @(posedge clk) 
					if (csr_write && !locked && (r_immed[11:0] == 12'h3a0)) 
					if (r_control[1]) r_pmp_prot[I] <= r_pmp_prot[I]|in[((I&3)*8)+2:((I&3)*8)+0]; else
					if (r_control[2]) r_pmp_prot[I] <= r_pmp_prot[I]&~in[((I&3)*8)+2:((I&3)*8)+0]; else r_pmp_prot[I] <= in[((I&3)*8)+2:((I&3)*8)+0];
				end
			end

			always @(posedge clk) 
			if (csr_write && !locked && (r_immed[11:0] == (12'h3b0+I))) 
			if (r_control[1]) r_pmp_addr[I] <= r_pmp_addr[I]|in[RV-1:0]; else
			if (r_control[2]) r_pmp_addr[I] <= r_pmp_addr[I]&~in[RV-1:0]; else r_pmp_addr[I] <= in[RV-1:0];

			assign	pmp.locked[I] = locked;
		
			reg [NPHYS-1:2]mask;
			always @(*) 
			casez (r_pmp_addr[I]) // synthesis full_case parallel_case
			54'b????_??????????_??????????_??????????_??????????_?????????0: mask = {53'b0, ~1'h0};
			54'b????_??????????_??????????_??????????_??????????_????????01: mask = {52'b0, ~2'h0};
			54'b????_??????????_??????????_??????????_??????????_???????011: mask = {51'b0, ~3'h0};
			54'b????_??????????_??????????_??????????_??????????_??????0111: mask = {50'b0, ~4'h0};
			54'b????_??????????_??????????_??????????_??????????_?????01111: mask = {49'b0, ~5'h0};
			54'b????_??????????_??????????_??????????_??????????_????011111: mask = {48'b0, ~6'h0};
			54'b????_??????????_??????????_??????????_??????????_???0111111: mask = {47'b0, ~7'h0};
			54'b????_??????????_??????????_??????????_??????????_??01111111: mask = {46'b0, ~8'h0};
			54'b????_??????????_??????????_??????????_??????????_?011111111: mask = {45'b0, ~9'h0};
			54'b????_??????????_??????????_??????????_??????????_0111111111: mask = {44'b0, ~10'h0};

			54'b????_??????????_??????????_??????????_?????????0_1111111111: mask = {43'b0, ~11'h0};
			54'b????_??????????_??????????_??????????_????????01_1111111111: mask = {42'b0, ~12'h0};
			54'b????_??????????_??????????_??????????_???????011_1111111111: mask = {41'b0, ~13'h0};
			54'b????_??????????_??????????_??????????_??????0111_1111111111: mask = {40'b0, ~14'h0};
			54'b????_??????????_??????????_??????????_?????01111_1111111111: mask = {39'b0, ~15'h0};
			54'b????_??????????_??????????_??????????_????011111_1111111111: mask = {38'b0, ~16'h0};
			54'b????_??????????_??????????_??????????_???0111111_1111111111: mask = {37'b0, ~17'h0};
			54'b????_??????????_??????????_??????????_??01111111_1111111111: mask = {36'b0, ~18'h0};
			54'b????_??????????_??????????_??????????_?011111111_1111111111: mask = {35'b0, ~19'h0};
			54'b????_??????????_??????????_??????????_0111111111_1111111111: mask = {34'b0, ~20'h0};

			54'b????_??????????_??????????_?????????0_1111111111_1111111111: mask = {33'b0, ~21'h0};
			54'b????_??????????_??????????_????????01_1111111111_1111111111: mask = {32'b0, ~22'h0};
			54'b????_??????????_??????????_???????011_1111111111_1111111111: mask = {31'b0, ~23'h0};
			54'b????_??????????_??????????_??????0111_1111111111_1111111111: mask = {30'b0, ~24'h0};
			54'b????_??????????_??????????_?????01111_1111111111_1111111111: mask = {29'b0, ~25'h0};
			54'b????_??????????_??????????_????011111_1111111111_1111111111: mask = {28'b0, ~26'h0};
			54'b????_??????????_??????????_???0111111_1111111111_1111111111: mask = {27'b0, ~27'h0};
			54'b????_??????????_??????????_??01111111_1111111111_1111111111: mask = {26'b0, ~28'h0};
			54'b????_??????????_??????????_?011111111_1111111111_1111111111: mask = {25'b0, ~29'h0};
			54'b????_??????????_??????????_0111111111_1111111111_1111111111: mask = {24'b0, ~30'h0};

			54'b????_??????????_?????????0_1111111111_1111111111_1111111111: mask = {23'b0, ~31'h0};
			54'b????_??????????_????????01_1111111111_1111111111_1111111111: mask = {22'b0, ~32'h0};
			54'b????_??????????_???????011_1111111111_1111111111_1111111111: mask = {21'b0, ~33'h0};
			54'b????_??????????_??????0111_1111111111_1111111111_1111111111: mask = {20'b0, ~34'h0};
			54'b????_??????????_?????01111_1111111111_1111111111_1111111111: mask = {19'b0, ~35'h0};
			54'b????_??????????_????011111_1111111111_1111111111_1111111111: mask = {18'b0, ~36'h0};
			54'b????_??????????_???0111111_1111111111_1111111111_1111111111: mask = {17'b0, ~37'h0};
			54'b????_??????????_??01111111_1111111111_1111111111_1111111111: mask = {16'b0, ~38'h0};
			54'b????_??????????_?011111111_1111111111_1111111111_1111111111: mask = {15'b0, ~39'h0};
			54'b????_??????????_0111111111_1111111111_1111111111_1111111111: mask = {14'b0, ~40'h0};

			54'b????_?????????0_1111111111_1111111111_1111111111_1111111111: mask = {13'b0, ~41'h0};
			54'b????_????????01_1111111111_1111111111_1111111111_1111111111: mask = {12'b0, ~42'h0};
			54'b????_???????011_1111111111_1111111111_1111111111_1111111111: mask = {11'b0, ~43'h0};
			54'b????_??????0111_1111111111_1111111111_1111111111_1111111111: mask = {10'b0, ~44'h0};
			54'b????_?????01111_1111111111_1111111111_1111111111_1111111111: mask = {9'b0, ~45'h0};
			54'b????_????011111_1111111111_1111111111_1111111111_1111111111: mask = {8'b0, ~46'h0};
			54'b????_???0111111_1111111111_1111111111_1111111111_1111111111: mask = {7'b0, ~47'h0};
			54'b????_??01111111_1111111111_1111111111_1111111111_1111111111: mask = {6'b0, ~48'h0};
			54'b????_?011111111_1111111111_1111111111_1111111111_1111111111: mask = {5'b0, ~49'h0};
			54'b????_0111111111_1111111111_1111111111_1111111111_1111111111: mask = {4'b0, ~50'h0};

			54'b???0_1111111111_1111111111_1111111111_1111111111_1111111111: mask = {3'b0, ~51'h0};
			54'b??01_1111111111_1111111111_1111111111_1111111111_1111111111: mask = {2'b0, ~52'h0};
			54'b?011_1111111111_1111111111_1111111111_1111111111_1111111111: mask = {1'b0, ~53'h0};
			54'b?111_1111111111_1111111111_1111111111_1111111111_1111111111: mask = ~54'b0;
			endcase

			if (I == (NUM_PMP-1)) begin
				always @(*) begin
					case (r_pmp_a[I])
					2'b00:	begin
								c_pmp_valid[I] = 0;				// OFF
								c_pmp_start[I] = 'bx;
								c_pmp_end[I] = 'bx;
							end
					2'b01:	begin
								c_pmp_valid[I] = 1;				// NATOP
								c_pmp_start[I] = I==0?0:r_pmp_addr[I-1];
								c_pmp_end[I]   = r_pmp_addr[I];
							end
					2'b10:	begin
								c_pmp_valid[I] = 1;				// NA4
								c_pmp_start[I] = r_pmp_addr[I];
								c_pmp_end[I]   = r_pmp_addr[I];
							end
					2'b11:	begin
								c_pmp_valid[I] = 1;				// NAPOT
								c_pmp_start[I] = r_pmp_addr[I]&~mask;
								c_pmp_end[I] = r_pmp_addr[I]|mask;
							end
					endcase
				end
			end else begin
				always @(*) begin
					case (r_pmp_a[I])
					2'b00:	begin
								c_pmp_valid[I] = 0;
								c_pmp_start[I] = 'bx;
								c_pmp_end[I] = 'bx;
							end
					2'b01:	begin
								c_pmp_valid[I] = (r_pmp_a[I+1]!=2'b01);
								c_pmp_start[I] = I==0?0:r_pmp_addr[I-1];
								c_pmp_end[I]   = r_pmp_addr[I];
							end
					2'b10:	begin
								c_pmp_valid[I] = (r_pmp_a[I+1]!=2'b01);
								c_pmp_start[I] = r_pmp_addr[I];
								c_pmp_end[I]   = r_pmp_addr[I];
							end
					2'b11:	begin
								c_pmp_valid[I] = (r_pmp_a[I+1]!=2'b01);
								c_pmp_start[I] = r_pmp_addr[I]&~mask;
								c_pmp_end[I] = r_pmp_addr[I]|mask;
							end
					endcase
				end
			end
		end
	endgenerate


	//
	//	Moonbase specific registers
	//

	reg		[31:0]r_pseudo_random;
	assign	orand = r_pseudo_random[31];
	always @(posedge clk) 
	if (reset) r_pseudo_random <= 0; else // 0 turns it off
	if (csr_write && (r_immed[11:0] == 12'hbf8)) begin	// pseudo seed - used for cache randomisation
		r_pseudo_random <= in[31:0];
	end else begin
		r_pseudo_random <= {r_pseudo_random[30:0], r_pseudo_random[31]^r_pseudo_random[28]};
	end
	
	reg		r_unified_asid;
	assign unified_asid = r_unified_asid;
	always @(posedge clk) 
	if (reset) r_unified_asid <= 0; else // 0 turns it off
	if (csr_write && (r_immed[11:0] == 12'hbf9)) 
	if (r_control[1]) r_unified_asid <= r_unified_asid|in[0]; else
	if (r_control[2]) r_unified_asid <= r_unified_asid&~in[0]; else r_unified_asid <= in[0];

`ifdef TRACE_CACHE
	reg [3:0]r_trace_enable;
	reg [3:0]r_trace_scale;
	assign trace_enable = |(r_trace_enable&r_cpu_mode);
	assign trace_scale = r_trace_scale;

	always @(posedge clk) 
`ifdef SIMD
	if (reset) r_trace_enable <= (simd_trace_enable?4'b1111:4'b0000); else // 0 turns it off
`else
	if (reset) r_trace_enable <= 4'b0000; else // 0 turns it off
`endif
	if (csr_write && (r_immed[11:0] == 12'hbf9)) 
	if (r_control[1]) r_trace_enable <= r_trace_enable|in[4:1]; else
	if (r_control[2]) r_trace_enable <= r_trace_enable&~in[4:1]; else r_trace_enable <= in[4:1];

	always @(posedge clk) 
	if (reset) r_trace_scale <= 4'b1001; else 
	if (csr_write && (r_immed[11:0] == 12'hbf9)) 
	if (r_control[1]) r_trace_scale <= r_trace_scale|in[8:5]; else
	if (r_control[2]) r_trace_scale <= r_trace_scale&~in[8:5]; else r_trace_scale <= in[8:5];

`else
	wire [3:0]r_trace_enable=0;
	wire [3:0]r_trace_scale=0;
`endif

	reg		r_all_reset;
	assign	reset_out = r_all_reset;

	always @(posedge clk)
    if (reset) r_all_reset <= 0; else // 0 turns it off		// system reset
    if (csr_write && (r_immed[11:0] == 12'hbfa))
    if (r_control[1]) r_all_reset <= r_all_reset|in[0]; else
    if (r_control[2]) r_all_reset <= 0; else r_all_reset <= in[0];

	reg [31:0]r_u_debug;
	assign u_debug = r_u_debug;
    always @(posedge clk)
    if (reset) r_u_debug <= 0; else
    if (csr_write && (r_immed[11:0] == 12'h480))	// debug register
		r_u_debug <= in[31:0];



	//
	//
		
	reg  [63:0]r_io_timer;
	always @(posedge clk)
		r_io_timer <= io_timer;
	wire [63:0]mtime = r_io_timer+(r_v&(|r_cpu_mode[1:0])? r_htimedelta:0);

	always @(*) begin
		c_res = 0;
		if (c_int_force_fetch) begin
			casez ({fast_int_m||(int_m_pending&r_m_ie), fast_int_s||(int_s_pending&r_s_ie), fast_int_u||(int_u_pending&r_u_ie)})  // synthesis full_case parallel_case
			3'b1??: if (!rv32) begin
						c_res = {r_m_tvt[RV-1:3+$clog2(NINTERRUPTS)], clic_m_int, 3'b000};
					end else begin
						c_res = {r_m_tvt, 1'b0, clic_m_int, 2'b00};
					end
			3'b01?: if (!rv32) begin
						c_res = {r_s_tvt[RV-1:3+$clog2(NINTERRUPTS)], clic_s_int, 3'b000};
					end else begin
						c_res = {r_s_tvt, 1'b0, clic_s_int, 2'b00};
					end
			3'b001: if (!rv32) begin
						c_res = {r_u_tvt[RV-1:3+$clog2(NINTERRUPTS)], clic_u_int, 3'b000};
					end else begin
						c_res = {r_u_tvt, 1'b0, clic_u_int, 2'b00};
					end
			endcase
		end else
		casez ({r_v, r_immed[11:0]}) // synthesis full_case parallel_case
		// user mode
		13'b?_00_00_0000_0000:		//	user status register
					c_res = {59'b0, r_u_pie, 3'b0, r_u_ie};
		13'b?_00_00_0000_0001:		//  FP accrued exceptions
`ifdef FP
					c_res = {59'b0, r_fflags};
`else
					c_res = 0;
`endif
		13'b?_00_00_0000_0010:		//  FP dynamic rounding mode
`ifdef FP
					c_res = {61'b0, r_frm};
`else
					c_res = 0;
`endif
		13'b?_00_00_0000_0011:		//  FP dynamic CS reg
`ifdef FP
					c_res = {56'b0, r_frm, r_fflags};
`else
					c_res = 0;
`endif
		13'b?_00_00_0000_0100:		//  user interrupt enable register
					c_res = clic_u_enable?64'b0:{55'b0, r_u_eie, 3'b0, r_u_tie, 3'b0, r_u_sie};
		13'b?_00_00_0000_0101:		//  user trap handler base address
					c_res = {r_u_trap_base[RV-1:6], clic_u_enable?4'b0:r_u_trap_base[5:2], r_u_trap_type};
		13'b?_00_00_0000_0111:		//  sup tvt base address
					if (rv32) begin
						c_res = {r_u_tvt, {2+$clog2(NINTERRUPTS){1'b0}}};
					end else begin
						c_res = {r_u_tvt[RV-1:3+$clog2(NINTERRUPTS)], {3+$clog2(NINTERRUPTS){1'b0}}};
					end

		13'b?_00_00_0100_0000:		//  scratch reg for trap handlers
					c_res = r_u_scratch;
		13'b?_00_00_0100_0001:		//  user UEPC
					c_res = {r_u_epc, 1'b0};
		13'b?_00_00_0100_0010:		//  user trap cause
					if (rv32) begin
						c_res = {r_u_trap_interrupt, 31'b0, r_u_trap_interrupt, !clic_u_enable?1'b0:r_u_inhv, 1'b0, 1'b0, !clic_u_enable?1'b0:r_u_pie, 3'b000, !clic_u_enable?8'b0:r_u_pil, 4'b0000, r_u_trap_cause};
					end else begin
						c_res = {r_u_trap_interrupt, 32'b0, !clic_u_enable?1'b0:r_u_inhv, 1'b0, 1'b0, !clic_u_enable?1'b0:r_u_pie, 3'b000, !clic_u_enable?8'b0:r_u_pil, 4'b0000, r_u_trap_cause};
					end
		13'b?_00_00_0100_0011:		//  user bad address or instruction 
					c_res = r_u_mtval;
		13'b?_00_00_0100_0100:		//  user interrupt pending
					c_res = {48'b0, u_ext, 3'b000, u_eip, 3'b0, u_tip, 3'b0, u_sip};
		13'b?_00_00_0100_0101:		//  user nxti
					if (!rv32) begin
						c_res = !clic_u_enable || !clic_u_pending || !cpu_mode[0] || clic_u_il <= r_u_pil || clic_u_il <= r_u_intthresh || !clic_u_vec? 64'b0: {r_u_tvt[RV-1:3+$clog2(NINTERRUPTS)], clic_u_int, 3'b000};
					end else begin
						c_res = !clic_u_enable || !clic_u_pending || !cpu_mode[0] || clic_u_il <= r_u_pil || clic_u_il <= r_u_intthresh || !clic_u_vec? 32'b0: {r_u_tvt, clic_u_int, 2'b00};
					end
		13'b?_00_00_0100_0110:		//  user current interrupt levels	FIXME address
					c_res = {32'b0, 8'b0, 8'b0, 8'b0, r_u_il};
		13'b?_00_00_0100_1000:		//  user scratchsw
					c_res = r_m_pp == 0 ? r_u_scratch : r_r1;
		13'b?_00_00_0100_1001:		//  user scratchswl
					c_res = (r_u_pil == 0) != (clic_u_il != 0)  ? r_u_scratch : r_r1;
		13'b?_00_00_0100_1010:		//  user int threshol	FIXME addressd
					c_res = {32'b0, 8'b0, 8'b0, 8'b0, r_u_intthresh};
		13'b?_00_00_0100_1011:		//  sup clic base	FIXME address
					c_res = {U_CLIC_BASE[RV-1:20], cpu_id[3:0], 16'b0};

		13'b?_11_00_0000_0000,		//  cycle counter for RDCYCLE
		13'b?_10_11_0000_0000:		//  cycle counter for RDCYCLE
					c_res = r_cycle;	
		13'b?_11_00_0000_0001:		//  timer for RDTime
					c_res = mtime;	
		13'b?_11_00_0000_0010,		//  instructions retired for RDINSTRET
		13'b?_10_11_0000_0010:		//  instructions retired for RDINSTRET
					c_res = r_retired;	
		13'b?_11_00_0000_0100,		//  branches retired
		13'b?_10_11_0000_0100:	
					c_res = r_branches_retired;

		13'b?_11_00_0000_0101,		//  branches predicted
		13'b?_10_11_0000_0101:	
					c_res = r_branches_predicted;

		13'b?_11_00_0000_0110,		//  instructions decoded
		13'b?_10_11_0000_0110:	
					c_res = r_instructions_decoded;

		13'b?_11_00_0000_0111,		//  decode-bundles decoded
		13'b?_10_11_0000_0111:	
					c_res = r_bundles_decoded;

		13'b?_11_00_0000_0011,		//  performance monitoring counter
		13'b?_10_11_0000_0011,		//  performance monitoring counter
		13'b?_11_00_0000_011?,		//  performance monitoring counter
		13'b?_10_11_0000_011?,		//  performance monitoring counter
		13'b?_11_00_0000_1???,		//  performance monitoring counter
		13'b?_10_11_0000_1???,		//  performance monitoring counter
		13'b?_11_00_0001_????,		//  performance monitoring counter
		13'b?_10_11_0001_????:		//  performance monitoring counter
					c_res = 0;
			
		// hi byte for 32-bit cases
		13'b?_11_00_1000_0000,		//  cycle counter for RDCYCLE
		13'b?_10_11_1000_0000:		//  cycle counter for RDCYCLE
					c_res = r_cycle[63:32];	
		13'b?_11_00_1000_0001:		//  timer for RDTime
					c_res = mtime[63:32];	
		13'b?_11_00_1000_0010,		//  instructions retired for RDINSTRET
		13'b?_10_11_1000_0010:		//  instructions retired for RDINSTRET
					c_res = r_retired[63:32];	
		13'b?_11_00_1000_010?,		//  performance monitoring counter
		13'b?_10_11_1000_010?:		//  performance monitoring counter
					c_res = 0;
		13'b?_11_00_1000_0011,		//  performance monitoring counter
		13'b?_10_11_1000_0011,		//  performance monitoring counter
		13'b?_11_00_1000_01??,		//  performance monitoring counter
		13'b?_10_11_1000_01??,		//  performance monitoring counter
		13'b?_11_00_1000_1???,		//  performance monitoring counter
		13'b?_10_11_1000_1???,		//  performance monitoring counter
		13'b?_11_00_1001_????,		//  performance monitoring counter
		13'b?_10_11_1001_????:		//  performance monitoring counter
					c_res = 0;

		13'b?_00_11_0010_0000:		//  performance counter inhibit
					c_res = {32'b0, 27'b0, r_inh_branches_predicted, r_inh_branches_retired, r_inh_retired, 1'b0, r_inh_cycle};
			
		// sup mode
		13'b0_00_01_0000_0000:		//	sup status register
					c_res = {((r_xs==3)|(r_fs==3)?1'b1:1'b0), 29'b0, r_uxl,
					        12'b0, r_s_mxr, r_s_sum, 1'b0, r_xs, r_fs, 4'b0, r_s_pp,
							2'b0, r_s_pie, r_u_pie, 2'b0, r_s_ie, r_u_ie};
		13'b0_00_01_0000_0010:		//  sup exception delegation reg
					c_res = {48'b0, r_s_deleg_storeamo_pf, 1'b0, r_s_deleg_load_pf, r_s_deleg_ins_pf, 3'b0, r_s_deleg_env_u, r_s_deleg_storeamo_access, r_s_deleg_storeamo_align, r_s_deleg_load_access, r_s_deleg_load_align, r_s_deleg_break, r_s_deleg_illegal_inst, r_s_deleg_inst_access, r_s_deleg_inst_align};
		13'b0_00_01_0000_0011:		//  sup interrupt delegation reg
					c_res = {47'b0, r_s_deleg_ext&(r_v?r_h_deleg_ext:5'b0)&r_m_deleg_ext, r_s_deleg_mei&(r_v?r_h_deleg_mei:1'b0)&r_m_deleg_mei, 1'b0, r_s_deleg_sei&(r_v?r_h_deleg_sei:1'b0)&r_m_deleg_sei, r_s_deleg_uei&(r_v?r_h_deleg_uei:1'b0)&r_m_deleg_uei, r_s_deleg_mti&(r_v?r_h_deleg_mti:1'b0)&r_m_deleg_mti, 1'b0,  r_s_deleg_sti&(r_v?r_h_deleg_sti:1'b0)&r_m_deleg_sti, r_s_deleg_uti&(r_v?r_h_deleg_uti:1'b0)&r_m_deleg_uti, r_s_deleg_msi&(r_v?r_h_deleg_msi:1'b0)&r_m_deleg_msi, 1'b0, r_s_deleg_ssi&(r_v?r_h_deleg_ssi:1'b0)&r_m_deleg_ssi, r_s_deleg_usi&(r_v?r_h_deleg_usi:1'b0)&r_m_deleg_usi};
		13'b0_00_01_0000_0100:		//  sup interrupt enable register
					c_res = clic_s_enable?64'b0:{54'b0, r_s_eie, r_u_eie, 2'b0, r_s_tie, r_u_tie, 2'b0, r_s_sie, r_u_sie};
		13'b0_00_01_0000_0101:		//  sup trap handler base address
					c_res = {r_s_trap_base[RV-1:6], clic_s_enable?4'b0:r_s_trap_base[5:2], r_s_trap_type};
		13'b0_00_01_0000_0110:		//  sup counter enable
					c_res = {61'b0, r_s_ir, r_s_tm, r_s_cy};
		13'b0_00_01_0000_0111:		//  sup tvt base address
					if (rv32) begin
						c_res = {r_s_tvt, {2+$clog2(NINTERRUPTS){1'b0}}};
					end else begin
						c_res = {r_s_tvt[RV-1:3+$clog2(NINTERRUPTS)], {3+$clog2(NINTERRUPTS){1'b0}}};
					end

		13'b0_00_01_0100_0000:		//  scratch reg for sup trap handlers
					c_res = r_s_scratch;
		13'b0_00_01_0100_0001:		//  sup SEPC
					c_res = {r_s_epc, 1'b0};
		13'b0_00_01_0100_0010:		//  sup trap cause
					if (rv32) begin
						c_res = {r_s_trap_interrupt, 31'b0, r_s_trap_interrupt, !clic_s_enable?1'b0:r_s_inhv, 1'b0, !clic_s_enable?1'b0:r_s_pp, !clic_s_enable?1'b0:r_s_pie, 3'b000, !clic_s_enable?8'b0:r_s_pil, 4'b0000, r_s_trap_cause};
					end else begin
						c_res = {r_s_trap_interrupt, 32'b0, !clic_s_enable?1'b0:r_s_inhv, 1'b0, !clic_s_enable?1'b0:r_s_pp, !clic_s_enable?1'b0:r_s_pie, 3'b000, !clic_s_enable?8'b0:r_s_pil, 4'b0000, r_s_trap_cause};
					end
		13'b0_00_01_0100_0011:		//  sup bad address or instruction 
					c_res = r_s_mtval;
		13'b0_00_01_0100_0100:		//  sup interrupt pending
					c_res = {48'b0, s_ext, 2'b00, s_eip, u_eip, 2'b0, s_tip, u_tip, 2'b0, s_sip, u_sip};
		13'b0_00_01_0100_0101:		//  sup nxti
					if (!rv32) begin
						c_res = !clic_s_enable || !cpu_mode[1] || clic_s_il <= r_s_pil || clic_s_il <= r_s_intthresh || !clic_s_vec? 64'b0: {r_s_tvt[RV-1:3+$clog2(NINTERRUPTS)], clic_s_int, 3'b000};
					end else begin
						c_res = !clic_s_enable || !cpu_mode[1] || clic_s_il <= r_s_pil || clic_s_il <= r_s_intthresh || !clic_s_vec? 32'b0: {r_s_tvt, clic_s_int, 2'b00};
					end
		13'b0_00_01_0100_0110:		//  sup current interrupt levels FIXME address
					c_res = {32'b0, 8'b0, 8'b0, r_s_il, r_u_il};
		13'b0_00_01_0100_1000:		//  sup scratchsw
					c_res = r_m_pp == 1 ? r_s_scratch : r_r1;
		13'b0_00_01_0100_1001:		//  sup scratchswl
					c_res = (r_s_pil == 0) != (clic_s_il != 0)  ? r_s_scratch : r_r1;
		13'b0_00_01_0100_1010:		//  sup int threshold	FIXME address
					c_res = {32'b0, 8'b0, 8'b0, 8'b0, r_s_intthresh};
		13'b0_00_01_0100_1011:		//  sup clic base	FIXME address
					c_res = {S_CLIC_BASE[RV-1:20], cpu_id[3:0], 16'b0};

		13'b0_00_01_1000_0000:		//  sup address translation and protection
					if (rv32) begin
						c_res = {r_s_vm_mode[1], r_s_asid[8:0], r_s_ppn[21:0]};
					end else begin
						c_res = {(r_s_vm_mode[0]?4'd0:r_s_vm_mode[2]?4'd8:4'd9), {r_unified_asid?r_s_asid[15]:1'b0, r_s_asid[14:0]}, r_s_ppn};
					end

		// hypervisor
		13'b?_01_10_0000_0000:		//	hypervisor status register
					if (RV == 64) begin
						c_res = {30'b0, r_vsxl, 9'b0, r_vtsr, r_sp2p, r_spv, r_stl, r_vsbe, 4'b0, r_sprv};
					end else begin
						c_res = {9'b0, r_vtsr, r_sp2p, r_spv, r_stl, r_vsbe, 4'b0, r_sprv};
					end
		13'b?_01_10_0000_0010:		//	hypervisor exception delegation reg
					c_res = {48'b0, r_h_deleg_storeamo_pf&r_m_deleg_storeamo_pf, 1'b0, r_h_deleg_load_pf&r_m_deleg_load_pf, r_h_deleg_ins_pf&r_m_deleg_ins_pf, 2'b0, r_h_deleg_env_s&r_m_deleg_env_s, r_h_deleg_env_u&r_m_deleg_env_u, r_h_deleg_storeamo_access&r_m_deleg_storeamo_access, r_h_deleg_storeamo_align&r_m_deleg_storeamo_align, r_h_deleg_load_access&r_m_deleg_load_access, r_h_deleg_load_align&r_m_deleg_load_align, r_h_deleg_break&r_m_deleg_break, r_h_deleg_illegal_inst&r_m_deleg_illegal_inst, r_h_deleg_inst_access&r_m_deleg_inst_access, r_h_deleg_inst_align&r_m_deleg_inst_align};
		13'b?_01_10_0000_0011:		//	hypervisor interrupt delegation reg
					c_res = {47'b0, r_h_deleg_ext&r_m_deleg_ext, r_h_deleg_mei&r_m_deleg_mei, 1'b0, r_h_deleg_sei&r_m_deleg_sei, r_h_deleg_uei&r_m_deleg_uei, r_h_deleg_mti&r_m_deleg_mti, 1'b0, r_h_deleg_sti&r_m_deleg_sti, r_h_deleg_uti&r_m_deleg_uti, r_h_deleg_msi&r_m_deleg_msi, 1'b0, r_h_deleg_ssi&r_m_deleg_ssi, r_h_deleg_usi&r_m_deleg_usi};
		13'b?_01_10_0000_0101:		//	hypervisor delta for VS/VU mode timer
					c_res = r_htimedelta;
		13'b?_01_10_0000_0110:		//	hypervisor counter enable
					c_res = {61'b0, r_h_ir, r_h_tm, r_h_cy};
		13'b?_01_10_0001_0101:		//	upper bits of delta for VS/VU mode timer for RV32
					c_res = r_htimedelta[63:32];
		13'b?_01_10_1000_0000:		//  hypervisor guest address translation/protection
					// something for RV32 here
					if (rv32) begin
						c_res = {r_h_vm_mode[1], r_h_asid[8:0], r_h_ppn[21:0]};
					end else begin
						c_res = {(r_h_vm_mode[0]?4'd0:r_h_vm_mode[2]?4'd8:4'd9), r_h_asid, r_h_ppn};
					end
		
		// virtual supervisor registers
		13'b?_00_10_0000_0000:		//	virt sup status register
					c_res = {((r_xs==3)|(r_fs==3)?1'b1:1'b0), 29'b0, r_uxl, 12'b0, r_s_mxr, r_vs_sum, 1'b0, r_xs, r_fs, 4'b0, r_s_pp, 1'b0, r_vs_pie, r_u_pie, 3'b0, r_vs_ie, r_u_ie};
		13'b0_00_10_0000_0100,		//  virt sup interrupt enable register
		13'b1_00_01_0000_0100:		//  virt sup interrupt enable register
					c_res = clic_h_enable?64'b0:{54'b0, r_vs_eie, r_u_eie, 2'b0, r_vs_tie, r_u_tie, 2'b0, r_vs_sie, r_u_sie};
		13'b0_00_10_0000_0101,		//  virt sup trap handler base address
		13'b1_00_01_0000_0101:		//  virt sup trap handler base address
					c_res = {r_vs_trap_base[RV-1:6], clic_h_enable?4'b0:r_vs_trap_base[5:2], r_vs_trap_type};
		13'b0_00_10_0000_0111,
		13'b1_00_01_0000_0111:		//  virt sup tvt base address
					if (rv32) begin
						c_res = {r_vs_tvt, {2+$clog2(NINTERRUPTS){1'b0}}};
					end else begin
						c_res = {r_vs_tvt[RV-1:3+$clog2(NINTERRUPTS)], {3+$clog2(NINTERRUPTS){1'b0}}};
					end

		13'b0_00_10_0100_0000,		//  virt scratch reg for sup trap handlers
		13'b1_00_01_0100_0000:		//  virt scratch reg for sup trap handlers
					c_res = r_vs_scratch;
		13'b0_00_10_0100_0001,		//  virt sup SEPC
		13'b1_00_01_0100_0001:		//  virt sup SEPC
					c_res = {r_vs_epc, 1'b0};
		13'b0_00_10_0100_0010,		//  virt sup trap cause
		13'b1_00_01_0100_0010:		//  virt sup trap cause
					if (rv32) begin
						c_res = {r_s_trap_interrupt, 31'b0, r_s_trap_interrupt, !clic_h_enable?1'b0:r_vs_inhv, 1'b0, !clic_h_enable?1'b0:r_s_pp, !clic_h_enable?1'b0:r_vs_pie, 3'b000, !clic_h_enable?1'b0:r_vs_pil, 4'b0000, r_m_trap_cause};	// FIXME r_m_trap_cause
					end else begin
						c_res = {r_s_trap_interrupt, 32'b0, !clic_h_enable?1'b0:r_vs_inhv, 1'b0, !clic_h_enable?1'b0:r_s_pp, !clic_h_enable?1'b0:r_vs_pie, 3'b000, !clic_h_enable?1'b0:r_vs_pil, 4'b0000, r_m_trap_cause};	// FIXME r_m_trap_cause
					end
		13'b0_00_10_0100_0011,		//  virt sup bad address or instruction 
		13'b1_00_01_0100_0011:		//  virt sup bad address or instruction 
					c_res = r_s_mtval;
		13'b0_00_10_0100_0100,		//  virt sup interrupt pending
		13'b1_00_01_0100_0100:		//  virt sup interrupt pending
					c_res = {48'b0, h_ext, 2'b00, h_eip, u_eip, 2'b0, h_tip, u_tip, 2'b0, h_sip, u_sip};
		13'b0_00_10_0100_0101,		//  virt sup nxti
		13'b1_00_01_0100_0101:		//  virt sup nxti
					if (!rv32) begin
						c_res = !clic_h_enable || !clic_s_pending || !cpu_mode[1] || clic_h_il <= r_vs_pil || clic_h_il <= r_vs_intthresh || !clic_h_vec? 64'b0: {r_vs_tvt[RV-1:3+$clog2(NINTERRUPTS)], clic_h_int, 3'b000};
					end else begin
						c_res = !clic_h_enable || !clic_s_pending || !cpu_mode[1] || clic_h_il <= r_vs_pil || clic_h_il <= r_vs_intthresh || !clic_h_vec? 32'b0: {r_vs_tvt, clic_h_int, 2'b00};
					end
		13'b0_00_10_0100_0110,		//  virt sup current interrupt levels FIXME address
		13'b1_00_01_0100_0110:		//  virt sup current interrupt levels FIXME address
					c_res = {32'b0, 8'b0, 8'b0, r_vs_il, r_u_il};
		13'b0_00_10_0100_1000:		//  virt sup scratchsw
					c_res = r_m_pp == 2 ? r_vs_scratch : r_r1;
		13'b1_00_01_0100_1000:		//  virt sup scratchsw
					c_res = r_m_pp == 1 ? r_vs_scratch : r_r1;
		13'b0_00_10_0100_1001,		//  virt sup scratchswl
		13'b1_00_01_0100_1001:		//  virt sup scratchswl
					c_res = (r_vs_pil == 0) != (clic_h_il != 0)  ? r_vs_scratch : r_r1;
		13'b0_00_10_0100_1010,		//  virt sup int threshold	FIXME address
		13'b1_00_01_0100_1010:		//  virt sup int threshold	FIXME address
					c_res = {32'b0, 8'b0, 8'b0, 8'b0, r_vs_intthresh};
		13'b0_00_10_0100_1011,		//  virt sup clic base	FIXME address
		13'b1_00_01_0100_1011:		//  virt sup clic base	FIXME address
					c_res = {VS_CLIC_BASE[RV-1:20], cpu_id[3:0], 16'b0};

		13'b0_00_10_0100_1000,		//  virt sup address translation and protection
		13'b1_00_01_0100_1000:		//  virt sup address translation and protection
					if (rv32) begin
						c_res = {r_vs_vm_mode[1], r_vs_asid[8:0], r_vs_ppn[21:0]};
					end else begin
						c_res = {(r_vs_vm_mode[0]?4'd0:r_vs_vm_mode[2]?4'd8:4'd9), r_vs_asid, r_vs_ppn};
					end

		// machine mode
		13'b?_00_11_0000_0000:		//	mach status register
					if (RV == 64) begin
						c_res = {((r_xs==3)|(r_fs==3)?1'b1:1'b0), 23'b0, r_mpv, r_mtl, 2'b0,r_sxl, r_uxl, 9'b0, r_tsr, r_tw, r_tvm, r_m_mxr, r_s_sum, r_mprv, r_xs, r_fs, r_m_pp, 2'b0, r_s_pp, r_m_pie, 1'b0, r_s_pie, r_u_pie, r_m_ie, 1'b0, r_s_ie, r_u_ie};
					end else begin
						c_res = {((r_xs==3)|(r_fs==3)?1'b1:1'b0), 8'b0, r_tsr, r_tw, r_tvm, r_m_mxr, r_s_sum, r_mprv, r_xs, r_fs, r_m_pp, 2'b0, r_s_pp, r_m_pie, 1'b0, r_s_pie, r_u_pie, r_m_ie, 1'b0, r_s_ie, r_u_ie};
					end
		13'b?_00_11_0001_0000:		// 32-bit extension to status
					c_res = {r_mpv, r_mtl, 6'b0};
		13'b?_00_11_0000_0001:		//	ISA and extensions
					if (RV == 64) begin
`ifdef FP
						c_res = {r_mxl, 37'b0, 17'b0_0001_0100_0011_0001,r_hs,5'b010_11, b, 1'b1}; // 64  ACDFIMNSU
`else
						c_res = {r_mxl, 37'b0, 17'b0_0001_0100_0011_0001,r_hs,5'b000_01, b, 1'b1}; // 64  ACIMNSU
`endif
					end else begin
`ifdef FP
						c_res = {r_mxl, 5'b0, 17'b0_0001_0100_0011_0001_, r_hs,5'b010_01, b, 1'b1}; // 32  ACFIMNSU
`else
						c_res = {r_mxl, 5'b0, 17'b0_0001_0100_0011_0001_, r_hs,5'b000_01, b, 1'b1}; // 32  ACIMNSU
`endif
					end
		13'b?_00_11_0000_0010:		//  mach exception delegation reg
					c_res = {48'b0, r_m_deleg_storeamo_pf, 1'b0, r_m_deleg_load_pf, r_m_deleg_ins_pf, 2'b0, r_m_deleg_env_s, r_m_deleg_env_u, r_m_deleg_storeamo_access, r_m_deleg_storeamo_align, r_m_deleg_load_access, r_m_deleg_load_align, r_m_deleg_break, r_m_deleg_illegal_inst, r_m_deleg_inst_access, r_m_deleg_inst_align};
		13'b?_00_11_0000_0011:		//  mach interrupt delegation reg
					c_res = {47'b0, r_m_deleg_ext, r_m_deleg_mei, 1'b0, r_m_deleg_sei, r_m_deleg_uei, r_m_deleg_mti, 1'b0, r_m_deleg_sti, r_m_deleg_uti, r_m_deleg_msi, 1'b0, r_m_deleg_ssi, r_m_deleg_usi};
		13'b?_00_11_0000_0100:		//  mach interrupt enable register
					c_res = clic_m_enable?64'b0:{52'b0, r_m_eie, 1'b0, r_s_eie, r_u_eie, r_m_tie, 1'b0,  r_s_tie, r_u_tie, r_m_sie, 1'b0, r_s_sie, r_u_sie};
		13'b?_00_11_0000_0101:		//  mach trap handler base address
					c_res = {r_m_trap_base[RV-1:6], clic_m_enable?4'b0:r_m_trap_base[5:2], r_m_trap_type};
		13'b?_00_11_0000_0110:		//  mach counter enable
					c_res = {61'b0, r_m_ir, r_m_tm, r_m_cy};
		13'b?_00_11_0000_0111:		//  virt sup tvt base address
					if (rv32) begin
						c_res = {r_m_tvt, {2+$clog2(NINTERRUPTS){1'b0}}};
					end else begin
						c_res = {r_m_tvt[RV-1:3+$clog2(NINTERRUPTS)], {3+$clog2(NINTERRUPTS){1'b0}}};
					end
		13'b?_00_11_0010_0000:		//  mach count inhibit
					c_res = {61'b0, r_i_ir, 1'b0, r_i_cy};
		13'b?_00_11_0100_0000:		//  scratch reg for mach trap handlers
					c_res = r_m_scratch;
		13'b?_00_11_0100_0001:		//  mach MEPC
					c_res = {r_m_epc, 1'b0};
		13'b?_00_11_0100_0010:		//  mach trap cause
					if (rv32) begin
						c_res = {r_m_trap_interrupt, 31'b0,r_m_trap_interrupt, !clic_m_enable?1'b0:r_m_inhv, !clic_m_enable?2'b0:r_m_pp, !clic_m_enable?1'b0:r_m_pie, 3'b000, !clic_m_enable?8'b0:r_m_pil, 4'b0000, r_m_trap_cause};
					end else begin
						c_res = {r_m_trap_interrupt, 32'b0,  !clic_m_enable?1'b0:r_m_inhv, !clic_m_enable?2'b0:r_m_pp, !clic_m_enable?1'b0:r_m_pie, 3'b000, !clic_m_enable?8'b0:r_m_pil, 4'b0000, r_m_trap_cause};	
					end
		13'b?_00_11_0100_0011:		//  mach bad address or instruction 
					c_res = r_m_mtval;
		13'b?_00_11_0100_0100:		//  mach interrupt pending
					c_res = {48'b0, m_ext, m_eip, 1'b0, s_eip, u_eip, m_tip, 1'b0,  s_tip, u_tip, m_sip, 1'b0, s_sip, u_sip};
		13'b?_00_11_0100_0101:		// mach nxti
					if (!rv32) begin
						c_res = !clic_m_enable || !clic_m_pending || !cpu_mode[3] || clic_m_il <= r_m_pil || clic_m_il <= r_m_intthresh || !clic_m_vec? 64'b0: {r_m_tvt[RV-1:3+$clog2(NINTERRUPTS)], clic_m_int, 3'b000};
					end else begin
						c_res = !clic_m_enable || !clic_m_pending || !cpu_mode[3] || clic_m_il <= r_m_pil || clic_m_il <= r_m_intthresh || !clic_m_vec? 32'b0: {r_m_tvt, clic_m_int, 2'b00};
					end
		13'b?_00_11_0100_0110:		// mach current interrupt levels FIXME address
					c_res = {32'b0, r_m_il, 8'b0, r_s_il, r_u_il};
		13'b?_00_11_0100_1000:		//  mach scratchsw
					c_res = r_m_pp == 3 ? r_m_scratch : r_r1;
		13'b?_00_11_0100_1001:		//  mach scratchswl
					c_res = (r_m_pil == 0) != (clic_m_il != 0)  ? r_m_scratch : r_r1;
		13'b?_00_11_0100_1010:		//  mach int threshold	FIXME address
					c_res = {32'b0, 8'b0, 8'b0, 8'b0, r_m_intthresh};
		13'b?_00_11_0100_1011:		//  mach clic base	FIXME address
					c_res = {M_CLIC_BASE[RV-1:20], cpu_id[3:0], 16'b0};

		13'b?_00_11_1010_0000:		//  Physical memory config
					if (!rv32) begin
						c_res = pmp_data_0a;
					end else begin
						c_res = pmp_data_0b;
					end
		13'b?_00_11_1010_0001:		
					c_res = pmp_data_1;
		13'b?_00_11_1010_0010:		
					if (!rv32) begin
						c_res = pmp_data_2a;
					end else begin
						c_res = pmp_data_2b;
					end
		13'b?_00_11_1010_0011:		
					c_res = pmp_data_3;
		13'b?_00_11_1011_0000:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[0]};
		13'b?_00_11_1011_0001:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[1]};
		13'b?_00_11_1011_0010:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[2]};
		13'b?_00_11_1011_0011:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[3]};
		13'b?_00_11_1011_0100:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[4]};
		13'b?_00_11_1011_0101:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[5]};
		13'b?_00_11_1011_0110:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[6]};
		13'b?_00_11_1011_0111:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[7]};
		13'b?_00_11_1011_1000:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[8]};
		13'b?_00_11_1011_1001:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[9]};
		13'b?_00_11_1011_1010:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[10]};
		13'b?_00_11_1011_1011:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[11]};
		13'b?_00_11_1011_1100:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[12]};
		13'b?_00_11_1011_1101:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[13]};
		13'b?_00_11_1011_1110:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[14]};
		13'b?_00_11_1011_1111:		//  Physical memory protection address reg
					c_res = {10'b0, x_pmp_addr[15]};

		13'b?_01_11_1010_0000,		//  mach tselect
		13'b?_01_11_1010_0001,		//  mach data1
		13'b?_01_11_1010_0010,		//  mach data2
		13'b?_01_11_1010_0011,		//  mach data3

		13'b?_01_11_1011_0000,		//  mach debug csr
		13'b?_01_11_1011_0001,		//  mach debug pc
		13'b?_01_11_1011_0010,		//  mach debug scratch 0
		13'b?_01_11_1011_0011:		//  mach debug scratch 1
					c_res = 64'h0; // for the moment

		13'b?_11_11_0001_0001:		//	vendor ID
					c_res = 64'h0; // for the moment
		13'b?_11_11_0001_0010:		//	architecture ID
					c_res = 64'h4d6f_6f6e_6261_7365;
		13'b?_11_11_0001_0011:		//	implemention ID
					c_res = 64'h5672_6f6f_6d21_3030;
		13'b?_11_11_0001_0100:		//	HART ID
					c_res = {55'b0, cpu_id, hart};
		13'b?_11_11_1100_0000:		// CLNT BASE
					c_res = 64'hffffffffff000000;
		13'b?_11_11_1100_0001:		// PLIC BASE
					c_res = 64'hfffffffff4000000;

		//
		//	Moonbase specific registers
		//


		13'b?_10_11_1111_1000:		//	pseudo random 
					c_res = {32'b0, r_pseudo_random};
		13'b?_10_11_1111_1001:		//	options
					c_res = {55'b0, r_trace_scale, r_trace_enable, r_unified_asid};
		13'b?_10_11_1111_1010:		//	all reset
					c_res = 0;
		//
		//

		default:	c_res = 0;
		endcase
	end

	//
	//	interrupts
	//

	reg int_pending;
	reg	int_m_pending, int_h_pending, int_s_pending, int_u_pending;
	reg	int_m_vec, int_h_vec, int_s_vec, int_u_vec;
	reg [4:0]mvec, hvec, svec, uvec;

	always @(*) begin
		if (clic_m_enable) begin
			mvec = clic_m_int;
			m_ext = 0;
			m_eip = 0;
			m_tip = 0;
			m_sip = 0;
			int_m_pending = clic_m_pending && clic_m_il > r_m_il && clic_m_il > r_m_intthresh;
			int_m_vec = clic_m_vec;
		end else begin
			m_ext = io_interrupts[NINTERRUPTS-1:12]&~r_m_deleg_ext;
			m_sip = (io_interrupts[3]&~r_m_deleg_msi)||
					(io_interrupts[1]&~r_m_deleg_ssi)||
					(io_interrupts[0]&~r_m_deleg_usi);
			m_tip = (io_interrupts[7]&~r_m_deleg_mti)||
					(io_interrupts[5]&~r_m_deleg_sti)||
					(io_interrupts[4]&~r_m_deleg_uti);
			m_eip = (io_interrupts[11]&~r_m_deleg_mei)||
					(io_interrupts[9]&~r_m_deleg_sei)||
					(io_interrupts[8]&~r_m_deleg_uei);
			int_m_pending = (m_tip&r_m_tie) | (m_sip&r_m_sie) | (m_eip&r_m_eie) | |(m_ext&r_m_exte);
			int_m_vec = r_m_trap_type[0];
			casez ({(m_ext&r_m_exte), (m_eip&r_m_eie), (m_tip&r_m_tie), (m_sip&r_m_sie)}) // synthesis full_case parallel_case
			7'b1???_?_?_?:	mvec = 15;
			7'b01??_?_?_?:	mvec = 14;
			7'b001?_?_?_?:	mvec = 13;
			7'b0001_?_?_?:	mvec = 12;
			7'b0000_1_?_?:	mvec = 11;
			7'b0000_0_1_?:	mvec = 7;
			7'b0000_0_0_1:	mvec = 3;
			endcase
		end
		h_ext=0;
		h_eip=0;
		h_tip=0;
		h_sip=0;
		int_h_pending = 0;
		int_h_vec = 0;
		if (clic_h_enable) begin
		end else begin
		end
		if (clic_s_enable) begin
			svec = clic_s_int;
			s_ext = 0;
			s_eip = 0;
			s_tip = 0;
			s_sip = 0;
			int_s_pending = clic_s_pending && clic_s_il > r_s_il && clic_s_il > r_s_intthresh;
			int_s_vec = clic_s_vec;
		end else begin
			s_ext = io_interrupts[NINTERRUPTS-1:12]&r_m_deleg_ext&~r_s_deleg_ext&(r_v?r_h_deleg_ext:~5'b0);
			s_sip = (io_interrupts[3]&r_m_deleg_msi&~r_s_deleg_msi&(~r_v|r_h_deleg_msi)) ||
					(io_interrupts[1]&r_m_deleg_ssi&~r_s_deleg_ssi&(~r_v|r_h_deleg_ssi)) ||
					(io_interrupts[0]&r_m_deleg_usi&~r_s_deleg_usi&(~r_v|r_h_deleg_usi));
			s_tip = (io_interrupts[7]&r_m_deleg_mti&~r_s_deleg_mti&(~r_v|r_h_deleg_mti)) ||
					(io_interrupts[5]&r_m_deleg_sti&~r_s_deleg_sti&(~r_v|r_h_deleg_sti)) ||
					(io_interrupts[4]&r_m_deleg_uti&~r_s_deleg_uti&(~r_v|r_h_deleg_uti));
			s_eip = (io_interrupts[11]&r_m_deleg_mei&~r_s_deleg_mei&(~r_v|r_h_deleg_mei)) ||
					(io_interrupts[9]&r_m_deleg_sei&~r_s_deleg_sei&(~r_v|r_h_deleg_sei)) ||
					(io_interrupts[8]&r_m_deleg_uei&~r_s_deleg_uei&(~r_v|r_h_deleg_uei));
			int_s_pending = (s_tip&r_s_tie) | (s_sip&r_s_sie) | (s_eip&r_s_eie) | |(s_ext&r_s_exte);
			int_s_vec = r_s_trap_type[0];
			casez ({(s_ext&r_s_exte), (s_eip&r_s_eie), (s_tip&r_s_tie), (s_sip&r_s_sie)}) // synthesis full_case parallel_case
			7'b1???_?_?_?:	svec = 15;
			7'b01??_?_?_?:	svec = 14;
			7'b001?_?_?_?:	svec = 13;
			7'b0001_?_?_?:	svec = 12;
			7'b0000_1_?_?:	svec = 9;
			7'b0000_0_1_?:	svec = 5;
			7'b0000_0_0_1:	svec = 1;
			endcase
		end
		if (clic_u_enable) begin
			uvec = clic_u_int;
			u_ext = 0;
			u_eip = 0;
			u_tip = 0;
			u_sip = 0;
			int_u_pending = clic_u_pending && clic_u_il > r_u_il && clic_u_il > r_u_intthresh;
			int_u_vec = clic_u_vec;
		end else begin
			u_ext = io_interrupts[NINTERRUPTS-1:12]&r_m_deleg_ext&r_s_deleg_ext&(r_v?r_h_deleg_ext:~5'b0);
			u_sip = (io_interrupts[3]&r_m_deleg_msi&r_s_deleg_msi&(~r_v|r_h_deleg_msi)) ||
					(io_interrupts[1]&r_m_deleg_ssi&r_s_deleg_ssi&(~r_v|r_h_deleg_ssi)) ||
					(io_interrupts[0]&r_m_deleg_usi&r_s_deleg_usi&(~r_v|r_h_deleg_usi));
			u_tip = (io_interrupts[7]&r_m_deleg_mti&r_s_deleg_mti&(~r_v|r_h_deleg_mti)) ||
					(io_interrupts[5]&r_m_deleg_sti&r_s_deleg_sti&(~r_v|r_h_deleg_sti)) ||
					(io_interrupts[4]&r_m_deleg_uti&r_s_deleg_uti&(~r_v|r_h_deleg_uti));
			u_eip = (io_interrupts[11]&r_m_deleg_mei&r_s_deleg_mei&(~r_v|r_h_deleg_mei)) ||
					(io_interrupts[9]&r_m_deleg_sei&r_s_deleg_sei&(~r_v|r_h_deleg_sei)) ||
					(io_interrupts[8]&r_m_deleg_uei&r_s_deleg_uei&(~r_v|r_h_deleg_uei));
			int_u_pending = (u_tip&r_u_tie) | (u_sip&r_u_sie) | (u_eip&r_u_eie) | |(u_ext&r_u_exte);
			int_u_vec = r_u_trap_type[0];
			casez ({(u_ext&r_u_exte), (u_eip&r_u_eie), (u_tip&r_u_tie), (u_sip&r_u_sie)}) // synthesis full_case parallel_case
			7'b1???_?_?_?:	uvec = 15;
			7'b01??_?_?_?:	uvec = 14;
			7'b001?_?_?_?:	uvec = 13;
			7'b0001_?_?_?:	uvec = 12;
			7'b0000_1_?_?:	uvec = 8;
			7'b0000_0_1_?:	uvec = 4;
			7'b0000_0_0_1:	uvec = 0;
			endcase
		end
		casez (r_cpu_mode)	// synthesis full_case parallel_case 
		4'b1???: int_pending = int_m_pending&r_m_ie;
		//2:
		4'b??1?: int_pending = (int_m_pending&r_m_ie) | (int_s_pending&r_s_ie);
		4'b???1: int_pending = (int_m_pending&r_m_ie) | (int_s_pending&r_s_ie) | (int_u_pending&r_u_ie);
		endcase
	end

	always @(*) begin
		reg_clic_ack = (clic_m_enable && csr_write && clic_m_pending && r_immed[11:0] == 12'h345 && !(r_control[1] && in != 0) && clic_m_enable && cpu_mode[3] && clic_m_il > r_m_pil && clic_m_il > r_m_intthresh && clic_m_vec) ||
					   (clic_s_enable && csr_write && clic_s_pending && r_immed[11:0] == 12'h145 && !(r_control[1] && in != 0) && clic_s_enable && cpu_mode[1] && clic_s_il > r_s_pil && clic_s_il > r_s_intthresh && clic_s_vec) ||
					   (clic_u_enable && csr_write && clic_u_pending && r_immed[11:0] == 12'h045 && !(r_control[1] && in != 0) && clic_u_enable && cpu_mode[0] && clic_u_il > r_u_pil && clic_u_il > r_u_intthresh && clic_u_vec);
	
		casez (cpu_mode) // synthesis full_case parallel_case
		4'b1???: reg_clic_ack_int = clic_m_int;
		4'b?1??: reg_clic_ack_int = clic_h_int;
		4'b??1?: reg_clic_ack_int = clic_s_int;
		4'b???1: reg_clic_ack_int = clic_u_int;
		endcase
	end

	assign interrupt_pending = int_pending;

	//

`ifdef SIMV
	always @(posedge clk)
	if (csr_write && r_immed[11:0] == 12'h8f0) begin
			$write("%c",in[7:0]);
	end
	always @(posedge clk)
	if (csr_write && r_immed[11:0] == 12'h8f1)
			$display("%x",in[31:0]);
	always @(posedge clk)
	if (csr_write && r_immed[11:0] == 12'h8f2)
			$display("%x",in[63:0]);
	always @(posedge clk)
	if (csr_write && r_immed[11:0] == 12'h8f3) begin
			$display("FAIL: %x",in[63:0]);
			$finish(0);
	end
	always @(posedge clk)
	if (csr_write && r_immed[11:0] == 12'h8f4) begin
			if (in[63:0] != 64'h010101010)
				$display("FINISHED: %x",in[63:0]);
			$finish(0);
	end
`endif
`ifdef SIMD
	always @(posedge clk) begin
		if (trap_br_enable && simd_enable) $display("T %d %x %x->%x", $time,r_rd,{{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc,1'b0},{trap_br,1'b0});
	end
	always @(posedge clk) begin
		if (int_br_enable && simd_enable) $display("I %d %x %x->%x", $time,r_rd,{{RV-VA_SZ{r_pc[VA_SZ-1]}}, r_pc,1'b0},{trap_br,1'b0});
	end
`endif

`ifdef AWS_DEBUG
    ila_csr ila_csr(.clk(clk),
            .trig_in(1'b0),
            .reset(reset),
            .cpu_mode(cpu_mode),
            .trap_br_enable(trap_br_enable),
            .trap_br(trap_br),
            .rd(rd),
            .m_trap_cause(r_m_trap_cause[7:0]),
            .m_epc({r_m_epc[31:1], 1'b0}),
            .m_mtval(r_m_mtval[31:0]),
            .s_trap_cause(r_s_trap_cause[7:0]),
            .s_epc({r_s_epc[31:1], 1'b0}),
            .s_mtval(r_s_mtval[31:0]),
            .xxtrig(xxtrig),
            .enable(enable),
            .immed(immed[16:0]),    // 17
            .control(control),       // 6
            .interrupt(interrupt),
			.r_m_trap_interrupt(r_m_trap_interrupt),
			.r_s_trap_interrupt(r_s_trap_interrupt),
			.interrupt_pending({interrupt_pending, int_m_pending&r_m_ie, int_s_pending&r_s_ie, int_u_pending&r_u_ie}),	// 4
			.r_x_pp({fast_int_u, s_pending, fast_int_s, r_s_pp, r_m_pp}),	// 6
			.r_fs(r_fs),	// 2
			.ie({r_m_ie, 1'b0, r_s_ie, r_u_ie}),    // 4
			.pie({r_m_pie, 1'b0, r_s_pie, r_u_pie}), // 4
			.r_v(r_v),
			.r_mpv(r_mpv),
			.r1(r1[31:0]),
			.wfi({s_tip, r_s_tie, csr_wfi_pause, csr_wfi_wake, int_m_pending, int_s_pending, int_u_pending}) // 8
            );

    wire [3:0]xxtrig_sel;
    wire [31:0]xxtrig_cmp;

    reg xcsr_trig;
    assign csr_trig=xcsr_trig;
    always @(*)
    case (xxtrig_sel)
    0: xcsr_trig = r_m_trap_cause[7:0]==xxtrig_cmp;
    1: xcsr_trig = r_s_trap_cause[7:0]==xxtrig_cmp;
    2: xcsr_trig = {r_m_epc[31:1],1'b0}==xxtrig_cmp;
    3: xcsr_trig = {r_s_epc[31:1],1'b0}==xxtrig_cmp;
    4: xcsr_trig = trap && r_control[3:0]==xxtrig_cmp;
    5: xcsr_trig = interrupt && r_control[3:0]==xxtrig_cmp;
	6: xcsr_trig = r_s_ie;
	7: xcsr_trig = r_s_trap_interrupt;
	8: xcsr_trig = r_enable && r_control[5:0]==xxtrig_cmp[5:0];
	9: xcsr_trig = fast_int_s || (interrupt && s_pending && !r_control[0]);
	10: xcsr_trig = r_enable && r_control[5:0]==xxtrig_cmp[5:0] && cpu_mode[0];
    11: xcsr_trig = cpu_mode[0] && trap && xxtrig_cmp[r_control[3:0]];	// trap from user mode
    12: xcsr_trig = cpu_mode[1] && trap && xxtrig_cmp[r_control[3:0]];	// trap from sup mode
	13: xcsr_trig = iret && r_control[1:0] == 3 && fast_int_s;
    default: xcsr_trig=0;
    endcase

    vio_cpu vio_csr_trig(.clk(clk),
            // outputs
             .xxtrig_sel(xxtrig_sel),
             .xxtrig_cmp(xxtrig_cmp)
            );

	vio_perf vio_perf(.clk(clk),
		.r_cycle(r_cycle[31:0]),
		.r_retired(r_retired[31:0]),
		.r_branches_retired(r_branches_retired[31:0]),
		.r_branches_predicted(r_branches_predicted[31:0]));

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

