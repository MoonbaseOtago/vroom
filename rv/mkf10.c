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

        printf("	always @(*)\n");
        printf("	casez (mantissa_1) // synthesis full_case parallel_case\n");
	for (i = 0; i < 53; i++) {
	printf("	53'b");
	for (j = 0; j < 53; j++) printf(i==j?"1":i<j?"?":"0");
	printf(": m1_shl = %d;\n", i);
	}
        printf("	default: m1_shl = 'bx;\n");
        printf("	endcase\n\n");

        printf("	always @(*)\n");
        printf("	casez (m1_shlx) // synthesis full_case parallel_case\n");
	printf("	0: mantissa_sh_1 = mantissa_1;\n");
	for (i=1; i < 53; i++) 
	printf("	%d: mantissa_sh_1 = {mantissa_1[%d:0], %d'b0};\n", i, 52-i, i);
	printf("	default: mantissa_sh_1 = 'bx;\n");
        printf("	endcase\n\n");

        printf("	always @(*)\n");
        printf("	casez (mantissa_2) // synthesis full_case parallel_case\n");
	for (i = 0; i < 53; i++) {
	printf("	53'b");
	for (j = 0; j < 53; j++) printf(i==j?"1":i<j?"?":"0");
	printf(": m2_shl = %d;\n", i);
	}
        printf("	default: m2_shl = 'bx;\n");
        printf("	endcase\n\n");

        printf("	always @(*)\n");
        printf("	casez (m2_shl) // synthesis full_case parallel_case\n");
	printf("	0: mantissa_sh_2 = mantissa_2;\n");
	for (i=1; i < 53; i++) 
	printf("	%d: mantissa_sh_2 = {mantissa_2[%d:0], %d'b0};\n", i, 52-i, i);
	printf("	default: mantissa_sh_2 = 'bx;\n");
        printf("	endcase\n\n");

}
