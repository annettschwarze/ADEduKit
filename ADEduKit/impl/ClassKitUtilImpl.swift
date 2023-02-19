//
//  ClassKitUtilImpl.swift
//  ADEduKit
//
//  Created by Schwarze on 22.12.21.
//

import Foundation
import ClassKit
import UIKit

class ClassKitUtilImpl: ClassKitUtil {
    var _container: ContainerImpl
    let scoreIsPrimary: Bool = true
    
    init(container: ContainerImpl) {
        _container = container
        super.init()
    }

    override public func contextTypeForModel(model: ModelNode) -> CLSContextType {
        var rc : CLSContextType = .chapter
        switch model.type() {
        case ModelNodeImpl.typeMetagroup:
            rc = .chapter
        case ModelNodeImpl.typeGroup:
            rc = .chapter
        case ModelNodeImpl.typeTask:
            rc = .task
        default:
            rc = .chapter
        }
        Log.log("contexttype = \(rc)")
        return rc
    }

    override public func contextTopicForModel(model: ModelNode) -> CLSContextTopic {
        switch model.topic() {
        case ModelNodeImpl.topicMusic:
            return .artsAndMusic
        case ModelNodeImpl.topicMath:
            return .science
        case ModelNodeImpl.topicPhysics:
            return .science
        default:
            return .science
        }
    }

    override func createContext(forIdentifier identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? {
        guard let model = _container.rootModelNode() else {
            Log.log("\(#function): error retrieving root model object")
            return nil
        }
        // The method is called as delegate on the root node. If this is the case, find the actual node depending on the parentIdentifierPath. Other scenarios call the core_ variant on the correct node instance.
        var node = model
        let _root = model.root()
        if identifier == _root.identifier() {
            Log.log("\(#function): detected root id")
        }
        let selfParentPath = node.identifierPath()
        if selfParentPath == parentIdentifierPath {
            Log.log("\(#function): parent paths match")
        } else {
            Log.log("\(#function): parent paths do not match - finding node (\(selfParentPath) != \(parentIdentifierPath)")
            var lookupPath = parentIdentifierPath;
            if _root.identifier() == lookupPath.first {
                // Path starts with root id, remove that
                lookupPath = Array(lookupPath[1...])
            }
            if let n = _root.modelAt(path: lookupPath) {
                Log.log("\(#function): found node \(n.identifier())")
                node = n
            } else {
                Log.log("\(#function): error finding node for lookupPath \(lookupPath)")
            }
        }

        var core_path = parentIdentifierPath
        if core_path.first == _root.identifier() {
            Log.log("\(#function): removing leading root id from path (\(core_path))")
            core_path = Array(core_path[1...])
        }
        let result = core_createContextFor(identifier: identifier, parentContext: parentContext, parentIdentifierPath: core_path)
        return result
    }

    /*
     identifier             : child-1
     parentIdentifierPath   : []

     identifier             : child-1-1
     parentIdentifierPath   : ["child-1"]

     - need to find the node, which matches the identifier
     - find the node relative to root for the parentIdentifierPath
     - find the child matching the identifier
     - fill with data
     */
    override public func core_createContextFor(identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? {
        Log.log("\(#function): identifier=\(identifier) parentIdentifierPath=\(parentIdentifierPath)")
        guard let model = _container.rootModelNode() else {
            Log.log("\(#function): error retrieving root model object")
            return nil
        }
        let rootNode = model.root()
        var node = rootNode.modelAt(path: parentIdentifierPath)
        let children = node?.children()
        if let childNode = children?.first(where: { $0.identifier() == identifier }) {
            node = childNode
        }
        guard let node = node else {
            return nil
        }

        let title = node.localizedTitle()
        let summary = node.localizedSummary()
        let contextType = contextTypeForModel(model: node)

        let context = CLSContext(type: contextType, identifier: identifier, title: title)
        // context.topic = .artsAndMusic
        context.topic = contextTopicForModel(model: model)
        if #available(iOS 13.4, *) {
            context.summary = summary;
        }
        if #available(iOS 14, *) {
            context.isAssignable = context.type == .task
        }

        if #available(iOS 13.4, *) {
            if let thnprv = thumbnailProvider {
                let img = thnprv.classKitUtilThumbnailImage(identifier: identifier, parentIdentifierPath: parentIdentifierPath)
                if let img = img {
                    context.thumbnail = img.cgImage
                }
            }
        } else {
            // nothing to be done without the thumbnail property
        }

        let scheme = _container.metadata()?.scheme() ?? AppConfig.ADEduKitScheme
        let url = node.url(scheme: scheme)
        context.universalLinkURL = url

        return context
    }

    override public func core_updateContext(context: CLSContext, model: ModelNode) -> Bool {
        var updated = false
        let contextType = contextTypeForModel(model: model)
        if context.type != contextType {
            if #available(iOS 14, *) {
                context.setType(contextType)
                updated = true
            }
        }
        let locTitle = model.localizedTitle()
        if context.title != locTitle {
            context.title = locTitle
            updated = true
        }
        if #available(iOS 13.4, *) {
            let locSum = model.localizedSummary()
            if context.summary != locSum {
                context.summary = locSum
                updated = true
            }
        }
        let url = model.url(scheme: _container.metadata()?.scheme() ?? AppConfig.ADEduKitScheme)
        if context.universalLinkURL != url {
            context.universalLinkURL = url
            updated = true
        }
        let idValue = model.identifier()
        if context.identifier != idValue {
            Log.log("\(#function): identifiers do not match (context \(context.identifier) vs node \(idValue)")
        }
        // FIXME: update thumbnail if necessary (how to detect that?, update always?)
        return updated
    }

    public override func setupContext(model: ModelNode) {
        CLSDataStore.shared.delegate = self
        createContexts(model: model)
    }

    public func createContexts(model: ModelNode) {
        // Don't create contexts for root
        if let _ = model.parent() {
            Self.createContextForModel(model: model)
        }
        let children = model.children()
        for chNode in children {
            createContexts(model: chNode)
        }
    }

    static func createContextForModel(model: ModelNode) {
        let path = model.identifierPath()
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: path) { context, error in
            Log.log("\(#function): CLSDataStore - path \(path) - error \(String(describing: error))")
        }
    }

    override public func startActivityForModel(model: ModelNode) {
        let path = model.identifierPath()
        startActivityForPath(path: path)
    }

    public func startActivityForPath(path: [String]) {
        Log.log("\(#function): startActivity for path = \(path)")
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: path) { context, error in
            context?.becomeActive()
            var act = context?.currentActivity
            if act == nil {
                act = context?.createNewActivity()
            }
            if !(act?.isStarted ?? true) {
                act?.start()
            }
            CLSDataStore.shared.save { error in
                Log.log("\(#function): error = \(String(describing: error))")
            }
        }
    }

    override public func stopActivityForModel(model: ModelNode) {
        let path = model.identifierPath()
        stopActivityForPath(path: path)
    }

    public func stopActivityForPath(path: [String]) {
        Log.log("\(#function): stopActivity for path = \(path)")
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: path) { context, error in
            context?.becomeActive()
            var act = context?.currentActivity
            if act == nil {
                act = context?.createNewActivity()
            }
            if act?.isStarted ?? false {
                act?.stop()
            }
            context?.resignActive()
            CLSDataStore.shared.save { error in
                Log.log("\(#function): error = \(String(describing: error))")
            }
        }
    }

    override public func updateActivityForModel(model: ModelNode, progress: Double, score: Int, maxScore: Int) {
        let path = model.identifierPath()
        updateActivityForPath(path: path, progress: progress, score: score, maxScore: maxScore)
    }

    public func updateActivityForPath(path: [String], progress: Double, score: Int, maxScore: Int) {
        Log.log("\(#function): updateActivity for path = \(path)")
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: path) { context, error in
            guard let act = context?.currentActivity else {
                Log.log("\(#function): context has no activity to update. path=\(path)")
                return
            }
            if progress > act.progress {
                act.addProgressRange(fromStart: 0.0, toEnd: progress)
            }
            var scoreItem: CLSScoreItem?

            if self.scoreIsPrimary {
                scoreItem = act.primaryActivityItem as? CLSScoreItem
            } else {
                let items = act.additionalActivityItems
                for item in items {
                    if item.identifier == "score" {
                        scoreItem = item as? CLSScoreItem
                    }
                }
            }
            if scoreItem == nil {
                scoreItem = CLSScoreItem(identifier: "score", title: "Score", score: Double(score), maxScore: Double(maxScore))
                if self.scoreIsPrimary {
                    act.primaryActivityItem = scoreItem
                } else {
                    act .addAdditionalActivityItem(scoreItem!)
                }
            } else {
                scoreItem?.score = Double(score)
                scoreItem?.maxScore = Double(maxScore)
            }
            if progress >= 1.0 {
                act.stop()
                context?.resignActive()
                CLSDataStore.shared.completeAllAssignedActivities(matching: path)
            }
            CLSDataStore.shared.save { error in
                Log.log("\(#function): error = \(String(describing: error))")
            }
        }
    }
}
