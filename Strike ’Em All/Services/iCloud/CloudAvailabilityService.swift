//
//  CloudAvailabilityService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/10/25.
//

import CloudKit
import Combine

protocol CloudAvailabilityChecking {
    func iCloudAvailability() -> AnyPublisher<Bool, Never>
}

final class CloudAvailabilityService: CloudAvailabilityChecking {
    private let container: CKContainer
    
    init(container: CKContainer = .default()) {
        self.container = container
    }
    
    func iCloudAvailability() -> AnyPublisher<Bool, Never> {
        Deferred {
            Future<Bool, Never> { promise in
                self.container.accountStatus { status, _ in
                    let available = (status == .available)
                    FileLogger.shared.log("iCloudAvailability changed: \(available)", level: .info)
                    promise(.success(available))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
