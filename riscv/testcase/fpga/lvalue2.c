#include "io.h"
int a[4];
int main()
{
    int b[4];
    b[2]=2;
    int *p;
	p=b;
    outlln(p[2]);
}
