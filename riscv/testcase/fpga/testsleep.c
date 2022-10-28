#include "io.h"
int main()
{
    int a = clock();
    sleep(10000); // sleep for 10s
    int b = clock();
    outlln(b-a);
    outlln((b-a)/CPU_CLK_FREQ); // should be 10
    return 0; // check actual running time
}