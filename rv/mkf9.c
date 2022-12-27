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

	// 105-52 = 105:54:
	// 105-21 = 105:85:
        printf("	always @(*)\n");
        printf("	casez ({!r_b_muladd||eq, r_b_muladd&&gt}) // synthesis full_case parallel_case\n");
	printf("	2'b1?: begin\n");
        printf("		mantissa_s = {1'b0, mantissa_m, 3'b0};\n");
        printf("		mantissa_s_3 = {r_b_mantissa_3[56], r_b_mantissa_3, 52'b0};\n");
        printf("	       end\n");
	printf("	2'b?1: begin\n");
        printf("		mantissa_s_3 = {r_b_mantissa_3[56], r_b_mantissa_3, 52'b0};\n");
        printf("		case (mdiff) // synthesis full_case parallel_case\n");
        printf("	      	1: mantissa_s = {2'b0, mantissa_m, 2'b0};\n");
        printf("	      	2: mantissa_s = {3'b0, mantissa_m, 1'b0};\n");
        printf("	      	3: mantissa_s = {4'b0, mantissa_m};\n");
	for (i = 4; i < 108; i++) 
        printf("	      	%d: mantissa_s = {%d'b0, mantissa_m[105:%d], |mantissa_m[%d:0]};\n", i, i+1, i-2, i-3);
        printf("	      	default: mantissa_s = {109'b0, |mantissa_m};\n");
        printf("		endcase\n");
        printf("	       end\n");
        printf("	2'b00: begin\n");
        printf("	      	mantissa_s = {1'b0, mantissa_m, 3'b0};\n");
        printf("		case (~mdiff) // synthesis full_case parallel_case\n");
        //printf("		12'hfff: mantissa_s_3 = {r_b_mantissa_3, 53'b0};\n");
        //printf("	      	0: mantissa_s_3 = {r_b_mantissa_3, 53'b0};\n");
	for (i = 1; i < 52; i++) 
        printf("	      	%d: mantissa_s_3 = {{%d{r_b_mantissa_3[56]}}, r_b_mantissa_3, %d'b0};\n", i-1, i+1, 52-i);
	for (i = 52; i < 108; i++) 
        printf("	      	%d: mantissa_s_3 = {{%d{r_b_mantissa_3[56]}}, r_b_mantissa_3[56:%d], |r_b_mantissa_3[%d:0]};\n", i-1, i+1, i-51, i-52);
        printf("	      	default: mantissa_s_3 = {{109{r_b_mantissa_3[56]}}, |r_b_mantissa_3};\n");
        printf("		endcase\n");
        printf("	       end\n");
        printf("	endcase\n\n");
}
