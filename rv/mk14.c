
//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-23 Paul Campbell - paul@taniwha.com
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
	int ind=1,nldstq, naddr, nload, nstore, lnldstq, nmul, nfp;
    	if (argc < 2) {
err:
        	fprintf(stderr, "mk14 naddr nmul\n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	naddr = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nload = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nstore = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nmul = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nfp = strtol((const char *)argv[ind++], 0, 0);
	
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


	printf("	always @(*) begin\n");	
	printf("		this_addr_done = ");
	for (i = 0; i < naddr; i++) 
		printf("(ls.ack[%d].hart[H]&&(ls.ack[%d].rd==C))%s",i,i, i==naddr-1?";\n":"||");
	printf("	end\n");	
	printf("	always @(*) begin\n");	
	printf("		this_load_done = ");
	for (i = 0; i < naddr; i++) 
		printf("(ls.ack[%d].hart[H]&&(ls.ack[%d].rd==C)&&(ls.ack[%d].trap_type!=0))||",i,i,i);
	for (i = 0; i < nload; i++) 
		printf("(ld_wb.wb[%d].hart[H]&&(ld_wb.wb[%d].rd==C))%s",i,i,i==nload-1?";\n":"||");
	printf("	end\n");	
	printf("	always @(*) begin\n");	
	printf("		this_trap_type = 'bx;\n");
	printf("		this_vm_pause = 0;\n");
	printf("		this_vm_stall = 0;\n");
	printf("		casez({");
	for (i = 0; i < (naddr); i++) 
		printf("(ls.ack[%d].hart[H]&&(ls.ack[%d].rd==C))%s",i,i,i == (naddr-1)?"})// synthesis full_case parallel_case\n":",");
	for (i = naddr-1;i>=0; i--) {
		printf("		%d'b",naddr);
		for (j = 0; j < naddr; j++) printf(i==j?"1":"?");
		printf(": begin this_trap_type = ls.ack[%d].trap_type; this_vm_pause = ls.ack[%d].vm_pause; this_vm_stall = ls.ack[%d].vm_stall; end\n",i, i, i);
	}
	printf("		%d'b",naddr);
	for (j = 0; j < naddr; j++) printf("0");
	printf(": begin this_trap_type = 0; this_vm_pause = 0; this_vm_stall = 0; end\n");
	printf("		endcase\n");
	printf("	end\n");	
	//printf("	always @(*) begin\n");	
	//printf("		this_store_done = ");
	//for (i = 0; i < nstore; i++) 
		//printf("(st_data.req[%d].enable&&st_data.req[%d].hart==H&&(st_data.req[%d].rd==C))%s",i, i,i,i==nstore-1?";\n":"||");
	//printf("	end\n");	
	printf("	always @(*) begin\n");	
	printf("		this_divide_busy = ");
	for (i = 0; i < nmul; i++) 
		printf("(divide_busy[%d]&&(divide_hart[%d]==H)&&(divide_commit[%d]==C))%s",i,i,i,i==nmul-1?";\n":"||");
	printf("	end\n");	
	if (nfp > 0) {
	printf("`ifdef FP\n");	
	printf("	always @(*) begin\n");	
	printf("		this_fp_done = ");
	for (i = nfp-1;i >=0;i--) printf("(reg_write_enable[NSHIFT+NALU+NMUL+%d][H]&(reg_write_addr[NSHIFT+NALU+NMUL+%d]==C))%s", i, i, i==0?";\n":"|");
	if (nfp == 1) {
	printf("		this_fp_exceptions = fp_unit_exceptions[0];\n");
	} else {
	printf("		this_fp_exceptions = 'bx;\n");
	printf("		casez ({");
	for (i = nfp-1;i >=0;i--) printf("reg_write_enable[NSHIFT+NALU+NMUL+%d][H]&(reg_write_addr[NSHIFT+NALU+NMUL+%d]==C)%s", i, i, i==0?"":",");
	printf("}) // synthesis full_case paralllel_case\n");
	for (i = 0; i < nfp; i++) {
	printf("		%d'b", nfp);
	for (j = nfp-1; j >= 0; j--) printf(i==j?"1": "?");
	printf(": this_fp_exceptions = fp_unit_exceptions[%d];\n", i);
	printf("		endcase\n");
	}
	}
	printf("	end\n");	
	printf("`endif\n");	
	}
}
