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
    @discardableResult func pop() -> EmuByte
    func sub()
    func jlq()
    func call()
    func ret()
    func interrupt()
    func addInterrupt(_ code: EmuByte, _ callback: @escaping (MinimalCPU) -> (Void))
    func replaceInterrupt(_ code: EmuByte, _ callback: @escaping (MinimalCPU) -> (Void))
    func loadBinary(_ binary: [EmuByte], at baseAddress: EmuInt)
    func executeNextInstruction()
}
