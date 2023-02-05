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

char tt[100];
char *bin(int v, int l)
{
	int i;
	char *cp=&tt[0];
	for (i = l-1; i >= 0; i--) 
		*cp++ = (v&(1<<i)?'1':'0');
	*cp = 0;
	return &tt[0];
}

int main(int argc, char ** argv)
{
	int i,j,k,t;

	if (argc < 2) {
		B = 8;
	} else {
		B = strtol((const char *)argv[1], 0, 0);
	}
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

	printf("// clmul*\n");
	printf("`ifdef B\n");
	printf("	wire [63:0]xr1 = r1;\n");
	printf("	wire [63:0]xr2 = r2;\n");
	for (i = 0; i < B; i += 8) {
	printf("	reg [%d:%d]r_clm_%d;\n", B+i+6, i, i);
	printf("	always @(posedge clk)\n");
	printf("		r_clm_%d <= \n", i);
	printf("			{7'b0, (xr1[%d:%d]&{%d{xr2[%d]%s}})}^\n", B-1, 0, B, i+0, ((i+7) >= 32?"":""));
	for (j = 1; j < 7; j++)
	printf("			{%d'b0, (xr1[%d:%d]&{%d{xr2[%d]%s}}),%d'b0}^\n", 7-j, B-1, 0, B, i+j, ((i+j) >= 32?"":""),  j);
	printf("			{(xr1[%d:%d]&{%d{xr2[%d]%s}}),7'b0};\n", B-1, 0, B, i+7, ((i+7) >= 32?"":""));
	}
	printf("	wire [%d-2:0]clmul_res = {%d'b0, r_clm_0}^\n", 2*B, B-1);
	for (i = 8; i < (B-8); i += 8) 
	printf("	                         {%d'b0, r_clm_%d, %d'b0}^\n", B-i-1, i, i);
	printf("	                         {r_clm_%d, %d'b0};\n", i, i);
	printf("	wire [%d:0]clmul_res_rev = {", B-1);
	for (i = 0; i <B; i++) printf("clmul_res[%d]%s",i,i==(B-1)?"};\n":",");
	printf("`endif\n");
}
