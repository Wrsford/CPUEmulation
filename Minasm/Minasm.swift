//
//  Minasm.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/22/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation
import iCPUEmulation

public class iCPURunner {
    public static func runCode(cpu: MinimalCPU, _ code: String)
    {
        let preproc = MinimalPreprocessor()
        let compiler = MinimalCompiler()
        let assembler = MinimalAssembler()
        let binary = assembler.assemble(
            compiler.compile(
                preproc.preprocess(code)
            )
        )
        
       // let cpu = MinimalCPU()
        
        cpu.loadBinary(binary, at: 0x0)
        var isRunning = false
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
            if (isRunning)
            {
                return
            }
            else {
                if (cpu.brkFlag)
                {
                    timer.invalidate()
                }
                else {
                    isRunning = true
                    cpu.executeNextInstruction()
                    isRunning = false
                }
                
                
            }
        }
        
        
    }
}
