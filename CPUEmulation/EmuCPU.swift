//
//  EmuCPU.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

/// Stack machine
public protocol EmuCPU {
    func push(_ val: EmuByte)
    func pop() -> EmuByte
    func sub()
    func jlq()
    func executeNextInstruction()
}
