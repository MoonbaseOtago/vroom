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
        	fprintf(stderr, "mk13 nldstq nload nstore\n");
        	exit(99);
    	}
    	if (ind >= argc) goto err;
    	nldstq = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nload = strtol((const char *)argv[ind++], 0, 0);
    	if (ind >= argc) goto err;
    	nstore = strtol((const char *)argv[ind++], 0, 0);
	
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


	for (i = 0; i < nload; i++) {
		printf("	always @(*) begin\n");	
		printf("		load_snoop[%d] = %d'bx;\n", i, nldstq);	
		printf("		load_hazard[%d] = %d'bx;\n", i, nldstq);	
		printf("		casez ({r_ldstq_out, load_snoop_hit[%d]}) // synthesis full_case parallel_case\n", i);	
		for (j = 0; j < nldstq; j++) {
			for (k = 0; k < nldstq; k++) {
				char x[100];
				printf("		%d'b", lnldstq+nldstq);	
				for (n = 0; n < lnldstq;n++)printf((1<<(lnldstq-1-n))&((j+1)&(nldstq-1))?"1":"0");
				printf("_");
				for (n = 0; n < nldstq; n++) 
					x[n] = n < k?'0':n==k?'1':'?';
				for (n = 0; n<nldstq; n++)
					printf("%c", x[(n+(j)+1)&(nldstq-1)]);
				printf(": begin load_snoop[%d] = load_snoop_data[%d]; load_hazard[%d] = load_snoop_hazard[%d][%d]; end\n", i, (j-k)&(nldstq-1), i, i, (j-k)&(nldstq-1));
#ifdef NOTDEF
				for (n = 0; n < nldstq; n++) 
					x[n] = n < k?'0':n==k?'1':'?';
				for (n = 0; n<nldstq; n++)
					printf("%c", x[(nldstq-(n+j))&(nldstq-1)]);
				printf(": begin load_snoop[%d] = load_snoop_data[%d]; load_hazard[%d] = load_snoop_hazard[%d][%d]; end\n", i, (k+j+nldstq-1)%(nldstq), i, i, (k+j+nldstq-1)%(nldstq));
#endif
			}
			if (j != (nldstq-1)) printf("\n");
			
		}
		printf("		endcase\n");	
		printf("	end\n");	
	}
	printf("	assign num_allocate = 10'b0");
	for (i = 0; i < nload; i++) printf("+c_load_allocate[%d]\n", i);
	for (i = 0; i < nstore; i++) printf("+c_store_allocate[%d]\n", i);
	printf(";\n");
	printf("	wire [%d-1:0]nallocate;\n",nload+nstore);
	for (i = 0; i < (nstore+nload); i++) {
		int first = 1;
		printf("	assign nallocate[%d] = ", i);
		for (j = 0; j < (1<<(nload+nstore)); j++)
		if (popcount(j) == (i+1)) {
			int xf = 1;
			if (first) {
				first = 0;
			} else {
				printf("|");
			}
			printf("(");
			for (k = 0; k < (nstore+nload); k++)
			if (j&(1<<k)) {
				if (xf) {
					xf = 0;
				} else {
					printf("&");
				}
				if (k < nload) {
					printf("c_load_allocate[%d]", k);
				} else {
					printf("c_store_allocate[%d]", k-nload);
				}
			}
			printf(")");
		}
		printf(";\n");
		printf("	wire [$clog2(NLDSTQ)-1:0]w_%d=r_ldstq_out+%d;\n",i,i);
	}
	
	printf("	wire [%d-1:0]wallocate[0:NLDSTQ-1];\n", nload+nstore);
	printf("	wire [NLDSTQ-1:0]callocate[0:%d-1];\n", nload+nstore);
	for (i = 0; i < nldstq; i++) {
		for (j = 0; j < (nload+nstore); j++) {
			printf("	assign wallocate[%d][%d] = (w_%d == %d);\n", i, j, j, i);
			printf("	assign callocate[%d][%d] = nallocate[%d]&wallocate[%d][%d];\n", j, i, j, i, j);
		}
	}
		
	for (i = 0; i < nldstq; i++) {
		int first = 1;
		printf("	assign q_allocate[%d] = ", i);
		for (j = 0; j < (nload+nstore); j++) {
			if (first) {
				first = 0;
			} else {
				printf("|");
			}
			printf("callocate[%d][%d]", j, i);
		}
		printf(";\n");
	}
	printf("	wire [NLDSTQ-1:0]a_line_hit[0:%d-1];\n", nload+nstore);
	printf("	assign a_line_hit[0] = 0;\n");
	for (i = 1; i < (nload+nstore); i++) {
		char *i0 = i < nload?"c_load_io":"c_store_io";
		char *c0 = i < nload?"c_load_paddr":"c_store_paddr";
		int n0 = i < nload?i:i-nload;
		for (j = 0; j < i; j++) {
			char *i1 = j < nload?"c_load_io":"c_store_io";
			char *c1 = j < nload?"c_load_paddr":"c_store_paddr";
			int n1 = j < nload?j:j-nload;
			printf("	reg xline_hit_%d_%d;\n",i,j);
			printf("	always @(*) begin\n");
			!printf("		xline_hit_%d_%d = %s[%d][NPHYS-1:ACACHE_LINE_SIZE] == %s[%d][NPHYS-1:ACACHE_LINE_SIZE] && !%s[%d] && !%s[%d];\n",i,j,c0,n0,c1,n1,i0,n0,i1,n1);
			printf("	end\n");
		}
		printf("	assign a_line_hit[%d] = ", i);
		for (j = 0; j < i; j++) {
			if (j != 0)
				printf("|");
			printf("(xline_hit_%d_%d?callocate[%d]:0)", i,j,j);
		}
		printf(";\n");
	}
	for (n = 0; n < nldstq; n++) {
		printf("        assign wq_new_active[%d] = (", n);
		for (i = 0; i < (nload+nstore-1); i++) {
			int g=0;
			for (j = 0; j <= i; j++)
				g += (1<<((n-1-j)&(nldstq-1)));
			printf("r_ldstq_out==%d ? ", (n-i-1)&(nldstq-1));
			printf("(nallocate[%d:0]!=0?%d:0):", i,g);
		}
		printf("0);\n");
	}
	printf("	reg [%d-1:0]xallocate[0:NLDSTQ-1];\n", nload+nstore);
	for (n = 0; n < nldstq; n++) {
		printf("	always @(*) begin\n");
		printf("		xallocate[%d] = 0;\n",n);
		printf("		casez ({");
		for (j=0;j<(nload+nstore); j++) printf("wallocate[%d][%d],",n,j);
		for (j=0;j<(nload); j++) printf("c_load_allocate[%d],",j);
		for (j=0;j<(nstore); j++) printf("c_store_allocate[%d]%s",j,j<(nstore-1)?",":"");
		printf("}) // synthesis full_case parallel_case\n");
		for (m = 0; m < (nload+nstore); m++) {
			int first = 1;
			printf("		");
			for (i = 0; i < (nload+nstore); i++) {
				for (j = 0; j < (1<<(nload+nstore)); j++)
				if (j&(1<<m)) {
					int q = j&((1<<(m+1))-1);
					if (q != j)break;
					if (popcount(q) == (i+1)) {
						if (first) {
							first = 0;
						} else {
							printf(",\n		");
						}
						printf("%d'b", 2*(nload+nstore));
						for (k = 0;k<(nload+nstore);k++) printf(k==i?"1":"?");
						printf("_");
						for (k = 0;k<(nload);k++) printf((1<<k)&q?"1":(1<<k)>q?"?":"0");
						printf("_");
						for (k = nload;k<(nstore+nload);k++) printf((1<<k)&q?"1":(1<<k)>q?"?":"0");
					}
				}
			}
			printf(": xallocate[%d][%d] = 1;\n", n, m);
		}
		printf("		default: ;\n");
		printf("		endcase\n");
		printf("	end\n");
	}
	printf("	always @(*) begin\n");
	printf("		casez (iload_enable) // synthesis full_case parallel_case\n");
	for (i = 0; i < ((1<<nload)-1); i++)
	printf("		%d: q_load_unit_s0 = %d;\n", i, popcount(i));
	printf("		default: q_load_unit_s0 = 'bx;\n"); 
	printf("		endcase\n");
	printf("	end\n");
	for (i = 0; i < nldstq; i++) {
		int first = 1;
		printf("	assign q_load[%d] = ", i);
		for (j = 0; j < nload; j++) {
			if (first) {
				first = 0;
			} else {
				printf("|");
			}
			printf("xallocate[%d][%d]", i, j);
		}
		printf(";\n");
		first = 1;
		printf("	assign q_store[%d] = ", i);
		for (j = nload; j < (nload+nstore); j++) {
			if (first) {
				first = 0;
			} else {
				printf("|");
			}
			printf("(xallocate[%d][%d]&!c_store_fence[%d])", i, j, j-nload);
		}
		printf(";\n");
		first = 1;
		printf("	assign q_fence_type[%d] = ", i);
		for (j = nload; j < (nload+nstore); j++) {
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?r_store_control[%d][4:3]:", i, j, j-nload);
			} else {
				printf("r_store_control[%d][4:3]", j-nload);
			}
		}
		printf(";\n");
		first = 1;
		printf("	assign q_amo[%d] = ", i);
		for (j = 0; j < (nload+nstore); j++) {
			if (j < (nload)) {
				printf("xallocate[%d][%d]?{5'bx,r_load_control[%d][4]}:", i, j, j < nload?j:j-nload);
			} else
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?{r_store_amo[%d],r_store_control[%d][4]}:", i, j,j < nload?j:j-nload, j < nload?j:j-nload);
			} else {
				printf("{r_store_amo[%d],r_store_control[%d][4]}", j < nload?j:j-nload, j < nload?j:j-nload);
			}
		}
		printf(";\n");
		first = 1;
		printf("	assign q_fence[%d] = ", i);
		for (j = nload; j < (nload+nstore); j++) {
			if (first) {
				first = 0;
			} else {
				printf("|");
			}
			printf("(xallocate[%d][%d]&c_store_fence[%d])", i, j, j-nload);
		}
		printf(";\n");
		first = 1;
		printf("	assign q_cache_miss[%d] = (", i);
		for (j = 0; j < (nload); j++) {
			int xx =  j < nload?j:j-nload;
			printf("xallocate[%d][%d]?!dc_rd_hit[%d]||(dc_rd_lr[%d]&&dc_rd_hit_need_o[%d]):", i, j, xx, xx, xx);
		}
		printf("0);\n");
		first = 1;
		printf("	assign q_data[%d] = (", i);
		for (j = nload; j < (nload+nstore); j++) {
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?c_store_data[%d]:", i,j,j-nload);
			} else {
				printf("c_store_data[%d]", j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_io[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"c_load_io":"c_store_io");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i, j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_addr[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char c[256];
			char *cp = &c[0];
			if (j < nload) {
				snprintf(c, sizeof(c), "c_load_paddr[%d]", j);
			} else {
				snprintf(c, sizeof(c), "(c_store_fence[%d]&&(r_store_control[%d][2:0]<3)?c_store_vaddr[%d]:c_store_paddr[%d])", j-nload, j-nload, j-nload, j-nload);
			}
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s:", i, j,cp);
			} else {
				printf("%s", cp);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_fd[%d] = (", i);
		for (j = nload; j < (nload+nstore); j++) {
			char *cp = "r_store_fd";
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_aq_rl[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_aq_rl":"r_store_aq_rl");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("`ifdef FP\n");
		printf("	assign q_fp[%d] = (", i);
		for (j = 0; j < (nload); j++) {
			char *cp = (j < nload?"r_load_fp":"r_store_fp");
			if (j != (nload-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		printf("`endif\n");
		first = 1;
		printf("	assign q_rd[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_rd":"r_store_rd");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_makes_rd[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_makes_rd":"r_store_makes_rd");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_mask[%d] = (", i);
		for (j = nload; j < (nload+nstore); j++) {
			char *cp = "c_store_mask";
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_hart[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_hart":"r_store_hart");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_control[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_control":"r_store_control");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_hazard[%d] = (", i);
		for (j = 0; j < (nload); j++) {
			if (j != (nload-1)) {
				printf("xallocate[%d][%d]?load_snoop_hazard[%d]:", i, j,j < nload?j:j-nload);
			} else {
				printf("load_snoop_hazard[%d]", j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_line_hit[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"load_snoop_line_hit":"store_snoop_line_hit");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]|a_line_hit[%d]:", i, j,cp,j < nload?j:j-nload, j);
			} else {
				printf("%s[%d]|a_line_hit[%d]", cp, j < nload?j:j-nload,j);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_load_ack[%d] = ", i);
		for (j = 0; j < (nload); j++) {
			if (first) {
				first = 0;
			} else {
				printf("||");
			}
			printf("(c_load_queued_ready[%d] && !iload_enable[%d] && (c_load_queued_index[%d] == %d))", j,j,j,i);
		}
		printf(";\n");
		first = 1;
		printf("	assign q_load_ack_fail[%d] = ", i);
		for (j = 0; j < (nload); j++) {
			if (first) {
				first = 0;
			} else {
				printf("||");
			}
			printf("(r_load_state[%d] && r_load_queued[%d] && (r_load_ack_entry[%d] == %d) && !dc_rd_hit[%d])", j,j,j,i,j);
		}
		printf(";\n");
	}
	printf("	reg [NLDSTQ-1:0]ldr;\n");
	printf("	reg [NLOAD-1:0]lden;\n");
	printf("	reg [$clog2(NLDSTQ)-1:0]ldi[0:NLOAD-1];\n");
	printf("	always @(*) begin\n");
	for (i = 0; i < nload; i++) 
		printf("		c_load_queued_index[%d] = 'bx;\n",i);
	printf("		case (r_ldstq_in) // synthesis full_case parallel_case\n");
	for (i = 0; i < nldstq; i++) {
		printf("		%d: ldr = {", i);
		for (j = 0; j < nldstq; j++) 
			printf("%sload_ready[%d]", j==0?"":",", (i+j)%nldstq);
		printf("};\n");
	}
	printf("		endcase\n");
	for (i = 0; i < nload; i++) {
		printf("		ldi[%d] = 'bx;\n",i);
		printf("		casez (ldr) // synthesis full_case parallel_case\n");
		for (j = i; j < nldstq; j++) {
			int first = 1;
			printf("		");
			for (k = 0; k < (1<<nldstq); k++)
			if (popcount(k) == (i+1) && k&(1<<j) && k < (1<<(j+1))) {
				if (first) {
					first = 0;
				} else {
					printf(",\n		");
				}
				printf("%d'b", nldstq);
				for (m = 0; m < nldstq; m++)
					printf(k&(1<<m)?"1":(1<<m) > k?"?":"0");
			}
			printf(": begin lden[%d] = 1; ldi[%d] = r_ldstq_in+%d; end\n", i, i, j);
		}
		printf("		default: lden[%d] = 0;\n", i);
		printf("		endcase\n");
	}
	printf("		c_load_queued_ready = 0;\n");
	printf("		if (!iload_enable[0]) begin\n");
	printf("			c_load_queued_ready[0] = lden[0];\n");
	printf("			c_load_queued_index[0] = ldi[0];\n");
	printf("			if (!iload_enable[1]) begin\n");
	printf("				c_load_queued_ready[1] = lden[1];\n");
	printf("				c_load_queued_index[1] = ldi[1];\n");
	if (nload > 2) {
	printf("				if (!iload_enable[2]) begin\n");
	printf("					c_load_queued_ready[2] = lden[2];\n");
	printf("					c_load_queued_index[2] = ldi[2];\n");
	printf("				end\n");
	printf("			end else\n");
	printf("			if (!iload_enable[2]) begin\n");
	printf("				c_load_queued_ready[2] = lden[1];\n");
	printf("				c_load_queued_index[2] = ldi[1];\n");
	}
	printf("			end\n");
	printf("		end else\n");
	printf("		if (!iload_enable[1]) begin\n");
	printf("			c_load_queued_ready[1] = lden[0];\n");
	printf("			c_load_queued_index[1] = ldi[0];\n");
	if (nload > 2) {
	printf("			if (!iload_enable[2]) begin\n");
	printf("				c_load_queued_ready[2] = lden[1];\n");
	printf("				c_load_queued_index[2] = ldi[1];\n");
	printf("			end\n");
	printf("		end else\n");
	printf("		if (!iload_enable[2]) begin\n");
	printf("			c_load_queued_ready[2] = lden[0];\n");
	printf("			c_load_queued_index[2] = ldi[0];\n");
	}
	printf("		end\n");
			
	printf("		q_mem_hart='bx;\n");
	printf("		q_mem_sc='bx;\n");
	printf("		q_mem_mask='bx;\n");
	printf("		q_mem_data='bx;\n");
	printf("		q_mem_addr='bx;\n");
	printf("		q_mem_io='bx;\n");
	printf("		q_mem_amo='bx;\n");
	printf("		casez (store_mem) // synthesis full_case parallel_case\n");
	for (i = 0; i < nldstq; i++) {
		printf("		%d'b",nldstq);
		for (j = 0; j < nldstq; j++) printf(j==(nldstq-1-i)?"1":"?");
		printf(": begin q_mem_mask = write_mem_mask[%d]; q_mem_data = write_mem_data[%d]; q_mem_addr = write_mem_addr[%d][NPHYS-1:(RV==64?3:2)]; q_mem_hart = write_mem_hart[%d]; q_mem_sc = write_mem_sc[%d]; q_mem_amo = write_mem_amo[%d]; q_mem_io = write_mem_io[%d]; end\n", i, i,i,i,i,i,i);
	}
	printf("		endcase\n");
	printf("	end\n");
	printf("	always @(*) begin\n");
	printf("		tlb_inv_type = 'bx;\n");
	printf("		tlb_inv_addr = 'bx;\n");
	printf("		tlb_inv_asid = 'bx;\n");
	printf("		tlb_inv_hart = 'bx;\n");
	printf("		casez (fence_tlb_invalidate) // synthesis full_case parallel_case\n");
	for (i = 0; i < nldstq; i++) {
		printf("		%d'b", nldstq);
		for (j = nldstq-1; j >= 0; j--) printf(j==i?"1":"?");
		printf(": begin tlb_inv_type = fence_tlb_inv_type[%d]; tlb_inv_addr = write_mem_addr[%d][VA_SZ-1:12]; tlb_inv_asid=write_mem_data[%d][15:0]; tlb_inv_hart = wq_hart[%d]; end\n", i,i,i,i);
	}
	printf("		endcase\n");
	printf("	end\n");
}
