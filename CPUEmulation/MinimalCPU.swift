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
    public var brkFlag: Bool = false
    
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
            argCount = 0x0
            sub()
        case 0x2:
            argCount = 0x0
            jlq()
        case 0x3:
            argCount = 0x1
            push(ram.getByte(at: programCounter + 1))
        case 0x4:
            argCount = 0x0
            pop()
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
