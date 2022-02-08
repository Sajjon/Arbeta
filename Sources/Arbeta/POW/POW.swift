//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-05.
//

import Foundation

public struct POW: Equatable {
    public typealias Magic = Int32
    public typealias Nonce = UInt64
    
    /// We can perfectly model the difficulty as an UInt8 with the max value
    /// of 255, since there are only 256 bits in the SHA256 digest, and it is
    /// of course impossible to compute 1337 leading zeros in 256 bit data.
    public typealias Difficulty = UInt8
    
    public let input: Data
    
    /// An optional number 
    public let magic: Magic?
    
    /// The relevant result of the PoW, a number that affected the `output` hash resulting
    /// in it containing enough leading zeros as `difficulty` requires.
    public let nonce: Nonce
    
    /// The hash which starts with `difficulty` many leading zeros.
    public let output: Data
    
    public let difficulty: Difficulty
}
