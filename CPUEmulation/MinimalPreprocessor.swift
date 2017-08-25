//
//  MinimalPreprocessor.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

public class MinimalPreprocessor: EmuPreprocessor
{
    private let backingAssembler = MinimalAssembler()
    
    public init() {
        
    }
    
    func removeComments(_ line: String) -> String
    {
        var resultLine = line
        if (resultLine.contains(";"))
        {
            let indexOfComment = resultLine.range(of: ";")!.lowerBound
            let withCommentRemoved = resultLine.substring(to: indexOfComment)
            resultLine = withCommentRemoved.trimmingCharacters(in: .whitespaces)
        }
        
        if (resultLine.contains("//"))
        {
            let indexOfComment = resultLine.range(of: "//")!.lowerBound
            let withCommentRemoved = resultLine.substring(to: indexOfComment)
            resultLine = withCommentRemoved.trimmingCharacters(in: .whitespaces)
        }
        
        return resultLine
    }
    
    public func preprocess(_ code: String) -> String {
        let allLines = backingAssembler.getLines(code)
        var processedLines = [String]()
        
        for line in allLines {
            let trimmedLine = removeComments(line.trimmingCharacters(in: .whitespaces))
            
            if (trimmedLine.characters.count == 0)
            {
                // blank
                continue
            }
            else {
                processedLines.append(trimmedLine)
            }
        }
        
        return processedLines.joined(separator:"\n")
    }
}
