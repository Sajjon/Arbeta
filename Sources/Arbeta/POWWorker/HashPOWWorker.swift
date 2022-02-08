//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-05.
//

import Foundation
import CryptoKit
import Shaman

public typealias FastHashFunction = HashFunction & CacheableHasher & HashFunctionWithSink

public typealias SHA256TwicePOWWorker = HashPOWWorker<SHA256TwiceHash>
public typealias SHA256POWWorker = HashPOWWorker<Shaman256>

public struct HashPOWWorker<H: FastHashFunction>: POWWorker {
    
    /// The target number of leading zeros in HASH(input || nonce)
    /// The higher the difficulty the longer time it will take to
    /// calculate this POW, i.e. the higher the nonce will reach.
    public let difficulty: POW.Difficulty
    
    /// Max time for an attempted POW, if this POW worker does not
    /// finish computing the POW in time, a timeout error will be
    /// thrown.
    public let maxDuration: TimeInterval
    
    /// An optional number that is prepended to input data for PoW.
    public let magic: POW.Magic?
    
    public static var defaultDifficulty: POW.Difficulty { 16 }
    public static var defaultTimeout: TimeInterval { 30 }
    private let useCache: Bool
    
    internal init(
        difficulty: POW.Difficulty = Self.defaultDifficulty,
        magic: POW.Magic?,
        maxDuration: TimeInterval = Self.defaultTimeout,
        useCache: Bool = true // for testing
    ) {
        self.difficulty = difficulty
        self.maxDuration = maxDuration
        self.magic = magic
        self.useCache = useCache
    }
}
 
public extension HashPOWWorker {
    init(
        difficulty: POW.Difficulty = Self.defaultDifficulty,
        magic: POW.Magic?,
        maxDuration: TimeInterval = Self.defaultTimeout
    ) {
        self.init(
            difficulty: difficulty,
            magic: magic,
            maxDuration: maxDuration,
            useCache: true
        )
    }
}

// MARK: - Error
// MARK: -
public extension HashPOWWorker {
    enum Error: Swift.Error {
        case timeout
    }
}

// MARK: - POWWorker
// MARK: -
public extension HashPOWWorker {

    func pow(data: Data) async throws -> POW {
        let actor = POWActor<H>(
            input: data,
            magic: magic,
            deadline: Date().addingTimeInterval(maxDuration),
            difficulty: difficulty,
            useCache: useCache
        )
        
        return try await actor.work()
    }
    
    func verify(pow: POW) -> Bool {
        let data = pow.magic.map { Data($0.bytes() + pow.input) } ?? pow.input
        let output = hash(data: data, concatenatedWithNonce: pow.nonce)
        guard output == pow.output else { return false }
        return output.leadingZeroBitCount() >= pow.difficulty
    }
}

// MARK: - Private
// MARK: -
private extension HashPOWWorker {

    func hash(data: Data) -> Data {
        Data(H.hash(data: data))
    }

    func hash(
        data: Data,
        concatenatedWithNonce nonce: POW.Nonce
    ) -> Data {
        let nonceData = Data(nonce.bytes(endianess: .big))
        assert(nonceData.count == 8)
        return hash(data: data + nonceData)
    }
}
