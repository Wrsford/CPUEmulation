//
//  minimal_cpu.h
//  CPUEmulation
//
//  Created by Will Stafford on 8/24/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

#ifndef minimal_cpu_h
#define minimal_cpu_h

#include <stdio.h>
#include "minimal_ram.h"

typedef struct {
    long program_counter;
    long backup_reg;
    long data_reg;
} min_cpu_callstack_state;

typedef struct {
    long code;
    void* callback;
} min_cpu_interrupt_handler;

#define MIN_CPU_STACK_MAX_SIZE 4096
#define MIN_CPU_CALLSTACK_MAX_SIZE 2048
#define MAX_INTERRUPT_COUNT 50
typedef struct {
    long program_counter;
    long data_reg;
    long backup_reg;
    
    long break_flag;
    
    minimal_ram_context ram;
    
    min_cpu_callstack_state callstack[MIN_CPU_CALLSTACK_MAX_SIZE];
    long callstack_size;
    
    long stack[MIN_CPU_STACK_MAX_SIZE];
    long stack_size;
    
    min_cpu_interrupt_handler interrupt_handlers[MAX_INTERRUPT_COUNT];
    long interrupt_count;
} minimal_cpu_context;

extern void min_cpu_interrupt_base_handler(minimal_cpu_context* cpu);

typedef typeof(min_cpu_interrupt_base_handler) min_cpu_interrupt_handler_callback;


// Public Functions
extern void min_cpu_init(minimal_cpu_context* cpu);
extern void min_cpu_exec_next_instr(minimal_cpu_context* cpu);
extern void min_cpu_load_binary(minimal_cpu_context* cpu, long address, long* binary, long bin_size);
extern void min_cpu_add_interrupt_handler(minimal_cpu_context* cpu, min_cpu_interrupt_handler handler);

// Op declarations
extern void min_cpu_push(minimal_cpu_context* cpu, long val);
extern long min_cpu_pop(minimal_cpu_context* cpu);
extern void min_cpu_sub(minimal_cpu_context* cpu);
extern void min_cpu_jlq(minimal_cpu_context* cpu);
extern void min_cpu_interrupt(minimal_cpu_context* cpu);
extern void min_cpu_call(minimal_cpu_context* cpu);
extern void min_cpu_ret(minimal_cpu_context* cpu);
extern void min_cpu_break(minimal_cpu_context* cpu);

// Declare interrupt setup
extern void min_cpu_setup_interrupts(minimal_cpu_context* cpu);
// Declare interrupt handlers
extern void min_cpu_interrupt_push_pc(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_pop_ram(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_push_ram(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_pop_data(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_push_data(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_pop_backup(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_push_backup(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_print_char(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_print_space(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_print_newline(minimal_cpu_context* cpu);
extern void min_cpu_interrupt_debugger(minimal_cpu_context* cpu);
#endif /* minimal_cpu_h */
