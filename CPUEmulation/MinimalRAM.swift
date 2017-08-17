//
//  MinimalRAM.swift
//  CPUEmulation
//
//  Created by Will Stafford on 8/16/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import Foundation

public class MinimalRAM: EmuMemory {
    
    enum MinimalRamError: Error {
        case noMemoryRegion(virtualAddress: EmuInt)
    }
    
    class Region {
        var virtualAddress: EmuInt
        static let size: EmuInt = 2048
        let size: EmuInt = Region.size
        private var backingBytes: [EmuByte] = [EmuByte](repeating: 0, count: Region.size)
        
        init(virtual: EmuInt) {
            // we are going to align the virtual address here
            let alignedAddress: EmuInt = virtual - (virtual % size)
            virtualAddress = alignedAddress
        }
        
        func adjustedAddress(_ address: EmuInt) -> EmuInt
        {
            return address - virtualAddress
        }
        
        subscript(address: EmuInt) -> EmuByte {
            get {
                return backingBytes[adjustedAddress(address)]
            }
            set(newValue) {
                backingBytes[adjustedAddress(address)] = newValue
            }
        }
    }
    
    private var regions: [Region] = []
    
    /// Gets the region that owns the given address
    private func getRegion(address virtualAddress: EmuInt) throws -> Region  {
        var matchingRegion: Region? = nil
        // Check all regions for the address owner
        for region in regions {
            // Check if it is within the region's lower bound
            if (virtualAddress >= region.virtualAddress)
            {
                // Check if it is within the region's upper bound
                if (virtualAddress < region.virtualAddress + region.size)
                {
                    // Found owning region
                    matchingRegion = region
                    break
                }
            }
        }
        
        // No region found
        if (matchingRegion == nil)
        {
            throw MinimalRamError.noMemoryRegion(virtualAddress: virtualAddress)
        }
        else {
            return matchingRegion!
        }
    }
    
    public func setByte(_ val: EmuByte, at address: EmuInt) {
        do {
            let region = try getRegion(address: address)
            // Region exists, set the value
            region[address] = val
            
        } catch MinimalRamError.noMemoryRegion(_) {
            // Need a new region
            
            let newRegion = Region(virtual: address)
            newRegion[address] = val
            regions.append(newRegion)
        }
        catch {
            print("Couldn't set byte at \(address)!")
        }

    }
    
    public func getByte(at address: EmuInt) -> EmuByte {
        do {
            let region = try getRegion(address: address)
            
            return region[address]
            
        } catch MinimalRamError.noMemoryRegion(let virtualAddress) {
            print("No owning region found for requested address: \(virtualAddress)")
            return 0
        }
        catch {
            return 0
        }
    }
}
