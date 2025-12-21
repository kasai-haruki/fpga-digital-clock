#include <stdio.h>

int zeller(int, int, int);
int isleap(int);
int daysofmonth(int, int);

int main(void) {
    int year, month, w;

    FILE* fp = fopen("weekday.txt", "w");

    for (year = 2000; year <= 2100; year++) {
        for (month = 1; month <= 12; month++) {
            w = zeller(year, month, 1); 
            fprintf(fp, "%X\n", w); 
        }
    }

    fclose(fp);
    return 0;
}

int zeller(int y, int m, int d) {
    int i, j, goukei, w;
    goukei = 0;
    for (i = 1; i < y; i++) {
        for (j = 1;j <= 12;j++) {
            goukei += daysofmonth(i, j);
        }
    }
    for (j = 1; j < m; j++) {
        goukei += daysofmonth(y, j);
    }
    w = (goukei + d) % 7;
    
    return w;
}

int daysofmonth(int year, int month)
{
    int day;

    switch(month){
        case 1:
        case 3:
        case 5:
        case 7:
        case 8:
        case 10:
        case 12: day = 31;
            break;
        case 4:
        case 6:
        case 9:
        case 11: day = 30;
            break;
        case 2: day = 28 + isleap(year);
            break;
    }

    return day;
}

int isleap(int year)
{
    return (year % 4 == 0 && year % 100 != 0 || year % 400 == 0);
}