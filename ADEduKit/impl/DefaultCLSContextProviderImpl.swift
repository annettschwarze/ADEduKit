//
//  DefaultCLSContextProviderImpl.swift
//  ADEduKit
//
//  Created by Schwarze on 25.12.21.
//

import Foundation
import ClassKit

class DefaultCLSContextProviderImpl: DefaultCLSContextProvider {
    let _container: Container
    static let errorDomain = "ADEduKit"

    init(container: Container) {
        _container = container
    }

    /**
     Creates child contexts for the given context. Note that the completion handler should be called as early as possible.
     */
    override func updateDescendants(of context: CLSContext, completion: @escaping (Error?) -> Void) {
        let error: Error? = nil

        let container = _container
        let model = container.rootModelNode()

        guard let rootNode = model else {
            let e = NSError(domain: Self.errorDomain, code: 1, userInfo: ["details": "No rootNode found"])
            completion(e)
            return
        }
        let idPath : [String] = context.identifierPath
        let subPath = Array(idPath[1...])
        guard let node = rootNode.modelAt(path: subPath) else {
            let e = NSError(domain: Self.errorDomain, code: 2, userInfo: ["details": "No node found at subpath \(subPath); identifierPath=\(idPath)"])
            completion(e)
            return
        }
        let children = node.children()

        guard let util = container.classKitUtil() else {
            let e = NSError(domain: Self.errorDomain, code: 3, userInfo: ["details": "No ClassKitUtil instance"])
            completion(e)
            return
        }
        // FIXME: run more tests, whether also children of mainAppContext reliably work here
        let mainAppContext = CLSDataStore.shared.mainAppContext
        let predicate = NSPredicate(format: "parent = %@", mainAppContext)
        CLSDataStore.shared.contexts(matching: predicate) { (contexts, error) in
            for childNode in children {
                Log.log("\(#function): checking \(String(describing: childNode.identifier))")
                let _childIndex = contexts.firstIndex(where: { $0.identifier == childNode.identifier() })
                if let childIndex = _childIndex {
                    // Exists
                    let childContext = contexts[childIndex]
                    if util.core_updateContext(context: childContext, model: childNode) {
                        Log.log("\(#function): core_updateContext returned true - context is updated now")
                    }
                } else {
                    // Does not exist
                    let childContext = util.core_createContextFor(identifier: childNode.identifier(), parentContext: context, parentIdentifierPath: subPath)
                    if childContext != nil {
                        Log.log("\(#function): adding child context \(String(describing: childContext)) path \(childContext!.identifierPath)")
                        context.addChildContext(childContext!)
                    }
                }
            }

            CLSDataStore.shared.save { error in
                Log.log("\(#function): context saved - error = \(String(describing: error))")
                Log.log("\(#function): calling completion block for enclosing updateDescendants()")
                completion(error)
            }
        }
    }
}
