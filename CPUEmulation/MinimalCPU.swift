//
//  MinimalCPU.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

public class MinimalCPU: EmuCPU {
    public var programCounter: EmuInt = 0
    public let ram = MinimalRAM()
    public var stack: [EmuByte] = []
    public var callstack: [EmuByte] = []
    public var dataReg: EmuByte = 0; // Stores a single value
    public var brkFlag: Bool = false
    private var interruptTable = [EmuByte: (MinimalCPU) -> (Void)]()
    
    public init() {
        // set up interrupts
        
        // Interrupt 0: Push PC to stack
        addInterrupt(0x0) { (cpu) -> () in
            cpu.push(cpu.programCounter)
        }
        
        // Interrupt 1: write a value to RAM
        addInterrupt(0x1) { (cpu) -> () in
            let addr = cpu.pop()
            let val = cpu.pop()
            
            cpu.ram.setByte(val, at: addr)
        }
        
        // Interrupt 2: push a value from RAM to the stack
        addInterrupt(0x2) { (cpu) -> () in
            let addr = cpu.pop()
            let val = cpu.ram.getByte(at: addr)
            cpu.push(val)
        }
        
        // Interrupt 3: pop to data register
        addInterrupt(0x3) { (cpu) -> (Void) in
            cpu.dataReg = cpu.pop()
        }
        
        // Interrupt 4: push data register
        addInterrupt(0x4) { (cpu) -> (Void) in
            cpu.push(cpu.dataReg)
        }
        
        // Interrupt 0xDEADFACE: Debugger breakpoing
        addInterrupt(0xdeadface) { (cpu) -> (Void) in
            print("Hit debugger");
        }
    }
    
    public func push(_ val: EmuByte) {
        stack.append(val)
    }
    
    @discardableResult public func pop() -> EmuByte {
        return stack.popLast()!
    }
    
    public func sub() {
        let rhs = pop()
        let lhs = pop()
        push(lhs - rhs)
    }
    
    public func jlq() {
        
        let rhs = pop()
        let addr = pop()
        let lhs = pop()
        
        
        if (lhs <= rhs)
        {
            programCounter = addr
        }
    }
    
    public func call()
    {
        let addr = pop()
        callstack.append(programCounter + 1)
        
        programCounter = addr
    }
    
    public func ret()
    {
        let addr = callstack.popLast()!
        
        programCounter = addr
    }
    
    public func dup()
    {
        // duplicate the last value on the stack
        let lastVal = pop()
        push(lastVal)
        push(lastVal)
    }
    
    public func interrupt() {
        let intCode = pop()
        interruptTable[intCode]!(self)
    }
    
    public func addInterrupt(_ code: EmuByte, _ callback: @escaping (MinimalCPU) -> (Void))
    {
        interruptTable[code] = callback
    }
    
    
    public func executeNextInstruction() {
        if (brkFlag)
        {
            return
        }
        let nextInstrOpCode = ram.getByte(at: programCounter)
        let pcBackup = programCounter
        var argCount = 0x0
        // we have like 4 instructions, hardcode for now
        switch nextInstrOpCode {
        case 0x1:
            sub()
        case 0x2:
            jlq()
        case 0x3:
            argCount = 0x1
            push(ram.getByte(at: programCounter + 1))
        case 0x4:
            pop()
        case 0x5:
            // interrupt
            interrupt()
        case 0x6:
            // call
            call()
        case 0x7:
            // ret
            ret()
        default:
            brkFlag = true
            break
        }
        
        if (programCounter == pcBackup)
        {
            programCounter += argCount + 1
        }
        else {
            // PC was modified by instruction, don't auto increment
        }
    }
    
    public func loadBinary(_ binary: [EmuByte], at baseAddress: EmuInt)
    {
        var binAddr = baseAddress
        for binByte in binary {
            ram.setByte(binByte, at: binAddr)
            binAddr += 1
        }
    }
}
