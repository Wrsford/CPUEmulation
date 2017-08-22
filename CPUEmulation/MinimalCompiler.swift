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
    private let funcAddressBase: EmuInt = 0xFF00
    // Func label : Address of func start
    private var funcLookup: [String:EmuInt] = [:]
    let compilerDirectivePrefix = "@"
    
    func isCompilerDirective(_ strToCheck: String) -> Bool
    {
        var result = false
        
        if (strToCheck.hasPrefix(compilerDirectivePrefix))
        {
            result = true
        }
        
        return result
    }
    
    func getCallDirectiveSize(_ directive: MinimalAssembler.AssemblerInstruction) -> EmuInt {
        return 6 + (directive.args.count - 1) * 2
    }
    
    func getJumpDirectiveSize(_ directive: MinimalAssembler.AssemblerInstruction) -> EmuInt {
        // +push 0
        // push addr
        // +push cmpval
        return 6 + (directive.args.count - 1) * 2 + 4
    }
    
    func getDirectiveSize(_ directive: MinimalAssembler.AssemblerInstruction) -> EmuInt
    {
        if (directive.name == "@call")
        {
            return getCallDirectiveSize(directive)
        }
        else if (directive.name == "@jump")
        {
            return getJumpDirectiveSize(directive)
        }
        else if (directive.name == "@pushfunc")
        {
            return 2
        }
        
        
        return 0
    }
    
    /// Funcs in funcs will not work HERE. Move them out & above this func to use them
    func createFunctionWrapper(_ funcContent: [MinimalAssembler.AssemblerInstruction]) -> [MinimalAssembler.AssemblerInstruction]
    {
        var compiled: [MinimalAssembler.AssemblerInstruction] = []
        
        let funcLookupAddress: EmuInt = funcAddressBase + funcLookup.count
        let addrOffset = 24
        
        // need to figure out the size of the body
        // go through each instr, compile, assemble & get size
        var funcBodySize = 0
        for funcLine in funcContent {
            var thisLineSize = 0
            if (isCompilerDirective(funcLine.name))
            {
                thisLineSize = getDirectiveSize(funcLine)
            }
            else {
                // compile the line
                let compiledLine = expandInstruction(funcLine)
                // adjust push commands to the 0x2 size
                for cl in compiledLine {
                    if (cl.name == "push")
                    {
                        thisLineSize -= 1 // one less since we already have a for a push
                    }
                    thisLineSize += 1 + cl.args.count * 2 // pushing each arg = * 2
                }
            }
            
            if (thisLineSize < 0)
            {
                // bad!
                print("bad line size: \(funcLine.toLine())")
            }
            else {
                funcBodySize += thisLineSize
            }
        }
        
        var theFuncBody: [String] = []
        let lastBodyIndex = funcContent.count - 2 // What do empty funcs do? prolly crash
        for i in 1...lastBodyIndex {
            theFuncBody.append(funcContent[i].toLine())
        }
        
        // yay hardcoded minasm
        var wrapper: [String] = [
            "push 0",
            "int 0",
            "push -\(addrOffset)",
            "sub",
            "int 3",
            "int 4",
            "push \(funcLookupAddress)",
            "push 1",
            "int",
            "int 0",
            "push -\(funcBodySize + 1 + 7)", // add one for the ret
            "sub",
            "push 0",
            "jlq",
        ]
        
        wrapper.append(contentsOf: theFuncBody)
        wrapper.append("ret")
        
        for wrapLine in wrapper {
            compiled.append(MinimalAssembler.AssemblerInstruction(wrapLine))
        }
        
        return compiled;
    }
    
    func convertCharacters(_ line: MinimalAssembler.AssemblerInstruction) -> MinimalAssembler.AssemblerInstruction {
        let newLine = MinimalAssembler.AssemblerInstruction(line.toLine())
        for i in 0..<newLine.args.count
        {
            let theArg = newLine.args[i]
            if (theArg.hasPrefix("'") && theArg.hasSuffix("'") && theArg.characters.count == 3)
            {
                // It's a character
                newLine.args[i].characters.removeLast()
                let theChar =  newLine.args[i].characters.removeLast()
                let strChar = String(theChar)
                newLine.args[i] = String(strChar.utf8CString.first!)
                
            }
        }
        return newLine
    }
    
    // Spaces aren't supported, sorry
//    func convertStrings(_ line: MinimalAssembler.AssemblerInstruction) -> [MinimalAssembler.AssemblerInstruction] {
//        var newLine = MinimalAssembler.AssemblerInstruction(line.toLine())
//        for i in 0..<newLine.args.count
//        {
//            let theArg = newLine.args[i]
//            if (theArg.hasPrefix("\"") && theArg.hasSuffix("\"") && theArg.characters.count == 3)
//            {
//                // It's a string
//                newLine.args[i].characters.removeLast()
//                let theChar =  newLine.args[i].characters.removeLast()
//                let strChar = String(theChar)
//                newLine.args[i] = String(strChar.utf8CString.first!)
//                
//            }
//        }
//        return newLine
//    }
    
    /// Evaluates all compiler directives & SHOULD return instructions without and directives left
    func evaluateCompilerDirectives(_ allLines: [MinimalAssembler.AssemblerInstruction]) -> [MinimalAssembler.AssemblerInstruction]
    {
        // NOTE: Let's do one at a time, then recurse w/ the result. That should simplify some stuff
        
        // What the actual fuck? cant call the constructor normally: [MinimalAssembler.AssemblerInstruction]()
        var resolved: [MinimalAssembler.AssemblerInstruction] = []
        
        // Go through lines and find all directives
        /// [LineNo : Directive]
        var allDirectives: [Int : MinimalAssembler.AssemblerInstruction] = [:]
        var lineNo = 0
        var earliestLineNo = -1
        for line in allLines {
            // TODO detect directives in args as well
            if (isCompilerDirective(line.name))
            {
                if (earliestLineNo == -1)
                {
                    earliestLineNo = lineNo
                }
                allDirectives[lineNo] = line
            }
            
            lineNo += 1
        }
        // Return if there are no directives left
        if (allDirectives.count == 0)
        {
            // Also ends recursion
            return allLines
        }
        
        var skipToLine = 0
        //var didCompileDirective = false
        
        // Figure out the order to evaluated those directives (TODO)
        for directive in allDirectives {
            if (directive.key > earliestLineNo)
            {
                continue
            }
            // What do we support initially? funcs & calls only? yep
            // func defs first
            if (directive.value.name == "@func")
            {
                // it's a func
                // Read to the end
                let startLineNo = directive.key;
                
                var endLineNo = -1;
                
                for possibleEnd in allDirectives
                {
                    if (possibleEnd.value.name == "@end")
                    {
                        // check if this is the correct @end
                        if (possibleEnd.value.args[0] == directive.value.args[0])
                        {
                            // they match
                            endLineNo = possibleEnd.key
                            break
                        }
                    }
                }
                
                if (endLineNo == -1)
                {
                    // TODO: throw a compiler error
                    print("No function end line #: \(directive.value.name) : Line \(directive.key)")
                }
                else {
                    // make function content
                    var funcContent: [MinimalAssembler.AssemblerInstruction] = []
                    for i in startLineNo...endLineNo
                    {
                        funcContent.append(allLines[i])
                    }
                    
                    // now get the compiled version
                    let compiledFunc = createFunctionWrapper(funcContent)
                    
                    // Append preceeding lines
                    for i in 0..<startLineNo
                    {
                        resolved.append(allLines[i])
                    }
                    
                    for compiledLine in compiledFunc {
                        resolved.append(compiledLine)
                    }
                    skipToLine = endLineNo + 1
                }
                funcLookup[directive.value.args[0]] = funcAddressBase + funcLookup.count
                break
            }
            else if (directive.value.name == "@call")
            {
                //continue
                // it's a call
                let theTargetAddress = funcLookup[directive.value.args[0]]!
                var finalInstr: [String] = []
                if (directive.value.args.count > 1)
                {
                    for i in 1..<directive.value.args.count
                    {
                        finalInstr.append("push \(directive.value.args[i])")
                    }
                }
                finalInstr.append("push \(theTargetAddress)") // Call doesnt know that more args were passed, will assume the last pushed value is the dest
                finalInstr.append("int 2")
                finalInstr.append("call")
                
                // Append preceeding lines
                for i in 0..<directive.key
                {
                    resolved.append(allLines[i])
                }
                for fi in finalInstr
                {
                    resolved.append(MinimalAssembler.AssemblerInstruction(fi))
                }
                
                skipToLine = directive.key + 1
                break

            }
            else if (directive.value.name == "@jump")
            {
                //continue
                // it's a jump
                let theTargetAddress = funcLookup[directive.value.args[0]]!
                var finalInstr: [String] = []
                if (directive.value.args.count > 1)
                {
                    for i in 1..<directive.value.args.count
                    {
                        finalInstr.append("push \(directive.value.args[i])")
                    }
                }
                finalInstr.append("push 0")
                finalInstr.append("push \(theTargetAddress)") // Call doesnt know that more args were passed, will assume the last pushed value is the dest
                finalInstr.append("int 2")
                finalInstr.append("push 0")
                finalInstr.append("jlq")
                
                // Append preceeding lines
                for i in 0..<directive.key
                {
                    resolved.append(allLines[i])
                }
                for fi in finalInstr
                {
                    resolved.append(MinimalAssembler.AssemblerInstruction(fi))
                }
                
                skipToLine = directive.key + 1
                break
                
            }
            else if (directive.value.name == "@pushfunc")
            {
                let theTargetAddress = funcLookup[directive.value.args[0]]!
                let finalInstr: [String] = [
                    "push \(theTargetAddress)"
                ]
                
                // Append preceeding lines
                for i in 0..<directive.key
                {
                    resolved.append(allLines[i])
                }
                for fi in finalInstr
                {
                    resolved.append(MinimalAssembler.AssemblerInstruction(fi))
                }
                
                skipToLine = directive.key + 1
                break
            }
            
        }
        // As we get back resolved directives, we will add them to the "resolved" array in order
        
        // append remaining lines
        if (skipToLine != -1 && skipToLine < allLines.count)
        {
            for i in skipToLine..<allLines.count
            {
                
                resolved.append(allLines[i])
            }
        }
        
        // Recurse & return final result (recursion will end when no directives are left)
        
        
        return evaluateCompilerDirectives(resolved)
    }
    
    
    
    func expandLine(_ line: String) -> [String]
    {
        let instr = MinimalAssembler.AssemblerInstruction(line)
        
        if (instr.name != "push" || (instr.args.count > 1))
        {
            var expandedLines = [String]()
            for arg in instr.args
            {
                expandedLines.append("push \(arg)")
            }
            if (instr.name != "push")
            {
                expandedLines.append(instr.name)
            }
            
            return expandedLines
        }
        else {
            return [line]
        }
    }
    
    func expandInstruction(_ line: MinimalAssembler.AssemblerInstruction) -> [MinimalAssembler.AssemblerInstruction]
    {
        // lazy
        let expandedLineStrings = expandLine(line.toLine())
        var expInstrs: [MinimalAssembler.AssemblerInstruction] = []
        for els in expandedLineStrings
        {
            expInstrs.append(MinimalAssembler.AssemblerInstruction(els))
        }
        return expInstrs
        
    }
    
    func hasStrings(_ line: String) -> Bool {
        return line.range(of: "\"") != nil
    }
    
    func convertStrings(_ line: String) -> String
    {
        // I hate parsing string args
        
        // Step 1: Externalize
        let escapedEscapeMarker = "$$$ARE__YOU_FOR$$REAL__RIGHT_NOW?$$$$$"
        let escapedQuoteMarker = "$esc_str$"
        
        if (line.range(of: escapedQuoteMarker) != nil)
        {
            print("Detected a line with the escape marker already included. Fuck you.")
        }
        
        // Escape escaped quotes :/
        let escapedQuotes = line.replacingOccurrences(of: "\\\"", with: escapedQuoteMarker)
        
        // Use a regex
        let quotedContent = escapedQuotes.capturedGroups(withRegex: "\"(.*?)\"")!
        var resolvedString = escapedQuotes
        for qc in quotedContent {
            // TODO: Other escape chars (\n, \t, etc)
            let resolvedCapture = qc.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: escapedQuoteMarker, with: "\"")
            var charVals: [String] = []
            // Get character values
            for rcChar in resolvedCapture.utf8
            {
                charVals.append(String(Int(rcChar)))
            }
            charVals.append("0") // null terminator
            // Reverse string pushing
            charVals.reverse()
            
            // This should be the resolved string
            let spacedOutString = charVals.joined(separator: " ")
            resolvedString = resolvedString.replacingOccurrences(of: "\"\(qc)\"", with: spacedOutString)
        }
        
        
        return resolvedString
    }
    
    /// Just do all the string crap
    func handleStrings(_ allLines: [String]) -> [String]
    {
        var resolvedLines: [String] = []
        
        for line in allLines
        {
            if (hasStrings(line))
            {
                resolvedLines.append(convertStrings(line))
            }
            else {
                resolvedLines.append(line)
            }
        }
        
        
        return resolvedLines
    }
    
    public func compile(_ code: String) -> String {
        let lines = handleStrings(backingAssembler.getLines(code))
        var parsedInstrs: [MinimalAssembler.AssemblerInstruction] = []
        for line in lines {
            parsedInstrs.append(MinimalAssembler.AssemblerInstruction(line))
        }
        
        let parsedDirectives = evaluateCompilerDirectives(parsedInstrs)
        var afterDirectives: [String] = []
        
        var compiledLines = [String]()
        for line in parsedDirectives {
            let convChars = convertCharacters(line)
            afterDirectives.append(convChars.toLine())
            
            let expandedLine = expandLine(convChars.toLine())
            compiledLines.append(contentsOf: expandedLine)
        }
        
        //let parsedDirStr = afterDirectives.joined(separator: "\n")
        
        let resultCode = compiledLines.joined(separator:"\n")
        //print(resultCode)
        return resultCode
    }
}
extension String {
    func capturedGroups(withRegex pattern: String) -> [String]? {
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return nil
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.characters.count))
        
        guard let match = matches.first else { return nil }
        
        // Note: Index 1 is 1st capture group, 2 is 2nd, ..., while index 0 is full match which we don't use
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return nil }
        
        var results = [String]()
        
        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.rangeAt(i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }
        
        return results
    }
}
