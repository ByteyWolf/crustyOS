// test hello world!
typedef unsigned int uint32_t;

void kputs(const char* s);
void kputc(char c);

void kmain(void) {
    kputs("Hello from 0x10000! We are in 32-bit :)");
    while (1);  // halt
}

void kputc(char c) {
    volatile char* video = (volatile char*)0xB8000;
    static uint32_t pos = 0;
    video[pos++] = c;
    video[pos++] = 0x07;  // light grey on black
}

void kputs(const char* s) {
    while (*s) kputc(*s++);
}

