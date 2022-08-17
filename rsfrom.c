// RSF to EEPROM BIN

#include <stdio.h>
#include <memory.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
	FILE *fp;
	char outb[65535];
	char title[4][15];
	char author[4][8];
	char buffer;
	int i = 0;
	int j;
	int k;
	int l;
	int m = 0;
	int cur = 0;
	int prev;
	short swap;
	short size[4] = {0, 0, 0, 0};
	if (argc < 2 || argc > 5) {
		printf("incorrect parameter\nusage: rsfrom [file1] [file2] [file3] [file4]");
		return 1;
	}
	if (argc > 3) {
		printf("more than 2 files selected - header will be incorect\n");
	}
	k = argc - 1;
	for (j = 0; j < k; j++) {
		fp = fopen(argv[j+1], "rb");
		fseek(fp, 20, SEEK_SET); // skip header
		for (l = 0; l < 3; m++) { // read title and author
			fread(&buffer, sizeof(char), 1, fp);
			if (l == 0 && m < 15) {
				title[j][m] = buffer;
			}
			if (l == 1 && m - cur < 8) {
				author[j][m - cur] = buffer;
			}
			if (buffer == 0) {
				cur = m;
				l++;
			}
		}
		while (fread(&buffer, sizeof(char), 1, fp) == 1) { // read data
			outb[i] = buffer;
			i++;
    	}
		fclose(fp);
		outb[i] = 0xfe; // end flag 
		i = i + 1;
		if (j == 0) { // uncompleted ...
			size[0] = 0x64;
			prev = i + 0x64;
		} else {
			size[j] = prev;
			prev = i;
		}
	}
	fp = fopen("64krom", "wb");
		for (j = 0; j < 4; j++) {
			swap = size[j] << 8;
			swap |= size[j] >> 8;
    		fwrite(&swap, sizeof(short), 1, fp);
		}
		for(j = 0; j < 4; j++) {
			for (k = 0; k < 15; k++) {
				fwrite(&title[j][k], sizeof(char), 1, fp);
			}
			for (k = 0; k < 8; k++) {
				fwrite(&author[j][k], sizeof(char), 1, fp);
			}
		}
    	fwrite(outb, sizeof(char), i, fp);
    	fclose(fp);
	return 0;
}
