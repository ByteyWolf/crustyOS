#include "memman.h"
#include <stdint.h>

struct memory_segment {
    uintptr_t base;
    uintptr_t length;
    uint8_t type;
    struct memory_segment* next_seg;
    struct memory_segment* prev_seg;
};

#define MEMORY_TYPE_FREE 0
#define MEMORY_TYPE_CLAIMED 1
#define MEMORY_TYPE_MEMMAP 2

struct memory_segment* memory_root;

uint8_t init_memory() {
    return 0;
}
