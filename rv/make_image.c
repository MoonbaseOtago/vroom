#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>


int
main(int argc, const char **argv)
{
	FILE *out = 0;
	const char *o=0;
	int i, j;
	unsigned long addr=0;
	u_int64_t header[256/8];
	int off=0;

	memset(header, 0, 256);
	for (i = 1; i < argc; i++)
	if (strcmp(argv[i], "-o") == 0 && i < (argc-1)) {
		o = argv[i+1];
		out = fopen(argv[i+1], "w");
		break;
	}
	if (!out) {
		if (o) {
			fprintf(stderr, "Can't create '%s'\n", o);
		} else {
			fprintf(stderr, "No output file specified\n");
		}
		return 1;
	}
	for (i = 1; i < argc; i++)
	if (strcmp(argv[i], "-o") == 0 && i < (argc-1)) {
		i++;
	} else
	if (strcmp(argv[i], "-f") == 0 && i < (argc-1)) {
		i++;
	} else
	if (strcmp(argv[i], "-a") == 0 && i < (argc-1)) {
		i++;
		addr = strtoul(argv[i], 0, 0);
	} else 
	if (argv[i][0] != '-') {
		FILE *in = fopen(argv[i], "r");
		struct stat s;
		char b[1024];
		if (!in) {
			fprintf(stderr, "Can't open '%s'\n", argv[i]);
			return 1;
		}
		fstat(fileno(in), &s);
		header[off++] = addr;
		header[off++] = (s.st_size+255)/256;
		fseek(out, addr+256, SEEK_SET);
		for (;;) {
			j = fread(b, 1, sizeof(b), in);
			if (j <= 0)
				break;
			if (j < sizeof(b)) {
				int k = j;
				j += 255;
				j /= 256;
				j *= 256;
				if (j != k)
					memset(&b[k], 0, j-k);
			}
			fwrite(b, 1, j, out);
		}
		fclose(in);
	}
	for (i = 1; i < argc; i++)
	if (strcmp(argv[i], "-f") == 0 && i < (argc-1)) {
		struct stat s;
		char b[1024];
		FILE *in = fopen(argv[i+1], "r");
		long len, offset = ftell(out); 
		if (!in) {
			fprintf(stderr, "Can't open '%s'\n", argv[i]);
			return 1;
		}
		i++;
		if (offset&0xff) {
			offset += 256-(offset&0xff);
			fseek(out, SEEK_SET, offset);
		}
		len = 0;
		for (;;) {
			int j = fread(b, 1, sizeof(b), in);
			if (j <= 0)
				break;
			if (j < sizeof(b)) {
				int k = j;
				j += 255;
				j /= 256;
				j *= 256;
				if (j != k)
					memset(&b[k], 0, j-k);
			}
			fwrite(b, 1, j, out);
			len += j;
		}
		fclose(in);
		header[off++] = 0;
		header[off++] = 0;		// end marker
		header[off++] = offset;		//  size of diak image
		header[off++] = len;		//
		break;
	} else
	if (argv[i][0] == '-') {
		i++;
	}
	fseek(out, 0L, SEEK_SET);
	fwrite(header, 1, 256, out);
	fclose(out);
	
	return 0;
}
