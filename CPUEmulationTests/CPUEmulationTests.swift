//
//  CPUEmulationTests.swift
//  CPUEmulationTests
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import XCTest
@testable import CPUEmulation

class CPUEmulationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimalRAM() {
        let testAddresses = [0, 0x423, 0x5532, 0x288818, 0xFFFFFFFF]
        let theRam = MinimalRAM()
        for address in testAddresses
        {
            theRam.setByte(0x33, at: address)
        }
        
        for address in testAddresses
        {
            let theVal = theRam.getByte(at: address)
            assert(theVal == 0x33)
        }
    }
    
    func testMinimalAssembler() {
        let assembler = MinimalAssembler()
        let codeLines = [
            "push 5",// 0x0 - 0x1
            "push 3",// 0x2 - 0x3
            "sub",   // 0x4 - 0x4
            "push 0",// 0x5 - 0x6
            "push 1",// 0x7 - 0x8
            "jlq",   // 0x9 - 0x9
        ]
        let allCode = codeLines.joined(separator: "\n")
        let assembled = assembler.assemble(allCode)
        
        let expectedBytes = [
            0x3, 0x5,
            0x3, 0x3,
            0x1,
            0x3, 0x0,
            0x3, 0x1,
            0x2
        ]
        
        for i in 0...0x9 {
            assert(assembled[i] == expectedBytes[i])
        }
    }
    
    func testMinimalCPU() {
        let assembler = MinimalAssembler()
        let codeLines = [
            "push 1337",
            "push 3",
            "push 5",
            "sub",   
            "push 4",
            "push 1",
            "jlq",
            "push 50"
        ]
        let allCode = codeLines.joined(separator: "\n")
        let assembled = assembler.assemble(allCode)
        
        let cpu = MinimalCPU()
        cpu.loadBinary(assembled, at: 0x0)
        while (!cpu.brkFlag)
        {
            cpu.executeNextInstruction()
        }
        
        assert(cpu.pop() == 50)
        assert(cpu.stack.count == 0)
    }
    
    func testMinimalCompiler() {
        let compiler = MinimalCompiler()
        
        
        let codeLines = [
            "push 1337",
            "sub 3 5",
            "jlq 4 1",
            "push 50"
        ]
        let allCode = codeLines.joined(separator: "\n")
        
        let expectedCodeLines = [
            "push 1337",
            "push 3",
            "push 5",
            "sub",
            "push 4",
            "push 1",
            "jlq",
            "push 50"
        ]
        let expectedCode = expectedCodeLines.joined(separator: "\n")
        
        let actualCode = compiler.compile(allCode)
        
        assert(actualCode == expectedCode)
    }
    
    func testMinimalPreprocessor() {
        let preproc = MinimalPreprocessor()
        let codeLines = [
            " ; Start preprocessor test code",
            "push 1337 ; Pushing a large number so there is a large left hand side for the second sub()",
            "",
            "; 3 - 5",
            "push 3",
            "push 5 ; The jump below will land here, resulting in a subtraction of 5 from the last # on the stack",
            "sub ; Should give -2 on the first round",
            "jlq 4 1 ; Jumps to 0x4 (halfway through the original sub) if the last return value is <= 1",
            "",
            "; We get here if the sub result was > 1",
            "push 50 ; Push a value to allow a good assertion when testing execution later",
            " ; End preprocessor test code"
        ]
        let allCode = codeLines.joined(separator: "\n")
        
        let expectedCodeLines = [
            "push 1337",
            "push 3",
            "push 5",
            "sub",
            "jlq 4 1",
            "push 50"

        ]
        let expectedCode = expectedCodeLines.joined(separator: "\n")
        
        let actualCode = preproc.preprocess(allCode)
        
        assert(actualCode == expectedCode)
    }
    
    func testMinimalCodeExec() {
        let codeLines = [
            " ; Start preprocessor test code",
            "push 1337 ; Pushing a large number so there is a large left hand side for the second sub()",
            "",
            "; 3 - 5",
            "push 3",
            "push 5 ; The jump below will land here, resulting in a subtraction of 5 from the last # on the stack",
            "sub ; Should give -2 on the first round",
            "jlq 4 1 ; Jumps to 0x4 (halfway through the original sub) if the last return value is <= 1",
            "",
            "; We get here if the sub result was > 1",
            "push 50 ; Push a value to allow a good assertion when testing execution later",
            " ; End preprocessor test code"
        ]
        let allCode = codeLines.joined(separator: "\n")
        
        let preproc = MinimalPreprocessor()
        let compiler = MinimalCompiler()
        let assembler = MinimalAssembler()
        
        let binary = assembler.assemble(
            compiler.compile(
                preproc.preprocess(allCode)
            )
        )
        
        // Make our CPU
        let cpu = MinimalCPU()
        
        // load up code
        cpu.loadBinary(binary, at: 0x0)
        
        // Execute
        while (!cpu.brkFlag)
        {
            cpu.executeNextInstruction()
        }
        
        assert(cpu.pop() == 50)
        assert(cpu.stack.count == 0)

    }
    
    
    func testMinimalCodePlaygroundExec() {
        // Srry guys, dont have time for xcode project bs
        let allCode = try! String(contentsOfFile: "/Users/wrsford/Dropbox/Development17/CPUEmulation/CPUEmulationTests/minimalPlayground.minasm");
        
        let preproc = MinimalPreprocessor()
        let compiler = MinimalCompiler()
        let assembler = MinimalAssembler()
        
        let binary = assembler.assemble(
            compiler.compile(
                preproc.preprocess(allCode)
            )
        )
        
        // Make our CPU
        let cpu = MinimalCPU()
        
        // load up code
        cpu.loadBinary(binary, at: 0x0)
        
        // Execute
        while (!cpu.brkFlag)
        {
            cpu.executeNextInstruction()
        }
        
        assert(cpu.brkFlag);
        
    }
    
    func testMinimalCodeCompilerPlayground() {
        // Srry guys, dont have time for xcode project bs
        let allCode = try! String(contentsOfFile: "/Users/wrsford/Dropbox/Development17/CPUEmulation/CPUEmulationTests/compilerPlayground.minasm");
        
        let preproc = MinimalPreprocessor()
        let compiler = MinimalCompiler()
        
        let result = compiler.compile(preproc.preprocess(allCode))
        
        assert(result.characters.count > 0);
    }
    
    func testMinimalCodeCompilerPlaygroundExec() {
        // Srry guys, dont have time for xcode project bs
        let allCode = try! String(contentsOfFile: "/Users/wrsford/Dropbox/Development17/CPUEmulation/CPUEmulationTests/compilerPlayground.minasm");
        
        let preproc = MinimalPreprocessor()
        let compiler = MinimalCompiler()
        let assembler = MinimalAssembler()
        
        let binary = assembler.assemble(
            compiler.compile(
                preproc.preprocess(allCode)
            )
        )
        
        // Make our CPU
        let cpu = MinimalCPU()
        
        // load up code
        cpu.loadBinary(binary, at: 0x0)
        
        // Execute
        while (!cpu.brkFlag)
        {
            cpu.executeNextInstruction()
        }
        
        assert(cpu.brkFlag);
    }

    func testPrimitiveMinimalCPU() {
        let allCode = try! String(contentsOfFile: "/Users/wrsford/Dropbox/Development17/CPUEmulation/CPUEmulationTests/compilerPlayground.minasm");
        
        let preproc = MinimalPreprocessor()
        let compiler = MinimalCompiler()
        let assembler = MinimalAssembler()
        
        let binary = assembler.assemble(
            compiler.compile(
                preproc.preprocess(allCode)
            )
        )
        
        
        
        let primitiveBin = UnsafeMutablePointer<Int>.allocate(capacity: binary.count)
        var initBin = primitiveBin
        var cntr = 0
        var strVals: [String] = []
        
        for byte in binary {
            initBin.pointee = byte
            initBin = initBin.advanced(by: 1)
            cntr += 1
            
            strVals.append(String(byte))
        }
        
        print(strVals.joined(separator: ", "))
        
        
        var cpu = minimal_cpu_context()
        let cpuPtr = UnsafeMutablePointer<minimal_cpu_context>(&cpu)
        
        // Initialize
        min_cpu_init(cpuPtr)
        min_cpu_load_binary(cpuPtr, 0x0, primitiveBin, binary.count)
        
        
        while (cpu.break_flag != 1)
        {
            min_cpu_exec_next_instr(cpuPtr)
        }
        
        assert(true)
        
    }
    
    func testBuildWiiUTestProgram() {
        let allCode = try! String(contentsOfFile: "/Users/wrsford/Dropbox/Development17/CPUEmulation/CPUEmulationTests/wiiuTest.minasm");
        
        let preproc = MinimalPreprocessor()
        let compiler = MinimalCompiler()
        let assembler = MinimalAssembler()
        
        let compiled = compiler.compile(
            preproc.preprocess(allCode)
        )
        
        let binary = assembler.assemble(
            compiled
        )

        let compiledLines = assembler.getLines(compiled)
        
        var lines: [String] = [
            "const long testProgram[\(binary.count)] = {"
        ]
        var lineNo = 0
        var wasPush = false
        var byteCounter = 0
        for byte in binary {
            
            if (!wasPush && byte == 0x3)
            {
                // Push command, fill in next pass
                wasPush = true;
            }
            else if (wasPush)
            {
                let thisLine = ("  /* " + "\(byteCounter - 1)".padding(toLength: "\(binary.count)".characters.count, withPad: " ", startingAt: 0) + ": \(compiledLines[lineNo])").padding(toLength: 26, withPad: " ", startingAt: 0) + "*/   3, \(byte),"
                lines.append(thisLine);
                wasPush = false;
                lineNo += 1
            }
            else {
                // Other command
                
                let thisLine = ("  /* " + "\(byteCounter)".padding(toLength: "\(binary.count)".characters.count, withPad: " ", startingAt: 0) + ": \(compiledLines[lineNo])").padding(toLength: 26, withPad: " ", startingAt: 0) + "*/   \(byte),"
                lines.append(thisLine);
                lineNo += 1
                
            }
            byteCounter += 1
        }
        lines.append(contentsOf: [
            "};",
            "",
            "long* minasm_get_test_program() {",
            "\treturn (long*)testProgram;",
            "}",
            "long minasm_get_program_size() {",
            "\treturn \(binary.count);",
            "}"
            ])
        
        let finalStr = lines.joined(separator: "\n")
        print(finalStr)
        try! finalStr.write(toFile: "/Users/wrsford/Dropbox/Development17/WiiU/homebrew-app-template/appcode/minasm/min_wii_asm.c", atomically: true, encoding: .utf8)
        assert(true)
        
    }
}
