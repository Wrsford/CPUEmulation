//
//  ViewController.swift
//  Minasm
//
//  Created by Will Stafford on 8/22/17.
//  Copyright © 2017 Wrsford. All rights reserved.
//

import UIKit
import iCPUEmulation

class ViewController: UIViewController {
    private let theCPU = MinimalCPU()
    private let resX = 300
    private let resY = 300
    
    private func setPixel(_ color: Int, x: Int, y: Int)
    {
        // Set the
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add graphics interrupts
        theCPU.addInterrupt(0x800) { (cpu) -> (Void) in
            // [color, x, y]
            let yVal = cpu.pop()
            let xVal = cpu.pop()
            let color = cpu.pop()
            self.setPixel(color, x: xVal, y: yVal)
        }
        
        // get horizontal resolution
        theCPU.addInterrupt(0x801) { (cpu) -> (Void) in
            cpu.push(self.resX)
        }
        
        // get vertical resolution
        theCPU.addInterrupt(0x802) { (cpu) -> (Void) in
            cpu.push(self.resY)
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

