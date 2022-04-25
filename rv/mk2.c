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
	int n, i,j,k,t, mm;

	if (argc < 2) {
		B = 8;
	} else {
		B = strtol((const char *)argv[1], 0, 0);
	}
	t=1<<B;

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

	printf("wire hart_dec=H;\n");

	printf("	if (D==0) begin\n");
	printf("		always @(*) begin\n");
	printf("`ifdef FP\n");
	printf("			renamed_rs1 = rs1_fp?scoreboard_latest_rename_fp[s1]:scoreboard_latest_rename[s1];\n");
	printf("			renamed_rs2 = rs2_fp?scoreboard_latest_rename_fp[s2]:scoreboard_latest_rename[s2];\n");
	printf("			renamed_rs3 = rs3_fp?scoreboard_latest_rename_fp[s3]:scoreboard_latest_rename[s3];\n");
	printf("`else\n");
	printf("			renamed_rs1 = scoreboard_latest_rename[s1];\n");
	printf("			renamed_rs2 = scoreboard_latest_rename[s2];\n");
	printf("			renamed_rs3 = scoreboard_latest_rename[s3];\n");
	printf("`endif\n");
	printf("			local1 = 0;\n");
	printf("			local2 = 0;\n");
	printf("			local3 = 0;\n");
	printf("		end \n");
	printf("	end else\n");
	for (i = 1; i < B; i++) {
		printf("	if (D==%d) begin\n", i);
		printf("`ifdef FP\n");
		printf("		wire [%d:0]fpmatch1 = {", i-1);
		for (j = i-1; j >= 0; j--)printf("all_rd_fp_rename[%d]==rs1_fp%s",j,j>0?",":"};\n");
		printf("`else\n");
		printf("		wire [%d:0]fpmatch1 = %d'b", i-1,i);
		for (j = i-1; j >= 0; j--)printf("1");printf(";\n");
		printf("`endif\n");
		printf("		wire [%d:0]mk1 = fpmatch1&{", i-1);
		for (j = i-1; j >= 0; j--) 
			printf("all_makes_rd_rename[%d]&(all_rd_rename[%d] == s1)%s", j,j,j==0?"};\n":", ");
		for (n = 0; n < 2; n++) {
			switch (n) {
			case 0: {
					printf("		if (LNCOMMIT >= 5) begin\n");
				}
				break;
			case 1: {
					printf("		end else begin\n");
					printf("			wire [5-LNCOMMIT-1:0]ff;\n");
					printf("			assign ff=0;\n");
				}
				break;
			}
//			for (mm=0; mm < 2; mm++) {
//				if (mm == 0) {
//					printf("			if (NHART==1) begin\n");
//				} else {
//					printf("			end else begin\n");
//				}
				printf("				always @(*) begin local1 = 1; \n");
				printf("				if (s1==0) begin\n");
				printf("					renamed_rs1 = 0;\n");
				printf("				end else\n");
				printf("				casez (mk1) // synthesis full_case parallel_case\n");
				for (j=i-1; j >= 0 ; j--) {
					printf("				%d'b", i);
					for (k=i-1; k >= 0;k--)
						printf(k >j?"0":k==j?"1":"?");
					if (n == 1) {
//						if (mm==0) {
							printf(": renamed_rs1 = {1'b1, ff, map_rd_rename[%d]};\n", j);
//						} else {
//							printf(": renamed_rs1 = {1'b1, hart_dec, ff, map_rd_rename[%d]};\n", j);
//						}
					} else {
//						if (mm == 0) {
							printf(": renamed_rs1 = {1'b1, map_rd_rename[%d]};\n", j);
//						} else {
//							printf(": renamed_rs1 = {1'b1, hart_dec, map_rd_rename[%d]};\n", j);
//						}
					}
				
				}
			
				printf("`ifdef FP\n");
				printf("				default: begin local1 = 0; renamed_rs1 = rs1_fp?scoreboard_latest_rename_fp[s1]:scoreboard_latest_rename[s1]; end\n"); // something for hart here
				printf("`else\n");
				printf("				default: begin local1 = 0;renamed_rs1 = scoreboard_latest_rename[s1];end\n");
				printf("`endif\n");
				printf("				endcase\n");
				printf("				end\n");
//				if (mm == 1) 
//					printf("			end\n");
//			}
			if (n == 1) {
				printf("			end\n");
			}
		}
		printf("`ifdef FP\n");
		printf("		wire [%d:0]fpmatch2 = {", i-1);
		for (j = i-1; j >= 0; j--)printf("all_rd_fp_rename[%d]==rs2_fp%s",j,j>0?",":"};\n");
		printf("`else\n");
		printf("		wire [%d:0]fpmatch2 = %d'b", i-1,i);
		for (j = i-1; j >= 0; j--)printf("1");printf(";");
		printf("`endif\n");
		printf("		wire [%d:0]mk2 = fpmatch2&{", i-1);
		for (j = i-1; j >= 0; j--) 
			printf("all_makes_rd_rename[%d]&(all_rd_rename[%d] == s2)&needs_s2%s", j,j,j==0?"};\n":", ");
		for (n = 0; n < 2; n++) {
			switch (n) {
			case 0: {
					printf("		if (LNCOMMIT >= 5) begin\n");
				}
				break;
			case 1: {
					printf("		end else begin\n");
					printf("			wire [5-LNCOMMIT-1:0]ff;\n");
					printf("			assign ff=0;\n");
				}
				break;
			}
//			for (mm=0; mm < 2; mm++) {
//				if (mm == 0) {
//					printf("			if (NHART==1) begin\n");
//				} else {
//					printf("			end else begin\n");
//				}
				printf("				always @(*) begin local2 = 1;\n");
				printf("				if (s2==0) begin\n");
				printf("					renamed_rs2 = 0;\n");
				printf("				end else\n");
				printf("				casez (mk2) // synthesis full_case parallel_case\n");
				for (j=i-1; j >= 0 ; j--) {
					printf("				%d'b", i);
					for (k=i-1; k >= 0;k--)
						printf(k >j?"0":k==j?"1":"?");
					if (n == 1) {
//						if (mm == 0) {
							printf(": renamed_rs2 = {1'b1, ff, map_rd_rename[%d]};\n", j);
//						} else {
//							printf(": renamed_rs2 = {1'b1, hart_dec, ff, map_rd_rename[%d]};\n", j);
//						}
					} else {
//						if (mm == 0) {
							printf(": renamed_rs2 = {1'b1, map_rd_rename[%d]};\n", j);
//						} else {
//							printf(": renamed_rs2 = {1'b1, hart_dec, map_rd_rename[%d]};\n", j);
//						}
					}
				}
				printf("`ifdef FP\n");
				printf("				default: begin local2 = 0;renamed_rs2 = rs2_fp?scoreboard_latest_rename_fp[s2]:scoreboard_latest_rename[s2];end\n");
				printf("`else\n");
				printf("				default: begin local2 = 0;renamed_rs2 = scoreboard_latest_rename[s2];end\n");
				printf("`endif\n");
				printf("				endcase\n");
				printf("				end\n");
//				if (mm == 1) 
//					printf("			end\n");
//			}
			if (n == 1) {
				printf("		end\n");
			}
		}
		printf("`ifdef FP\n");
		printf("		wire [%d:0]fpmatch3 = {", i-1);
		for (j = i-1; j >= 0; j--)printf("all_rd_fp_rename[%d]==rs3_fp%s",j,j>0?",":"};\n");
		printf("`else\n");
		printf("		wire [%d:0]fpmatch3 = %d'b", i-1,i);
		for (j = i-1; j >= 0; j--)printf("1");printf(";");
		printf("`endif\n");
		printf("		wire [%d:0]mk3 = fpmatch3&{", i-1);
		for (j = i-1; j >= 0; j--) 
			printf("all_makes_rd_rename[%d]&(all_rd_rename[%d] == s3)&needs_s3%s", j,j,j==0?"};\n":", ");
		for (n = 0; n < 2; n++) {
			switch (n) {
			case 0: {
					printf("		if (LNCOMMIT >= 5) begin\n");
				}
				break;
			case 1: {
					printf("		end else begin\n");
					printf("			wire [5-LNCOMMIT-1:0]ff;\n");
					printf("			assign ff=0;\n");
				}
				break;
			}
//			for (mm=0; mm < 2; mm++) {
//				if (mm == 0) {
//					printf("			if (NHART==1) begin\n");
//				} else {
//					printf("			end else begin\n");
//				}
				printf("				always @(*) begin local3 = 1;\n");
				printf("				if (s3==0) begin\n");
				printf("					renamed_rs3 = 0;\n");
				printf("				end else\n");
				printf("				casez (mk3) // synthesis full_case parallel_case\n");
				for (j=i-1; j >= 0 ; j--) {
					printf("				%d'b", i);
					for (k=i-1; k >= 0;k--)
						printf(k >j?"0":k==j?"1":"?");
					if (n == 1) {
//						if (mm == 0) {
							printf(": renamed_rs3 = {1'b1, ff, map_rd_rename[%d]};\n", j);
//						} else {
//							printf(": renamed_rs3 = {1'b1, hart_dec, ff, map_rd_rename[%d]};\n", j);
//						}
					} else {
//						if (mm == 0) {
							printf(": renamed_rs3 = {1'b1, map_rd_rename[%d]};\n", j);
//						} else {
//							printf(": renamed_rs3 = {1'b1, hart_dec, map_rd_rename[%d]};\n", j);
//						}
					}
				}
				printf("`ifdef FP\n");
				printf("				default: begin local3 = 0;renamed_rs3 = rs3_fp?scoreboard_latest_rename_fp[s3]:scoreboard_latest_rename[s3];end\n");
				printf("`else\n");
				printf("				default: begin local3 = 0;renamed_rs3 = scoreboard_latest_rename[s3];end\n");
				printf("`endif\n");
				printf("				endcase\n");
				printf("				end\n");
//				if (mm == 1) 
//					printf("			end\n");
//			}
			if (n == 1) {
				printf("		end\n");
			}
		}
		printf("	end else\n");
	}
	printf("	begin end\n");
	printf("	\n");

        printf("	always @(*) begin\n");
        printf("		d = 5'bx;\n");
        printf("		s1 = 5'bx;\n");
        printf("		s2 = 5'bx;\n");
        printf("		s3 = 5'bx;\n");
        printf("		makes_d = 1'bx;\n");
        printf("		needs_s2 = 1'bx;\n");
        printf("		needs_s3 = 1'bx;\n");
        printf("		rd_fp = 1'bx;\n");
        printf("		rs1_fp = 1'bx;\n");
        printf("		rs2_fp = 1'bx;\n");
        printf("		rs3_fp = 1'bx;\n");
        printf("		branch_token = 'bx;\n");
        printf("		branch_token_ret = 'bx;\n");
        printf("		short = 'bx;\n");
        printf("		start = 'bx;\n");
        printf("		immed = 'bx;\n");
        printf("		control = 'bx;\n");
        printf("		unit_type = 'bx;\n");
        printf("		pc_dest = pc_dest_dec;\n");
        printf("`ifdef TRACE_CACHE\n");
        printf("		if (pc_trace_used[H]) begin \n");
        printf("			d = trace_out_rd[H][D];\n");
        printf("			s1 = trace_out_rs1[H][D];\n");
        printf("			s2 = trace_out_rs2[H][D];\n");
        printf("			s3 = trace_out_rs3[H][D];\n");
        printf("			control = trace_out_control[H][D];\n");
        printf("			makes_d = trace_out_makes_rd[H][D];\n");
        printf("			needs_s2 = trace_out_needs_rs2[H][D];\n");
        printf("			needs_s3 = trace_out_needs_rs3[H][D];\n");
        printf("`ifdef FP\n");
        printf("			rd_fp = trace_out_rd_fp[H][D];\n");
        printf("			rs1_fp = trace_out_rs1_fp[H][D];\n");
        printf("			rs2_fp = trace_out_rs2_fp[H][D];\n");
        printf("			rs3_fp = trace_out_rs3_fp[H][D];\n");
        printf("`endif\n");
        printf("			branch_token = trace_out_branch_token[H][D];\n");
        printf("			branch_token_ret = trace_out_branch_token_ret[H][D];\n");
        printf("			short = trace_out_short[H][D];\n");
        printf("			start = trace_out_start[H][D];\n");
        printf("			immed = trace_out_immed[H][D];\n");
        printf("			unit_type = trace_out_unit_type[H][D];\n");
        printf("			pc = trace_out_pc[H][D];\n");
        printf("			pc_dest = trace_out_pc_dest[H][D];\n");
        printf("		end else\n");
        printf("`endif\n");
        printf("		casez (sel_out) // synthesis full_case parallel_case\n");
        for (i = 0; i < B; i++) {
                printf("		%d'b", B);
                for (j = B-1; j >= 0; j--) printf(i==j?"1":"?");
                printf(": begin d = rd_dec[%d]; s1 = rs1_dec[%d]; needs_s2 = needs_rs2_dec[%d];needs_s3 = needs_rs3_dec[%d];s2 = rs2_dec[%d]; s3 = rs3_dec[%d];makes_d = makes_rd_dec[%d]; short = short_dec[%d]; start = start_dec[%d]; immed = immed_dec[%d]; control=control_dec[%d]; unit_type=unit_type_dec[%d];pc=pc_dec[%d]; rd_fp = rd_fp_dec[%d]; rs1_fp = rs1_fp_dec[%d]; rs2_fp = rs2_fp_dec[%d]; rs3_fp = rs3_fp_dec[%d]; ",  i, i, i,i,i,i,i,i,i,i,i,i,i,i,i,i,i);
		if (i > 0) {
			printf(" branch_token = dec_branch_token; branch_token_ret = dec_branch_token_ret; end\n");
		} else {
			printf(" branch_token = r_dec_partial0?dec_branch_token_prev:dec_branch_token; branch_token_ret = r_dec_partial0?dec_branch_token_ret_prev:dec_branch_token_ret; end\n");
		}
        }
        printf("		endcase\n");
        printf("	end\n");

}
