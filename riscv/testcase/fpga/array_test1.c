#include "io.h"
//input: 1 2 3 4

int a[4];
int main()
{
    int b[4];
	int i;
    for (i = 0; i < 4; i++)
	{
		a[i] = 0;
		b[i] = inl();
	}
	for (i = 0; i < 4; i++)
	{
		outl(a[i]);
	}
	println("");
	int *p;
	p=b;
	for (i = 0; i < 4; i++)
	{
		outl(p[i]);
	}
}
