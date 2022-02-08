//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-05.
//

import Foundation

public protocol POWWorker {
    func pow(data: Data) async throws -> POW
    func verify(pow: POW) -> Bool
}
