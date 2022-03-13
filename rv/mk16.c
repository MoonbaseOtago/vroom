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
int B=30;

void
px(int k)
{
    int i;
    for (i = 0; i < k; i++)
        printf("    ");
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

int ffs(int x)
{
	int i;
	for (i = B-1;i >=0;i--)
	if (x&(1<<i))
		return i;
	return 99;
}


int main(int argc, char ** argv)
{
	int m,n, i,j,k,l,t;
	int ind=1,nldstq, nload, nstore, lnldstq;
    	if (argc < 2) {
err:
        	fprintf(stderr, "mk16 nldstq \n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	nldstq = strtol((const char *)argv[ind++], 0, 0);
	lnldstq = ffs(nldstq);

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
	printf("		dc_raddr_req_out = 1;\n");
        printf("		dc_raddr_trans_out = 'bx;\n");
        printf("		dc_raddr_snoop_out = 'bx;\n");
        printf("		dc_raddr_out = 'bx;\n");
        printf("		mem_req = 'bx;\n");
        printf("		casez ((mem_read_req|mem_write_req)&~write_mem_io) // synthesis full_case parallel_case\n");
	i=0;
		for (j = 0; j < nldstq;j++) {
			printf("		%d'b",nldstq);
			for (k = nldstq-1; k >= 0; k--) {
				int n = i+j;
				
				if (k == j) printf("1"); else
				if (k < j)  printf(k <i && j>=i?"?":"0"); else
				if (j <i) printf(k < i?"?":"0"); else
					  printf("?");
			}
			printf(": mem_req = %d;\n", j);
		}
	printf("                %d'b",nldstq);
	for (k = nldstq-1; k >= 0; k--) 
		printf("0");
	printf(": dc_raddr_req_out = 0;\n");
	printf("		endcase\n");	
        printf("		dc_raddr_out = write_mem_addr[mem_req][NPHYS-1:ACACHE_LINE_SIZE];\n");
        printf("		dc_raddr_trans_out = mem_req;\n");
        printf("		dc_raddr_snoop_out = mem_write_req[mem_req]?(mem_write_invalidate[mem_req]?RSNOOP_READ_LINE_INV_SHARED:RSNOOP_READ_LINE_EXCLUSIVE):(mem_read_cancel[mem_req]?RSNOOP_READ_CANCEL:wq_amo[mem_req][0]?RSNOOP_READ_LINE_EXCLUSIVE:RSNOOP_READ_LINE_SHARED);\n");
	printf("	end\n");	
}
