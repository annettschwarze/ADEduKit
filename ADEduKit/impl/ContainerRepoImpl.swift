//
//  ContainerRepoImpl.swift
//  ADEduKit
//
//  Created by Schwarze on 18.12.21.
//

import Foundation

class ContainerRepoImpl: ContainerRepo {
    var _containerNames = ["dummy"]
    var _containers: [String: Container] = [:]

    override init() {
    }

    override func containerNames() -> [String] {
        return _containerNames
    }

    override func containerForName(name: String) -> Container? {
        if let c = _containers[name] {
            return c
        }
        let c = ContainerImpl(name: name)
        _containers[name] = c
        return c
    }

    override public func registerContainerName(name: String) -> Bool {
        if _containerNames.contains(name) {
            return false
        }
        _containerNames.append(name)
        return true
    }
}
