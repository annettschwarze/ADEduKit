//
//  Facade.swift
//  ADEduKit
//
//  Created by Schwarze on 17.12.21.
//

import Foundation

/**
 Main entry point for users of this framework.
 */
@objc @objcMembers
public class Facade: NSObject {
    public static let sharedInstance = Facade()

    let _containerRepo = ContainerRepoImpl()

    public func repo() -> ContainerRepo {
        return _containerRepo
    }

    public func defaultContextProviderFor(container: Container) -> DefaultCLSContextProvider {
        return DefaultCLSContextProviderImpl(container: container)
    }
}
