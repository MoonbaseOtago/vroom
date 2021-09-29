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

int main(int argc, char ** argv)
{
	int i,j,k,t,n;
	int num_read_ports=3;

	if (argc < 3) {
		num_read_ports = 3;
	} else {
		num_read_ports = strtol((const char *)argv[2], 0, 0);
	}
	if (argc < 2) {
		B = 8;
	} else {
		B = strtol((const char *)argv[1], 0, 0);
	}
	t=1<<B;

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

	for (n = 0; n < num_read_ports; n++) {
        	printf("		always @(*) begin\n");
        	printf("			rd_paddr_res_%d = 45'bx;\n",n);
        	printf("			rd_%su%s_res_%d = %d'bx;\n",num_read_ports==2?"a":"ad", num_read_ports==2?"x":"wrx",n, num_read_ports==2?3:5);
        	printf("			casez (rd_match_%d) // synthesis full_case parallel_case \n",n);
		for (i = 0; i < B; i++) {
			printf("			%d'b", B);
			for (j=0;j< B ; j++)printf(i==j?"1":"?");
			printf(": begin rd_paddr_res_%d = r_tlb_paddr[%d]; rd_%su%s_res_%d = r_tlb_g%su%s[%d][%d:0]; end\n", n, B-i-1, num_read_ports==2?"a":"ad",num_read_ports==2?"x":"wrx", n, num_read_ports==2?"a":"ad", num_read_ports==2?"x":"wrx", B-i-1, num_read_ports==2?2:5);
		}
        	printf("			endcase\n");
        	printf("		end\n");
	}
}
