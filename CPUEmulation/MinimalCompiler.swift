//
//  MinimalCompiler.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

public class MinimalCompiler: EmuCompiler {
    private let backingAssembler = MinimalAssembler()
    func expandLine(_ line: String) -> [String]
    {
        let instr = MinimalAssembler.AssemblerInstruction(line)
        
        if (instr.name != "push")
        {
            var expandedLines = [String]()
            for arg in instr.args
            {
                expandedLines.append("push \(arg)")
            }
            expandedLines.append(instr.name)
            return expandedLines
        }
        else {
            return [line]
        }
    }
    
    public func compile(_ code: String) -> String {
        let lines = backingAssembler.getLines(code)
        var compiledLines = [String]()
        for line in lines {
            let expandedLine = expandLine(line)
            compiledLines.append(contentsOf: expandedLine)
        }
        return compiledLines.joined(separator:"\n")
    }
}
