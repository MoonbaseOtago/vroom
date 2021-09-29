#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

int
main(int argc, char **argv)
{
	FILE *f;
	unsigned char d[16];
	int a;
	int width;

	if (argc < 3) {
		fprintf(stderr, "missing input file\n");
		exit(99);
	}
	width = atoi(argv[3]);
	assert (width==64 || width==128);
	f = fopen(argv[1], "r");
	if (!f) {
		fprintf(stderr, "can't open %s\n", argv[1]);
		exit(99);
	}
	printf("module %s(input [8:0]addr, output [%d:0]data);\n",argv[2], width-1);
	printf("	reg [%d:0]rdata;assign data=rdata;\n", width-1);
	printf("	always @(*)\n");
	printf("	case (addr) // synthesis full_case parallel_case\n");
	for (a = 0;;a++) {
		int v = fread(d, 1, width/8, f);
		if (v <= 0)
			break;
		if (width == 128) {
			printf("	9'h%x: rdata = 128'h%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x;\n",
				a,
				d[15], d[14], d[13], d[12],
				d[11], d[10], d[9], d[8],
				d[7], d[6], d[5], d[4],
				d[3], d[2], d[1], d[0]);
		} else
		if (width == 64) {
			printf("	9'h%x: rdata = 64'h%02x%02x%02x%02x%02x%02x%02x%02x;\n",
				a,
				d[7], d[6], d[5], d[4],
				d[3], d[2], d[1], d[0]);
		}
	}
	printf("\n	endcase\n");
	printf("endmodule\n");
	return 0;
}
