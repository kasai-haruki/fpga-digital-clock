#include <stdio.h>

int main(void)
{
	int val, count;

	count = 0;
	FILE *fin = fopen("weekday.txt", "r");
	FILE *fout = fopen("weekday.coe", "w");

	fprintf(fout, "memory_initialization_radix=16;\n");
	fprintf(fout, "memory_initialization_vector=\n");

	while (fscanf_s(fin, "%d", &val) == 1) {
		fprintf(fout, "%d", val);
		count++;
		if (count < 1212) {
			fprintf(fout, ",");
		}
		if (count % 16 == 0) fprintf(fout, "\n");
	}

	fprintf(fout, ";\n");

	fclose(fin);
	fclose(fout);

	return 0;
}