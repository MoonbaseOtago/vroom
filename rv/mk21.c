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

int B=32;

int xlog2(int x)
{
	int i;
	for (i = 1;;i++)
	if (x < (1<<i)) return i;
	return 0;
}

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

char tt[100];
char *bin(int v, int l)
{
	int i;
	char *cp=&tt[0];
	for (i = l-1; i >= 0; i--) 
		*cp++ = (v&(1<<i)?'1':'0');
	*cp = 0;
	return &tt[0];
}

int main(int argc, char ** argv)
{
	int i,j,k,l;
	int ind=1;
	int nc, naddr, nload, nstore;
	int nhart=1;
	int nldstq;
	int nwports=1;

	if (argc < 6) {
		fprintf(stderr, "Usage: mk21 ncommit naddr nload nstore nldstq\n");
		exit(99);
	}
    	nc = strtol((const char *)argv[ind++], 0, 0);
    	naddr = strtol((const char *)argv[ind++], 0, 0);
    	nload = strtol((const char *)argv[ind++], 0, 0);
    	nstore = strtol((const char *)argv[ind++], 0, 0);
    	nldstq = strtol((const char *)argv[ind++], 0, 0);
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

	for (i = 0; i < nhart; i++) {
	printf("	rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))add_rol_%d(.in(ls_ready.load_addr_ready[%d]|ls_ready.store_addr_ready[%d]), .r(ls_ready.current_start[%d]), .out(addr_rdy[%d]));\n", i, i, i, i, i);
	for (l = 0; l < naddr; l++) {
	printf("	always @(*) begin\n");
	printf("		addr_enable[%d] = 0;\n", l);
	if (l != (naddr-1))
	printf("		addr_inh[%d] = 0;\n", l);
	printf("		addr_rd[%d] = 'bx;\n", l);
 	printf("		if (vmq_rdy[%d])\n", i);
 	printf("		casez (addr_rdy[%d][NCOMMIT-1:%d]", i, l);
	for (j=0; j < l; j++) printf("&~addr_inh[%d][NCOMMIT-1:%d]", j, l);
			printf(") // synthesis full_case parallel_case\n");
	for (j = l; j < nc; j++) {
 	printf("		%d'b", nc-l);
	for (k = nc-1; k >= l; k--) printf("%s", k < j ? "0":k==j ? "1":"?");
	                      printf(":	begin\n");
	printf("								addr_enable[%d] = 1;\n", l);
	printf("								addr_rd[%d] = ls_ready.current_start[%d]+%d;\n", l, i, j);
	if (l != (naddr-1))
	printf("								addr_inh[%d][%d] = 1;\n", l, j);
	printf("							end\n");
	}
 	printf("		%d'b", nc-l);
	for (k = 0; k < (nc-l); k++) printf("0"); printf(": ;\n");
	printf("		endcase\n");
	printf("	end\n");
	}
	}

	if (nhart == 1) {
	printf("	assign load_hart[0] = 0;\n");
	} else {
	printf("	reg [NHART-1:0]x_load_hart[0:NLOAD-1];\n");
	}
	for (i = 0; i < nhart; i++) {
	printf("	rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))ld_rol_%d(.in(hazard_clear_load[%d]), .r(ls_ready.current_start[%d]), .out(ld_rdy[%d]));\n", i, i, i, i);
	for (l = 0; l < nload; l++) {
	printf("	always @(*) begin\n");
	printf("		xload_enable[%d] = 0;\n", l);
	if (l != (nload-1))
	printf("		ld_inh[%d] = 0;\n", l);	
	if (nhart > 1)
	printf("		load_hart[%d] = 'bx;\n", l);
	printf("		load_rd[%d] = 'bx;\n", l);
	printf("		load_qindex[%d] = 'bx;\n", l);
 	printf("		casez ({ld_rdy[%d], q_load_ready}", i);
	for (j=0; j < l; j++) printf("&~{ld_inh[%d]}", j);
			printf(") // synthesis full_case parallel_case\n");
	for (j = l; j < (nc+nldstq); j++) {
 	printf("		%d'b", nc+nldstq);
	for (k = (nc+nldstq)-1; k >= 0; k--) printf("%s", k < j ? "0":k==j ? "1":"?");
	                      printf(":	begin\n");
	printf("								xload_enable[%d] = 1;\n", l);
	if (j >= nldstq) {
	if (nhart > 1)
	printf("								x_load_hart[%d] = %d;\n", l, i);
	printf("								load_rd[%d] = ls_ready.current_start[%d]+%d;\n", l, i, j-nldstq);
	printf("								load_queued[%d] = 0;\n", l);
	} else {
	if (nhart > 1)
	printf("								x_load_hart[%d] = wq_hart[%d];\n", l, j);
	printf("								load_rd[%d] = wq_rd[%d];\n", l, j);
	printf("								load_queued[%d] = 1;\n", l);
	printf("								load_qindex[%d] = %d;\n", l, j);
	}
	if (l != (nload-1))
	printf("								ld_inh[%d][%d] = 1;\n", l, j);
	printf("							end\n");
	}
 	printf("		%d'b", nc+nldstq);
	for (k = 0; k < (nc+nldstq-l); k++) printf("0"); printf(": ;\n");
	printf("		endcase\n");
	printf("	end\n");
	}
	}

	if (nhart == 1) {
	printf("	assign store_hart[0] = 0;\n");
	} else {
	printf("	reg [LNHART-1:0]x_store_hart[0:NSTORE-1];\n");
	for (l = 0; l < nstore; l++)
	printf("	assign store_hart[%d] = x_store_hart[%d];\n", l, l);
	}
	for (i = 0; i < nhart; i++) {
	printf("	rot #(.LNCOMMIT(LNCOMMIT), .NCOMMIT(NCOMMIT))st_rol_%d(.in(hazard_clear_store[%d]), .r(ls_ready.current_start[%d]), .out(st_rdy[%d]));\n", i, i, i, i);
	for (l = 0; l < nload; l++) {
	printf("	always @(*) begin\n");
	printf("		xstore_enable[%d] = 0;\n", l);
	if (l != (nload-1))
	printf("		st_inh[%d] = 0;\n", l);	
	if (nhart > 1)
	printf("		x_store_hart[%d] = 'bx;\n", l);
	printf("		store_rd[%d] = 'bx;\n", l);
 	printf("		casez (st_rdy[%d][NCOMMIT-1:%d]", i, l);
	for (j=0; j < l; j++) printf("&~st_inh[%d][NCOMMIT-1:%d]", j, l);
			printf(") // synthesis full_case parallel_case\n");
	for (j = l; j < nc; j++) {
 	printf("		%d'b", nc-l);
	for (k = nc-1; k >= l; k--) printf("%s", k < j ? "0":k==j ? "1":"?");
	                      printf(":	begin\n");
	printf("								xstore_enable[%d] = 1;\n", l);
	if (nhart > 1)
	printf("								x_store_hart[%d] = %d;\n", l, i);
	printf("								store_rd[%d] = ls_ready.current_start[%d]+%d;\n", l, i, j);
	if (l != (nload-1))
	printf("								st_inh[%d][%d] = 1;\n", l, j);
	printf("							end\n");
	}
 	printf("		%d'b", nc-l);
	for (k = 0; k < (nc-l); k++) printf("0"); printf(": ;\n");
	printf("		endcase\n");
	printf("	end\n");
	}
	}

	printf("	for (H = 0; H < NHART; H=H+1)\n");
	printf("	for (C = 0; C < NCOMMIT; C = C+1) begin\n");
	printf("		always @(*) begin\n");
	printf("                	c_c_valid[H][C]   = r_c_valid[H][C];\n");
	printf("                	c_c_load[H][C]    = r_c_load[H][C];\n");
	printf("                	c_c_fence[H][C]   = r_c_fence[H][C];\n");
	printf("                	c_c_io[H][C]      = r_c_io[H][C];\n");
	printf("                	c_c_paddr[H][C]   = r_c_paddr[H][C];\n");
	printf("                	c_c_control[H][C] = r_c_control[H][C];\n");
	printf("                	c_c_aq_rl[H][C]   = r_c_aq_rl[H][C];\n");
	printf("                	c_c_makes_rd[H][C]= r_c_makes_rd[H][C];\n");
	printf("                	c_c_block[H][C]   = r_c_block[H][C];\n");
	printf("                	c_c_amo[H][C]     = r_c_amo[H][C];\n");
	printf("                	c_c_fd[H][C]      = r_c_fd[H][C];\n");
	printf("                	c_c_soft_hazard[H][C]= r_c_soft_hazard[H][C]&~hazard_gone[H]&~inhibit_hazard[H][C]&~commit_kill[H];\n");
	printf("                	c_c_hard_hazard[H][C]= r_c_hard_hazard[H][C]&~hazard_gone[H]&~commit_kill[H];\n");
	printf("                	c_c_mask[H][C]    = r_c_mask[H][C];\n");
	printf("                	if (reset || commit_kill[H][C] || commit_completed[H][C]) begin\n");
	printf("				c_c_valid[H][C] = 0;\n");
	printf("			end else \n");
	printf("			casez ({\n");
	for (l = naddr-1; l >= 0; l--) printf("				r_addr_busy[%d]&addr_is_ok[%d]&(r_addr_rd[%d]==C)&(addr_hart[%d]==H)%s", l,l,l,l,l==0?"}) // synthesis full_case parallel_case\n":",\n");
	printf("			%d'b", naddr);
	for (i = naddr-1; i >= 0; i--) printf("0");
	printf(":	;\n");
	for (l = naddr-1; l >= 0; l--) {
	printf("			%d'b", naddr);
	for (i = naddr-1; i >= 0; i--) printf(i==l?"1":"?");
	printf(": begin\n");
	printf("                                c_c_valid[H][C]   = 1;\n");
	printf("                                c_c_load[H][C]    = r_addr_load[%d];\n", l);
	printf("                                c_c_fence[H][C]   = addr_fence[%d];\n", l);
	printf("                                c_c_io[H][C]      = addr_io[%d];\n", l);
	printf("                                c_c_paddr[H][C]   = addr_p[%d];\n", l);
	printf("                                c_c_control[H][C] = r_addr_control[%d];\n", l);
	printf("                                c_c_aq_rl[H][C]   = r_addr_aq_rl[%d];\n", l);
	printf("                                c_c_makes_rd[H][C]= r_addr_makes_rd[%d];\n", l);
	printf("                                c_c_fd[H][C]      = addr_fd[%d];\n", l);
	printf("                                c_c_block[H][C]   = addr_blocks[%d];\n", l);
	printf("                                c_c_amo[H][C]     = r_addr_amo[%d];\n", l);
	printf("                                c_c_soft_hazard[H][C]= addr_soft_hazard[%d]&~hazard_gone[H];\n", l);
	printf("                                c_c_hard_hazard[H][C]= addr_hard_hazard[%d]&~hazard_gone[H];\n", l);
	printf("                                c_c_mask[H][C]    = addr_mask[%d];\n", l);
	printf("                            end\n");
	}
	printf("			endcase\n");
	printf("		end\n");
	printf("	end\n");
	printf("	for (H = 0; H < NHART; H=H+1) begin\n");
        printf("		always @(*) begin\n");
	printf("			c_reserved_address[H] = r_reserved_address[H];\n");
	printf("			c_reserved_address_set[H] = r_reserved_address_set[H];\n");
	printf("			casez ({\n");
	for (i = nload-1; i >=0; i--) printf("				r_load_enable[%d] & dc_load.ack[%d].hit & (dc_rd_hart[%d] == H) & dc_rd_lr[%d] & !load_allocate[%d] & !r_load_sc[%d],\n", i, i, i, i, i, i);
	// note: looping over actual write ports not nstore
	for (i = nwports-1; i >=0; i--) printf("(dc_wr_enable[%d] & (dc_wr_addr[%d][NPHYS-1:ACACHE_LINE_SIZE] == c_reserved_address[H]) & (dc_wr_hart[%d] != H )) | (dc_wr_enable[%d] & (dc_wr_hart[%d] == H) & dc_wr_sc[%d]) | (dc_snoop_addr_req & dc_snoop_addr_ack & (c_reserved_address[H] == dc_snoop_addr) & ((dc_snoop_snoop==SNOOP_READ_EXCLUSIVE)|(dc_snoop_snoop==SNOOP_READ_INVALID)))%s", i, i, i, i, i, i, i==0?"":",");
	printf("}) // synthesis full_case parallel_case\n");
	printf("			%d'b", nload+nwports);
	for (i = 0; i < nload+nwports; i++) printf("0");
	printf(": ;\n");
	for (i = nwports-1;i>=0; i--) {
	printf("			%d'b", nload+nwports);
	for (j = 0; j < nload; j++) printf("0");
	for (j = nwports-1; j >= 0; j--) printf(i==j?"1%s":"?%s", j==0?(i==0?":\n":",\n"):"");
	}
	printf("					c_reserved_address_set[H] = 0;\n");
	for (i = nload-1;i>=0; i--) {
	printf("			%d'b", nload+nwports);
	for (j = nload-1;j>=0; j--) printf(i==j?"1":"?");
	for (j = 0; j < nwports; j++) printf("?");
	printf(":	begin\n");
	printf("					c_reserved_address[H] = dc_load.req[%d].addr[NPHYS-1:ACACHE_LINE_SIZE];\n", i);
	printf("					c_reserved_address_set[H] = 1;\n");
	printf("				end\n");
	}
	printf("			endcase\n");
	printf("		end\n");

	printf("	end\n");
	
	
	printf("	reg [$clog2(NLDSTQ):0]num_free_n[0:(NLDSTQ/4)-1];\n");
	for (i = 0; i < nldstq; i+=4) {
	printf("	always @(*) begin\n");
	printf("		case (free[%d:%d]) // synthesis full_case parallel_case\n", i+3, i);
	for (j = 0; j <= (4); j++) {
	int first = 1;
	for (k = 0; k < (1<<4); k++) 
	if (popcount(k) == j) {
	if (first) {
		first = 0;
	} else {
		printf(",\n");
	}
	printf("		%d'h%x", 4, k);
	}
	printf(": num_free_n[%d] = %d;\n", i/4, j);	
	}
	printf("		endcase\n");
	printf("	end\n");
	}
	printf("	assign num_free = ");
	for (i = 0; i < nldstq; i+=4) {
		if (i != 0) printf("+");
		printf("num_free_n[%d]", i/4);
	}
	printf(";\n");

	printf("	always @(*) begin\n");
	printf("		case (r_load_enable&~r_load_queued&~load_allocate) // synthesis full_case parallel_case\n");
	for (j = 0; j <= (nload); j++) {
	int first = 1;
	for (k = 0; k < (1<<nload); k++) 
	if (popcount(k) == j) {
	if (first) {
		first = 0;
	} else {
		printf(",\n");
	}
	printf("		%d'h%x", nload, k);
	}
	printf(": num_load_unused = %d;\n", j);	
	}
	printf("		endcase\n");
	printf("	end\n");
	printf(";\n");

	printf("	always @(*) begin\n");
	printf("		case (r_store_enable&~store_allocate) // synthesis full_case parallel_case\n");
	for (j = 0; j <= (nstore); j++) {
	int first = 1;
	for (k = 0; k < (1<<nstore); k++) 
	if (popcount(k) == j) {
	if (first) {
		first = 0;
	} else {
		printf(",\n");
	}
	printf("		%d'h%x", nstore, k);
	}
	printf(": num_store_unused = %d;\n", j);	
	}
	printf("		endcase\n");
	printf("	end\n");
	printf(";\n");

	printf("	always @(*) begin\n");
	printf("		case (load_enable&~load_queued) // synthesis full_case parallel_case\n");
	for (j = 0; j <= (nload); j++) {
	int first = 1;
	for (k = 0; k < (1<<nload); k++) 
	if (popcount(k) == j) {
	if (first) {
		first = 0;
	} else {
		printf(",\n");
	}
	printf("		%d'h%x", nload, k);
	}
	printf(": num_load_used = %d;\n", j);	
	}
	printf("		endcase\n");
	printf("	end\n");
	printf(";\n");

	printf("	always @(*) begin\n");
	printf("		case (store_enable) // synthesis full_case parallel_case\n");
	for (j = 0; j <= (nstore); j++) {
	int first = 1;
	for (k = 0; k < (1<<nstore); k++) 
	if (popcount(k) == j) {
	if (first) {
		first = 0;
	} else {
		printf(",\n");
	}
	printf("		%d'h%x", nstore, k);
	}
	printf(": num_store_used = %d;\n", j);	
	}
	printf("		endcase\n");
	printf("	end\n");
	printf(";\n");

	printf("	reg	[NLOAD-1:0]yload_enable;\n");
	printf("	always @(*) begin\n");
	printf("		if (r_num_available >= %d) begin\n", nload);
	printf("			yload_enable = xload_enable;\n");
	printf("		end else\n");
 	printf("		casez ({r_num_available[%d:0], xload_enable&~load_queued}) // synthesis full_case parallel_case\n", xlog2(nload)-1);
	for (i = 1; i < nload; i++) 
	for (j = 1; j < (1<<nload); j++){
	if (i == popcount(j)) {
	int n, c=0;
	for (n = 0; n < nload; n++)
	if (j&(1<<n)) {
		c++;
		if (c == i)
			break;
	}
	printf("		%d'b", nload+xlog2(nload));
	for (k = xlog2(nload)-1; k >= 0; k--) printf(i&(1<<k)?"1":"0");
	printf("_");
	for (k = nload-1; k >= 0; k--) printf(k > n?"?":j&(1<<k)?"1":"0");
	printf(": yload_enable = %d;\n", j);
	}
	}

	
	printf("		default: yload_enable = 0;\n");
	printf("		endcase\n");
	printf("	end\n");
	printf("	assign load_enable = yload_enable | (xload_enable&load_queued);\n");

	printf("	reg	[NSTORE-1:0]store_mask;\n");
	printf("	always @(*) begin\n");
	printf("		if (r_num_available >= %d) begin\n", nload+nstore);
	printf("			store_mask = %d'h%x;\n", nstore, (1<<nstore)-1);
	printf("		end else\n");
 	printf("		casez ({r_num_available[%d:0], xload_enable&~load_queued}) // synthesis full_case parallel_case\n", xlog2(nload+nstore)-1);
	for (i = 0; i < (nload+nstore); i++) 
	for (j = 0; j < (1<<nload); j++) {
	int count = i < popcount(j) ? 0 : i - popcount(j);
	if (count < nstore) {
	printf("		%d'b", nload+xlog2(nload+nstore));
	for (k = xlog2(nload+nstore)-1; k >= 0; k--) printf(i&(1<<k)?"1":"0");
	printf("_");
	for (k = nload-1; k >= 0; k--) printf(j&(1<<k)?"1":"0");
	printf(": store_mask = %d'h%x;\n", nstore, count == 0?0: ((1<<(count))-1));
	}
	}
	printf("		default: store_mask = %d'h%x;\n", nstore, (1<<nstore)-1);
	printf("		endcase\n");
	printf("	end\n");
	printf("	assign store_enable = xstore_enable&store_mask;\n");
}
