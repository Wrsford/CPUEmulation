//
//  MinimalAssembler.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

public class MinimalAssembler: EmuAssembler {
    class AssemblerInstruction {
        var name: String
        var args: [String] = []
        init(_ code: String) {
            let parts = code.components(separatedBy: " ")
            name = parts[0]
            var isFirst = true
            for part in parts {
                if (isFirst)
                {
                    isFirst = false
                    continue
                }
                else {
                    args.append(part)
                }
            }
        }
    }
    
    func getLines(_ code: String) -> [String]
    {
        return code.components(separatedBy:"\n")
    }
    
    func assembleInstruction(_ instr: AssemblerInstruction) -> [EmuByte]
    {
        var opCode = 0
        var args = [EmuByte]()
        
        switch instr.name {
        case "sub":
            opCode = 0x1
        case "jlq":
            opCode = 0x2
        case "push":
            opCode = 0x3
        case "pop":
            opCode = 0x4
        default:
            opCode = 0x0
        }
        
        for arg in instr.args
        {
            args.append(Int(arg)!)
        }
        
        args.insert(opCode, at: 0)
        return args;
    }
    
    public func assemble(_ code: String) -> [EmuByte] {
        // Setup return array
        var assembledBytes = [EmuByte]()
        // Get each line
        let lines = getLines(code)
        for line in lines
        {
            let instr = AssemblerInstruction(line)
            let assembledInstr = assembleInstruction(instr)
            assembledBytes.append(contentsOf: assembledInstr)
        }
        
        return assembledBytes
    }
}
