
// This file is licensed under the BSD-3 Clause License
// Copyright 2022 © Charlotte Belanger

import Foundation

public func findSafeRegister(_ fn: UnsafeMutableRawPointer, isns: Int? = nil) -> Int {
    
    var clobbers: [UInt32] = []
    
    let instructions: [UInt32] = fn.withMemoryRebound(to: UInt32.self, capacity: isns ?? 5, { ptr in
        Array(UnsafeMutableBufferPointer(start: ptr, count: 5))
    })
    
    instructions.forEach { isn in
        let opcode = (isn >> 25)
        if opcode == (movz.base >> 25) || opcode == ((movz.base | 1 << 31) >> 25) {
            // we found a movz
            // let's check for the register
            let reg = isn & 0x1F 
            print("register found:", reg)
            
            guard reg <= 20 || reg >= 10 else {
                return
            }
            
            clobbers.append(reg)
        }
        if opcode == ((ldr.base | 0b11 << 30) >> 25) || opcode == ((ldr.base | 0b10 << 30) >> 25) {
            print("Found ldr")
            // we found a movz
            // let's check for the register
            let reg = isn & 0x1F
            print("register found:", reg)
            
            guard reg <= 20 || reg >= 10 else {
                return
            }
            
            clobbers.append(reg)
        }
        
        if opcode == (adrp.base >> 25) {
            print("Found adrp")
            // we found a movz
            // let's check for the register
            let reg = isn & 0x1F
            print("register found:", reg)
            
            guard reg <= 20 || reg >= 10 else {
                return
            }
            
            clobbers.append(reg)
        }
        
        let orrBaseX = (0b0_01_01010_00_0_00000_000000_00000_00000 | 1 << 31)
        let orrBaseW = (0b0_01_01010_00_0_00000_000000_00000_00000)
        
        if opcode == (orrBaseX >> 25) || opcode == (orrBaseW >> 25) {
            print("Found orr")
            // we found a movz
            // let's check for the register
            let reg = isn & 0x1F
            print("register found:", reg)
            
            guard reg <= 20 || reg >= 10 else {
                return
            }
            
            clobbers.append(reg)
        }
        
        let bicBase = 0b0_00_100100_0_000000_000000_00000_00000
        if opcode == (bicBase >> 25) || opcode == (bicBase | 1 << 31) >> 25 {
            // we found a movz
            // let's check for the register
            let reg = isn & 0x1F
            
            guard reg <= 20 || reg >= 10 else {
                return
            }
            
            clobbers.append(reg)
        }
    }
    
    if !clobbers.contains(16) {
        return 16
    } else if !clobbers.contains(17) {
        return 17
    } else if !clobbers.contains(15) {
        return 15
    }
    
    return 16 // hope for the best
}
