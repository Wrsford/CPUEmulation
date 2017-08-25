//
//  minimal_ram.c
//  CPUEmulation
//
//  Created by Will Stafford on 8/24/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

#include "minimal_ram.h"

struct minimal_ram_context {
    min_ram_region regions[MIN_RAM_MAX_REGION_COUNT];
    long region_count;
};

// internal defs
extern min_ram_region* get_region_for_address(minimal_ram_context* ram, long address);
extern long has_region_for_address(minimal_ram_context* ram, long address);
extern void add_region_for_address(minimal_ram_context* ram, long address);
extern long get_region_byte_for_virtual_address(min_ram_region* region, long virtual_address);
extern void set_region_byte_for_virtual_address(min_ram_region* region, long virtual_address, long value);

// Public

/// Constructor
void minimal_ram_init(minimal_ram_context* ram)
{
    ram->region_count = 0;
}

/// Dealloc
void minimal_ram_teardown(minimal_ram_context* ram)
{
    
}


/// Gets a byte at the address
long min_ram_get_byte(minimal_ram_context* ram, long address)
{
    min_ram_region* region = get_region_for_address(ram, address);
    
    if (region == NULL)
    {
        // Region doesn't exist
        // I believe the Swift version returns 0 in this case
        return 0;
    }
    else {
        return get_region_byte_for_virtual_address(region, address);
    }
    
}


/// Sets a byte at the address
void min_ram_set_byte(minimal_ram_context* ram, long address, long val)
{
    // Check if the region exists
    if (has_region_for_address(ram, address) == 0)
    {
        // Doesn't exist, add it
        add_region_for_address(ram, address);
    }
    
    // Get the region
    min_ram_region* region = get_region_for_address(ram, address);
    
    // Set the value
    set_region_byte_for_virtual_address(region, address, val);
}


// Private/internal

/// Gets the owning region for the virtual address
min_ram_region* get_region_for_address(minimal_ram_context* ram, long address)
{
    min_ram_region* region = NULL;
    long i;
    for (i = 0; i < ram->region_count; i++)
    {
        // Check the lower boundary
        if (ram->regions[i].virtual_address <= address)
        {
            // Check upper boundary
            if (ram->regions[i].virtual_address + ram->regions[i].size > address)
            {
                // Found a match
                region = &ram->regions[i];
                // Break out of loop & return
                break;
            }
        }
    }
    
    // NULL if it doesn't exist
    return region;
}

/// Checks if a region exists
long has_region_for_address(minimal_ram_context* ram, long address) {
    min_ram_region* region = get_region_for_address(ram, address);
    if (region == NULL)
    {
        // Doesn't exist
        return 0;
    }
    else {
        // It exists
        return 1;
    }
}

/// Adds a region for the address (auto-aligned)
void add_region_for_address(minimal_ram_context* ram, long address)
{
    min_ram_region newRegion;
    
    // Set the size
    newRegion.size = MIN_RAM_REGION_SIZE;
    
    // Requested address offset from an aligned address
    long virtualBaseOffset = address % newRegion.size;
    // The aligned base address
    long alignedBaseAddress = (address - virtualBaseOffset);
    
    // check calculated address
    if (alignedBaseAddress % newRegion.size != 0)
    {
        // Bad calculation
        printf("Bad alignment calculation!");
        // Crash the program so we know something is wrong (tries to get ram address -1)
        newRegion.virtual_address = ((int*)NULL)[-1];
    }
    
    // Set the aligned address
    newRegion.virtual_address = alignedBaseAddress;
    
    // Add it
    ram->regions[ram->region_count++] = newRegion;
}

/// Calculates the actual address for the region and returns the value
long get_region_byte_for_virtual_address(min_ram_region* region, long virtual_address)
{
    // Calc relative address
    long regionAddr = virtual_address - region->virtual_address;
    // Return byte
    return region->values[regionAddr];
}

/// Calculates the actual address for the region and sets the value
void set_region_byte_for_virtual_address(min_ram_region* region, long virtual_address, long value)
{
    // Calc relative address
    long regionAddr = virtual_address - region->virtual_address;
    // Set byte
    region->values[regionAddr] = value;
}
