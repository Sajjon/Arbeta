//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-05.
//

import Foundation

public struct POW: Equatable {
    
    /// The input for the PoW worker, used to produce this proof of work.
    public let input: Input
    
    /// The outputted result of the PoW worker, being the nonce and the hash
    /// which has #`config.diffuculty` many leading zeros.
    public let output: Output
    
    /// The configuration used by the PoW worker to produce this proof of work.
    public let config: Config
}

public extension POW {
    typealias Magic = Int32
    typealias Nonce = UInt64
    
    /// We can perfectly model the difficulty as an UInt8 with the max value
    /// of 255, since there are only 256 bits in the SHA256 digest, and it is
    /// of course impossible to compute 1337 leading zeros in 256 bit data.
    typealias Difficulty = UInt8
}

public extension POW {
    struct Config: Equatable {
        
        /// The target number of leading zeros of the outputted hash of the work.
        public let difficulty: Difficulty
        
        /// An optional number prepended to the input of the PoW worker.
        public let magic: Magic?
    }
    
    struct Input: Equatable {
        public let original: Data
        
        /// Same as `original` if `config.magic` is nil, else `magic || original`
        public let used: Data
    }
    
    struct Output: Equatable {
        
        /// The relevant result of the PoW, a number that affected the `output` hash resulting
        /// in it containing enough leading zeros as `difficulty` requires.
        public let nonce: Nonce
        
        /// The hash which starts with `difficulty` many leading zeros.
        public let output: Data
    }
}
