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

int B, num_trace_lines, num_retire;

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

int clog2(unsigned long x) 
{
	int i;
	for (i = 8*sizeof(x)-1; ; i--) {
		if (i <= 0)
			return 1;
		if ((1UL<<i) == x)
			return i;
		if ((1UL<<i) > x)
			continue;
		return i+1;
	}
}

int main(int argc, char ** argv)
{
	int i,j,k,t;

	if (argc < 2) {
		num_trace_lines = 32;
	} else {
		num_trace_lines = strtol((const char *)argv[1], 0, 0);
	}
	if (argc < 3) {
		num_retire = 8;
	} else {
		num_retire = strtol((const char *)argv[2], 0, 0);
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

	
	printf("	\n");
	printf("	//read port\n");
	printf("	always @(*)\n");
	printf("	casez (match) // synthesis full_case parallel_case\n");
	for (i = 0; i < num_trace_lines; i++) {
	printf("	%d'b", num_trace_lines);
	for (j = num_trace_lines-1; j>=0; j--) printf(i==j?"1":"?");
	printf(": cache = {");
	for (j = num_retire-1; j>=0; j--) printf("r_trace_cache[%d][%d]%s",i,j,j!=0?",":""); printf("};\n");
	}
	printf("	default: cache = 'bx;\n");
	printf("	endcase\n");

	printf("	always @(*) begin\n");
	printf("		c_next_use_valid = 0;\n");
	printf("		c_next_use = 'bx;\n");
	printf("		casez ({c_last, use_free}) // synthesis full_case parallel_case\n");
	for (i = 0; i < num_trace_lines; i++) {
	for (j = num_trace_lines-1; j >=0; j--) {
		if (i == j)
			continue;
	printf("		%d'b", num_trace_lines+clog2(num_trace_lines));
	for (k = clog2(num_trace_lines)-1;k >=0;k--)printf(i&(1<<k)?"1":"0");printf("_");
	for (k = num_trace_lines-1;k>=0;k--) 
	if (k == i) printf("?") ; else
	if (k == j) printf("1") ; else
	if (j > i) {
		printf(k > i && k < j? "0":"?");
	} else { //j < i
		printf(k > i || k < j? "0":"?");
	} printf(": begin\n");
		
	printf("				c_next_use_valid = 1;\n");
	printf("				c_next_use = %d;\n", j);
	printf("			end\n");
	}
	}
	printf("		%d'b", num_trace_lines+clog2(num_trace_lines));
	for (k = clog2(num_trace_lines)-1;k >=0;k--)printf("?");printf("_");
	for (k = num_trace_lines-1;k>=0;k--) printf("0"); printf(": ;\n");
	printf("		endcase\n");
	printf("	end\n");

	

	printf("	always @(*)\n");
	printf("	casez (match) // synthesis full_case parallel_case\n");
	for (i = 0; i < num_trace_lines; i++) {
	printf("	%d'b", num_trace_lines);
	for (j = num_trace_lines-1; j>=0; j--) printf(i==j?"1":"?");
	printf(": xbundle_valid = r_valid[%d];\n", i);
	}
	printf("	%d'b", num_trace_lines);
	for (j = num_trace_lines-1; j>=0; j--) printf("0");
	printf("	: xbundle_valid = 0;\n");
	printf("	endcase\n");

	printf("	always @(*)\n");
	printf("	casez (match) // synthesis full_case parallel_case\n");
	for (i = 0; i < num_trace_lines; i++) {
	printf("	%d'b", num_trace_lines);
	for (j = num_trace_lines-1; j>=0; j--) printf(i==j?"1":"?");
	printf(": begin xpc_next = r_pc_next[%d]; xpc_push_pop = r_pc_push_pop[%d]; xpc_ret_addr = r_pc_ret_addr[%d]; xpc_ret_addr_short = r_pc_ret_addr_short[%d];end \n", i, i, i, i);
	}
	printf("	default: begin xpc_next = 'bx; xpc_push_pop = 'bx; xpc_ret_addr = 'bx; xpc_ret_addr_short = 'bx; end\n");
	printf("	endcase\n");

	printf("	always @(*)\n");
	printf("	casez (match_starting) // synthesis full_case parallel_case\n");
	for (i = 0; i < num_trace_lines; i++) {
        printf("        %d'b", num_trace_lines);
        for (j = num_trace_lines-1; j>=0; j--) printf(i==j?"1":"?");
	printf(": starting_valid = r_valid[%d];\n", i);
	}
	printf("	default: starting_valid = 'bx;\n");
	printf("	endcase\n");
	
}
