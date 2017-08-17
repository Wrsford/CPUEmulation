//
//  Memory.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

public typealias EmuInt = Int
public typealias EmuByte = Int

public protocol EmuMemory {
    func setByte(_ val: EmuByte, at address: EmuInt)
    func getByte(at address: EmuInt) -> EmuByte
}
