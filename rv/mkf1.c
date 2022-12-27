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
        printf("		exponent_x = 'bx;\n");
        printf("		shifted_mantissa_1 = 'bx;\n");
        printf("		shifted_mantissa_2 = 'bx;\n");
        printf("		casez ({exp_gt, exp_eq}) // synthesis full_case parallel_case\n");
        printf("		2'b1?:begin\n");
        printf("		      	casez (sz) // synthesis full_case parallel_case\n");
        printf("		      	2'b1?: begin\n");
        printf("		      		case (exp_diff[10:6]) // synthesis full_case parallel_case\n");
	for (i = 1; i < 13; i++) {
	if (i <= 3) {
        printf("		      		5'd%d:shifted_mantissa_2 = {%d'b0, mantissa_2[55:%d],42'bx};\n",i,i,42+i);
	} else {
        printf("		      		5'd%d:shifted_mantissa_2 = {%d'b0, mantissa_2[55:%d],|mantissa_2[%d:42],42'bx};\n",i,i,43+i,42+i);
	}
	}
        printf("		      		default:shifted_mantissa_2 = {13'b0, |mantissa_2[55:42],42'bx};\n");
        //printf("		      		5'd%d:shifted_mantissa_2 = {10'b0, |mantissa_2[55:42],42'bx};\n", i);
        //printf("		      		default:shifted_mantissa_2 = {10'b1, 42'bx};\n");
        printf("		      		endcase\n");
        printf("		      	       end\n");
        printf("		      	2'b00: begin\n");
        printf("		      		case (exp_diff[10:3]) // synthesis full_case parallel_case\n");
	for (i = 1; i < 26; i++) {
	if (i <= 3) {
        printf("		      		8'd%d:shifted_mantissa_2 = {%d'b0, mantissa_2[55:%d],29'bx};\n",i,i,29+i);
	} else {
        printf("		      		8'd%d:shifted_mantissa_2 = {%d'b0, mantissa_2[55:%d],|mantissa_2[%d:32],29'bx};\n",i,i,30+i,29+i);
	}
	}
        printf("		      		default:shifted_mantissa_2 = {26'b0, |mantissa_2[55:32], 29'bx};\n");
        //printf("		      		8'd%d:shifted_mantissa_2 = {24'b0, 29'bx};\n", i);
        //printf("		      		default :shifted_mantissa_2 = {23'b0, |mantissa_2[55:32],29'bx};\n");
        printf("		      		endcase\n");
        printf("		      	       end\n");
        printf("		      	2'b?1: begin\n");
        printf("		      		case (exp_diff) // synthesis full_case parallel_case\n");
	for (i = 1; i < 55; i++) {
	if (i <= 3) {
        printf("		      		11'd%d:shifted_mantissa_2 = {%d'b0, mantissa_2[55:%d]};\n",i,i,i);
	} else {
        printf("		      		11'd%d:shifted_mantissa_2 = {%d'b0, mantissa_2[55:%d],|mantissa_2[%d:3]};\n",i,i,1+i,i);
	}
	}
        printf("		      		default:shifted_mantissa_2 = {55'b0, |mantissa_2[55:3]};\n");
        //printf("		      		11'd%d :shifted_mantissa_2 = {53'b0, |mantissa_2[55:3]};\n",i);
        //printf("		      		default :shifted_mantissa_2 = 54'b0;\n");
        printf("		      		endcase\n");
        printf("		      	       end\n");
        printf("		      	endcase\n");
        printf("		      	shifted_mantissa_1 = mantissa_1;\n");
        printf("		      	exponent_x = rexp_1;\n");
        printf("		      end\n");
        printf("		2'b00:begin\n");
        printf("		      	casez (sz) // synthesis full_case parallel_case\n");
        printf("		      	2'b1?: begin\n");
        printf("		      		case (exp_diff[10:6]) // synthesis full_case parallel_case\n");
	for (i = 1; i < 13; i++) {
	if (i <= 3) {
        printf("		      		5'h%x:shifted_mantissa_1 = {%d'b0, mantissa_1[55:%d],42'bx};\n",0x20-i,i,42+i);
	} else {
        printf("		      		5'h%x:shifted_mantissa_1 = {%d'b0, mantissa_1[55:%d],|mantissa_1[%d:42],42'bx};\n",0x20-i,i,43+i,42+i);
	}
	}
        printf("		      		default:shifted_mantissa_1 = {13'b0, |mantissa_1[55:42],42'bx};\n");
        //printf("		      		8'h%x:shifted_mantissa_1 = {10'b0, |mantissa_1[55:42],42'bx};\n", 0x100-i);
        //printf("		      		default :shifted_mantissa_1 = {11'b0, 42'bx};\n");
        printf("		      		endcase\n");
        printf("		      	       end\n");
        printf("		      	2'b00: begin\n");
        printf("		      		case (exp_diff[10:3]) // synthesis full_case parallel_case\n");
	for (i = 1; i < 26; i++) {
	if (i <= 3) {
        printf("		      		8'h%x:shifted_mantissa_1 = {%d'b0, mantissa_1[55:%d],29'bx};\n",0x100-i,i,29+i);
	} else {
        printf("		      		8'h%x:shifted_mantissa_1 = {%d'b0, mantissa_1[55:%d],|mantissa_1[%d:32],29'bx};\n",0x100-i,i,30+i,29+i);
	}
	}
        printf("		      		default:shifted_mantissa_1 = {26'b0, |mantissa_1[55:32],29'bx};\n");
        //printf("		      		8'h%x:shifted_mantissa_1 = {23'b0, |mantissa_1[55:32],29'bx};\n", 0x100-i);
        //printf("		      		default :shifted_mantissa_1 = {24'b0, 29'bx};\n");
        printf("		      		endcase\n");
        printf("		      	       end\n");
        printf("		      	2'b?1: begin\n");
        printf("		      		case (exp_diff) // synthesis full_case parallel_case\n");
        //printf("		      		11'h%x:shifted_mantissa_1 = mantissa_1;\n",0x800-0);
	for (i = 1; i < 55; i++) {
	if (i <= 3) {
        //printf("		      		11'h%x:shifted_mantissa_1 = {%d'b0, mantissa_1[55:%d]};\n",0x800-i,i,i);
        printf("		      		11'h%x:shifted_mantissa_1 = {%d'b0, mantissa_1[55:%d],|mantissa_1[%d:0]};\n",0x800-i,i,1+i,i);
	} else {
        printf("		      		11'h%x:shifted_mantissa_1 = {%d'b0, mantissa_1[55:%d],|mantissa_1[%d:3]};\n",0x800-i,i,1+i,i);
	}
	}
        printf("		      		default:shifted_mantissa_1 = {55'b0, |mantissa_1[55:3]};\n");
        //printf("		      		11'h%x:shifted_mantissa_1 = {53'b0, |mantissa_1[55:3]};\n", 0x800-i);
        //printf("		      		default :shifted_mantissa_1 = 54'b0;\n");
        printf("		      		endcase\n");
        printf("		      	       end\n");
        printf("		      	endcase\n");
        printf("		      	shifted_mantissa_2 = mantissa_2;\n");
        printf("		      	exponent_x = rexp_2;\n");
        printf("		      end\n");
        printf("		      2'b?1:begin\n");
        printf("		      	shifted_mantissa_1 = mantissa_1;\n");
        printf("		      	shifted_mantissa_2 = mantissa_2;\n");
        printf("		      	exponent_x = rexp_2;\n");
        printf("		      end\n");
        printf("		endcase\n");
        printf("	end\n");
}
