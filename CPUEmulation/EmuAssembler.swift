//
//  EmuAssembler.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

public protocol EmuAssembler {
    func assemble(_ code: String) -> [EmuByte]
}
