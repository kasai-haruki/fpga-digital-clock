#include <stdio.h>

int main(void) {
    int h, m, s, hh, mm, ss;

    FILE* fp = fopen("ref.hex", "w");
    if (!fp) return 1;

    for ( h = 0; h < 24; h++) {
        for ( m = 0; m < 60; m++) {
            for ( s = 0; s < 60; s++) {
                 hh = ((h / 10) << 4) | (h % 10);
                 mm = ((m / 10) << 4) | (m % 10);
                 ss = ((s / 10) << 4) | (s % 10);

                fprintf(fp, "%02X%02X%02X\n", hh, mm, ss);
            }
        }
    }

    fclose(fp);
    return 0;
}
