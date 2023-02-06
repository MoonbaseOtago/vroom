//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-23 Paul Campbell - paul@taniwha.com
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
	int i,j,k,t;

	if (argc < 2) {
		B = 8;
	} else {
		B = strtol((const char *)argv[1], 0, 0);
	}
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

	printf("	always @(*)\n");
	printf("	casez ({r_op, r_addw, r_arith, r_right, sr2[5:0]}) // synthesis full_case parallel_case\n");
	printf("// sll \n");
	for (i = 0; i < B; i++) {
		printf("	12'b000_0?0_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if (((B-1)-i-j) <0) {
				printf("1'b0%s", j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B-1)-i-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// srl\n");
	for (i = 0; i < B; i++) {
		printf("	12'b000_0?1_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if (j < i) {
				printf("fill%s", j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B-1)+i-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// sll.w\n");
	for (i = 0; i < (B/2); i++) {
		printf("	12'b000_1?0_?%s: c_res = {", bin(i, 5));
		for (j = 0; j < (B/2); j++) 
			printf("r1[%d],", (B/2-1)-i);
		for (j = 0; j < (B/2); j++) {
			if (((B/2-1)-i-j) <0) {
				printf("1'b0%s", j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B/2-1)-i-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("// srl.w\n");
	for (i = 0; i < (B/2); i++) {
		printf("	12'b000_1?1_?%s: c_res = {", bin(i, 5));
		if (i==0) {
			for (j = 0; j < (B/2);j++)
				printf("r1[31],");
		} else {
			for (j = 0; j < (B/2);j++)
				printf("fill32,");
		}
		for (j = 0; j < (B/2); j++) {
			if (j < i) {
				printf("fill32%s", j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B/2-1)+i-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("`ifdef B\n");
	printf("// slo \n");
	for (i = 0; i < B; i++) {
		printf("	12'b001_000_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if (((B-1)-i-j) <0) {
				printf("1'b1%s", j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B-1)-i-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// sro\n");
	for (i = 0; i < B; i++) {
		printf("	12'b001_001_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if (j < i) {
				printf("1'b1%s", j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B-1)+i-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// slo.w\n");
	for (i = 0; i < (B/2); i++) {
		printf("	12'b000_100_?%s: c_res = {", bin(i, 5));
		for (j = 0; j < (B/2); j++) 
			printf("r1[%d],", (B/2-1)-i);
		for (j = 0; j < (B/2); j++) {
			if (((B/2-1)-i-j) <0) {
				printf("1'b1%s", j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B/2-1)-i-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("// sro.w\n");
	for (i = 0; i < (B/2); i++) {
		printf("	12'b000_101_?%s: c_res = {", bin(i, 5));
		if (i==0) {
			for (j = 0; j < (B/2);j++)
				printf("r1[31],");
		} else {
			for (j = 0; j < (B/2);j++)
				printf("1'b1,");
		}
		for (j = 0; j < (B/2); j++) {
			if (j < i) {
				printf("1'b1%s", j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B/2-1)+i-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("// rol \n");
	for (i = 0; i < B; i++) {
		printf("	12'b001_010_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if (((B-1)-i-j) <0) {
				printf("r1[%d]%s", ((B-1)-i-j)&0x3f, j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B-1)-i-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// ror\n");
	for (i = 0; i < B; i++) {
		printf("	12'b001_011_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if (j < i) {
				printf("r1[%d]%s", ((B-1)+i-j)&0x3f, j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B-1)+i-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// rol.w \n");
	for (i = 0; i < B/2; i++) {
		printf("	12'b001_110_?%s: c_res = {", bin(i, 5));
		for (j = 0; j < B/2; j++) 
			printf("r1[%d],", ((B/2)-i-1)&0x1f);
		for (j = 0; j < B/2; j++) {
			if (((B/2-1)-i-j) <0) {
				printf("r1[%d]%s", ((B/2-1)-i-j)&0x1f, j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B/2-1)-i-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("// ror.w\n");
	for (i = 0; i < B/2; i++) {
		printf("	12'b001_111_?%s: c_res = {", bin(i, 5));
		for (j = 0; j < B/2; j++) 
			printf("r1[%d],", ((B/2)+i-1)&0x1f);
		for (j = 0; j < B/2; j++) {
			if (j < i) {
				printf("r1[%d]%s", ((B/2-1)+i-j)&0x1f, j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", (B/2-1)+i-j, j == (B/2-1)?"};\n":",");
			}
		}
	}

	printf("// orc \n");
	printf("	12'b010_000_??????: c_res = {");
	for (i = 7; i >= 0; i--) printf("{{8{|r1[%d:%d]}}}%s", 8*i+7,8*i, i==0?"};\n":",");

	printf("// rev8 \n");
	printf("	12'b010_001_??????: c_res = (rv32 ? {32'bx, r1[7:0], r1[15:8], r1[23:16], r1[31:24]}:\n");
	printf("	                                    {r1[7:0], r1[15:8], r1[23:16], r1[31:24], r1[39:32], r1[47:40], r1[55:48], r1[63:56]});\n");


	printf("// zip \n");
	printf("	12'b010_010_??????: c_res = {{32{r1[31]}},");
	for (i = 15; i >= 0; i--) printf("r1[%d], r1[%d]%s", 2*i+1, i, i==0?"};\n":",");
	printf("// unzip \n");
	printf("	12'b010_011_??????: c_res = {{32{r1[31]}},");
	for (i = 31; i >= 1; i-=2) printf("r1[%d],", i);
	for (i = 30; i >= 0; i-=2) printf("r1[%d]%s", i, i==0?"};\n":",");

	printf("// bclr \n");
	for (i = 0; i < B; i++) {
		printf("	12'b011_000_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if ((B-1-j) == i) {
				printf("1'b0%s", j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", B-1-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// bset \n");
	for (i = 0; i < B; i++) {
		printf("	12'b011_001_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if ((B-1-j) == i) {
				printf("1'b1%s", j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", B-1-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// binv \n");
	for (i = 0; i < B; i++) {
		printf("	12'b011_010_%s: c_res = {", bin(i, 6));
		for (j = 0; j < B; j++) {
			if ((B-1-j) == i) {
				printf("~r1[%d]%s", B-1-j, j == (B-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", B-1-j, j == (B-1)?"};\n":",");
			}
		}
	}
	printf("// bext \n");
	for (i = 0; i < B; i++) {
		printf("	12'b011_011_%s: c_res = {", bin(i, 6));
		printf("63'b0, r1[%d]};\n", i);
	}
	printf("// bclr.w \n");
	for (i = 0; i < B/2; i++) {
		printf("	12'b011_100_?%s: c_res = {r1[63:32],", bin(i, 5));
		for (j = 0; j < B/2; j++) {
			if ((B/2-1-j) == i) {
				printf("1'b0%s", j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", B/2-1-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("// bset.w \n");
	for (i = 0; i < B/2; i++) {
		printf("	12'b011_101_?%s: c_res = {r1[63:32],", bin(i, 5));
		for (j = 0; j < B/2; j++) {
			if ((B/2-1-j) == i) {
				printf("1'b1%s", j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", B/2-1-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("// binv.w \n");
	for (i = 0; i < B/2; i++) {
		printf("	12'b011_110_?%s: c_res = {r1[63:32],", bin(i, 5));
		for (j = 0; j < B/2; j++) {
			if ((B/2-1-j) == i) {
				printf("~r1[%d]%s", B/2-1-j, j == (B/2-1)?"};\n":",");
			} else {
				printf("r1[%d]%s", B/2-1-j, j == (B/2-1)?"};\n":",");
			}
		}
	}
	printf("// bext.w \n");
	for (i = 0; i < B/2; i++) {
		printf("	12'b011_111_?%s: c_res = {", bin(i, 5));
		printf("63'b0, r1[%d]};\n", i);
	}

	printf("// sllu.w\n");
	for (i = 0; i < (B); i++) {
		printf("	12'b100_100_?%s: c_res = {", bin(i, 5));
		if (i < (B/2)) 
			printf("%d'b0,", B/2-i);
		if (i < (B/2)) {
			printf("r1[31:0]%s",i==0?"};\n":",");
		} else {
			printf("r1[%d:0],", i < B/2?31:B-i-1);
		}
		if (i > 0)
			printf("%d'b0};\n",i);
	}

	printf("	12'b100_?01_??????: begin\n");
	printf("				casez(r_immed[4:0]) // synthesis full_case parallel_case\n");
	printf("// sm4ed/sm4ks\n");
	printf("				5'b1????:\n");
	printf("					c_res = {{32{sm4[31]}}, sm4};\n");
	printf("// sm3p0\n");
	printf("				5'b0???0:\n");
	printf("					c_res = {{32{r1[31]^r1[22]^r1[14]}},r1[31:0]^{r1[22:0],r1[31:23]}^{r1[14:0],r1[31:15]}};\n");
	printf("// sm3p1\n");
	printf("				5'b0???1:\n");
	printf("					c_res = {{32{r1[31]^r1[16]^r1[8]}},r1[31:0]^{r1[16:0],r1[31:17]}^{r1[8:0],r1[31:9]}};\n");
	printf("			    	endcase\n");
	printf("			    end\n");

	printf("// sext.b\n");
	printf("	12'b100_?10_??????: c_res = {{56{r1[7]}}, r1[7:0]};\n");
	printf("// sext.h\n");
	printf("	12'b100_?11_??????: c_res = {{48{r1[15]}}, r1[15:0]};\n");

	printf("// xperm8\n");
	printf("	12'b101_?00_??????: begin : xperm8\n");
	printf("				reg[7:0]p[0:7];\n");
	for (i = 0; i < 8; i++) {
	printf("				p[%d] = r1[%d:%d];\n", i, 8*i+7, 8*i);
	}
	for (i = 0; i < 64; i+=8) {
	printf("				casez({rv32, r2[%d:%d]}) // synthesis full_case parallel_case\n", i+7, i);
	printf("				9'b1_0000_00??,\n");
	printf("  			    	9'b0_0000_0???: c_res[%d:%d] = p[r2[%d:%d]];\n", i+7, i, i+2, i);
	printf("  			    	default: c_res[%d:%d] = 8'b0;\n", i+7, i);
	printf("  			    	endcase\n");
	}
	printf("  			    end\n");
	printf("// xperm4\n");
	printf("	12'b101_?01_??????: begin : xperm4\n");
	printf("				reg[3:0]p[0:15];\n");
	for (i = 0; i < 16; i++) {
	printf("				p[%d] = r1[%d:%d];\n", i, 4*i+3, 4*i);
	}
	for (i = 0; i < 64; i+=4) {
	printf("				casez({rv32, r2[%d:%d]}) // synthesis full_case parallel_case\n", i+3, i);
	printf("				5'b1_0???,\n");
	printf("  			    	5'b0_????: c_res[%d:%d] = p[r2[%d:%d]];\n", i+3, i, i+3, i);
	printf("  			    	default: c_res[%d:%d] = 8'b0;\n", i+3, i);
	printf("  			    	endcase\n");
	}
	printf("  			    end\n");
	printf("// aes64ks2i\n");
	printf("	12'b101_?10_??????: c_res = aes64ks2i;\n");
	printf("// sha256/512\n");
	printf("	12'b101_?11_??????: begin : sha256\n");
	printf("			    	reg [31:0]a;\n");
	printf("			    	case(r_immed[3:0])// synthesis full_case parallel_case\n");
	printf("			    	0: begin //sha256sum0\n");
	printf("			    		a = {r1[1:0],r1[31:2]}^{r1[12:0],r1[31:13]}^{r1[21:0],r1[31:22]};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	1: begin //sha256sum1\n");
	printf("			    		a = {r1[5:0],r1[31:6]}^{r1[10:0],r1[31:11]}^{r1[24:0],r1[31:25]};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	2: begin //sha256sig0\n");
	printf("			    		a = {r1[6:0],r1[31:7]}^{r1[17:0],r1[31:18]}^{3'b0,r1[31:3]};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	3: begin //sha256sig1\n");
	printf("			    		a = {r1[16:0],r1[31:17]}^{r1[18:0],r1[31:19]}^{10'b0,r1[31:10]};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	4: //sha512sum0\n");
	printf("			    	    c_res = {r1[27:0],r1[63:28]}^{r1[33:0],r1[63:34]}^{r1[38:0],r1[63:39]};\n");
	printf("			    	5: //sha512sum1\n");
	printf("			    	    c_res = {r1[13:0],r1[63:14]}^{r1[17:0],r1[63:18]}^{r1[40:0],r1[63:41]};\n");
	printf("			    	6: //sha512sig0\n");
	printf("			    	    c_res = {r1[0],r1[63:1]}^{r1[7:0],r1[63:8]}^{7'b0,r1[63:7]};\n");
	printf("			    	7: //sha512sig1\n");
	printf("			    	    c_res = {r1[18:0],r1[63:19]}^{r1[60:0],r1[63:61]}^{6'b0,r1[63:6]};\n");
	printf("			    	8: begin //sha512sum0r\n");
	printf("			    		a = {r1[6:0],25'b0}^{r1[1:0],30'b0}^{28'b0, r1[31:28]}^{7'b0,r2[31:7]}^{2'b0, r2[31:2]}^{r2[28:0],4'b0};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	9: begin //sha512sum1r\n");
	printf("			    		a = {r1[8:0],23'b0}^{14'b0,r1[31:14]}^{18'b0, r1[31:18]}^{r2[22:0],9'b0}^{r2[14:0], 18'b0}^{r2[18:0],14'b0};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	10: begin //sha512sig0l\n");
	printf("			    		a = {1'b0, r1[31:1]}^{7'b0, r1[31:7]}^{8'b0, r1[31:8]}^{r2[0:0],31'b0}^{r2[7:0],24'b0}^{r2[6:0],25'b0};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	11: begin //sha512sig1l\n");
	printf("			    		a = {r1[28:0], 3'b0}^{6'b0, r1[31:6]}^{19'b0, r1[31:19]}^{29'b0, r2[31:29]}^{r2[18:0],13'b0}^{r2[5:0],26'b0};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	12: begin //sha512sig0h\n");
	printf("			    		a = {1'b0, r1[31:1]}^{7'b0, r1[31:7]}^{8'b0, r1[31:8]}^{r2[0:0],31'b0}^{r2[7:0],24'b0};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	13: begin //sha512sig1h\n");
	printf("			    		a = {r1[28:0], 3'b0}^{6'b0, r1[31:6]}^{19'b0, r1[31:19]}^{29'b0, r2[31:29]}^{r2[19:0],13'b0};\n");
	printf("			    		c_res = {{32{a[31]}}, a};\n");
	printf("			    	    end\n");
	printf("			    	endcase\n");
	printf("			    end\n");
#ifdef NOTDEF
	printf("// bmator\n");
	printf("	12'b101_?00_??????: c_res = {");
	printf("		(r1[56]&r2[7])|(r1[57]&r2[15])|(r1[58]&r2[23])|(r1[59]&r2[31])|(r1[60]&r2[39])|(r1[61]&r2[47])|(r1[62]&r2[55])|(r1[63]&r2[63]),\n");
	printf("		(r1[56]&r2[6])|(r1[57]&r2[14])|(r1[58]&r2[22])|(r1[59]&r2[30])|(r1[60]&r2[38])|(r1[61]&r2[46])|(r1[62]&r2[54])|(r1[63]&r2[62]),\n");
	printf("		(r1[56]&r2[5])|(r1[57]&r2[13])|(r1[58]&r2[21])|(r1[59]&r2[29])|(r1[60]&r2[37])|(r1[61]&r2[45])|(r1[62]&r2[53])|(r1[63]&r2[61]),\n");
	printf("		(r1[56]&r2[4])|(r1[57]&r2[12])|(r1[58]&r2[20])|(r1[59]&r2[28])|(r1[60]&r2[36])|(r1[61]&r2[44])|(r1[62]&r2[52])|(r1[63]&r2[60]),\n");
	printf("		(r1[56]&r2[3])|(r1[57]&r2[11])|(r1[58]&r2[19])|(r1[59]&r2[27])|(r1[60]&r2[35])|(r1[61]&r2[43])|(r1[62]&r2[51])|(r1[63]&r2[59]),\n");
	printf("		(r1[56]&r2[2])|(r1[57]&r2[10])|(r1[58]&r2[18])|(r1[59]&r2[26])|(r1[60]&r2[34])|(r1[61]&r2[42])|(r1[62]&r2[50])|(r1[63]&r2[58]),\n");
	printf("		(r1[56]&r2[1])|(r1[57]&r2[9])|(r1[58]&r2[17])|(r1[59]&r2[25])|(r1[60]&r2[33])|(r1[61]&r2[41])|(r1[62]&r2[49])|(r1[63]&r2[57]),\n");
	printf("		(r1[56]&r2[0])|(r1[57]&r2[8])|(r1[58]&r2[16])|(r1[59]&r2[24])|(r1[60]&r2[32])|(r1[61]&r2[40])|(r1[62]&r2[48])|(r1[63]&r2[56]),\n");
	printf("		(r1[48]&r2[7])|(r1[49]&r2[15])|(r1[50]&r2[23])|(r1[51]&r2[31])|(r1[52]&r2[39])|(r1[53]&r2[47])|(r1[54]&r2[55])|(r1[55]&r2[63]),\n");
	printf("		(r1[48]&r2[6])|(r1[49]&r2[14])|(r1[50]&r2[22])|(r1[51]&r2[30])|(r1[52]&r2[38])|(r1[53]&r2[46])|(r1[54]&r2[54])|(r1[55]&r2[62]),\n");
	printf("		(r1[48]&r2[5])|(r1[49]&r2[13])|(r1[50]&r2[21])|(r1[51]&r2[29])|(r1[52]&r2[37])|(r1[53]&r2[45])|(r1[54]&r2[53])|(r1[55]&r2[61]),\n");
	printf("		(r1[48]&r2[4])|(r1[49]&r2[12])|(r1[50]&r2[20])|(r1[51]&r2[28])|(r1[52]&r2[36])|(r1[53]&r2[44])|(r1[54]&r2[52])|(r1[55]&r2[60]),\n");
	printf("		(r1[48]&r2[3])|(r1[49]&r2[11])|(r1[50]&r2[19])|(r1[51]&r2[27])|(r1[52]&r2[35])|(r1[53]&r2[43])|(r1[54]&r2[51])|(r1[55]&r2[59]),\n");
	printf("		(r1[48]&r2[2])|(r1[49]&r2[10])|(r1[50]&r2[18])|(r1[51]&r2[26])|(r1[52]&r2[34])|(r1[53]&r2[42])|(r1[54]&r2[50])|(r1[55]&r2[58]),\n");
	printf("		(r1[48]&r2[1])|(r1[49]&r2[9])|(r1[50]&r2[17])|(r1[51]&r2[25])|(r1[52]&r2[33])|(r1[53]&r2[41])|(r1[54]&r2[49])|(r1[55]&r2[57]),\n");
	printf("		(r1[48]&r2[0])|(r1[49]&r2[8])|(r1[50]&r2[16])|(r1[51]&r2[24])|(r1[52]&r2[32])|(r1[53]&r2[40])|(r1[54]&r2[48])|(r1[55]&r2[56]),\n");
	printf("		(r1[40]&r2[7])|(r1[41]&r2[15])|(r1[42]&r2[23])|(r1[43]&r2[31])|(r1[44]&r2[39])|(r1[45]&r2[47])|(r1[46]&r2[55])|(r1[47]&r2[63]),\n");
	printf("		(r1[40]&r2[6])|(r1[41]&r2[14])|(r1[42]&r2[22])|(r1[43]&r2[30])|(r1[44]&r2[38])|(r1[45]&r2[46])|(r1[46]&r2[54])|(r1[47]&r2[62]),\n");
	printf("		(r1[40]&r2[5])|(r1[41]&r2[13])|(r1[42]&r2[21])|(r1[43]&r2[29])|(r1[44]&r2[37])|(r1[45]&r2[45])|(r1[46]&r2[53])|(r1[47]&r2[61]),\n");
	printf("		(r1[40]&r2[4])|(r1[41]&r2[12])|(r1[42]&r2[20])|(r1[43]&r2[28])|(r1[44]&r2[36])|(r1[45]&r2[44])|(r1[46]&r2[52])|(r1[47]&r2[60]),\n");
	printf("		(r1[40]&r2[3])|(r1[41]&r2[11])|(r1[42]&r2[19])|(r1[43]&r2[27])|(r1[44]&r2[35])|(r1[45]&r2[43])|(r1[46]&r2[51])|(r1[47]&r2[59]),\n");
	printf("		(r1[40]&r2[2])|(r1[41]&r2[10])|(r1[42]&r2[18])|(r1[43]&r2[26])|(r1[44]&r2[34])|(r1[45]&r2[42])|(r1[46]&r2[50])|(r1[47]&r2[58]),\n");
	printf("		(r1[40]&r2[1])|(r1[41]&r2[9])|(r1[42]&r2[17])|(r1[43]&r2[25])|(r1[44]&r2[33])|(r1[45]&r2[41])|(r1[46]&r2[49])|(r1[47]&r2[57]),\n");
	printf("		(r1[40]&r2[0])|(r1[41]&r2[8])|(r1[42]&r2[16])|(r1[43]&r2[24])|(r1[44]&r2[32])|(r1[45]&r2[40])|(r1[46]&r2[48])|(r1[47]&r2[56]),\n");
	printf("		(r1[32]&r2[7])|(r1[33]&r2[15])|(r1[34]&r2[23])|(r1[35]&r2[31])|(r1[36]&r2[39])|(r1[37]&r2[47])|(r1[38]&r2[55])|(r1[39]&r2[63]),\n");
	printf("		(r1[32]&r2[6])|(r1[33]&r2[14])|(r1[34]&r2[22])|(r1[35]&r2[30])|(r1[36]&r2[38])|(r1[37]&r2[46])|(r1[38]&r2[54])|(r1[39]&r2[62]),\n");
	printf("		(r1[32]&r2[5])|(r1[33]&r2[13])|(r1[34]&r2[21])|(r1[35]&r2[29])|(r1[36]&r2[37])|(r1[37]&r2[45])|(r1[38]&r2[53])|(r1[39]&r2[61]),\n");
	printf("		(r1[32]&r2[4])|(r1[33]&r2[12])|(r1[34]&r2[20])|(r1[35]&r2[28])|(r1[36]&r2[36])|(r1[37]&r2[44])|(r1[38]&r2[52])|(r1[39]&r2[60]),\n");
	printf("		(r1[32]&r2[3])|(r1[33]&r2[11])|(r1[34]&r2[19])|(r1[35]&r2[27])|(r1[36]&r2[35])|(r1[37]&r2[43])|(r1[38]&r2[51])|(r1[39]&r2[59]),\n");
	printf("		(r1[32]&r2[2])|(r1[33]&r2[10])|(r1[34]&r2[18])|(r1[35]&r2[26])|(r1[36]&r2[34])|(r1[37]&r2[42])|(r1[38]&r2[50])|(r1[39]&r2[58]),\n");
	printf("		(r1[32]&r2[1])|(r1[33]&r2[9])|(r1[34]&r2[17])|(r1[35]&r2[25])|(r1[36]&r2[33])|(r1[37]&r2[41])|(r1[38]&r2[49])|(r1[39]&r2[57]),\n");
	printf("		(r1[32]&r2[0])|(r1[33]&r2[8])|(r1[34]&r2[16])|(r1[35]&r2[24])|(r1[36]&r2[32])|(r1[37]&r2[40])|(r1[38]&r2[48])|(r1[39]&r2[56]),\n");
	printf("		(r1[24]&r2[7])|(r1[25]&r2[15])|(r1[26]&r2[23])|(r1[27]&r2[31])|(r1[28]&r2[39])|(r1[29]&r2[47])|(r1[30]&r2[55])|(r1[31]&r2[63]),\n");
	printf("		(r1[24]&r2[6])|(r1[25]&r2[14])|(r1[26]&r2[22])|(r1[27]&r2[30])|(r1[28]&r2[38])|(r1[29]&r2[46])|(r1[30]&r2[54])|(r1[31]&r2[62]),\n");
	printf("		(r1[24]&r2[5])|(r1[25]&r2[13])|(r1[26]&r2[21])|(r1[27]&r2[29])|(r1[28]&r2[37])|(r1[29]&r2[45])|(r1[30]&r2[53])|(r1[31]&r2[61]),\n");
	printf("		(r1[24]&r2[4])|(r1[25]&r2[12])|(r1[26]&r2[20])|(r1[27]&r2[28])|(r1[28]&r2[36])|(r1[29]&r2[44])|(r1[30]&r2[52])|(r1[31]&r2[60]),\n");
	printf("		(r1[24]&r2[3])|(r1[25]&r2[11])|(r1[26]&r2[19])|(r1[27]&r2[27])|(r1[28]&r2[35])|(r1[29]&r2[43])|(r1[30]&r2[51])|(r1[31]&r2[59]),\n");
	printf("		(r1[24]&r2[2])|(r1[25]&r2[10])|(r1[26]&r2[18])|(r1[27]&r2[26])|(r1[28]&r2[34])|(r1[29]&r2[42])|(r1[30]&r2[50])|(r1[31]&r2[58]),\n");
	printf("		(r1[24]&r2[1])|(r1[25]&r2[9])|(r1[26]&r2[17])|(r1[27]&r2[25])|(r1[28]&r2[33])|(r1[29]&r2[41])|(r1[30]&r2[49])|(r1[31]&r2[57]),\n");
	printf("		(r1[24]&r2[0])|(r1[25]&r2[8])|(r1[26]&r2[16])|(r1[27]&r2[24])|(r1[28]&r2[32])|(r1[29]&r2[40])|(r1[30]&r2[48])|(r1[31]&r2[56]),\n");
	printf("		(r1[16]&r2[7])|(r1[17]&r2[15])|(r1[18]&r2[23])|(r1[19]&r2[31])|(r1[20]&r2[39])|(r1[21]&r2[47])|(r1[22]&r2[55])|(r1[23]&r2[63]),\n");
	printf("		(r1[16]&r2[6])|(r1[17]&r2[14])|(r1[18]&r2[22])|(r1[19]&r2[30])|(r1[20]&r2[38])|(r1[21]&r2[46])|(r1[22]&r2[54])|(r1[23]&r2[62]),\n");
	printf("		(r1[16]&r2[5])|(r1[17]&r2[13])|(r1[18]&r2[21])|(r1[19]&r2[29])|(r1[20]&r2[37])|(r1[21]&r2[45])|(r1[22]&r2[53])|(r1[23]&r2[61]),\n");
	printf("		(r1[16]&r2[4])|(r1[17]&r2[12])|(r1[18]&r2[20])|(r1[19]&r2[28])|(r1[20]&r2[36])|(r1[21]&r2[44])|(r1[22]&r2[52])|(r1[23]&r2[60]),\n");
	printf("		(r1[16]&r2[3])|(r1[17]&r2[11])|(r1[18]&r2[19])|(r1[19]&r2[27])|(r1[20]&r2[35])|(r1[21]&r2[43])|(r1[22]&r2[51])|(r1[23]&r2[59]),\n");
	printf("		(r1[16]&r2[2])|(r1[17]&r2[10])|(r1[18]&r2[18])|(r1[19]&r2[26])|(r1[20]&r2[34])|(r1[21]&r2[42])|(r1[22]&r2[50])|(r1[23]&r2[58]),\n");
	printf("		(r1[16]&r2[1])|(r1[17]&r2[9])|(r1[18]&r2[17])|(r1[19]&r2[25])|(r1[20]&r2[33])|(r1[21]&r2[41])|(r1[22]&r2[49])|(r1[23]&r2[57]),\n");
	printf("		(r1[16]&r2[0])|(r1[17]&r2[8])|(r1[18]&r2[16])|(r1[19]&r2[24])|(r1[20]&r2[32])|(r1[21]&r2[40])|(r1[22]&r2[48])|(r1[23]&r2[56]),\n");
	printf("		(r1[8]&r2[7])|(r1[9]&r2[15])|(r1[10]&r2[23])|(r1[11]&r2[31])|(r1[12]&r2[39])|(r1[13]&r2[47])|(r1[14]&r2[55])|(r1[15]&r2[63]),\n");
	printf("		(r1[8]&r2[6])|(r1[9]&r2[14])|(r1[10]&r2[22])|(r1[11]&r2[30])|(r1[12]&r2[38])|(r1[13]&r2[46])|(r1[14]&r2[54])|(r1[15]&r2[62]),\n");
	printf("		(r1[8]&r2[5])|(r1[9]&r2[13])|(r1[10]&r2[21])|(r1[11]&r2[29])|(r1[12]&r2[37])|(r1[13]&r2[45])|(r1[14]&r2[53])|(r1[15]&r2[61]),\n");
	printf("		(r1[8]&r2[4])|(r1[9]&r2[12])|(r1[10]&r2[20])|(r1[11]&r2[28])|(r1[12]&r2[36])|(r1[13]&r2[44])|(r1[14]&r2[52])|(r1[15]&r2[60]),\n");
	printf("		(r1[8]&r2[3])|(r1[9]&r2[11])|(r1[10]&r2[19])|(r1[11]&r2[27])|(r1[12]&r2[35])|(r1[13]&r2[43])|(r1[14]&r2[51])|(r1[15]&r2[59]),\n");
	printf("		(r1[8]&r2[2])|(r1[9]&r2[10])|(r1[10]&r2[18])|(r1[11]&r2[26])|(r1[12]&r2[34])|(r1[13]&r2[42])|(r1[14]&r2[50])|(r1[15]&r2[58]),\n");
	printf("		(r1[8]&r2[1])|(r1[9]&r2[9])|(r1[10]&r2[17])|(r1[11]&r2[25])|(r1[12]&r2[33])|(r1[13]&r2[41])|(r1[14]&r2[49])|(r1[15]&r2[57]),\n");
	printf("		(r1[8]&r2[0])|(r1[9]&r2[8])|(r1[10]&r2[16])|(r1[11]&r2[24])|(r1[12]&r2[32])|(r1[13]&r2[40])|(r1[14]&r2[48])|(r1[15]&r2[56]),\n");
	printf("		(r1[0]&r2[7])|(r1[1]&r2[15])|(r1[2]&r2[23])|(r1[3]&r2[31])|(r1[4]&r2[39])|(r1[5]&r2[47])|(r1[6]&r2[55])|(r1[7]&r2[63]),\n");
	printf("		(r1[0]&r2[6])|(r1[1]&r2[14])|(r1[2]&r2[22])|(r1[3]&r2[30])|(r1[4]&r2[38])|(r1[5]&r2[46])|(r1[6]&r2[54])|(r1[7]&r2[62]),\n");
	printf("		(r1[0]&r2[5])|(r1[1]&r2[13])|(r1[2]&r2[21])|(r1[3]&r2[29])|(r1[4]&r2[37])|(r1[5]&r2[45])|(r1[6]&r2[53])|(r1[7]&r2[61]),\n");
	printf("		(r1[0]&r2[4])|(r1[1]&r2[12])|(r1[2]&r2[20])|(r1[3]&r2[28])|(r1[4]&r2[36])|(r1[5]&r2[44])|(r1[6]&r2[52])|(r1[7]&r2[60]),\n");
	printf("		(r1[0]&r2[3])|(r1[1]&r2[11])|(r1[2]&r2[19])|(r1[3]&r2[27])|(r1[4]&r2[35])|(r1[5]&r2[43])|(r1[6]&r2[51])|(r1[7]&r2[59]),\n");
	printf("		(r1[0]&r2[2])|(r1[1]&r2[10])|(r1[2]&r2[18])|(r1[3]&r2[26])|(r1[4]&r2[34])|(r1[5]&r2[42])|(r1[6]&r2[50])|(r1[7]&r2[58]),\n");
	printf("		(r1[0]&r2[1])|(r1[1]&r2[9])|(r1[2]&r2[17])|(r1[3]&r2[25])|(r1[4]&r2[33])|(r1[5]&r2[41])|(r1[6]&r2[49])|(r1[7]&r2[57]),\n");
	printf("		(r1[0]&r2[0])|(r1[1]&r2[8])|(r1[2]&r2[16])|(r1[3]&r2[24])|(r1[4]&r2[32])|(r1[5]&r2[40])|(r1[6]&r2[48])|(r1[7]&r2[56])};\n");
	printf("// bmatxor\n");
	printf("	12'b101_?01_??????: c_res = {\n");
	printf("		(r1[56]&r2[7])^(r1[57]&r2[15])^(r1[58]&r2[23])^(r1[59]&r2[31])^(r1[60]&r2[39])^(r1[61]&r2[47])^(r1[62]&r2[55])^(r1[63]&r2[63]),\n");
	printf("		(r1[56]&r2[6])^(r1[57]&r2[14])^(r1[58]&r2[22])^(r1[59]&r2[30])^(r1[60]&r2[38])^(r1[61]&r2[46])^(r1[62]&r2[54])^(r1[63]&r2[62]),\n");
	printf("		(r1[56]&r2[5])^(r1[57]&r2[13])^(r1[58]&r2[21])^(r1[59]&r2[29])^(r1[60]&r2[37])^(r1[61]&r2[45])^(r1[62]&r2[53])^(r1[63]&r2[61]),\n");
	printf("		(r1[56]&r2[4])^(r1[57]&r2[12])^(r1[58]&r2[20])^(r1[59]&r2[28])^(r1[60]&r2[36])^(r1[61]&r2[44])^(r1[62]&r2[52])^(r1[63]&r2[60]),\n");
	printf("		(r1[56]&r2[3])^(r1[57]&r2[11])^(r1[58]&r2[19])^(r1[59]&r2[27])^(r1[60]&r2[35])^(r1[61]&r2[43])^(r1[62]&r2[51])^(r1[63]&r2[59]),\n");
	printf("		(r1[56]&r2[2])^(r1[57]&r2[10])^(r1[58]&r2[18])^(r1[59]&r2[26])^(r1[60]&r2[34])^(r1[61]&r2[42])^(r1[62]&r2[50])^(r1[63]&r2[58]),\n");
	printf("		(r1[56]&r2[1])^(r1[57]&r2[9])^(r1[58]&r2[17])^(r1[59]&r2[25])^(r1[60]&r2[33])^(r1[61]&r2[41])^(r1[62]&r2[49])^(r1[63]&r2[57]),\n");
	printf("		(r1[56]&r2[0])^(r1[57]&r2[8])^(r1[58]&r2[16])^(r1[59]&r2[24])^(r1[60]&r2[32])^(r1[61]&r2[40])^(r1[62]&r2[48])^(r1[63]&r2[56]),\n");
	printf("		(r1[48]&r2[7])^(r1[49]&r2[15])^(r1[50]&r2[23])^(r1[51]&r2[31])^(r1[52]&r2[39])^(r1[53]&r2[47])^(r1[54]&r2[55])^(r1[55]&r2[63]),\n");
	printf("		(r1[48]&r2[6])^(r1[49]&r2[14])^(r1[50]&r2[22])^(r1[51]&r2[30])^(r1[52]&r2[38])^(r1[53]&r2[46])^(r1[54]&r2[54])^(r1[55]&r2[62]),\n");
	printf("		(r1[48]&r2[5])^(r1[49]&r2[13])^(r1[50]&r2[21])^(r1[51]&r2[29])^(r1[52]&r2[37])^(r1[53]&r2[45])^(r1[54]&r2[53])^(r1[55]&r2[61]),\n");
	printf("		(r1[48]&r2[4])^(r1[49]&r2[12])^(r1[50]&r2[20])^(r1[51]&r2[28])^(r1[52]&r2[36])^(r1[53]&r2[44])^(r1[54]&r2[52])^(r1[55]&r2[60]),\n");
	printf("		(r1[48]&r2[3])^(r1[49]&r2[11])^(r1[50]&r2[19])^(r1[51]&r2[27])^(r1[52]&r2[35])^(r1[53]&r2[43])^(r1[54]&r2[51])^(r1[55]&r2[59]),\n");
	printf("		(r1[48]&r2[2])^(r1[49]&r2[10])^(r1[50]&r2[18])^(r1[51]&r2[26])^(r1[52]&r2[34])^(r1[53]&r2[42])^(r1[54]&r2[50])^(r1[55]&r2[58]),\n");
	printf("		(r1[48]&r2[1])^(r1[49]&r2[9])^(r1[50]&r2[17])^(r1[51]&r2[25])^(r1[52]&r2[33])^(r1[53]&r2[41])^(r1[54]&r2[49])^(r1[55]&r2[57]),\n");
	printf("		(r1[48]&r2[0])^(r1[49]&r2[8])^(r1[50]&r2[16])^(r1[51]&r2[24])^(r1[52]&r2[32])^(r1[53]&r2[40])^(r1[54]&r2[48])^(r1[55]&r2[56]),\n");
	printf("		(r1[40]&r2[7])^(r1[41]&r2[15])^(r1[42]&r2[23])^(r1[43]&r2[31])^(r1[44]&r2[39])^(r1[45]&r2[47])^(r1[46]&r2[55])^(r1[47]&r2[63]),\n");
	printf("		(r1[40]&r2[6])^(r1[41]&r2[14])^(r1[42]&r2[22])^(r1[43]&r2[30])^(r1[44]&r2[38])^(r1[45]&r2[46])^(r1[46]&r2[54])^(r1[47]&r2[62]),\n");
	printf("		(r1[40]&r2[5])^(r1[41]&r2[13])^(r1[42]&r2[21])^(r1[43]&r2[29])^(r1[44]&r2[37])^(r1[45]&r2[45])^(r1[46]&r2[53])^(r1[47]&r2[61]),\n");
	printf("		(r1[40]&r2[4])^(r1[41]&r2[12])^(r1[42]&r2[20])^(r1[43]&r2[28])^(r1[44]&r2[36])^(r1[45]&r2[44])^(r1[46]&r2[52])^(r1[47]&r2[60]),\n");
	printf("		(r1[40]&r2[3])^(r1[41]&r2[11])^(r1[42]&r2[19])^(r1[43]&r2[27])^(r1[44]&r2[35])^(r1[45]&r2[43])^(r1[46]&r2[51])^(r1[47]&r2[59]),\n");
	printf("		(r1[40]&r2[2])^(r1[41]&r2[10])^(r1[42]&r2[18])^(r1[43]&r2[26])^(r1[44]&r2[34])^(r1[45]&r2[42])^(r1[46]&r2[50])^(r1[47]&r2[58]),\n");
	printf("		(r1[40]&r2[1])^(r1[41]&r2[9])^(r1[42]&r2[17])^(r1[43]&r2[25])^(r1[44]&r2[33])^(r1[45]&r2[41])^(r1[46]&r2[49])^(r1[47]&r2[57]),\n");
	printf("		(r1[40]&r2[0])^(r1[41]&r2[8])^(r1[42]&r2[16])^(r1[43]&r2[24])^(r1[44]&r2[32])^(r1[45]&r2[40])^(r1[46]&r2[48])^(r1[47]&r2[56]),\n");
	printf("		(r1[32]&r2[7])^(r1[33]&r2[15])^(r1[34]&r2[23])^(r1[35]&r2[31])^(r1[36]&r2[39])^(r1[37]&r2[47])^(r1[38]&r2[55])^(r1[39]&r2[63]),\n");
	printf("		(r1[32]&r2[6])^(r1[33]&r2[14])^(r1[34]&r2[22])^(r1[35]&r2[30])^(r1[36]&r2[38])^(r1[37]&r2[46])^(r1[38]&r2[54])^(r1[39]&r2[62]),\n");
	printf("		(r1[32]&r2[5])^(r1[33]&r2[13])^(r1[34]&r2[21])^(r1[35]&r2[29])^(r1[36]&r2[37])^(r1[37]&r2[45])^(r1[38]&r2[53])^(r1[39]&r2[61]),\n");
	printf("		(r1[32]&r2[4])^(r1[33]&r2[12])^(r1[34]&r2[20])^(r1[35]&r2[28])^(r1[36]&r2[36])^(r1[37]&r2[44])^(r1[38]&r2[52])^(r1[39]&r2[60]),\n");
	printf("		(r1[32]&r2[3])^(r1[33]&r2[11])^(r1[34]&r2[19])^(r1[35]&r2[27])^(r1[36]&r2[35])^(r1[37]&r2[43])^(r1[38]&r2[51])^(r1[39]&r2[59]),\n");
	printf("		(r1[32]&r2[2])^(r1[33]&r2[10])^(r1[34]&r2[18])^(r1[35]&r2[26])^(r1[36]&r2[34])^(r1[37]&r2[42])^(r1[38]&r2[50])^(r1[39]&r2[58]),\n");
	printf("		(r1[32]&r2[1])^(r1[33]&r2[9])^(r1[34]&r2[17])^(r1[35]&r2[25])^(r1[36]&r2[33])^(r1[37]&r2[41])^(r1[38]&r2[49])^(r1[39]&r2[57]),\n");
	printf("		(r1[32]&r2[0])^(r1[33]&r2[8])^(r1[34]&r2[16])^(r1[35]&r2[24])^(r1[36]&r2[32])^(r1[37]&r2[40])^(r1[38]&r2[48])^(r1[39]&r2[56]),\n");
	printf("		(r1[24]&r2[7])^(r1[25]&r2[15])^(r1[26]&r2[23])^(r1[27]&r2[31])^(r1[28]&r2[39])^(r1[29]&r2[47])^(r1[30]&r2[55])^(r1[31]&r2[63]),\n");
	printf("		(r1[24]&r2[6])^(r1[25]&r2[14])^(r1[26]&r2[22])^(r1[27]&r2[30])^(r1[28]&r2[38])^(r1[29]&r2[46])^(r1[30]&r2[54])^(r1[31]&r2[62]),\n");
	printf("		(r1[24]&r2[5])^(r1[25]&r2[13])^(r1[26]&r2[21])^(r1[27]&r2[29])^(r1[28]&r2[37])^(r1[29]&r2[45])^(r1[30]&r2[53])^(r1[31]&r2[61]),\n");
	printf("		(r1[24]&r2[4])^(r1[25]&r2[12])^(r1[26]&r2[20])^(r1[27]&r2[28])^(r1[28]&r2[36])^(r1[29]&r2[44])^(r1[30]&r2[52])^(r1[31]&r2[60]),\n");
	printf("		(r1[24]&r2[3])^(r1[25]&r2[11])^(r1[26]&r2[19])^(r1[27]&r2[27])^(r1[28]&r2[35])^(r1[29]&r2[43])^(r1[30]&r2[51])^(r1[31]&r2[59]),\n");
	printf("		(r1[24]&r2[2])^(r1[25]&r2[10])^(r1[26]&r2[18])^(r1[27]&r2[26])^(r1[28]&r2[34])^(r1[29]&r2[42])^(r1[30]&r2[50])^(r1[31]&r2[58]),\n");
	printf("		(r1[24]&r2[1])^(r1[25]&r2[9])^(r1[26]&r2[17])^(r1[27]&r2[25])^(r1[28]&r2[33])^(r1[29]&r2[41])^(r1[30]&r2[49])^(r1[31]&r2[57]),\n");
	printf("		(r1[24]&r2[0])^(r1[25]&r2[8])^(r1[26]&r2[16])^(r1[27]&r2[24])^(r1[28]&r2[32])^(r1[29]&r2[40])^(r1[30]&r2[48])^(r1[31]&r2[56]),\n");
	printf("		(r1[16]&r2[7])^(r1[17]&r2[15])^(r1[18]&r2[23])^(r1[19]&r2[31])^(r1[20]&r2[39])^(r1[21]&r2[47])^(r1[22]&r2[55])^(r1[23]&r2[63]),\n");
	printf("		(r1[16]&r2[6])^(r1[17]&r2[14])^(r1[18]&r2[22])^(r1[19]&r2[30])^(r1[20]&r2[38])^(r1[21]&r2[46])^(r1[22]&r2[54])^(r1[23]&r2[62]),\n");
	printf("		(r1[16]&r2[5])^(r1[17]&r2[13])^(r1[18]&r2[21])^(r1[19]&r2[29])^(r1[20]&r2[37])^(r1[21]&r2[45])^(r1[22]&r2[53])^(r1[23]&r2[61]),\n");
	printf("		(r1[16]&r2[4])^(r1[17]&r2[12])^(r1[18]&r2[20])^(r1[19]&r2[28])^(r1[20]&r2[36])^(r1[21]&r2[44])^(r1[22]&r2[52])^(r1[23]&r2[60]),\n");
	printf("		(r1[16]&r2[3])^(r1[17]&r2[11])^(r1[18]&r2[19])^(r1[19]&r2[27])^(r1[20]&r2[35])^(r1[21]&r2[43])^(r1[22]&r2[51])^(r1[23]&r2[59]),\n");
	printf("		(r1[16]&r2[2])^(r1[17]&r2[10])^(r1[18]&r2[18])^(r1[19]&r2[26])^(r1[20]&r2[34])^(r1[21]&r2[42])^(r1[22]&r2[50])^(r1[23]&r2[58]),\n");
	printf("		(r1[16]&r2[1])^(r1[17]&r2[9])^(r1[18]&r2[17])^(r1[19]&r2[25])^(r1[20]&r2[33])^(r1[21]&r2[41])^(r1[22]&r2[49])^(r1[23]&r2[57]),\n");
	printf("		(r1[16]&r2[0])^(r1[17]&r2[8])^(r1[18]&r2[16])^(r1[19]&r2[24])^(r1[20]&r2[32])^(r1[21]&r2[40])^(r1[22]&r2[48])^(r1[23]&r2[56]),\n");
	printf("		(r1[8]&r2[7])^(r1[9]&r2[15])^(r1[10]&r2[23])^(r1[11]&r2[31])^(r1[12]&r2[39])^(r1[13]&r2[47])^(r1[14]&r2[55])^(r1[15]&r2[63]),\n");
	printf("		(r1[8]&r2[6])^(r1[9]&r2[14])^(r1[10]&r2[22])^(r1[11]&r2[30])^(r1[12]&r2[38])^(r1[13]&r2[46])^(r1[14]&r2[54])^(r1[15]&r2[62]),\n");
	printf("		(r1[8]&r2[5])^(r1[9]&r2[13])^(r1[10]&r2[21])^(r1[11]&r2[29])^(r1[12]&r2[37])^(r1[13]&r2[45])^(r1[14]&r2[53])^(r1[15]&r2[61]),\n");
	printf("		(r1[8]&r2[4])^(r1[9]&r2[12])^(r1[10]&r2[20])^(r1[11]&r2[28])^(r1[12]&r2[36])^(r1[13]&r2[44])^(r1[14]&r2[52])^(r1[15]&r2[60]),\n");
	printf("		(r1[8]&r2[3])^(r1[9]&r2[11])^(r1[10]&r2[19])^(r1[11]&r2[27])^(r1[12]&r2[35])^(r1[13]&r2[43])^(r1[14]&r2[51])^(r1[15]&r2[59]),\n");
	printf("		(r1[8]&r2[2])^(r1[9]&r2[10])^(r1[10]&r2[18])^(r1[11]&r2[26])^(r1[12]&r2[34])^(r1[13]&r2[42])^(r1[14]&r2[50])^(r1[15]&r2[58]),\n");
	printf("		(r1[8]&r2[1])^(r1[9]&r2[9])^(r1[10]&r2[17])^(r1[11]&r2[25])^(r1[12]&r2[33])^(r1[13]&r2[41])^(r1[14]&r2[49])^(r1[15]&r2[57]),\n");
	printf("		(r1[8]&r2[0])^(r1[9]&r2[8])^(r1[10]&r2[16])^(r1[11]&r2[24])^(r1[12]&r2[32])^(r1[13]&r2[40])^(r1[14]&r2[48])^(r1[15]&r2[56]),\n");
	printf("		(r1[0]&r2[7])^(r1[1]&r2[15])^(r1[2]&r2[23])^(r1[3]&r2[31])^(r1[4]&r2[39])^(r1[5]&r2[47])^(r1[6]&r2[55])^(r1[7]&r2[63]),\n");
	printf("		(r1[0]&r2[6])^(r1[1]&r2[14])^(r1[2]&r2[22])^(r1[3]&r2[30])^(r1[4]&r2[38])^(r1[5]&r2[46])^(r1[6]&r2[54])^(r1[7]&r2[62]),\n");
	printf("		(r1[0]&r2[5])^(r1[1]&r2[13])^(r1[2]&r2[21])^(r1[3]&r2[29])^(r1[4]&r2[37])^(r1[5]&r2[45])^(r1[6]&r2[53])^(r1[7]&r2[61]),\n");
	printf("		(r1[0]&r2[4])^(r1[1]&r2[12])^(r1[2]&r2[20])^(r1[3]&r2[28])^(r1[4]&r2[36])^(r1[5]&r2[44])^(r1[6]&r2[52])^(r1[7]&r2[60]),\n");
	printf("		(r1[0]&r2[3])^(r1[1]&r2[11])^(r1[2]&r2[19])^(r1[3]&r2[27])^(r1[4]&r2[35])^(r1[5]&r2[43])^(r1[6]&r2[51])^(r1[7]&r2[59]),\n");
	printf("		(r1[0]&r2[2])^(r1[1]&r2[10])^(r1[2]&r2[18])^(r1[3]&r2[26])^(r1[4]&r2[34])^(r1[5]&r2[42])^(r1[6]&r2[50])^(r1[7]&r2[58]),\n");
	printf("		(r1[0]&r2[1])^(r1[1]&r2[9])^(r1[2]&r2[17])^(r1[3]&r2[25])^(r1[4]&r2[33])^(r1[5]&r2[41])^(r1[6]&r2[49])^(r1[7]&r2[57]),\n");
	printf("		(r1[0]&r2[0])^(r1[1]&r2[8])^(r1[2]&r2[16])^(r1[3]&r2[24])^(r1[4]&r2[32])^(r1[5]&r2[40])^(r1[6]&r2[48])^(r1[7]&r2[56])};\n");

	printf("// bfp/bfpw\n");
	printf("	12'b101_?10_??????:	if (rv32|r_addw) begin\n");
	printf("					reg [15:0]mask;\n");
	printf("					reg [31:0]maskl;\n");
	printf("					reg [31:0]datal;\n");
	printf("					reg [31:0]res;\n");
	printf("					case (r2[27:24])\n");
	printf("					0: mask = 16'hffff;\n");
	for (i = 1; i < 16; i++)
	printf("					%d: mask = 16'h%x;\n", i, (unsigned)((1<<i)-1));
	printf("					endcase\n");
	printf("					case (r2[20:16])\n");
	printf("					0: begin maskl = {16'b0, mask}; datal = {16'bx, r2[15:0]}; end\n");
	for (i = 1; i < 16; i++)				
	printf("					%d: begin maskl = {%d'b0, mask, %d'b0}; datal = {%d'bx, r2[15:0], %d'bx}; end\n", i, 16-i, i, 16-i, i);
	for (i = 16; i < 32; i++)				
	printf("					%d: begin maskl = {mask[%d:0], %d'b0}; datal = {r2[%d:0], %d'bx}; end\n", i, 31-i, i, 31-i, i);
	printf("					endcase\n");
	printf("					res = (mask&datal)|(~mask&r1);\n");
	printf("					c_res = {{32{res[31]}}, res};\n");
	printf("				end else begin\n");
	printf("					reg [31:0]mask;\n");
	printf("					reg [63:0]maskl;\n");
	printf("					reg [63:0]datal;\n");
	printf("					reg [63:0]res;\n");
	printf("					reg [5:0]off;\n");
	printf("					reg [4:0]w;\n");
	printf("					w = (r2[63:62]==2'b10 ?r2[60:56]:r2[44:40]);\n");
	printf("					off = (r2[63:62]==2'b10 ?r2[53:48]:r2[37:32]);\n");
	printf("					case (w)\n");
	printf("					0: mask = 32'hffff_ffff;\n");
	for (i = 1; i < 32; i++)
	printf("					%d: mask = 32'h%x;\n", i, (unsigned)((1<<i)-1));
	printf("					endcase\n");
	printf("					case (off)\n");
	printf("					0: begin maskl = {32'b0, mask}; datal = {32'bx, r2[31:0]}; end\n");
	for (i = 1; i < 32; i++)				
	printf("					%d: begin maskl = {%d'b0, mask, %d'b0}; datal = {%d'bx, r2[31:0], %d'bx}; end\n", i, 32-i, i, 32-i, i);
	for (i = 32; i < 64; i++)				
	printf("					%d: begin maskl = {mask[%d:0], %d'b0}; datal = {r2[%d:0], %d'bx}; end\n", i, 63-i, i, 63-i, i);
	printf("					endcase\n");
	printf("					c_res = (mask&datal)|(~mask&r1);\n");
	printf("				end\n");


#endif

	printf("// aes64ks1i/aes64im\n");
	printf("	12'b110_?00_??????: c_res = r_immed[4]?aes64ks1i:aes64im;\n");
	printf("// brev8\n");
	printf("	12'b110_?01_??????: c_res = {\n");
	for (i = 56; i >= 0; i-=8) {
		for (j = 0; j < 8; j++) printf("r1[%d]%s", i+j, i==0&&j==7?"};\n":",");
	}
	printf("// zext.h / pack\n");
	printf("	12'b110_?10_??????: c_res = (r_addw|rv32?{{32{r2[15]}}, r2[15:0], r1[15:0]}:{r2[31:0], r1[31:0]});\n");
	printf("// packh\n");
	printf("	12'b110_?11_??????: c_res = {48'b0, r2[7:0], r1[7:0]};\n");

	printf("// aes32esi/aes64es  \n");
	printf("	12'b111_?00_??????: c_res = (rv32? {{32{aes32[7]}}, aes32}: aes64_e_end);\n");
	printf("// aes32esmi/aes64esm  \n");
	printf("	12'b111_?01_??????: c_res = (rv32? {{32{aes32[7]}}, aes32}: aes64_e_mid);\n");
	printf("// aes32dsi/aes64ds  \n");
	printf("	12'b111_?10_??????: c_res = (rv32? {{32{aes32[7]}}, aes32}: aes64_d_end);\n");
	printf("// aes32dsmi/aes64dsm  \n");
	printf("	12'b111_?11_??????: c_res = (rv32? {{32{aes32[7]}}, aes32}: aes64_d_mid);\n");
	printf("`endif\n");
	printf("	endcase \n");
}
