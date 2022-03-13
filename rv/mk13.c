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

	printf("	always @(*) begin\n");	
	printf("		io_ack = 0;\n");	
	printf("		io_req = 'bx;\n");	
	printf("		casez (write_io_read_req|write_io_write_req) // synthesis full_case parallel_case\n");	
	for (i = 0; i < nldstq; i++) {
	printf("		%d'b", nldstq);
	for (j = nldstq-1; j >= 0; j--) printf(j < i?"0":i==j?"1":"?");
	printf(": begin io_req = %d; io_ack[%d] = 1; end\n", i, i);
	}
	printf("		%d'b", nldstq);
	for (j = nldstq-1; j >= 0; j--) printf("0");
	printf(": ;\n");
	printf("		endcase\n");	
	printf("	end\n");	

	for (i = 0; i < nload; i++) {
		printf("	assign load_snoop_hit_mask[%d] = load_snoop.ack[%d].hit&~(",i,i);
		for (j = 0; j < nldstq; j++) {
			printf("%s(load_snoop.ack[%d].hit[%d]?depends[%d]:0)",(j==0?"":"|"), i,j,j);
		} 
		printf(");\n");	
		printf("	always @(*) begin\n");	
		printf("		load_snoop_result[%d] = %d'bx;\n", i, nldstq);	
		printf("		load_hazard[%d] = %d'bx;\n", i, nldstq);	
		printf("		casez (load_snoop_hit_mask[%d]) // synthesis full_case parallel_case\n", i);	
			for (k = 0; k < nldstq; k++) {
//				char x[100];
				printf("		%d'b", nldstq);	
				for (n = nldstq-1; n >= 0; n--) 
					printf(n==k?"1":"?");
//					x[n] = n==k?'1':'?';
//				for (n = 0; n<nldstq; n++)
//					printf("%c", x[(n+(j)+1)&(nldstq-1)]);
				printf(": begin load_snoop_result[%d] = load_snoop_data[%d]; load_hazard[%d] = load_snoop.ack[%d].hazard[%d]; end\n", i, k, i, i, k);
			}
			if (j != (nldstq-1)) printf("\n");
			
		printf("		endcase\n");	
		printf("	end\n");	
	}
	printf("	wire [%d-1:0]nallocate_n;\n",nload+nstore);
	printf("	reg [%d-1:0]nallocate;\n",nload+nstore);
	printf("	reg [NLDSTQ-1:0]ldstq_allocated[0:%d-1];\n",nload+nstore);
	for (i = 0; i < (nstore+nload); i++) {
		int first = 1;
		printf("	assign nallocate_n[%d] = ", i);
		for (j = 0; j < (1<<(nload+nstore)); j++)
		if (popcount(j) == (i+1)) {
			int xf = 1;
#ifdef NOTDEF
			int cont=0;

			for (k = 0; k < nload; k++) 
			if (!(j&(1<<k))) {	
				for (k++; k < nload; k++)
				if (j&(1<<k)) {
					cont = 1;
					break;
				}
				break;
			}
			for (k = nload; k < (nload+nstore); k++) 
			if (!(j&(1<<k))) {	
				for (k++; k < (nload+nstore); k++)
				if (j&(1<<k)) {
					cont = 1;
					break;
				}
				break;
			}
			if (cont)
				continue;
#endif
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
					printf("load_allocate[%d]", k);
				} else {
					printf("store_allocate[%d]", k-nload);
				}
			}
			printf(")");
		}
		printf(";\n");
		printf("	reg [$clog2(NLDSTQ)-1:0]w_%d;\n",i);
		printf("	always @(*) begin\n");
		printf("		w_%d='bx;\n",i);
		printf("		ldstq_allocated[%d] = 0;\n",i);
		printf("		nallocate[%d] = nallocate_n[%d];\n",i, i);
       		printf("                casez (all_active[NLDSTQ-1-1:%d]", i);
        	for (j=0; j < i; j++) printf("|ldstq_allocated[%d][NLDSTQ-1:%d]", j, i);
                        printf(") // synthesis full_case parallel_case\n");
		for (j = i; j < nldstq; j++) {
		printf("		%d'b", nldstq-i);
		for (k = nldstq-1; k >= i; k--) printf(k > j?"?":k==j?"0":"1");
		printf(": begin ");
		printf("ldstq_allocated[%d][%d] = 1; ", i, j);
		printf("w_%d=%d; end\n", i, j);
		}
		printf("		%d'b", nldstq-i);
		for (k = nldstq-1; k >= i; k--) printf("1");
		printf(": begin nallocate[%d] = 0; end\n", i);
		printf("		endcase\n");
		printf("	end\n");
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
#ifdef NOTDE
	printf("	wire [NLDSTQ-1:0]a_line_hit[0:%d-1];\n", nload+nstore);
	printf("	assign a_line_hit[0] = 0;\n");
	for (i = 1; i < (nload+nstore); i++) {
		char *i0 = i < nload?"r_load_io":"r_store_io";
		char *c0 = i < nload?"r_load_paddr":"r_store_paddr";
		int n0 = i < nload?i:i-nload;
		for (j = 0; j < i; j++) {
			char *i1 = j < nload?"r_load_io":"r_store_io";
			char *c1 = j < nload?"r_load_paddr":"r_store_paddr";
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
	printf("        assign wq_new_active = ");
	for (i = 0; i < (nload+nstore); i++) {
		printf("ldstq_allocated[%d]%s", i, i != (nload+nstore-1)?"|":";\n");
	}
#endif
	printf("	reg [%d-1:0]xallocate[0:NLDSTQ-1];\n", nload+nstore);
	for (n = 0; n < nldstq; n++) {
		printf("	always @(*) begin\n");
		printf("		xallocate[%d] = 0;\n",n);
		printf("		casez ({");
		for (j=0;j<(nload+nstore); j++) printf("wallocate[%d][%d],",n,j);
		for (j=0;j<(nload); j++) printf("load_allocate[%d],",j);
		for (j=0;j<(nstore); j++) printf("store_allocate[%d]%s",j,j<(nstore-1)?",":"");
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
	printf("		casez (load_enable&load_queued) // synthesis full_case parallel_case\n");
	for (i = 0; i < nload; i++) {
	printf("		%d'b", nload);
	for (j=nload-1;j >= 0; j--) printf(j > i?"?":i==j?"1":"0");
	printf(": q_load_unit_s0 = %d;\n", i);
	}
	printf("		default: q_load_unit_s0 = 'bx;\n"); 
	printf("		endcase\n");
	printf("	end\n");
	for (i = 0; i < (nload+nstore); i++) {
		char *cp = (i < nload?"load":"store");
		printf("	always @(*) begin\n");
		printf("		%s_line_busy_index[%d] = 'bx;\n", cp, i < nload?i:i-nload);
		printf("		casez (%s_snoop.ack[%d].line_busy) // synthesis full_case parallel_case\n", cp, i < nload?i:i-nload);
		for (j = 0; j < nldstq; j++) {
		printf("		%d'b", nldstq);
		for (k=nldstq-1;k>=0;k--)printf(j==k?"1":"?");
		printf(": %s_line_busy_index[%d] = %d;\n", cp, i < nload?i:i-nload, j);
		}
		printf("		endcase\n");
		printf("	end\n");
	}
	printf("	reg [NLOAD+NSTORE-1:0]j_line_busy;\n");
	printf("	reg [TRANS_ID_SIZE-1:0]j_line_busy_index[0:NLOAD+NSTORE-1];\n");
	for (i=0; i < (nload+nstore); i++) {
	char *cp = (i < nload?"load":"store");
	printf("	always @(*)\n");
	printf("	if (dc_raddr_req && dc_raddr_ack && dc_raddr[NPHYS-1:ACACHE_LINE_SIZE]==%s_snoop.req[%d].addr[NPHYS-1:ACACHE_LINE_SIZE]) begin\n", cp, i<nload?i:i-nload);
	printf("		j_line_busy[%d] = 1; j_line_busy_index[%d] = dc_raddr_trans;\n", i, i);
	printf("	end else begin\n");
	printf("		j_line_busy[%d] = |%s_snoop.ack[%d].line_busy; j_line_busy_index[%d] = %s_line_busy_index[%d];\n", i, cp, i < nload?i:i-nload, i, cp, i < nload?i:i-nload);
	printf("	end\n");
	}

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
			printf("(xallocate[%d][%d]&!r_store_fence[%d])", i, j, j-nload);
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
			printf("(xallocate[%d][%d]&r_store_fence[%d])", i, j, j-nload);
		}
		printf(";\n");
		first = 1;
		printf("	assign q_cache_miss[%d] = (", i);
		for (j = 0; j < (nload); j++) {
			int xx =  j < nload?j:j-nload;
			printf("xallocate[%d][%d]?!dc_load.ack[%d].hit||(dc_rd_lr[%d]&&dc_load.ack[%d].hit_need_o):", i, j, xx, xx, xx);
		}
		printf("0);\n");
		first = 1;
#ifdef NOTDEF
		printf("	assign q_data[%d] = (", i);
		for (j = nload; j < (nload+nstore); j++) {
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?store_data[%d]:", i,j,j-nload);
			} else {
				printf("store_data[%d]", j-nload);
			}
		}
		printf(");\n");
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d][%d:%d]) // synthesis full_case parallel_case\n", i, nstore+nload-1, nload);
		printf("	%d'b",nstore);
		for (j=0; j < (nstore); j++) printf("0");
		printf(": q_data[%d] = 'bx;\n", i);
		for (j= nload; j < (nload+nstore); j++) {
			char *cp = "store_data";
			printf("	%d'b",nstore);
			for (k=(nload+nstore)-1; k >= nload; k--) printf(j==k?"1":"?");
			printf(": q_data[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
		first = 1;
		printf("	assign q_io[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_io":"r_store_io");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i, j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_io[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_io":"r_store_io");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_io[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
		first = 1;
		printf("	assign q_addr[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char c[256];
			char *cp = &c[0];
			if (j < nload) {
				snprintf(c, sizeof(c), "r_load_paddr[%d]", j);
			} else {
				snprintf(c, sizeof(c), "r_store_paddr[%d]", j-nload);
			}
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s:", i, j,cp);
			} else {
				printf("%s", cp);
			}
		}
		printf(");\n");
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_addr[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_paddr":"r_store_paddr");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_addr[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
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
#ifdef NOTDEF
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
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_aq_rl[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_aq_rl":"r_store_aq_rl");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_aq_rl[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
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
#endif
		printf("`ifdef FP\n");
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_fp[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_fp":"r_store_fp");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_fp[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
		printf("`endif\n");
#ifdef NOTDEF
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
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_rd[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_rd":"r_store_rd");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_rd[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
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
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_makes_rd[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_makes_rd":"r_store_makes_rd");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_makes_rd[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
		first = 1;
		printf("	assign q_mask[%d] = (", i);
		for (j = nload; j < (nload+nstore); j++) {
			char *cp = "store_mask";
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s[%d]:", i,j,cp,j < nload?j:j-nload);
			} else {
				printf("%s[%d]", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_hart[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_mask":"store_mask");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_mask[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
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
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_hart[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_hart":"r_store_hart");
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_hart[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
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
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_control[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"r_load_control":"r_store_control");

			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_control[%d] = %s[%d];\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");
#ifdef NOTDEF
		first = 1;
		printf("	assign q_hazard[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"load_snoop":"store_snoop");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s.ack[%d].hazard:", i, j,cp, j < nload?j:j-nload);
			} else {
				printf("%s.ack[%d].hazard", cp, j < nload?j:j-nload);
			}
		}
		printf(");\n");
		first = 1;
		printf("	assign q_line_busy[%d] = (", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"load_snoop":"store_snoop");
			if (j != (nload+nstore-1)) {
				printf("xallocate[%d][%d]?%s.ack[%d].line_hit|a_line_hit[%d]:", i, j,cp,j < nload?j:j-nload, j);
			} else {
				printf("%s.ack[%d].line_hit|a_line_hit[%d]", cp, j < nload?j:j-nload,j);
			}
		}
		printf(");\n");
#endif
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n", i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_hazard[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			char *cp = (j < nload?"load_snoop":"store_snoop");

			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": q_hazard[%d] = %s.ack[%d].hazard;\n", i, cp, j < nload?j:j-nload);
		}
		printf("	endcase\n");

	
		printf("	always @(*)\n");
		printf("	casez (xallocate[%d]) // synthesis full_case parallel_case\n",i);
		printf("	%d'b",nload+nstore);
		for (j=0; j < (nload+nstore); j++) printf("0");
		printf(": q_line_busy[%d] = 'bx;\n", i);
		for (j = 0; j < (nload+nstore); j++) {
			printf("	%d'b",nload+nstore);
			for (k=(nload+nstore)-1; k >= 0; k--) printf(j==k?"1":"?");
			printf(": begin q_line_busy[%d] = j_line_busy[%d]; q_line_busy_index[%d] = j_line_busy_index[%d];end\n", i, j, i, j);
		}
		printf("	endcase\n");
		first = 1;
		printf("	assign q_load_ack[%d] = ", i);
		for (j = 0; j < (nload); j++) {
			if (first) {
				first = 0;
			} else {
				printf("||");
			}
			printf("(load_enable[%d] && load_queued[%d] && (load_qindex[%d] == %d))", j,j,j,i);
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
			printf("(r_load_enable[%d] && r_load_queued[%d] && (r_load_ack_entry[%d] == %d) && !dc_load.ack[%d].hit)", j,j,j,i,j);
		}
		printf(";\n");
	}
	printf("        always @(*) begin\n");
	printf("		q_mem_hart='bx;\n");
	printf("		q_mem_sc='bx;\n");
	printf("		q_mem_mask='bx;\n");
	printf("		q_mem_data='bx;\n");
	printf("		q_mem_addr='bx;\n");
	printf("		q_mem_io='bx;\n");
	printf("		q_mem_amo='bx;\n");
	printf("		store_ack=0;\n");
	printf("		casez (store_mem) // synthesis full_case parallel_case\n");
	for (i = 0; i < nldstq; i++) {
		printf("		%d'b",nldstq);
		for (j = 0; j < nldstq; j++) printf(j > (nldstq-1-i)? "0":j==(nldstq-1-i)?"1":"?");
		printf(": begin store_ack[%d] = 1; q_mem_mask = write_mem_mask[%d]; q_mem_data = write_mem_data[%d]; q_mem_addr = write_mem_addr[%d][NPHYS-1:(RV==64?3:2)]; q_mem_hart = write_mem_hart[%d]; q_mem_sc = write_mem_sc[%d]; q_mem_amo = write_mem_amo[%d]; q_mem_io = write_mem_io[%d]; end\n", i, i,i,i,i,i,i,i);
	}
	printf("		%d'b",nldstq);
	for (j = 0; j < nldstq; j++) printf("0");
	printf(": ;\n");
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
