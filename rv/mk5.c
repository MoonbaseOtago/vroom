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

	printf("	always @(*) begin\n");
	printf("		makes_rd = 1'bx;\n");
	printf("		needs_rs2 = 1'bx;\n");
	printf("		needs_rs3 = 1'bx;\n");
	printf("		pc_rn = 63'bx;\n");
	printf("		pc_dest_rn = 63'bx;\n");
	printf("		real_rd = 'bx;\n");
	printf("		real_rs1 = 'bx;\n");
	printf("		real_rs2 = 'bx;\n");
	printf("		real_rs3 = 'bx;\n");
	printf("		rs1 = 'bx;\n");
	printf("		rs2 = 'bx;\n");
	printf("		rs3 = 'bx;\n");
	printf("		control = 'bx;\n");
	printf("		unit_type = 'bx;\n");
	printf("		immed = 'bx;\n");
	printf("		start = 'bx;\n");
	printf("		short = 'bx;\n");
	printf("		branch_token = 'bx;\n");
	printf("		branch_token_ret = 'bx;\n");
	printf("		casez ({");
	for (i = 0; i < B; i++)
		printf("(rd_rename[%d]==C)&valid_rename[%d]%s", i, i, (i==(B-1))?"":",");
	printf("}) // synthesis full_case parallel_case\n");
	for (i = 0; i < B; i++) {
		printf("		%d'b", B);
		for (j = 0; j < B; j++)
			printf(i==j?"1":"?");
		printf(": begin\n ");
		printf("			xload = 1;\n");
		printf("			makes_rd = makes_rd_rename[%d];\n",i);
		printf("			needs_rs2 = needs_rs2_rename[%d];\n",i);
		printf("			needs_rs3 = needs_rs3_rename[%d];\n",i);
		printf("			rd_fp = rd_fp_rename[%d];\n",i);
		printf("			rs1_fp = rs1_fp_rename[%d];\n",i);
		printf("			rs2_fp = rs2_fp_rename[%d];\n",i);
		printf("			rs3_fp = rs3_fp_rename[%d];\n",i);
		printf("			pc_rn = pc_rename[%d];\n",i);
		printf("			pc_dest_rn = pc_dest_rename[%d];\n",i);
		printf("			real_rd = rd_real_rename[%d];\n",i);
		printf("			rs1 = rs1_rename[%d];\n",i);
		printf("			rs2 = rs2_rename[%d];\n",i);
		printf("			rs3 = rs3_rename[%d];\n",i);
		printf("			real_rs1 = real_rs1_rename[%d];\n",i);
		printf("			real_rs2 = real_rs2_rename[%d];\n",i);
		printf("			real_rs3 = real_rs3_rename[%d];\n",i);
		printf("			control = control_rename[%d];\n",i);
		printf("			unit_type = unit_type_rename[%d];\n",i);
		printf("			branch_token = branch_token_rename[%d];\n",i);
		printf("			branch_token_ret = branch_token_ret_rename[%d];\n",i);
		printf("			immed = immed_rename[%d];\n",i);
		printf("			start = start_rename[%d];\n",i);
		printf("			short = short_rename[%d];\n",i);
		printf("		    end\n");
	}
	printf("		%d'b", B);
	for (j = 0; j < B; j++)
		printf("0");
	printf(": xload = 0;\n ");
	printf("		endcase \n");
	printf("	end \n");
}
