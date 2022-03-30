
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


#include <stdio.h>
#include <stdlib.h>

#define NRESOLVE 8
int B=30;

void
px(int k)
{
    int i;
    for (i = 0; i < k; i++)
        printf("    ");
}

int popcount(int x)
{
	int count = 0;
	int i;
	for (i = 0;i<B;i++)
	if (x&(1<<i))
		count++;
	return count;
}

int ffs(int x)
{
	int i;
	for (i = B-1;i >=0;i--)
	if (x&(1<<i))
		return i;
	return 99;
}


int main(int argc, char ** argv)
{
	int m,n, i,j,k,l,t;

	printf("//\n");
	printf("// RVOOM! Risc-V superscalar O-O\n");
	printf("// Copyright (C) 2019-22 Paul Campbell - paul@taniwha.com\n");
	printf("//\n");
	printf("// This program is free software: you can redistribute it and/or modify\n");
	printf("// it under the terms of the GNU General Public License as published by\n");
	printf("// the Free Software Foundation, either version 3 of the License, or\n");
	printf("// (at your option) any later version.\n");
	printf("//\n");
	printf("// This program is distributed in the hope that it will be useful,\n");
	printf("// but WITHOUT ANY WARRANTY; without even the implied warranty of\n");
	printf("// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n");
	printf("// GNU General Public License for more details.\n");
	printf("//\n");
	printf("// You should have received a copy of the GNU General Public License\n");
	printf("// along with this program.  If not, see <http://www.gnu.org/licenses/>.\n");
	printf("//\n");


	printf("module ic1_xdata(\n");	
	printf("	input clk,\n");
	printf("	input wen,\n");
	printf("	input [5:0]waddr,\n");
	printf("	input [511:0]din,\n");
	printf("	input [NPHYS-1:12]tin,\n");
	printf("	input [5:0]raddr_0,\n");
	printf("	output [511:0]dout_0,\n");
	printf("	output [NPHYS-1:12]tout_0,\n");
	printf("	input [5:0]raddr_1,\n");
	printf("	output [511:0]dout_1,\n");
	printf("	output [NPHYS-1:12]tout_1,\n");
	printf("	input [5:0]raddr_2,\n");
	printf("	output [NPHYS-1:12]tout_2,\n");
	printf("	output [NPHYS-1:12]tout_3);\n");
	printf("	parameter NPHYS=55;\n");
	printf("	genvar i;\n");
	printf("	generate\n");
	printf("		for (i = 12; i < NPHYS; i=i+1) begin\n");
	printf("			RAM64M t(");
	printf(".ADDRA(raddr_0),");
        printf(".ADDRB(raddr_1),");
        printf(".ADDRC(raddr_2),");
        printf(".ADDRD(waddr),");
        printf(".DIA(tin[i]),");
        printf(".DIB(tin[i]),");
        printf(".DIC(tin[i]),");
        printf(".DID(tin[i]),");
        printf(".DOA(tout_0[i]),");
        printf(".DOB(tout_1[i]),");
        printf(".DOC(tout_2[i]),");
        printf(".DOD(tout_3[i]),");
        printf(".WCLK(clk),");
        printf(".WE(wen));\n");
	printf("		end\n");
	printf("		for (i = 0; i < 512; i=i+1) begin\n");
	printf("			RAM64M d(");
	printf(".ADDRA(raddr_0),");
       	printf(".ADDRB(raddr_1),");
       	printf(".ADDRC(6'b0),");
       	printf(".ADDRD(waddr),");
       	printf(".DIA(din[i]),");
       	printf(".DIB(din[i]),");
       	printf(".DIC(1'b0),");
       	printf(".DID(1'b0),");
       	printf(".DOA(dout_0[i]),");
       	printf(".DOB(dout_1[i]),");
       	printf(".WCLK(clk),");
       	printf(".WE(wen));\n");
	printf("		end\n");
	printf("	endgenerate\n");
	printf("endmodule\n");	
}
