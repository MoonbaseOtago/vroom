
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
	int ind=1,nldstq, nload, nstore, lnldstq, nmul;
    	if (argc < 3) {
err:
        	fprintf(stderr, "mk14 nload nstore nmul\n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	nload = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nstore = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nmul = strtol((const char *)argv[ind++], 0, 0);
	
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
	printf("		this_load_done = ");
	for (i = 0; i < nload; i++) 
		printf("(load_done[%d]&&(load_done_hart[%d]==H)&&(load_done_commit[%d]==C))%s",i,i,i,i==nload-1?";\n":"||");
	printf("		this_load_trap_type = 'bx;\n");
	printf("		this_load_pending = ");
	for (i = 0; i < nload; i++) 
		printf("(load_pending[%d]&&load_done[%d]&&(load_done_hart[%d]==H)&&(load_done_commit[%d]==C))%s",i,i,i,i,i==nload-1?";\n":"||");
	printf("		casez({");
	for (i = 0; i < (nload); i++) 
		printf("(load_done[%d]&&(load_done_hart[%d]==H)&&(load_done_commit[%d]==C))%s",i,i,i,i == (nload-1)?"})// synthesis full_case parallel_case\n":",");
	for (i = nload-1;i>=0; i--) {
		printf("		%d'b",nload);
		for (j = 0; j < nload; j++) printf(i==j?"1":"?");
		printf(": this_load_trap_type = load_trap_type[%d];\n",i);
	}
	printf("		endcase\n");
	printf("		this_store_running = ");
	for (i = 0; i < nstore; i++) 
		printf("(store_running[%d]&&(store_running_hart[%d]==H)&&(store_running_commit[%d]==C))%s",i,i,i,i==nstore-1?";\n":"||");

	if (nstore == 1) {
		printf("		this_store_trap_type = store_running_trap_type[0];\n");
	} else {
		printf("		casez({");
		for (i = 0; i < (nstore); i++) 
			printf("(store_running[%d]&&(store_running_hart[%d]==H)&&(store_running_commit[%d]==C))%s",i,i,i,i == (nstore-1)?"})// synthesis full_case parallel_case\n":",");
		for (i = nstore-1;i>=0; i--) {
			printf("		%d'b",nstore);
			for (j = 0; j < nstore; j++) printf(i==j?"1":"?");
			printf(": this_store_trap_type = store_running_trap_type[%d];\n",i);
		}
		printf("		endcase\n");
	}

	printf("		this_divide_busy = ");
	for (i = 0; i < nmul; i++) 
		printf("(divide_busy[%d]&&(divide_hart[%d]==H)&&(divide_commit[%d]==C))%s",i,i,i,i==nmul-1?";\n":"||");
	printf("	end\n");	
}
