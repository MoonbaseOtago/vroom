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
	int ind=1;
	int ways, pending;

	if (argc < 3) {
		fprintf(stderr, "Usage: mk20 num_pending num_branch_way\n");
		exit(99);
	}
    	pending = strtol((const char *)argv[ind++], 0, 0);
    	ways = strtol((const char *)argv[ind++], 0, 0);
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
 	printf("		case (r_pend_out) // syntheis full_case parallel_case\n");
	for (k = 0; k < pending; k++) {
 	printf("		%d:	casez (global_pend_prediction_push_valid) // syntheis full_case parallel_case\n", k);
	for (i = 0; i < pending; i++) {
		printf("			%d'b", pending);
		for (j = pending-1; j >=0; j--) printf(((j-k+pending)%pending) > i ?"0":((j-k+pending)%pending)==i?"1":"?");
		printf(": global_pred_push_index = %d;\n", (i+k)%pending);
	}
	printf("			default: global_pred_push_index = 'bx;\n");
	printf("			endcase\n");
	}
	printf("		endcase\n");
	printf("	end\n");

	printf("	always @(*) begin\n");
 	printf("		case (r_pend_out) // syntheis full_case parallel_case\n");
	for (k = 0; k < pending; k++) {
 	printf("		%d:	casez (global_pend_prediction_valid) // syntheis full_case parallel_case\n", k);
	for (i = 0; i < pending; i++) {
		printf("			%d'b", pending);
		for (j = pending-1; j >=0; j--) printf(((j-k+pending)%pending) > i ?"0":((j-k+pending)%pending)==i?"1":"?");
		printf(": global_pred_index = %d;\n", (i+k)%pending);
	}
	printf("			default: global_pred_index = 'bx;\n");
	printf("			endcase\n");
	}
	printf("		endcase\n");
	printf("	end\n");

	printf("	always @(*) begin\n");
 	printf("		case (r_pend_out) // syntheis full_case parallel_case\n");
	for (k = 0; k < pending; k++) {
 	printf("		%d:	casez (bimodal_pend_prediction_valid) // syntheis full_case parallel_case\n", k);
	for (i = 0; i < pending; i++) {
		printf("			%d'b", pending);
		for (j = pending-1; j >=0; j--) printf(((j-k+pending)%pending) > i ?"0":((j-k+pending)%pending)==i?"1":"?");
		printf(": bimodal_pred_index = %d;\n", (i+k)%pending);
	}
	printf("			default: bimodal_pred_index = 'bx;\n");
	printf("			endcase\n");
	}
	printf("		endcase\n");
	printf("	end\n");

	printf("	always @(*) begin\n");
 	printf("		case (r_pend_out) // syntheis full_case parallel_case\n");
	for (k = 0; k < pending; k++) {
 	printf("		%d:	casez (bimodal_pend_prediction_push_valid) // syntheis full_case parallel_case\n", k);
	for (i = 0; i < pending; i++) {
		printf("			%d'b", pending);
		for (j = pending-1; j >=0; j--) printf(((j-k+pending)%pending) > i ?"0":((j-k+pending)%pending)==i?"1":"?");
		printf(": bimodal_pred_push_index = %d;\n", (i+k)%pending);
	}
	printf("			default: bimodal_pred_push_index = 'bx;\n");
	printf("			endcase\n");
	}
	printf("		endcase\n");
	printf("	end\n");

	printf("	always @(*) begin\n");
 	printf("		case (r_pend_out) // syntheis full_case parallel_case\n");
	for (k = 0; k < pending; k++) {
 	printf("		%d:	casez (combined_pend_prediction_push_valid) // syntheis full_case parallel_case\n", k);
	for (i = 0; i < pending; i++) {
		printf("			%d'b", pending);
		for (j = pending-1; j >=0; j--) printf(((j-k+pending)%pending) > i ?"0":((j-k+pending)%pending)==i?"1":"?");
		printf(": combined_pred_push_index = %d;\n", (i+k)%pending);
	}
	printf("			default: combined_pred_push_index = 'bx;\n");
	printf("			endcase\n");
	}
	printf("		endcase\n");
	printf("	end\n");

	printf("	always @(*) begin\n");
 	printf("		case (r_pend_out) // syntheis full_case parallel_case\n");
	for (k = 0; k < pending; k++) {
 	printf("		%d:	casez (combined_pend_prediction_valid) // syntheis full_case parallel_case\n", k);
	for (i = 0; i < pending; i++) {
		printf("			%d'b", pending);
		for (j = pending-1; j >=0; j--) printf(((j-k+pending)%pending) > i ?"0":((j-k+pending)%pending)==i?"1":"?");
		printf(": combined_pred_index = %d;\n", (i+k)%pending);
	}
	printf("			default: combined_pred_index = 'bx;\n");
	printf("			endcase\n");
	}
	printf("		endcase\n");
	printf("	end\n");


	printf("	always @(*) begin\n");
 	printf("		casez (r_pend_valid&(r_pend_committed|commit_token)) // syntheis full_case parallel_case\n");
	for (i = 0; i < pending; i++) {
		printf("		%d'b", pending);
		for (j = pending-1; j >=0; j--) printf(j==i?"0":j==(i==0?pending-1:i-1)?"1":"?");
		printf(": trap_shootdown_index = %d;\n", i);
	}
	printf("		%d'b", pending);
	for (j = pending-1; j >=0; j--) printf("0");
	printf(": trap_shootdown_index = r_pend_in;\n");
	printf("		default: trap_shootdown_index = 'bx;\n");
	printf("		endcase\n");
	printf("	end\n");
}
