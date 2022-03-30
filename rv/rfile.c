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

int main(int argc, char ** argv)
{
	int n, i,j,k,t;
	int ind, inc, ncommit, numfpureadports, numglobalreadports, numlocalreadports, numtransferports, numglobalwriteports, numlocalwriteports;

	if (argc < 2) {
err:
		fprintf(stderr, "rfile [-inc] num-global-read-ports num-local-read-ports num-global-write-ports num-local-write-ports num-transfer-ports ncommit\n");
		exit(0);
	} 	
	if (strcmp(argv[1], "-inc")==0) {
		ind=2;
		inc = 1;
	} else {
		ind = 1;
		inc = 0;
	}
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

	if (ind >= argc) goto err;
	numglobalreadports = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	numlocalreadports = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	numglobalwriteports = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	numlocalwriteports = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	numtransferports = strtol((const char *)argv[ind++], 0, 0);
	if (ind >= argc) goto err;
	ncommit = strtol((const char *)argv[ind++], 0, 0);
	if (ind < argc) {
		numfpureadports = strtol((const char *)argv[ind++], 0, 0);
	} else {
		numfpureadports = 1;
	}
	if (!inc) {
		printf("module regfile(input clk, input reset,\n");
		printf("`ifdef AWS_DEBUG\n");
		printf("		input xxtrig,\n");
		printf("`endif\n");
		for (i = 0; i < (numglobalreadports+numlocalreadports); i++) 
			printf("		input read_enable%d,input [RA-1:0]read_addr%d,output [RV-1:0]read_data%d,\n", i, i, i);
		for (i = 0; i < (numglobalwriteports+numlocalwriteports);i++) 
			printf("		input write_enable%d,input [LNCOMMIT-1:0]write_addr%d,input [RV-1:0]write_data%d,\n", i, i, i);
		printf("`ifdef FP\n");
		for (i = 0; i < (numfpureadports); i++) 
			printf("		input fpu_read_enable%d,input [RA-1:0]fpu_read_addr%d,output [RV-1:0]fpu_read_data%d,\n", i, i, i);
		for (i = 0; i < (numglobalwriteports+numlocalwriteports);i++) 
			printf("		input write_fp%d,\n", i);
		for (i = 0; i < (numtransferports); i++) 
			printf("		input transfer_dest_fp%d,\n", i);
		printf("`endif\n");
		for (i = 0; i < numtransferports; i++)
			printf("		input transfer_enable%d,input [LNCOMMIT-1:0]transfer_source_addr%d,input [4:0]transfer_dest_addr%d%s\n", i, i,i, (i!= (numtransferports-1)?",":""));
		printf("		);\n");
		printf("        parameter LNHART=0;\n");
		printf("        parameter NHART=1;\n");
		printf("        parameter RA=6;\n");
		printf("        parameter RV=64;\n");
		printf("        parameter HART=0;\n");
		printf("        parameter NCOMMIT = 32;\n");
		printf("        parameter LNCOMMIT = 5;\n");
		printf("        \n");

		for (i = 0; i < (numglobalreadports+numlocalreadports); i++) {
			printf("	reg [RA-1:0]r_rd_reg%d;\n", i);
			printf("	reg [RV-1:0]out%d, r_out%d, xout%d;\n", i, i, i);
			printf("	assign read_data%d = xout%d;\n", i, i);
		}
		printf("`ifdef FP\n");
		for (i = 0; i < (numfpureadports); i++) {
			printf("	reg [RA-1:0]r_rd_fpu_reg%d;\n", i);
			printf("	reg [RV-1:0]fpu_out%d, r_fpu_out%d, x_fpu_out%d;\n", i, i, i);
			printf("	assign fpu_read_data%d = x_fpu_out%d;\n", i, i);
		}
		printf("`endif\n");
		printf("	always @(posedge clk) begin\n");
		for (i = 0; i < (numglobalreadports+numlocalreadports); i++) {
			printf("		r_out%d <= out%d;\n", i, i);
			printf("		r_rd_reg%d <= read_addr%d;\n", i, i);
		}
		printf("`ifdef FP\n");
		for (i = 0; i < (numfpureadports); i++) {
			printf("		r_fpu_out%d <= fpu_out%d;\n", i, i);
			printf("		r_rd_fpu_reg%d <= fpu_read_addr%d;\n", i, i);
		}
		printf("`endif\n");
		printf("	end\n\n");
		printf("`ifdef VSYNTH\n");
		for (i = 1; i < 32; i++)
			printf("    reg [RV-1:0]r_real_reg_%d;\n",i);
		printf("`ifdef FP\n");
		for (i = 0; i < 32; i++)
			printf("    reg [RV-1:0]r_real_fp_reg_%d;\n",i);
		printf("`endif\n");
		for (i = 0; i < ncommit; i++)
			printf("    reg [RV-1:0]r_commit_reg_%d;\n",i);
		printf("`else\n");
		printf("	reg [RV-1:0]r_real_reg[1:31];\n");
		printf("`ifdef FP\n");
		printf("	reg [RV-1:0]r_real_fp_reg[0:31];\n");
		printf("`endif\n");
		printf("	reg [RV-1:0]r_commit_reg[0:NCOMMIT-1];\n");
		printf("`endif\n");
		for (i = 0; i < numtransferports; i++) {
			printf("	reg [RV-1:0]transfer_reg_%d;\n", i);
			printf("	reg [4:0]transfer_write_addr_%d;\n", i);
			printf("`ifdef FP\n");
			printf("	reg      transfer_write_fp_%d;\n", i);
			printf("`endif\n");
		}
		printf("	reg [%d:0]transfer_pending;\n", numtransferports-1);
		printf("	wire [%d:0]transfer_pending_ok;\n",numtransferports-1);

		
		printf("`ifdef VSYNTH\n");
		for (i = 0; i < ncommit; i++) {
			printf("	reg	[RV-1:0]xvr_%d;\n", i);
			printf("	wire [%d:0]xwp_%d = {", numglobalwriteports+numlocalwriteports-1, i);
			for (j = numglobalwriteports+numlocalwriteports-1; j >= 0; j--) 
				printf("write_enable%d&(write_addr%d==%d)%s ",j,j,i,j>0?",":"");
			printf("};\n");
			printf("	always @(*) begin\n");
			printf("		xvr_%d = 'bx;\n", i);
			printf("		casez (xwp_%d) // synthesis full_case parallel_case\n",i);
			for (j = numglobalwriteports+numlocalwriteports-1; j >= 0; j--) {
				printf("		%d'b", numglobalwriteports+numlocalwriteports);
				for (k = numglobalwriteports+numlocalwriteports-1;k >=0; k--) printf(j==k?"1":"?");
				printf(": xvr_%d = write_data%d;\n",i,j);
			}
			printf("		endcase\n");
			printf("	end\n");
			printf("	always @(posedge clk)\n");
			printf("	if (|xwp_%d)\n", i);
			printf("		r_commit_reg_%d <= xvr_%d;\n",i, i);
		}
		printf("`else\n");
		for (i = 0; i < (numglobalwriteports); i++) {
			printf("	always @(posedge clk) \n");
			printf("		if (write_enable%d) r_commit_reg[write_addr%d] <= write_data%d;\n",i,i,i);
		}
		for (i = numglobalwriteports; i < (numglobalwriteports+numlocalwriteports); i++) {
			printf("	always @(posedge clk) \n");
			printf("		if (write_enable%d) r_commit_reg[write_addr%d] <= write_data%d;\n",i,i,i);
		}
		printf("`endif\n");
		for (i = 0; i < numtransferports; i++) {
			printf("`ifdef VSYNTH\n");
			printf("	reg [RV-1:0]tr_%d;\n",i);
			printf("	always @(*) begin\n");
			printf("		case(transfer_source_addr%d) // synthesis full_case parallel_case\n", i);
			for (j = 0; j < ncommit; j++) 
				printf("		%d: tr_%d = r_commit_reg_%d;\n", j, i, j);
			printf("		endcase\n");
			printf("	end \n");
			printf("	always @(posedge clk) \n");
			printf("		transfer_reg_%d <= tr_%d;\n",i,i);
			printf("`else\n");
			printf("	always @(posedge clk) \n");
			printf("		transfer_reg_%d <= r_commit_reg[transfer_source_addr%d];\n",i,i);
			printf("`endif\n");
			printf("	always @(posedge clk) \n");
			printf("		transfer_write_addr_%d <= transfer_dest_addr%d;\n",i,i);
			printf("`ifdef FP\n");
			printf("	always @(posedge clk) \n");
			printf("		transfer_write_fp_%d <= transfer_dest_fp%d;\n", i,i);
			printf("	always @(posedge clk) \n");
			printf("		if (transfer_enable%d && !reset && (transfer_dest_fp%d||transfer_dest_addr%d!=0)) begin\n", i,i,i);
			printf("			transfer_pending[%d] <= 1;\n",i);
			printf("		end else begin\n");
			printf("			transfer_pending[%d] <= 0;\n",i);
			printf("		end \n");
			printf("`else\n");
			printf("	always @(posedge clk) \n");
			printf("		if (transfer_enable%d && !reset && transfer_dest_addr%d!=0) begin\n", i, i);
			printf("			transfer_pending[%d] <= 1;\n",i);
			printf("		end else begin\n");
			printf("			transfer_pending[%d] <= 0;\n",i);
			printf("		end \n");
			printf("`endif\n");
			printf("`ifndef VSYNTH\n");
			printf("	always @(posedge clk) \n");
			printf("`ifdef FP\n");
			printf("	if (transfer_pending_ok[%d] && !transfer_dest_fp%d)\n",i,i);
			printf("`else\n");
			printf("	if (transfer_pending_ok[%d])\n",i);
			printf("`endif\n");
			printf("		r_real_reg[transfer_write_addr_%d] <= transfer_reg_%d;\n",i,i);
			printf("`endif\n");
			printf("	assign transfer_pending_ok[%d] = (transfer_pending[%d]\n",i,i);
			for (j=i+1;j < numtransferports; j++) {
				printf(" && !(transfer_pending[%d] && transfer_write_addr_%d == transfer_write_addr_%d \n", j, j, i);
				printf("`ifdef FP\n");
				printf(" && (transfer_dest_fp%d == transfer_dest_fp%d) \n", j, i);
				printf("`endif\n");
				printf(")\n");
			}
			printf(");\n");
		}
		printf("`ifdef FP\n");
		printf("	wire [%d:0]fp_transfer = {",numtransferports-1);
		for (j = numtransferports-1; j >= 0; j--) 
			printf("transfer_write_fp_%d%s",j,j>0?",":"};\n");
		printf("`endif\n");
				
		printf("`ifdef VSYNTH\n");
		for (i = 1; i < 32; i++) {
			printf("	reg	[RV-1:0]tvr_%d;\n", i);
			printf("	wire [%d:0]rwp_%d = {", numtransferports-1, i);
			for (j = numtransferports-1; j >= 0; j--) 
				printf("transfer_pending[%d]&(transfer_write_addr_%d==%d)%s ",j,j,i,j>0?",":"");
			printf("};\n");
			printf("	always @(*) begin\n");
			printf("		tvr_%d = 'bx;\n", i);
			printf("		casez (rwp_%d) // synthesis full_case parallel_case\n",i);
			for (j = numtransferports-1; j >= 0; j--) {
				printf("		%d'b", numtransferports);
				for (k = numtransferports-1;k >=0; k--) printf(j==k?"1":"?");
				printf(": tvr_%d = transfer_reg_%d;\n",i,j);
			}
			printf("		endcase\n");
			printf("	end\n");
			printf("	always @(posedge clk)\n");
			printf("`ifdef FP\n");
			printf("	if (|(rwp_%d&~fp_transfer))\n", i);
			printf("`else\n");
			printf("	if (|rwp_%d)\n", i);
			printf("`endif\n");
			printf("		r_real_reg_%d <= tvr_%d;\n",i, i);
		}

		printf("`ifdef FP\n");
		i = 0;
		printf("	reg	[RV-1:0]tvr_%d;\n", i);
		printf("	wire [%d:0]rwp_%d = {", numtransferports-1, i);
		for (j = numtransferports-1; j >= 0; j--) 
			printf("transfer_pending[%d]&(transfer_write_addr_%d==%d)%s ",j,j,i,j>0?",":"");
		printf("};\n");
		printf("	always @(*) begin\n");
		printf("		tvr_%d = 'bx;\n", i);
		printf("		casez (rwp_%d) // synthesis full_case parallel_case\n",i);
		for (j = numtransferports-1; j >= 0; j--) {
			printf("		%d'b", numtransferports);
			for (k = numtransferports-1;k >=0; k--) printf(j==k?"1":"?");
			printf(": tvr_%d = transfer_reg_%d;\n",i,j);
		}
		printf("		endcase\n");
		printf("	end\n");
		for (i = 0; i < 32; i++) {
			printf("	always @(posedge clk)\n");
			printf("	if (|(rwp_%d&fp_transfer))\n", i);
			printf("		r_real_fp_reg_%d <= tvr_%d;\n",i, i);
		}
		printf("`endif\n");
		printf("`endif\n");
		for (i = 0; i < (numglobalreadports+numlocalreadports); i++) {
			printf("	always @(*) begin\n");
			printf("`ifdef FP\n");
			printf("		casez ({");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("write_enable%d&~write_fp%d&(write_addr%d==r_rd_reg%d[LNCOMMIT-1:0]), ", j, j, j, i);
			printf("r_rd_reg%d[RA-1]}) // synthesis full_case parallel_case\n",i);
			printf("`else\n");
			printf("		casez ({");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("write_enable%d&(write_addr%d==r_rd_reg%d[LNCOMMIT-1:0]), ", j, j, i);
			printf("r_rd_reg%d[RA-1]}) // synthesis full_case parallel_case\n",i);
			printf("`endif\n");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) {	// 0-clock bypass
				printf("		%d'b",1+(numlocalwriteports+numglobalwriteports));
				for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf(j==k?"1":"?");
				printf("_1: xout%d = write_data%d;\n", i, j);
			}
			printf("		%d'b",1+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf("0");
			printf("_1,\n");
			printf("		%d'b",1+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf("?");
			printf("_0: xout%d = r_out%d;\n", i, i);
			printf("		endcase\n");
			printf("	end\n");
		}
		printf("`ifdef FP\n");
		for (i = 0; i < (numfpureadports); i++) {
			printf("	always @(*) begin\n");
			printf("		casez ({");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("write_enable%d&write_fp%d&(write_addr%d==r_rd_fpu_reg%d[LNCOMMIT-1:0]), ", j, j, j, i);
			printf("r_rd_fpu_reg%d[RA-1]}) // synthesis full_case parallel_case\n",i);
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) {	// 0-clock bypass
				printf("		%d'b",1+(numlocalwriteports+numglobalwriteports));
				for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf(j==k?"1":"?");
				printf("_1: x_fpu_out%d = write_data%d;\n", i, j);
			}
			printf("		%d'b",1+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf("0");
			printf("_1,\n");
			printf("		%d'b",1+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf("?");
			printf("_0: x_fpu_out%d = r_fpu_out%d;\n", i, i);
			printf("		endcase\n");
			printf("	end\n");
		}
		printf("`endif\n");
		for (i = 0; i < (numglobalreadports+numlocalreadports); i++) {
			printf("	always @(*) begin\n");
			printf("`ifdef FP\n");
			printf("		casez ({");
			for (j = 0; j < numtransferports; j++) printf("transfer_pending_ok[%d]&~transfer_write_fp_%d&(transfer_write_addr_%d==read_addr%d[4:0]), ", j, j, j, i);
			for (j = 0; j < (numglobalwriteports); j++) printf("write_enable%d&~write_fp%d&(write_addr%d==read_addr%d[LNCOMMIT-1:0]), ", j,j, j, i);
			for (j = numglobalwriteports; j < (numglobalwriteports+numlocalwriteports); j++) printf("write_enable%d&~write_fp%d&(write_addr%d==read_addr%d[LNCOMMIT-1:0]), ", j, j, j, i);
			printf("read_enable%d, read_addr%d[RA-1]}) // synthesis full_case parallel_case\n",i,i);
			printf("`else\n");
			printf("		casez ({");
			for (j = 0; j < numtransferports; j++) printf("transfer_pending_ok[%d]&(transfer_write_addr_%d==read_addr%d[4:0]), ", j, j, i);
			for (j = 0; j < (numglobalwriteports); j++) printf("write_enable%d&(write_addr%d==read_addr%d[LNCOMMIT-1:0]), ", j, j, i);
			for (j = numglobalwriteports; j < (numglobalwriteports+numlocalwriteports); j++) printf("write_enable%d&(write_addr%d==read_addr%d[LNCOMMIT-1:0]), ", j, j, i);
			printf("read_enable%d, read_addr%d[RA-1]}) // synthesis full_case parallel_case\n",i,i);
			printf("`endif\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (j = 0; j < numtransferports; j++) printf("?");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("?");
			printf("_0?: out%d = 64'bx;\n", i);
			for (j = 0; j < numtransferports; j++) {
				printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
				for (k = 0; k < numtransferports; k++)printf(j==k?"1":"?");
				printf("_");
				for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++) printf("?");
				printf("_10: out%d = transfer_reg_%d;\n", i, j);
			}

			printf("`ifdef VSYNTH\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("0");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("?");
			printf("_10:	case (read_addr%d[4:0]) // synthesis full_case parallel_case\n", i);
			printf("				0: out%d = 0;\n", i);
			for (j=1;j<32;j++)
			printf("				%d: out%d = r_real_reg_%d;\n", j,i,j);
			printf("				endcase\n");
			printf("`else\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("0");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("?");
			printf("_10: out%d = (read_addr%d[4:0]==0?0:r_real_reg[read_addr%d[4:0]]);\n", i, i, i);
			printf("`endif\n");

			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) {
				printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
				for (k = 0; k < numtransferports; k++) printf("?");
				printf("_");
				for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf(j==k?"1":"?");
				printf("_11: out%d = write_data%d;\n", i, j);
			}

			printf("`ifdef VSYNTH\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("?");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("0");
			printf("_11:	case (read_addr%d[LNCOMMIT-1:0]) // synthesis full_case parallel_case\n", i);
			for (j = 0; j < ncommit; j++)
			printf("					%d: out%d = r_commit_reg_%d;\n", j, i, j);
			printf("					endcase\n");
			printf("`else\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("?");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("0");
			printf("_11: out%d = r_commit_reg[read_addr%d[LNCOMMIT-1:0]];\n", i, i);
			printf("`endif\n");


			printf("		endcase\n");
			printf("	end\n");
		}
	
		printf("`ifdef FP\n");
		for (i = 0; i < (numfpureadports); i++) {
			printf("	always @(*) begin\n");
			printf("		casez ({");
			for (j = 0; j < numtransferports; j++) printf("transfer_pending_ok[%d]&transfer_write_fp_%d&(transfer_write_addr_%d==read_addr%d[4:0]), ", j, j, j, i);
			for (j = 0; j < (numglobalwriteports); j++) printf("write_enable%d&write_fp%d&(write_addr%d==read_addr%d[LNCOMMIT-1:0]), ", j,j, j, i);
			for (j = numglobalwriteports; j < (numglobalwriteports+numlocalwriteports); j++) printf("write_enable%d&write_fp%d&(write_addr%d==read_addr%d[LNCOMMIT-1:0]), ", j, j, j, i);
			printf("fpu_read_enable%d, fpu_read_addr%d[RA-1]}) // synthesis full_case parallel_case\n",i,i);
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (j = 0; j < numtransferports; j++) printf("?");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("?");
			printf("_0?: fpu_out%d = 64'bx;\n", i);
			for (j = 0; j < numtransferports; j++) {
				printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
				for (k = 0; k < numtransferports; k++)printf(j==k?"1":"?");
				printf("_");
				for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++) printf("?");
				printf("_10: fpu_out%d = transfer_reg_%d;\n", i, j);
			}

			printf("`ifdef VSYNTH\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("0");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("?");
			printf("_10:	case (fpu_read_addr%d[4:0]) // synthesis full_case parallel_case\n", i);
			for (j=0;j<32;j++)
			printf("				%d: fpu_out%d = r_real_fp_reg_%d;\n", j,i,j);
			printf("				endcase\n");
			printf("`else\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("0");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("?");
			printf("_10: fpu_out%d = r_real_fp_reg[fpu_read_addr%d[4:0]];\n", i, i);
			printf("`endif\n");

			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) {
				printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
				for (k = 0; k < numtransferports; k++) printf("?");
				printf("_");
				for (k = 0; k < (numglobalwriteports+numlocalwriteports); k++)printf(j==k?"1":"?");
				printf("_11: fpu_out%d = write_data%d;\n", i, j);
			}

			printf("`ifdef VSYNTH\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("?");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("0");
			printf("_11:	case (fpu_read_addr%d[LNCOMMIT-1:0]) // synthesis full_case parallel_case\n", i);
			for (j = 0; j < ncommit; j++)
			printf("					%d: fpu_out%d = r_commit_reg_%d;\n", j, i, j);
			printf("					endcase\n");
			printf("`else\n");
			printf("		%d'b",2+numtransferports+(numlocalwriteports+numglobalwriteports));
			for (k = 0; k < numtransferports; k++)printf("?");
			printf("_");
			for (j = 0; j < (numglobalwriteports+numlocalwriteports); j++) printf("0");
			printf("_11: fpu_out%d = r_commit_reg[fpu_read_addr%d[LNCOMMIT-1:0]];\n", i, i);
			printf("`endif\n");


			printf("		endcase\n");
			printf("	end\n");
		}
		printf("`endif\n");
		printf("`ifdef AWS_DEBUG\n");
		printf("	ila_reg ila_reg(.clk(clk),\n");
		for (i = 0; i < 16; i++) {
		printf("		.r_en_%d(read_enable%d),\n",i,i);
		printf("		.r_addr_%d(read_addr%d),\n",i,i);
		printf("		.r_data_%d(read_data%d[31:0]),\n",i,i);
		}
		printf("		.xxtrig(xxtrig));\n");
	
		printf("	ila_reg2 ila_reg2(.clk(clk),\n");
		for (i = 0; i < 8; i++) {
		printf("		.w_en_%d(write_enable%d),\n",i,i);
		printf("		.w_addr_%d(write_addr%d),\n",i,i);
		printf("		.w_data_%d(write_data%d[31:0]),\n",i,i);
		}
		for (i = 0; i < 8; i++) {
		printf("		.t_en_%d(transfer_enable%d),\n",i,i);
		printf("		.t_src_%d(transfer_source_addr%d),\n",i,i);
		printf("		.t_dst_%d(transfer_dest_addr%d),\n",i,i);
		}
		printf("		.r_en_0(read_enable0),\n");
		printf("		.xxtrig(xxtrig));\n");
		printf("`endif\n");
	
		printf("endmodule\n");
	} else {
		printf("			regfile  #(.RA(RA), .HART(H), .NHART(NHART), .LNHART(LNHART), .NCOMMIT(NCOMMIT), .LNCOMMIT(LNCOMMIT)) rf(.clk(clk), .reset(reset),\n");
		for (i = 0; i < numglobalreadports; i++) 
			printf("				.read_enable%d(reg_read_enable[%d][H]),.read_addr%d(reg_read_addr[%d]),.read_data%d(reg_read_data[%d][H]),\n", i, i, i, i, i, i);
		for (i = 0; i < numlocalreadports; i++) 
			printf("				.read_enable%d(local_reg_read_enable[%d][H]),.read_addr%d(local_reg_read_addr[%d][H]),.read_data%d(local_reg_read_data[%d][H]),\n", i+numglobalreadports, i, i+numglobalreadports, i, i+numglobalreadports, i);
		for (i = 0; i < numglobalwriteports;i++) 
			printf("				.write_enable%d(reg_write_enable[%d][H]),.write_addr%d(reg_write_addr[%d]),.write_data%d(reg_write_data[%d]),\n", i, i, i, i, i, i);
		for (i = 0; i < numlocalwriteports;i++) 
			printf("				.write_enable%d(local_reg_write_enable[%d][H]),.write_addr%d(local_reg_write_addr[%d][H]),.write_data%d(local_reg_write_data[%d][H]),\n", numglobalwriteports+i, i, numglobalwriteports+i, i, numglobalwriteports+i, i);
		printf("`ifdef FP\n");
		for (i = 0; i < numfpureadports; i++) 
			printf("				.fpu_read_enable%d(fpu_reg_read_enable[%d][H]),.fpu_read_addr%d(fpu_reg_read_addr[%d]),.fpu_read_data%d(fpu_reg_read_data[%d][H]),\n", i, i, i, i, i, i);
		for (i = 0; i < numtransferports;i++) 
			printf("				.transfer_dest_fp%d(reg_transfer_dest_fp[H][%d]),\n", i, i);
		for (i = 0; i < numglobalwriteports;i++) 
			printf("				.write_fp%d(reg_write_fp[%d]),\n", i, i);
		for (i = 0; i < numlocalwriteports;i++) 
			printf("				.write_fp%d(1'b0),\n", numglobalwriteports+i);
		printf("`endif\n");
		for (i = 0; i < numtransferports; i++)
			printf("				.transfer_enable%d(reg_transfer_enable[H][%d]),.transfer_source_addr%d(reg_transfer_source_addr[%d][H]),.transfer_dest_addr%d(reg_transfer_dest_addr[%d][H])%s\n", i, i, i, i, i,i, (i!= (numtransferports-1)?",":""));
		printf("`ifdef AWS_DEBUG\n");
		printf("		,\n");
		printf("		.xxtrig(xxtrig)\n");
		printf("`endif \n");
		printf("				);\n\n");
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
