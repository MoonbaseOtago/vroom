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

void
generate_sched(const char *name, int nunit, int numhart, int ncommit, int seperate)
{
	int i, j, k, l, m, n, first;

	j = 0;
	for (j = 0; j < nunit; j++) {
		printf("		reg [LNCOMMIT-1:0]%s_out%d;\n", name, j);
		printf("		reg 		%s_ready%d;\n", name, j);
		if (numhart > 1) {
			printf("		reg [LNHART-1:0]%s_hart%d;\n", name, j);
			printf("		assign %s_hart_%d = %s_hart%d;\n", name, j, name, j);
		} else {
			printf("		assign %s_hart_%d = 0;\n", name, j);
		}
		printf("		assign %s_addr_%d = %s_out%d;\n", name, j, name, j);
		printf("		assign %s_enable_%d =  %s_ready%d;\n", name, j, name, j);
	}

	if (nunit > 1)
		printf("	reg [%d-1:0]%s_inh[0:%d-2];\n", ncommit*numhart, name, nunit);
	for (l = 0; l < nunit; l++) {
		printf("        always @(*) begin\n");
		printf("                %s_ready%d = 0;\n", name, l);
		if (l != (nunit-1))
		printf("                %s_inh[%d] = 0;\n", name, l);
		printf("                %s_out%d = 'bx;\n", name, l);
		if (numhart > 1)
		printf("                %s_hart%d = 'bx;\n", name, l);
		if (seperate) {
		printf("                c_%s_sched_state_%d = {1'b0, r_%s_sched_state_%d[2]};\n", name, l, name, l);
		}
        printf("                casez ({");
		if (seperate) {
			if (numhart == 1) {
				printf("%s_r%d_%c%d[%d:%d]", name, 0, seperate, l, ncommit-1, l);
			} else
			for (i=ncommit*numhart-1;i >= l; i--) {
				int h = i%numhart;
				int b = i / numhart;
				printf("%s_r%d_%c%d[%d]%s", name, h, seperate, l,b,(i==l?"":","));
			}
		} else {
			if (numhart == 1) {
				printf("%s_r%d[%d:%d]", name, 0, ncommit-1, l);
			} else
			for (i=ncommit*numhart-1;i >= l; i--) {
				int h = i%numhart;
				int b = i / numhart;
				printf("%s_r%d[%d]%s", name, h,b,(i==l?"":","));
			}
		}
		printf("}");
        for (j=0; j < l; j++) printf("&~%s_inh[%d][NCOMMIT-1:%d]", name, j, l);
                        printf(") // synthesis full_case parallel_case\n");
        for (j = l; j < ncommit*numhart; j++) {
        printf("                %d'b", ncommit*numhart-l);
        for (k = ncommit*numhart-1; k >= l; k--) printf("%s", k < j ? "0":k==j ? "1":"?");
                              printf(": begin\n");
        printf("                                                                %s_ready%d = 1;\n", name, l);
        printf("                                                                %s_out%d = start_commit_%d+%d;\n", name, l, j%numhart, j/numhart);
		if (strcmp(name, "fpu") == 0) {
        printf("                                                                fpu_div[%d] =  fpu_div_ready[%d][start_commit_%d+%d];\n", l, l, j%numhart, j/numhart);
		}
		if (numhart > 1)
        printf("                                                                %s_hart%d = %d;\n", name, l, j%numhart);
        if (l != (nunit-1))
        printf("                                                                %s_inh[%d][%d] = 1;\n", name, l, j);
		if (seperate) {
		printf("																c_%s_sched_state_%d = {1'b0, r_%s_sched_state_%d[2]}|%s_tsize[%d][%s_out%d];\n", name, l, name, l, name, j%numhart, name, l);
		}
        printf("                                                        end\n");
        }
        printf("                %d'b", ncommit*numhart-l);
        for (k = 0; k < (ncommit*numhart-l); k++) printf("0"); printf(": ;\n");
        printf("                endcase\n");
        printf("        end\n");
	}
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
	int ind, inc, nxferports, ncommit, numhart, nalu, nshift, nbranch, nmul, nfpu;

	if (argc < 2) {
err:
		fprintf(stderr, "mkctrl [-hdr|-inst|-core] num-xfer-ports num-hart num-commit num-alu num-shift num-branch num-mul\n");
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
	nfpu = strtol((const char *)argv[ind++], 0, 0);
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

	switch (inc) {
	case 0:
		printf("		input [%d-1:0]divide_busy, \n", nmul);
		if (nfpu) {
			printf("	    input [%d-1:0]fpu_div_done,\n", nfpu);
		}
		for (i = 0; i < numhart; i++) {
			printf("		input [LNCOMMIT-1:0]start_commit_%d, \n", i);
			printf("		input [NCOMMIT-1:0]alu_ready_%d, \n", i);
			if (nfpu) {
				for (j = 0; j < ncommit; j++)
				printf("		input [3:0]fpu_ready_%d_%d, \n", i, j);
			}
			printf("		input [NCOMMIT-1:0]shift_ready_%d, \n", i);
			printf("`ifndef COMBINED_BRANCH\n");
			printf("		input [NCOMMIT-1:0]branch_ready_%d, \n", i);
			printf("`endif\n");
			printf("		input [NCOMMIT-1:0]mul_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]div_ready_%d, \n", i);
			printf("		input [NCOMMIT-1:0]csr_ready_%d, \n", i);
		}
		for (i = 0; i < nalu; i++) {
			printf("		output [LNCOMMIT-1:0]alu_addr_%d, \n", i);
			printf("		output [LNHART-1:0]alu_hart_%d, \n", i);
			printf("		output            alu_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < nfpu; i++) {
			printf("		output [LNCOMMIT-1:0]fpu_addr_%d, \n", i);
			printf("		output [LNHART-1:0]fpu_hart_%d, \n", i);
			printf("		output            fpu_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < nshift; i++) {
			printf("		output [LNCOMMIT-1:0]shift_addr_%d, \n", i);
			printf("		output [LNHART-1:0]shift_hart_%d, \n", i);
			printf("		output            shift_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < nmul; i++) {
			printf("		output [LNCOMMIT-1:0]mul_addr_%d, \n", i);
			printf("		output [LNHART-1:0]mul_hart_%d, \n", i);
			printf("		output            mul_enable_%d, \n", i);
			printf("\n");
		}
		for (i = 0; i < numhart; i++) {
			printf("`ifndef COMBINED_BRANCH\n");
			for (j = 0; j < nbranch; j++) {
				printf("		output [LNCOMMIT-1:0]branch_addr_%d_%d, \n", j, i);
				printf("		output            branch_enable_%d_%d, \n", j, i);
				printf("\n");
			}
			printf("`endif\n");
			printf("		output [LNCOMMIT-1:0]csr_addr_%d, \n", i);
			printf("		output            csr_enable_%d, \n", i);
			printf("\n");
		
		}
		break;
	case 1:
		j = 0;
		if (nfpu) {
			printf("	reg  [%d-1:0]r_fpu_div_busy;\n", nfpu);
			printf("	reg  [%d-1:0]fpu_div;\n", nfpu);
			for (i = 0; i < nfpu; i++) {
			printf("	always @(posedge clk) begin\n");
			printf("		if (reset) r_fpu_div_busy[%d] <= 0; else\n", i);
			printf("		if (fpu_ready%d && fpu_div[%d]) r_fpu_div_busy[%d] <= 1; else\n", i, i, i);
			printf("		if (fpu_div_done[%d]) r_fpu_div_busy[%d] <= 0;\n", i, i);
			printf("	end\n");
			}
			printf("	wire [2:1]fpu_tsize[0:NHART-1][0:NCOMMIT-1];\n");
			printf("	wire fpu_div_ready[0:NHART-1][0:NCOMMIT-1];\n");
		}
		for (i = 0; i < numhart; i++) {
			printf("		wire [LNCOMMIT-1:0]sh%d = start_commit_%d;\n", i, i);
			printf("		wire [NCOMMIT-1:0]mul_r_%d = mul_ready_%d|(|divide_busy?0:div_ready_%d);\n",i,i,i); // FIXME - need better solution for multiple multipliers
			printf("		wire [NCOMMIT-1:0]alu_r%d, shift_r%d, mul_r%d;\n", i,i,i);
			if (nfpu) {
				for (k = 0; k < ncommit; k++) {
				printf("	assign fpu_tsize[%d][%d] = fpu_ready_%d_%d[2:1];\n", i, k, i, k);
				printf("	assign fpu_div_ready[%d][%d] = fpu_ready_%d_%d[3];\n", i, k, i, k);
				}
				for (j = 0; j < nfpu; j++) {
					printf("		reg [2:1]r_fpu_sched_state_%d, c_fpu_sched_state_%d;\n", j, j);
					printf("		always @(posedge clk) r_fpu_sched_state_%d <= (reset?2'b0:c_fpu_sched_state_%d);\n", j, j);
					printf("		wire [3:0]fp_ok_%d = {~r_fpu_div_busy[%d]|fpu_div_done[%d], 1'b1, ~r_fpu_sched_state_%d[2:1]};\n", j, j, j, j);
					printf("		wire [NCOMMIT-1:0]fpu_r%d_f%d;\n", i, j);
					printf("		wire [NCOMMIT-1:0]fpu_ready_%d_f%d;\n", i, j);
					for (k = 0; k < ncommit; k++)
					printf("		assign fpu_ready_%d_f%d[%d] = |(fpu_ready_%d_%d&fp_ok_%d);\n", i, j, k, i, k, j);
					printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))fpu_%d_f%d(.in(fpu_ready_%d_f%d), .r(sh%d), .out(fpu_r%d_f%d));\n", i, j, i, j, i, i, j);
				}
			}
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))alu_%d(.in(alu_ready_%d), .r(sh%d), .out(alu_r%d));\n", i, i, i, i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))sh_%d(.in(shift_ready_%d), .r(sh%d), .out(shift_r%d));\n", i, i, i, i);
			printf("`ifndef COMBINED_BRANCH\n");
			printf("		wire [NCOMMIT-1:0]branch_r%d;\n", i);
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))br_%d(.in(branch_ready_%d), .r(sh%d), .out(branch_r%d));\n", i, i, i, i);
			printf("`endif\n");
			printf("		rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))mul_%d(.in(mul_r_%d), .r(sh%d), .out(mul_r%d));\n", i, i, i, i);
		}
		generate_sched("alu", nalu, numhart, ncommit, 0);
		if (nfpu)
			generate_sched("fpu", nfpu, numhart, ncommit, 'f');
		generate_sched("shift", nshift, numhart, ncommit, 0);
		generate_sched("mul", nmul, numhart, ncommit, 0);
		for (j = 0; j < numhart; j++) {
			printf("`ifndef COMBINED_BRANCH\n");
			local_generate_sched("branch", nbranch, j, ncommit);
			printf("`endif\n");
			printf("		assign csr_addr_%d = start_commit_%d;\n", j, j);
			printf("		assign csr_enable_%d =  csr_ready_%d[start_commit_%d];\n", j, j, j);
		}
		break;
	case 2:	// inst
		j = 0;
		printf("		.divide_busy(divide_busy), \n");
		for (i = 0; i < numhart; i++) {
			printf("		.start_commit_%d(current_start[%d]), \n", i, i);
			if (nfpu) {
				for (k = 0; k < ncommit; k++)
				printf("		.fpu_ready_%d_%d(fpu_ready_commit[%d][%d]),\n", i, k, i, k);
			}
			printf("		.alu_ready_%d(alu_ready_commit[%d]), \n", i, i);
			printf("		.shift_ready_%d(shift_ready_commit[%d]), \n", i, i);
			printf("`ifndef COMBINED_BRANCH\n");
			printf("		.branch_ready_%d(branch_ready_commit[%d]), \n", i, i);
			printf("`endif\n");
			printf("		.mul_ready_%d(mul_ready_commit[%d]), \n", i, i);
			printf("		.div_ready_%d(div_ready_commit[%d]), \n", i, i);
			printf("		.csr_ready_%d(csr_ready_commit[%d]), \n", i, i);
		}
		for (i = 0; i < nalu; i++) {
			printf("		.alu_addr_%d(alu_sched[%d]), \n", i, j);
			printf("		.alu_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.alu_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < nshift; i++) {
			printf("		.shift_addr_%d(alu_sched[%d]), \n", i, j);
			printf("		.shift_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.shift_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < nmul; i++) {
			printf("		.mul_addr_%d(alu_sched[%d]), \n", i, j);
			printf("		.mul_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.mul_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		for (i = 0; i < nfpu; i++) {
			printf("		.fpu_addr_%d(alu_sched[%d]), \n", i, j);
			printf("		.fpu_hart_%d(hart_sched[%d]), \n", i, j);
			printf("		.fpu_enable_%d(enable_sched[%d]), \n", i, j);
			printf("\n");
			j++;
		}
		if (nfpu) {
			printf("		.fpu_div_done(fpu_div_done), \n");
		}
		for (i = 0; i < numhart; i++) {
			j = 0;
			printf("`ifndef COMBINED_BRANCH\n");
			for (k = 0; k < nbranch; k++) {
				printf("		.branch_addr_%d_%d(local_alu_sched[%d][%d]),\n", k, i, j, i);
				printf("		.branch_enable_%d_%d(local_enable_sched[%d][%d]),\n", k, i, j, i);
				printf("\n");
				j++;
			}
			printf("`endif\n");
			printf("		.csr_addr_%d(local_alu_sched[%d][%d]), \n", i, j, i);
			printf("		.csr_enable_%d(local_enable_sched[%d][%d]), \n", i, j, i);
			j++;
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
