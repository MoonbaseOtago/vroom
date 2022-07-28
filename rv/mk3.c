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

	printf("`ifdef FP\n");
	printf("	assign rename_match = {");
	for (i = 0; i < B; i++) 
		printf("(all_rd_rename[%d]==R)&(all_rd_fp_rename[%d]==is_fp)&all_makes_rd_rename[%d]%s", i, i, i, i==(B-1)?"};\n":", ");
	printf("`else\n");
	printf("	assign rename_match = {");
	for (i = 0; i < B; i++) 
		printf("(all_rd_rename[%d]==R)&all_makes_rd_rename[%d]%s", i, i, i==(B-1)?"};\n":", ");
	printf("`endif\n");
	printf("`ifdef RENAME_OPT\n");
	for (i = B-2; i >= 0 ; i--) {
	printf("	wire [%d:1]move_match_%d = {", (B-i)-1, (B-i)-1);
	for (j = B-1; j > i; j--) printf("%smap_is_move_rename[%d]&&(all_rd_rename[%d]==map_is_move_reg_rename[%d])", j==(B-1)?"":",", (B-1)-i, (B-1)-j, (B-1)-i);
	printf("};\n");
	}
	printf("`endif\n");
	
	printf("		always @(*) begin\n");
	printf("			rename_result = 'bx;\n"); 
	printf("			rename_match_valid = 1;\n"); 
	printf("`ifdef RENAME_OPT\n");
	printf("			rename_is_0 = 'bx;\n");
	printf("			rename_is_move = 'bx;\n");
	printf("			rename_is_move_reg = 'bx;\n");
	printf("`endif\n");
	printf("			casez (rename_match) // synthesis full_case parallel_case\n");
	for (i = B-1; i >= 0; i--) {
		printf("			%d'b", B);
		for (j = B-1; j >= 0; j--) 
			printf(i==j?"1":j>i?"?":"0");
		printf(": begin\n");
		printf("						rename_result = map_rd_rename[%d];\n",  B-i-1 );
		printf("`ifdef RENAME_OPT\n");
		printf("						rename_is_0 = map_is_0_rename[%d];\n",  B-i-1 );
		printf("						rename_is_move = map_is_move_rename[%d];\n",  B-i-1 );
		if (i == B-1) {
		printf("						rename_is_move_reg = map_is_move_reg_rename[%d];\n",  B-i-1 );
		} else {
		printf("						casez ({");
		//for (j = B-1; j > i; j--) printf("%smap_is_move_rename[%d]&&(all_rd_rename[%d]==R)", j==(B-1)?"":",", (B-1)-i, (B-1)-j);
		printf("move_match_%d", B-i-1);
		printf("}) // synthesis full_case parallel_case\n");
		for (j = B-1; j > i; j--) {
		printf("						%d'b", (B-1)-i);
		for (k = B-1; k > i; k--) printf(k == j?"1":k > j ?"?":"0");
		printf(": rename_is_move_reg = {1'b1, map_rd_rename[%d]};\n", (B-1)-j);
		}
		printf("						default: rename_is_move_reg = map_is_move_reg_rename[%d];\n",  B-i-1 );
		printf("						endcase\n");
		}
		printf("`endif\n");
		printf("					end\n");
	}
	printf("			%d'd0: begin\n", B);
	printf("					rename_match_valid=0;\n");
	printf("			       end\n");
	printf("			endcase\n");
	printf("		end\n");
}
