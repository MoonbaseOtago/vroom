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

#define NRESOLVE 8
int B;

int popcount(unsigned int x)
{
	int count = 0;
	while (x) {
		if (x&1)
			count++;
		x=x>>1;
	}
	return count;
}

void
px(int k)
{
    int i;
    for (i = 0; i < k; i++)
        printf("    ");
}


void
xrecurse(int nresolve, int port, int nxferports, int s, int k)
{
	int l;
	px(port);printf("			%d'b", nresolve);
	for (l = 0; l < nresolve; l++) printf(l < s?"?":l < k?"0":l==k?"1":"?");
	printf(": begin\n");
	//px(port);printf("				if (commit_store_req_shift[%d]) begin\n", nresolve-k-1);
	//px(port);printf("					x_write_store_ack[s%d] = 1;\n", k);
	//px(port);printf("				end else begin\n");
	px(port);printf("					x_write_port_%d = s%d;\n", port, k);
	px(port);printf("					x_write_enable[%d] = 1;\n", port);
	px(port);printf("					x_write_ack[s%d] = 1;\n", k);
	//px(port);printf("				end\n");
	port++;
	if (port < nxferports && (k+1) < l) {
		px(port-1);printf("				casez (commit_resolved_masked) // synthesis full_case parallel_case\n");
		for (l = k+1; l < nresolve; l++)
			xrecurse(nresolve, port, nxferports, k+1, l);
		px(port-1);printf("				default:;\n");
		px(port-1);printf("				endcase\n");
	}
	px(port-1);printf("				end\n");
	
}


void
krecurse(int ind, int first, int last,  int br, int nbranch)
{
	int i, j;
	if (first < last || br > nbranch)
		return;
        px(ind); printf("		casez (branch_mask[%d:%d]) // synthesis full_case parallel_case\n", first,last);
	for (i = first; i>= last; i--) {
		px(ind); printf("		%d'b", first+1-last);
		for (j = first; j >= last; j--) 
			printf(j>i ?"0":j==i?"1":"?");
		printf(": begin\n");
		px(ind); printf("			c_update_br[%d] = 1;\n", br);
		px(ind); printf("			c_update_br_sel[%d] = s%d;\n", br, NRESOLVE-1-i);
		krecurse(ind+2, first-1, last, br+1, nbranch);
		px(ind); printf("		  end\n");
	}
	px(ind); printf("		default: ;\n");
	px(ind); printf("		endcase\n");
}

int main(int argc, char ** argv)
{
	int n, i,j,k,l,t;
	int ind=1,nxferports, nrename;
	int nbranch = 2;
	int ncommit = 32;
    	if (argc < 3) {
err:
        	fprintf(stderr, "mk7 num-rename num-xfer-ports ncommit nbranch\n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	nrename = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nxferports = strtol((const char *)argv[ind++], 0, 0);
	if (ind < argc)
    	ncommit = strtol((const char *)argv[ind++], 0, 0);
	if (ind < argc)
    	nbranch = strtol((const char *)argv[ind++], 0, 0);


	t=1<<nrename;

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


	k = nrename;
	if (NRESOLVE > k)
		k = NRESOLVE;
	for (i = 0; i < k; i++) {
        	printf("	wire [LNCOMMIT-1:0]s%d = r_commit_start+%d;\n",i,i);
	}
	printf("	wire[%d-1:0]commit_done_shift = {", NRESOLVE);
	for (k = 0; k < NRESOLVE; k++)
		printf("commit_done[s%d]%s", k,k!=(NRESOLVE-1)?",":"};\n");
	printf("	wire[%d-1:0]commit_branch_shift = {", NRESOLVE);
	for (k = 0; k < NRESOLVE; k++)
		printf("commit_branch[s%d]%s", k,k!=(NRESOLVE-1)?",":"};\n");
	printf("	wire[%d-1:0]commit_branch_ok_shift = {", NRESOLVE);
	for (k = 0; k < NRESOLVE; k++)
		printf("commit_branch_ok[s%d]%s", k,k!=(NRESOLVE-1)?",":"};\n");

	//
	//
	printf("	reg [%d:0]commit_mask;\n", NRESOLVE-1);
        printf("	reg [%d:0]c_update_br;\n", nbranch-1);
        printf("	assign commit_update_br = c_update_br;\n");	
	printf("	wire [%d:0]branch_mask = commit_branch_shift&commit_mask;\n", NRESOLVE-1);
	//printf("	assign is_branch  = branch_mask;\n");
	printf("	assign current_commit_mask  = commit_mask;\n");
	printf("	wire [%d:0]branch_ok_mask = commit_branch_shift&commit_mask&commit_branch_ok_shift;\n", NRESOLVE-1);

	printf("	reg [3:0]c_num_branches_retired;\n");
	printf("	reg [3:0]c_num_branches_predicted;\n");
	printf("	assign num_branches_retired = c_num_branches_retired;\n");
	printf("	assign num_branches_predicted = c_num_branches_predicted;\n");
	printf("	always @(*) begin\n");
	printf("		c_num_branches_predicted = \n");
	for (i = 0; i < NRESOLVE; i++) {
		printf("			{3'b0, branch_ok_mask[%d]} %s\n", i, i==(NRESOLVE-1)?";":"+");
	}
	printf("		c_num_branches_retired = \n");
	for (i = 0; i < NRESOLVE; i++) {
		printf("			{3'b0, branch_mask[%d]} %s\n", i, i==(NRESOLVE-1)?";":"+");
	}
        printf("	end\n\n");
        printf("	always @(*) begin\n");
        printf("		c_commit_ended = 0;\n");
        printf("		inc = 0;\n");
        printf("		casez (commit_done_shift) // synthesis full_case parallel_case\n");
        for (i = 0; i < NRESOLVE; i++) {
                printf("		%d'b", NRESOLVE);
                for (j = NRESOLVE-1; j >= 0; j--) printf(j >=i?"1":j == (i-1)?"0":"?");
                printf(": begin\n");
		printf("				inc = %d;\n",NRESOLVE-i);
		printf("				commit_mask = %d'b",NRESOLVE);
                for (j = NRESOLVE-1; j >= 0; j--) printf(j >=i?"1":"0");
		printf(";\n");
		for (j = 0; j < (nrename-i); j++)
			printf("				c_commit_ended[s%d] = 1;\n", j);
		printf("			end\n");
		
	}
        printf("		%d'b0", nrename);
	for (j = 0; j < (nrename-1); j++)
		printf("?");
	printf(": begin inc = 0; commit_mask = 0; end\n");
        printf("		endcase\n");
        printf("	end\n");




	printf("	reg [%d-1:0]commit_req_mask;\n", NRESOLVE);
	printf("	wire[%d-1:0]commit_req_shift = {", NRESOLVE);
	for (k = 0; k < NRESOLVE; k++)
		printf("commit_req[s%d]%s", k,k!=(NRESOLVE-1)?",":"};\n");
	//printf("	wire[%d-1:0]commit_store_req_shift = {", NRESOLVE);
	//for (k = 0; k < NRESOLVE; k++)
		//printf("commit_store_req[s%d]%s", k,k!=(NRESOLVE-1)?",":"};\n");
	//printf("	always @(*) begin\n");
	//printf("		casez (commit_done_shift|commit_req_shift|commit_store_req_shift) // synthesis full_case parallel_case\n");
	//printf("		casez (commit_done_shift|commit_req_shift) // synthesis full_case parallel_case\n");
	//for (k = 0; k < (NRESOLVE+1); k++) {
		//printf("		%d'b", NRESOLVE);
		//for (l = 0; l < NRESOLVE; l++) printf(l < k?"1":l==k?"0":"?");
		//printf(": commit_req_mask = %d'b", NRESOLVE);
		//for (l = 0; l < NRESOLVE; l++) printf(l < k?"1":"0");
		//printf(";\n");
	//}
	//printf("		endcase\n");
	//printf("	end\n");



	//printf("	wire[%d-1:0]commit_resolved_masked = commit_req_mask&(commit_store_req_shift|commit_req_shift);", NRESOLVE);
	printf("	wire[%d-1:0]commit_resolved_masked = commit_req_mask&commit_req_shift;", NRESOLVE);
	printf("	reg [%d:0]x_write_enable;\n", nxferports-1);
	for (k = 0; k < nxferports; k++) {
		printf("	reg [LNCOMMIT-1:0]x_write_port_%d;\n", k);
		printf("	assign commit_write_port_%d = x_write_port_%d;\n", k, k);
		printf("	assign commit_write_enable[%d] = x_write_enable[%d];\n", k, k);
	}
	printf("	reg	[NCOMMIT-1:0]x_write_ack;\n");
	printf("	assign commit_ack = x_write_ack;\n");
	//printf("	reg	[NCOMMIT-1:0]x_write_store_ack;\n");
	//printf("	assign commit_store_ack = x_write_store_ack;\n");
	printf("	\n");
	printf("	always @(*) begin\n");
	printf("		x_write_enable = 0;\n");
	for (k = 0; k < nxferports; k++) {
		printf("		x_write_port_%d = 'bx;\n", k);
	}
	printf("		x_write_ack = 0;\n");
	//printf("		x_write_store_ack = 0;\n");
	printf("		casez (commit_resolved_masked) // synthesis full_case parallel_case\n");
//start_commit_%d
	for (k = 0; k < NRESOLVE; k++) {
		xrecurse(NRESOLVE, 0, nxferports, 0, k);
	}
	printf("		default:;\n");
	printf("		endcase\n");
	printf("	end\n");	
	printf("	wire [NCOMMIT-1:0]req_done = commit_done|commit_req|commit_store_req;\n");	
	printf("	reg [NCOMMIT-1:0]commit_done_sh_mask;\n");
	printf("	always @(*) begin\n");
	printf("		case (r_commit_start) // synthesis full_case parallel_case\n");
	for (i = 0; i < ncommit; i++) {
	printf("		%d: begin\n", i);
	if (i == 0) {
	for (j = 0; j < ncommit; j++) 
	printf("			commit_done_sh_mask[%d] = &req_done[%d:0];\n", j, j);
	} else {
	for (j = 0; j < ncommit; j++) 
	if (j >= i) {
	printf("			commit_done_sh_mask[%d] = &req_done[%d:%d];\n", j, j, i);
	} else {
	printf("			commit_done_sh_mask[%d] = &req_done[NCOMMIT-1:%d] & (&req_done[%d:0]);\n", j, i, j);
	}
	}
	printf("		    end\n");
	}
	printf("		endcase\n");
	printf("	end\n");	
	printf("	always @(*) begin\n");
	printf("		case (r_commit_start) // synthesis full_case parallel_case\n");
	for (i = 0; i < ncommit; i++) {
	printf("		%d: begin\n", i);
	printf("		    	commit_req_mask = {");
	for (j = 0; j < NRESOLVE; j++) {
	char *cp = (j==(NRESOLVE-1)?"};\n":",");
	if ((i+j) >= ncommit) {
	printf("commit_done_sh_mask[%d]%s",i+j-ncommit,cp);
	} else {
	printf("commit_done_sh_mask[%d]%s",i+j,cp);
	}
	}
	printf("		    end\n");
	}
	printf("		endcase\n");
	printf("	end\n");	
	printf("	assign commit_store_ack = commit_done_sh_mask&commit_store_req;\n\n");	
	
}
