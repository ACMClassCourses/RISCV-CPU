#include "io.h"
// san check: if your predictor && icache work, it should be 1.5s @ 100Mhz
unsigned n, sum;
void work() {
	for (int i = 1; i <= 5 * n; i++) {
		sum += i * 998244353;
	}
}
int main() {
    n = 50;
	work();
	n = 10000000;
	work();
	outlln(sum);
}