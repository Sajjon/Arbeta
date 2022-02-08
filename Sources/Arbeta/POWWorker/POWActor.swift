//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//


import Foundation
import CryptoKit
import Shaman

public extension POWActor {
    struct Config: Equatable {
        /// An optional number prepended to the input.
        public let magic: POW.Magic?
        
        /// The target number of leading zeros of the outputted hash of the work.
        public let difficulty: POW.Difficulty
        
        /// When by the latest we need this PoW, if the work is not done by then,
        /// a timeout error will be thrown.
        public let deadline: Date
        
        /// In normal cases this should be true, for testing purposes it might
        /// be set to false. If set to true, you will see a 10-50% performance
        /// boost at no cost. Can be set to false for testing purposes to evaluate
        /// this performance boost. Under the hood we will use cached state for
        /// HASH(inputData) using [Shaman][shaman]
        ///
        /// [shaman]: https://github.com/Sajjon/Shaman
        internal let useCache: Bool
        
        internal init(
            difficulty: POW.Difficulty,
            deadline: Date,
            magic: POW.Magic?,
            useCache: Bool = true
        ) {
            self.difficulty = difficulty
            self.deadline = deadline
            self.magic = magic
            self.useCache = useCache
        }
        
        public init(
            difficulty: POW.Difficulty,
            deadline: Date,
            magic: POW.Magic?
        ) {
            self.init(
                difficulty: difficulty,
                deadline: deadline,
                magic: magic,
                useCache: true
            )
        }
    }
    
    struct State {
        fileprivate var output = Data(repeating: 0x00, count: H.Digest.byteCount)
        
        /// Since perform HASH(data || nonce) for every
        /// nonce attempt, we can once perform HASH(data)
        /// and store that as a precomputed midstate that
        /// we init the hasher with before every attempted
        /// nonce, which works because:
        /// HASH(data || nonce) <=> HASH(data); HASH(nonce).
        fileprivate var cachedState: H.CachedState?

        fileprivate var nonce: POW.Nonce = 0
    }
}

/// An attempted run of a POW, with a deadline and a target difficulty.
public actor POWActor<H: FastHashFunction> {
    
    private let input: POW.Input
    private let config: Config
    private var hasher = H()
    private var state: State

    fileprivate init(
        input: POW.Input,
        config: Config,
        state: State = .init(),
        hasher: H = .init()
    ) {
        self.input = input
        self.config = config
        self.state = state
        self.hasher = hasher
    }
}

internal extension POWActor {
    convenience init(input orignalInput: Data, config: Config) {
        self.init(
            input: .init(
                original: orignalInput,
                used: config.magic.map { Data($0.bytes() + orignalInput) } ?? orignalInput
            ),
            config: config
        )
    }
    
    convenience init(
        input originalInput: Data,
        difficulty: POW.Difficulty,
        deadline: Date,
        magic: POW.Magic?,
        useCache: Bool = true
    ) {
        self.init(
            input: originalInput,
            config: .init(
                difficulty: difficulty,
                deadline: deadline,
                magic: magic,
                useCache: useCache
            )
        )
    }
}

public extension POWActor {
    convenience init(
        input originalInput: Data,
        difficulty: POW.Difficulty,
        deadline: Date,
        magic: POW.Magic?
    ) {
        self.init(
            input: originalInput,
            config: .init(
                difficulty: difficulty,
                deadline: deadline,
                magic: magic
            )
        )
    }
}

private extension POWActor {

    func initHasher() {
        
        if state.cachedState != nil {
            hasher.restore(cachedState: &state.cachedState!)
        } else if config.useCache {
            state.cachedState = hasher.updateAndCacheState(data: input.used, stateDescription: "input data")
        } else {
            hasher = H()
            hasher.update(data: input.used)
        }
    }
    
    func updateOutputByHashingNonce() {
        initHasher()

        withUnsafeBytes(of: state.nonce.bigEndian) { nonceBytes in
            hasher.update(bufferPointer: nonceBytes)
        }
        state.output.withUnsafeMutableBytes { target in
            hasher.finalize(to: target)
        }
    }
}

extension POWActor {
    func work() async throws -> POW {
        try await Task<POW, Swift.Error>(priority: .userInitiated) {
            while true {
                guard
                    Date() < config.deadline
                else {
                    throw SHA256TwicePOWWorker.Error.timeout
                }
                
                updateOutputByHashingNonce()
                
                if state.output.leadingZeroBitCount() >= config.difficulty {
                    return POW(
                        state: state,
                        config: config,
                        input: input
                    )
                } else {
                    state.nonce += 1
                }
            }
        }.value
    }
}

private extension POW {
    init<H: FastHashFunction>(
        state: POWActor<H>.State,
        config: POWActor<H>.Config,
        input: POW.Input
    ) {
        self.init(
            input: input,
            output: .init(
                nonce: state.nonce,
                output: state.output
            ),
            config: .init(
                difficulty: config.difficulty,
                magic: config.magic
            )
        )
    }
}
