//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-23 Paul Campbell - paul@taniwha.com
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
	printf("// Copyright (C) 2019-23 Paul Campbell - paul@taniwha.com\n");
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

	// 105-52 = 105:54:
	// 105-21 = 105:85:
        printf("	always @(*) begin\n");
        printf("		shl_x = 0;\n");
        printf("		casez (mantissa_n[56:0]) // synthesis full_case parallel_case\n");
	for (i = 56; i >= 0; i--) {
        printf("	      	57'b");
	for (j = 56; j >= 0; j--) printf(j > i?"0":j==i?"1":"?");
	printf(": shl_x = %d;\n", 56-i);
	}
	printf("		57'b0: shl_x = 0;\n");
        printf("	      	endcase\n");
        printf("	end\n");
        printf("	always @(*) begin\n");
	printf("		if (shr!=0) begin\n");
        printf("			case (shr) // synthesis full_case parallel_case\n");
        printf("	      		0: mantissa_z = 57'bx;\n");
        printf("	      		1: mantissa_z = {1'b0, mantissa_n[56:3], |mantissa_n[2:0]};\n");
	for (i = 2; i < 55; i++) 
        printf("	      		%d: mantissa_z = {%d'b0, mantissa_n[56:%d], |mantissa_n[%d:0]};\n",i,i, i+2,i+1);
        printf("	      		default: mantissa_z = {55'b0,|mantissa_n};\n");
        printf("	      		endcase\n");
	printf("		end else begin\n");
        printf("			case (shl) // synthesis full_case parallel_case\n");
        printf("			0: mantissa_z = {mantissa_n[56:2], |mantissa_n[1:0]};\n");
        printf("			1: mantissa_z = {mantissa_n[55:0]};\n");
	for (i = 2; i < 57; i++) 
        printf("			%d: mantissa_z = {mantissa_n[%d:0], %d'b0};\n", i,56-i, i-1);
        printf("	      		default: mantissa_z = 0;\n");
        printf("	      		endcase\n");
        printf("		end\n");
        printf("	end\n");
}
