//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-06.
//

import Foundation

enum Endianess {
    case big, little
}

internal extension FixedWidthInteger {
 
    func bytes(endianess: Endianess = .big) -> [UInt8] {
        withUnsafeBytes(of: endianess == .big ? self.bigEndian : self.littleEndian, Array.init)
    }
}
