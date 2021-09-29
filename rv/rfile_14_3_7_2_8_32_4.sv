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
module regfile(input clk, input reset,
`ifdef AWS_DEBUG
		input xxtrig,
`endif
		input read_enable0,input [RA-1:0]read_addr0,output [RV-1:0]read_data0,
		input read_enable1,input [RA-1:0]read_addr1,output [RV-1:0]read_data1,
		input read_enable2,input [RA-1:0]read_addr2,output [RV-1:0]read_data2,
		input read_enable3,input [RA-1:0]read_addr3,output [RV-1:0]read_data3,
		input read_enable4,input [RA-1:0]read_addr4,output [RV-1:0]read_data4,
		input read_enable5,input [RA-1:0]read_addr5,output [RV-1:0]read_data5,
		input read_enable6,input [RA-1:0]read_addr6,output [RV-1:0]read_data6,
		input read_enable7,input [RA-1:0]read_addr7,output [RV-1:0]read_data7,
		input read_enable8,input [RA-1:0]read_addr8,output [RV-1:0]read_data8,
		input read_enable9,input [RA-1:0]read_addr9,output [RV-1:0]read_data9,
		input read_enable10,input [RA-1:0]read_addr10,output [RV-1:0]read_data10,
		input read_enable11,input [RA-1:0]read_addr11,output [RV-1:0]read_data11,
		input read_enable12,input [RA-1:0]read_addr12,output [RV-1:0]read_data12,
		input read_enable13,input [RA-1:0]read_addr13,output [RV-1:0]read_data13,
		input read_enable14,input [RA-1:0]read_addr14,output [RV-1:0]read_data14,
		input read_enable15,input [RA-1:0]read_addr15,output [RV-1:0]read_data15,
		input read_enable16,input [RA-1:0]read_addr16,output [RV-1:0]read_data16,
		input write_enable0,input [LNCOMMIT-1:0]write_addr0,input [RV-1:0]write_data0,
		input write_enable1,input [LNCOMMIT-1:0]write_addr1,input [RV-1:0]write_data1,
		input write_enable2,input [LNCOMMIT-1:0]write_addr2,input [RV-1:0]write_data2,
		input write_enable3,input [LNCOMMIT-1:0]write_addr3,input [RV-1:0]write_data3,
		input write_enable4,input [LNCOMMIT-1:0]write_addr4,input [RV-1:0]write_data4,
		input write_enable5,input [LNCOMMIT-1:0]write_addr5,input [RV-1:0]write_data5,
		input write_enable6,input [LNCOMMIT-1:0]write_addr6,input [RV-1:0]write_data6,
		input write_enable7,input [LNCOMMIT-1:0]write_addr7,input [RV-1:0]write_data7,
		input write_enable8,input [LNCOMMIT-1:0]write_addr8,input [RV-1:0]write_data8,
`ifdef FP
		input fpu_read_enable0,input [RA-1:0]fpu_read_addr0,output [RV-1:0]fpu_read_data0,
		input fpu_read_enable1,input [RA-1:0]fpu_read_addr1,output [RV-1:0]fpu_read_data1,
		input fpu_read_enable2,input [RA-1:0]fpu_read_addr2,output [RV-1:0]fpu_read_data2,
		input fpu_read_enable3,input [RA-1:0]fpu_read_addr3,output [RV-1:0]fpu_read_data3,
		input write_fp0,
		input write_fp1,
		input write_fp2,
		input write_fp3,
		input write_fp4,
		input write_fp5,
		input write_fp6,
		input write_fp7,
		input write_fp8,
		input transfer_dest_fp0,
		input transfer_dest_fp1,
		input transfer_dest_fp2,
		input transfer_dest_fp3,
		input transfer_dest_fp4,
		input transfer_dest_fp5,
		input transfer_dest_fp6,
		input transfer_dest_fp7,
`endif
		input transfer_enable0,input [LNCOMMIT-1:0]transfer_source_addr0,input [4:0]transfer_dest_addr0,
		input transfer_enable1,input [LNCOMMIT-1:0]transfer_source_addr1,input [4:0]transfer_dest_addr1,
		input transfer_enable2,input [LNCOMMIT-1:0]transfer_source_addr2,input [4:0]transfer_dest_addr2,
		input transfer_enable3,input [LNCOMMIT-1:0]transfer_source_addr3,input [4:0]transfer_dest_addr3,
		input transfer_enable4,input [LNCOMMIT-1:0]transfer_source_addr4,input [4:0]transfer_dest_addr4,
		input transfer_enable5,input [LNCOMMIT-1:0]transfer_source_addr5,input [4:0]transfer_dest_addr5,
		input transfer_enable6,input [LNCOMMIT-1:0]transfer_source_addr6,input [4:0]transfer_dest_addr6,
		input transfer_enable7,input [LNCOMMIT-1:0]transfer_source_addr7,input [4:0]transfer_dest_addr7
		);
        parameter LNHART=0;
        parameter NHART=1;
        parameter RA=6;
        parameter RV=64;
        parameter HART=0;
        parameter NCOMMIT = 32;
        parameter LNCOMMIT = 5;
        
	reg [RA-1:0]r_rd_reg0;
	reg [RV-1:0]out0, r_out0, xout0;
	assign read_data0 = xout0;
	reg [RA-1:0]r_rd_reg1;
	reg [RV-1:0]out1, r_out1, xout1;
	assign read_data1 = xout1;
	reg [RA-1:0]r_rd_reg2;
	reg [RV-1:0]out2, r_out2, xout2;
	assign read_data2 = xout2;
	reg [RA-1:0]r_rd_reg3;
	reg [RV-1:0]out3, r_out3, xout3;
	assign read_data3 = xout3;
	reg [RA-1:0]r_rd_reg4;
	reg [RV-1:0]out4, r_out4, xout4;
	assign read_data4 = xout4;
	reg [RA-1:0]r_rd_reg5;
	reg [RV-1:0]out5, r_out5, xout5;
	assign read_data5 = xout5;
	reg [RA-1:0]r_rd_reg6;
	reg [RV-1:0]out6, r_out6, xout6;
	assign read_data6 = xout6;
	reg [RA-1:0]r_rd_reg7;
	reg [RV-1:0]out7, r_out7, xout7;
	assign read_data7 = xout7;
	reg [RA-1:0]r_rd_reg8;
	reg [RV-1:0]out8, r_out8, xout8;
	assign read_data8 = xout8;
	reg [RA-1:0]r_rd_reg9;
	reg [RV-1:0]out9, r_out9, xout9;
	assign read_data9 = xout9;
	reg [RA-1:0]r_rd_reg10;
	reg [RV-1:0]out10, r_out10, xout10;
	assign read_data10 = xout10;
	reg [RA-1:0]r_rd_reg11;
	reg [RV-1:0]out11, r_out11, xout11;
	assign read_data11 = xout11;
	reg [RA-1:0]r_rd_reg12;
	reg [RV-1:0]out12, r_out12, xout12;
	assign read_data12 = xout12;
	reg [RA-1:0]r_rd_reg13;
	reg [RV-1:0]out13, r_out13, xout13;
	assign read_data13 = xout13;
	reg [RA-1:0]r_rd_reg14;
	reg [RV-1:0]out14, r_out14, xout14;
	assign read_data14 = xout14;
	reg [RA-1:0]r_rd_reg15;
	reg [RV-1:0]out15, r_out15, xout15;
	assign read_data15 = xout15;
	reg [RA-1:0]r_rd_reg16;
	reg [RV-1:0]out16, r_out16, xout16;
	assign read_data16 = xout16;
`ifdef FP
	reg [RA-1:0]r_rd_fpu_reg0;
	reg [RV-1:0]fpu_out0, r_fpu_out0, x_fpu_out0;
	assign fpu_read_data0 = x_fpu_out0;
	reg [RA-1:0]r_rd_fpu_reg1;
	reg [RV-1:0]fpu_out1, r_fpu_out1, x_fpu_out1;
	assign fpu_read_data1 = x_fpu_out1;
	reg [RA-1:0]r_rd_fpu_reg2;
	reg [RV-1:0]fpu_out2, r_fpu_out2, x_fpu_out2;
	assign fpu_read_data2 = x_fpu_out2;
	reg [RA-1:0]r_rd_fpu_reg3;
	reg [RV-1:0]fpu_out3, r_fpu_out3, x_fpu_out3;
	assign fpu_read_data3 = x_fpu_out3;
`endif
	always @(posedge clk) begin
		r_out0 <= out0;
		r_rd_reg0 <= read_addr0;
		r_out1 <= out1;
		r_rd_reg1 <= read_addr1;
		r_out2 <= out2;
		r_rd_reg2 <= read_addr2;
		r_out3 <= out3;
		r_rd_reg3 <= read_addr3;
		r_out4 <= out4;
		r_rd_reg4 <= read_addr4;
		r_out5 <= out5;
		r_rd_reg5 <= read_addr5;
		r_out6 <= out6;
		r_rd_reg6 <= read_addr6;
		r_out7 <= out7;
		r_rd_reg7 <= read_addr7;
		r_out8 <= out8;
		r_rd_reg8 <= read_addr8;
		r_out9 <= out9;
		r_rd_reg9 <= read_addr9;
		r_out10 <= out10;
		r_rd_reg10 <= read_addr10;
		r_out11 <= out11;
		r_rd_reg11 <= read_addr11;
		r_out12 <= out12;
		r_rd_reg12 <= read_addr12;
		r_out13 <= out13;
		r_rd_reg13 <= read_addr13;
		r_out14 <= out14;
		r_rd_reg14 <= read_addr14;
		r_out15 <= out15;
		r_rd_reg15 <= read_addr15;
		r_out16 <= out16;
		r_rd_reg16 <= read_addr16;
`ifdef FP
		r_fpu_out0 <= fpu_out0;
		r_rd_fpu_reg0 <= fpu_read_addr0;
		r_fpu_out1 <= fpu_out1;
		r_rd_fpu_reg1 <= fpu_read_addr1;
		r_fpu_out2 <= fpu_out2;
		r_rd_fpu_reg2 <= fpu_read_addr2;
		r_fpu_out3 <= fpu_out3;
		r_rd_fpu_reg3 <= fpu_read_addr3;
`endif
	end

`ifdef VSYNTH
    reg [RV-1:0]r_real_reg_1;
    reg [RV-1:0]r_real_reg_2;
    reg [RV-1:0]r_real_reg_3;
    reg [RV-1:0]r_real_reg_4;
    reg [RV-1:0]r_real_reg_5;
    reg [RV-1:0]r_real_reg_6;
    reg [RV-1:0]r_real_reg_7;
    reg [RV-1:0]r_real_reg_8;
    reg [RV-1:0]r_real_reg_9;
    reg [RV-1:0]r_real_reg_10;
    reg [RV-1:0]r_real_reg_11;
    reg [RV-1:0]r_real_reg_12;
    reg [RV-1:0]r_real_reg_13;
    reg [RV-1:0]r_real_reg_14;
    reg [RV-1:0]r_real_reg_15;
    reg [RV-1:0]r_real_reg_16;
    reg [RV-1:0]r_real_reg_17;
    reg [RV-1:0]r_real_reg_18;
    reg [RV-1:0]r_real_reg_19;
    reg [RV-1:0]r_real_reg_20;
    reg [RV-1:0]r_real_reg_21;
    reg [RV-1:0]r_real_reg_22;
    reg [RV-1:0]r_real_reg_23;
    reg [RV-1:0]r_real_reg_24;
    reg [RV-1:0]r_real_reg_25;
    reg [RV-1:0]r_real_reg_26;
    reg [RV-1:0]r_real_reg_27;
    reg [RV-1:0]r_real_reg_28;
    reg [RV-1:0]r_real_reg_29;
    reg [RV-1:0]r_real_reg_30;
    reg [RV-1:0]r_real_reg_31;
`ifdef FP
    reg [RV-1:0]r_real_fp_reg_0;
    reg [RV-1:0]r_real_fp_reg_1;
    reg [RV-1:0]r_real_fp_reg_2;
    reg [RV-1:0]r_real_fp_reg_3;
    reg [RV-1:0]r_real_fp_reg_4;
    reg [RV-1:0]r_real_fp_reg_5;
    reg [RV-1:0]r_real_fp_reg_6;
    reg [RV-1:0]r_real_fp_reg_7;
    reg [RV-1:0]r_real_fp_reg_8;
    reg [RV-1:0]r_real_fp_reg_9;
    reg [RV-1:0]r_real_fp_reg_10;
    reg [RV-1:0]r_real_fp_reg_11;
    reg [RV-1:0]r_real_fp_reg_12;
    reg [RV-1:0]r_real_fp_reg_13;
    reg [RV-1:0]r_real_fp_reg_14;
    reg [RV-1:0]r_real_fp_reg_15;
    reg [RV-1:0]r_real_fp_reg_16;
    reg [RV-1:0]r_real_fp_reg_17;
    reg [RV-1:0]r_real_fp_reg_18;
    reg [RV-1:0]r_real_fp_reg_19;
    reg [RV-1:0]r_real_fp_reg_20;
    reg [RV-1:0]r_real_fp_reg_21;
    reg [RV-1:0]r_real_fp_reg_22;
    reg [RV-1:0]r_real_fp_reg_23;
    reg [RV-1:0]r_real_fp_reg_24;
    reg [RV-1:0]r_real_fp_reg_25;
    reg [RV-1:0]r_real_fp_reg_26;
    reg [RV-1:0]r_real_fp_reg_27;
    reg [RV-1:0]r_real_fp_reg_28;
    reg [RV-1:0]r_real_fp_reg_29;
    reg [RV-1:0]r_real_fp_reg_30;
    reg [RV-1:0]r_real_fp_reg_31;
`endif
    reg [RV-1:0]r_commit_reg_0;
    reg [RV-1:0]r_commit_reg_1;
    reg [RV-1:0]r_commit_reg_2;
    reg [RV-1:0]r_commit_reg_3;
    reg [RV-1:0]r_commit_reg_4;
    reg [RV-1:0]r_commit_reg_5;
    reg [RV-1:0]r_commit_reg_6;
    reg [RV-1:0]r_commit_reg_7;
    reg [RV-1:0]r_commit_reg_8;
    reg [RV-1:0]r_commit_reg_9;
    reg [RV-1:0]r_commit_reg_10;
    reg [RV-1:0]r_commit_reg_11;
    reg [RV-1:0]r_commit_reg_12;
    reg [RV-1:0]r_commit_reg_13;
    reg [RV-1:0]r_commit_reg_14;
    reg [RV-1:0]r_commit_reg_15;
    reg [RV-1:0]r_commit_reg_16;
    reg [RV-1:0]r_commit_reg_17;
    reg [RV-1:0]r_commit_reg_18;
    reg [RV-1:0]r_commit_reg_19;
    reg [RV-1:0]r_commit_reg_20;
    reg [RV-1:0]r_commit_reg_21;
    reg [RV-1:0]r_commit_reg_22;
    reg [RV-1:0]r_commit_reg_23;
    reg [RV-1:0]r_commit_reg_24;
    reg [RV-1:0]r_commit_reg_25;
    reg [RV-1:0]r_commit_reg_26;
    reg [RV-1:0]r_commit_reg_27;
    reg [RV-1:0]r_commit_reg_28;
    reg [RV-1:0]r_commit_reg_29;
    reg [RV-1:0]r_commit_reg_30;
    reg [RV-1:0]r_commit_reg_31;
`else
	reg [RV-1:0]r_real_reg[1:31];
`ifdef FP
	reg [RV-1:0]r_real_fp_reg[0:31];
`endif
	reg [RV-1:0]r_commit_reg[0:NCOMMIT-1];
`endif
	reg [RV-1:0]transfer_reg_0;
	reg [4:0]transfer_write_addr_0;
`ifdef FP
	reg      transfer_write_fp_0;
`endif
	reg [RV-1:0]transfer_reg_1;
	reg [4:0]transfer_write_addr_1;
`ifdef FP
	reg      transfer_write_fp_1;
`endif
	reg [RV-1:0]transfer_reg_2;
	reg [4:0]transfer_write_addr_2;
`ifdef FP
	reg      transfer_write_fp_2;
`endif
	reg [RV-1:0]transfer_reg_3;
	reg [4:0]transfer_write_addr_3;
`ifdef FP
	reg      transfer_write_fp_3;
`endif
	reg [RV-1:0]transfer_reg_4;
	reg [4:0]transfer_write_addr_4;
`ifdef FP
	reg      transfer_write_fp_4;
`endif
	reg [RV-1:0]transfer_reg_5;
	reg [4:0]transfer_write_addr_5;
`ifdef FP
	reg      transfer_write_fp_5;
`endif
	reg [RV-1:0]transfer_reg_6;
	reg [4:0]transfer_write_addr_6;
`ifdef FP
	reg      transfer_write_fp_6;
`endif
	reg [RV-1:0]transfer_reg_7;
	reg [4:0]transfer_write_addr_7;
`ifdef FP
	reg      transfer_write_fp_7;
`endif
	reg [7:0]transfer_pending;
	wire [7:0]transfer_pending_ok;
`ifdef VSYNTH
	reg	[RV-1:0]xvr_0;
	wire [8:0]xwp_0 = {write_enable8&(write_addr8==0), write_enable7&(write_addr7==0), write_enable6&(write_addr6==0), write_enable5&(write_addr5==0), write_enable4&(write_addr4==0), write_enable3&(write_addr3==0), write_enable2&(write_addr2==0), write_enable1&(write_addr1==0), write_enable0&(write_addr0==0) };
	always @(*) begin
		xvr_0 = 'bx;
		casez (xwp_0) // synthesis full_case parallel_case
		9'b1????????: xvr_0 = write_data8;
		9'b?1???????: xvr_0 = write_data7;
		9'b??1??????: xvr_0 = write_data6;
		9'b???1?????: xvr_0 = write_data5;
		9'b????1????: xvr_0 = write_data4;
		9'b?????1???: xvr_0 = write_data3;
		9'b??????1??: xvr_0 = write_data2;
		9'b???????1?: xvr_0 = write_data1;
		9'b????????1: xvr_0 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_0)
		r_commit_reg_0 <= xvr_0;
	reg	[RV-1:0]xvr_1;
	wire [8:0]xwp_1 = {write_enable8&(write_addr8==1), write_enable7&(write_addr7==1), write_enable6&(write_addr6==1), write_enable5&(write_addr5==1), write_enable4&(write_addr4==1), write_enable3&(write_addr3==1), write_enable2&(write_addr2==1), write_enable1&(write_addr1==1), write_enable0&(write_addr0==1) };
	always @(*) begin
		xvr_1 = 'bx;
		casez (xwp_1) // synthesis full_case parallel_case
		9'b1????????: xvr_1 = write_data8;
		9'b?1???????: xvr_1 = write_data7;
		9'b??1??????: xvr_1 = write_data6;
		9'b???1?????: xvr_1 = write_data5;
		9'b????1????: xvr_1 = write_data4;
		9'b?????1???: xvr_1 = write_data3;
		9'b??????1??: xvr_1 = write_data2;
		9'b???????1?: xvr_1 = write_data1;
		9'b????????1: xvr_1 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_1)
		r_commit_reg_1 <= xvr_1;
	reg	[RV-1:0]xvr_2;
	wire [8:0]xwp_2 = {write_enable8&(write_addr8==2), write_enable7&(write_addr7==2), write_enable6&(write_addr6==2), write_enable5&(write_addr5==2), write_enable4&(write_addr4==2), write_enable3&(write_addr3==2), write_enable2&(write_addr2==2), write_enable1&(write_addr1==2), write_enable0&(write_addr0==2) };
	always @(*) begin
		xvr_2 = 'bx;
		casez (xwp_2) // synthesis full_case parallel_case
		9'b1????????: xvr_2 = write_data8;
		9'b?1???????: xvr_2 = write_data7;
		9'b??1??????: xvr_2 = write_data6;
		9'b???1?????: xvr_2 = write_data5;
		9'b????1????: xvr_2 = write_data4;
		9'b?????1???: xvr_2 = write_data3;
		9'b??????1??: xvr_2 = write_data2;
		9'b???????1?: xvr_2 = write_data1;
		9'b????????1: xvr_2 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_2)
		r_commit_reg_2 <= xvr_2;
	reg	[RV-1:0]xvr_3;
	wire [8:0]xwp_3 = {write_enable8&(write_addr8==3), write_enable7&(write_addr7==3), write_enable6&(write_addr6==3), write_enable5&(write_addr5==3), write_enable4&(write_addr4==3), write_enable3&(write_addr3==3), write_enable2&(write_addr2==3), write_enable1&(write_addr1==3), write_enable0&(write_addr0==3) };
	always @(*) begin
		xvr_3 = 'bx;
		casez (xwp_3) // synthesis full_case parallel_case
		9'b1????????: xvr_3 = write_data8;
		9'b?1???????: xvr_3 = write_data7;
		9'b??1??????: xvr_3 = write_data6;
		9'b???1?????: xvr_3 = write_data5;
		9'b????1????: xvr_3 = write_data4;
		9'b?????1???: xvr_3 = write_data3;
		9'b??????1??: xvr_3 = write_data2;
		9'b???????1?: xvr_3 = write_data1;
		9'b????????1: xvr_3 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_3)
		r_commit_reg_3 <= xvr_3;
	reg	[RV-1:0]xvr_4;
	wire [8:0]xwp_4 = {write_enable8&(write_addr8==4), write_enable7&(write_addr7==4), write_enable6&(write_addr6==4), write_enable5&(write_addr5==4), write_enable4&(write_addr4==4), write_enable3&(write_addr3==4), write_enable2&(write_addr2==4), write_enable1&(write_addr1==4), write_enable0&(write_addr0==4) };
	always @(*) begin
		xvr_4 = 'bx;
		casez (xwp_4) // synthesis full_case parallel_case
		9'b1????????: xvr_4 = write_data8;
		9'b?1???????: xvr_4 = write_data7;
		9'b??1??????: xvr_4 = write_data6;
		9'b???1?????: xvr_4 = write_data5;
		9'b????1????: xvr_4 = write_data4;
		9'b?????1???: xvr_4 = write_data3;
		9'b??????1??: xvr_4 = write_data2;
		9'b???????1?: xvr_4 = write_data1;
		9'b????????1: xvr_4 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_4)
		r_commit_reg_4 <= xvr_4;
	reg	[RV-1:0]xvr_5;
	wire [8:0]xwp_5 = {write_enable8&(write_addr8==5), write_enable7&(write_addr7==5), write_enable6&(write_addr6==5), write_enable5&(write_addr5==5), write_enable4&(write_addr4==5), write_enable3&(write_addr3==5), write_enable2&(write_addr2==5), write_enable1&(write_addr1==5), write_enable0&(write_addr0==5) };
	always @(*) begin
		xvr_5 = 'bx;
		casez (xwp_5) // synthesis full_case parallel_case
		9'b1????????: xvr_5 = write_data8;
		9'b?1???????: xvr_5 = write_data7;
		9'b??1??????: xvr_5 = write_data6;
		9'b???1?????: xvr_5 = write_data5;
		9'b????1????: xvr_5 = write_data4;
		9'b?????1???: xvr_5 = write_data3;
		9'b??????1??: xvr_5 = write_data2;
		9'b???????1?: xvr_5 = write_data1;
		9'b????????1: xvr_5 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_5)
		r_commit_reg_5 <= xvr_5;
	reg	[RV-1:0]xvr_6;
	wire [8:0]xwp_6 = {write_enable8&(write_addr8==6), write_enable7&(write_addr7==6), write_enable6&(write_addr6==6), write_enable5&(write_addr5==6), write_enable4&(write_addr4==6), write_enable3&(write_addr3==6), write_enable2&(write_addr2==6), write_enable1&(write_addr1==6), write_enable0&(write_addr0==6) };
	always @(*) begin
		xvr_6 = 'bx;
		casez (xwp_6) // synthesis full_case parallel_case
		9'b1????????: xvr_6 = write_data8;
		9'b?1???????: xvr_6 = write_data7;
		9'b??1??????: xvr_6 = write_data6;
		9'b???1?????: xvr_6 = write_data5;
		9'b????1????: xvr_6 = write_data4;
		9'b?????1???: xvr_6 = write_data3;
		9'b??????1??: xvr_6 = write_data2;
		9'b???????1?: xvr_6 = write_data1;
		9'b????????1: xvr_6 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_6)
		r_commit_reg_6 <= xvr_6;
	reg	[RV-1:0]xvr_7;
	wire [8:0]xwp_7 = {write_enable8&(write_addr8==7), write_enable7&(write_addr7==7), write_enable6&(write_addr6==7), write_enable5&(write_addr5==7), write_enable4&(write_addr4==7), write_enable3&(write_addr3==7), write_enable2&(write_addr2==7), write_enable1&(write_addr1==7), write_enable0&(write_addr0==7) };
	always @(*) begin
		xvr_7 = 'bx;
		casez (xwp_7) // synthesis full_case parallel_case
		9'b1????????: xvr_7 = write_data8;
		9'b?1???????: xvr_7 = write_data7;
		9'b??1??????: xvr_7 = write_data6;
		9'b???1?????: xvr_7 = write_data5;
		9'b????1????: xvr_7 = write_data4;
		9'b?????1???: xvr_7 = write_data3;
		9'b??????1??: xvr_7 = write_data2;
		9'b???????1?: xvr_7 = write_data1;
		9'b????????1: xvr_7 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_7)
		r_commit_reg_7 <= xvr_7;
	reg	[RV-1:0]xvr_8;
	wire [8:0]xwp_8 = {write_enable8&(write_addr8==8), write_enable7&(write_addr7==8), write_enable6&(write_addr6==8), write_enable5&(write_addr5==8), write_enable4&(write_addr4==8), write_enable3&(write_addr3==8), write_enable2&(write_addr2==8), write_enable1&(write_addr1==8), write_enable0&(write_addr0==8) };
	always @(*) begin
		xvr_8 = 'bx;
		casez (xwp_8) // synthesis full_case parallel_case
		9'b1????????: xvr_8 = write_data8;
		9'b?1???????: xvr_8 = write_data7;
		9'b??1??????: xvr_8 = write_data6;
		9'b???1?????: xvr_8 = write_data5;
		9'b????1????: xvr_8 = write_data4;
		9'b?????1???: xvr_8 = write_data3;
		9'b??????1??: xvr_8 = write_data2;
		9'b???????1?: xvr_8 = write_data1;
		9'b????????1: xvr_8 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_8)
		r_commit_reg_8 <= xvr_8;
	reg	[RV-1:0]xvr_9;
	wire [8:0]xwp_9 = {write_enable8&(write_addr8==9), write_enable7&(write_addr7==9), write_enable6&(write_addr6==9), write_enable5&(write_addr5==9), write_enable4&(write_addr4==9), write_enable3&(write_addr3==9), write_enable2&(write_addr2==9), write_enable1&(write_addr1==9), write_enable0&(write_addr0==9) };
	always @(*) begin
		xvr_9 = 'bx;
		casez (xwp_9) // synthesis full_case parallel_case
		9'b1????????: xvr_9 = write_data8;
		9'b?1???????: xvr_9 = write_data7;
		9'b??1??????: xvr_9 = write_data6;
		9'b???1?????: xvr_9 = write_data5;
		9'b????1????: xvr_9 = write_data4;
		9'b?????1???: xvr_9 = write_data3;
		9'b??????1??: xvr_9 = write_data2;
		9'b???????1?: xvr_9 = write_data1;
		9'b????????1: xvr_9 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_9)
		r_commit_reg_9 <= xvr_9;
	reg	[RV-1:0]xvr_10;
	wire [8:0]xwp_10 = {write_enable8&(write_addr8==10), write_enable7&(write_addr7==10), write_enable6&(write_addr6==10), write_enable5&(write_addr5==10), write_enable4&(write_addr4==10), write_enable3&(write_addr3==10), write_enable2&(write_addr2==10), write_enable1&(write_addr1==10), write_enable0&(write_addr0==10) };
	always @(*) begin
		xvr_10 = 'bx;
		casez (xwp_10) // synthesis full_case parallel_case
		9'b1????????: xvr_10 = write_data8;
		9'b?1???????: xvr_10 = write_data7;
		9'b??1??????: xvr_10 = write_data6;
		9'b???1?????: xvr_10 = write_data5;
		9'b????1????: xvr_10 = write_data4;
		9'b?????1???: xvr_10 = write_data3;
		9'b??????1??: xvr_10 = write_data2;
		9'b???????1?: xvr_10 = write_data1;
		9'b????????1: xvr_10 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_10)
		r_commit_reg_10 <= xvr_10;
	reg	[RV-1:0]xvr_11;
	wire [8:0]xwp_11 = {write_enable8&(write_addr8==11), write_enable7&(write_addr7==11), write_enable6&(write_addr6==11), write_enable5&(write_addr5==11), write_enable4&(write_addr4==11), write_enable3&(write_addr3==11), write_enable2&(write_addr2==11), write_enable1&(write_addr1==11), write_enable0&(write_addr0==11) };
	always @(*) begin
		xvr_11 = 'bx;
		casez (xwp_11) // synthesis full_case parallel_case
		9'b1????????: xvr_11 = write_data8;
		9'b?1???????: xvr_11 = write_data7;
		9'b??1??????: xvr_11 = write_data6;
		9'b???1?????: xvr_11 = write_data5;
		9'b????1????: xvr_11 = write_data4;
		9'b?????1???: xvr_11 = write_data3;
		9'b??????1??: xvr_11 = write_data2;
		9'b???????1?: xvr_11 = write_data1;
		9'b????????1: xvr_11 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_11)
		r_commit_reg_11 <= xvr_11;
	reg	[RV-1:0]xvr_12;
	wire [8:0]xwp_12 = {write_enable8&(write_addr8==12), write_enable7&(write_addr7==12), write_enable6&(write_addr6==12), write_enable5&(write_addr5==12), write_enable4&(write_addr4==12), write_enable3&(write_addr3==12), write_enable2&(write_addr2==12), write_enable1&(write_addr1==12), write_enable0&(write_addr0==12) };
	always @(*) begin
		xvr_12 = 'bx;
		casez (xwp_12) // synthesis full_case parallel_case
		9'b1????????: xvr_12 = write_data8;
		9'b?1???????: xvr_12 = write_data7;
		9'b??1??????: xvr_12 = write_data6;
		9'b???1?????: xvr_12 = write_data5;
		9'b????1????: xvr_12 = write_data4;
		9'b?????1???: xvr_12 = write_data3;
		9'b??????1??: xvr_12 = write_data2;
		9'b???????1?: xvr_12 = write_data1;
		9'b????????1: xvr_12 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_12)
		r_commit_reg_12 <= xvr_12;
	reg	[RV-1:0]xvr_13;
	wire [8:0]xwp_13 = {write_enable8&(write_addr8==13), write_enable7&(write_addr7==13), write_enable6&(write_addr6==13), write_enable5&(write_addr5==13), write_enable4&(write_addr4==13), write_enable3&(write_addr3==13), write_enable2&(write_addr2==13), write_enable1&(write_addr1==13), write_enable0&(write_addr0==13) };
	always @(*) begin
		xvr_13 = 'bx;
		casez (xwp_13) // synthesis full_case parallel_case
		9'b1????????: xvr_13 = write_data8;
		9'b?1???????: xvr_13 = write_data7;
		9'b??1??????: xvr_13 = write_data6;
		9'b???1?????: xvr_13 = write_data5;
		9'b????1????: xvr_13 = write_data4;
		9'b?????1???: xvr_13 = write_data3;
		9'b??????1??: xvr_13 = write_data2;
		9'b???????1?: xvr_13 = write_data1;
		9'b????????1: xvr_13 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_13)
		r_commit_reg_13 <= xvr_13;
	reg	[RV-1:0]xvr_14;
	wire [8:0]xwp_14 = {write_enable8&(write_addr8==14), write_enable7&(write_addr7==14), write_enable6&(write_addr6==14), write_enable5&(write_addr5==14), write_enable4&(write_addr4==14), write_enable3&(write_addr3==14), write_enable2&(write_addr2==14), write_enable1&(write_addr1==14), write_enable0&(write_addr0==14) };
	always @(*) begin
		xvr_14 = 'bx;
		casez (xwp_14) // synthesis full_case parallel_case
		9'b1????????: xvr_14 = write_data8;
		9'b?1???????: xvr_14 = write_data7;
		9'b??1??????: xvr_14 = write_data6;
		9'b???1?????: xvr_14 = write_data5;
		9'b????1????: xvr_14 = write_data4;
		9'b?????1???: xvr_14 = write_data3;
		9'b??????1??: xvr_14 = write_data2;
		9'b???????1?: xvr_14 = write_data1;
		9'b????????1: xvr_14 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_14)
		r_commit_reg_14 <= xvr_14;
	reg	[RV-1:0]xvr_15;
	wire [8:0]xwp_15 = {write_enable8&(write_addr8==15), write_enable7&(write_addr7==15), write_enable6&(write_addr6==15), write_enable5&(write_addr5==15), write_enable4&(write_addr4==15), write_enable3&(write_addr3==15), write_enable2&(write_addr2==15), write_enable1&(write_addr1==15), write_enable0&(write_addr0==15) };
	always @(*) begin
		xvr_15 = 'bx;
		casez (xwp_15) // synthesis full_case parallel_case
		9'b1????????: xvr_15 = write_data8;
		9'b?1???????: xvr_15 = write_data7;
		9'b??1??????: xvr_15 = write_data6;
		9'b???1?????: xvr_15 = write_data5;
		9'b????1????: xvr_15 = write_data4;
		9'b?????1???: xvr_15 = write_data3;
		9'b??????1??: xvr_15 = write_data2;
		9'b???????1?: xvr_15 = write_data1;
		9'b????????1: xvr_15 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_15)
		r_commit_reg_15 <= xvr_15;
	reg	[RV-1:0]xvr_16;
	wire [8:0]xwp_16 = {write_enable8&(write_addr8==16), write_enable7&(write_addr7==16), write_enable6&(write_addr6==16), write_enable5&(write_addr5==16), write_enable4&(write_addr4==16), write_enable3&(write_addr3==16), write_enable2&(write_addr2==16), write_enable1&(write_addr1==16), write_enable0&(write_addr0==16) };
	always @(*) begin
		xvr_16 = 'bx;
		casez (xwp_16) // synthesis full_case parallel_case
		9'b1????????: xvr_16 = write_data8;
		9'b?1???????: xvr_16 = write_data7;
		9'b??1??????: xvr_16 = write_data6;
		9'b???1?????: xvr_16 = write_data5;
		9'b????1????: xvr_16 = write_data4;
		9'b?????1???: xvr_16 = write_data3;
		9'b??????1??: xvr_16 = write_data2;
		9'b???????1?: xvr_16 = write_data1;
		9'b????????1: xvr_16 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_16)
		r_commit_reg_16 <= xvr_16;
	reg	[RV-1:0]xvr_17;
	wire [8:0]xwp_17 = {write_enable8&(write_addr8==17), write_enable7&(write_addr7==17), write_enable6&(write_addr6==17), write_enable5&(write_addr5==17), write_enable4&(write_addr4==17), write_enable3&(write_addr3==17), write_enable2&(write_addr2==17), write_enable1&(write_addr1==17), write_enable0&(write_addr0==17) };
	always @(*) begin
		xvr_17 = 'bx;
		casez (xwp_17) // synthesis full_case parallel_case
		9'b1????????: xvr_17 = write_data8;
		9'b?1???????: xvr_17 = write_data7;
		9'b??1??????: xvr_17 = write_data6;
		9'b???1?????: xvr_17 = write_data5;
		9'b????1????: xvr_17 = write_data4;
		9'b?????1???: xvr_17 = write_data3;
		9'b??????1??: xvr_17 = write_data2;
		9'b???????1?: xvr_17 = write_data1;
		9'b????????1: xvr_17 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_17)
		r_commit_reg_17 <= xvr_17;
	reg	[RV-1:0]xvr_18;
	wire [8:0]xwp_18 = {write_enable8&(write_addr8==18), write_enable7&(write_addr7==18), write_enable6&(write_addr6==18), write_enable5&(write_addr5==18), write_enable4&(write_addr4==18), write_enable3&(write_addr3==18), write_enable2&(write_addr2==18), write_enable1&(write_addr1==18), write_enable0&(write_addr0==18) };
	always @(*) begin
		xvr_18 = 'bx;
		casez (xwp_18) // synthesis full_case parallel_case
		9'b1????????: xvr_18 = write_data8;
		9'b?1???????: xvr_18 = write_data7;
		9'b??1??????: xvr_18 = write_data6;
		9'b???1?????: xvr_18 = write_data5;
		9'b????1????: xvr_18 = write_data4;
		9'b?????1???: xvr_18 = write_data3;
		9'b??????1??: xvr_18 = write_data2;
		9'b???????1?: xvr_18 = write_data1;
		9'b????????1: xvr_18 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_18)
		r_commit_reg_18 <= xvr_18;
	reg	[RV-1:0]xvr_19;
	wire [8:0]xwp_19 = {write_enable8&(write_addr8==19), write_enable7&(write_addr7==19), write_enable6&(write_addr6==19), write_enable5&(write_addr5==19), write_enable4&(write_addr4==19), write_enable3&(write_addr3==19), write_enable2&(write_addr2==19), write_enable1&(write_addr1==19), write_enable0&(write_addr0==19) };
	always @(*) begin
		xvr_19 = 'bx;
		casez (xwp_19) // synthesis full_case parallel_case
		9'b1????????: xvr_19 = write_data8;
		9'b?1???????: xvr_19 = write_data7;
		9'b??1??????: xvr_19 = write_data6;
		9'b???1?????: xvr_19 = write_data5;
		9'b????1????: xvr_19 = write_data4;
		9'b?????1???: xvr_19 = write_data3;
		9'b??????1??: xvr_19 = write_data2;
		9'b???????1?: xvr_19 = write_data1;
		9'b????????1: xvr_19 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_19)
		r_commit_reg_19 <= xvr_19;
	reg	[RV-1:0]xvr_20;
	wire [8:0]xwp_20 = {write_enable8&(write_addr8==20), write_enable7&(write_addr7==20), write_enable6&(write_addr6==20), write_enable5&(write_addr5==20), write_enable4&(write_addr4==20), write_enable3&(write_addr3==20), write_enable2&(write_addr2==20), write_enable1&(write_addr1==20), write_enable0&(write_addr0==20) };
	always @(*) begin
		xvr_20 = 'bx;
		casez (xwp_20) // synthesis full_case parallel_case
		9'b1????????: xvr_20 = write_data8;
		9'b?1???????: xvr_20 = write_data7;
		9'b??1??????: xvr_20 = write_data6;
		9'b???1?????: xvr_20 = write_data5;
		9'b????1????: xvr_20 = write_data4;
		9'b?????1???: xvr_20 = write_data3;
		9'b??????1??: xvr_20 = write_data2;
		9'b???????1?: xvr_20 = write_data1;
		9'b????????1: xvr_20 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_20)
		r_commit_reg_20 <= xvr_20;
	reg	[RV-1:0]xvr_21;
	wire [8:0]xwp_21 = {write_enable8&(write_addr8==21), write_enable7&(write_addr7==21), write_enable6&(write_addr6==21), write_enable5&(write_addr5==21), write_enable4&(write_addr4==21), write_enable3&(write_addr3==21), write_enable2&(write_addr2==21), write_enable1&(write_addr1==21), write_enable0&(write_addr0==21) };
	always @(*) begin
		xvr_21 = 'bx;
		casez (xwp_21) // synthesis full_case parallel_case
		9'b1????????: xvr_21 = write_data8;
		9'b?1???????: xvr_21 = write_data7;
		9'b??1??????: xvr_21 = write_data6;
		9'b???1?????: xvr_21 = write_data5;
		9'b????1????: xvr_21 = write_data4;
		9'b?????1???: xvr_21 = write_data3;
		9'b??????1??: xvr_21 = write_data2;
		9'b???????1?: xvr_21 = write_data1;
		9'b????????1: xvr_21 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_21)
		r_commit_reg_21 <= xvr_21;
	reg	[RV-1:0]xvr_22;
	wire [8:0]xwp_22 = {write_enable8&(write_addr8==22), write_enable7&(write_addr7==22), write_enable6&(write_addr6==22), write_enable5&(write_addr5==22), write_enable4&(write_addr4==22), write_enable3&(write_addr3==22), write_enable2&(write_addr2==22), write_enable1&(write_addr1==22), write_enable0&(write_addr0==22) };
	always @(*) begin
		xvr_22 = 'bx;
		casez (xwp_22) // synthesis full_case parallel_case
		9'b1????????: xvr_22 = write_data8;
		9'b?1???????: xvr_22 = write_data7;
		9'b??1??????: xvr_22 = write_data6;
		9'b???1?????: xvr_22 = write_data5;
		9'b????1????: xvr_22 = write_data4;
		9'b?????1???: xvr_22 = write_data3;
		9'b??????1??: xvr_22 = write_data2;
		9'b???????1?: xvr_22 = write_data1;
		9'b????????1: xvr_22 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_22)
		r_commit_reg_22 <= xvr_22;
	reg	[RV-1:0]xvr_23;
	wire [8:0]xwp_23 = {write_enable8&(write_addr8==23), write_enable7&(write_addr7==23), write_enable6&(write_addr6==23), write_enable5&(write_addr5==23), write_enable4&(write_addr4==23), write_enable3&(write_addr3==23), write_enable2&(write_addr2==23), write_enable1&(write_addr1==23), write_enable0&(write_addr0==23) };
	always @(*) begin
		xvr_23 = 'bx;
		casez (xwp_23) // synthesis full_case parallel_case
		9'b1????????: xvr_23 = write_data8;
		9'b?1???????: xvr_23 = write_data7;
		9'b??1??????: xvr_23 = write_data6;
		9'b???1?????: xvr_23 = write_data5;
		9'b????1????: xvr_23 = write_data4;
		9'b?????1???: xvr_23 = write_data3;
		9'b??????1??: xvr_23 = write_data2;
		9'b???????1?: xvr_23 = write_data1;
		9'b????????1: xvr_23 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_23)
		r_commit_reg_23 <= xvr_23;
	reg	[RV-1:0]xvr_24;
	wire [8:0]xwp_24 = {write_enable8&(write_addr8==24), write_enable7&(write_addr7==24), write_enable6&(write_addr6==24), write_enable5&(write_addr5==24), write_enable4&(write_addr4==24), write_enable3&(write_addr3==24), write_enable2&(write_addr2==24), write_enable1&(write_addr1==24), write_enable0&(write_addr0==24) };
	always @(*) begin
		xvr_24 = 'bx;
		casez (xwp_24) // synthesis full_case parallel_case
		9'b1????????: xvr_24 = write_data8;
		9'b?1???????: xvr_24 = write_data7;
		9'b??1??????: xvr_24 = write_data6;
		9'b???1?????: xvr_24 = write_data5;
		9'b????1????: xvr_24 = write_data4;
		9'b?????1???: xvr_24 = write_data3;
		9'b??????1??: xvr_24 = write_data2;
		9'b???????1?: xvr_24 = write_data1;
		9'b????????1: xvr_24 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_24)
		r_commit_reg_24 <= xvr_24;
	reg	[RV-1:0]xvr_25;
	wire [8:0]xwp_25 = {write_enable8&(write_addr8==25), write_enable7&(write_addr7==25), write_enable6&(write_addr6==25), write_enable5&(write_addr5==25), write_enable4&(write_addr4==25), write_enable3&(write_addr3==25), write_enable2&(write_addr2==25), write_enable1&(write_addr1==25), write_enable0&(write_addr0==25) };
	always @(*) begin
		xvr_25 = 'bx;
		casez (xwp_25) // synthesis full_case parallel_case
		9'b1????????: xvr_25 = write_data8;
		9'b?1???????: xvr_25 = write_data7;
		9'b??1??????: xvr_25 = write_data6;
		9'b???1?????: xvr_25 = write_data5;
		9'b????1????: xvr_25 = write_data4;
		9'b?????1???: xvr_25 = write_data3;
		9'b??????1??: xvr_25 = write_data2;
		9'b???????1?: xvr_25 = write_data1;
		9'b????????1: xvr_25 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_25)
		r_commit_reg_25 <= xvr_25;
	reg	[RV-1:0]xvr_26;
	wire [8:0]xwp_26 = {write_enable8&(write_addr8==26), write_enable7&(write_addr7==26), write_enable6&(write_addr6==26), write_enable5&(write_addr5==26), write_enable4&(write_addr4==26), write_enable3&(write_addr3==26), write_enable2&(write_addr2==26), write_enable1&(write_addr1==26), write_enable0&(write_addr0==26) };
	always @(*) begin
		xvr_26 = 'bx;
		casez (xwp_26) // synthesis full_case parallel_case
		9'b1????????: xvr_26 = write_data8;
		9'b?1???????: xvr_26 = write_data7;
		9'b??1??????: xvr_26 = write_data6;
		9'b???1?????: xvr_26 = write_data5;
		9'b????1????: xvr_26 = write_data4;
		9'b?????1???: xvr_26 = write_data3;
		9'b??????1??: xvr_26 = write_data2;
		9'b???????1?: xvr_26 = write_data1;
		9'b????????1: xvr_26 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_26)
		r_commit_reg_26 <= xvr_26;
	reg	[RV-1:0]xvr_27;
	wire [8:0]xwp_27 = {write_enable8&(write_addr8==27), write_enable7&(write_addr7==27), write_enable6&(write_addr6==27), write_enable5&(write_addr5==27), write_enable4&(write_addr4==27), write_enable3&(write_addr3==27), write_enable2&(write_addr2==27), write_enable1&(write_addr1==27), write_enable0&(write_addr0==27) };
	always @(*) begin
		xvr_27 = 'bx;
		casez (xwp_27) // synthesis full_case parallel_case
		9'b1????????: xvr_27 = write_data8;
		9'b?1???????: xvr_27 = write_data7;
		9'b??1??????: xvr_27 = write_data6;
		9'b???1?????: xvr_27 = write_data5;
		9'b????1????: xvr_27 = write_data4;
		9'b?????1???: xvr_27 = write_data3;
		9'b??????1??: xvr_27 = write_data2;
		9'b???????1?: xvr_27 = write_data1;
		9'b????????1: xvr_27 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_27)
		r_commit_reg_27 <= xvr_27;
	reg	[RV-1:0]xvr_28;
	wire [8:0]xwp_28 = {write_enable8&(write_addr8==28), write_enable7&(write_addr7==28), write_enable6&(write_addr6==28), write_enable5&(write_addr5==28), write_enable4&(write_addr4==28), write_enable3&(write_addr3==28), write_enable2&(write_addr2==28), write_enable1&(write_addr1==28), write_enable0&(write_addr0==28) };
	always @(*) begin
		xvr_28 = 'bx;
		casez (xwp_28) // synthesis full_case parallel_case
		9'b1????????: xvr_28 = write_data8;
		9'b?1???????: xvr_28 = write_data7;
		9'b??1??????: xvr_28 = write_data6;
		9'b???1?????: xvr_28 = write_data5;
		9'b????1????: xvr_28 = write_data4;
		9'b?????1???: xvr_28 = write_data3;
		9'b??????1??: xvr_28 = write_data2;
		9'b???????1?: xvr_28 = write_data1;
		9'b????????1: xvr_28 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_28)
		r_commit_reg_28 <= xvr_28;
	reg	[RV-1:0]xvr_29;
	wire [8:0]xwp_29 = {write_enable8&(write_addr8==29), write_enable7&(write_addr7==29), write_enable6&(write_addr6==29), write_enable5&(write_addr5==29), write_enable4&(write_addr4==29), write_enable3&(write_addr3==29), write_enable2&(write_addr2==29), write_enable1&(write_addr1==29), write_enable0&(write_addr0==29) };
	always @(*) begin
		xvr_29 = 'bx;
		casez (xwp_29) // synthesis full_case parallel_case
		9'b1????????: xvr_29 = write_data8;
		9'b?1???????: xvr_29 = write_data7;
		9'b??1??????: xvr_29 = write_data6;
		9'b???1?????: xvr_29 = write_data5;
		9'b????1????: xvr_29 = write_data4;
		9'b?????1???: xvr_29 = write_data3;
		9'b??????1??: xvr_29 = write_data2;
		9'b???????1?: xvr_29 = write_data1;
		9'b????????1: xvr_29 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_29)
		r_commit_reg_29 <= xvr_29;
	reg	[RV-1:0]xvr_30;
	wire [8:0]xwp_30 = {write_enable8&(write_addr8==30), write_enable7&(write_addr7==30), write_enable6&(write_addr6==30), write_enable5&(write_addr5==30), write_enable4&(write_addr4==30), write_enable3&(write_addr3==30), write_enable2&(write_addr2==30), write_enable1&(write_addr1==30), write_enable0&(write_addr0==30) };
	always @(*) begin
		xvr_30 = 'bx;
		casez (xwp_30) // synthesis full_case parallel_case
		9'b1????????: xvr_30 = write_data8;
		9'b?1???????: xvr_30 = write_data7;
		9'b??1??????: xvr_30 = write_data6;
		9'b???1?????: xvr_30 = write_data5;
		9'b????1????: xvr_30 = write_data4;
		9'b?????1???: xvr_30 = write_data3;
		9'b??????1??: xvr_30 = write_data2;
		9'b???????1?: xvr_30 = write_data1;
		9'b????????1: xvr_30 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_30)
		r_commit_reg_30 <= xvr_30;
	reg	[RV-1:0]xvr_31;
	wire [8:0]xwp_31 = {write_enable8&(write_addr8==31), write_enable7&(write_addr7==31), write_enable6&(write_addr6==31), write_enable5&(write_addr5==31), write_enable4&(write_addr4==31), write_enable3&(write_addr3==31), write_enable2&(write_addr2==31), write_enable1&(write_addr1==31), write_enable0&(write_addr0==31) };
	always @(*) begin
		xvr_31 = 'bx;
		casez (xwp_31) // synthesis full_case parallel_case
		9'b1????????: xvr_31 = write_data8;
		9'b?1???????: xvr_31 = write_data7;
		9'b??1??????: xvr_31 = write_data6;
		9'b???1?????: xvr_31 = write_data5;
		9'b????1????: xvr_31 = write_data4;
		9'b?????1???: xvr_31 = write_data3;
		9'b??????1??: xvr_31 = write_data2;
		9'b???????1?: xvr_31 = write_data1;
		9'b????????1: xvr_31 = write_data0;
		endcase
	end
	always @(posedge clk)
	if (|xwp_31)
		r_commit_reg_31 <= xvr_31;
`else
	always @(posedge clk) 
		if (write_enable0) r_commit_reg[write_addr0] <= write_data0;
	always @(posedge clk) 
		if (write_enable1) r_commit_reg[write_addr1] <= write_data1;
	always @(posedge clk) 
		if (write_enable2) r_commit_reg[write_addr2] <= write_data2;
	always @(posedge clk) 
		if (write_enable3) r_commit_reg[write_addr3] <= write_data3;
	always @(posedge clk) 
		if (write_enable4) r_commit_reg[write_addr4] <= write_data4;
	always @(posedge clk) 
		if (write_enable5) r_commit_reg[write_addr5] <= write_data5;
	always @(posedge clk) 
		if (write_enable6) r_commit_reg[write_addr6] <= write_data6;
	always @(posedge clk) 
		if (write_enable7) r_commit_reg[write_addr7] <= write_data7;
	always @(posedge clk) 
		if (write_enable8) r_commit_reg[write_addr8] <= write_data8;
`endif
`ifdef VSYNTH
	reg [RV-1:0]tr_0;
	always @(*) begin
		case(transfer_source_addr0) // synthesis full_case parallel_case
		0: tr_0 = r_commit_reg_0;
		1: tr_0 = r_commit_reg_1;
		2: tr_0 = r_commit_reg_2;
		3: tr_0 = r_commit_reg_3;
		4: tr_0 = r_commit_reg_4;
		5: tr_0 = r_commit_reg_5;
		6: tr_0 = r_commit_reg_6;
		7: tr_0 = r_commit_reg_7;
		8: tr_0 = r_commit_reg_8;
		9: tr_0 = r_commit_reg_9;
		10: tr_0 = r_commit_reg_10;
		11: tr_0 = r_commit_reg_11;
		12: tr_0 = r_commit_reg_12;
		13: tr_0 = r_commit_reg_13;
		14: tr_0 = r_commit_reg_14;
		15: tr_0 = r_commit_reg_15;
		16: tr_0 = r_commit_reg_16;
		17: tr_0 = r_commit_reg_17;
		18: tr_0 = r_commit_reg_18;
		19: tr_0 = r_commit_reg_19;
		20: tr_0 = r_commit_reg_20;
		21: tr_0 = r_commit_reg_21;
		22: tr_0 = r_commit_reg_22;
		23: tr_0 = r_commit_reg_23;
		24: tr_0 = r_commit_reg_24;
		25: tr_0 = r_commit_reg_25;
		26: tr_0 = r_commit_reg_26;
		27: tr_0 = r_commit_reg_27;
		28: tr_0 = r_commit_reg_28;
		29: tr_0 = r_commit_reg_29;
		30: tr_0 = r_commit_reg_30;
		31: tr_0 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_0 <= tr_0;
`else
	always @(posedge clk) 
		transfer_reg_0 <= r_commit_reg[transfer_source_addr0];
`endif
	always @(posedge clk) 
		transfer_write_addr_0 <= transfer_dest_addr0;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_0 <= transfer_dest_fp0;
	always @(posedge clk) 
		if (transfer_enable0 && !reset && (transfer_dest_fp0||transfer_dest_addr0!=0)) begin
			transfer_pending[0] <= 1;
		end else begin
			transfer_pending[0] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable0 && !reset && transfer_dest_addr0!=0) begin
			transfer_pending[0] <= 1;
		end else begin
			transfer_pending[0] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[0] && !transfer_dest_fp0)
`else
	if (transfer_pending_ok[0])
`endif
		r_real_reg[transfer_write_addr_0] <= transfer_reg_0;
`endif
	assign transfer_pending_ok[0] = (transfer_pending[0]
 && !(transfer_pending[1] && transfer_write_addr_1 == transfer_write_addr_0 
`ifdef FP
 && (transfer_dest_fp1 == transfer_dest_fp0) 
`endif
)
 && !(transfer_pending[2] && transfer_write_addr_2 == transfer_write_addr_0 
`ifdef FP
 && (transfer_dest_fp2 == transfer_dest_fp0) 
`endif
)
 && !(transfer_pending[3] && transfer_write_addr_3 == transfer_write_addr_0 
`ifdef FP
 && (transfer_dest_fp3 == transfer_dest_fp0) 
`endif
)
 && !(transfer_pending[4] && transfer_write_addr_4 == transfer_write_addr_0 
`ifdef FP
 && (transfer_dest_fp4 == transfer_dest_fp0) 
`endif
)
 && !(transfer_pending[5] && transfer_write_addr_5 == transfer_write_addr_0 
`ifdef FP
 && (transfer_dest_fp5 == transfer_dest_fp0) 
`endif
)
 && !(transfer_pending[6] && transfer_write_addr_6 == transfer_write_addr_0 
`ifdef FP
 && (transfer_dest_fp6 == transfer_dest_fp0) 
`endif
)
 && !(transfer_pending[7] && transfer_write_addr_7 == transfer_write_addr_0 
`ifdef FP
 && (transfer_dest_fp7 == transfer_dest_fp0) 
`endif
)
);
`ifdef VSYNTH
	reg [RV-1:0]tr_1;
	always @(*) begin
		case(transfer_source_addr1) // synthesis full_case parallel_case
		0: tr_1 = r_commit_reg_0;
		1: tr_1 = r_commit_reg_1;
		2: tr_1 = r_commit_reg_2;
		3: tr_1 = r_commit_reg_3;
		4: tr_1 = r_commit_reg_4;
		5: tr_1 = r_commit_reg_5;
		6: tr_1 = r_commit_reg_6;
		7: tr_1 = r_commit_reg_7;
		8: tr_1 = r_commit_reg_8;
		9: tr_1 = r_commit_reg_9;
		10: tr_1 = r_commit_reg_10;
		11: tr_1 = r_commit_reg_11;
		12: tr_1 = r_commit_reg_12;
		13: tr_1 = r_commit_reg_13;
		14: tr_1 = r_commit_reg_14;
		15: tr_1 = r_commit_reg_15;
		16: tr_1 = r_commit_reg_16;
		17: tr_1 = r_commit_reg_17;
		18: tr_1 = r_commit_reg_18;
		19: tr_1 = r_commit_reg_19;
		20: tr_1 = r_commit_reg_20;
		21: tr_1 = r_commit_reg_21;
		22: tr_1 = r_commit_reg_22;
		23: tr_1 = r_commit_reg_23;
		24: tr_1 = r_commit_reg_24;
		25: tr_1 = r_commit_reg_25;
		26: tr_1 = r_commit_reg_26;
		27: tr_1 = r_commit_reg_27;
		28: tr_1 = r_commit_reg_28;
		29: tr_1 = r_commit_reg_29;
		30: tr_1 = r_commit_reg_30;
		31: tr_1 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_1 <= tr_1;
`else
	always @(posedge clk) 
		transfer_reg_1 <= r_commit_reg[transfer_source_addr1];
`endif
	always @(posedge clk) 
		transfer_write_addr_1 <= transfer_dest_addr1;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_1 <= transfer_dest_fp1;
	always @(posedge clk) 
		if (transfer_enable1 && !reset && (transfer_dest_fp1||transfer_dest_addr1!=0)) begin
			transfer_pending[1] <= 1;
		end else begin
			transfer_pending[1] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable1 && !reset && transfer_dest_addr1!=0) begin
			transfer_pending[1] <= 1;
		end else begin
			transfer_pending[1] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[1] && !transfer_dest_fp1)
`else
	if (transfer_pending_ok[1])
`endif
		r_real_reg[transfer_write_addr_1] <= transfer_reg_1;
`endif
	assign transfer_pending_ok[1] = (transfer_pending[1]
 && !(transfer_pending[2] && transfer_write_addr_2 == transfer_write_addr_1 
`ifdef FP
 && (transfer_dest_fp2 == transfer_dest_fp1) 
`endif
)
 && !(transfer_pending[3] && transfer_write_addr_3 == transfer_write_addr_1 
`ifdef FP
 && (transfer_dest_fp3 == transfer_dest_fp1) 
`endif
)
 && !(transfer_pending[4] && transfer_write_addr_4 == transfer_write_addr_1 
`ifdef FP
 && (transfer_dest_fp4 == transfer_dest_fp1) 
`endif
)
 && !(transfer_pending[5] && transfer_write_addr_5 == transfer_write_addr_1 
`ifdef FP
 && (transfer_dest_fp5 == transfer_dest_fp1) 
`endif
)
 && !(transfer_pending[6] && transfer_write_addr_6 == transfer_write_addr_1 
`ifdef FP
 && (transfer_dest_fp6 == transfer_dest_fp1) 
`endif
)
 && !(transfer_pending[7] && transfer_write_addr_7 == transfer_write_addr_1 
`ifdef FP
 && (transfer_dest_fp7 == transfer_dest_fp1) 
`endif
)
);
`ifdef VSYNTH
	reg [RV-1:0]tr_2;
	always @(*) begin
		case(transfer_source_addr2) // synthesis full_case parallel_case
		0: tr_2 = r_commit_reg_0;
		1: tr_2 = r_commit_reg_1;
		2: tr_2 = r_commit_reg_2;
		3: tr_2 = r_commit_reg_3;
		4: tr_2 = r_commit_reg_4;
		5: tr_2 = r_commit_reg_5;
		6: tr_2 = r_commit_reg_6;
		7: tr_2 = r_commit_reg_7;
		8: tr_2 = r_commit_reg_8;
		9: tr_2 = r_commit_reg_9;
		10: tr_2 = r_commit_reg_10;
		11: tr_2 = r_commit_reg_11;
		12: tr_2 = r_commit_reg_12;
		13: tr_2 = r_commit_reg_13;
		14: tr_2 = r_commit_reg_14;
		15: tr_2 = r_commit_reg_15;
		16: tr_2 = r_commit_reg_16;
		17: tr_2 = r_commit_reg_17;
		18: tr_2 = r_commit_reg_18;
		19: tr_2 = r_commit_reg_19;
		20: tr_2 = r_commit_reg_20;
		21: tr_2 = r_commit_reg_21;
		22: tr_2 = r_commit_reg_22;
		23: tr_2 = r_commit_reg_23;
		24: tr_2 = r_commit_reg_24;
		25: tr_2 = r_commit_reg_25;
		26: tr_2 = r_commit_reg_26;
		27: tr_2 = r_commit_reg_27;
		28: tr_2 = r_commit_reg_28;
		29: tr_2 = r_commit_reg_29;
		30: tr_2 = r_commit_reg_30;
		31: tr_2 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_2 <= tr_2;
`else
	always @(posedge clk) 
		transfer_reg_2 <= r_commit_reg[transfer_source_addr2];
`endif
	always @(posedge clk) 
		transfer_write_addr_2 <= transfer_dest_addr2;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_2 <= transfer_dest_fp2;
	always @(posedge clk) 
		if (transfer_enable2 && !reset && (transfer_dest_fp2||transfer_dest_addr2!=0)) begin
			transfer_pending[2] <= 1;
		end else begin
			transfer_pending[2] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable2 && !reset && transfer_dest_addr2!=0) begin
			transfer_pending[2] <= 1;
		end else begin
			transfer_pending[2] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[2] && !transfer_dest_fp2)
`else
	if (transfer_pending_ok[2])
`endif
		r_real_reg[transfer_write_addr_2] <= transfer_reg_2;
`endif
	assign transfer_pending_ok[2] = (transfer_pending[2]
 && !(transfer_pending[3] && transfer_write_addr_3 == transfer_write_addr_2 
`ifdef FP
 && (transfer_dest_fp3 == transfer_dest_fp2) 
`endif
)
 && !(transfer_pending[4] && transfer_write_addr_4 == transfer_write_addr_2 
`ifdef FP
 && (transfer_dest_fp4 == transfer_dest_fp2) 
`endif
)
 && !(transfer_pending[5] && transfer_write_addr_5 == transfer_write_addr_2 
`ifdef FP
 && (transfer_dest_fp5 == transfer_dest_fp2) 
`endif
)
 && !(transfer_pending[6] && transfer_write_addr_6 == transfer_write_addr_2 
`ifdef FP
 && (transfer_dest_fp6 == transfer_dest_fp2) 
`endif
)
 && !(transfer_pending[7] && transfer_write_addr_7 == transfer_write_addr_2 
`ifdef FP
 && (transfer_dest_fp7 == transfer_dest_fp2) 
`endif
)
);
`ifdef VSYNTH
	reg [RV-1:0]tr_3;
	always @(*) begin
		case(transfer_source_addr3) // synthesis full_case parallel_case
		0: tr_3 = r_commit_reg_0;
		1: tr_3 = r_commit_reg_1;
		2: tr_3 = r_commit_reg_2;
		3: tr_3 = r_commit_reg_3;
		4: tr_3 = r_commit_reg_4;
		5: tr_3 = r_commit_reg_5;
		6: tr_3 = r_commit_reg_6;
		7: tr_3 = r_commit_reg_7;
		8: tr_3 = r_commit_reg_8;
		9: tr_3 = r_commit_reg_9;
		10: tr_3 = r_commit_reg_10;
		11: tr_3 = r_commit_reg_11;
		12: tr_3 = r_commit_reg_12;
		13: tr_3 = r_commit_reg_13;
		14: tr_3 = r_commit_reg_14;
		15: tr_3 = r_commit_reg_15;
		16: tr_3 = r_commit_reg_16;
		17: tr_3 = r_commit_reg_17;
		18: tr_3 = r_commit_reg_18;
		19: tr_3 = r_commit_reg_19;
		20: tr_3 = r_commit_reg_20;
		21: tr_3 = r_commit_reg_21;
		22: tr_3 = r_commit_reg_22;
		23: tr_3 = r_commit_reg_23;
		24: tr_3 = r_commit_reg_24;
		25: tr_3 = r_commit_reg_25;
		26: tr_3 = r_commit_reg_26;
		27: tr_3 = r_commit_reg_27;
		28: tr_3 = r_commit_reg_28;
		29: tr_3 = r_commit_reg_29;
		30: tr_3 = r_commit_reg_30;
		31: tr_3 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_3 <= tr_3;
`else
	always @(posedge clk) 
		transfer_reg_3 <= r_commit_reg[transfer_source_addr3];
`endif
	always @(posedge clk) 
		transfer_write_addr_3 <= transfer_dest_addr3;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_3 <= transfer_dest_fp3;
	always @(posedge clk) 
		if (transfer_enable3 && !reset && (transfer_dest_fp3||transfer_dest_addr3!=0)) begin
			transfer_pending[3] <= 1;
		end else begin
			transfer_pending[3] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable3 && !reset && transfer_dest_addr3!=0) begin
			transfer_pending[3] <= 1;
		end else begin
			transfer_pending[3] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[3] && !transfer_dest_fp3)
`else
	if (transfer_pending_ok[3])
`endif
		r_real_reg[transfer_write_addr_3] <= transfer_reg_3;
`endif
	assign transfer_pending_ok[3] = (transfer_pending[3]
 && !(transfer_pending[4] && transfer_write_addr_4 == transfer_write_addr_3 
`ifdef FP
 && (transfer_dest_fp4 == transfer_dest_fp3) 
`endif
)
 && !(transfer_pending[5] && transfer_write_addr_5 == transfer_write_addr_3 
`ifdef FP
 && (transfer_dest_fp5 == transfer_dest_fp3) 
`endif
)
 && !(transfer_pending[6] && transfer_write_addr_6 == transfer_write_addr_3 
`ifdef FP
 && (transfer_dest_fp6 == transfer_dest_fp3) 
`endif
)
 && !(transfer_pending[7] && transfer_write_addr_7 == transfer_write_addr_3 
`ifdef FP
 && (transfer_dest_fp7 == transfer_dest_fp3) 
`endif
)
);
`ifdef VSYNTH
	reg [RV-1:0]tr_4;
	always @(*) begin
		case(transfer_source_addr4) // synthesis full_case parallel_case
		0: tr_4 = r_commit_reg_0;
		1: tr_4 = r_commit_reg_1;
		2: tr_4 = r_commit_reg_2;
		3: tr_4 = r_commit_reg_3;
		4: tr_4 = r_commit_reg_4;
		5: tr_4 = r_commit_reg_5;
		6: tr_4 = r_commit_reg_6;
		7: tr_4 = r_commit_reg_7;
		8: tr_4 = r_commit_reg_8;
		9: tr_4 = r_commit_reg_9;
		10: tr_4 = r_commit_reg_10;
		11: tr_4 = r_commit_reg_11;
		12: tr_4 = r_commit_reg_12;
		13: tr_4 = r_commit_reg_13;
		14: tr_4 = r_commit_reg_14;
		15: tr_4 = r_commit_reg_15;
		16: tr_4 = r_commit_reg_16;
		17: tr_4 = r_commit_reg_17;
		18: tr_4 = r_commit_reg_18;
		19: tr_4 = r_commit_reg_19;
		20: tr_4 = r_commit_reg_20;
		21: tr_4 = r_commit_reg_21;
		22: tr_4 = r_commit_reg_22;
		23: tr_4 = r_commit_reg_23;
		24: tr_4 = r_commit_reg_24;
		25: tr_4 = r_commit_reg_25;
		26: tr_4 = r_commit_reg_26;
		27: tr_4 = r_commit_reg_27;
		28: tr_4 = r_commit_reg_28;
		29: tr_4 = r_commit_reg_29;
		30: tr_4 = r_commit_reg_30;
		31: tr_4 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_4 <= tr_4;
`else
	always @(posedge clk) 
		transfer_reg_4 <= r_commit_reg[transfer_source_addr4];
`endif
	always @(posedge clk) 
		transfer_write_addr_4 <= transfer_dest_addr4;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_4 <= transfer_dest_fp4;
	always @(posedge clk) 
		if (transfer_enable4 && !reset && (transfer_dest_fp4||transfer_dest_addr4!=0)) begin
			transfer_pending[4] <= 1;
		end else begin
			transfer_pending[4] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable4 && !reset && transfer_dest_addr4!=0) begin
			transfer_pending[4] <= 1;
		end else begin
			transfer_pending[4] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[4] && !transfer_dest_fp4)
`else
	if (transfer_pending_ok[4])
`endif
		r_real_reg[transfer_write_addr_4] <= transfer_reg_4;
`endif
	assign transfer_pending_ok[4] = (transfer_pending[4]
 && !(transfer_pending[5] && transfer_write_addr_5 == transfer_write_addr_4 
`ifdef FP
 && (transfer_dest_fp5 == transfer_dest_fp4) 
`endif
)
 && !(transfer_pending[6] && transfer_write_addr_6 == transfer_write_addr_4 
`ifdef FP
 && (transfer_dest_fp6 == transfer_dest_fp4) 
`endif
)
 && !(transfer_pending[7] && transfer_write_addr_7 == transfer_write_addr_4 
`ifdef FP
 && (transfer_dest_fp7 == transfer_dest_fp4) 
`endif
)
);
`ifdef VSYNTH
	reg [RV-1:0]tr_5;
	always @(*) begin
		case(transfer_source_addr5) // synthesis full_case parallel_case
		0: tr_5 = r_commit_reg_0;
		1: tr_5 = r_commit_reg_1;
		2: tr_5 = r_commit_reg_2;
		3: tr_5 = r_commit_reg_3;
		4: tr_5 = r_commit_reg_4;
		5: tr_5 = r_commit_reg_5;
		6: tr_5 = r_commit_reg_6;
		7: tr_5 = r_commit_reg_7;
		8: tr_5 = r_commit_reg_8;
		9: tr_5 = r_commit_reg_9;
		10: tr_5 = r_commit_reg_10;
		11: tr_5 = r_commit_reg_11;
		12: tr_5 = r_commit_reg_12;
		13: tr_5 = r_commit_reg_13;
		14: tr_5 = r_commit_reg_14;
		15: tr_5 = r_commit_reg_15;
		16: tr_5 = r_commit_reg_16;
		17: tr_5 = r_commit_reg_17;
		18: tr_5 = r_commit_reg_18;
		19: tr_5 = r_commit_reg_19;
		20: tr_5 = r_commit_reg_20;
		21: tr_5 = r_commit_reg_21;
		22: tr_5 = r_commit_reg_22;
		23: tr_5 = r_commit_reg_23;
		24: tr_5 = r_commit_reg_24;
		25: tr_5 = r_commit_reg_25;
		26: tr_5 = r_commit_reg_26;
		27: tr_5 = r_commit_reg_27;
		28: tr_5 = r_commit_reg_28;
		29: tr_5 = r_commit_reg_29;
		30: tr_5 = r_commit_reg_30;
		31: tr_5 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_5 <= tr_5;
`else
	always @(posedge clk) 
		transfer_reg_5 <= r_commit_reg[transfer_source_addr5];
`endif
	always @(posedge clk) 
		transfer_write_addr_5 <= transfer_dest_addr5;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_5 <= transfer_dest_fp5;
	always @(posedge clk) 
		if (transfer_enable5 && !reset && (transfer_dest_fp5||transfer_dest_addr5!=0)) begin
			transfer_pending[5] <= 1;
		end else begin
			transfer_pending[5] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable5 && !reset && transfer_dest_addr5!=0) begin
			transfer_pending[5] <= 1;
		end else begin
			transfer_pending[5] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[5] && !transfer_dest_fp5)
`else
	if (transfer_pending_ok[5])
`endif
		r_real_reg[transfer_write_addr_5] <= transfer_reg_5;
`endif
	assign transfer_pending_ok[5] = (transfer_pending[5]
 && !(transfer_pending[6] && transfer_write_addr_6 == transfer_write_addr_5 
`ifdef FP
 && (transfer_dest_fp6 == transfer_dest_fp5) 
`endif
)
 && !(transfer_pending[7] && transfer_write_addr_7 == transfer_write_addr_5 
`ifdef FP
 && (transfer_dest_fp7 == transfer_dest_fp5) 
`endif
)
);
`ifdef VSYNTH
	reg [RV-1:0]tr_6;
	always @(*) begin
		case(transfer_source_addr6) // synthesis full_case parallel_case
		0: tr_6 = r_commit_reg_0;
		1: tr_6 = r_commit_reg_1;
		2: tr_6 = r_commit_reg_2;
		3: tr_6 = r_commit_reg_3;
		4: tr_6 = r_commit_reg_4;
		5: tr_6 = r_commit_reg_5;
		6: tr_6 = r_commit_reg_6;
		7: tr_6 = r_commit_reg_7;
		8: tr_6 = r_commit_reg_8;
		9: tr_6 = r_commit_reg_9;
		10: tr_6 = r_commit_reg_10;
		11: tr_6 = r_commit_reg_11;
		12: tr_6 = r_commit_reg_12;
		13: tr_6 = r_commit_reg_13;
		14: tr_6 = r_commit_reg_14;
		15: tr_6 = r_commit_reg_15;
		16: tr_6 = r_commit_reg_16;
		17: tr_6 = r_commit_reg_17;
		18: tr_6 = r_commit_reg_18;
		19: tr_6 = r_commit_reg_19;
		20: tr_6 = r_commit_reg_20;
		21: tr_6 = r_commit_reg_21;
		22: tr_6 = r_commit_reg_22;
		23: tr_6 = r_commit_reg_23;
		24: tr_6 = r_commit_reg_24;
		25: tr_6 = r_commit_reg_25;
		26: tr_6 = r_commit_reg_26;
		27: tr_6 = r_commit_reg_27;
		28: tr_6 = r_commit_reg_28;
		29: tr_6 = r_commit_reg_29;
		30: tr_6 = r_commit_reg_30;
		31: tr_6 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_6 <= tr_6;
`else
	always @(posedge clk) 
		transfer_reg_6 <= r_commit_reg[transfer_source_addr6];
`endif
	always @(posedge clk) 
		transfer_write_addr_6 <= transfer_dest_addr6;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_6 <= transfer_dest_fp6;
	always @(posedge clk) 
		if (transfer_enable6 && !reset && (transfer_dest_fp6||transfer_dest_addr6!=0)) begin
			transfer_pending[6] <= 1;
		end else begin
			transfer_pending[6] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable6 && !reset && transfer_dest_addr6!=0) begin
			transfer_pending[6] <= 1;
		end else begin
			transfer_pending[6] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[6] && !transfer_dest_fp6)
`else
	if (transfer_pending_ok[6])
`endif
		r_real_reg[transfer_write_addr_6] <= transfer_reg_6;
`endif
	assign transfer_pending_ok[6] = (transfer_pending[6]
 && !(transfer_pending[7] && transfer_write_addr_7 == transfer_write_addr_6 
`ifdef FP
 && (transfer_dest_fp7 == transfer_dest_fp6) 
`endif
)
);
`ifdef VSYNTH
	reg [RV-1:0]tr_7;
	always @(*) begin
		case(transfer_source_addr7) // synthesis full_case parallel_case
		0: tr_7 = r_commit_reg_0;
		1: tr_7 = r_commit_reg_1;
		2: tr_7 = r_commit_reg_2;
		3: tr_7 = r_commit_reg_3;
		4: tr_7 = r_commit_reg_4;
		5: tr_7 = r_commit_reg_5;
		6: tr_7 = r_commit_reg_6;
		7: tr_7 = r_commit_reg_7;
		8: tr_7 = r_commit_reg_8;
		9: tr_7 = r_commit_reg_9;
		10: tr_7 = r_commit_reg_10;
		11: tr_7 = r_commit_reg_11;
		12: tr_7 = r_commit_reg_12;
		13: tr_7 = r_commit_reg_13;
		14: tr_7 = r_commit_reg_14;
		15: tr_7 = r_commit_reg_15;
		16: tr_7 = r_commit_reg_16;
		17: tr_7 = r_commit_reg_17;
		18: tr_7 = r_commit_reg_18;
		19: tr_7 = r_commit_reg_19;
		20: tr_7 = r_commit_reg_20;
		21: tr_7 = r_commit_reg_21;
		22: tr_7 = r_commit_reg_22;
		23: tr_7 = r_commit_reg_23;
		24: tr_7 = r_commit_reg_24;
		25: tr_7 = r_commit_reg_25;
		26: tr_7 = r_commit_reg_26;
		27: tr_7 = r_commit_reg_27;
		28: tr_7 = r_commit_reg_28;
		29: tr_7 = r_commit_reg_29;
		30: tr_7 = r_commit_reg_30;
		31: tr_7 = r_commit_reg_31;
		endcase
	end 
	always @(posedge clk) 
		transfer_reg_7 <= tr_7;
`else
	always @(posedge clk) 
		transfer_reg_7 <= r_commit_reg[transfer_source_addr7];
`endif
	always @(posedge clk) 
		transfer_write_addr_7 <= transfer_dest_addr7;
`ifdef FP
	always @(posedge clk) 
		transfer_write_fp_7 <= transfer_dest_fp7;
	always @(posedge clk) 
		if (transfer_enable7 && !reset && (transfer_dest_fp7||transfer_dest_addr7!=0)) begin
			transfer_pending[7] <= 1;
		end else begin
			transfer_pending[7] <= 0;
		end 
`else
	always @(posedge clk) 
		if (transfer_enable7 && !reset && transfer_dest_addr7!=0) begin
			transfer_pending[7] <= 1;
		end else begin
			transfer_pending[7] <= 0;
		end 
`endif
`ifndef VSYNTH
	always @(posedge clk) 
`ifdef FP
	if (transfer_pending_ok[7] && !transfer_dest_fp7)
`else
	if (transfer_pending_ok[7])
`endif
		r_real_reg[transfer_write_addr_7] <= transfer_reg_7;
`endif
	assign transfer_pending_ok[7] = (transfer_pending[7]
);
`ifdef FP
	wire [7:0]fp_transfer = {transfer_write_fp_7,transfer_write_fp_6,transfer_write_fp_5,transfer_write_fp_4,transfer_write_fp_3,transfer_write_fp_2,transfer_write_fp_1,transfer_write_fp_0};
`endif
`ifdef VSYNTH
	reg	[RV-1:0]tvr_1;
	wire [7:0]rwp_1 = {transfer_pending[7]&(transfer_write_addr_7==1), transfer_pending[6]&(transfer_write_addr_6==1), transfer_pending[5]&(transfer_write_addr_5==1), transfer_pending[4]&(transfer_write_addr_4==1), transfer_pending[3]&(transfer_write_addr_3==1), transfer_pending[2]&(transfer_write_addr_2==1), transfer_pending[1]&(transfer_write_addr_1==1), transfer_pending[0]&(transfer_write_addr_0==1) };
	always @(*) begin
		tvr_1 = 'bx;
		casez (rwp_1) // synthesis full_case parallel_case
		8'b1???????: tvr_1 = transfer_reg_7;
		8'b?1??????: tvr_1 = transfer_reg_6;
		8'b??1?????: tvr_1 = transfer_reg_5;
		8'b???1????: tvr_1 = transfer_reg_4;
		8'b????1???: tvr_1 = transfer_reg_3;
		8'b?????1??: tvr_1 = transfer_reg_2;
		8'b??????1?: tvr_1 = transfer_reg_1;
		8'b???????1: tvr_1 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_1&~fp_transfer))
`else
	if (|rwp_1)
`endif
		r_real_reg_1 <= tvr_1;
	reg	[RV-1:0]tvr_2;
	wire [7:0]rwp_2 = {transfer_pending[7]&(transfer_write_addr_7==2), transfer_pending[6]&(transfer_write_addr_6==2), transfer_pending[5]&(transfer_write_addr_5==2), transfer_pending[4]&(transfer_write_addr_4==2), transfer_pending[3]&(transfer_write_addr_3==2), transfer_pending[2]&(transfer_write_addr_2==2), transfer_pending[1]&(transfer_write_addr_1==2), transfer_pending[0]&(transfer_write_addr_0==2) };
	always @(*) begin
		tvr_2 = 'bx;
		casez (rwp_2) // synthesis full_case parallel_case
		8'b1???????: tvr_2 = transfer_reg_7;
		8'b?1??????: tvr_2 = transfer_reg_6;
		8'b??1?????: tvr_2 = transfer_reg_5;
		8'b???1????: tvr_2 = transfer_reg_4;
		8'b????1???: tvr_2 = transfer_reg_3;
		8'b?????1??: tvr_2 = transfer_reg_2;
		8'b??????1?: tvr_2 = transfer_reg_1;
		8'b???????1: tvr_2 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_2&~fp_transfer))
`else
	if (|rwp_2)
`endif
		r_real_reg_2 <= tvr_2;
	reg	[RV-1:0]tvr_3;
	wire [7:0]rwp_3 = {transfer_pending[7]&(transfer_write_addr_7==3), transfer_pending[6]&(transfer_write_addr_6==3), transfer_pending[5]&(transfer_write_addr_5==3), transfer_pending[4]&(transfer_write_addr_4==3), transfer_pending[3]&(transfer_write_addr_3==3), transfer_pending[2]&(transfer_write_addr_2==3), transfer_pending[1]&(transfer_write_addr_1==3), transfer_pending[0]&(transfer_write_addr_0==3) };
	always @(*) begin
		tvr_3 = 'bx;
		casez (rwp_3) // synthesis full_case parallel_case
		8'b1???????: tvr_3 = transfer_reg_7;
		8'b?1??????: tvr_3 = transfer_reg_6;
		8'b??1?????: tvr_3 = transfer_reg_5;
		8'b???1????: tvr_3 = transfer_reg_4;
		8'b????1???: tvr_3 = transfer_reg_3;
		8'b?????1??: tvr_3 = transfer_reg_2;
		8'b??????1?: tvr_3 = transfer_reg_1;
		8'b???????1: tvr_3 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_3&~fp_transfer))
`else
	if (|rwp_3)
`endif
		r_real_reg_3 <= tvr_3;
	reg	[RV-1:0]tvr_4;
	wire [7:0]rwp_4 = {transfer_pending[7]&(transfer_write_addr_7==4), transfer_pending[6]&(transfer_write_addr_6==4), transfer_pending[5]&(transfer_write_addr_5==4), transfer_pending[4]&(transfer_write_addr_4==4), transfer_pending[3]&(transfer_write_addr_3==4), transfer_pending[2]&(transfer_write_addr_2==4), transfer_pending[1]&(transfer_write_addr_1==4), transfer_pending[0]&(transfer_write_addr_0==4) };
	always @(*) begin
		tvr_4 = 'bx;
		casez (rwp_4) // synthesis full_case parallel_case
		8'b1???????: tvr_4 = transfer_reg_7;
		8'b?1??????: tvr_4 = transfer_reg_6;
		8'b??1?????: tvr_4 = transfer_reg_5;
		8'b???1????: tvr_4 = transfer_reg_4;
		8'b????1???: tvr_4 = transfer_reg_3;
		8'b?????1??: tvr_4 = transfer_reg_2;
		8'b??????1?: tvr_4 = transfer_reg_1;
		8'b???????1: tvr_4 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_4&~fp_transfer))
`else
	if (|rwp_4)
`endif
		r_real_reg_4 <= tvr_4;
	reg	[RV-1:0]tvr_5;
	wire [7:0]rwp_5 = {transfer_pending[7]&(transfer_write_addr_7==5), transfer_pending[6]&(transfer_write_addr_6==5), transfer_pending[5]&(transfer_write_addr_5==5), transfer_pending[4]&(transfer_write_addr_4==5), transfer_pending[3]&(transfer_write_addr_3==5), transfer_pending[2]&(transfer_write_addr_2==5), transfer_pending[1]&(transfer_write_addr_1==5), transfer_pending[0]&(transfer_write_addr_0==5) };
	always @(*) begin
		tvr_5 = 'bx;
		casez (rwp_5) // synthesis full_case parallel_case
		8'b1???????: tvr_5 = transfer_reg_7;
		8'b?1??????: tvr_5 = transfer_reg_6;
		8'b??1?????: tvr_5 = transfer_reg_5;
		8'b???1????: tvr_5 = transfer_reg_4;
		8'b????1???: tvr_5 = transfer_reg_3;
		8'b?????1??: tvr_5 = transfer_reg_2;
		8'b??????1?: tvr_5 = transfer_reg_1;
		8'b???????1: tvr_5 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_5&~fp_transfer))
`else
	if (|rwp_5)
`endif
		r_real_reg_5 <= tvr_5;
	reg	[RV-1:0]tvr_6;
	wire [7:0]rwp_6 = {transfer_pending[7]&(transfer_write_addr_7==6), transfer_pending[6]&(transfer_write_addr_6==6), transfer_pending[5]&(transfer_write_addr_5==6), transfer_pending[4]&(transfer_write_addr_4==6), transfer_pending[3]&(transfer_write_addr_3==6), transfer_pending[2]&(transfer_write_addr_2==6), transfer_pending[1]&(transfer_write_addr_1==6), transfer_pending[0]&(transfer_write_addr_0==6) };
	always @(*) begin
		tvr_6 = 'bx;
		casez (rwp_6) // synthesis full_case parallel_case
		8'b1???????: tvr_6 = transfer_reg_7;
		8'b?1??????: tvr_6 = transfer_reg_6;
		8'b??1?????: tvr_6 = transfer_reg_5;
		8'b???1????: tvr_6 = transfer_reg_4;
		8'b????1???: tvr_6 = transfer_reg_3;
		8'b?????1??: tvr_6 = transfer_reg_2;
		8'b??????1?: tvr_6 = transfer_reg_1;
		8'b???????1: tvr_6 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_6&~fp_transfer))
`else
	if (|rwp_6)
`endif
		r_real_reg_6 <= tvr_6;
	reg	[RV-1:0]tvr_7;
	wire [7:0]rwp_7 = {transfer_pending[7]&(transfer_write_addr_7==7), transfer_pending[6]&(transfer_write_addr_6==7), transfer_pending[5]&(transfer_write_addr_5==7), transfer_pending[4]&(transfer_write_addr_4==7), transfer_pending[3]&(transfer_write_addr_3==7), transfer_pending[2]&(transfer_write_addr_2==7), transfer_pending[1]&(transfer_write_addr_1==7), transfer_pending[0]&(transfer_write_addr_0==7) };
	always @(*) begin
		tvr_7 = 'bx;
		casez (rwp_7) // synthesis full_case parallel_case
		8'b1???????: tvr_7 = transfer_reg_7;
		8'b?1??????: tvr_7 = transfer_reg_6;
		8'b??1?????: tvr_7 = transfer_reg_5;
		8'b???1????: tvr_7 = transfer_reg_4;
		8'b????1???: tvr_7 = transfer_reg_3;
		8'b?????1??: tvr_7 = transfer_reg_2;
		8'b??????1?: tvr_7 = transfer_reg_1;
		8'b???????1: tvr_7 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_7&~fp_transfer))
`else
	if (|rwp_7)
`endif
		r_real_reg_7 <= tvr_7;
	reg	[RV-1:0]tvr_8;
	wire [7:0]rwp_8 = {transfer_pending[7]&(transfer_write_addr_7==8), transfer_pending[6]&(transfer_write_addr_6==8), transfer_pending[5]&(transfer_write_addr_5==8), transfer_pending[4]&(transfer_write_addr_4==8), transfer_pending[3]&(transfer_write_addr_3==8), transfer_pending[2]&(transfer_write_addr_2==8), transfer_pending[1]&(transfer_write_addr_1==8), transfer_pending[0]&(transfer_write_addr_0==8) };
	always @(*) begin
		tvr_8 = 'bx;
		casez (rwp_8) // synthesis full_case parallel_case
		8'b1???????: tvr_8 = transfer_reg_7;
		8'b?1??????: tvr_8 = transfer_reg_6;
		8'b??1?????: tvr_8 = transfer_reg_5;
		8'b???1????: tvr_8 = transfer_reg_4;
		8'b????1???: tvr_8 = transfer_reg_3;
		8'b?????1??: tvr_8 = transfer_reg_2;
		8'b??????1?: tvr_8 = transfer_reg_1;
		8'b???????1: tvr_8 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_8&~fp_transfer))
`else
	if (|rwp_8)
`endif
		r_real_reg_8 <= tvr_8;
	reg	[RV-1:0]tvr_9;
	wire [7:0]rwp_9 = {transfer_pending[7]&(transfer_write_addr_7==9), transfer_pending[6]&(transfer_write_addr_6==9), transfer_pending[5]&(transfer_write_addr_5==9), transfer_pending[4]&(transfer_write_addr_4==9), transfer_pending[3]&(transfer_write_addr_3==9), transfer_pending[2]&(transfer_write_addr_2==9), transfer_pending[1]&(transfer_write_addr_1==9), transfer_pending[0]&(transfer_write_addr_0==9) };
	always @(*) begin
		tvr_9 = 'bx;
		casez (rwp_9) // synthesis full_case parallel_case
		8'b1???????: tvr_9 = transfer_reg_7;
		8'b?1??????: tvr_9 = transfer_reg_6;
		8'b??1?????: tvr_9 = transfer_reg_5;
		8'b???1????: tvr_9 = transfer_reg_4;
		8'b????1???: tvr_9 = transfer_reg_3;
		8'b?????1??: tvr_9 = transfer_reg_2;
		8'b??????1?: tvr_9 = transfer_reg_1;
		8'b???????1: tvr_9 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_9&~fp_transfer))
`else
	if (|rwp_9)
`endif
		r_real_reg_9 <= tvr_9;
	reg	[RV-1:0]tvr_10;
	wire [7:0]rwp_10 = {transfer_pending[7]&(transfer_write_addr_7==10), transfer_pending[6]&(transfer_write_addr_6==10), transfer_pending[5]&(transfer_write_addr_5==10), transfer_pending[4]&(transfer_write_addr_4==10), transfer_pending[3]&(transfer_write_addr_3==10), transfer_pending[2]&(transfer_write_addr_2==10), transfer_pending[1]&(transfer_write_addr_1==10), transfer_pending[0]&(transfer_write_addr_0==10) };
	always @(*) begin
		tvr_10 = 'bx;
		casez (rwp_10) // synthesis full_case parallel_case
		8'b1???????: tvr_10 = transfer_reg_7;
		8'b?1??????: tvr_10 = transfer_reg_6;
		8'b??1?????: tvr_10 = transfer_reg_5;
		8'b???1????: tvr_10 = transfer_reg_4;
		8'b????1???: tvr_10 = transfer_reg_3;
		8'b?????1??: tvr_10 = transfer_reg_2;
		8'b??????1?: tvr_10 = transfer_reg_1;
		8'b???????1: tvr_10 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_10&~fp_transfer))
`else
	if (|rwp_10)
`endif
		r_real_reg_10 <= tvr_10;
	reg	[RV-1:0]tvr_11;
	wire [7:0]rwp_11 = {transfer_pending[7]&(transfer_write_addr_7==11), transfer_pending[6]&(transfer_write_addr_6==11), transfer_pending[5]&(transfer_write_addr_5==11), transfer_pending[4]&(transfer_write_addr_4==11), transfer_pending[3]&(transfer_write_addr_3==11), transfer_pending[2]&(transfer_write_addr_2==11), transfer_pending[1]&(transfer_write_addr_1==11), transfer_pending[0]&(transfer_write_addr_0==11) };
	always @(*) begin
		tvr_11 = 'bx;
		casez (rwp_11) // synthesis full_case parallel_case
		8'b1???????: tvr_11 = transfer_reg_7;
		8'b?1??????: tvr_11 = transfer_reg_6;
		8'b??1?????: tvr_11 = transfer_reg_5;
		8'b???1????: tvr_11 = transfer_reg_4;
		8'b????1???: tvr_11 = transfer_reg_3;
		8'b?????1??: tvr_11 = transfer_reg_2;
		8'b??????1?: tvr_11 = transfer_reg_1;
		8'b???????1: tvr_11 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_11&~fp_transfer))
`else
	if (|rwp_11)
`endif
		r_real_reg_11 <= tvr_11;
	reg	[RV-1:0]tvr_12;
	wire [7:0]rwp_12 = {transfer_pending[7]&(transfer_write_addr_7==12), transfer_pending[6]&(transfer_write_addr_6==12), transfer_pending[5]&(transfer_write_addr_5==12), transfer_pending[4]&(transfer_write_addr_4==12), transfer_pending[3]&(transfer_write_addr_3==12), transfer_pending[2]&(transfer_write_addr_2==12), transfer_pending[1]&(transfer_write_addr_1==12), transfer_pending[0]&(transfer_write_addr_0==12) };
	always @(*) begin
		tvr_12 = 'bx;
		casez (rwp_12) // synthesis full_case parallel_case
		8'b1???????: tvr_12 = transfer_reg_7;
		8'b?1??????: tvr_12 = transfer_reg_6;
		8'b??1?????: tvr_12 = transfer_reg_5;
		8'b???1????: tvr_12 = transfer_reg_4;
		8'b????1???: tvr_12 = transfer_reg_3;
		8'b?????1??: tvr_12 = transfer_reg_2;
		8'b??????1?: tvr_12 = transfer_reg_1;
		8'b???????1: tvr_12 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_12&~fp_transfer))
`else
	if (|rwp_12)
`endif
		r_real_reg_12 <= tvr_12;
	reg	[RV-1:0]tvr_13;
	wire [7:0]rwp_13 = {transfer_pending[7]&(transfer_write_addr_7==13), transfer_pending[6]&(transfer_write_addr_6==13), transfer_pending[5]&(transfer_write_addr_5==13), transfer_pending[4]&(transfer_write_addr_4==13), transfer_pending[3]&(transfer_write_addr_3==13), transfer_pending[2]&(transfer_write_addr_2==13), transfer_pending[1]&(transfer_write_addr_1==13), transfer_pending[0]&(transfer_write_addr_0==13) };
	always @(*) begin
		tvr_13 = 'bx;
		casez (rwp_13) // synthesis full_case parallel_case
		8'b1???????: tvr_13 = transfer_reg_7;
		8'b?1??????: tvr_13 = transfer_reg_6;
		8'b??1?????: tvr_13 = transfer_reg_5;
		8'b???1????: tvr_13 = transfer_reg_4;
		8'b????1???: tvr_13 = transfer_reg_3;
		8'b?????1??: tvr_13 = transfer_reg_2;
		8'b??????1?: tvr_13 = transfer_reg_1;
		8'b???????1: tvr_13 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_13&~fp_transfer))
`else
	if (|rwp_13)
`endif
		r_real_reg_13 <= tvr_13;
	reg	[RV-1:0]tvr_14;
	wire [7:0]rwp_14 = {transfer_pending[7]&(transfer_write_addr_7==14), transfer_pending[6]&(transfer_write_addr_6==14), transfer_pending[5]&(transfer_write_addr_5==14), transfer_pending[4]&(transfer_write_addr_4==14), transfer_pending[3]&(transfer_write_addr_3==14), transfer_pending[2]&(transfer_write_addr_2==14), transfer_pending[1]&(transfer_write_addr_1==14), transfer_pending[0]&(transfer_write_addr_0==14) };
	always @(*) begin
		tvr_14 = 'bx;
		casez (rwp_14) // synthesis full_case parallel_case
		8'b1???????: tvr_14 = transfer_reg_7;
		8'b?1??????: tvr_14 = transfer_reg_6;
		8'b??1?????: tvr_14 = transfer_reg_5;
		8'b???1????: tvr_14 = transfer_reg_4;
		8'b????1???: tvr_14 = transfer_reg_3;
		8'b?????1??: tvr_14 = transfer_reg_2;
		8'b??????1?: tvr_14 = transfer_reg_1;
		8'b???????1: tvr_14 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_14&~fp_transfer))
`else
	if (|rwp_14)
`endif
		r_real_reg_14 <= tvr_14;
	reg	[RV-1:0]tvr_15;
	wire [7:0]rwp_15 = {transfer_pending[7]&(transfer_write_addr_7==15), transfer_pending[6]&(transfer_write_addr_6==15), transfer_pending[5]&(transfer_write_addr_5==15), transfer_pending[4]&(transfer_write_addr_4==15), transfer_pending[3]&(transfer_write_addr_3==15), transfer_pending[2]&(transfer_write_addr_2==15), transfer_pending[1]&(transfer_write_addr_1==15), transfer_pending[0]&(transfer_write_addr_0==15) };
	always @(*) begin
		tvr_15 = 'bx;
		casez (rwp_15) // synthesis full_case parallel_case
		8'b1???????: tvr_15 = transfer_reg_7;
		8'b?1??????: tvr_15 = transfer_reg_6;
		8'b??1?????: tvr_15 = transfer_reg_5;
		8'b???1????: tvr_15 = transfer_reg_4;
		8'b????1???: tvr_15 = transfer_reg_3;
		8'b?????1??: tvr_15 = transfer_reg_2;
		8'b??????1?: tvr_15 = transfer_reg_1;
		8'b???????1: tvr_15 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_15&~fp_transfer))
`else
	if (|rwp_15)
`endif
		r_real_reg_15 <= tvr_15;
	reg	[RV-1:0]tvr_16;
	wire [7:0]rwp_16 = {transfer_pending[7]&(transfer_write_addr_7==16), transfer_pending[6]&(transfer_write_addr_6==16), transfer_pending[5]&(transfer_write_addr_5==16), transfer_pending[4]&(transfer_write_addr_4==16), transfer_pending[3]&(transfer_write_addr_3==16), transfer_pending[2]&(transfer_write_addr_2==16), transfer_pending[1]&(transfer_write_addr_1==16), transfer_pending[0]&(transfer_write_addr_0==16) };
	always @(*) begin
		tvr_16 = 'bx;
		casez (rwp_16) // synthesis full_case parallel_case
		8'b1???????: tvr_16 = transfer_reg_7;
		8'b?1??????: tvr_16 = transfer_reg_6;
		8'b??1?????: tvr_16 = transfer_reg_5;
		8'b???1????: tvr_16 = transfer_reg_4;
		8'b????1???: tvr_16 = transfer_reg_3;
		8'b?????1??: tvr_16 = transfer_reg_2;
		8'b??????1?: tvr_16 = transfer_reg_1;
		8'b???????1: tvr_16 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_16&~fp_transfer))
`else
	if (|rwp_16)
`endif
		r_real_reg_16 <= tvr_16;
	reg	[RV-1:0]tvr_17;
	wire [7:0]rwp_17 = {transfer_pending[7]&(transfer_write_addr_7==17), transfer_pending[6]&(transfer_write_addr_6==17), transfer_pending[5]&(transfer_write_addr_5==17), transfer_pending[4]&(transfer_write_addr_4==17), transfer_pending[3]&(transfer_write_addr_3==17), transfer_pending[2]&(transfer_write_addr_2==17), transfer_pending[1]&(transfer_write_addr_1==17), transfer_pending[0]&(transfer_write_addr_0==17) };
	always @(*) begin
		tvr_17 = 'bx;
		casez (rwp_17) // synthesis full_case parallel_case
		8'b1???????: tvr_17 = transfer_reg_7;
		8'b?1??????: tvr_17 = transfer_reg_6;
		8'b??1?????: tvr_17 = transfer_reg_5;
		8'b???1????: tvr_17 = transfer_reg_4;
		8'b????1???: tvr_17 = transfer_reg_3;
		8'b?????1??: tvr_17 = transfer_reg_2;
		8'b??????1?: tvr_17 = transfer_reg_1;
		8'b???????1: tvr_17 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_17&~fp_transfer))
`else
	if (|rwp_17)
`endif
		r_real_reg_17 <= tvr_17;
	reg	[RV-1:0]tvr_18;
	wire [7:0]rwp_18 = {transfer_pending[7]&(transfer_write_addr_7==18), transfer_pending[6]&(transfer_write_addr_6==18), transfer_pending[5]&(transfer_write_addr_5==18), transfer_pending[4]&(transfer_write_addr_4==18), transfer_pending[3]&(transfer_write_addr_3==18), transfer_pending[2]&(transfer_write_addr_2==18), transfer_pending[1]&(transfer_write_addr_1==18), transfer_pending[0]&(transfer_write_addr_0==18) };
	always @(*) begin
		tvr_18 = 'bx;
		casez (rwp_18) // synthesis full_case parallel_case
		8'b1???????: tvr_18 = transfer_reg_7;
		8'b?1??????: tvr_18 = transfer_reg_6;
		8'b??1?????: tvr_18 = transfer_reg_5;
		8'b???1????: tvr_18 = transfer_reg_4;
		8'b????1???: tvr_18 = transfer_reg_3;
		8'b?????1??: tvr_18 = transfer_reg_2;
		8'b??????1?: tvr_18 = transfer_reg_1;
		8'b???????1: tvr_18 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_18&~fp_transfer))
`else
	if (|rwp_18)
`endif
		r_real_reg_18 <= tvr_18;
	reg	[RV-1:0]tvr_19;
	wire [7:0]rwp_19 = {transfer_pending[7]&(transfer_write_addr_7==19), transfer_pending[6]&(transfer_write_addr_6==19), transfer_pending[5]&(transfer_write_addr_5==19), transfer_pending[4]&(transfer_write_addr_4==19), transfer_pending[3]&(transfer_write_addr_3==19), transfer_pending[2]&(transfer_write_addr_2==19), transfer_pending[1]&(transfer_write_addr_1==19), transfer_pending[0]&(transfer_write_addr_0==19) };
	always @(*) begin
		tvr_19 = 'bx;
		casez (rwp_19) // synthesis full_case parallel_case
		8'b1???????: tvr_19 = transfer_reg_7;
		8'b?1??????: tvr_19 = transfer_reg_6;
		8'b??1?????: tvr_19 = transfer_reg_5;
		8'b???1????: tvr_19 = transfer_reg_4;
		8'b????1???: tvr_19 = transfer_reg_3;
		8'b?????1??: tvr_19 = transfer_reg_2;
		8'b??????1?: tvr_19 = transfer_reg_1;
		8'b???????1: tvr_19 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_19&~fp_transfer))
`else
	if (|rwp_19)
`endif
		r_real_reg_19 <= tvr_19;
	reg	[RV-1:0]tvr_20;
	wire [7:0]rwp_20 = {transfer_pending[7]&(transfer_write_addr_7==20), transfer_pending[6]&(transfer_write_addr_6==20), transfer_pending[5]&(transfer_write_addr_5==20), transfer_pending[4]&(transfer_write_addr_4==20), transfer_pending[3]&(transfer_write_addr_3==20), transfer_pending[2]&(transfer_write_addr_2==20), transfer_pending[1]&(transfer_write_addr_1==20), transfer_pending[0]&(transfer_write_addr_0==20) };
	always @(*) begin
		tvr_20 = 'bx;
		casez (rwp_20) // synthesis full_case parallel_case
		8'b1???????: tvr_20 = transfer_reg_7;
		8'b?1??????: tvr_20 = transfer_reg_6;
		8'b??1?????: tvr_20 = transfer_reg_5;
		8'b???1????: tvr_20 = transfer_reg_4;
		8'b????1???: tvr_20 = transfer_reg_3;
		8'b?????1??: tvr_20 = transfer_reg_2;
		8'b??????1?: tvr_20 = transfer_reg_1;
		8'b???????1: tvr_20 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_20&~fp_transfer))
`else
	if (|rwp_20)
`endif
		r_real_reg_20 <= tvr_20;
	reg	[RV-1:0]tvr_21;
	wire [7:0]rwp_21 = {transfer_pending[7]&(transfer_write_addr_7==21), transfer_pending[6]&(transfer_write_addr_6==21), transfer_pending[5]&(transfer_write_addr_5==21), transfer_pending[4]&(transfer_write_addr_4==21), transfer_pending[3]&(transfer_write_addr_3==21), transfer_pending[2]&(transfer_write_addr_2==21), transfer_pending[1]&(transfer_write_addr_1==21), transfer_pending[0]&(transfer_write_addr_0==21) };
	always @(*) begin
		tvr_21 = 'bx;
		casez (rwp_21) // synthesis full_case parallel_case
		8'b1???????: tvr_21 = transfer_reg_7;
		8'b?1??????: tvr_21 = transfer_reg_6;
		8'b??1?????: tvr_21 = transfer_reg_5;
		8'b???1????: tvr_21 = transfer_reg_4;
		8'b????1???: tvr_21 = transfer_reg_3;
		8'b?????1??: tvr_21 = transfer_reg_2;
		8'b??????1?: tvr_21 = transfer_reg_1;
		8'b???????1: tvr_21 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_21&~fp_transfer))
`else
	if (|rwp_21)
`endif
		r_real_reg_21 <= tvr_21;
	reg	[RV-1:0]tvr_22;
	wire [7:0]rwp_22 = {transfer_pending[7]&(transfer_write_addr_7==22), transfer_pending[6]&(transfer_write_addr_6==22), transfer_pending[5]&(transfer_write_addr_5==22), transfer_pending[4]&(transfer_write_addr_4==22), transfer_pending[3]&(transfer_write_addr_3==22), transfer_pending[2]&(transfer_write_addr_2==22), transfer_pending[1]&(transfer_write_addr_1==22), transfer_pending[0]&(transfer_write_addr_0==22) };
	always @(*) begin
		tvr_22 = 'bx;
		casez (rwp_22) // synthesis full_case parallel_case
		8'b1???????: tvr_22 = transfer_reg_7;
		8'b?1??????: tvr_22 = transfer_reg_6;
		8'b??1?????: tvr_22 = transfer_reg_5;
		8'b???1????: tvr_22 = transfer_reg_4;
		8'b????1???: tvr_22 = transfer_reg_3;
		8'b?????1??: tvr_22 = transfer_reg_2;
		8'b??????1?: tvr_22 = transfer_reg_1;
		8'b???????1: tvr_22 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_22&~fp_transfer))
`else
	if (|rwp_22)
`endif
		r_real_reg_22 <= tvr_22;
	reg	[RV-1:0]tvr_23;
	wire [7:0]rwp_23 = {transfer_pending[7]&(transfer_write_addr_7==23), transfer_pending[6]&(transfer_write_addr_6==23), transfer_pending[5]&(transfer_write_addr_5==23), transfer_pending[4]&(transfer_write_addr_4==23), transfer_pending[3]&(transfer_write_addr_3==23), transfer_pending[2]&(transfer_write_addr_2==23), transfer_pending[1]&(transfer_write_addr_1==23), transfer_pending[0]&(transfer_write_addr_0==23) };
	always @(*) begin
		tvr_23 = 'bx;
		casez (rwp_23) // synthesis full_case parallel_case
		8'b1???????: tvr_23 = transfer_reg_7;
		8'b?1??????: tvr_23 = transfer_reg_6;
		8'b??1?????: tvr_23 = transfer_reg_5;
		8'b???1????: tvr_23 = transfer_reg_4;
		8'b????1???: tvr_23 = transfer_reg_3;
		8'b?????1??: tvr_23 = transfer_reg_2;
		8'b??????1?: tvr_23 = transfer_reg_1;
		8'b???????1: tvr_23 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_23&~fp_transfer))
`else
	if (|rwp_23)
`endif
		r_real_reg_23 <= tvr_23;
	reg	[RV-1:0]tvr_24;
	wire [7:0]rwp_24 = {transfer_pending[7]&(transfer_write_addr_7==24), transfer_pending[6]&(transfer_write_addr_6==24), transfer_pending[5]&(transfer_write_addr_5==24), transfer_pending[4]&(transfer_write_addr_4==24), transfer_pending[3]&(transfer_write_addr_3==24), transfer_pending[2]&(transfer_write_addr_2==24), transfer_pending[1]&(transfer_write_addr_1==24), transfer_pending[0]&(transfer_write_addr_0==24) };
	always @(*) begin
		tvr_24 = 'bx;
		casez (rwp_24) // synthesis full_case parallel_case
		8'b1???????: tvr_24 = transfer_reg_7;
		8'b?1??????: tvr_24 = transfer_reg_6;
		8'b??1?????: tvr_24 = transfer_reg_5;
		8'b???1????: tvr_24 = transfer_reg_4;
		8'b????1???: tvr_24 = transfer_reg_3;
		8'b?????1??: tvr_24 = transfer_reg_2;
		8'b??????1?: tvr_24 = transfer_reg_1;
		8'b???????1: tvr_24 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_24&~fp_transfer))
`else
	if (|rwp_24)
`endif
		r_real_reg_24 <= tvr_24;
	reg	[RV-1:0]tvr_25;
	wire [7:0]rwp_25 = {transfer_pending[7]&(transfer_write_addr_7==25), transfer_pending[6]&(transfer_write_addr_6==25), transfer_pending[5]&(transfer_write_addr_5==25), transfer_pending[4]&(transfer_write_addr_4==25), transfer_pending[3]&(transfer_write_addr_3==25), transfer_pending[2]&(transfer_write_addr_2==25), transfer_pending[1]&(transfer_write_addr_1==25), transfer_pending[0]&(transfer_write_addr_0==25) };
	always @(*) begin
		tvr_25 = 'bx;
		casez (rwp_25) // synthesis full_case parallel_case
		8'b1???????: tvr_25 = transfer_reg_7;
		8'b?1??????: tvr_25 = transfer_reg_6;
		8'b??1?????: tvr_25 = transfer_reg_5;
		8'b???1????: tvr_25 = transfer_reg_4;
		8'b????1???: tvr_25 = transfer_reg_3;
		8'b?????1??: tvr_25 = transfer_reg_2;
		8'b??????1?: tvr_25 = transfer_reg_1;
		8'b???????1: tvr_25 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_25&~fp_transfer))
`else
	if (|rwp_25)
`endif
		r_real_reg_25 <= tvr_25;
	reg	[RV-1:0]tvr_26;
	wire [7:0]rwp_26 = {transfer_pending[7]&(transfer_write_addr_7==26), transfer_pending[6]&(transfer_write_addr_6==26), transfer_pending[5]&(transfer_write_addr_5==26), transfer_pending[4]&(transfer_write_addr_4==26), transfer_pending[3]&(transfer_write_addr_3==26), transfer_pending[2]&(transfer_write_addr_2==26), transfer_pending[1]&(transfer_write_addr_1==26), transfer_pending[0]&(transfer_write_addr_0==26) };
	always @(*) begin
		tvr_26 = 'bx;
		casez (rwp_26) // synthesis full_case parallel_case
		8'b1???????: tvr_26 = transfer_reg_7;
		8'b?1??????: tvr_26 = transfer_reg_6;
		8'b??1?????: tvr_26 = transfer_reg_5;
		8'b???1????: tvr_26 = transfer_reg_4;
		8'b????1???: tvr_26 = transfer_reg_3;
		8'b?????1??: tvr_26 = transfer_reg_2;
		8'b??????1?: tvr_26 = transfer_reg_1;
		8'b???????1: tvr_26 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_26&~fp_transfer))
`else
	if (|rwp_26)
`endif
		r_real_reg_26 <= tvr_26;
	reg	[RV-1:0]tvr_27;
	wire [7:0]rwp_27 = {transfer_pending[7]&(transfer_write_addr_7==27), transfer_pending[6]&(transfer_write_addr_6==27), transfer_pending[5]&(transfer_write_addr_5==27), transfer_pending[4]&(transfer_write_addr_4==27), transfer_pending[3]&(transfer_write_addr_3==27), transfer_pending[2]&(transfer_write_addr_2==27), transfer_pending[1]&(transfer_write_addr_1==27), transfer_pending[0]&(transfer_write_addr_0==27) };
	always @(*) begin
		tvr_27 = 'bx;
		casez (rwp_27) // synthesis full_case parallel_case
		8'b1???????: tvr_27 = transfer_reg_7;
		8'b?1??????: tvr_27 = transfer_reg_6;
		8'b??1?????: tvr_27 = transfer_reg_5;
		8'b???1????: tvr_27 = transfer_reg_4;
		8'b????1???: tvr_27 = transfer_reg_3;
		8'b?????1??: tvr_27 = transfer_reg_2;
		8'b??????1?: tvr_27 = transfer_reg_1;
		8'b???????1: tvr_27 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_27&~fp_transfer))
`else
	if (|rwp_27)
`endif
		r_real_reg_27 <= tvr_27;
	reg	[RV-1:0]tvr_28;
	wire [7:0]rwp_28 = {transfer_pending[7]&(transfer_write_addr_7==28), transfer_pending[6]&(transfer_write_addr_6==28), transfer_pending[5]&(transfer_write_addr_5==28), transfer_pending[4]&(transfer_write_addr_4==28), transfer_pending[3]&(transfer_write_addr_3==28), transfer_pending[2]&(transfer_write_addr_2==28), transfer_pending[1]&(transfer_write_addr_1==28), transfer_pending[0]&(transfer_write_addr_0==28) };
	always @(*) begin
		tvr_28 = 'bx;
		casez (rwp_28) // synthesis full_case parallel_case
		8'b1???????: tvr_28 = transfer_reg_7;
		8'b?1??????: tvr_28 = transfer_reg_6;
		8'b??1?????: tvr_28 = transfer_reg_5;
		8'b???1????: tvr_28 = transfer_reg_4;
		8'b????1???: tvr_28 = transfer_reg_3;
		8'b?????1??: tvr_28 = transfer_reg_2;
		8'b??????1?: tvr_28 = transfer_reg_1;
		8'b???????1: tvr_28 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_28&~fp_transfer))
`else
	if (|rwp_28)
`endif
		r_real_reg_28 <= tvr_28;
	reg	[RV-1:0]tvr_29;
	wire [7:0]rwp_29 = {transfer_pending[7]&(transfer_write_addr_7==29), transfer_pending[6]&(transfer_write_addr_6==29), transfer_pending[5]&(transfer_write_addr_5==29), transfer_pending[4]&(transfer_write_addr_4==29), transfer_pending[3]&(transfer_write_addr_3==29), transfer_pending[2]&(transfer_write_addr_2==29), transfer_pending[1]&(transfer_write_addr_1==29), transfer_pending[0]&(transfer_write_addr_0==29) };
	always @(*) begin
		tvr_29 = 'bx;
		casez (rwp_29) // synthesis full_case parallel_case
		8'b1???????: tvr_29 = transfer_reg_7;
		8'b?1??????: tvr_29 = transfer_reg_6;
		8'b??1?????: tvr_29 = transfer_reg_5;
		8'b???1????: tvr_29 = transfer_reg_4;
		8'b????1???: tvr_29 = transfer_reg_3;
		8'b?????1??: tvr_29 = transfer_reg_2;
		8'b??????1?: tvr_29 = transfer_reg_1;
		8'b???????1: tvr_29 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_29&~fp_transfer))
`else
	if (|rwp_29)
`endif
		r_real_reg_29 <= tvr_29;
	reg	[RV-1:0]tvr_30;
	wire [7:0]rwp_30 = {transfer_pending[7]&(transfer_write_addr_7==30), transfer_pending[6]&(transfer_write_addr_6==30), transfer_pending[5]&(transfer_write_addr_5==30), transfer_pending[4]&(transfer_write_addr_4==30), transfer_pending[3]&(transfer_write_addr_3==30), transfer_pending[2]&(transfer_write_addr_2==30), transfer_pending[1]&(transfer_write_addr_1==30), transfer_pending[0]&(transfer_write_addr_0==30) };
	always @(*) begin
		tvr_30 = 'bx;
		casez (rwp_30) // synthesis full_case parallel_case
		8'b1???????: tvr_30 = transfer_reg_7;
		8'b?1??????: tvr_30 = transfer_reg_6;
		8'b??1?????: tvr_30 = transfer_reg_5;
		8'b???1????: tvr_30 = transfer_reg_4;
		8'b????1???: tvr_30 = transfer_reg_3;
		8'b?????1??: tvr_30 = transfer_reg_2;
		8'b??????1?: tvr_30 = transfer_reg_1;
		8'b???????1: tvr_30 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_30&~fp_transfer))
`else
	if (|rwp_30)
`endif
		r_real_reg_30 <= tvr_30;
	reg	[RV-1:0]tvr_31;
	wire [7:0]rwp_31 = {transfer_pending[7]&(transfer_write_addr_7==31), transfer_pending[6]&(transfer_write_addr_6==31), transfer_pending[5]&(transfer_write_addr_5==31), transfer_pending[4]&(transfer_write_addr_4==31), transfer_pending[3]&(transfer_write_addr_3==31), transfer_pending[2]&(transfer_write_addr_2==31), transfer_pending[1]&(transfer_write_addr_1==31), transfer_pending[0]&(transfer_write_addr_0==31) };
	always @(*) begin
		tvr_31 = 'bx;
		casez (rwp_31) // synthesis full_case parallel_case
		8'b1???????: tvr_31 = transfer_reg_7;
		8'b?1??????: tvr_31 = transfer_reg_6;
		8'b??1?????: tvr_31 = transfer_reg_5;
		8'b???1????: tvr_31 = transfer_reg_4;
		8'b????1???: tvr_31 = transfer_reg_3;
		8'b?????1??: tvr_31 = transfer_reg_2;
		8'b??????1?: tvr_31 = transfer_reg_1;
		8'b???????1: tvr_31 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
`ifdef FP
	if (|(rwp_31&~fp_transfer))
`else
	if (|rwp_31)
`endif
		r_real_reg_31 <= tvr_31;
`ifdef FP
	reg	[RV-1:0]tvr_0;
	wire [7:0]rwp_0 = {transfer_pending[7]&(transfer_write_addr_7==0), transfer_pending[6]&(transfer_write_addr_6==0), transfer_pending[5]&(transfer_write_addr_5==0), transfer_pending[4]&(transfer_write_addr_4==0), transfer_pending[3]&(transfer_write_addr_3==0), transfer_pending[2]&(transfer_write_addr_2==0), transfer_pending[1]&(transfer_write_addr_1==0), transfer_pending[0]&(transfer_write_addr_0==0) };
	always @(*) begin
		tvr_0 = 'bx;
		casez (rwp_0) // synthesis full_case parallel_case
		8'b1???????: tvr_0 = transfer_reg_7;
		8'b?1??????: tvr_0 = transfer_reg_6;
		8'b??1?????: tvr_0 = transfer_reg_5;
		8'b???1????: tvr_0 = transfer_reg_4;
		8'b????1???: tvr_0 = transfer_reg_3;
		8'b?????1??: tvr_0 = transfer_reg_2;
		8'b??????1?: tvr_0 = transfer_reg_1;
		8'b???????1: tvr_0 = transfer_reg_0;
		endcase
	end
	always @(posedge clk)
	if (|(rwp_0&fp_transfer))
		r_real_fp_reg_0 <= tvr_0;
	always @(posedge clk)
	if (|(rwp_1&fp_transfer))
		r_real_fp_reg_1 <= tvr_1;
	always @(posedge clk)
	if (|(rwp_2&fp_transfer))
		r_real_fp_reg_2 <= tvr_2;
	always @(posedge clk)
	if (|(rwp_3&fp_transfer))
		r_real_fp_reg_3 <= tvr_3;
	always @(posedge clk)
	if (|(rwp_4&fp_transfer))
		r_real_fp_reg_4 <= tvr_4;
	always @(posedge clk)
	if (|(rwp_5&fp_transfer))
		r_real_fp_reg_5 <= tvr_5;
	always @(posedge clk)
	if (|(rwp_6&fp_transfer))
		r_real_fp_reg_6 <= tvr_6;
	always @(posedge clk)
	if (|(rwp_7&fp_transfer))
		r_real_fp_reg_7 <= tvr_7;
	always @(posedge clk)
	if (|(rwp_8&fp_transfer))
		r_real_fp_reg_8 <= tvr_8;
	always @(posedge clk)
	if (|(rwp_9&fp_transfer))
		r_real_fp_reg_9 <= tvr_9;
	always @(posedge clk)
	if (|(rwp_10&fp_transfer))
		r_real_fp_reg_10 <= tvr_10;
	always @(posedge clk)
	if (|(rwp_11&fp_transfer))
		r_real_fp_reg_11 <= tvr_11;
	always @(posedge clk)
	if (|(rwp_12&fp_transfer))
		r_real_fp_reg_12 <= tvr_12;
	always @(posedge clk)
	if (|(rwp_13&fp_transfer))
		r_real_fp_reg_13 <= tvr_13;
	always @(posedge clk)
	if (|(rwp_14&fp_transfer))
		r_real_fp_reg_14 <= tvr_14;
	always @(posedge clk)
	if (|(rwp_15&fp_transfer))
		r_real_fp_reg_15 <= tvr_15;
	always @(posedge clk)
	if (|(rwp_16&fp_transfer))
		r_real_fp_reg_16 <= tvr_16;
	always @(posedge clk)
	if (|(rwp_17&fp_transfer))
		r_real_fp_reg_17 <= tvr_17;
	always @(posedge clk)
	if (|(rwp_18&fp_transfer))
		r_real_fp_reg_18 <= tvr_18;
	always @(posedge clk)
	if (|(rwp_19&fp_transfer))
		r_real_fp_reg_19 <= tvr_19;
	always @(posedge clk)
	if (|(rwp_20&fp_transfer))
		r_real_fp_reg_20 <= tvr_20;
	always @(posedge clk)
	if (|(rwp_21&fp_transfer))
		r_real_fp_reg_21 <= tvr_21;
	always @(posedge clk)
	if (|(rwp_22&fp_transfer))
		r_real_fp_reg_22 <= tvr_22;
	always @(posedge clk)
	if (|(rwp_23&fp_transfer))
		r_real_fp_reg_23 <= tvr_23;
	always @(posedge clk)
	if (|(rwp_24&fp_transfer))
		r_real_fp_reg_24 <= tvr_24;
	always @(posedge clk)
	if (|(rwp_25&fp_transfer))
		r_real_fp_reg_25 <= tvr_25;
	always @(posedge clk)
	if (|(rwp_26&fp_transfer))
		r_real_fp_reg_26 <= tvr_26;
	always @(posedge clk)
	if (|(rwp_27&fp_transfer))
		r_real_fp_reg_27 <= tvr_27;
	always @(posedge clk)
	if (|(rwp_28&fp_transfer))
		r_real_fp_reg_28 <= tvr_28;
	always @(posedge clk)
	if (|(rwp_29&fp_transfer))
		r_real_fp_reg_29 <= tvr_29;
	always @(posedge clk)
	if (|(rwp_30&fp_transfer))
		r_real_fp_reg_30 <= tvr_30;
	always @(posedge clk)
	if (|(rwp_31&fp_transfer))
		r_real_fp_reg_31 <= tvr_31;
`endif
`endif
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg0[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg0[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg0[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg0[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg0[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg0[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg0[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg0[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg0[LNCOMMIT-1:0]), r_rd_reg0[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg0[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg0[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg0[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg0[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg0[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg0[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg0[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg0[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg0[LNCOMMIT-1:0]), r_rd_reg0[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout0 = write_data0;
		10'b?1???????_1: xout0 = write_data1;
		10'b??1??????_1: xout0 = write_data2;
		10'b???1?????_1: xout0 = write_data3;
		10'b????1????_1: xout0 = write_data4;
		10'b?????1???_1: xout0 = write_data5;
		10'b??????1??_1: xout0 = write_data6;
		10'b???????1?_1: xout0 = write_data7;
		10'b????????1_1: xout0 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout0 = r_out0;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg1[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg1[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg1[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg1[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg1[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg1[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg1[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg1[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg1[LNCOMMIT-1:0]), r_rd_reg1[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg1[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg1[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg1[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg1[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg1[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg1[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg1[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg1[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg1[LNCOMMIT-1:0]), r_rd_reg1[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout1 = write_data0;
		10'b?1???????_1: xout1 = write_data1;
		10'b??1??????_1: xout1 = write_data2;
		10'b???1?????_1: xout1 = write_data3;
		10'b????1????_1: xout1 = write_data4;
		10'b?????1???_1: xout1 = write_data5;
		10'b??????1??_1: xout1 = write_data6;
		10'b???????1?_1: xout1 = write_data7;
		10'b????????1_1: xout1 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout1 = r_out1;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg2[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg2[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg2[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg2[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg2[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg2[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg2[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg2[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg2[LNCOMMIT-1:0]), r_rd_reg2[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg2[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg2[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg2[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg2[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg2[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg2[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg2[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg2[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg2[LNCOMMIT-1:0]), r_rd_reg2[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout2 = write_data0;
		10'b?1???????_1: xout2 = write_data1;
		10'b??1??????_1: xout2 = write_data2;
		10'b???1?????_1: xout2 = write_data3;
		10'b????1????_1: xout2 = write_data4;
		10'b?????1???_1: xout2 = write_data5;
		10'b??????1??_1: xout2 = write_data6;
		10'b???????1?_1: xout2 = write_data7;
		10'b????????1_1: xout2 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout2 = r_out2;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg3[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg3[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg3[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg3[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg3[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg3[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg3[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg3[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg3[LNCOMMIT-1:0]), r_rd_reg3[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg3[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg3[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg3[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg3[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg3[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg3[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg3[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg3[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg3[LNCOMMIT-1:0]), r_rd_reg3[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout3 = write_data0;
		10'b?1???????_1: xout3 = write_data1;
		10'b??1??????_1: xout3 = write_data2;
		10'b???1?????_1: xout3 = write_data3;
		10'b????1????_1: xout3 = write_data4;
		10'b?????1???_1: xout3 = write_data5;
		10'b??????1??_1: xout3 = write_data6;
		10'b???????1?_1: xout3 = write_data7;
		10'b????????1_1: xout3 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout3 = r_out3;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg4[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg4[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg4[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg4[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg4[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg4[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg4[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg4[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg4[LNCOMMIT-1:0]), r_rd_reg4[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg4[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg4[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg4[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg4[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg4[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg4[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg4[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg4[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg4[LNCOMMIT-1:0]), r_rd_reg4[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout4 = write_data0;
		10'b?1???????_1: xout4 = write_data1;
		10'b??1??????_1: xout4 = write_data2;
		10'b???1?????_1: xout4 = write_data3;
		10'b????1????_1: xout4 = write_data4;
		10'b?????1???_1: xout4 = write_data5;
		10'b??????1??_1: xout4 = write_data6;
		10'b???????1?_1: xout4 = write_data7;
		10'b????????1_1: xout4 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout4 = r_out4;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg5[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg5[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg5[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg5[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg5[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg5[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg5[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg5[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg5[LNCOMMIT-1:0]), r_rd_reg5[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg5[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg5[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg5[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg5[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg5[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg5[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg5[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg5[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg5[LNCOMMIT-1:0]), r_rd_reg5[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout5 = write_data0;
		10'b?1???????_1: xout5 = write_data1;
		10'b??1??????_1: xout5 = write_data2;
		10'b???1?????_1: xout5 = write_data3;
		10'b????1????_1: xout5 = write_data4;
		10'b?????1???_1: xout5 = write_data5;
		10'b??????1??_1: xout5 = write_data6;
		10'b???????1?_1: xout5 = write_data7;
		10'b????????1_1: xout5 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout5 = r_out5;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg6[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg6[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg6[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg6[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg6[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg6[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg6[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg6[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg6[LNCOMMIT-1:0]), r_rd_reg6[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg6[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg6[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg6[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg6[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg6[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg6[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg6[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg6[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg6[LNCOMMIT-1:0]), r_rd_reg6[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout6 = write_data0;
		10'b?1???????_1: xout6 = write_data1;
		10'b??1??????_1: xout6 = write_data2;
		10'b???1?????_1: xout6 = write_data3;
		10'b????1????_1: xout6 = write_data4;
		10'b?????1???_1: xout6 = write_data5;
		10'b??????1??_1: xout6 = write_data6;
		10'b???????1?_1: xout6 = write_data7;
		10'b????????1_1: xout6 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout6 = r_out6;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg7[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg7[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg7[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg7[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg7[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg7[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg7[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg7[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg7[LNCOMMIT-1:0]), r_rd_reg7[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg7[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg7[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg7[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg7[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg7[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg7[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg7[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg7[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg7[LNCOMMIT-1:0]), r_rd_reg7[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout7 = write_data0;
		10'b?1???????_1: xout7 = write_data1;
		10'b??1??????_1: xout7 = write_data2;
		10'b???1?????_1: xout7 = write_data3;
		10'b????1????_1: xout7 = write_data4;
		10'b?????1???_1: xout7 = write_data5;
		10'b??????1??_1: xout7 = write_data6;
		10'b???????1?_1: xout7 = write_data7;
		10'b????????1_1: xout7 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout7 = r_out7;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg8[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg8[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg8[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg8[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg8[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg8[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg8[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg8[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg8[LNCOMMIT-1:0]), r_rd_reg8[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg8[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg8[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg8[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg8[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg8[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg8[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg8[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg8[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg8[LNCOMMIT-1:0]), r_rd_reg8[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout8 = write_data0;
		10'b?1???????_1: xout8 = write_data1;
		10'b??1??????_1: xout8 = write_data2;
		10'b???1?????_1: xout8 = write_data3;
		10'b????1????_1: xout8 = write_data4;
		10'b?????1???_1: xout8 = write_data5;
		10'b??????1??_1: xout8 = write_data6;
		10'b???????1?_1: xout8 = write_data7;
		10'b????????1_1: xout8 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout8 = r_out8;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg9[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg9[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg9[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg9[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg9[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg9[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg9[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg9[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg9[LNCOMMIT-1:0]), r_rd_reg9[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg9[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg9[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg9[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg9[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg9[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg9[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg9[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg9[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg9[LNCOMMIT-1:0]), r_rd_reg9[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout9 = write_data0;
		10'b?1???????_1: xout9 = write_data1;
		10'b??1??????_1: xout9 = write_data2;
		10'b???1?????_1: xout9 = write_data3;
		10'b????1????_1: xout9 = write_data4;
		10'b?????1???_1: xout9 = write_data5;
		10'b??????1??_1: xout9 = write_data6;
		10'b???????1?_1: xout9 = write_data7;
		10'b????????1_1: xout9 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout9 = r_out9;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg10[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg10[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg10[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg10[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg10[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg10[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg10[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg10[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg10[LNCOMMIT-1:0]), r_rd_reg10[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg10[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg10[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg10[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg10[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg10[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg10[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg10[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg10[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg10[LNCOMMIT-1:0]), r_rd_reg10[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout10 = write_data0;
		10'b?1???????_1: xout10 = write_data1;
		10'b??1??????_1: xout10 = write_data2;
		10'b???1?????_1: xout10 = write_data3;
		10'b????1????_1: xout10 = write_data4;
		10'b?????1???_1: xout10 = write_data5;
		10'b??????1??_1: xout10 = write_data6;
		10'b???????1?_1: xout10 = write_data7;
		10'b????????1_1: xout10 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout10 = r_out10;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg11[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg11[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg11[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg11[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg11[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg11[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg11[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg11[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg11[LNCOMMIT-1:0]), r_rd_reg11[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg11[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg11[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg11[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg11[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg11[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg11[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg11[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg11[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg11[LNCOMMIT-1:0]), r_rd_reg11[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout11 = write_data0;
		10'b?1???????_1: xout11 = write_data1;
		10'b??1??????_1: xout11 = write_data2;
		10'b???1?????_1: xout11 = write_data3;
		10'b????1????_1: xout11 = write_data4;
		10'b?????1???_1: xout11 = write_data5;
		10'b??????1??_1: xout11 = write_data6;
		10'b???????1?_1: xout11 = write_data7;
		10'b????????1_1: xout11 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout11 = r_out11;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg12[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg12[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg12[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg12[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg12[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg12[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg12[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg12[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg12[LNCOMMIT-1:0]), r_rd_reg12[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg12[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg12[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg12[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg12[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg12[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg12[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg12[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg12[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg12[LNCOMMIT-1:0]), r_rd_reg12[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout12 = write_data0;
		10'b?1???????_1: xout12 = write_data1;
		10'b??1??????_1: xout12 = write_data2;
		10'b???1?????_1: xout12 = write_data3;
		10'b????1????_1: xout12 = write_data4;
		10'b?????1???_1: xout12 = write_data5;
		10'b??????1??_1: xout12 = write_data6;
		10'b???????1?_1: xout12 = write_data7;
		10'b????????1_1: xout12 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout12 = r_out12;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg13[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg13[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg13[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg13[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg13[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg13[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg13[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg13[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg13[LNCOMMIT-1:0]), r_rd_reg13[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg13[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg13[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg13[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg13[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg13[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg13[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg13[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg13[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg13[LNCOMMIT-1:0]), r_rd_reg13[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout13 = write_data0;
		10'b?1???????_1: xout13 = write_data1;
		10'b??1??????_1: xout13 = write_data2;
		10'b???1?????_1: xout13 = write_data3;
		10'b????1????_1: xout13 = write_data4;
		10'b?????1???_1: xout13 = write_data5;
		10'b??????1??_1: xout13 = write_data6;
		10'b???????1?_1: xout13 = write_data7;
		10'b????????1_1: xout13 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout13 = r_out13;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg14[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg14[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg14[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg14[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg14[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg14[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg14[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg14[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg14[LNCOMMIT-1:0]), r_rd_reg14[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg14[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg14[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg14[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg14[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg14[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg14[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg14[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg14[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg14[LNCOMMIT-1:0]), r_rd_reg14[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout14 = write_data0;
		10'b?1???????_1: xout14 = write_data1;
		10'b??1??????_1: xout14 = write_data2;
		10'b???1?????_1: xout14 = write_data3;
		10'b????1????_1: xout14 = write_data4;
		10'b?????1???_1: xout14 = write_data5;
		10'b??????1??_1: xout14 = write_data6;
		10'b???????1?_1: xout14 = write_data7;
		10'b????????1_1: xout14 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout14 = r_out14;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg15[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg15[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg15[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg15[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg15[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg15[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg15[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg15[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg15[LNCOMMIT-1:0]), r_rd_reg15[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg15[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg15[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg15[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg15[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg15[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg15[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg15[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg15[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg15[LNCOMMIT-1:0]), r_rd_reg15[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout15 = write_data0;
		10'b?1???????_1: xout15 = write_data1;
		10'b??1??????_1: xout15 = write_data2;
		10'b???1?????_1: xout15 = write_data3;
		10'b????1????_1: xout15 = write_data4;
		10'b?????1???_1: xout15 = write_data5;
		10'b??????1??_1: xout15 = write_data6;
		10'b???????1?_1: xout15 = write_data7;
		10'b????????1_1: xout15 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout15 = r_out15;
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({write_enable0&~write_fp0&(write_addr0==r_rd_reg16[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==r_rd_reg16[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==r_rd_reg16[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==r_rd_reg16[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==r_rd_reg16[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==r_rd_reg16[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==r_rd_reg16[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==r_rd_reg16[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==r_rd_reg16[LNCOMMIT-1:0]), r_rd_reg16[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({write_enable0&(write_addr0==r_rd_reg16[LNCOMMIT-1:0]), write_enable1&(write_addr1==r_rd_reg16[LNCOMMIT-1:0]), write_enable2&(write_addr2==r_rd_reg16[LNCOMMIT-1:0]), write_enable3&(write_addr3==r_rd_reg16[LNCOMMIT-1:0]), write_enable4&(write_addr4==r_rd_reg16[LNCOMMIT-1:0]), write_enable5&(write_addr5==r_rd_reg16[LNCOMMIT-1:0]), write_enable6&(write_addr6==r_rd_reg16[LNCOMMIT-1:0]), write_enable7&(write_addr7==r_rd_reg16[LNCOMMIT-1:0]), write_enable8&(write_addr8==r_rd_reg16[LNCOMMIT-1:0]), r_rd_reg16[RA-1]}) // synthesis full_case parallel_case
`endif
		10'b1????????_1: xout16 = write_data0;
		10'b?1???????_1: xout16 = write_data1;
		10'b??1??????_1: xout16 = write_data2;
		10'b???1?????_1: xout16 = write_data3;
		10'b????1????_1: xout16 = write_data4;
		10'b?????1???_1: xout16 = write_data5;
		10'b??????1??_1: xout16 = write_data6;
		10'b???????1?_1: xout16 = write_data7;
		10'b????????1_1: xout16 = write_data8;
		10'b000000000_1,
		10'b?????????_0: xout16 = r_out16;
		endcase
	end
`ifdef FP
	always @(*) begin
		casez ({write_enable0&write_fp0&(write_addr0==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==r_rd_fpu_reg0[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==r_rd_fpu_reg0[LNCOMMIT-1:0]), r_rd_fpu_reg0[RA-1]}) // synthesis full_case parallel_case
		10'b1????????_1: x_fpu_out0 = write_data0;
		10'b?1???????_1: x_fpu_out0 = write_data1;
		10'b??1??????_1: x_fpu_out0 = write_data2;
		10'b???1?????_1: x_fpu_out0 = write_data3;
		10'b????1????_1: x_fpu_out0 = write_data4;
		10'b?????1???_1: x_fpu_out0 = write_data5;
		10'b??????1??_1: x_fpu_out0 = write_data6;
		10'b???????1?_1: x_fpu_out0 = write_data7;
		10'b????????1_1: x_fpu_out0 = write_data8;
		10'b000000000_1,
		10'b?????????_0: x_fpu_out0 = r_fpu_out0;
		endcase
	end
	always @(*) begin
		casez ({write_enable0&write_fp0&(write_addr0==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==r_rd_fpu_reg1[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==r_rd_fpu_reg1[LNCOMMIT-1:0]), r_rd_fpu_reg1[RA-1]}) // synthesis full_case parallel_case
		10'b1????????_1: x_fpu_out1 = write_data0;
		10'b?1???????_1: x_fpu_out1 = write_data1;
		10'b??1??????_1: x_fpu_out1 = write_data2;
		10'b???1?????_1: x_fpu_out1 = write_data3;
		10'b????1????_1: x_fpu_out1 = write_data4;
		10'b?????1???_1: x_fpu_out1 = write_data5;
		10'b??????1??_1: x_fpu_out1 = write_data6;
		10'b???????1?_1: x_fpu_out1 = write_data7;
		10'b????????1_1: x_fpu_out1 = write_data8;
		10'b000000000_1,
		10'b?????????_0: x_fpu_out1 = r_fpu_out1;
		endcase
	end
	always @(*) begin
		casez ({write_enable0&write_fp0&(write_addr0==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==r_rd_fpu_reg2[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==r_rd_fpu_reg2[LNCOMMIT-1:0]), r_rd_fpu_reg2[RA-1]}) // synthesis full_case parallel_case
		10'b1????????_1: x_fpu_out2 = write_data0;
		10'b?1???????_1: x_fpu_out2 = write_data1;
		10'b??1??????_1: x_fpu_out2 = write_data2;
		10'b???1?????_1: x_fpu_out2 = write_data3;
		10'b????1????_1: x_fpu_out2 = write_data4;
		10'b?????1???_1: x_fpu_out2 = write_data5;
		10'b??????1??_1: x_fpu_out2 = write_data6;
		10'b???????1?_1: x_fpu_out2 = write_data7;
		10'b????????1_1: x_fpu_out2 = write_data8;
		10'b000000000_1,
		10'b?????????_0: x_fpu_out2 = r_fpu_out2;
		endcase
	end
	always @(*) begin
		casez ({write_enable0&write_fp0&(write_addr0==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==r_rd_fpu_reg3[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==r_rd_fpu_reg3[LNCOMMIT-1:0]), r_rd_fpu_reg3[RA-1]}) // synthesis full_case parallel_case
		10'b1????????_1: x_fpu_out3 = write_data0;
		10'b?1???????_1: x_fpu_out3 = write_data1;
		10'b??1??????_1: x_fpu_out3 = write_data2;
		10'b???1?????_1: x_fpu_out3 = write_data3;
		10'b????1????_1: x_fpu_out3 = write_data4;
		10'b?????1???_1: x_fpu_out3 = write_data5;
		10'b??????1??_1: x_fpu_out3 = write_data6;
		10'b???????1?_1: x_fpu_out3 = write_data7;
		10'b????????1_1: x_fpu_out3 = write_data8;
		10'b000000000_1,
		10'b?????????_0: x_fpu_out3 = r_fpu_out3;
		endcase
	end
`endif
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr0[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr0[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr0[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr0[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr0[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr0[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr0[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr0[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr0[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr0[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr0[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr0[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr0[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr0[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr0[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr0[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr0[LNCOMMIT-1:0]), read_enable0, read_addr0[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr0[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr0[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr0[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr0[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr0[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr0[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr0[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr0[4:0]), write_enable0&(write_addr0==read_addr0[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr0[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr0[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr0[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr0[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr0[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr0[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr0[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr0[LNCOMMIT-1:0]), read_enable0, read_addr0[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out0 = 64'bx;
		19'b1???????_?????????_10: out0 = transfer_reg_0;
		19'b?1??????_?????????_10: out0 = transfer_reg_1;
		19'b??1?????_?????????_10: out0 = transfer_reg_2;
		19'b???1????_?????????_10: out0 = transfer_reg_3;
		19'b????1???_?????????_10: out0 = transfer_reg_4;
		19'b?????1??_?????????_10: out0 = transfer_reg_5;
		19'b??????1?_?????????_10: out0 = transfer_reg_6;
		19'b???????1_?????????_10: out0 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr0[4:0]) // synthesis full_case parallel_case
				0: out0 = 0;
				1: out0 = r_real_reg_1;
				2: out0 = r_real_reg_2;
				3: out0 = r_real_reg_3;
				4: out0 = r_real_reg_4;
				5: out0 = r_real_reg_5;
				6: out0 = r_real_reg_6;
				7: out0 = r_real_reg_7;
				8: out0 = r_real_reg_8;
				9: out0 = r_real_reg_9;
				10: out0 = r_real_reg_10;
				11: out0 = r_real_reg_11;
				12: out0 = r_real_reg_12;
				13: out0 = r_real_reg_13;
				14: out0 = r_real_reg_14;
				15: out0 = r_real_reg_15;
				16: out0 = r_real_reg_16;
				17: out0 = r_real_reg_17;
				18: out0 = r_real_reg_18;
				19: out0 = r_real_reg_19;
				20: out0 = r_real_reg_20;
				21: out0 = r_real_reg_21;
				22: out0 = r_real_reg_22;
				23: out0 = r_real_reg_23;
				24: out0 = r_real_reg_24;
				25: out0 = r_real_reg_25;
				26: out0 = r_real_reg_26;
				27: out0 = r_real_reg_27;
				28: out0 = r_real_reg_28;
				29: out0 = r_real_reg_29;
				30: out0 = r_real_reg_30;
				31: out0 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out0 = (read_addr0[4:0]==0?0:r_real_reg[read_addr0[4:0]]);
`endif
		19'b????????_1????????_11: out0 = write_data0;
		19'b????????_?1???????_11: out0 = write_data1;
		19'b????????_??1??????_11: out0 = write_data2;
		19'b????????_???1?????_11: out0 = write_data3;
		19'b????????_????1????_11: out0 = write_data4;
		19'b????????_?????1???_11: out0 = write_data5;
		19'b????????_??????1??_11: out0 = write_data6;
		19'b????????_???????1?_11: out0 = write_data7;
		19'b????????_????????1_11: out0 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr0[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out0 = r_commit_reg_0;
					1: out0 = r_commit_reg_1;
					2: out0 = r_commit_reg_2;
					3: out0 = r_commit_reg_3;
					4: out0 = r_commit_reg_4;
					5: out0 = r_commit_reg_5;
					6: out0 = r_commit_reg_6;
					7: out0 = r_commit_reg_7;
					8: out0 = r_commit_reg_8;
					9: out0 = r_commit_reg_9;
					10: out0 = r_commit_reg_10;
					11: out0 = r_commit_reg_11;
					12: out0 = r_commit_reg_12;
					13: out0 = r_commit_reg_13;
					14: out0 = r_commit_reg_14;
					15: out0 = r_commit_reg_15;
					16: out0 = r_commit_reg_16;
					17: out0 = r_commit_reg_17;
					18: out0 = r_commit_reg_18;
					19: out0 = r_commit_reg_19;
					20: out0 = r_commit_reg_20;
					21: out0 = r_commit_reg_21;
					22: out0 = r_commit_reg_22;
					23: out0 = r_commit_reg_23;
					24: out0 = r_commit_reg_24;
					25: out0 = r_commit_reg_25;
					26: out0 = r_commit_reg_26;
					27: out0 = r_commit_reg_27;
					28: out0 = r_commit_reg_28;
					29: out0 = r_commit_reg_29;
					30: out0 = r_commit_reg_30;
					31: out0 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out0 = r_commit_reg[read_addr0[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr1[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr1[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr1[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr1[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr1[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr1[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr1[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr1[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr1[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr1[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr1[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr1[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr1[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr1[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr1[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr1[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr1[LNCOMMIT-1:0]), read_enable1, read_addr1[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr1[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr1[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr1[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr1[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr1[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr1[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr1[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr1[4:0]), write_enable0&(write_addr0==read_addr1[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr1[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr1[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr1[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr1[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr1[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr1[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr1[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr1[LNCOMMIT-1:0]), read_enable1, read_addr1[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out1 = 64'bx;
		19'b1???????_?????????_10: out1 = transfer_reg_0;
		19'b?1??????_?????????_10: out1 = transfer_reg_1;
		19'b??1?????_?????????_10: out1 = transfer_reg_2;
		19'b???1????_?????????_10: out1 = transfer_reg_3;
		19'b????1???_?????????_10: out1 = transfer_reg_4;
		19'b?????1??_?????????_10: out1 = transfer_reg_5;
		19'b??????1?_?????????_10: out1 = transfer_reg_6;
		19'b???????1_?????????_10: out1 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr1[4:0]) // synthesis full_case parallel_case
				0: out1 = 0;
				1: out1 = r_real_reg_1;
				2: out1 = r_real_reg_2;
				3: out1 = r_real_reg_3;
				4: out1 = r_real_reg_4;
				5: out1 = r_real_reg_5;
				6: out1 = r_real_reg_6;
				7: out1 = r_real_reg_7;
				8: out1 = r_real_reg_8;
				9: out1 = r_real_reg_9;
				10: out1 = r_real_reg_10;
				11: out1 = r_real_reg_11;
				12: out1 = r_real_reg_12;
				13: out1 = r_real_reg_13;
				14: out1 = r_real_reg_14;
				15: out1 = r_real_reg_15;
				16: out1 = r_real_reg_16;
				17: out1 = r_real_reg_17;
				18: out1 = r_real_reg_18;
				19: out1 = r_real_reg_19;
				20: out1 = r_real_reg_20;
				21: out1 = r_real_reg_21;
				22: out1 = r_real_reg_22;
				23: out1 = r_real_reg_23;
				24: out1 = r_real_reg_24;
				25: out1 = r_real_reg_25;
				26: out1 = r_real_reg_26;
				27: out1 = r_real_reg_27;
				28: out1 = r_real_reg_28;
				29: out1 = r_real_reg_29;
				30: out1 = r_real_reg_30;
				31: out1 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out1 = (read_addr1[4:0]==0?0:r_real_reg[read_addr1[4:0]]);
`endif
		19'b????????_1????????_11: out1 = write_data0;
		19'b????????_?1???????_11: out1 = write_data1;
		19'b????????_??1??????_11: out1 = write_data2;
		19'b????????_???1?????_11: out1 = write_data3;
		19'b????????_????1????_11: out1 = write_data4;
		19'b????????_?????1???_11: out1 = write_data5;
		19'b????????_??????1??_11: out1 = write_data6;
		19'b????????_???????1?_11: out1 = write_data7;
		19'b????????_????????1_11: out1 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr1[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out1 = r_commit_reg_0;
					1: out1 = r_commit_reg_1;
					2: out1 = r_commit_reg_2;
					3: out1 = r_commit_reg_3;
					4: out1 = r_commit_reg_4;
					5: out1 = r_commit_reg_5;
					6: out1 = r_commit_reg_6;
					7: out1 = r_commit_reg_7;
					8: out1 = r_commit_reg_8;
					9: out1 = r_commit_reg_9;
					10: out1 = r_commit_reg_10;
					11: out1 = r_commit_reg_11;
					12: out1 = r_commit_reg_12;
					13: out1 = r_commit_reg_13;
					14: out1 = r_commit_reg_14;
					15: out1 = r_commit_reg_15;
					16: out1 = r_commit_reg_16;
					17: out1 = r_commit_reg_17;
					18: out1 = r_commit_reg_18;
					19: out1 = r_commit_reg_19;
					20: out1 = r_commit_reg_20;
					21: out1 = r_commit_reg_21;
					22: out1 = r_commit_reg_22;
					23: out1 = r_commit_reg_23;
					24: out1 = r_commit_reg_24;
					25: out1 = r_commit_reg_25;
					26: out1 = r_commit_reg_26;
					27: out1 = r_commit_reg_27;
					28: out1 = r_commit_reg_28;
					29: out1 = r_commit_reg_29;
					30: out1 = r_commit_reg_30;
					31: out1 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out1 = r_commit_reg[read_addr1[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr2[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr2[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr2[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr2[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr2[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr2[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr2[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr2[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr2[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr2[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr2[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr2[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr2[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr2[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr2[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr2[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr2[LNCOMMIT-1:0]), read_enable2, read_addr2[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr2[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr2[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr2[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr2[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr2[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr2[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr2[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr2[4:0]), write_enable0&(write_addr0==read_addr2[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr2[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr2[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr2[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr2[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr2[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr2[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr2[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr2[LNCOMMIT-1:0]), read_enable2, read_addr2[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out2 = 64'bx;
		19'b1???????_?????????_10: out2 = transfer_reg_0;
		19'b?1??????_?????????_10: out2 = transfer_reg_1;
		19'b??1?????_?????????_10: out2 = transfer_reg_2;
		19'b???1????_?????????_10: out2 = transfer_reg_3;
		19'b????1???_?????????_10: out2 = transfer_reg_4;
		19'b?????1??_?????????_10: out2 = transfer_reg_5;
		19'b??????1?_?????????_10: out2 = transfer_reg_6;
		19'b???????1_?????????_10: out2 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr2[4:0]) // synthesis full_case parallel_case
				0: out2 = 0;
				1: out2 = r_real_reg_1;
				2: out2 = r_real_reg_2;
				3: out2 = r_real_reg_3;
				4: out2 = r_real_reg_4;
				5: out2 = r_real_reg_5;
				6: out2 = r_real_reg_6;
				7: out2 = r_real_reg_7;
				8: out2 = r_real_reg_8;
				9: out2 = r_real_reg_9;
				10: out2 = r_real_reg_10;
				11: out2 = r_real_reg_11;
				12: out2 = r_real_reg_12;
				13: out2 = r_real_reg_13;
				14: out2 = r_real_reg_14;
				15: out2 = r_real_reg_15;
				16: out2 = r_real_reg_16;
				17: out2 = r_real_reg_17;
				18: out2 = r_real_reg_18;
				19: out2 = r_real_reg_19;
				20: out2 = r_real_reg_20;
				21: out2 = r_real_reg_21;
				22: out2 = r_real_reg_22;
				23: out2 = r_real_reg_23;
				24: out2 = r_real_reg_24;
				25: out2 = r_real_reg_25;
				26: out2 = r_real_reg_26;
				27: out2 = r_real_reg_27;
				28: out2 = r_real_reg_28;
				29: out2 = r_real_reg_29;
				30: out2 = r_real_reg_30;
				31: out2 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out2 = (read_addr2[4:0]==0?0:r_real_reg[read_addr2[4:0]]);
`endif
		19'b????????_1????????_11: out2 = write_data0;
		19'b????????_?1???????_11: out2 = write_data1;
		19'b????????_??1??????_11: out2 = write_data2;
		19'b????????_???1?????_11: out2 = write_data3;
		19'b????????_????1????_11: out2 = write_data4;
		19'b????????_?????1???_11: out2 = write_data5;
		19'b????????_??????1??_11: out2 = write_data6;
		19'b????????_???????1?_11: out2 = write_data7;
		19'b????????_????????1_11: out2 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr2[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out2 = r_commit_reg_0;
					1: out2 = r_commit_reg_1;
					2: out2 = r_commit_reg_2;
					3: out2 = r_commit_reg_3;
					4: out2 = r_commit_reg_4;
					5: out2 = r_commit_reg_5;
					6: out2 = r_commit_reg_6;
					7: out2 = r_commit_reg_7;
					8: out2 = r_commit_reg_8;
					9: out2 = r_commit_reg_9;
					10: out2 = r_commit_reg_10;
					11: out2 = r_commit_reg_11;
					12: out2 = r_commit_reg_12;
					13: out2 = r_commit_reg_13;
					14: out2 = r_commit_reg_14;
					15: out2 = r_commit_reg_15;
					16: out2 = r_commit_reg_16;
					17: out2 = r_commit_reg_17;
					18: out2 = r_commit_reg_18;
					19: out2 = r_commit_reg_19;
					20: out2 = r_commit_reg_20;
					21: out2 = r_commit_reg_21;
					22: out2 = r_commit_reg_22;
					23: out2 = r_commit_reg_23;
					24: out2 = r_commit_reg_24;
					25: out2 = r_commit_reg_25;
					26: out2 = r_commit_reg_26;
					27: out2 = r_commit_reg_27;
					28: out2 = r_commit_reg_28;
					29: out2 = r_commit_reg_29;
					30: out2 = r_commit_reg_30;
					31: out2 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out2 = r_commit_reg[read_addr2[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr3[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr3[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr3[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr3[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr3[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr3[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr3[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr3[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr3[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr3[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr3[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr3[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr3[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr3[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr3[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr3[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr3[LNCOMMIT-1:0]), read_enable3, read_addr3[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr3[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr3[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr3[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr3[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr3[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr3[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr3[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr3[4:0]), write_enable0&(write_addr0==read_addr3[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr3[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr3[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr3[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr3[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr3[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr3[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr3[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr3[LNCOMMIT-1:0]), read_enable3, read_addr3[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out3 = 64'bx;
		19'b1???????_?????????_10: out3 = transfer_reg_0;
		19'b?1??????_?????????_10: out3 = transfer_reg_1;
		19'b??1?????_?????????_10: out3 = transfer_reg_2;
		19'b???1????_?????????_10: out3 = transfer_reg_3;
		19'b????1???_?????????_10: out3 = transfer_reg_4;
		19'b?????1??_?????????_10: out3 = transfer_reg_5;
		19'b??????1?_?????????_10: out3 = transfer_reg_6;
		19'b???????1_?????????_10: out3 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr3[4:0]) // synthesis full_case parallel_case
				0: out3 = 0;
				1: out3 = r_real_reg_1;
				2: out3 = r_real_reg_2;
				3: out3 = r_real_reg_3;
				4: out3 = r_real_reg_4;
				5: out3 = r_real_reg_5;
				6: out3 = r_real_reg_6;
				7: out3 = r_real_reg_7;
				8: out3 = r_real_reg_8;
				9: out3 = r_real_reg_9;
				10: out3 = r_real_reg_10;
				11: out3 = r_real_reg_11;
				12: out3 = r_real_reg_12;
				13: out3 = r_real_reg_13;
				14: out3 = r_real_reg_14;
				15: out3 = r_real_reg_15;
				16: out3 = r_real_reg_16;
				17: out3 = r_real_reg_17;
				18: out3 = r_real_reg_18;
				19: out3 = r_real_reg_19;
				20: out3 = r_real_reg_20;
				21: out3 = r_real_reg_21;
				22: out3 = r_real_reg_22;
				23: out3 = r_real_reg_23;
				24: out3 = r_real_reg_24;
				25: out3 = r_real_reg_25;
				26: out3 = r_real_reg_26;
				27: out3 = r_real_reg_27;
				28: out3 = r_real_reg_28;
				29: out3 = r_real_reg_29;
				30: out3 = r_real_reg_30;
				31: out3 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out3 = (read_addr3[4:0]==0?0:r_real_reg[read_addr3[4:0]]);
`endif
		19'b????????_1????????_11: out3 = write_data0;
		19'b????????_?1???????_11: out3 = write_data1;
		19'b????????_??1??????_11: out3 = write_data2;
		19'b????????_???1?????_11: out3 = write_data3;
		19'b????????_????1????_11: out3 = write_data4;
		19'b????????_?????1???_11: out3 = write_data5;
		19'b????????_??????1??_11: out3 = write_data6;
		19'b????????_???????1?_11: out3 = write_data7;
		19'b????????_????????1_11: out3 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr3[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out3 = r_commit_reg_0;
					1: out3 = r_commit_reg_1;
					2: out3 = r_commit_reg_2;
					3: out3 = r_commit_reg_3;
					4: out3 = r_commit_reg_4;
					5: out3 = r_commit_reg_5;
					6: out3 = r_commit_reg_6;
					7: out3 = r_commit_reg_7;
					8: out3 = r_commit_reg_8;
					9: out3 = r_commit_reg_9;
					10: out3 = r_commit_reg_10;
					11: out3 = r_commit_reg_11;
					12: out3 = r_commit_reg_12;
					13: out3 = r_commit_reg_13;
					14: out3 = r_commit_reg_14;
					15: out3 = r_commit_reg_15;
					16: out3 = r_commit_reg_16;
					17: out3 = r_commit_reg_17;
					18: out3 = r_commit_reg_18;
					19: out3 = r_commit_reg_19;
					20: out3 = r_commit_reg_20;
					21: out3 = r_commit_reg_21;
					22: out3 = r_commit_reg_22;
					23: out3 = r_commit_reg_23;
					24: out3 = r_commit_reg_24;
					25: out3 = r_commit_reg_25;
					26: out3 = r_commit_reg_26;
					27: out3 = r_commit_reg_27;
					28: out3 = r_commit_reg_28;
					29: out3 = r_commit_reg_29;
					30: out3 = r_commit_reg_30;
					31: out3 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out3 = r_commit_reg[read_addr3[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr4[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr4[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr4[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr4[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr4[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr4[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr4[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr4[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr4[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr4[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr4[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr4[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr4[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr4[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr4[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr4[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr4[LNCOMMIT-1:0]), read_enable4, read_addr4[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr4[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr4[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr4[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr4[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr4[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr4[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr4[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr4[4:0]), write_enable0&(write_addr0==read_addr4[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr4[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr4[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr4[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr4[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr4[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr4[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr4[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr4[LNCOMMIT-1:0]), read_enable4, read_addr4[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out4 = 64'bx;
		19'b1???????_?????????_10: out4 = transfer_reg_0;
		19'b?1??????_?????????_10: out4 = transfer_reg_1;
		19'b??1?????_?????????_10: out4 = transfer_reg_2;
		19'b???1????_?????????_10: out4 = transfer_reg_3;
		19'b????1???_?????????_10: out4 = transfer_reg_4;
		19'b?????1??_?????????_10: out4 = transfer_reg_5;
		19'b??????1?_?????????_10: out4 = transfer_reg_6;
		19'b???????1_?????????_10: out4 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr4[4:0]) // synthesis full_case parallel_case
				0: out4 = 0;
				1: out4 = r_real_reg_1;
				2: out4 = r_real_reg_2;
				3: out4 = r_real_reg_3;
				4: out4 = r_real_reg_4;
				5: out4 = r_real_reg_5;
				6: out4 = r_real_reg_6;
				7: out4 = r_real_reg_7;
				8: out4 = r_real_reg_8;
				9: out4 = r_real_reg_9;
				10: out4 = r_real_reg_10;
				11: out4 = r_real_reg_11;
				12: out4 = r_real_reg_12;
				13: out4 = r_real_reg_13;
				14: out4 = r_real_reg_14;
				15: out4 = r_real_reg_15;
				16: out4 = r_real_reg_16;
				17: out4 = r_real_reg_17;
				18: out4 = r_real_reg_18;
				19: out4 = r_real_reg_19;
				20: out4 = r_real_reg_20;
				21: out4 = r_real_reg_21;
				22: out4 = r_real_reg_22;
				23: out4 = r_real_reg_23;
				24: out4 = r_real_reg_24;
				25: out4 = r_real_reg_25;
				26: out4 = r_real_reg_26;
				27: out4 = r_real_reg_27;
				28: out4 = r_real_reg_28;
				29: out4 = r_real_reg_29;
				30: out4 = r_real_reg_30;
				31: out4 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out4 = (read_addr4[4:0]==0?0:r_real_reg[read_addr4[4:0]]);
`endif
		19'b????????_1????????_11: out4 = write_data0;
		19'b????????_?1???????_11: out4 = write_data1;
		19'b????????_??1??????_11: out4 = write_data2;
		19'b????????_???1?????_11: out4 = write_data3;
		19'b????????_????1????_11: out4 = write_data4;
		19'b????????_?????1???_11: out4 = write_data5;
		19'b????????_??????1??_11: out4 = write_data6;
		19'b????????_???????1?_11: out4 = write_data7;
		19'b????????_????????1_11: out4 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr4[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out4 = r_commit_reg_0;
					1: out4 = r_commit_reg_1;
					2: out4 = r_commit_reg_2;
					3: out4 = r_commit_reg_3;
					4: out4 = r_commit_reg_4;
					5: out4 = r_commit_reg_5;
					6: out4 = r_commit_reg_6;
					7: out4 = r_commit_reg_7;
					8: out4 = r_commit_reg_8;
					9: out4 = r_commit_reg_9;
					10: out4 = r_commit_reg_10;
					11: out4 = r_commit_reg_11;
					12: out4 = r_commit_reg_12;
					13: out4 = r_commit_reg_13;
					14: out4 = r_commit_reg_14;
					15: out4 = r_commit_reg_15;
					16: out4 = r_commit_reg_16;
					17: out4 = r_commit_reg_17;
					18: out4 = r_commit_reg_18;
					19: out4 = r_commit_reg_19;
					20: out4 = r_commit_reg_20;
					21: out4 = r_commit_reg_21;
					22: out4 = r_commit_reg_22;
					23: out4 = r_commit_reg_23;
					24: out4 = r_commit_reg_24;
					25: out4 = r_commit_reg_25;
					26: out4 = r_commit_reg_26;
					27: out4 = r_commit_reg_27;
					28: out4 = r_commit_reg_28;
					29: out4 = r_commit_reg_29;
					30: out4 = r_commit_reg_30;
					31: out4 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out4 = r_commit_reg[read_addr4[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr5[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr5[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr5[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr5[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr5[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr5[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr5[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr5[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr5[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr5[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr5[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr5[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr5[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr5[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr5[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr5[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr5[LNCOMMIT-1:0]), read_enable5, read_addr5[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr5[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr5[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr5[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr5[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr5[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr5[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr5[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr5[4:0]), write_enable0&(write_addr0==read_addr5[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr5[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr5[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr5[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr5[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr5[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr5[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr5[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr5[LNCOMMIT-1:0]), read_enable5, read_addr5[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out5 = 64'bx;
		19'b1???????_?????????_10: out5 = transfer_reg_0;
		19'b?1??????_?????????_10: out5 = transfer_reg_1;
		19'b??1?????_?????????_10: out5 = transfer_reg_2;
		19'b???1????_?????????_10: out5 = transfer_reg_3;
		19'b????1???_?????????_10: out5 = transfer_reg_4;
		19'b?????1??_?????????_10: out5 = transfer_reg_5;
		19'b??????1?_?????????_10: out5 = transfer_reg_6;
		19'b???????1_?????????_10: out5 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr5[4:0]) // synthesis full_case parallel_case
				0: out5 = 0;
				1: out5 = r_real_reg_1;
				2: out5 = r_real_reg_2;
				3: out5 = r_real_reg_3;
				4: out5 = r_real_reg_4;
				5: out5 = r_real_reg_5;
				6: out5 = r_real_reg_6;
				7: out5 = r_real_reg_7;
				8: out5 = r_real_reg_8;
				9: out5 = r_real_reg_9;
				10: out5 = r_real_reg_10;
				11: out5 = r_real_reg_11;
				12: out5 = r_real_reg_12;
				13: out5 = r_real_reg_13;
				14: out5 = r_real_reg_14;
				15: out5 = r_real_reg_15;
				16: out5 = r_real_reg_16;
				17: out5 = r_real_reg_17;
				18: out5 = r_real_reg_18;
				19: out5 = r_real_reg_19;
				20: out5 = r_real_reg_20;
				21: out5 = r_real_reg_21;
				22: out5 = r_real_reg_22;
				23: out5 = r_real_reg_23;
				24: out5 = r_real_reg_24;
				25: out5 = r_real_reg_25;
				26: out5 = r_real_reg_26;
				27: out5 = r_real_reg_27;
				28: out5 = r_real_reg_28;
				29: out5 = r_real_reg_29;
				30: out5 = r_real_reg_30;
				31: out5 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out5 = (read_addr5[4:0]==0?0:r_real_reg[read_addr5[4:0]]);
`endif
		19'b????????_1????????_11: out5 = write_data0;
		19'b????????_?1???????_11: out5 = write_data1;
		19'b????????_??1??????_11: out5 = write_data2;
		19'b????????_???1?????_11: out5 = write_data3;
		19'b????????_????1????_11: out5 = write_data4;
		19'b????????_?????1???_11: out5 = write_data5;
		19'b????????_??????1??_11: out5 = write_data6;
		19'b????????_???????1?_11: out5 = write_data7;
		19'b????????_????????1_11: out5 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr5[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out5 = r_commit_reg_0;
					1: out5 = r_commit_reg_1;
					2: out5 = r_commit_reg_2;
					3: out5 = r_commit_reg_3;
					4: out5 = r_commit_reg_4;
					5: out5 = r_commit_reg_5;
					6: out5 = r_commit_reg_6;
					7: out5 = r_commit_reg_7;
					8: out5 = r_commit_reg_8;
					9: out5 = r_commit_reg_9;
					10: out5 = r_commit_reg_10;
					11: out5 = r_commit_reg_11;
					12: out5 = r_commit_reg_12;
					13: out5 = r_commit_reg_13;
					14: out5 = r_commit_reg_14;
					15: out5 = r_commit_reg_15;
					16: out5 = r_commit_reg_16;
					17: out5 = r_commit_reg_17;
					18: out5 = r_commit_reg_18;
					19: out5 = r_commit_reg_19;
					20: out5 = r_commit_reg_20;
					21: out5 = r_commit_reg_21;
					22: out5 = r_commit_reg_22;
					23: out5 = r_commit_reg_23;
					24: out5 = r_commit_reg_24;
					25: out5 = r_commit_reg_25;
					26: out5 = r_commit_reg_26;
					27: out5 = r_commit_reg_27;
					28: out5 = r_commit_reg_28;
					29: out5 = r_commit_reg_29;
					30: out5 = r_commit_reg_30;
					31: out5 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out5 = r_commit_reg[read_addr5[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr6[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr6[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr6[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr6[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr6[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr6[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr6[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr6[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr6[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr6[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr6[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr6[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr6[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr6[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr6[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr6[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr6[LNCOMMIT-1:0]), read_enable6, read_addr6[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr6[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr6[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr6[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr6[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr6[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr6[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr6[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr6[4:0]), write_enable0&(write_addr0==read_addr6[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr6[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr6[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr6[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr6[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr6[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr6[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr6[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr6[LNCOMMIT-1:0]), read_enable6, read_addr6[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out6 = 64'bx;
		19'b1???????_?????????_10: out6 = transfer_reg_0;
		19'b?1??????_?????????_10: out6 = transfer_reg_1;
		19'b??1?????_?????????_10: out6 = transfer_reg_2;
		19'b???1????_?????????_10: out6 = transfer_reg_3;
		19'b????1???_?????????_10: out6 = transfer_reg_4;
		19'b?????1??_?????????_10: out6 = transfer_reg_5;
		19'b??????1?_?????????_10: out6 = transfer_reg_6;
		19'b???????1_?????????_10: out6 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr6[4:0]) // synthesis full_case parallel_case
				0: out6 = 0;
				1: out6 = r_real_reg_1;
				2: out6 = r_real_reg_2;
				3: out6 = r_real_reg_3;
				4: out6 = r_real_reg_4;
				5: out6 = r_real_reg_5;
				6: out6 = r_real_reg_6;
				7: out6 = r_real_reg_7;
				8: out6 = r_real_reg_8;
				9: out6 = r_real_reg_9;
				10: out6 = r_real_reg_10;
				11: out6 = r_real_reg_11;
				12: out6 = r_real_reg_12;
				13: out6 = r_real_reg_13;
				14: out6 = r_real_reg_14;
				15: out6 = r_real_reg_15;
				16: out6 = r_real_reg_16;
				17: out6 = r_real_reg_17;
				18: out6 = r_real_reg_18;
				19: out6 = r_real_reg_19;
				20: out6 = r_real_reg_20;
				21: out6 = r_real_reg_21;
				22: out6 = r_real_reg_22;
				23: out6 = r_real_reg_23;
				24: out6 = r_real_reg_24;
				25: out6 = r_real_reg_25;
				26: out6 = r_real_reg_26;
				27: out6 = r_real_reg_27;
				28: out6 = r_real_reg_28;
				29: out6 = r_real_reg_29;
				30: out6 = r_real_reg_30;
				31: out6 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out6 = (read_addr6[4:0]==0?0:r_real_reg[read_addr6[4:0]]);
`endif
		19'b????????_1????????_11: out6 = write_data0;
		19'b????????_?1???????_11: out6 = write_data1;
		19'b????????_??1??????_11: out6 = write_data2;
		19'b????????_???1?????_11: out6 = write_data3;
		19'b????????_????1????_11: out6 = write_data4;
		19'b????????_?????1???_11: out6 = write_data5;
		19'b????????_??????1??_11: out6 = write_data6;
		19'b????????_???????1?_11: out6 = write_data7;
		19'b????????_????????1_11: out6 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr6[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out6 = r_commit_reg_0;
					1: out6 = r_commit_reg_1;
					2: out6 = r_commit_reg_2;
					3: out6 = r_commit_reg_3;
					4: out6 = r_commit_reg_4;
					5: out6 = r_commit_reg_5;
					6: out6 = r_commit_reg_6;
					7: out6 = r_commit_reg_7;
					8: out6 = r_commit_reg_8;
					9: out6 = r_commit_reg_9;
					10: out6 = r_commit_reg_10;
					11: out6 = r_commit_reg_11;
					12: out6 = r_commit_reg_12;
					13: out6 = r_commit_reg_13;
					14: out6 = r_commit_reg_14;
					15: out6 = r_commit_reg_15;
					16: out6 = r_commit_reg_16;
					17: out6 = r_commit_reg_17;
					18: out6 = r_commit_reg_18;
					19: out6 = r_commit_reg_19;
					20: out6 = r_commit_reg_20;
					21: out6 = r_commit_reg_21;
					22: out6 = r_commit_reg_22;
					23: out6 = r_commit_reg_23;
					24: out6 = r_commit_reg_24;
					25: out6 = r_commit_reg_25;
					26: out6 = r_commit_reg_26;
					27: out6 = r_commit_reg_27;
					28: out6 = r_commit_reg_28;
					29: out6 = r_commit_reg_29;
					30: out6 = r_commit_reg_30;
					31: out6 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out6 = r_commit_reg[read_addr6[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr7[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr7[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr7[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr7[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr7[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr7[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr7[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr7[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr7[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr7[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr7[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr7[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr7[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr7[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr7[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr7[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr7[LNCOMMIT-1:0]), read_enable7, read_addr7[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr7[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr7[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr7[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr7[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr7[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr7[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr7[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr7[4:0]), write_enable0&(write_addr0==read_addr7[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr7[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr7[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr7[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr7[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr7[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr7[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr7[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr7[LNCOMMIT-1:0]), read_enable7, read_addr7[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out7 = 64'bx;
		19'b1???????_?????????_10: out7 = transfer_reg_0;
		19'b?1??????_?????????_10: out7 = transfer_reg_1;
		19'b??1?????_?????????_10: out7 = transfer_reg_2;
		19'b???1????_?????????_10: out7 = transfer_reg_3;
		19'b????1???_?????????_10: out7 = transfer_reg_4;
		19'b?????1??_?????????_10: out7 = transfer_reg_5;
		19'b??????1?_?????????_10: out7 = transfer_reg_6;
		19'b???????1_?????????_10: out7 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr7[4:0]) // synthesis full_case parallel_case
				0: out7 = 0;
				1: out7 = r_real_reg_1;
				2: out7 = r_real_reg_2;
				3: out7 = r_real_reg_3;
				4: out7 = r_real_reg_4;
				5: out7 = r_real_reg_5;
				6: out7 = r_real_reg_6;
				7: out7 = r_real_reg_7;
				8: out7 = r_real_reg_8;
				9: out7 = r_real_reg_9;
				10: out7 = r_real_reg_10;
				11: out7 = r_real_reg_11;
				12: out7 = r_real_reg_12;
				13: out7 = r_real_reg_13;
				14: out7 = r_real_reg_14;
				15: out7 = r_real_reg_15;
				16: out7 = r_real_reg_16;
				17: out7 = r_real_reg_17;
				18: out7 = r_real_reg_18;
				19: out7 = r_real_reg_19;
				20: out7 = r_real_reg_20;
				21: out7 = r_real_reg_21;
				22: out7 = r_real_reg_22;
				23: out7 = r_real_reg_23;
				24: out7 = r_real_reg_24;
				25: out7 = r_real_reg_25;
				26: out7 = r_real_reg_26;
				27: out7 = r_real_reg_27;
				28: out7 = r_real_reg_28;
				29: out7 = r_real_reg_29;
				30: out7 = r_real_reg_30;
				31: out7 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out7 = (read_addr7[4:0]==0?0:r_real_reg[read_addr7[4:0]]);
`endif
		19'b????????_1????????_11: out7 = write_data0;
		19'b????????_?1???????_11: out7 = write_data1;
		19'b????????_??1??????_11: out7 = write_data2;
		19'b????????_???1?????_11: out7 = write_data3;
		19'b????????_????1????_11: out7 = write_data4;
		19'b????????_?????1???_11: out7 = write_data5;
		19'b????????_??????1??_11: out7 = write_data6;
		19'b????????_???????1?_11: out7 = write_data7;
		19'b????????_????????1_11: out7 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr7[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out7 = r_commit_reg_0;
					1: out7 = r_commit_reg_1;
					2: out7 = r_commit_reg_2;
					3: out7 = r_commit_reg_3;
					4: out7 = r_commit_reg_4;
					5: out7 = r_commit_reg_5;
					6: out7 = r_commit_reg_6;
					7: out7 = r_commit_reg_7;
					8: out7 = r_commit_reg_8;
					9: out7 = r_commit_reg_9;
					10: out7 = r_commit_reg_10;
					11: out7 = r_commit_reg_11;
					12: out7 = r_commit_reg_12;
					13: out7 = r_commit_reg_13;
					14: out7 = r_commit_reg_14;
					15: out7 = r_commit_reg_15;
					16: out7 = r_commit_reg_16;
					17: out7 = r_commit_reg_17;
					18: out7 = r_commit_reg_18;
					19: out7 = r_commit_reg_19;
					20: out7 = r_commit_reg_20;
					21: out7 = r_commit_reg_21;
					22: out7 = r_commit_reg_22;
					23: out7 = r_commit_reg_23;
					24: out7 = r_commit_reg_24;
					25: out7 = r_commit_reg_25;
					26: out7 = r_commit_reg_26;
					27: out7 = r_commit_reg_27;
					28: out7 = r_commit_reg_28;
					29: out7 = r_commit_reg_29;
					30: out7 = r_commit_reg_30;
					31: out7 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out7 = r_commit_reg[read_addr7[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr8[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr8[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr8[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr8[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr8[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr8[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr8[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr8[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr8[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr8[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr8[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr8[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr8[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr8[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr8[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr8[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr8[LNCOMMIT-1:0]), read_enable8, read_addr8[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr8[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr8[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr8[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr8[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr8[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr8[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr8[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr8[4:0]), write_enable0&(write_addr0==read_addr8[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr8[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr8[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr8[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr8[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr8[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr8[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr8[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr8[LNCOMMIT-1:0]), read_enable8, read_addr8[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out8 = 64'bx;
		19'b1???????_?????????_10: out8 = transfer_reg_0;
		19'b?1??????_?????????_10: out8 = transfer_reg_1;
		19'b??1?????_?????????_10: out8 = transfer_reg_2;
		19'b???1????_?????????_10: out8 = transfer_reg_3;
		19'b????1???_?????????_10: out8 = transfer_reg_4;
		19'b?????1??_?????????_10: out8 = transfer_reg_5;
		19'b??????1?_?????????_10: out8 = transfer_reg_6;
		19'b???????1_?????????_10: out8 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr8[4:0]) // synthesis full_case parallel_case
				0: out8 = 0;
				1: out8 = r_real_reg_1;
				2: out8 = r_real_reg_2;
				3: out8 = r_real_reg_3;
				4: out8 = r_real_reg_4;
				5: out8 = r_real_reg_5;
				6: out8 = r_real_reg_6;
				7: out8 = r_real_reg_7;
				8: out8 = r_real_reg_8;
				9: out8 = r_real_reg_9;
				10: out8 = r_real_reg_10;
				11: out8 = r_real_reg_11;
				12: out8 = r_real_reg_12;
				13: out8 = r_real_reg_13;
				14: out8 = r_real_reg_14;
				15: out8 = r_real_reg_15;
				16: out8 = r_real_reg_16;
				17: out8 = r_real_reg_17;
				18: out8 = r_real_reg_18;
				19: out8 = r_real_reg_19;
				20: out8 = r_real_reg_20;
				21: out8 = r_real_reg_21;
				22: out8 = r_real_reg_22;
				23: out8 = r_real_reg_23;
				24: out8 = r_real_reg_24;
				25: out8 = r_real_reg_25;
				26: out8 = r_real_reg_26;
				27: out8 = r_real_reg_27;
				28: out8 = r_real_reg_28;
				29: out8 = r_real_reg_29;
				30: out8 = r_real_reg_30;
				31: out8 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out8 = (read_addr8[4:0]==0?0:r_real_reg[read_addr8[4:0]]);
`endif
		19'b????????_1????????_11: out8 = write_data0;
		19'b????????_?1???????_11: out8 = write_data1;
		19'b????????_??1??????_11: out8 = write_data2;
		19'b????????_???1?????_11: out8 = write_data3;
		19'b????????_????1????_11: out8 = write_data4;
		19'b????????_?????1???_11: out8 = write_data5;
		19'b????????_??????1??_11: out8 = write_data6;
		19'b????????_???????1?_11: out8 = write_data7;
		19'b????????_????????1_11: out8 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr8[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out8 = r_commit_reg_0;
					1: out8 = r_commit_reg_1;
					2: out8 = r_commit_reg_2;
					3: out8 = r_commit_reg_3;
					4: out8 = r_commit_reg_4;
					5: out8 = r_commit_reg_5;
					6: out8 = r_commit_reg_6;
					7: out8 = r_commit_reg_7;
					8: out8 = r_commit_reg_8;
					9: out8 = r_commit_reg_9;
					10: out8 = r_commit_reg_10;
					11: out8 = r_commit_reg_11;
					12: out8 = r_commit_reg_12;
					13: out8 = r_commit_reg_13;
					14: out8 = r_commit_reg_14;
					15: out8 = r_commit_reg_15;
					16: out8 = r_commit_reg_16;
					17: out8 = r_commit_reg_17;
					18: out8 = r_commit_reg_18;
					19: out8 = r_commit_reg_19;
					20: out8 = r_commit_reg_20;
					21: out8 = r_commit_reg_21;
					22: out8 = r_commit_reg_22;
					23: out8 = r_commit_reg_23;
					24: out8 = r_commit_reg_24;
					25: out8 = r_commit_reg_25;
					26: out8 = r_commit_reg_26;
					27: out8 = r_commit_reg_27;
					28: out8 = r_commit_reg_28;
					29: out8 = r_commit_reg_29;
					30: out8 = r_commit_reg_30;
					31: out8 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out8 = r_commit_reg[read_addr8[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr9[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr9[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr9[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr9[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr9[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr9[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr9[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr9[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr9[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr9[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr9[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr9[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr9[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr9[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr9[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr9[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr9[LNCOMMIT-1:0]), read_enable9, read_addr9[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr9[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr9[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr9[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr9[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr9[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr9[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr9[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr9[4:0]), write_enable0&(write_addr0==read_addr9[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr9[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr9[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr9[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr9[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr9[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr9[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr9[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr9[LNCOMMIT-1:0]), read_enable9, read_addr9[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out9 = 64'bx;
		19'b1???????_?????????_10: out9 = transfer_reg_0;
		19'b?1??????_?????????_10: out9 = transfer_reg_1;
		19'b??1?????_?????????_10: out9 = transfer_reg_2;
		19'b???1????_?????????_10: out9 = transfer_reg_3;
		19'b????1???_?????????_10: out9 = transfer_reg_4;
		19'b?????1??_?????????_10: out9 = transfer_reg_5;
		19'b??????1?_?????????_10: out9 = transfer_reg_6;
		19'b???????1_?????????_10: out9 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr9[4:0]) // synthesis full_case parallel_case
				0: out9 = 0;
				1: out9 = r_real_reg_1;
				2: out9 = r_real_reg_2;
				3: out9 = r_real_reg_3;
				4: out9 = r_real_reg_4;
				5: out9 = r_real_reg_5;
				6: out9 = r_real_reg_6;
				7: out9 = r_real_reg_7;
				8: out9 = r_real_reg_8;
				9: out9 = r_real_reg_9;
				10: out9 = r_real_reg_10;
				11: out9 = r_real_reg_11;
				12: out9 = r_real_reg_12;
				13: out9 = r_real_reg_13;
				14: out9 = r_real_reg_14;
				15: out9 = r_real_reg_15;
				16: out9 = r_real_reg_16;
				17: out9 = r_real_reg_17;
				18: out9 = r_real_reg_18;
				19: out9 = r_real_reg_19;
				20: out9 = r_real_reg_20;
				21: out9 = r_real_reg_21;
				22: out9 = r_real_reg_22;
				23: out9 = r_real_reg_23;
				24: out9 = r_real_reg_24;
				25: out9 = r_real_reg_25;
				26: out9 = r_real_reg_26;
				27: out9 = r_real_reg_27;
				28: out9 = r_real_reg_28;
				29: out9 = r_real_reg_29;
				30: out9 = r_real_reg_30;
				31: out9 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out9 = (read_addr9[4:0]==0?0:r_real_reg[read_addr9[4:0]]);
`endif
		19'b????????_1????????_11: out9 = write_data0;
		19'b????????_?1???????_11: out9 = write_data1;
		19'b????????_??1??????_11: out9 = write_data2;
		19'b????????_???1?????_11: out9 = write_data3;
		19'b????????_????1????_11: out9 = write_data4;
		19'b????????_?????1???_11: out9 = write_data5;
		19'b????????_??????1??_11: out9 = write_data6;
		19'b????????_???????1?_11: out9 = write_data7;
		19'b????????_????????1_11: out9 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr9[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out9 = r_commit_reg_0;
					1: out9 = r_commit_reg_1;
					2: out9 = r_commit_reg_2;
					3: out9 = r_commit_reg_3;
					4: out9 = r_commit_reg_4;
					5: out9 = r_commit_reg_5;
					6: out9 = r_commit_reg_6;
					7: out9 = r_commit_reg_7;
					8: out9 = r_commit_reg_8;
					9: out9 = r_commit_reg_9;
					10: out9 = r_commit_reg_10;
					11: out9 = r_commit_reg_11;
					12: out9 = r_commit_reg_12;
					13: out9 = r_commit_reg_13;
					14: out9 = r_commit_reg_14;
					15: out9 = r_commit_reg_15;
					16: out9 = r_commit_reg_16;
					17: out9 = r_commit_reg_17;
					18: out9 = r_commit_reg_18;
					19: out9 = r_commit_reg_19;
					20: out9 = r_commit_reg_20;
					21: out9 = r_commit_reg_21;
					22: out9 = r_commit_reg_22;
					23: out9 = r_commit_reg_23;
					24: out9 = r_commit_reg_24;
					25: out9 = r_commit_reg_25;
					26: out9 = r_commit_reg_26;
					27: out9 = r_commit_reg_27;
					28: out9 = r_commit_reg_28;
					29: out9 = r_commit_reg_29;
					30: out9 = r_commit_reg_30;
					31: out9 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out9 = r_commit_reg[read_addr9[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr10[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr10[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr10[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr10[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr10[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr10[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr10[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr10[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr10[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr10[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr10[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr10[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr10[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr10[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr10[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr10[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr10[LNCOMMIT-1:0]), read_enable10, read_addr10[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr10[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr10[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr10[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr10[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr10[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr10[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr10[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr10[4:0]), write_enable0&(write_addr0==read_addr10[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr10[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr10[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr10[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr10[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr10[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr10[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr10[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr10[LNCOMMIT-1:0]), read_enable10, read_addr10[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out10 = 64'bx;
		19'b1???????_?????????_10: out10 = transfer_reg_0;
		19'b?1??????_?????????_10: out10 = transfer_reg_1;
		19'b??1?????_?????????_10: out10 = transfer_reg_2;
		19'b???1????_?????????_10: out10 = transfer_reg_3;
		19'b????1???_?????????_10: out10 = transfer_reg_4;
		19'b?????1??_?????????_10: out10 = transfer_reg_5;
		19'b??????1?_?????????_10: out10 = transfer_reg_6;
		19'b???????1_?????????_10: out10 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr10[4:0]) // synthesis full_case parallel_case
				0: out10 = 0;
				1: out10 = r_real_reg_1;
				2: out10 = r_real_reg_2;
				3: out10 = r_real_reg_3;
				4: out10 = r_real_reg_4;
				5: out10 = r_real_reg_5;
				6: out10 = r_real_reg_6;
				7: out10 = r_real_reg_7;
				8: out10 = r_real_reg_8;
				9: out10 = r_real_reg_9;
				10: out10 = r_real_reg_10;
				11: out10 = r_real_reg_11;
				12: out10 = r_real_reg_12;
				13: out10 = r_real_reg_13;
				14: out10 = r_real_reg_14;
				15: out10 = r_real_reg_15;
				16: out10 = r_real_reg_16;
				17: out10 = r_real_reg_17;
				18: out10 = r_real_reg_18;
				19: out10 = r_real_reg_19;
				20: out10 = r_real_reg_20;
				21: out10 = r_real_reg_21;
				22: out10 = r_real_reg_22;
				23: out10 = r_real_reg_23;
				24: out10 = r_real_reg_24;
				25: out10 = r_real_reg_25;
				26: out10 = r_real_reg_26;
				27: out10 = r_real_reg_27;
				28: out10 = r_real_reg_28;
				29: out10 = r_real_reg_29;
				30: out10 = r_real_reg_30;
				31: out10 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out10 = (read_addr10[4:0]==0?0:r_real_reg[read_addr10[4:0]]);
`endif
		19'b????????_1????????_11: out10 = write_data0;
		19'b????????_?1???????_11: out10 = write_data1;
		19'b????????_??1??????_11: out10 = write_data2;
		19'b????????_???1?????_11: out10 = write_data3;
		19'b????????_????1????_11: out10 = write_data4;
		19'b????????_?????1???_11: out10 = write_data5;
		19'b????????_??????1??_11: out10 = write_data6;
		19'b????????_???????1?_11: out10 = write_data7;
		19'b????????_????????1_11: out10 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr10[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out10 = r_commit_reg_0;
					1: out10 = r_commit_reg_1;
					2: out10 = r_commit_reg_2;
					3: out10 = r_commit_reg_3;
					4: out10 = r_commit_reg_4;
					5: out10 = r_commit_reg_5;
					6: out10 = r_commit_reg_6;
					7: out10 = r_commit_reg_7;
					8: out10 = r_commit_reg_8;
					9: out10 = r_commit_reg_9;
					10: out10 = r_commit_reg_10;
					11: out10 = r_commit_reg_11;
					12: out10 = r_commit_reg_12;
					13: out10 = r_commit_reg_13;
					14: out10 = r_commit_reg_14;
					15: out10 = r_commit_reg_15;
					16: out10 = r_commit_reg_16;
					17: out10 = r_commit_reg_17;
					18: out10 = r_commit_reg_18;
					19: out10 = r_commit_reg_19;
					20: out10 = r_commit_reg_20;
					21: out10 = r_commit_reg_21;
					22: out10 = r_commit_reg_22;
					23: out10 = r_commit_reg_23;
					24: out10 = r_commit_reg_24;
					25: out10 = r_commit_reg_25;
					26: out10 = r_commit_reg_26;
					27: out10 = r_commit_reg_27;
					28: out10 = r_commit_reg_28;
					29: out10 = r_commit_reg_29;
					30: out10 = r_commit_reg_30;
					31: out10 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out10 = r_commit_reg[read_addr10[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr11[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr11[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr11[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr11[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr11[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr11[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr11[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr11[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr11[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr11[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr11[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr11[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr11[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr11[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr11[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr11[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr11[LNCOMMIT-1:0]), read_enable11, read_addr11[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr11[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr11[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr11[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr11[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr11[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr11[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr11[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr11[4:0]), write_enable0&(write_addr0==read_addr11[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr11[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr11[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr11[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr11[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr11[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr11[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr11[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr11[LNCOMMIT-1:0]), read_enable11, read_addr11[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out11 = 64'bx;
		19'b1???????_?????????_10: out11 = transfer_reg_0;
		19'b?1??????_?????????_10: out11 = transfer_reg_1;
		19'b??1?????_?????????_10: out11 = transfer_reg_2;
		19'b???1????_?????????_10: out11 = transfer_reg_3;
		19'b????1???_?????????_10: out11 = transfer_reg_4;
		19'b?????1??_?????????_10: out11 = transfer_reg_5;
		19'b??????1?_?????????_10: out11 = transfer_reg_6;
		19'b???????1_?????????_10: out11 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr11[4:0]) // synthesis full_case parallel_case
				0: out11 = 0;
				1: out11 = r_real_reg_1;
				2: out11 = r_real_reg_2;
				3: out11 = r_real_reg_3;
				4: out11 = r_real_reg_4;
				5: out11 = r_real_reg_5;
				6: out11 = r_real_reg_6;
				7: out11 = r_real_reg_7;
				8: out11 = r_real_reg_8;
				9: out11 = r_real_reg_9;
				10: out11 = r_real_reg_10;
				11: out11 = r_real_reg_11;
				12: out11 = r_real_reg_12;
				13: out11 = r_real_reg_13;
				14: out11 = r_real_reg_14;
				15: out11 = r_real_reg_15;
				16: out11 = r_real_reg_16;
				17: out11 = r_real_reg_17;
				18: out11 = r_real_reg_18;
				19: out11 = r_real_reg_19;
				20: out11 = r_real_reg_20;
				21: out11 = r_real_reg_21;
				22: out11 = r_real_reg_22;
				23: out11 = r_real_reg_23;
				24: out11 = r_real_reg_24;
				25: out11 = r_real_reg_25;
				26: out11 = r_real_reg_26;
				27: out11 = r_real_reg_27;
				28: out11 = r_real_reg_28;
				29: out11 = r_real_reg_29;
				30: out11 = r_real_reg_30;
				31: out11 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out11 = (read_addr11[4:0]==0?0:r_real_reg[read_addr11[4:0]]);
`endif
		19'b????????_1????????_11: out11 = write_data0;
		19'b????????_?1???????_11: out11 = write_data1;
		19'b????????_??1??????_11: out11 = write_data2;
		19'b????????_???1?????_11: out11 = write_data3;
		19'b????????_????1????_11: out11 = write_data4;
		19'b????????_?????1???_11: out11 = write_data5;
		19'b????????_??????1??_11: out11 = write_data6;
		19'b????????_???????1?_11: out11 = write_data7;
		19'b????????_????????1_11: out11 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr11[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out11 = r_commit_reg_0;
					1: out11 = r_commit_reg_1;
					2: out11 = r_commit_reg_2;
					3: out11 = r_commit_reg_3;
					4: out11 = r_commit_reg_4;
					5: out11 = r_commit_reg_5;
					6: out11 = r_commit_reg_6;
					7: out11 = r_commit_reg_7;
					8: out11 = r_commit_reg_8;
					9: out11 = r_commit_reg_9;
					10: out11 = r_commit_reg_10;
					11: out11 = r_commit_reg_11;
					12: out11 = r_commit_reg_12;
					13: out11 = r_commit_reg_13;
					14: out11 = r_commit_reg_14;
					15: out11 = r_commit_reg_15;
					16: out11 = r_commit_reg_16;
					17: out11 = r_commit_reg_17;
					18: out11 = r_commit_reg_18;
					19: out11 = r_commit_reg_19;
					20: out11 = r_commit_reg_20;
					21: out11 = r_commit_reg_21;
					22: out11 = r_commit_reg_22;
					23: out11 = r_commit_reg_23;
					24: out11 = r_commit_reg_24;
					25: out11 = r_commit_reg_25;
					26: out11 = r_commit_reg_26;
					27: out11 = r_commit_reg_27;
					28: out11 = r_commit_reg_28;
					29: out11 = r_commit_reg_29;
					30: out11 = r_commit_reg_30;
					31: out11 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out11 = r_commit_reg[read_addr11[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr12[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr12[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr12[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr12[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr12[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr12[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr12[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr12[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr12[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr12[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr12[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr12[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr12[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr12[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr12[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr12[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr12[LNCOMMIT-1:0]), read_enable12, read_addr12[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr12[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr12[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr12[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr12[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr12[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr12[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr12[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr12[4:0]), write_enable0&(write_addr0==read_addr12[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr12[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr12[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr12[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr12[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr12[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr12[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr12[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr12[LNCOMMIT-1:0]), read_enable12, read_addr12[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out12 = 64'bx;
		19'b1???????_?????????_10: out12 = transfer_reg_0;
		19'b?1??????_?????????_10: out12 = transfer_reg_1;
		19'b??1?????_?????????_10: out12 = transfer_reg_2;
		19'b???1????_?????????_10: out12 = transfer_reg_3;
		19'b????1???_?????????_10: out12 = transfer_reg_4;
		19'b?????1??_?????????_10: out12 = transfer_reg_5;
		19'b??????1?_?????????_10: out12 = transfer_reg_6;
		19'b???????1_?????????_10: out12 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr12[4:0]) // synthesis full_case parallel_case
				0: out12 = 0;
				1: out12 = r_real_reg_1;
				2: out12 = r_real_reg_2;
				3: out12 = r_real_reg_3;
				4: out12 = r_real_reg_4;
				5: out12 = r_real_reg_5;
				6: out12 = r_real_reg_6;
				7: out12 = r_real_reg_7;
				8: out12 = r_real_reg_8;
				9: out12 = r_real_reg_9;
				10: out12 = r_real_reg_10;
				11: out12 = r_real_reg_11;
				12: out12 = r_real_reg_12;
				13: out12 = r_real_reg_13;
				14: out12 = r_real_reg_14;
				15: out12 = r_real_reg_15;
				16: out12 = r_real_reg_16;
				17: out12 = r_real_reg_17;
				18: out12 = r_real_reg_18;
				19: out12 = r_real_reg_19;
				20: out12 = r_real_reg_20;
				21: out12 = r_real_reg_21;
				22: out12 = r_real_reg_22;
				23: out12 = r_real_reg_23;
				24: out12 = r_real_reg_24;
				25: out12 = r_real_reg_25;
				26: out12 = r_real_reg_26;
				27: out12 = r_real_reg_27;
				28: out12 = r_real_reg_28;
				29: out12 = r_real_reg_29;
				30: out12 = r_real_reg_30;
				31: out12 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out12 = (read_addr12[4:0]==0?0:r_real_reg[read_addr12[4:0]]);
`endif
		19'b????????_1????????_11: out12 = write_data0;
		19'b????????_?1???????_11: out12 = write_data1;
		19'b????????_??1??????_11: out12 = write_data2;
		19'b????????_???1?????_11: out12 = write_data3;
		19'b????????_????1????_11: out12 = write_data4;
		19'b????????_?????1???_11: out12 = write_data5;
		19'b????????_??????1??_11: out12 = write_data6;
		19'b????????_???????1?_11: out12 = write_data7;
		19'b????????_????????1_11: out12 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr12[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out12 = r_commit_reg_0;
					1: out12 = r_commit_reg_1;
					2: out12 = r_commit_reg_2;
					3: out12 = r_commit_reg_3;
					4: out12 = r_commit_reg_4;
					5: out12 = r_commit_reg_5;
					6: out12 = r_commit_reg_6;
					7: out12 = r_commit_reg_7;
					8: out12 = r_commit_reg_8;
					9: out12 = r_commit_reg_9;
					10: out12 = r_commit_reg_10;
					11: out12 = r_commit_reg_11;
					12: out12 = r_commit_reg_12;
					13: out12 = r_commit_reg_13;
					14: out12 = r_commit_reg_14;
					15: out12 = r_commit_reg_15;
					16: out12 = r_commit_reg_16;
					17: out12 = r_commit_reg_17;
					18: out12 = r_commit_reg_18;
					19: out12 = r_commit_reg_19;
					20: out12 = r_commit_reg_20;
					21: out12 = r_commit_reg_21;
					22: out12 = r_commit_reg_22;
					23: out12 = r_commit_reg_23;
					24: out12 = r_commit_reg_24;
					25: out12 = r_commit_reg_25;
					26: out12 = r_commit_reg_26;
					27: out12 = r_commit_reg_27;
					28: out12 = r_commit_reg_28;
					29: out12 = r_commit_reg_29;
					30: out12 = r_commit_reg_30;
					31: out12 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out12 = r_commit_reg[read_addr12[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr13[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr13[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr13[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr13[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr13[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr13[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr13[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr13[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr13[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr13[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr13[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr13[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr13[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr13[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr13[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr13[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr13[LNCOMMIT-1:0]), read_enable13, read_addr13[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr13[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr13[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr13[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr13[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr13[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr13[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr13[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr13[4:0]), write_enable0&(write_addr0==read_addr13[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr13[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr13[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr13[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr13[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr13[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr13[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr13[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr13[LNCOMMIT-1:0]), read_enable13, read_addr13[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out13 = 64'bx;
		19'b1???????_?????????_10: out13 = transfer_reg_0;
		19'b?1??????_?????????_10: out13 = transfer_reg_1;
		19'b??1?????_?????????_10: out13 = transfer_reg_2;
		19'b???1????_?????????_10: out13 = transfer_reg_3;
		19'b????1???_?????????_10: out13 = transfer_reg_4;
		19'b?????1??_?????????_10: out13 = transfer_reg_5;
		19'b??????1?_?????????_10: out13 = transfer_reg_6;
		19'b???????1_?????????_10: out13 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr13[4:0]) // synthesis full_case parallel_case
				0: out13 = 0;
				1: out13 = r_real_reg_1;
				2: out13 = r_real_reg_2;
				3: out13 = r_real_reg_3;
				4: out13 = r_real_reg_4;
				5: out13 = r_real_reg_5;
				6: out13 = r_real_reg_6;
				7: out13 = r_real_reg_7;
				8: out13 = r_real_reg_8;
				9: out13 = r_real_reg_9;
				10: out13 = r_real_reg_10;
				11: out13 = r_real_reg_11;
				12: out13 = r_real_reg_12;
				13: out13 = r_real_reg_13;
				14: out13 = r_real_reg_14;
				15: out13 = r_real_reg_15;
				16: out13 = r_real_reg_16;
				17: out13 = r_real_reg_17;
				18: out13 = r_real_reg_18;
				19: out13 = r_real_reg_19;
				20: out13 = r_real_reg_20;
				21: out13 = r_real_reg_21;
				22: out13 = r_real_reg_22;
				23: out13 = r_real_reg_23;
				24: out13 = r_real_reg_24;
				25: out13 = r_real_reg_25;
				26: out13 = r_real_reg_26;
				27: out13 = r_real_reg_27;
				28: out13 = r_real_reg_28;
				29: out13 = r_real_reg_29;
				30: out13 = r_real_reg_30;
				31: out13 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out13 = (read_addr13[4:0]==0?0:r_real_reg[read_addr13[4:0]]);
`endif
		19'b????????_1????????_11: out13 = write_data0;
		19'b????????_?1???????_11: out13 = write_data1;
		19'b????????_??1??????_11: out13 = write_data2;
		19'b????????_???1?????_11: out13 = write_data3;
		19'b????????_????1????_11: out13 = write_data4;
		19'b????????_?????1???_11: out13 = write_data5;
		19'b????????_??????1??_11: out13 = write_data6;
		19'b????????_???????1?_11: out13 = write_data7;
		19'b????????_????????1_11: out13 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr13[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out13 = r_commit_reg_0;
					1: out13 = r_commit_reg_1;
					2: out13 = r_commit_reg_2;
					3: out13 = r_commit_reg_3;
					4: out13 = r_commit_reg_4;
					5: out13 = r_commit_reg_5;
					6: out13 = r_commit_reg_6;
					7: out13 = r_commit_reg_7;
					8: out13 = r_commit_reg_8;
					9: out13 = r_commit_reg_9;
					10: out13 = r_commit_reg_10;
					11: out13 = r_commit_reg_11;
					12: out13 = r_commit_reg_12;
					13: out13 = r_commit_reg_13;
					14: out13 = r_commit_reg_14;
					15: out13 = r_commit_reg_15;
					16: out13 = r_commit_reg_16;
					17: out13 = r_commit_reg_17;
					18: out13 = r_commit_reg_18;
					19: out13 = r_commit_reg_19;
					20: out13 = r_commit_reg_20;
					21: out13 = r_commit_reg_21;
					22: out13 = r_commit_reg_22;
					23: out13 = r_commit_reg_23;
					24: out13 = r_commit_reg_24;
					25: out13 = r_commit_reg_25;
					26: out13 = r_commit_reg_26;
					27: out13 = r_commit_reg_27;
					28: out13 = r_commit_reg_28;
					29: out13 = r_commit_reg_29;
					30: out13 = r_commit_reg_30;
					31: out13 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out13 = r_commit_reg[read_addr13[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr14[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr14[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr14[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr14[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr14[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr14[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr14[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr14[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr14[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr14[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr14[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr14[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr14[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr14[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr14[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr14[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr14[LNCOMMIT-1:0]), read_enable14, read_addr14[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr14[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr14[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr14[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr14[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr14[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr14[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr14[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr14[4:0]), write_enable0&(write_addr0==read_addr14[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr14[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr14[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr14[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr14[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr14[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr14[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr14[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr14[LNCOMMIT-1:0]), read_enable14, read_addr14[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out14 = 64'bx;
		19'b1???????_?????????_10: out14 = transfer_reg_0;
		19'b?1??????_?????????_10: out14 = transfer_reg_1;
		19'b??1?????_?????????_10: out14 = transfer_reg_2;
		19'b???1????_?????????_10: out14 = transfer_reg_3;
		19'b????1???_?????????_10: out14 = transfer_reg_4;
		19'b?????1??_?????????_10: out14 = transfer_reg_5;
		19'b??????1?_?????????_10: out14 = transfer_reg_6;
		19'b???????1_?????????_10: out14 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr14[4:0]) // synthesis full_case parallel_case
				0: out14 = 0;
				1: out14 = r_real_reg_1;
				2: out14 = r_real_reg_2;
				3: out14 = r_real_reg_3;
				4: out14 = r_real_reg_4;
				5: out14 = r_real_reg_5;
				6: out14 = r_real_reg_6;
				7: out14 = r_real_reg_7;
				8: out14 = r_real_reg_8;
				9: out14 = r_real_reg_9;
				10: out14 = r_real_reg_10;
				11: out14 = r_real_reg_11;
				12: out14 = r_real_reg_12;
				13: out14 = r_real_reg_13;
				14: out14 = r_real_reg_14;
				15: out14 = r_real_reg_15;
				16: out14 = r_real_reg_16;
				17: out14 = r_real_reg_17;
				18: out14 = r_real_reg_18;
				19: out14 = r_real_reg_19;
				20: out14 = r_real_reg_20;
				21: out14 = r_real_reg_21;
				22: out14 = r_real_reg_22;
				23: out14 = r_real_reg_23;
				24: out14 = r_real_reg_24;
				25: out14 = r_real_reg_25;
				26: out14 = r_real_reg_26;
				27: out14 = r_real_reg_27;
				28: out14 = r_real_reg_28;
				29: out14 = r_real_reg_29;
				30: out14 = r_real_reg_30;
				31: out14 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out14 = (read_addr14[4:0]==0?0:r_real_reg[read_addr14[4:0]]);
`endif
		19'b????????_1????????_11: out14 = write_data0;
		19'b????????_?1???????_11: out14 = write_data1;
		19'b????????_??1??????_11: out14 = write_data2;
		19'b????????_???1?????_11: out14 = write_data3;
		19'b????????_????1????_11: out14 = write_data4;
		19'b????????_?????1???_11: out14 = write_data5;
		19'b????????_??????1??_11: out14 = write_data6;
		19'b????????_???????1?_11: out14 = write_data7;
		19'b????????_????????1_11: out14 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr14[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out14 = r_commit_reg_0;
					1: out14 = r_commit_reg_1;
					2: out14 = r_commit_reg_2;
					3: out14 = r_commit_reg_3;
					4: out14 = r_commit_reg_4;
					5: out14 = r_commit_reg_5;
					6: out14 = r_commit_reg_6;
					7: out14 = r_commit_reg_7;
					8: out14 = r_commit_reg_8;
					9: out14 = r_commit_reg_9;
					10: out14 = r_commit_reg_10;
					11: out14 = r_commit_reg_11;
					12: out14 = r_commit_reg_12;
					13: out14 = r_commit_reg_13;
					14: out14 = r_commit_reg_14;
					15: out14 = r_commit_reg_15;
					16: out14 = r_commit_reg_16;
					17: out14 = r_commit_reg_17;
					18: out14 = r_commit_reg_18;
					19: out14 = r_commit_reg_19;
					20: out14 = r_commit_reg_20;
					21: out14 = r_commit_reg_21;
					22: out14 = r_commit_reg_22;
					23: out14 = r_commit_reg_23;
					24: out14 = r_commit_reg_24;
					25: out14 = r_commit_reg_25;
					26: out14 = r_commit_reg_26;
					27: out14 = r_commit_reg_27;
					28: out14 = r_commit_reg_28;
					29: out14 = r_commit_reg_29;
					30: out14 = r_commit_reg_30;
					31: out14 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out14 = r_commit_reg[read_addr14[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr15[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr15[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr15[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr15[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr15[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr15[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr15[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr15[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr15[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr15[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr15[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr15[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr15[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr15[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr15[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr15[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr15[LNCOMMIT-1:0]), read_enable15, read_addr15[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr15[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr15[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr15[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr15[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr15[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr15[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr15[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr15[4:0]), write_enable0&(write_addr0==read_addr15[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr15[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr15[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr15[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr15[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr15[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr15[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr15[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr15[LNCOMMIT-1:0]), read_enable15, read_addr15[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out15 = 64'bx;
		19'b1???????_?????????_10: out15 = transfer_reg_0;
		19'b?1??????_?????????_10: out15 = transfer_reg_1;
		19'b??1?????_?????????_10: out15 = transfer_reg_2;
		19'b???1????_?????????_10: out15 = transfer_reg_3;
		19'b????1???_?????????_10: out15 = transfer_reg_4;
		19'b?????1??_?????????_10: out15 = transfer_reg_5;
		19'b??????1?_?????????_10: out15 = transfer_reg_6;
		19'b???????1_?????????_10: out15 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr15[4:0]) // synthesis full_case parallel_case
				0: out15 = 0;
				1: out15 = r_real_reg_1;
				2: out15 = r_real_reg_2;
				3: out15 = r_real_reg_3;
				4: out15 = r_real_reg_4;
				5: out15 = r_real_reg_5;
				6: out15 = r_real_reg_6;
				7: out15 = r_real_reg_7;
				8: out15 = r_real_reg_8;
				9: out15 = r_real_reg_9;
				10: out15 = r_real_reg_10;
				11: out15 = r_real_reg_11;
				12: out15 = r_real_reg_12;
				13: out15 = r_real_reg_13;
				14: out15 = r_real_reg_14;
				15: out15 = r_real_reg_15;
				16: out15 = r_real_reg_16;
				17: out15 = r_real_reg_17;
				18: out15 = r_real_reg_18;
				19: out15 = r_real_reg_19;
				20: out15 = r_real_reg_20;
				21: out15 = r_real_reg_21;
				22: out15 = r_real_reg_22;
				23: out15 = r_real_reg_23;
				24: out15 = r_real_reg_24;
				25: out15 = r_real_reg_25;
				26: out15 = r_real_reg_26;
				27: out15 = r_real_reg_27;
				28: out15 = r_real_reg_28;
				29: out15 = r_real_reg_29;
				30: out15 = r_real_reg_30;
				31: out15 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out15 = (read_addr15[4:0]==0?0:r_real_reg[read_addr15[4:0]]);
`endif
		19'b????????_1????????_11: out15 = write_data0;
		19'b????????_?1???????_11: out15 = write_data1;
		19'b????????_??1??????_11: out15 = write_data2;
		19'b????????_???1?????_11: out15 = write_data3;
		19'b????????_????1????_11: out15 = write_data4;
		19'b????????_?????1???_11: out15 = write_data5;
		19'b????????_??????1??_11: out15 = write_data6;
		19'b????????_???????1?_11: out15 = write_data7;
		19'b????????_????????1_11: out15 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr15[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out15 = r_commit_reg_0;
					1: out15 = r_commit_reg_1;
					2: out15 = r_commit_reg_2;
					3: out15 = r_commit_reg_3;
					4: out15 = r_commit_reg_4;
					5: out15 = r_commit_reg_5;
					6: out15 = r_commit_reg_6;
					7: out15 = r_commit_reg_7;
					8: out15 = r_commit_reg_8;
					9: out15 = r_commit_reg_9;
					10: out15 = r_commit_reg_10;
					11: out15 = r_commit_reg_11;
					12: out15 = r_commit_reg_12;
					13: out15 = r_commit_reg_13;
					14: out15 = r_commit_reg_14;
					15: out15 = r_commit_reg_15;
					16: out15 = r_commit_reg_16;
					17: out15 = r_commit_reg_17;
					18: out15 = r_commit_reg_18;
					19: out15 = r_commit_reg_19;
					20: out15 = r_commit_reg_20;
					21: out15 = r_commit_reg_21;
					22: out15 = r_commit_reg_22;
					23: out15 = r_commit_reg_23;
					24: out15 = r_commit_reg_24;
					25: out15 = r_commit_reg_25;
					26: out15 = r_commit_reg_26;
					27: out15 = r_commit_reg_27;
					28: out15 = r_commit_reg_28;
					29: out15 = r_commit_reg_29;
					30: out15 = r_commit_reg_30;
					31: out15 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out15 = r_commit_reg[read_addr15[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
`ifdef FP
		casez ({transfer_pending_ok[0]&~transfer_write_fp_0&(transfer_write_addr_0==read_addr16[4:0]), transfer_pending_ok[1]&~transfer_write_fp_1&(transfer_write_addr_1==read_addr16[4:0]), transfer_pending_ok[2]&~transfer_write_fp_2&(transfer_write_addr_2==read_addr16[4:0]), transfer_pending_ok[3]&~transfer_write_fp_3&(transfer_write_addr_3==read_addr16[4:0]), transfer_pending_ok[4]&~transfer_write_fp_4&(transfer_write_addr_4==read_addr16[4:0]), transfer_pending_ok[5]&~transfer_write_fp_5&(transfer_write_addr_5==read_addr16[4:0]), transfer_pending_ok[6]&~transfer_write_fp_6&(transfer_write_addr_6==read_addr16[4:0]), transfer_pending_ok[7]&~transfer_write_fp_7&(transfer_write_addr_7==read_addr16[4:0]), write_enable0&~write_fp0&(write_addr0==read_addr16[LNCOMMIT-1:0]), write_enable1&~write_fp1&(write_addr1==read_addr16[LNCOMMIT-1:0]), write_enable2&~write_fp2&(write_addr2==read_addr16[LNCOMMIT-1:0]), write_enable3&~write_fp3&(write_addr3==read_addr16[LNCOMMIT-1:0]), write_enable4&~write_fp4&(write_addr4==read_addr16[LNCOMMIT-1:0]), write_enable5&~write_fp5&(write_addr5==read_addr16[LNCOMMIT-1:0]), write_enable6&~write_fp6&(write_addr6==read_addr16[LNCOMMIT-1:0]), write_enable7&~write_fp7&(write_addr7==read_addr16[LNCOMMIT-1:0]), write_enable8&~write_fp8&(write_addr8==read_addr16[LNCOMMIT-1:0]), read_enable16, read_addr16[RA-1]}) // synthesis full_case parallel_case
`else
		casez ({transfer_pending_ok[0]&(transfer_write_addr_0==read_addr16[4:0]), transfer_pending_ok[1]&(transfer_write_addr_1==read_addr16[4:0]), transfer_pending_ok[2]&(transfer_write_addr_2==read_addr16[4:0]), transfer_pending_ok[3]&(transfer_write_addr_3==read_addr16[4:0]), transfer_pending_ok[4]&(transfer_write_addr_4==read_addr16[4:0]), transfer_pending_ok[5]&(transfer_write_addr_5==read_addr16[4:0]), transfer_pending_ok[6]&(transfer_write_addr_6==read_addr16[4:0]), transfer_pending_ok[7]&(transfer_write_addr_7==read_addr16[4:0]), write_enable0&(write_addr0==read_addr16[LNCOMMIT-1:0]), write_enable1&(write_addr1==read_addr16[LNCOMMIT-1:0]), write_enable2&(write_addr2==read_addr16[LNCOMMIT-1:0]), write_enable3&(write_addr3==read_addr16[LNCOMMIT-1:0]), write_enable4&(write_addr4==read_addr16[LNCOMMIT-1:0]), write_enable5&(write_addr5==read_addr16[LNCOMMIT-1:0]), write_enable6&(write_addr6==read_addr16[LNCOMMIT-1:0]), write_enable7&(write_addr7==read_addr16[LNCOMMIT-1:0]), write_enable8&(write_addr8==read_addr16[LNCOMMIT-1:0]), read_enable16, read_addr16[RA-1]}) // synthesis full_case parallel_case
`endif
		19'b????????_?????????_0?: out16 = 64'bx;
		19'b1???????_?????????_10: out16 = transfer_reg_0;
		19'b?1??????_?????????_10: out16 = transfer_reg_1;
		19'b??1?????_?????????_10: out16 = transfer_reg_2;
		19'b???1????_?????????_10: out16 = transfer_reg_3;
		19'b????1???_?????????_10: out16 = transfer_reg_4;
		19'b?????1??_?????????_10: out16 = transfer_reg_5;
		19'b??????1?_?????????_10: out16 = transfer_reg_6;
		19'b???????1_?????????_10: out16 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (read_addr16[4:0]) // synthesis full_case parallel_case
				0: out16 = 0;
				1: out16 = r_real_reg_1;
				2: out16 = r_real_reg_2;
				3: out16 = r_real_reg_3;
				4: out16 = r_real_reg_4;
				5: out16 = r_real_reg_5;
				6: out16 = r_real_reg_6;
				7: out16 = r_real_reg_7;
				8: out16 = r_real_reg_8;
				9: out16 = r_real_reg_9;
				10: out16 = r_real_reg_10;
				11: out16 = r_real_reg_11;
				12: out16 = r_real_reg_12;
				13: out16 = r_real_reg_13;
				14: out16 = r_real_reg_14;
				15: out16 = r_real_reg_15;
				16: out16 = r_real_reg_16;
				17: out16 = r_real_reg_17;
				18: out16 = r_real_reg_18;
				19: out16 = r_real_reg_19;
				20: out16 = r_real_reg_20;
				21: out16 = r_real_reg_21;
				22: out16 = r_real_reg_22;
				23: out16 = r_real_reg_23;
				24: out16 = r_real_reg_24;
				25: out16 = r_real_reg_25;
				26: out16 = r_real_reg_26;
				27: out16 = r_real_reg_27;
				28: out16 = r_real_reg_28;
				29: out16 = r_real_reg_29;
				30: out16 = r_real_reg_30;
				31: out16 = r_real_reg_31;
				endcase
`else
		19'b00000000_?????????_10: out16 = (read_addr16[4:0]==0?0:r_real_reg[read_addr16[4:0]]);
`endif
		19'b????????_1????????_11: out16 = write_data0;
		19'b????????_?1???????_11: out16 = write_data1;
		19'b????????_??1??????_11: out16 = write_data2;
		19'b????????_???1?????_11: out16 = write_data3;
		19'b????????_????1????_11: out16 = write_data4;
		19'b????????_?????1???_11: out16 = write_data5;
		19'b????????_??????1??_11: out16 = write_data6;
		19'b????????_???????1?_11: out16 = write_data7;
		19'b????????_????????1_11: out16 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (read_addr16[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: out16 = r_commit_reg_0;
					1: out16 = r_commit_reg_1;
					2: out16 = r_commit_reg_2;
					3: out16 = r_commit_reg_3;
					4: out16 = r_commit_reg_4;
					5: out16 = r_commit_reg_5;
					6: out16 = r_commit_reg_6;
					7: out16 = r_commit_reg_7;
					8: out16 = r_commit_reg_8;
					9: out16 = r_commit_reg_9;
					10: out16 = r_commit_reg_10;
					11: out16 = r_commit_reg_11;
					12: out16 = r_commit_reg_12;
					13: out16 = r_commit_reg_13;
					14: out16 = r_commit_reg_14;
					15: out16 = r_commit_reg_15;
					16: out16 = r_commit_reg_16;
					17: out16 = r_commit_reg_17;
					18: out16 = r_commit_reg_18;
					19: out16 = r_commit_reg_19;
					20: out16 = r_commit_reg_20;
					21: out16 = r_commit_reg_21;
					22: out16 = r_commit_reg_22;
					23: out16 = r_commit_reg_23;
					24: out16 = r_commit_reg_24;
					25: out16 = r_commit_reg_25;
					26: out16 = r_commit_reg_26;
					27: out16 = r_commit_reg_27;
					28: out16 = r_commit_reg_28;
					29: out16 = r_commit_reg_29;
					30: out16 = r_commit_reg_30;
					31: out16 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: out16 = r_commit_reg[read_addr16[LNCOMMIT-1:0]];
`endif
		endcase
	end
`ifdef FP
	always @(*) begin
		casez ({transfer_pending_ok[0]&transfer_write_fp_0&(transfer_write_addr_0==read_addr0[4:0]), transfer_pending_ok[1]&transfer_write_fp_1&(transfer_write_addr_1==read_addr0[4:0]), transfer_pending_ok[2]&transfer_write_fp_2&(transfer_write_addr_2==read_addr0[4:0]), transfer_pending_ok[3]&transfer_write_fp_3&(transfer_write_addr_3==read_addr0[4:0]), transfer_pending_ok[4]&transfer_write_fp_4&(transfer_write_addr_4==read_addr0[4:0]), transfer_pending_ok[5]&transfer_write_fp_5&(transfer_write_addr_5==read_addr0[4:0]), transfer_pending_ok[6]&transfer_write_fp_6&(transfer_write_addr_6==read_addr0[4:0]), transfer_pending_ok[7]&transfer_write_fp_7&(transfer_write_addr_7==read_addr0[4:0]), write_enable0&write_fp0&(write_addr0==read_addr0[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==read_addr0[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==read_addr0[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==read_addr0[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==read_addr0[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==read_addr0[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==read_addr0[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==read_addr0[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==read_addr0[LNCOMMIT-1:0]), fpu_read_enable0, fpu_read_addr0[RA-1]}) // synthesis full_case parallel_case
		19'b????????_?????????_0?: fpu_out0 = 64'bx;
		19'b1???????_?????????_10: fpu_out0 = transfer_reg_0;
		19'b?1??????_?????????_10: fpu_out0 = transfer_reg_1;
		19'b??1?????_?????????_10: fpu_out0 = transfer_reg_2;
		19'b???1????_?????????_10: fpu_out0 = transfer_reg_3;
		19'b????1???_?????????_10: fpu_out0 = transfer_reg_4;
		19'b?????1??_?????????_10: fpu_out0 = transfer_reg_5;
		19'b??????1?_?????????_10: fpu_out0 = transfer_reg_6;
		19'b???????1_?????????_10: fpu_out0 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (fpu_read_addr0[4:0]) // synthesis full_case parallel_case
				0: fpu_out0 = r_real_fp_reg_0;
				1: fpu_out0 = r_real_fp_reg_1;
				2: fpu_out0 = r_real_fp_reg_2;
				3: fpu_out0 = r_real_fp_reg_3;
				4: fpu_out0 = r_real_fp_reg_4;
				5: fpu_out0 = r_real_fp_reg_5;
				6: fpu_out0 = r_real_fp_reg_6;
				7: fpu_out0 = r_real_fp_reg_7;
				8: fpu_out0 = r_real_fp_reg_8;
				9: fpu_out0 = r_real_fp_reg_9;
				10: fpu_out0 = r_real_fp_reg_10;
				11: fpu_out0 = r_real_fp_reg_11;
				12: fpu_out0 = r_real_fp_reg_12;
				13: fpu_out0 = r_real_fp_reg_13;
				14: fpu_out0 = r_real_fp_reg_14;
				15: fpu_out0 = r_real_fp_reg_15;
				16: fpu_out0 = r_real_fp_reg_16;
				17: fpu_out0 = r_real_fp_reg_17;
				18: fpu_out0 = r_real_fp_reg_18;
				19: fpu_out0 = r_real_fp_reg_19;
				20: fpu_out0 = r_real_fp_reg_20;
				21: fpu_out0 = r_real_fp_reg_21;
				22: fpu_out0 = r_real_fp_reg_22;
				23: fpu_out0 = r_real_fp_reg_23;
				24: fpu_out0 = r_real_fp_reg_24;
				25: fpu_out0 = r_real_fp_reg_25;
				26: fpu_out0 = r_real_fp_reg_26;
				27: fpu_out0 = r_real_fp_reg_27;
				28: fpu_out0 = r_real_fp_reg_28;
				29: fpu_out0 = r_real_fp_reg_29;
				30: fpu_out0 = r_real_fp_reg_30;
				31: fpu_out0 = r_real_fp_reg_31;
				endcase
`else
		19'b00000000_?????????_10: fpu_out0 = r_real_fp_reg[fpu_read_addr0[4:0]];
`endif
		19'b????????_1????????_11: fpu_out0 = write_data0;
		19'b????????_?1???????_11: fpu_out0 = write_data1;
		19'b????????_??1??????_11: fpu_out0 = write_data2;
		19'b????????_???1?????_11: fpu_out0 = write_data3;
		19'b????????_????1????_11: fpu_out0 = write_data4;
		19'b????????_?????1???_11: fpu_out0 = write_data5;
		19'b????????_??????1??_11: fpu_out0 = write_data6;
		19'b????????_???????1?_11: fpu_out0 = write_data7;
		19'b????????_????????1_11: fpu_out0 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (fpu_read_addr0[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: fpu_out0 = r_commit_reg_0;
					1: fpu_out0 = r_commit_reg_1;
					2: fpu_out0 = r_commit_reg_2;
					3: fpu_out0 = r_commit_reg_3;
					4: fpu_out0 = r_commit_reg_4;
					5: fpu_out0 = r_commit_reg_5;
					6: fpu_out0 = r_commit_reg_6;
					7: fpu_out0 = r_commit_reg_7;
					8: fpu_out0 = r_commit_reg_8;
					9: fpu_out0 = r_commit_reg_9;
					10: fpu_out0 = r_commit_reg_10;
					11: fpu_out0 = r_commit_reg_11;
					12: fpu_out0 = r_commit_reg_12;
					13: fpu_out0 = r_commit_reg_13;
					14: fpu_out0 = r_commit_reg_14;
					15: fpu_out0 = r_commit_reg_15;
					16: fpu_out0 = r_commit_reg_16;
					17: fpu_out0 = r_commit_reg_17;
					18: fpu_out0 = r_commit_reg_18;
					19: fpu_out0 = r_commit_reg_19;
					20: fpu_out0 = r_commit_reg_20;
					21: fpu_out0 = r_commit_reg_21;
					22: fpu_out0 = r_commit_reg_22;
					23: fpu_out0 = r_commit_reg_23;
					24: fpu_out0 = r_commit_reg_24;
					25: fpu_out0 = r_commit_reg_25;
					26: fpu_out0 = r_commit_reg_26;
					27: fpu_out0 = r_commit_reg_27;
					28: fpu_out0 = r_commit_reg_28;
					29: fpu_out0 = r_commit_reg_29;
					30: fpu_out0 = r_commit_reg_30;
					31: fpu_out0 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: fpu_out0 = r_commit_reg[fpu_read_addr0[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
		casez ({transfer_pending_ok[0]&transfer_write_fp_0&(transfer_write_addr_0==read_addr1[4:0]), transfer_pending_ok[1]&transfer_write_fp_1&(transfer_write_addr_1==read_addr1[4:0]), transfer_pending_ok[2]&transfer_write_fp_2&(transfer_write_addr_2==read_addr1[4:0]), transfer_pending_ok[3]&transfer_write_fp_3&(transfer_write_addr_3==read_addr1[4:0]), transfer_pending_ok[4]&transfer_write_fp_4&(transfer_write_addr_4==read_addr1[4:0]), transfer_pending_ok[5]&transfer_write_fp_5&(transfer_write_addr_5==read_addr1[4:0]), transfer_pending_ok[6]&transfer_write_fp_6&(transfer_write_addr_6==read_addr1[4:0]), transfer_pending_ok[7]&transfer_write_fp_7&(transfer_write_addr_7==read_addr1[4:0]), write_enable0&write_fp0&(write_addr0==read_addr1[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==read_addr1[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==read_addr1[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==read_addr1[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==read_addr1[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==read_addr1[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==read_addr1[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==read_addr1[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==read_addr1[LNCOMMIT-1:0]), fpu_read_enable1, fpu_read_addr1[RA-1]}) // synthesis full_case parallel_case
		19'b????????_?????????_0?: fpu_out1 = 64'bx;
		19'b1???????_?????????_10: fpu_out1 = transfer_reg_0;
		19'b?1??????_?????????_10: fpu_out1 = transfer_reg_1;
		19'b??1?????_?????????_10: fpu_out1 = transfer_reg_2;
		19'b???1????_?????????_10: fpu_out1 = transfer_reg_3;
		19'b????1???_?????????_10: fpu_out1 = transfer_reg_4;
		19'b?????1??_?????????_10: fpu_out1 = transfer_reg_5;
		19'b??????1?_?????????_10: fpu_out1 = transfer_reg_6;
		19'b???????1_?????????_10: fpu_out1 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (fpu_read_addr1[4:0]) // synthesis full_case parallel_case
				0: fpu_out1 = r_real_fp_reg_0;
				1: fpu_out1 = r_real_fp_reg_1;
				2: fpu_out1 = r_real_fp_reg_2;
				3: fpu_out1 = r_real_fp_reg_3;
				4: fpu_out1 = r_real_fp_reg_4;
				5: fpu_out1 = r_real_fp_reg_5;
				6: fpu_out1 = r_real_fp_reg_6;
				7: fpu_out1 = r_real_fp_reg_7;
				8: fpu_out1 = r_real_fp_reg_8;
				9: fpu_out1 = r_real_fp_reg_9;
				10: fpu_out1 = r_real_fp_reg_10;
				11: fpu_out1 = r_real_fp_reg_11;
				12: fpu_out1 = r_real_fp_reg_12;
				13: fpu_out1 = r_real_fp_reg_13;
				14: fpu_out1 = r_real_fp_reg_14;
				15: fpu_out1 = r_real_fp_reg_15;
				16: fpu_out1 = r_real_fp_reg_16;
				17: fpu_out1 = r_real_fp_reg_17;
				18: fpu_out1 = r_real_fp_reg_18;
				19: fpu_out1 = r_real_fp_reg_19;
				20: fpu_out1 = r_real_fp_reg_20;
				21: fpu_out1 = r_real_fp_reg_21;
				22: fpu_out1 = r_real_fp_reg_22;
				23: fpu_out1 = r_real_fp_reg_23;
				24: fpu_out1 = r_real_fp_reg_24;
				25: fpu_out1 = r_real_fp_reg_25;
				26: fpu_out1 = r_real_fp_reg_26;
				27: fpu_out1 = r_real_fp_reg_27;
				28: fpu_out1 = r_real_fp_reg_28;
				29: fpu_out1 = r_real_fp_reg_29;
				30: fpu_out1 = r_real_fp_reg_30;
				31: fpu_out1 = r_real_fp_reg_31;
				endcase
`else
		19'b00000000_?????????_10: fpu_out1 = r_real_fp_reg[fpu_read_addr1[4:0]];
`endif
		19'b????????_1????????_11: fpu_out1 = write_data0;
		19'b????????_?1???????_11: fpu_out1 = write_data1;
		19'b????????_??1??????_11: fpu_out1 = write_data2;
		19'b????????_???1?????_11: fpu_out1 = write_data3;
		19'b????????_????1????_11: fpu_out1 = write_data4;
		19'b????????_?????1???_11: fpu_out1 = write_data5;
		19'b????????_??????1??_11: fpu_out1 = write_data6;
		19'b????????_???????1?_11: fpu_out1 = write_data7;
		19'b????????_????????1_11: fpu_out1 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (fpu_read_addr1[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: fpu_out1 = r_commit_reg_0;
					1: fpu_out1 = r_commit_reg_1;
					2: fpu_out1 = r_commit_reg_2;
					3: fpu_out1 = r_commit_reg_3;
					4: fpu_out1 = r_commit_reg_4;
					5: fpu_out1 = r_commit_reg_5;
					6: fpu_out1 = r_commit_reg_6;
					7: fpu_out1 = r_commit_reg_7;
					8: fpu_out1 = r_commit_reg_8;
					9: fpu_out1 = r_commit_reg_9;
					10: fpu_out1 = r_commit_reg_10;
					11: fpu_out1 = r_commit_reg_11;
					12: fpu_out1 = r_commit_reg_12;
					13: fpu_out1 = r_commit_reg_13;
					14: fpu_out1 = r_commit_reg_14;
					15: fpu_out1 = r_commit_reg_15;
					16: fpu_out1 = r_commit_reg_16;
					17: fpu_out1 = r_commit_reg_17;
					18: fpu_out1 = r_commit_reg_18;
					19: fpu_out1 = r_commit_reg_19;
					20: fpu_out1 = r_commit_reg_20;
					21: fpu_out1 = r_commit_reg_21;
					22: fpu_out1 = r_commit_reg_22;
					23: fpu_out1 = r_commit_reg_23;
					24: fpu_out1 = r_commit_reg_24;
					25: fpu_out1 = r_commit_reg_25;
					26: fpu_out1 = r_commit_reg_26;
					27: fpu_out1 = r_commit_reg_27;
					28: fpu_out1 = r_commit_reg_28;
					29: fpu_out1 = r_commit_reg_29;
					30: fpu_out1 = r_commit_reg_30;
					31: fpu_out1 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: fpu_out1 = r_commit_reg[fpu_read_addr1[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
		casez ({transfer_pending_ok[0]&transfer_write_fp_0&(transfer_write_addr_0==read_addr2[4:0]), transfer_pending_ok[1]&transfer_write_fp_1&(transfer_write_addr_1==read_addr2[4:0]), transfer_pending_ok[2]&transfer_write_fp_2&(transfer_write_addr_2==read_addr2[4:0]), transfer_pending_ok[3]&transfer_write_fp_3&(transfer_write_addr_3==read_addr2[4:0]), transfer_pending_ok[4]&transfer_write_fp_4&(transfer_write_addr_4==read_addr2[4:0]), transfer_pending_ok[5]&transfer_write_fp_5&(transfer_write_addr_5==read_addr2[4:0]), transfer_pending_ok[6]&transfer_write_fp_6&(transfer_write_addr_6==read_addr2[4:0]), transfer_pending_ok[7]&transfer_write_fp_7&(transfer_write_addr_7==read_addr2[4:0]), write_enable0&write_fp0&(write_addr0==read_addr2[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==read_addr2[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==read_addr2[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==read_addr2[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==read_addr2[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==read_addr2[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==read_addr2[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==read_addr2[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==read_addr2[LNCOMMIT-1:0]), fpu_read_enable2, fpu_read_addr2[RA-1]}) // synthesis full_case parallel_case
		19'b????????_?????????_0?: fpu_out2 = 64'bx;
		19'b1???????_?????????_10: fpu_out2 = transfer_reg_0;
		19'b?1??????_?????????_10: fpu_out2 = transfer_reg_1;
		19'b??1?????_?????????_10: fpu_out2 = transfer_reg_2;
		19'b???1????_?????????_10: fpu_out2 = transfer_reg_3;
		19'b????1???_?????????_10: fpu_out2 = transfer_reg_4;
		19'b?????1??_?????????_10: fpu_out2 = transfer_reg_5;
		19'b??????1?_?????????_10: fpu_out2 = transfer_reg_6;
		19'b???????1_?????????_10: fpu_out2 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (fpu_read_addr2[4:0]) // synthesis full_case parallel_case
				0: fpu_out2 = r_real_fp_reg_0;
				1: fpu_out2 = r_real_fp_reg_1;
				2: fpu_out2 = r_real_fp_reg_2;
				3: fpu_out2 = r_real_fp_reg_3;
				4: fpu_out2 = r_real_fp_reg_4;
				5: fpu_out2 = r_real_fp_reg_5;
				6: fpu_out2 = r_real_fp_reg_6;
				7: fpu_out2 = r_real_fp_reg_7;
				8: fpu_out2 = r_real_fp_reg_8;
				9: fpu_out2 = r_real_fp_reg_9;
				10: fpu_out2 = r_real_fp_reg_10;
				11: fpu_out2 = r_real_fp_reg_11;
				12: fpu_out2 = r_real_fp_reg_12;
				13: fpu_out2 = r_real_fp_reg_13;
				14: fpu_out2 = r_real_fp_reg_14;
				15: fpu_out2 = r_real_fp_reg_15;
				16: fpu_out2 = r_real_fp_reg_16;
				17: fpu_out2 = r_real_fp_reg_17;
				18: fpu_out2 = r_real_fp_reg_18;
				19: fpu_out2 = r_real_fp_reg_19;
				20: fpu_out2 = r_real_fp_reg_20;
				21: fpu_out2 = r_real_fp_reg_21;
				22: fpu_out2 = r_real_fp_reg_22;
				23: fpu_out2 = r_real_fp_reg_23;
				24: fpu_out2 = r_real_fp_reg_24;
				25: fpu_out2 = r_real_fp_reg_25;
				26: fpu_out2 = r_real_fp_reg_26;
				27: fpu_out2 = r_real_fp_reg_27;
				28: fpu_out2 = r_real_fp_reg_28;
				29: fpu_out2 = r_real_fp_reg_29;
				30: fpu_out2 = r_real_fp_reg_30;
				31: fpu_out2 = r_real_fp_reg_31;
				endcase
`else
		19'b00000000_?????????_10: fpu_out2 = r_real_fp_reg[fpu_read_addr2[4:0]];
`endif
		19'b????????_1????????_11: fpu_out2 = write_data0;
		19'b????????_?1???????_11: fpu_out2 = write_data1;
		19'b????????_??1??????_11: fpu_out2 = write_data2;
		19'b????????_???1?????_11: fpu_out2 = write_data3;
		19'b????????_????1????_11: fpu_out2 = write_data4;
		19'b????????_?????1???_11: fpu_out2 = write_data5;
		19'b????????_??????1??_11: fpu_out2 = write_data6;
		19'b????????_???????1?_11: fpu_out2 = write_data7;
		19'b????????_????????1_11: fpu_out2 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (fpu_read_addr2[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: fpu_out2 = r_commit_reg_0;
					1: fpu_out2 = r_commit_reg_1;
					2: fpu_out2 = r_commit_reg_2;
					3: fpu_out2 = r_commit_reg_3;
					4: fpu_out2 = r_commit_reg_4;
					5: fpu_out2 = r_commit_reg_5;
					6: fpu_out2 = r_commit_reg_6;
					7: fpu_out2 = r_commit_reg_7;
					8: fpu_out2 = r_commit_reg_8;
					9: fpu_out2 = r_commit_reg_9;
					10: fpu_out2 = r_commit_reg_10;
					11: fpu_out2 = r_commit_reg_11;
					12: fpu_out2 = r_commit_reg_12;
					13: fpu_out2 = r_commit_reg_13;
					14: fpu_out2 = r_commit_reg_14;
					15: fpu_out2 = r_commit_reg_15;
					16: fpu_out2 = r_commit_reg_16;
					17: fpu_out2 = r_commit_reg_17;
					18: fpu_out2 = r_commit_reg_18;
					19: fpu_out2 = r_commit_reg_19;
					20: fpu_out2 = r_commit_reg_20;
					21: fpu_out2 = r_commit_reg_21;
					22: fpu_out2 = r_commit_reg_22;
					23: fpu_out2 = r_commit_reg_23;
					24: fpu_out2 = r_commit_reg_24;
					25: fpu_out2 = r_commit_reg_25;
					26: fpu_out2 = r_commit_reg_26;
					27: fpu_out2 = r_commit_reg_27;
					28: fpu_out2 = r_commit_reg_28;
					29: fpu_out2 = r_commit_reg_29;
					30: fpu_out2 = r_commit_reg_30;
					31: fpu_out2 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: fpu_out2 = r_commit_reg[fpu_read_addr2[LNCOMMIT-1:0]];
`endif
		endcase
	end
	always @(*) begin
		casez ({transfer_pending_ok[0]&transfer_write_fp_0&(transfer_write_addr_0==read_addr3[4:0]), transfer_pending_ok[1]&transfer_write_fp_1&(transfer_write_addr_1==read_addr3[4:0]), transfer_pending_ok[2]&transfer_write_fp_2&(transfer_write_addr_2==read_addr3[4:0]), transfer_pending_ok[3]&transfer_write_fp_3&(transfer_write_addr_3==read_addr3[4:0]), transfer_pending_ok[4]&transfer_write_fp_4&(transfer_write_addr_4==read_addr3[4:0]), transfer_pending_ok[5]&transfer_write_fp_5&(transfer_write_addr_5==read_addr3[4:0]), transfer_pending_ok[6]&transfer_write_fp_6&(transfer_write_addr_6==read_addr3[4:0]), transfer_pending_ok[7]&transfer_write_fp_7&(transfer_write_addr_7==read_addr3[4:0]), write_enable0&write_fp0&(write_addr0==read_addr3[LNCOMMIT-1:0]), write_enable1&write_fp1&(write_addr1==read_addr3[LNCOMMIT-1:0]), write_enable2&write_fp2&(write_addr2==read_addr3[LNCOMMIT-1:0]), write_enable3&write_fp3&(write_addr3==read_addr3[LNCOMMIT-1:0]), write_enable4&write_fp4&(write_addr4==read_addr3[LNCOMMIT-1:0]), write_enable5&write_fp5&(write_addr5==read_addr3[LNCOMMIT-1:0]), write_enable6&write_fp6&(write_addr6==read_addr3[LNCOMMIT-1:0]), write_enable7&write_fp7&(write_addr7==read_addr3[LNCOMMIT-1:0]), write_enable8&write_fp8&(write_addr8==read_addr3[LNCOMMIT-1:0]), fpu_read_enable3, fpu_read_addr3[RA-1]}) // synthesis full_case parallel_case
		19'b????????_?????????_0?: fpu_out3 = 64'bx;
		19'b1???????_?????????_10: fpu_out3 = transfer_reg_0;
		19'b?1??????_?????????_10: fpu_out3 = transfer_reg_1;
		19'b??1?????_?????????_10: fpu_out3 = transfer_reg_2;
		19'b???1????_?????????_10: fpu_out3 = transfer_reg_3;
		19'b????1???_?????????_10: fpu_out3 = transfer_reg_4;
		19'b?????1??_?????????_10: fpu_out3 = transfer_reg_5;
		19'b??????1?_?????????_10: fpu_out3 = transfer_reg_6;
		19'b???????1_?????????_10: fpu_out3 = transfer_reg_7;
`ifdef VSYNTH
		19'b00000000_?????????_10:	case (fpu_read_addr3[4:0]) // synthesis full_case parallel_case
				0: fpu_out3 = r_real_fp_reg_0;
				1: fpu_out3 = r_real_fp_reg_1;
				2: fpu_out3 = r_real_fp_reg_2;
				3: fpu_out3 = r_real_fp_reg_3;
				4: fpu_out3 = r_real_fp_reg_4;
				5: fpu_out3 = r_real_fp_reg_5;
				6: fpu_out3 = r_real_fp_reg_6;
				7: fpu_out3 = r_real_fp_reg_7;
				8: fpu_out3 = r_real_fp_reg_8;
				9: fpu_out3 = r_real_fp_reg_9;
				10: fpu_out3 = r_real_fp_reg_10;
				11: fpu_out3 = r_real_fp_reg_11;
				12: fpu_out3 = r_real_fp_reg_12;
				13: fpu_out3 = r_real_fp_reg_13;
				14: fpu_out3 = r_real_fp_reg_14;
				15: fpu_out3 = r_real_fp_reg_15;
				16: fpu_out3 = r_real_fp_reg_16;
				17: fpu_out3 = r_real_fp_reg_17;
				18: fpu_out3 = r_real_fp_reg_18;
				19: fpu_out3 = r_real_fp_reg_19;
				20: fpu_out3 = r_real_fp_reg_20;
				21: fpu_out3 = r_real_fp_reg_21;
				22: fpu_out3 = r_real_fp_reg_22;
				23: fpu_out3 = r_real_fp_reg_23;
				24: fpu_out3 = r_real_fp_reg_24;
				25: fpu_out3 = r_real_fp_reg_25;
				26: fpu_out3 = r_real_fp_reg_26;
				27: fpu_out3 = r_real_fp_reg_27;
				28: fpu_out3 = r_real_fp_reg_28;
				29: fpu_out3 = r_real_fp_reg_29;
				30: fpu_out3 = r_real_fp_reg_30;
				31: fpu_out3 = r_real_fp_reg_31;
				endcase
`else
		19'b00000000_?????????_10: fpu_out3 = r_real_fp_reg[fpu_read_addr3[4:0]];
`endif
		19'b????????_1????????_11: fpu_out3 = write_data0;
		19'b????????_?1???????_11: fpu_out3 = write_data1;
		19'b????????_??1??????_11: fpu_out3 = write_data2;
		19'b????????_???1?????_11: fpu_out3 = write_data3;
		19'b????????_????1????_11: fpu_out3 = write_data4;
		19'b????????_?????1???_11: fpu_out3 = write_data5;
		19'b????????_??????1??_11: fpu_out3 = write_data6;
		19'b????????_???????1?_11: fpu_out3 = write_data7;
		19'b????????_????????1_11: fpu_out3 = write_data8;
`ifdef VSYNTH
		19'b????????_000000000_11:	case (fpu_read_addr3[LNCOMMIT-1:0]) // synthesis full_case parallel_case
					0: fpu_out3 = r_commit_reg_0;
					1: fpu_out3 = r_commit_reg_1;
					2: fpu_out3 = r_commit_reg_2;
					3: fpu_out3 = r_commit_reg_3;
					4: fpu_out3 = r_commit_reg_4;
					5: fpu_out3 = r_commit_reg_5;
					6: fpu_out3 = r_commit_reg_6;
					7: fpu_out3 = r_commit_reg_7;
					8: fpu_out3 = r_commit_reg_8;
					9: fpu_out3 = r_commit_reg_9;
					10: fpu_out3 = r_commit_reg_10;
					11: fpu_out3 = r_commit_reg_11;
					12: fpu_out3 = r_commit_reg_12;
					13: fpu_out3 = r_commit_reg_13;
					14: fpu_out3 = r_commit_reg_14;
					15: fpu_out3 = r_commit_reg_15;
					16: fpu_out3 = r_commit_reg_16;
					17: fpu_out3 = r_commit_reg_17;
					18: fpu_out3 = r_commit_reg_18;
					19: fpu_out3 = r_commit_reg_19;
					20: fpu_out3 = r_commit_reg_20;
					21: fpu_out3 = r_commit_reg_21;
					22: fpu_out3 = r_commit_reg_22;
					23: fpu_out3 = r_commit_reg_23;
					24: fpu_out3 = r_commit_reg_24;
					25: fpu_out3 = r_commit_reg_25;
					26: fpu_out3 = r_commit_reg_26;
					27: fpu_out3 = r_commit_reg_27;
					28: fpu_out3 = r_commit_reg_28;
					29: fpu_out3 = r_commit_reg_29;
					30: fpu_out3 = r_commit_reg_30;
					31: fpu_out3 = r_commit_reg_31;
					endcase
`else
		19'b????????_000000000_11: fpu_out3 = r_commit_reg[fpu_read_addr3[LNCOMMIT-1:0]];
`endif
		endcase
	end
`endif
`ifdef AWS_DEBUG
	ila_reg ila_reg(.clk(clk),
		.r_en_0(read_enable0),
		.r_addr_0(read_addr0),
		.r_data_0(read_data0[31:0]),
		.r_en_1(read_enable1),
		.r_addr_1(read_addr1),
		.r_data_1(read_data1[31:0]),
		.r_en_2(read_enable2),
		.r_addr_2(read_addr2),
		.r_data_2(read_data2[31:0]),
		.r_en_3(read_enable3),
		.r_addr_3(read_addr3),
		.r_data_3(read_data3[31:0]),
		.r_en_4(read_enable4),
		.r_addr_4(read_addr4),
		.r_data_4(read_data4[31:0]),
		.r_en_5(read_enable5),
		.r_addr_5(read_addr5),
		.r_data_5(read_data5[31:0]),
		.r_en_6(read_enable6),
		.r_addr_6(read_addr6),
		.r_data_6(read_data6[31:0]),
		.r_en_7(read_enable7),
		.r_addr_7(read_addr7),
		.r_data_7(read_data7[31:0]),
		.r_en_8(read_enable8),
		.r_addr_8(read_addr8),
		.r_data_8(read_data8[31:0]),
		.r_en_9(read_enable9),
		.r_addr_9(read_addr9),
		.r_data_9(read_data9[31:0]),
		.r_en_10(read_enable10),
		.r_addr_10(read_addr10),
		.r_data_10(read_data10[31:0]),
		.r_en_11(read_enable11),
		.r_addr_11(read_addr11),
		.r_data_11(read_data11[31:0]),
		.r_en_12(read_enable12),
		.r_addr_12(read_addr12),
		.r_data_12(read_data12[31:0]),
		.r_en_13(read_enable13),
		.r_addr_13(read_addr13),
		.r_data_13(read_data13[31:0]),
		.r_en_14(read_enable14),
		.r_addr_14(read_addr14),
		.r_data_14(read_data14[31:0]),
		.r_en_15(read_enable15),
		.r_addr_15(read_addr15),
		.r_data_15(read_data15[31:0]),
		.xxtrig(xxtrig));
	ila_reg2 ila_reg2(.clk(clk),
		.w_en_0(write_enable0),
		.w_addr_0(write_addr0),
		.w_data_0(write_data0[31:0]),
		.w_en_1(write_enable1),
		.w_addr_1(write_addr1),
		.w_data_1(write_data1[31:0]),
		.w_en_2(write_enable2),
		.w_addr_2(write_addr2),
		.w_data_2(write_data2[31:0]),
		.w_en_3(write_enable3),
		.w_addr_3(write_addr3),
		.w_data_3(write_data3[31:0]),
		.w_en_4(write_enable4),
		.w_addr_4(write_addr4),
		.w_data_4(write_data4[31:0]),
		.w_en_5(write_enable5),
		.w_addr_5(write_addr5),
		.w_data_5(write_data5[31:0]),
		.w_en_6(write_enable6),
		.w_addr_6(write_addr6),
		.w_data_6(write_data6[31:0]),
		.w_en_7(write_enable7),
		.w_addr_7(write_addr7),
		.w_data_7(write_data7[31:0]),
		.t_en_0(transfer_enable0),
		.t_src_0(transfer_source_addr0),
		.t_dst_0(transfer_dest_addr0),
		.t_en_1(transfer_enable1),
		.t_src_1(transfer_source_addr1),
		.t_dst_1(transfer_dest_addr1),
		.t_en_2(transfer_enable2),
		.t_src_2(transfer_source_addr2),
		.t_dst_2(transfer_dest_addr2),
		.t_en_3(transfer_enable3),
		.t_src_3(transfer_source_addr3),
		.t_dst_3(transfer_dest_addr3),
		.t_en_4(transfer_enable4),
		.t_src_4(transfer_source_addr4),
		.t_dst_4(transfer_dest_addr4),
		.t_en_5(transfer_enable5),
		.t_src_5(transfer_source_addr5),
		.t_dst_5(transfer_dest_addr5),
		.t_en_6(transfer_enable6),
		.t_src_6(transfer_source_addr6),
		.t_dst_6(transfer_dest_addr6),
		.t_en_7(transfer_enable7),
		.t_src_7(transfer_source_addr7),
		.t_dst_7(transfer_dest_addr7),
		.r_en_0(read_enable0),
		.xxtrig(xxtrig));
`endif
endmodule
