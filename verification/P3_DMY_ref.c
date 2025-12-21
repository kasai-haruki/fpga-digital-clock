#include <stdio.h>

int main(void) {
    int year, month, day, yy, mm, dd, max_day, week_day;
    week_day = 6;
    FILE* fp = fopen("ref.hex", "w");
    if (!fp) return 1;

    for (year = 0; year <= 100; year++) {
        for (month = 1; month < 13; month++) {
            max_day = (month == 4 || month == 6 || month == 9 || month == 11) ? 30 :
                (month == 2) ? ((year % 4 == 0) ? ((year % 100 == 0) ? ((year == 0) ? 29 : 28) : 29) : 28) :
                31;
            for (day = 1; day < max_day +1; day++) {
                yy = ((year / 100) << 8) | (((year % 100) / 10) << 4) | (year % 10);
                mm = ((month / 10) << 4) | (month % 10);
                dd = ((day / 10) << 4) | (day % 10);
                if (week_day == 7) {
                    week_day = 0;
                }
                fprintf(fp, "%01X%03X%02X%02X\n", week_day, yy, mm, dd);
                week_day = week_day + 1;
            }
        }
    }

    fclose(fp);
    return 0;
}
