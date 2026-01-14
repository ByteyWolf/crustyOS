#include <stdint.h>

struct memory_map_entry {
    uint64_t base;
    uint64_t length;
    uint32_t type;
    uint32_t acpi_ext_attrs;
} __attribute__((packed));

#define MEMORY_MAP_TYPE_AVAILABLE 1
#define MEMORY_MAP_TYPE_RESERVED 2
#define MEMORY_MAP_TYPE_ACPI_RECLAIMABLE 3
#define MEMORY_MAP_TYPE_ACPI_NVS 4
#define MEMORY_MAP_TYPE_BAD_MEMORY 5