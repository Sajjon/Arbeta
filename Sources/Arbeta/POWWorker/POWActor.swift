//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//


import Foundation
import CryptoKit
import Shaman

/// An attempted run of a POW, with a deadline and a target difficulty.
public actor POWActor<H: FastHashFunction> {
    
    /// The input data for the PoW (without `magic`, if any)
    private let originalData: Data
    
    /// `magic || originalData` if we have any `magic`, else same as `originalData`
    private let data: Data
    
    private let magic: POW.Magic?
    
    
    private let deadline: Date
    private let difficulty: POW.Difficulty

    private var output = Data(repeating: 0x00, count: H.Digest.byteCount)
    
    /// Since perform HASH(data || nonce) for every
    /// nonce attempt, we can once perform HASH(data)
    /// and store that as a precomputed midstate that
    /// we init the hasher with before every attempted
    /// nonce, which works because:
    /// HASH(data || nonce) <=> HASH(data); HASH(nonce).
    private var cachedState: H.CachedState?

    private var nonce: POW.Nonce = 0
    private var hasher = H()
    private let useCache: Bool

    internal init(
        input: Data,
        magic: POW.Magic?,
        deadline: Date,
        difficulty: POW.Difficulty,
        useCache: Bool = true // for tests
    ) {
        self.originalData = input
        self.magic = magic
        if let magic = magic {
            self.data = Data(magic.bytes() + input)
        } else {
            self.data = originalData
        }
        self.deadline = deadline
        self.difficulty = difficulty
        self.useCache = useCache
    }
}

public extension POWActor {
    convenience init(
        input: Data,
        magic: POW.Magic?,
        deadline: Date,
        difficulty: POW.Difficulty
    ) {
        self.init(input: input, magic: magic, deadline: deadline, difficulty: difficulty, useCache: true)
    }
}

private extension POWActor {

    func initHasher() {
        
        if cachedState != nil {
            hasher.restore(cachedState: &cachedState!)
        } else if useCache {
            cachedState = hasher.updateAndCacheState(data: data, stateDescription: "input data")
        } else {
            hasher = H()
            hasher.update(data: data)
        }
    }
    
    func updateOutputByHashingNonce() {
        initHasher()

        withUnsafeBytes(of: nonce.bigEndian) { nonceBytes in
            hasher.update(bufferPointer: nonceBytes)
        }
        output.withUnsafeMutableBytes { target in
            hasher.finalize(to: target)
        }
    }
}

extension POWActor {
    func work() async throws -> POW {
        try await Task<POW, Swift.Error>(priority: .userInitiated) {
            while true {
                guard
                    Date() < deadline
                else {
                    throw SHA256TwicePOWWorker.Error.timeout
                }
                
                updateOutputByHashingNonce()
                
                if output.leadingZeroBitCount() >= difficulty {
                    return POW(
                        input: originalData,
                        magic: magic,
                        nonce: nonce,
                        output: output,
                        difficulty: difficulty
                    )
                } else {
                    nonce += 1
                }
            }
        }.value
    }
}
