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

	printf("		casez (t2) // synthesis full_case parallel_case\n");
	for (i = 63; i > 0; i--) {
	printf("		64'b");
		for (j = 63; j > i; j--)printf("0");
		printf("1");
		for (j = i-1; j >= 0; j--)printf("?");
		printf(": begin ");
		if (i > 55) {
			printf("mantissa={t2[%d:%d], |t2[%d:0]};", i-1, i-54, i-55);
		} else 
		if (i == 55) {
			printf("mantissa=t2[54:0];");
		} else {
			printf("mantissa={t2[%d:0], %d'b0};", i-1, 55-i);
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
	printf("		64'b");
	for (j = 63; j >= 0; j--)printf("0");
	printf(": begin ");
	printf("mantissa=55'b0;");
	printf("exponent=0; ");
	printf(" end\n");
	printf("		endcase\n");
}
