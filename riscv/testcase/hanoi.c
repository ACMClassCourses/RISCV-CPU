#include "io.h"
int cd(int d, char* a, char* b, char* c, int sum) {
    sleep(5); // to prevent UART buffer from overflowing
    if (d == 1) {
        print("move ");
        print(a);
        print(" --> ");
        println(c);
        sum++;
    } else {
        sum = cd(d - 1, a, c, b, sum);
        print("move ");
        print(a);
        print(" --> ");
        println(c);
        sum = cd(d - 1, b, a, c, sum);
        sum++;
    }
    return sum;
}

int main() {
    char a[5] = "A";
	char b[5] = "B";
	char c[5] = "C";
    int d = inl();
    int sum = cd(d, a, b, c, 0);
    outlln(sum);
    return 0;
}

