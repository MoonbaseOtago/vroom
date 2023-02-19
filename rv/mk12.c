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

#define NRESOLVE 8
int B;

void
px(int k)
{
    int i;
    for (i = 0; i < k; i++)
        printf("    ");
}



int main(int argc, char ** argv)
{
	int n, i,j,k,l,t;
	int ind=1,ncommit;
    	if (argc < 2) {
err:
        	fprintf(stderr, "mk12 ncommit\n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	ncommit = strtol((const char *)argv[ind++], 0, 0);



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


	printf("		wire kill = (commit_trap_br_enable&(r_commit_end!=(commit_trap_br_addr+1)))|(commit_br_enable&(r_commit_end!=(commit_br_addr+1)));\n");
    	printf("		wire [LNCOMMIT-1:0]kill_start = (commit_trap_br_enable?commit_trap_br_addr:commit_br_addr);\n");	// number of things to kill
    	printf("		wire [LNCOMMIT-1:0]kill_count = r_commit_end-kill_start-2;\n");	// number of things to kill
    	printf("		wire [LNCOMMIT-1:0]kk = (~r_commit_end)+1;\n");	
	printf("		wire [NCOMMIT-1:0]kmask, kout;\n");	// mask identifying them
	printf("		rot  #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))k(.in(kmask), .out(kout), .r(kk));\n");
	printf("		wire [LNCOMMIT-1:0]ks1 = kill_start+1;\n");
	printf("		assign commit_kill = (kill && (ks1!=r_commit_end)?kout:0);\n");

	printf("		assign kmask = {");
	for (i = ncommit-1;i >= 1; i--) 
		printf("(kill_count>=%d),",(ncommit-1)-i);
	printf("(kill_count>=%d)};\n", (ncommit-1)-0);
	exit(0);
}
