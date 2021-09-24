#ifndef CPU_JUDGE_TEST_IO_H
#define CPU_JUDGE_TEST_IO_H

// #define SIM                         // whether in simulation

#define BYTE_PORT_IN 0x30000        // port for reading bytes from input
#define BYTE_PORT_OUT 0x30000       // port for writing bytes to output

#define CPUCLK_PORT_IN 0x30004      // port that reads clocks passed since cpu starts

#define CPU_CLK_FREQ 70000000       // clock frequency of the cpu on FPGA

static inline unsigned char inb()
{
	return *((volatile unsigned char *)BYTE_PORT_IN);
}

static inline void outb(const unsigned char data)
{
	*((volatile unsigned char *)BYTE_PORT_OUT) = data;
}

static inline unsigned long inl()
{
    unsigned long ret = 0;
    unsigned char ch;
    int sign=0;
    while ((ch=inb())) if(ch!='\n'&&ch!=' '&&ch!='\t') break;
    do {
        if(ch=='-'&&!sign) sign=1;
        else if(ch<'0'||ch>'9') break;
        ret = ret * 10 + ch - '0';
    }while ((ch=inb()));
    return sign?-ret:ret;
}

static inline void getstr(char* data)
{
    char c;
    int i=0;
    while((c=inb())!='\n') data[i++]=c;
    data[i]='\0';
}

static inline unsigned int ord(char data)
{
    return (unsigned int)data;
}

static inline void outl(const int data)
{
    unsigned char str[12];
    int tmp = data;
    int i=0, s=0;
    if (tmp<0){
        s=1;
        tmp=-tmp;
    }
    do {
        str[i++] = tmp % 10 + '0';
    }
    while ((tmp/=10)>0);
    if(s) str[i++]='-';
    while (i--) {
        outb(str[i]);
    }
}

static inline void print(const char *str)
{
	for (; *str; str++)
		outb(*str);
}

static inline void println(const char *str)
{
	print(str);
	outb('\n');
}

static inline void outlln(const unsigned int data)
{
    outl(data);
	outb('\n');
}

static inline unsigned int clock()
{
    // return *((volatile unsigned int*)CPUCLK_PORT_IN);
    unsigned t1 = (unsigned)(*((volatile unsigned char *)(CPUCLK_PORT_IN)));
    unsigned t2 = (unsigned)(*((volatile unsigned char *)(CPUCLK_PORT_IN+1)));
    unsigned t3 = (unsigned)(*((volatile unsigned char *)(CPUCLK_PORT_IN+2)));
    unsigned t4 = (unsigned)(*((volatile unsigned char *)(CPUCLK_PORT_IN+3)));
    return (t4<<24) | (t3<<16) | (t2<<8) | (t1);
}

#ifdef SIM
#define sleep(x) 
#else
static inline void sleep(const unsigned int milli_sec)
{
    unsigned int s = 0, d = milli_sec * (CPU_CLK_FREQ / 1000);
    s = clock();
    while (clock() - s < d);
}
#endif

#endif