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

int B, num_retire;

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
	int i,j,k,l, m, t;

	if (argc < 2) {
		num_retire = 8;
	} else {
		num_retire = strtol((const char *)argv[1], 0, 0);
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

	

	printf("	// 1b case\n");
	printf("	always @(*) begin\n");
	printf("		l1b_write_strobe = 0;\n");
	printf("		l1b_meta_next = 'bx;\n");
	printf("		casez ({trace_in.valid[NRETIRE-1:1], r_waiting_offset}) // synthesis full_case parallel_case\n");
	for (i = 1; i < num_retire; i++) {
	for (j = 1; j < (num_retire-(i-1)); j++) {
	printf("		%d'b", num_retire-1+clog2(num_retire)+1);
	for (k = (num_retire-1);k >= 1;k--) printf(k > j? "?":k == j?((i+j)==(num_retire)?"?":"0"):"1");printf("_");
	for (k = (clog2(num_retire));k >= 0;k--) printf(i&(1<<k)? "1":"0");
		printf(": begin\n");
	
	printf("					l1b_write_strobe = %d'b", num_retire);	
	if (i < num_retire) {
		for (k = num_retire-1; k >= i; k--) printf(k >= (i+j) ?"0":"1");
	}
	printf("_");
	for (k = 0; k < i; k++) printf("1");
	printf(";\n");
	printf("					l1b_meta_next = next_ins[%d];\n", j-1);
	printf("					l1b_write_data = {");
	if ((i+j)< num_retire) printf("{%d*BUNDLE_SIZE{1'bx}},", num_retire-(i+j));	
	printf("cx[%d*BUNDLE_SIZE-1:0],", j);
	printf("r_waiting[BUNDLE_SIZE*%d-1:0]};\n", i);
	if ((i+j)==(num_retire)) {
	printf("					l1b_c_waiting_valid = {%d'b0, trace_in.valid[%d:%d]};\n", j,  num_retire-1,j);
	printf("					l1b_c_waiting_pc = trace_in.b[%d].pc;\n", j);
	printf("					l1b_c_waiting = {");
	printf("{%d*BUNDLE_SIZE{1'bx}},", j);
	printf("cx[%d*BUNDLE_SIZE-1:%d*BUNDLE_SIZE]", num_retire, j);
	printf("};\n");
	printf("					l1b_c_waiting_next = 'bx;\n");	
	printf("					l1b_c_waiting_offset = 'bx;\n");	
	printf("					casez (trace_in.valid[NRETIRE-1:%d]) // synthesis full_case parallel_case\n", j);
	for (k = j; k <= num_retire; k++) {
	printf("					%d'b", num_retire-j);
	for (l=num_retire-1;l >= j; l--) printf(l>k?"?":l==k?"0":"1");printf(": begin\n");
	if (k != j) {
	printf("						l1b_c_waiting_next = next_ins[%d];\n", k-1);	
	printf("						l1b_c_waiting_offset = %d;\n", k);	
	}
	printf("						end\n");
	}
	printf("					endcase\n");
	} else {
	printf("					l1b_c_waiting_valid = 0;\n");
	printf("					l1b_c_waiting_pc = 'bx;\n");
	printf("					l1b_c_waiting = 'bx;\n");	
	printf("					l1b_c_waiting_offset = 'bx;\n");	
	printf("					l1b_c_waiting_next = 'bx;\n");	
	}
	printf("				end\n");
	}
	}
	printf("		%d'b", num_retire-1+clog2(num_retire)+1);
	for (k = (num_retire-1);k >= 1;k--) printf("?");printf("_1");
	for (k = (clog2(num_retire)-1);k >= 0;k--) printf("0"); printf(": begin\n");
	printf("					l1b_write_strobe = %d'b", num_retire);	
	for (k = 0; k < num_retire; k++) printf("1");
	printf(";\n");
	printf("					l1b_write_data = {");
	printf("{BUNDLE_SIZE{1'bx}},");	
	printf("r_waiting[BUNDLE_SIZE*%d-1:0]};\n", num_retire-1);
	printf("					l1b_meta_next = r_waiting_next;\n");
	printf("					l1b_c_waiting = cx;\n");
	printf("					l1b_c_waiting_pc = trace_in.b[0].pc;\n");
	printf("					l1b_c_waiting_valid = trace_in.valid;\n");
	printf("					l1b_c_waiting_next = 'bx;\n");
	printf("					l1b_c_waiting_offset = 'bx;\n");
	printf("					casez (trace_in.valid) // synthesis full_case parallel_case\n");
	for (i = 1; i <= num_retire; i++) {
	printf("					%d'b", num_retire);
	for (k=num_retire-1;k>=0;k--) printf(k > i?"?":k==i?"0":"1"); printf(": begin\n");
	printf("						l1b_c_waiting_next = next_ins[%d];\n", i-1);
	printf("						l1b_c_waiting_offset = %d;\n", i);
	printf("						end\n");
	}
	printf("					default:;\n");
	printf("					endcase\n");
	printf("				end\n");
	printf("		endcase\n");
	printf("	end\n");
	printf("\n");
	printf("	// 2 case\n");
	printf("	always @(*) begin\n");
	printf("		l2_c_waiting_pc = 'bx;\n");
	printf("		l2_c_waiting_next = 'bx;\n");
	printf("		l2_c_waiting = 'bx;\n");
	printf("		l2_c_waiting_offset = 'bx;\n");
	printf("		casez (trace_in.valid&start_vec) // synthesis full_case parallel_case\n");
	for (i = 0; i < num_retire; i++) {
	printf("		%d'b", num_retire);
	for (k = num_retire-1;k >= 0; k--) printf(k > i?"?":k==i?"1":"0"); printf(": begin\n");; 
	printf("					l2_c_waiting_pc = trace_in.b[%d].pc;\n", i);
	if (i == 0) {
	printf("					l2_c_waiting_valid = trace_in.valid;\n");
	printf("					l2_c_waiting = cx;\n");
	} else {
	printf("					l2_c_waiting_valid = {{%d{1'b0}}, trace_in.valid[NRETIRE-1:%d]};\n", i, i);
	printf("					l2_c_waiting = {{%d*BUNDLE_SIZE{1'bx}}, cx[BUNDLE_SIZE*%d-1:BUNDLE_SIZE*%d]};\n", i, num_retire, i);
	}
	if (i == (num_retire-1)){
	printf("					l2_c_waiting_next = next_ins[%d];\n", i);
	printf("					l2_c_waiting_offset = %d;\n", i+1);
	} else {
	printf("					casez (trace_in.valid[NRETIRE-1:%d]) // synthesis full_case parallel_case\n", i+1);
	for (j = i+1; j <= num_retire; j++) {
	printf("					%d'b", num_retire-i-1);
	for (k = num_retire-1; k >= (i+1); k--) printf(k > j?"?":k==j?"0":"1"); printf(": begin\n");
	printf("								l2_c_waiting_next = next_ins[%d];\n", j-1);
	printf("								l2_c_waiting_offset = %d;\n", j);
	printf("							end\n");
	}
	printf("					endcase\n");
	}
	printf("				end\n");
	}
	printf("		default:	l2_c_waiting_valid = 0;\n");
	printf("		endcase\n");
	printf("	end\n");
	printf("\n");
	printf("	// 4 case\n");
	printf("	always @(*) begin\n");
	printf("		l4_next = 'bx;\n");
	printf("		casez (trace_in.valid[NRETIRE-1:1]) // synthesis full_case parallel_case\n");
	for (i = 1; i <= num_retire; i++) {
	printf("		%d'b", num_retire-1);
	for (k = num_retire-1; k >= 1; k--) printf(k>i?"?":k==i?"0":"1");printf(": l4_next = next_ins[%d];\n", i-1);
	}
	printf("		endcase\n");
	printf("	end\n");

	printf("\n");
	printf("	// 3 case\n");
	printf("	always @(*) begin\n");
	printf("		l3_write_strobe = 0;\n");
	printf("		l3_meta_next = 'bx;\n");
	printf("		l3_c_waiting_valid = 0;\n");
	printf("		l3_c_waiting = 'bx;\n");
	printf("		l3_c_waiting_offset = 'bx;\n");
	printf("		l3_c_waiting_pc = 'bx;\n");
	printf("		l3_c_waiting_next = 'bx;\n");
	// we know that r_last_valid[0] == 1 and r_last_valid[7]==0 (otherwise we couldn't add)
	printf("		casez (r_last_valid[NRETIRE-1:1]) // synthesis full_case parallel_case\n");
	for (i = 1; i < (num_retire); i++) {
	printf("		%d'b", num_retire-2);
	for (k = num_retire-2; k >= 1; k--) printf(k>i?"?":k==i?"0":"1"); printf(": begin\n");
	printf("				l3_write_strobe = {trace_in.valid[%d:0], %d'b0};\n", num_retire-i-1, i);
	printf("				l3_write_data = {cx[%d*BUNDLE_SIZE-1:0], {BUNDLE_SIZE*%d{1'bx}}};\n", num_retire-i, i);	
	printf("				l3_c_waiting_valid = {%d'b0, trace_in.valid[NRETIRE-1:%d]};\n", num_retire-i, num_retire-i);
	printf("				l3_c_waiting = {{BUNDLE_SIZE*%d{1'bx}}, cx[NRETIRE*BUNDLE_SIZE-1:%d*BUNDLE_SIZE]};\n", i, num_retire-i);	
	printf("				l3_c_waiting_pc = trace_in.b[%d].pc;\n", num_retire-i);	
	if (i == (num_retire-1)) {
	printf("				l3_meta_next = next_ins[0];\n");	
	} else {
	printf("				casez (trace_in.valid[%d:1]) // synthesis full_case parallel_case\n", num_retire-i);
	for (j = 1; j <= (num_retire-i); j++) {
	printf("				%d'b", num_retire-i-1);
	for (k = num_retire-i-1; k >= 1; k--) printf(k>j?"?":k==j?"0":"1"); printf(": begin\n");
	printf("						l3_meta_next = next_ins[%d];\n", j-1);	
	printf("					end\n");
	}
	printf("				endcase\n");
	}
	printf("				casez (trace_in.valid[NRETIRE-1:%d]) // synthesis full_case parallel_case\n", num_retire-i);
	for (j = num_retire-i; j <= num_retire; j++) {
	printf("				%d'b", i);
	for (k = num_retire-1; k >= (num_retire-i); k--) printf(k>j?"?":k==j?"0":"1"); printf(": begin\n");
	if (j == (num_retire-i)) {
	printf("						l3_c_waiting_next = 'bx;\n");
	printf("						l3_c_waiting_offset = 'bx;\n");
	} else {
	printf("						l3_c_waiting_next = next_ins[%d];\n", j-1);
	printf("						l3_c_waiting_offset = %d;\n", j);
	}
	printf("					end\n");
	}
	printf("				endcase\n");
	
	printf("			end\n");
	}
	printf("		endcase\n");
	printf("	end\n");
}
