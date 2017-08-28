//
//  minimal_cpu.c
//  CPUEmulation
//
//  Created by Will Stafford on 8/24/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

#include "minimal_cpu.h"



// Public

/// Constructor
void min_cpu_init(minimal_cpu_context* cpu)
{
    // Set defaults
    
    // PC = 0
    cpu->program_counter = 0x0;
    
    // Regs = 0
    cpu->data_reg = 0x0;
    cpu->backup_reg = 0x0;
    
    // Break flag = 0
    cpu->break_flag = 0x0;
    
    // Init ram
    minimal_ram_init(&cpu->ram);
    
    // callstack size = 0
    cpu->callstack_size = 0x0;
    
    // Stack size = 0
    cpu->stack_size = 0x0;
    
    // interrupt count = 0
    cpu->interrupt_count = 0;
    
    min_cpu_setup_interrupts(cpu);
    
}

/// Executes next instruction
void min_cpu_exec_next_instr(minimal_cpu_context* cpu)
{
    long pcBackup = cpu->program_counter;
    long instructionSize = 0x1;
    long nextInstr = min_ram_get_byte(&cpu->ram, cpu->program_counter);
    
    switch (nextInstr) {
        case 0x1:
            min_cpu_sub(cpu);
            break;
        case 0x2:
            min_cpu_jlq(cpu);
            break;
        case 0x3:
            instructionSize += 1; // Push instructions are one byte larger
            min_cpu_push(cpu, min_ram_get_byte(&cpu->ram, cpu->program_counter + 1));
            break;
        case 0x4:
            min_cpu_pop(cpu); // Ignores result in this case
            break;
        case 0x5:
            min_cpu_interrupt(cpu);
            break;
        case 0x6:
            min_cpu_call(cpu);
            break;
        case 0x7:
            min_cpu_ret(cpu);
            break;
        default:
            min_cpu_break(cpu);
            break;
    }
    
    if (cpu->program_counter == pcBackup)
    {
        // PC was not changed by an instruction, increment it
        cpu->program_counter += instructionSize;
    }
}

/// Sets up the base interrupts
void min_cpu_setup_interrupts(minimal_cpu_context* cpu) {
    min_cpu_interrupt_handler push_pc;
    push_pc.callback = &min_cpu_interrupt_push_pc;
    push_pc.code = 0x0;
    min_cpu_add_interrupt_handler(cpu, push_pc);
    
    min_cpu_interrupt_handler pop_ram;
    pop_ram.callback = &min_cpu_interrupt_pop_ram;
    pop_ram.code = 0x1;
    min_cpu_add_interrupt_handler(cpu, pop_ram);
    
    min_cpu_interrupt_handler push_ram;
    push_ram.callback = &min_cpu_interrupt_push_ram;
    push_ram.code = 0x2;
    min_cpu_add_interrupt_handler(cpu, push_ram);
    
    min_cpu_interrupt_handler pop_data;
    pop_data.callback = &min_cpu_interrupt_pop_data;
    pop_data.code = 0x3;
    min_cpu_add_interrupt_handler(cpu, pop_data);
    
    min_cpu_interrupt_handler push_data;
    push_data.callback = &min_cpu_interrupt_push_data;
    push_data.code = 0x4;
    min_cpu_add_interrupt_handler(cpu, push_data);
    
    min_cpu_interrupt_handler pop_bkup;
    pop_bkup.callback = &min_cpu_interrupt_pop_backup;
    pop_bkup.code = 0x5;
    min_cpu_add_interrupt_handler(cpu, pop_bkup);
    
    min_cpu_interrupt_handler push_bkup;
    push_bkup.callback = &min_cpu_interrupt_push_backup;
    push_bkup.code = 0x6;
    min_cpu_add_interrupt_handler(cpu, push_bkup);
    
    min_cpu_interrupt_handler prt_char;
    prt_char.callback = &min_cpu_interrupt_print_char;
    prt_char.code = 0x7;
    min_cpu_add_interrupt_handler(cpu, prt_char);
    
    min_cpu_interrupt_handler prt_space;
    prt_space.callback = &min_cpu_interrupt_print_space;
    prt_space.code = 0x8;
    min_cpu_add_interrupt_handler(cpu, prt_space);
    
    min_cpu_interrupt_handler prt_newline;
    prt_newline.callback = &min_cpu_interrupt_print_newline;
    prt_newline.code = 0x9;
    min_cpu_add_interrupt_handler(cpu, prt_newline);
    
    min_cpu_interrupt_handler dbg_int;
    dbg_int.callback = &min_cpu_interrupt_debugger;
    dbg_int.code = 0xdeadface;
    min_cpu_add_interrupt_handler(cpu, dbg_int);
    
}

/// Loads a binary @ an address
void min_cpu_load_binary(minimal_cpu_context* cpu, long address, long* binary, long bin_size)
{
    long i;
    for (i = 0; i < bin_size; i++)
    {
        min_ram_set_byte(&cpu->ram, address + i, binary[i]);
    }
}

/// Sets up the interrupt function sig
void min_cpu_interrupt_base_handler(minimal_cpu_context* cpu)
{
    // Leave empty
}

void min_cpu_add_interrupt_handler(minimal_cpu_context* cpu, min_cpu_interrupt_handler handler)
{
    cpu->interrupt_handlers[cpu->interrupt_count++] = handler;
}

// Ops


// sub
void min_cpu_sub(minimal_cpu_context* cpu)
{
    long rhs = min_cpu_pop(cpu);
    long lhs = min_cpu_pop(cpu);
    
    min_cpu_push(cpu, lhs - rhs);
}

// jlq
void min_cpu_jlq(minimal_cpu_context* cpu)
{
    long rhs = min_cpu_pop(cpu);
    long targetAddr = min_cpu_pop(cpu);
    long lhs = min_cpu_pop(cpu);
    
    // Compare & jump if needed
    if (lhs <= rhs)
    {
        cpu->program_counter = targetAddr;
    }
}

// push
void min_cpu_push(minimal_cpu_context* cpu, long val)
{
    // Push val to stack
    cpu->stack[cpu->stack_size++] = val;
}

// pop
long min_cpu_pop(minimal_cpu_context* cpu)
{
    // Pop stack and return the value.
    long val = cpu->stack[--cpu->stack_size];
    cpu->stack[cpu->stack_size] = 0;
    return val;
}

// int
void min_cpu_interrupt(minimal_cpu_context* cpu)
{
    // Get interrupt code
    long interruptCode = min_cpu_pop(cpu);
    min_cpu_interrupt_handler* intHandler = NULL;
    
    long i;
    for (i = 0; i < cpu->interrupt_count; i++)
    {
        min_cpu_interrupt_handler handler = cpu->interrupt_handlers[i];
        if (handler.code == interruptCode)
        {
            // Matched
            intHandler = &handler;
            // Break out of loop
            break;
        }
    }
    
    // Check for null handler (not found)
    if (intHandler == NULL)
    {
        // Bad/unsupported interrupt
        printf("Bad interrupt requested. Code: %ld\n", interruptCode);
        min_cpu_break(cpu);
    }
    else
    {
        //printf("Interrupt requested. Code: %ld\n", interruptCode);
        // Call the interrupt
        ((min_cpu_interrupt_handler_callback*)intHandler->callback)(cpu);
    }
}

// call
void min_cpu_call(minimal_cpu_context* cpu)
{
    long targetAddress = min_cpu_pop(cpu);
    // Create backup
    min_cpu_callstack_state csBackup;
    csBackup.program_counter = cpu->program_counter + 1;
    csBackup.data_reg = cpu->data_reg;
    csBackup.backup_reg = cpu->backup_reg;
    
    // Push backup state
    cpu->callstack[cpu->callstack_size++] = csBackup;
    
    // Clear data & backup regs
    cpu->data_reg = 0;
    cpu->backup_reg = 0;
    cpu->program_counter = targetAddress;
}

// ret
void min_cpu_ret(minimal_cpu_context* cpu)
{
    // Pop backup state
    min_cpu_callstack_state backupState = cpu->callstack[--cpu->callstack_size];
    
    // Restore state
    cpu->program_counter = backupState.program_counter;
    cpu->data_reg = backupState.data_reg;
    cpu->backup_reg = backupState.backup_reg;
}

// brk
void min_cpu_break(minimal_cpu_context* cpu)
{
    // Set break flag
    cpu->break_flag = 1;
}

// INTERRUPTS

// 0
void min_cpu_interrupt_push_pc(minimal_cpu_context* cpu)
{
    min_cpu_push(cpu, cpu->program_counter);
}

// 1
void min_cpu_interrupt_pop_ram(minimal_cpu_context* cpu)
{
    long addr = min_cpu_pop(cpu);
    long val = min_cpu_pop(cpu);
    
    min_ram_set_byte(&cpu->ram, addr, val);
}

// 2
void min_cpu_interrupt_push_ram(minimal_cpu_context* cpu)
{
    long addr = min_cpu_pop(cpu);
    long val = min_ram_get_byte(&cpu->ram, addr);
    
    min_cpu_push(cpu, val);
}

// 3
void min_cpu_interrupt_pop_data(minimal_cpu_context* cpu)
{
    cpu->data_reg = min_cpu_pop(cpu);
}

// 4
void min_cpu_interrupt_push_data(minimal_cpu_context* cpu)
{
    min_cpu_push(cpu, cpu->data_reg);
}

// 5
void min_cpu_interrupt_pop_backup(minimal_cpu_context* cpu)
{
    cpu->backup_reg = min_cpu_pop(cpu);
}

// 6
void min_cpu_interrupt_push_backup(minimal_cpu_context* cpu)
{
    min_cpu_push(cpu, cpu->backup_reg);
}

// 7
void min_cpu_interrupt_print_char(minimal_cpu_context* cpu)
{
    char theChar = (char)min_cpu_pop(cpu);
    printf("%c", theChar);
}

// 8
void min_cpu_interrupt_print_space(minimal_cpu_context* cpu)
{
    printf(" ");
}

// 9
void min_cpu_interrupt_print_newline(minimal_cpu_context* cpu)
{
    printf("\n");
}

// 0xdeadface
void min_cpu_interrupt_debugger(minimal_cpu_context* cpu)
{
    // Set a breakpolong here
    cpu->program_counter += 1;
    cpu->program_counter -= 1;
}


