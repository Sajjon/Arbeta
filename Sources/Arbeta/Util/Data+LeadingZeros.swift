//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-06.
//

import Foundation

// MARK: - Data + Leading 0s
// MARK: -
internal extension Data {
    @inline(__always)
    func leadingZeroBitCount() -> Int {
        let bitsPerByte = 8
        guard let index = firstIndex(where: { $0 != 0 }) else {
            return count * bitsPerByte
        }
        
        // count zero bits in byte at index `index`
        return index * bitsPerByte + self[index].leadingZeroBitCount
    }
}

