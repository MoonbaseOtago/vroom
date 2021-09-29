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


#include <stdio.h>
#include <stdlib.h>

int B;

int ffs(int x)
{
	int i;
	for (i = B-1;i >=0;i--)
	if (x&(1<<i))
		return i;
	return 99;
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

int main(int argc, char ** argv)
{
	int n, i,j,k,t;

	printf("//\n");
	printf("// RVOOM! Risc-V superscalar O-O\n");
	printf("// Copyright (C) 2019-21 Paul Campbell - paul@taniwha.com\n");
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

	printf("	if (r_op[1]) begin :d8\n");
	printf("		reg [54:0]mantissa;\n");
	printf("		reg [11:0]exponent;\n");
	printf("		reg [11:0]e3;\n");
	printf("		reg [51:0]m3;\n");
	printf("		reg inc;\n");
	printf("		casez (m2) // synthesis full_case parallel_case\n");
	for (i = 63; i > 0; i--) {
	printf("		64'b");
		for (j = 63; j > i; j--)printf("0");
		printf("1");
		for (j = i-1; j >= 0; j--)printf("?");
		printf(": begin ");
		if (i > 55) {
			printf("mantissa={m2[%d:%d], |m2[%d:0]};", i-1, i-54, i-55);
		} else 
		if (i == 55) {
			printf("mantissa=m2[54:0];");
		} else {
			printf("mantissa={m2[%d:0], %d'b0};", i-1, 55-i);
		}
		printf("exponent=%d; ", 1023+i);
		printf(" end\n");
	}
	printf("		64'b");
	for (j = 63; j > 0; j--)printf("0");
	printf("1: begin ");
	printf("mantissa=55'b0;");
	printf("exponent=1023; ");
	printf(" end\n");
	printf("		default: begin mantissa=55'b0;exponent=0; end\n");
	printf("		endcase\n");
	printf("		case (r_rounding) //synthesis full_case parallel_case\n");
	printf("		0: inc = (mantissa[2:0]>4) || ((mantissa==4)&&mantissa[3]);\n");
	printf("		1: inc = 0;\n");
	printf("		2: inc = sign && (mantissa[2:0]!=0);\n");
	printf("		3: inc = !sign && (mantissa[2:0]!=0);\n");
	printf("		4: inc = mantissa[2:0]>=4;\n");
	printf("		endcase\n");
	printf("		m3 = (inc?mantissa[54:3]+1:mantissa[54:3]);\n");
	printf("		e3 = (inc && (mantissa[54:3]==52'hf_ffff_ffff_ffff)?exponent+1:exponent);\n");
	printf("		c_res = {sign, e3, m3};\n");
	printf("	end else begin :s8\n");
	printf("		reg [25:0]mantissa;\n");
	printf("		reg [7:0]exponent;\n");
	printf("		reg [7:0]e3;\n");
	printf("		reg [22:0]m3;\n");
	printf("		reg inc;\n");
	printf("		casez (m2[31:0]) // synthesis full_case parallel_case\n");
	for (i = 31; i > 0; i--) {
	printf("		32'b");
		for (j = 31; j > i; j--)printf("0");
		printf("1");
		for (j = i-1; j >= 0; j--)printf("?");
		printf(": begin ");
		if (i > 26) {
			printf("mantissa={m2[%d:%d], |m2[%d:0]};", i-1, i-25, i-26);
			
		} else 
		if (i == 26) {
			printf("mantissa={m2[25:0]};");
		} else {
			printf("mantissa={m2[%d:0], %d'b0};", i-1, 26-i);
		}
		printf("exponent=%d;", 127+i);
		printf(" end\n");
	}
	printf("		32'b");
	for (j = 31; j > 0; j--)printf("0");
	printf("1: begin ");
	printf("mantissa=26'b0;");
	printf("exponent=127; ");
	printf(" end\n");
	printf("		default: begin mantissa=26'b0;exponent=0; end\n");
	printf("		endcase\n");
	printf("		case (r_rounding) //synthesis full_case parallel_case\n");
	printf("		0: inc = (mantissa[2:0]>4) || ((mantissa==4)&&mantissa[3]);\n");
	printf("		1: inc = 0;\n");
	printf("		2: inc = sign && (mantissa[2:0]!=0);\n");
	printf("		3: inc = !sign && (mantissa[2:0]!=0);\n");
	printf("		4: inc = mantissa[2:0]>=4;\n");
	printf("		endcase\n");
	printf("		m3 = (inc?mantissa[25:3]+1:mantissa[25:3]);\n");
	printf("		e3 = (inc && (mantissa[25:3]==23'h7fffff)?exponent+1:exponent);\n");
	printf("		c_res = {32'hffff_ffff, sign, e3, m3};\n");
	printf("	end\n");
}
