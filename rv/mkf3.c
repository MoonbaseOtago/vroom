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

	// 105-52 = 105:54:
	// 105-21 = 105:85:
        printf("	always @(*) begin\n");
        printf("		shl_x = 0;\n");
        printf("		shr_x = 0;\n");
	printf("		if (r_c_mantissa[105]) begin\n");
        printf("			shr_x = 1;\n");
        printf("	      	end else\n");
        printf("		if (r_c_sz) begin\n");
        printf("			casez (r_c_mantissa[104:53]) // synthesis full_case parallel_case\n");
	for (i = 105; i >= 54; i--) {
        printf("		      	52'b");
	for (j = 105; j >= 54; j--) printf(j > i?"0":j==i?"1":"?");
	printf(": shl_x = %d;\n", 105-i);
	}
	printf("			52'b0: shl_x = 0;\n");
        printf("	      		endcase\n");
        printf("	      	end else begin\n");
        printf("			casez (r_c_mantissa[104:82]) // synthesis full_case parallel_case\n");
	for (i = 105; i >= 83; i--) {
        printf("		      	23'b");
	for (j = 105; j >= 83; j--) printf(j > i?"0":j==i?"1":"?");
	printf(": shl_x = %d;\n", 105-i);
	}
	printf("			23'b0: shl_x = 0;\n");
        printf("	      		endcase\n");
        printf("		end\n");
        printf("	end\n");
        printf("	always @(*) begin\n");
	printf("		if (shr) begin\n");
        printf("			if (r_c_sz) begin\n");
        printf("				case (shr) // synthesis full_case parallel_case\n");
        printf("		      		1: mantissa_z = {r_c_mantissa[105:51], |r_c_mantissa[50:0]};\n");
	for (i = 2; i < 56; i++) 
        printf("		      		%d: mantissa_z = {%d'b0, r_c_mantissa[105:%d], |r_c_mantissa[%d:0]};\n",i,i-1, 50+i,49+i);
        printf("		      		default: mantissa_z = {55'b0,|r_c_mantissa};\n");
        printf("		      		endcase\n");
	printf("			end else begin\n");
        printf("				case (shr) // synthesis full_case parallel_case\n");
        printf("		      		1: mantissa_z = {r_c_mantissa[105:80], |r_c_mantissa[79:58], 29'bx};\n");
	for (i = 2; i < 27; i++) 
        printf("		      		%d: mantissa_z = {%d'b0, r_c_mantissa[105:%d], |r_c_mantissa[%d:58], 29'bx};\n",i,i-1, 79+i,78+i);
        printf("		      		default: mantissa_z = {26'b0, |r_c_mantissa[105:58], 29'bx};\n");
        printf("		      		endcase\n");
        //printf("	      			mantissa_z = {r_c_mantissa[105:80], |r_c_mantissa[79:58], 29'bx};\n");
	printf("			end\n");
	printf("		end else begin\n");
        printf("			if (r_c_sz) begin\n");
        printf("				case (shl) // synthesis full_case parallel_case\n");
	for (i = 0; i < 50; i++) 
        printf("		      		%d: mantissa_z = {r_c_mantissa[%d:%d], |r_c_mantissa[%d:0]};\n",i,104-i,104-i-54, 104-i-55);
        printf("				50: mantissa_z = {r_c_mantissa[55:0], 1'b0};\n");
        printf("				51: mantissa_z = {r_c_mantissa[54:0], 2'b0};\n");
        printf("				52: mantissa_z = {r_c_mantissa[53:0], 3'b0};\n");
        printf("		      		default: mantissa_z = 0;\n");
        printf("		      		endcase\n");
        printf("			end else begin\n");
        printf("				case (shl) // synthesis full_case parallel_case\n");
	for (i = 0; i < 21; i++) 
        printf("		      		%d: mantissa_z = {r_c_mantissa[%d:%d], |r_c_mantissa[%d:58],29'bx};\n",i,104-i,104-i-25, 104-i-26);
        printf("		      		21: mantissa_z = {r_c_mantissa[83:58],1'b0,29'bx};\n");
        printf("		      		22: mantissa_z = {r_c_mantissa[82:58],2'b0,29'bx};\n");
        printf("		      		23: mantissa_z = {r_c_mantissa[81:58],3'b0,29'bx};\n");
        printf("		      		default: mantissa_z = {27'b0, 29'bx};\n");
        printf("		      		endcase\n");
        printf("			end\n");
        printf("		end\n");
        printf("	end\n");
}
