//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-06.
//

import Foundation
import Crypto
import Shaman

public struct SHA256TwiceHash: CacheableHasher & HashFunction & HashFunctionWithSink {
    
    
    private var onceHasher: Shaman256
    
    public init() {
        onceHasher = .init()
    }
}

public extension SHA256TwiceHash {
    
    typealias Digest = SHA256.Digest
    typealias CachedState = Shaman256.CachedState
    
    static let blockByteCount: Int = SHA256.blockByteCount
   
    
    /// Returns the digest from the data input in the hash function instance.
    ///
    /// - Returns: The digest of the inputted data
    func finalize() -> Digest {
        let once = Data(onceHasher.finalize())
        return SHA256.hash(data: once)
    }
    
    mutating func finalize(to bufferPointer: UnsafeMutableRawBufferPointer) {
        onceHasher.finalize(to: bufferPointer)
        
        let boundsCheckedPtr = UnsafeRawBufferPointer(
            start: bufferPointer.baseAddress,
            count: Shaman256.byteCount
        )
        onceHasher.reinitialize()
        onceHasher.update(bufferPointer: boundsCheckedPtr)
        onceHasher.finalize(to: bufferPointer)
    }
    
    /// Updates the hasher with the data.
    ///
    /// - Parameter data: The data to update the hash
    mutating func update<D>(bufferPointer data: D) where D : DataProtocol {
        onceHasher.update(data: data)
    }

    mutating func updateAndCacheState(input: UnsafeRawBufferPointer, stateDescription: String?) -> CachedState {
        onceHasher.updateAndCacheState(input: input, stateDescription: stateDescription)
    }
    
    mutating func restore(cachedState: inout CachedState) {
        onceHasher.restore(cachedState: &cachedState)
    }
    
}
