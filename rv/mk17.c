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
	int ind=1,nhart, naddr, vlen;
    	if (argc < 3) {
err:
        	fprintf(stderr, "mk17 nhart naddr\n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	nhart = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	naddr = strtol((const char *)argv[ind++], 0, 0);

	vlen = 2*nhart*(naddr);
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
	printf("		vmq_first = 'bx;\n");
	printf("		casez ({r_vmq_valid, vmq_shift}) // synthesis full_case parallel_case\n");	
	for (i = 0; i < (vlen+1); i++) {
		printf("		%d'b", vlen+1);
		for (j = (vlen)-1; j >=0;j--)
			printf(j >= i?"0":j == i-1?"1":"?");
		printf("_0: vmq_first = %d;\n", i==(vlen)?i-1:i);
	}
	printf("		%d'b", vlen+1);
	for (j = vlen-1; j >=0;j--)
		printf("0");
	printf("_1,\n");
	for (i = 0; i < (vlen); i++) {
		printf("		%d'b", (vlen)+1);
		for (j = (vlen)-1; j >=0;j--)
			printf(j > i?"0":j == i?"1":"?");
		printf("_1: vmq_first = %d;\n", i);
	}
	printf("		endcase\n");	
	printf("	end\n");	
	for (i = 0; i < (naddr); i++) {
		printf("	always @(*) begin\n");	
			printf("		casez (tlb_rd_stall) // synthesis full_case parallel_case\n");	
			for (j = i; j < (naddr); j++) {
				printf("		%d'b", naddr);
				for (k = (naddr)-1;k>=(i);k--) 
					printf(k >j?"?":k==j?"1":"0");
				for (k = i-1;k>=0;k--) 
					printf("1");
				printf(": begin\n");	
                        	printf("				cv_stall[%d] = 1;\n",i);
                        	printf("				cv_vaddr[%d] = dtlb.req[%d].vaddr;\n",i,j);
                        	printf("				cv_asid[%d] = dtlb.req[%d].asid;\n",i,j);
                        	printf("				cv_hart[%d] = addr_hart[%d];\n",i,j);
                        	printf("				cv_commit[%d] = r_addr_rd[%d];\n",i,j);
				printf("		         end\n");	
			}
			printf("		default: begin\n");	
                        printf("				cv_stall[%d] = 0;\n",i);
                        printf("				cv_vaddr[%d] = 'bx;\n",i);
                        printf("				cv_asid[%d] = 'bx;\n",i);
                        printf("				cv_hart[%d] = 'bx;\n",i);
                        printf("				cv_commit[%d] = 'bx;\n",i);
			printf("		         end\n");	
			printf("		endcase\n");	
		printf("	end\n");	
	}
}
