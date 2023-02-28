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
	int n, i,j,k,t;

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

	if (argc < 2) {
		t = 0;
	} else {
		t = strtol((const char *)argv[1], 0, 0);
	}
	switch (t) {
	case 0: // single<-double
		for (i = 0; i < 23; i++) 
        	printf("	11'h%x:	t = {%d'b0, 1'b1, fr1[51:%d], |fr1[%d:0]};\n", 0x380-23+i, 23-i, 51-i, 50-i);
		break;
	case 1: // half<-double
		for (i = 0; i < 10; i++) 
        	printf("	11'h%x:	t = {%d'b0, 1'b1, fr1[51:%d], |fr1[%d:0]};\n", 0x380-10+i, 10-i, 51-i, 50-i);
		break;
	case 2: // half<-single
		for (i = 0; i < 10; i++) 
        	printf("	11'h%x:	t = {%d'b0, 1'b1, fr1[51:%d], |fr1[%d:0]};\n", 0x80-10+i, 10-i, 23-i, 22-i);
		break;
	}
}
