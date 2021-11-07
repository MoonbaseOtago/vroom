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

#define NRESOLVE 8

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int B=63;

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

//
//	load/store scheduling
//
//	basic rules:
//		1) schedule loads first then stores (because LS unit can't snoop stores in progress to virtual addresses)
//		2) can't schedule a store out of order 
//		3) can't schedule a load past a store
//		4) can schedule a load out of order wrt another load
//		5) can schedule HARTs past each other (might be worth having per-hart LS scheduler)
//
//

void recurse_ls(int recurse_limit, int indent, int commit, int ncommit, int hart, int numhart, int load, int nload, int store, int nstore, int storing)
{
	int i, k, l, n;

	char p[80];
	for (i=0;i<indent;i++)
		p[i] = '\t';
	p[indent+1]=0;

	if (commit >= ncommit)
		return;
	printf("%s			casez (lsm) // synthesis full_case parallel_case\n", p);
	for (k = commit; k < ncommit; k++) {
		for (l = hart; l < numhart; l++) {
				int first = 1;
				printf("%s			%d'b", p,  numhart*ncommit);
				for (n = 0; n < (ncommit*numhart); n++)
					printf(n < (commit*numhart+hart)?"?": n < (k*numhart+l)?"0":n == (k*numhart+l)?"1":"?");
				printf(": begin\n");
				printf("%s					if (!store_not_r%d[%d]) \n", p, l, k);
				printf("%s					if (store_r%d[%d]) begin\n", p, l, k);
				printf("%s						if (ge%d) begin\n", p, load+store+1);
				printf("%s							store_ready%d = 1;\n", p, store);
				printf("%s							store_out%d = %d+start_commit_%d;\n", p, store, k, l);
				if (numhart > 1)
						printf("%s						store_hart%d = %d;\n", p, store, l);
				if ((store+1) < nstore) {
					recurse_ls(recurse_limit, indent+1, (l+1) < numhart?k:k+1, ncommit, (l+1) < numhart?l+1:0, numhart, load, nload, store+1, nstore, 1);
				}
				printf("%s						end\n", p);
				if (storing) {
					printf("%s					end\n", p);
				} else {
					printf("%s					end else\n", p);
					printf("%s					if (load_not_r%d[%d]) begin \n", p, l, k);
					if (recurse_limit < 3) 
						recurse_ls(recurse_limit+1, indent+1, (l+1) < numhart?k:k+1 , ncommit, (l+1) < numhart?l+1:0, numhart, load, nload, store, nstore, 0);
					printf("%s					end else begin // must be load\n", p);
					printf("%s						if (ge%d) begin\n", p, load+store+1);
					printf("%s							load_ready%d = 1;\n", p, load);
					printf("%s							load_out%d = %d+start_commit_%d;\n", p, load, k, l);
					if (numhart > 1)
							printf("%s						load_hart%d = %d;\n", p, load, l);
					if ((load+1) < nload)
						recurse_ls(recurse_limit, indent+1, (l+1) < numhart?k:k+1, ncommit, (l+1) < numhart?l+1:0, numhart, load+1, nload, store, nstore, 0);
					printf("%s						end \n", p);
					printf("%s					end \n", p);
				}
				printf("%s				end\n", p);
		}
	}
	printf("%s			%d'b", p,  numhart*ncommit);
	for (n = 0; n < (ncommit*numhart); n++)
			printf(n < (commit*numhart+hart)?"?": n < (k*numhart+l)?"0":n == (k*numhart+l)?"0":"?");
	printf(": ;\n");
	printf("%s			endcase\n", p);
}

void
generate_sched_ls(int nload, int nstore, int numhart, int ncommit) // special case for load/store
{
	int i, j, k, l, m, n, first;

	j = 0;
	for (i = 0; i < nload; i++) {
		char *name="load";
		printf("		reg [LNCOMMIT-1:0]%s_out%d;\n", name, i);
		printf("		reg 		%s_ready%d;\n", name, i);
		if (numhart > 1) {
			printf("		reg [LNHART-1:0]%s_hart%d;\n", name, i);
			printf("		assign %s_hart_%d = %s_hart%d;\n", name, i, name, i);
		}
		printf("		assign %s_addr_%d = %s_out%d;\n", name, i, name, i);
		printf("		assign %s_enable_%d =  %s_ready%d;\n", name, i, name, i);
		printf("		reg r_%s_enable_%d;\n", name, i);
		printf("		always @(posedge clk)\n");
		printf("			r_%s_enable_%d <= %s_enable_%d;\n", name, i, name, i);
	}
	for (i = 0; i < nstore; i++) {
		char *name="store";
		printf("		reg [LNCOMMIT-1:0]%s_out%d;\n", name, i);
		printf("		reg 		%s_ready%d;\n", name, i);
		if (numhart > 1) {
			printf("		reg [LNHART-1:0]%s_hart%d;\n", name, i);
			printf("		assign %s_hart_%d = %s_hart%d;\n", name, i, name, i);
		}
		printf("		assign %s_addr_%d = %s_out%d;\n", name, i, name, i);
		printf("		assign %s_enable_%d =  %s_ready%d;\n", name, i, name, i);
		printf("		reg r_%s_enable_%d;\n", name, i);
		printf("		always @(posedge clk)\n");
		printf("			r_%s_enable_%d <= %s_enable_%d;\n", name, i, name, i);
	}
	printf("		wire [$clog2(%d)-1:0]num_enabled=%d'b0", nload+nstore,nload+nstore);
	for (i = 0; i < nload; i++)
			printf("+r_load_enable_%d", i);
	for (i = 0; i < nstore; i++)
			printf("+r_store_enable_%d", i);
	printf(";\n");
		
	
	for (i = 0; i < (nload+nstore); i++)
		printf("		wire ge%d = (num_ldstq_available >= (%d+num_enabled));\n", i+1, i+1);
	for (i = 0; i < numhart; i++) 
		printf("		wire [NCOMMIT-1:0]lsm_%d = store_r%d|store_not_r%d|load_r%d|load_not_r%d;\n", i, i, i, i, i);
	printf("		wire [NCOMMIT*NHART-1:0]lsm = {");
	first = 1;
	for (k = 0; k < ncommit; k++) {
		for (l = 0; l < numhart; l++) {
			if (first) {
				first=0;
			} else {
				printf(",");
			}
			printf("lsm_%d[%d]", l, k);
		}
	}
	printf("};\n");
	printf("		always @(*) begin\n");
	for (i = 0; i < nload; i++) {
		char *name="load";
		printf("			%s_ready%d=0;\n",name,i);
		printf("			%s_out%d='bx;\n",name,i);
		if (numhart > 1)
			printf("			%s_hart%d='bx;\n",name,i);
	}
	for (i = 0; i < nstore; i++) {
		char *name="store";
		printf("			%s_ready%d=0;\n",name,i);
		printf("			%s_out%d='bx;\n",name,i);
		if (numhart > 1)
			printf("			%s_hart%d='bx;\n",name,i);
	}
	recurse_ls(9, 0, 0, ncommit, 0, numhart, 0, nload, 0, nstore, 0); 
	printf("		end\n");
}

void generate_sched_recursive(const char *name, int instance, int nunit, int start, int numhart, int ncommit);

void
generate_sched(const char *name, int nunit, int numhart, int ncommit)
{
	int i, j, k, l, m, n, first;

	j = 0;
	for (j = 0; j < nunit; j++) {
		printf("		reg [LNCOMMIT-1:0]%s_out%d;\n", name, j);
		printf("		reg 		%s_ready%d;\n", name, j);
		if (numhart > 1) {
			printf("		reg [LNHART-1:0]%s_hart%d;\n", name, j);
			printf("		assign %s_hart_%d = %s_hart%d;\n", name, j, name, j);
		}
		printf("		assign %s_addr_%d = %s_out%d;\n", name, j, name, j);
		printf("		assign %s_enable_%d =  %s_ready%d;\n", name, j, name, j);
	}
	printf("		always @(*) begin\n");
	for (j = 0; j < nunit; j++) {
		printf("			%s_ready%d=1'bx;\n",name,j);
		printf("			%s_out%d='bx;\n",name,j);
		if (numhart > 1)
			printf("			%s_hart%d='bx;\n",name,j);
	}
	generate_sched_recursive(name, 0, nunit, 0, numhart, ncommit);
	printf("		end");
}

void
generate_sched_recursive(const char *name, int instance, int nunit, int start, int numhart, int ncommit)
{
	char d[10];
	int x, i, j, k, l, m, n, first;
	for (i = 0; i < instance; i++)
		d[i] = '\t';
	d[instance] = 0;

	printf("%s			casez ({", d);
	first = 1;
	x=0;
	for (k = 0; k < ncommit; k++) {
			for (l = 0; l < numhart; l++) {
				if (x >= start) {
					if (first) {
						first=0;
					} else {
						printf(",");
					}
					printf("%s_r%d[%d]", name, l, k);
				}
				x++;
			}
		}
	printf("}) // synthesis full_case parallel_case\n");
	x = 0;
	for (k = 0; k < ncommit; k++) {
		for (l = 0; l < numhart; l++) {
			if (x >= start) {
				printf("%s			%d'b", d, numhart*ncommit-start);
				for (m = start; m < (k*numhart+l); m++)
					printf("0");
				printf("1");
				for (m= k*numhart+l+1; m < (numhart*ncommit); m++)
					printf("?");
				printf(": begin\n");
				printf("%s					%s_ready%d = 1;\n", d, name, instance);
				printf("%s					%s_out%d = %d+start_commit_%d;\n", d, name, instance, k, l);
				if (numhart > 1)
					printf("%s					%s_hart%d = %d;\n", d, name, instance, l);
				if (instance < (nunit-1)) {
					if ((x+1) < numhart*ncommit) {
						generate_sched_recursive(name, instance+1, nunit, x+1, numhart, ncommit);
					} else {
						for (i = instance+1; i < nunit; i++)
						printf("%s					%s_ready%d = 0;\n", d, name, i);
					}
				}
				printf("%s				end\n", d);
			}
			x++;
		}
    }
	printf("%s			default: begin\n",d);
	for (i = instance; i < nunit; i++)
	printf("%s					%s_ready%d = 0;\n", d, name, i);
	printf("%s				end\n",d);
	printf("%s			endcase\n",d);
	j++;
}

void
local_generate_sched(const char *name, int nunit, int hart, int ncommit)
{
	int i, j, k, m, n, first;

	j = 0;
	for (i = 0; i < nunit; i++) {
		printf("		reg [LNCOMMIT-1:0]%s_out%d_%d;\n", name, j, hart);
		printf("		reg 		%s_ready%d_%d;\n", name, j, hart);
		printf("		assign %s_addr_%d_%d = %s_out%d_%d;\n", name, i, hart, name, j, hart);
		printf("		assign %s_enable_%d_%d =  %s_ready%d_%d;\n", name, i, hart, name, j, hart);
		printf("		always @(*) begin\n");
		printf("			%s_ready%d_%d=0;\n",name,j,hart);
		printf("			%s_out%d_%d='bx;\n",name,j,hart);
		printf("			casez ({");
		first = 1;
		for (k = 0; k < ncommit; k++) {
			if (first) {
				first=0;
			} else {
				printf(",");
			}
			printf("%s_r%d[%d]", name, hart, k);
		}
		printf("}) // synthesis full_case parallel_case\n");
		switch (i) {
		default:
			printf("ERROR - fixme - handle more complex unit scheduling\n");
			fprintf(stderr, "ERROR - fixme - handle more complex unit scheduling\n");
			exit(0);
		case 0: for (k = 0; k < ncommit; k++) {
					printf("			%d'b", ncommit);
					for (m = 0; m < (k); m++)
						printf("0");
					printf("1");
					for (m= k+1; m < (ncommit); m++)
						printf("?");
					printf(": begin\n");
					printf("					%s_ready%d_%d = 1;\n", name, j, hart);
					printf("					%s_out%d_%d = %d+start_commit_%d;\n", name, j, hart, k, hart);
					printf("				end\n");
				}
				break;
		case 1: for (k = 0; k < ncommit; k++) {
					int first = 1;
					if (k == 0)
						continue;
					for (n = 0; n < k; n++) {
						if (first) {
							first = 0;
						} else {
							printf(",\n");
						}
						printf("			%d'b", ncommit);
						for (m = 0; m < (k); m++)
							printf(m==n?"1":"0");
						printf("1");
						for (m= k+1; m < (ncommit); m++)
							printf("?");
					}
					printf(": begin\n");
					printf("					%s_ready%d_%d = 1;\n", name, j, hart);
					printf("					%s_out%d_%d = %d+start_commit_%d;\n", name, j, hart, k, hart);
					printf("				end\n");
				}
				break;
		}
		printf("			default: begin\n");
		printf("					%s_ready%d_%d = 0;\n", name, j, hart);
		printf("				end\n");
		printf("			endcase\n");
		printf("		end\n");
		j++;
	}
}

void
px(int k)
{
	int i;
	for (i = 0; i < k; i++)
		printf("	");
}

void
xrecurse(int hart, int nresolve, int port, int nxferports, int s, int k)
{
	int l;
	px(port);printf("				%d'b", nresolve);
	for (l = 0; l < nresolve; l++) printf(l < s?"?":l < k?"0":l==k?"1":"?");
	printf(": begin\n");
	px(port);printf("					x_write_port_%d_%d = s%d_%d;\n", port, hart, k, hart);
	px(port);printf("					x_write_enable_%d_%d = 1;\n", port, hart);
	px(port);printf("					x_write_ack_%d[s%d_%d] = 1;\n", hart, k, hart);
	port++;
	if (port < nxferports && (k+1) < l) {
		px(port-1);printf("					casez (commit_resolved_masked%d) // synthesis full_case parallel_case\n",hart);
		for (l = k+1; l < nresolve; l++)
				xrecurse(hart, nresolve, port, nxferports, k+1, l);
		px(port-1);printf("					endcase\n");
	}
	px(port-1);printf("					end\n");
	
}

int main(int argc, char ** argv)
{
	int n, i,j,k,l,t;
	int ind, inc, nxferports, ncommit, numhart, nalu, nshift, nbranch, nmul, nload, nstore, nfpu;

	if (argc < 2) {
err:
		fprintf(stderr, "mkctrl [-hdr|-inst|-core] num-xfer-ports num-hart num-commit num-alu num-shift num-branch num-mul num-load num-store\n");
		exit(0);
	} 	
	if (strcmp(argv[1], "-inst")==0) {
		ind = 2;
		inc = 2;
	} else 
	if (strcmp(argv[1], "-hdr")==0) {
		ind = 2;
		inc = 0;
	} else 
	if (strcmp(argv[1], "-core")==0) {
		ind = 2;
		inc = 1;
	} else {
		goto err;
	}
	if (ind >= argc) goto err;
	nxferports = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	numhart = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	ncommit = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	nalu = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	nshift = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	nbranch = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	nmul = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	nload = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	nstore = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	nfpu = strtol((const char *)argv[ind++], 0, 0);
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

	switch (inc) {
	case 0:
		printf("		input [%d-1:0]divide_busy, \n", nmul);
		for (i = 0; i < numhart; i++) {
			printf("		input [LNCOMMIT-1:0]start_commit_%d, \n", i);
			printf("		input [NCOMMIT-1:0]alu_ready_%d, \n", i);
			if (nfpu)
				printf("		input [NCOMMIT-1:0]fpu_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]shift_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]branch_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]mul_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]div_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]load_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]load_not_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]store_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]store_not_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]csr_ready_%d, \n", i);
		}
		for (i = 0; i < nalu; i++) {
			printf("		output [LNCOMMIT-1:0]alu_addr_%d, \n", i);
			if (numhart > 1)
				printf("		output [LNHART-1:0]alu_hart_%d, \n", i);
			printf("		output            alu_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < nfpu; i++) {
			printf("		output [LNCOMMIT-1:0]fpu_addr_%d, \n", i);
			if (numhart > 1)
				printf("		output [LNHART-1:0]fpu_hart_%d, \n", i);
			printf("		output            fpu_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < nshift; i++) {
			printf("		output [LNCOMMIT-1:0]shift_addr_%d, \n", i);
			if (numhart > 1)
				printf("		output [LNHART-1:0]shift_hart_%d, \n", i);
			printf("		output            shift_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < nload; i++) {
			printf("		output [LNCOMMIT-1:0]load_addr_%d, \n", i);
			if (numhart > 1)
				printf("		output [LNHART-1:0]load_hart_%d, \n", i);
			printf("		output            load_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < nstore; i++) {
			printf("		output [LNCOMMIT-1:0]store_addr_%d, \n", i);
			if (numhart > 1)
				printf("		output [LNHART-1:0]store_hart_%d, \n", i);
			printf("		output            store_enable_%d, \n", i);
			printf("\n");
		}
		printf("		input [$clog2(NLDSTQ):0]num_ldstq_available,\n");
		for (i = 0; i < nmul; i++) {
			printf("		output [LNCOMMIT-1:0]mul_addr_%d, \n", i);
			if (numhart > 1)
				printf("		output [LNHART-1:0]mul_hart_%d, \n", i);
			printf("		output            mul_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < numhart; i++) {
			for (j = 0; j < nbranch; j++) {
				printf("		output [LNCOMMIT-1:0]branch_addr_%d_%d, \n", j, i);
				printf("		output            branch_enable_%d_%d, \n", j, i);
				printf("\n");
			}
			printf("		output [LNCOMMIT-1:0]csr_addr_%d, \n", i);
			printf("		output            csr_enable_%d, \n", i);
			printf("\n");
		
		}
		break;
	case 1:
		j = 0;
		for (i = 0; i < numhart; i++) {
			printf("		wire [LNCOMMIT-1:0]sh%d = start_commit_%d;\n", i, i);
			printf("		wire [NCOMMIT-1:0]mul_r_%d = mul_ready_%d|(|divide_busy?0:div_ready_%d);\n",i,i,i); // FIXME - need better solution for multiple multipliers
			printf("		wire [NCOMMIT-1:0]alu_r%d, shift_r%d, branch_r%d, mul_r%d, load_r%d, store_r%d, load_not_r%d, store_not_r%d;\n", i,i,i,i,i,i,i,i);
			if (nfpu)
				printf("		wire [NCOMMIT-1:0]fpu_r%d;\n", i);
			if (nfpu)
				printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))fpu_%d(.in(fpu_ready_%d), .r(sh%d), .out(fpu_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))alu_%d(.in(alu_ready_%d), .r(sh%d), .out(alu_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))sh_%d(.in(shift_ready_%d), .r(sh%d), .out(shift_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))br_%d(.in(branch_ready_%d), .r(sh%d), .out(branch_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))mul_%d(.in(mul_r_%d), .r(sh%d), .out(mul_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))ld_%d(.in(load_ready_%d), .r(sh%d), .out(load_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))ld_n%d(.in(load_not_ready_%d), .r(sh%d), .out(load_not_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))st_%d(.in(store_ready_%d), .r(sh%d), .out(store_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))st_n%d(.in(store_not_ready_%d), .r(sh%d), .out(store_not_r%d));\n", i, i, i, i);
		}
		generate_sched("alu", nalu, numhart, ncommit);
		if (nfpu)
			generate_sched("fpu", nfpu, numhart, ncommit);
		generate_sched("shift", nshift, numhart, ncommit);
		generate_sched_ls(nload, nstore, numhart, ncommit);
		generate_sched("mul", nmul, numhart, ncommit);
		for (j = 0; j < numhart; j++) {
			local_generate_sched("branch", nbranch, j, ncommit);
			printf("		assign csr_addr_%d = start_commit_%d;\n", j, j);
			printf("		assign csr_enable_%d =  csr_ready_%d[start_commit_%d];\n", j, j, j);
		}
		break;
	case 2:	// inst
		j = 0;
		printf("		.divide_busy(divide_busy), \n");
		for (i = 0; i < numhart; i++) {
			printf("		.start_commit_%d(current_start[%d]), \n", i, i);
			if (nfpu)
				printf("		.fpu_ready_%d(fpu_ready_commit[%d]), \n", i, i);
			printf("		.alu_ready_%d(alu_ready_commit[%d]), \n", i, i);
			printf("		.shift_ready_%d(shift_ready_commit[%d]), \n", i, i);
			printf("		.branch_ready_%d(branch_ready_commit[%d]), \n", i, i);
			printf("		.mul_ready_%d(mul_ready_commit[%d]), \n", i, i);
			printf("		.div_ready_%d(div_ready_commit[%d]), \n", i, i);
			printf("		.load_ready_%d(load_ready_commit[%d]&{NCOMMIT{~commit_vm_busy[%d]}}), \n", i, i, i);
			printf("		.load_not_ready_%d(load_not_ready_commit[%d]|(load_ready_commit[%d]&{NCOMMIT{commit_vm_busy[%d]}})), \n", i, i, i, i);
			printf("		.store_ready_%d(store_ready_commit[%d]&{NCOMMIT{~commit_vm_busy[%d]}}), \n", i, i, i);
			printf("		.store_not_ready_%d(store_not_ready_commit[%d]|(store_ready_commit[%d]&{NCOMMIT{commit_vm_busy[%d]}})), \n", i, i, i, i);
			printf("		.csr_ready_%d(csr_ready_commit[%d]), \n", i, i);
		}
		for (i = 0; i < nalu; i++) {
			printf("		.alu_addr_%d(alu_sched[%d]), \n", i, j);
			if (numhart > 1)
				printf("		.alu_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.alu_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < nshift; i++) {
			printf("		.shift_addr_%d(alu_sched[%d]), \n", i, j);
			if (numhart > 1)
				printf("		.shift_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.shift_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < nload; i++) {
			printf("		.load_addr_%d(alu_sched[%d]), \n", i, j);
			if (numhart > 1)
				printf("		.load_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.load_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < nstore; i++) {
			printf("		.store_addr_%d(alu_sched[%d]), \n", i, j);
			if (numhart > 1)
				printf("		.store_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.store_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		printf("		.num_ldstq_available(num_ldstq_available),\n");
		for (i = 0; i < nmul; i++) {
			printf("		.mul_addr_%d(alu_sched[%d]), \n", i, j);
			if (numhart > 1)
				printf("		.mul_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.mul_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < nfpu; i++) {
			printf("		.fpu_addr_%d(alu_sched[%d]), \n", i, j);
			if (numhart > 1)
				printf("		.fpu_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.fpu_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < numhart; i++) {
			j = 0;
			for (k = 0; k < nbranch; k++) {
				printf("		.branch_addr_%d_%d(local_alu_sched[%d][%d]),\n", k, i, j, i);
				printf("		.branch_enable_%d_%d(local_enable_sched[%d][%d]),\n", k, i, j, i);
				printf("\n");
				j++;
			}
			printf("		.csr_addr_%d(local_alu_sched[%d][%d]), \n", i, j, i);
			printf("		.csr_enable_%d(local_enable_sched[%d][%d]), \n", i, j, i);
			j++;
		}
		printf("		.dummy(1'b1));\n");
		if (numhart == 1) {
			j = 0;
			for (i = 0; i < nalu; i++) {
				printf("		assign hart_sched[%d] = 0;\n", j);
				j++;
			}
			for (i = 0; i < nshift; i++) {
				printf("		assign hart_sched[%d] = 0;\n", j);
				j++;
			}
			for (i = 0; i < nload; i++) {
				printf("		assign hart_sched[%d] = 0;\n", j);
				j++;
			}
			for (i = 0; i < nstore; i++) {
				printf("		assign hart_sched[%d] = 0;\n", j);
				j++;
			}
			for (i = 0; i < nmul; i++) {
				printf("		assign hart_sched[%d] = 0;\n", j);
				j++;
			}
			for (i = 0; i < nfpu; i++) {
				printf("		assign hart_sched[%d] = 0;\n", j);
				j++;
			}
		}
		break;
	}
}

/* For Emacs:
 * Local Variables:
 * mode:c
 * indent-tabs-mode:t
 * tab-width:4
 * c-basic-offset:4
 * End:
 * For VIM:
 * vim:set softtabstop=4 shiftwidth=4 tabstop=4:
 */
