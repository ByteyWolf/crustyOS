void kmain(void);

void _start(void) {
    kmain();
}

#include <stdint.h>

volatile char* video = (volatile char*)0xB8000;
static uint32_t pos = 0;

void kputc(char c, char attr) {
    if (c == '\n') {
        pos += 160 - (pos % 160);
        return;
    }
    video[pos++] = c;
    video[pos++] = attr;
}

void kputs(const char* s) {
    while (*s) kputc(*s++, 0x07);
}
void kputs_attr(const char* s, char attr) {
    while (*s) kputc(*s++, attr);
}

void print_hex8(uint8_t val) {
    uint8_t hi = (val >> 4) & 0xF;
    uint8_t lo = val & 0xF;
    kputc(hi < 10 ? '0' + hi : 'A' + (hi - 10), 0x07);
    kputc(lo < 10 ? '0' + lo : 'A' + (lo - 10), 0x07);
}

void kmain(void) {
    char continueexec = 1;
    if (*(volatile uint16_t*)0x9016 > 0xDEA9) {
        kputs_attr("Bootloader reported memory map failure.\nCrustyOS cannot continue.\n", 0x0C);
        kputs_attr("Error code: ", 0x0C);
        print_hex8((*((volatile uint8_t*)0x9016)));
        kputs("\n");
        continueexec = 0;
    }
    kputs("\nDUMP OF 0x9000:\n");
    volatile uint8_t* ptr = (volatile uint8_t*)0x9000;
    for (int i = 0; i < 128; i++) {
        print_hex8(ptr[i]);
        kputc(' ', 0x07);
        if ((i & 0xF) == 0xF) kputs("\n");
    }
    if (!continueexec) {
        while (1);
    }
    while (1);
}
