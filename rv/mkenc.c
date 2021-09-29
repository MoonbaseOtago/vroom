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
	int i,j,k,t;

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

	for (i = 0; i < B; i++) {
		int count = 1+i;
		printf("		if (ADDR==%d) begin\n", i);
		printf("			 always @(*) begin\n");
		printf("				c_valid_out = 1;\n");
		printf("				sel=%d'b", B);
		for (k=0;k<B;k++) printf("x");
		printf(";\n");
		printf("				casez (valid) // synthesis full_case parallel_case\n");
		for (j = i; j < B; j++) {
			int first = 1;
			for (k=1; k < t ; k++) {
				if (popcount(k) == count && ffs(k) == j) {
					int start, l;
					if (!first) printf(",\n");
					first = 0;
					printf("				%d'b", B);
					start = 1;
					for (l = B-1; l >= 0; l--) {
						if (l != (B-1) && (l&3)==3) printf("_");
						if (k&(1<<l)) {
							printf("1");
							start=0;
						} else
						if (start) {
							printf("?");
						} else {
							printf("0");
						}
					}
				}
			}
			printf(": sel = %d;\n", 1<<j);
		}
		printf("				default: c_valid_out = 0;\n");
		printf("				endcase\n");
		printf("			end\n");
		printf("		end else\n");
	}
	printf("		begin end\n");
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
