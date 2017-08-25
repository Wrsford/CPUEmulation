//
//  minimal_ram.h
//  CPUEmulation
//
//  Created by Will Stafford on 8/24/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

#ifndef minimal_ram_h
#define minimal_ram_h

#include <stdio.h>
#define MIN_RAM_REGION_SIZE 2048
typedef struct {
    long virtual_address;
    long size;
    long values[MIN_RAM_REGION_SIZE];
} min_ram_region;

// Not dealing with memory management for now
#define MIN_RAM_MAX_REGION_COUNT 30
typedef struct {
    min_ram_region regions[MIN_RAM_MAX_REGION_COUNT];
    long region_count;
} minimal_ram_context;


extern void minimal_ram_init(minimal_ram_context* ram);
extern void minimal_ram_teardown(minimal_ram_context* ram);

extern long min_ram_get_byte(minimal_ram_context* ram, long address);
extern void min_ram_set_byte(minimal_ram_context* ram, long address, long val);

#endif /* minimal_ram_h */
