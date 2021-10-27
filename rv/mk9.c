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

	if (argc < 2) {
		B = 8;
	} else {
		B = strtol((const char *)argv[1], 0, 0);
	}
	t=1<<B;

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


        printf("	always @(*) begin\n");
        printf("		casez (jumping_rel_jmp_end_fetch) // synthesis full_case parallel_case\n");
        for (i = 0; i < B; i++) {
                printf("		%d'b", B);
                for (j = 0; j < B; j++) printf((j) == (i)?"1":(j) >(i)?"0":"?");
                printf(": dec_br_offset = %d;\n", B-i-1);
	}
        printf("		default: dec_br_offset = 'bx;");
        printf("		endcase\n");
        printf("	end\n\n");
        printf("	always @(*) begin\n");
        printf("		predicted_branch = |jumping_rel_jmp_fetch;\n");
        printf("		branch_address = 'bx;\n");
        printf("		dec_br_start_offset = 'bx;\n");
        printf("		jumping_stall_pred = 0;\n");
	printf("		subr_push = 0;\n");
	printf("		subr_pop = 0;\n");
	printf("		subr_inc2 = 0;\n");
        printf("		casez (jumping_rel_jmp_fetch) // synthesis full_case parallel_case\n");
        for (i = 0; i < B; i++) {
                printf("		%d'b", B);
                for (j = 0; j < B; j++) printf((j) == (i)?"1":(j) >(i)?"0":"?");
                printf(": begin\n");
		printf("				branch_address = pc_br_fetch[%d];\n", B-i-1);
                printf("				dec_br_start_offset = %d;\n", B-i-1);
		printf("				jumping_stall_pred = jumping_stall_%d;\n", (B-i-1)>>1);
		printf("				subr_push = jumping_push[%d];\n", B-i-1);
		printf("				subr_pop = jumping_pop[%d];\n", B-i-1);
		printf("				subr_inc2 = jumping_inc2[%d];\n", B-i-1);
		printf("			end\n");
	}
        printf("		%d'b", B);
        for (j = 0; j < B; j++) printf("0");
        printf(": begin\n");
	printf("				subr_push = 0;\n");
	printf("				subr_pop = 0;\n");
	printf("				subr_inc2 = 0;\n");
	printf("			end\n");
        printf("		endcase\n");
        printf("	end\n\n");
#ifdef NOTDEF
        printf("	always @(*) begin\n");
	printf("		force_jmp = 0;\n");
	printf("		force_off = 'bx;\n");
	printf("		case (pc_fetch[H][BPRED-1:1])	// synthesis full_case parallel_case\n");
	for (i = 0; i < B; i++) {
        printf("		%d:\n",i);
	printf("			casez (must_jmp[%d:%d])	// synthesis full_case parallel_case\n", B-1, i);
	for (j = i; j < B; j++) {
	printf("			%d'b", B-i);
	for (k = B-1; k >= i; k--) printf(k>j?"?":k==j?"1":"0");
	printf(": begin force_jmp=1;force_off=%d;end\n", j);
	} 
	printf("			%d'b", B-i);
	for (k = B-1; k >= i; k--) printf("0");
	printf(": force_jmp=0;\n");
        printf("			endcase\n");
	}
        printf("		endcase\n");
        printf("	end\n");
#endif
}
