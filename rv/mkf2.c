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


        printf("	always @(*) begin\n");
        printf("		shr = 0;\n");
        printf("		shl_x = 0;\n");
	printf("		if (mantissa_y[56]) begin shr = 1; end else\n");
        printf("		if (r_b_sz) begin\n");
        printf("			casez (mantissa_y[55:0]) // synthesis full_case parallel_case\n");
	for (i = 55; i >= 0; i--) {
        printf("		      	56'b");
	for (j = 55; j >= 0; j--) printf(j > i?"0":j==i?"1":"?");
	printf(": shl_x = %d;\n", 55-i);
	}
	printf("			56'b0: shl_x = 0;\n");
        printf("	      		endcase\n");
        printf("	      	end else begin\n");
        printf("			casez (mantissa_y[55:29]) // synthesis full_case parallel_case\n");
	for (i = 55; i >= 29; i--) {
        printf("		      	27'b");
	for (j = 55; j >= 29; j--) printf(j > i?"0":j==i?"1":"?");
	printf(": shl_x = %d;\n", 55-i);
	}
	printf("			27'b0: shl_x = 0;\n");
        printf("	      		endcase\n");
        printf("		end\n");
        printf("	end\n");
        printf("	always @(*) begin\n");
        printf("		if (shr) begin\n");
        printf("			if (r_b_sz) begin\n");
        printf("				mantissa_z = {mantissa_y[56:2], |mantissa_y[1:0]};\n");
        printf("			end else begin\n");
        printf("				mantissa_z = {mantissa_y[56:31], |mantissa_y[30:29], 29'bx};\n");
        printf("			end \n");
        printf("		end else begin\n");
        printf("			if (r_b_sz) begin\n");
        printf("				case (shl) // synthesis full_case parallel_case\n");
        printf("		      		0: mantissa_z = mantissa_y[55:0];\n");
	for (i = 1; i < 56; i++) 
        printf("		      		%d: mantissa_z = {mantissa_y[%d:0], %d'b0};\n",i,55-i,i);
        printf("		      		default: mantissa_z = 0;\n");
        printf("	      			endcase\n");
        printf("			end else begin\n");
        printf("				case (shl) // synthesis full_case parallel_case\n");

        printf("		      		0: mantissa_z = {mantissa_y[55:29], 29'bx};\n");
	for (i = 1; i < 27; i++) 
        printf("		      		%d: mantissa_z = {mantissa_y[%d:29], %d'b0, 29'bx};\n",i,55-i,i);
        printf("		      		default: mantissa_z = {27'b0, 29'bx};\n");
        printf("	      			endcase\n");
        printf("			end\n");
        printf("		end\n");
        printf("	end\n");
}
