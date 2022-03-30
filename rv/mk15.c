
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
	int ind=1,nglobal_units, nlocal_units;
    	if (argc < 2) {
err:
        	fprintf(stderr, "mk15 nglobal_units nlocal_units\n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	nglobal_units = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nlocal_units = strtol((const char *)argv[ind++], 0, 0);
	
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


	printf("	for (H = 0; H < NHART; H=H+1) begin\n");	
	printf("		for (C = 0; C < NCOMMIT; C=C+1) begin :xx\n");	
	printf("			assign xsched[H][C] = \n");
	for (i = 0; i < nglobal_units; i++) 
	printf("				(enable_sched[%d]&&(alu_sched[%d]==C)&&(H==hart_sched[%d]))|\n",i,i,i);
	for (i = 0; i < nlocal_units; i++) 
	printf("				(local_enable_sched[%d][H]&&(local_alu_sched[%d][H]==C))|\n",i,i);
	printf("				1'b0;\n");	
	
	printf("			wire [NSTORE-1:0]store_sched;\n");
	printf("			for (S = 0; S < NSTORE; S=S+1) begin\n");
	printf("				assign store_sched[S] = st_data.req[S].enable&&(st_data.req[S].rd==C)&&(st_data.req[S].hart==H);\n");
	printf("			end\n");
	printf("			assign xsched_d[H][C] = |store_sched;\n");
	printf("		end\n");	
	printf("	end\n");	
}
