void kmain(void);

void _start(void) {
    kmain();
}

#include <stdint.h>
#include "mem.h"

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
    kputs("Welcome to ");
    kputs_attr("CrustyOS", 0x0A);
    kputs("!\n");
    uint16_t resultsig = *(volatile uint16_t*)0x8996;
    if (resultsig > 0xDEA9) {
        kputs_attr("Bootloader reported memory map failure.\nCrustyOS cannot continue.\n", 0x0C);
        kputs_attr("Error code: ", 0x0C);
        print_hex8((*((volatile uint8_t*)0x8996)));
        kputs("\n");

        kputs("\nDUMP OF 0x9000:\n");
        volatile uint8_t* ptr = (volatile uint8_t*)0x9000;
        for (int i = 0; i < 128; i++) {
            print_hex8(ptr[i]);
            kputc(' ', 0x07);
            if ((i & 0xF) == 0xF) kputs("\n");
        }
        while (1);
    }
    
    kputs("Memory map:\n");
    volatile struct memory_map_entry* entry = (volatile struct memory_map_entry*)0x9000;
    while (entry->type != 0) {
        kputs(" Base: 0x");
        for (int i = 7; i >= 0; i--) {
            print_hex8((entry->base >> (i * 8)) & 0xFF);
        }
        kputs(" Length: 0x");
        for (int i = 7; i >= 0; i--) {
            print_hex8((entry->length >> (i * 8)) & 0xFF);
        }
        kputs(" Type: ");
        print_hex8((uint8_t)(entry->type));
        kputs("\n");
        entry = (volatile struct memory_map_entry*)((uintptr_t)entry + sizeof(struct memory_map_entry) + 4);
    }
    while (1);
}
