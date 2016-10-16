#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int
main (int argc, char *argv[])
{
	int c, opt = 'x';
	unsigned int exponent, mantissa;
	union {
		long x;
		float f;
	} u;

	while ((c = getopt (argc, argv, "xd")) != -1) switch (c) {
		case 'x':
		case 'd':
			opt = c;
			break;
		case '?':
			default:
			opt = 'x';
	}

	(void)scanf((opt == 'x') ? "%x %x" : "%d %d", &exponent, &mantissa);
	u.x = (exponent << 24) | (mantissa & 0xffffff);
	(void)printf("%f\n", u.f);
}
