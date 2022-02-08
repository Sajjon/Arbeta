//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-05.
//

import Foundation
@testable import Arbeta
import XCTest
import Crypto
import Shaman

final class POWTests: XCTestCase {
    
    func testSha256Twice() {
        let data = "Arbeta! Arbeta!".data(using: .utf8)!
        let singleHash = Data(SHA256.hash(data: data))
        let twice = Data(SHA256.hash(data: singleHash))
        let double = Data(SHA256TwiceHash.hash(data: data))
        XCTAssertEqual(double, twice)
        XCTAssertEqual(singleHash.hex, "a82a903dac3bae747a4fe2d4e427dc73eec25efca6823a079949aa0317dec3e2")
        XCTAssertEqual(double.hex, "bc3e4bbaaefcbba2fad0107b93f235961f864c953a2ddbe9df30659cac9c664b")
    }
  
    func testPOWNonce9K() async throws {
        try await doTest(hash: SHA256TwiceHash.self, difficulty: 14, expectedNonce: 9255, magic: 12345)
    }

    func testPOWNonce500KPerformance() async throws {
        let vector = sha256TwiceVectors[0]
        let iterationCount = 10
        
        @discardableResult
        func doTest(
            useCache: Bool = true
        ) async throws -> CFAbsoluteTime {
            try await doTestVector(vector, hash: SHA256TwiceHash.self, printExecutionTime: false, useCache: useCache, iterations: iterationCount)
        }
        
        let withCache = try await doTest(useCache: true)
        let withoutCache = try await doTest(useCache: false)
        func printTime(_ time: CFAbsoluteTime, usedCache: Bool) {
            print(String(format: "✨✅ PoW usedCache=\(usedCache) took %.2fs (#\(iterationCount)iterations).", time))
        }
        printTime(withCache, usedCache: true)
        printTime(withoutCache, usedCache: false)
        XCTAssertLessThan(withCache, withoutCache)
    }

    func skipped_testSha256TwiceVectorsWithHighDifficulty() async throws {
        for vector in sha256TwiceVectors {
            try await doTestVector(vector, hash: SHA256TwiceHash.self)
        }
    }
    
    func testSha256InceVectorsWithHighDifficulty() async throws {
        for vector in sha256OnceVectors {
            try await doTestVector(vector, hash: Shaman256.self)
        }
    }
    
    func skip_testGenerateVectorsSha256Once() async throws {
        
        func randomData() -> Data {
            let bytesCount = 32
            var randomBytes = [UInt8](repeating: 0x00, count: bytesCount)
            
            guard SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes) == 0 else {
                fatalError()
            }
            return Data(randomBytes)
        }
        
        @discardableResult
        func generateVector(difficulty: POW.Difficulty, targetNonce: POW.Nonce) async throws -> Vector {
            let worker = SHA256POWWorker(difficulty: difficulty, magic: nil, maxDuration: 600)
            while true {
                let input = randomData()
                let pow = try await worker.pow(data: input)
                if pow.nonce >= targetNonce {
                    let vector: Vector = (expectedResultingNonce: pow.nonce, seed: input.hex, magic: nil, difficulty: difficulty)
                    print("🔮 vector: \(String(describing: vector))")
                    return vector
                }
            }
        }
        
        try await generateVector(difficulty: 16, targetNonce: 500)
    }

}

private extension POWTests {
    
    @discardableResult
    func doTestVector<H: FastHashFunction>(
        _ vector: Vector,
        hash: H.Type,
        printExecutionTime: Bool = true,
        useCache: Bool = true,
        iterations: Int = 1,
        maxDurationPerIteration: TimeInterval = 5
    ) async throws -> CFAbsoluteTime {
        let start = CFAbsoluteTimeGetCurrent()
        var pow: POW!
        for _ in 0..<iterations {
            pow = try await doTest(
                hash: H.self,
                difficulty: vector.difficulty,
                expectedNonce: vector.expectedResultingNonce,
                maxDuration: maxDurationPerIteration,
                magic: vector.magic,
                seed: vector.seed,
                useCache: useCache
            )
        }
        
        let diff = CFAbsoluteTimeGetCurrent() - start
        if printExecutionTime {
            let iterationString = iterations == 1 ? "" : "(#\(iterations) iterations)"
            print(String(format: "✨✅ POW took %.2fs \(iterationString), difficulty=\(vector.difficulty) => nonce=\(pow.nonce).", diff))
        }
        return diff
    }
    
    @discardableResult
    func doTest<H: FastHashFunction>(
        hash: H.Type,
        difficulty: POW.Difficulty,
        expectedNonce: POW.Nonce,
        maxDuration: TimeInterval = 1,
        magic: Int32? = nil,
        seed seedHex: String = "deadbeef00000000deadbeef00000000deadbeef00000000deadbeef00000000",
        useCache: Bool = true,
        _ line: UInt = #line
    ) async throws -> POW {
                
        let worker = HashPOWWorker<H>(
            difficulty: difficulty,
            magic: magic,
            maxDuration: maxDuration,
            useCache: useCache
        )
        
        let pow = try await worker.pow(data: Data(hex: seedHex))
        XCTAssertEqual(pow.difficulty, difficulty, line: line)
        XCTAssertEqual(pow.nonce, expectedNonce, line: line)
        
        return pow
    }

}


private typealias Vector = (
    expectedResultingNonce: POW.Nonce,
    seed: String,
    magic: Int32?,
    difficulty: POW.Difficulty
)

private let sha256OnceVectors: [Vector] = [
    (expectedResultingNonce: 13516, seed: "d480c8f2b171b25597deb7cb5be5540bc80442cf0c341d93233c66b467e3a269", magic: nil, difficulty: 16)
]

private let sha256TwiceVectors: [Vector] = [
    (
        expectedResultingNonce: 510190,
        seed: "887a9e87ecbcc8f13ea60dd732a3c115ea9478519ee3faac3be3ed89b4bbc535",
        magic: -1332248574,
        difficulty: 16
    ),
    (
        expectedResultingNonce: 322571,
        seed: "46ad4f54098f18f856a2ff05df25f5af587bd4f6dfc1e3b4cb406ceb25c61552",
        magic: -1332248574,
        difficulty: 16
    ),
    (
        expectedResultingNonce: 312514,
        seed: "f0f178d42ffe8fade8b8197782fd1ee72a4068d046d868806da7bfb1d0ffa7c1",
        magic: -1332248574,
        difficulty: 16
    ),
    (
        expectedResultingNonce: 311476,
        seed: "a33a90d0422aa12b68d1de6c53e83ca049ab82b06efeb03cf6731231e82470ef",
        magic: -1332248574,
        difficulty: 16
    ),
    (
        expectedResultingNonce: 285315,
        seed: "0519269eafbac3accba00cf6f7e93238aae1974a1e5439a58a6f53726a963095",
        magic: -1332248574,
        difficulty: 16
    ),
    (
        expectedResultingNonce: 270233,
        seed: "34931f7c0522352426d9d95f1c5527fafffce55b13082ae3723dc89f3c3e6276",
        magic: -1332248574,
        difficulty: 16
    )
]

