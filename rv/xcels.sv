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
module ic1_xdata(
	input clk,
	input wen,
	input [5:0]waddr,
	input [511:0]din,
	input [NPHYS-1:12]tin,
	input [5:0]raddr_0,
	output [511:0]dout_0,
	output [NPHYS-1:12]tout_0,
	input [5:0]raddr_1,
	output [511:0]dout_1,
	output [NPHYS-1:12]tout_1,
	input [5:0]raddr_2,
	output [NPHYS-1:12]tout_2,
	output [NPHYS-1:12]tout_3);
	parameter NPHYS=55;
	genvar I;
	generate
		for (I = 12; I < NPHYS; I=I+1) begin
			RAM64M t(.ADDRA(raddr_0),.ADDRB(raddr_1),.ADDRC(raddr_2),.ADDRD(waddr),.DIA(tin[I]),.DIB(tin[I]),.DIC(tin[I]),.DID(tin[I]),.DOA(tout_0[I]),.DOB(tout_1[I]),.DOC(tout_2[I]),.DOD(tout_3[I]),.WCLK(clk),.WE(wen));
		end
		for (I = 0; I < 512; I=I+1) begin
			RAM64M d(.ADDRA(raddr_0),.ADDRB(raddr_1),.ADDRC(6'b0),.ADDRD(waddr),.DIA(din[I]),.DIB(din[I]),.DIC(1'b0),.DID(1'b0),.DOA(dout_0[I]),.DOB(dout_1[I]),.WCLK(clk),.WE(wen));
		end
	endgenerate
endmodule


module tc2_xdata(
	input clk,
	input wen,
	input [$clog2(NENTRIES)-1:0]waddr,
	input [NPHYS:12]pin,
	input [VA_SZ-1:12+$clog2(NENTRIES)]vin,
	input [6:0]gin,
	input [$clog2(NENTRIES)-1:0]raddr_0,
	output [NPHYS:12]pout_0,
	output [VA_SZ-1:12+$clog2(NENTRIES)]vout_0,
	output [6:0]gout_0,
	input [$clog2(NENTRIES)-1:0]raddr_1,
	output [VA_SZ-1:12+$clog2(NENTRIES)]vout_1);

	parameter NPHYS = 44;
	parameter VA_SZ = 56;
	parameter NENTRIES=256;

	genvar I, J;
	wire [NPHYS:12]pout[0:(NENTRIES/64)-1];
	wire [VA_SZ-1:12+$clog2(NENTRIES)]vout0[0:(NENTRIES/64)-1];
	wire [VA_SZ-1:12+$clog2(NENTRIES)]vout1[0:(NENTRIES/64)-1];
	wire [6:0]gout[0:(NENTRIES/64)-1];
	assign pout_0 = pout[raddr_0[$clog2(NENTRIES)-1:6]];
	assign vout_0 = vout0[raddr_0[$clog2(NENTRIES)-1:6]];
	assign gout_0 = gout[raddr_0[$clog2(NENTRIES)-1:6]];
	assign vout_1 = vout1[raddr_0[$clog2(NENTRIES)-1:6]];
	generate
		for (J = 0; J < (NENTRIES/64); J = J + 1) begin
			wire wenx = wen && waddr[$clog2(NENTRIES)-1:6] == J;

			for (I = 0; I < 6; I=I+3) begin
				RAM64M g(.ADDRA(raddr_0[5:0]),.ADDRB(raddr_0[5:0]),.ADDRC(raddr_0[5:0]),.ADDRD(waddr[5:0]),.DIA(gin[I]),.DIB(gin[I+1]),.DIC(gin[I+2]),.DID(1'b0),.DOA(gout[J][I]),.DOB(gout[J][I+1]),.DOC(gout[J][I+2]),.WCLK(clk),.WE(wenx));
			end
			RAM64M g(.ADDRA(raddr_0[5:0]),.ADDRB(6'b0),.ADDRC(6'b0),.ADDRD(waddr[5:0]),.DIA(gin[6]),.DIB(1'b0),.DIC(1'b0),.DID(1'b0),.DOA(gout[J][6]),.WCLK(clk),.WE(wenx));

			for (I = 12; I < (NPHYS-1); I=I+3) begin
				RAM64M p(.ADDRA(raddr_0[5:0]),.ADDRB(raddr_0[5:0]),.ADDRC(raddr_0[5:0]),.ADDRD(waddr[5:0]),.DIA(pin[I]),.DIB(pin[I+1]),.DIC(pin[I+2]),.DID(1'b0),.DOA(pout[J][I]),.DOB(pout[J][I+1]),.DOC(pout[J][I+2]),.WCLK(clk),.WE(wenx));
			end
			if ((((NPHYS+1-12)%3)) == 2) begin
				RAM64M p(.ADDRA(raddr_0[5:0]),.ADDRB(raddr_0[5:0]),.ADDRC(6'b0),.ADDRD(waddr[5:0]),.DIA(pin[NPHYS]),.DIB(pin[NPHYS-1]),.DIC(1'b0),.DID(1'b0),.DOA(pout[J][NPHYS]),.DOB(pout[J][NPHYS-1]),.WCLK(clk),.WE(wenx));
			end else
			if ((((NPHYS+1-12)%3)) == 1) begin
				RAM64M p(.ADDRA(raddr_0[5:0]),.ADDRB(6'b0),.ADDRC(6'b0),.ADDRD(waddr[5:0]),.DIA(pin[NPHYS]),.DIB(1'b0),.DIC(1'b0),.DID(1'b0),.DOA(pout[J][NPHYS]),.WCLK(clk),.WE(wenx));
			end 

			for (I = 12+$clog2(NENTRIES); I < (VA_SZ-2); I=I+3) begin
				RAM64M v0(.ADDRA(raddr_0[5:0]),.ADDRB(raddr_0[5:0]),.ADDRC(raddr_0[5:0]),.ADDRD(waddr[5:0]),.DIA(vin[I]),.DIB(vin[I+1]),.DIC(vin[I+2]),.DID(1'b0),.DOA(vout0[J][I]),.DOB(vout0[J][I+1]),.DOC(vout0[J][I+2]),.WCLK(clk),.WE(wenx));
				RAM64M v1(.ADDRA(raddr_1[5:0]),.ADDRB(raddr_1[5:0]),.ADDRC(raddr_1[5:0]),.ADDRD(waddr[5:0]),.DIA(vin[I]),.DIB(vin[I+1]),.DIC(vin[I+2]),.DID(1'b0),.DOA(vout1[J][I]),.DOB(vout1[J][I+1]),.DOC(vout1[J][I+2]),.WCLK(clk),.WE(wenx));
			end
			if ((((VA_SZ-12-$clog2(NENTRIES))%3)) == 2) begin
				RAM64M v0(.ADDRA(raddr_0[5:0]),.ADDRB(raddr_0[5:0]),.ADDRC(6'b0),.ADDRD(waddr[5:0]),.DIA(vin[VA_SZ-1]),.DIB(vin[VA_SZ-2]),.DIC(1'b0),.DID(1'b0),.DOA(vout0[J][VA_SZ-1]),.DOB(vout0[J][VA_SZ-2]),.WCLK(clk),.WE(wenx));
				RAM64M v1(.ADDRA(raddr_1[5:0]),.ADDRB(raddr_1[5:0]),.ADDRC(6'b0),.ADDRD(waddr[5:0]),.DIA(vin[VA_SZ-1]),.DIB(vin[VA_SZ-2]),.DIC(1'b0),.DID(1'b0),.DOA(vout1[J][VA_SZ-1]),.DOB(vout1[J][VA_SZ-2]),.WCLK(clk),.WE(wenx));
			end else
			if ((((VA_SZ-12-$clog2(NENTRIES))%3)) == 1) begin
				RAM64M v0(.ADDRA(raddr_0[5:0]),.ADDRB(6'b0),.ADDRC(6'b0),.ADDRD(waddr[5:0]),.DIA(vin[VA_SZ-1]),.DIB(1'b0),.DIC(1'b0),.DID(1'b0),.DOA(vout0[J][VA_SZ-1]),.WCLK(clk),.WE(wenx));
				RAM64M v1(.ADDRA(raddr_1[5:0]),.ADDRB(6'b0),.ADDRC(6'b0),.ADDRD(waddr[5:0]),.DIA(vin[VA_SZ-1]),.DIB(1'b0),.DIC(1'b0),.DID(1'b0),.DOA(vout1[J][VA_SZ-1]),.WCLK(clk),.WE(wenx));
			end
		end
	endgenerate
endmodule

module dc1_xdata(
	input clk,
	input wen,
	input [63:0]wenb,
	input [5:0]waddr0,
	input [5:0]waddr1,
	input [511:0]din0,
	input [511:0]din1,
	input [5:0]raddr_0,
	output [511:0]dout_0,
	input [5:0]raddr_1,
	output [511:0]dout_1,
	input [5:0]raddr_2,
	output [511:0]dout_2,
	output [511:0]dout_3);
	parameter NPHYS=55;

	wire [63:0]we = (wen?~64'b0:wenb);
	wire [511:0]d = (wen?din0:din1);
	wire [5:0]waddr = (wen?waddr0:waddr1);
	genvar I, J;
	generate
		for (I = 0; I < 512; I=I+1) begin
			RAM64M dd(.ADDRA(raddr_0),.ADDRB(raddr_1),.ADDRC(raddr_2),.ADDRD(waddr),.DIA(d[I]),.DIB(d[I]),.DIC(d[I]),.DID(d[I]),.DOA(dout_0[I]),.DOB(dout_1[I]),.DOC(dout_2[I]),.DOD(dout_3[I]),.WCLK(clk),.WE(we[I/8]));
		end
	endgenerate
endmodule
module dc1_tdata(
	input clk,
	input wen,
	input [5:0]waddr,
	input [NPHYS-1:12]din,
	input [5:0]raddr_0,
	output [NPHYS-1:12]dout_0,
	input [5:0]raddr_1,
	output [NPHYS-1:12]dout_1,
	input [5:0]raddr_2,
	output [NPHYS-1:12]dout_2,
	input [5:0]raddr_3,
	output [NPHYS-1:12]dout_3,
	output [NPHYS-1:12]dout_4);

	parameter NPHYS=55;

	genvar I, J;
	generate
		for (I = 12; I < NPHYS; I=I+1) begin
			RAM64M d0(.ADDRA(raddr_0),.ADDRB(raddr_1),.ADDRC(6'b0),.ADDRD(waddr),.DIA(din[I]),.DIB(din[I]),.DIC(1'b0),.DID(din[I]),.DOA(dout_0[I]),.DOB(dout_1[I]),.DOD(dout_4[I]),.WCLK(clk),.WE(wen));
			RAM64M d1(.ADDRA(raddr_2),.ADDRB(raddr_3),.ADDRC(6'b0),.ADDRD(waddr),.DIA(din[I]),.DIB(din[I]),.DIC(1'b0),.DID(1'b0),.DOA(dout_2[I]),.DOB(dout_3[I]),.WCLK(clk),.WE(wen));
		end
	endgenerate
endmodule
