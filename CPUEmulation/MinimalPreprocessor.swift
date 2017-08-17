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
    
    func removeComments(_ line: String) -> String
    {
        if (line.contains(";"))
        {
            let indexOfComment = line.range(of: ";")!.lowerBound
            let withCommentRemoved = line.substring(to: indexOfComment)
            return withCommentRemoved.trimmingCharacters(in: .whitespaces)
        }
        else {
            return line
        }
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
