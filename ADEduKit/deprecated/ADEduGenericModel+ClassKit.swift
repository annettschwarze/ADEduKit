//
//  ADEduGenericModel+ClassKit.swift
//  ADEduKit
//
//  Created by Schwarze on 12.12.21.
//

import Foundation
import ClassKit
import UIKit

extension ADEduGenericModel: CLSDataStoreDelegate {
    public func contextType() -> CLSContextType {
        switch type {
        case "group", "metagroup", nil:
            return .chapter
        case "task":
            return .task
        default:
            return .task
        }
    }

    public func createContext(forIdentifier identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? {
        // The method is called as delegate on the root node. If this is the case, find the actual node depending on the parentIdentifierPath. Other scenarios call the core_ variant on the correct node instance.
        var node = self
        let _root = root()
        if identifier == _root.identifier {
            Log.log("\(#function): returning nil for root id")
            return nil
        }
        let selfParentPath = identifierPath()
        if selfParentPath == parentIdentifierPath {
            Log.log("\(#function): parent paths match")
        } else {
            Log.log("\(#function): parent paths do not match - finding node")
            var lookupPath = parentIdentifierPath;
            if _root.identifier == lookupPath.first {
                // Path starts with root id, remove that
                lookupPath = Array(lookupPath[1...])
            }
            if let n = _root.modelAt(path: lookupPath) {
                node = n
            } else {
                Log.log("\(#function): could not find node for lookupPath \(lookupPath)")
            }
        }

        var core_path = parentIdentifierPath
        if core_path.first == _root.identifier {
            Log.log("\(#function): removing leading root id from path")
            core_path = Array(core_path[1...])
        }
        return node.core_createContextFor(identifier: identifier, parentContext: parentContext, parentIdentifierPath: core_path)
    }

    public func core_createContextFor(identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? {
        Log.log("\(#function): identifier=\(identifier) parentIdentifierPath=\(parentIdentifierPath)")
        var pip = parentIdentifierPath
        let rootNode = root()
        if parentIdentifierPath.first == rootNode.identifier {
            pip = Array(parentIdentifierPath[1...])
            Log.log("\(#function): detected root identifier in parent path. adjusting path to: \(pip)")
            return nil
        }

        let parentPath = rootRelativeIdentifierPath()
        if parentPath == parentIdentifierPath {
            Log.log("\(#function): parentIdentifierPath matches")
        } else {
            Log.log("\(#function): parentIdentifierPath does not match: self.parent=\(parentPath), specified=\(parentIdentifierPath)")
        }
        var node : ADEduGenericModel? = nil

        if identifier == rootNode.identifier {
            node = rootNode
        } else {
            let children = children()
            let matchingNode = children.first { m in
                return m.identifier == identifier
            }
            if let mn = matchingNode {
                node = mn
            } else {
                Log.log("\(#function): did not find child with id \(identifier)")
                return nil
            }
        }

        let title = node?.localizedTitle() ?? "(no title)"
        let summary = node?.localizedSummary() ?? "(no summary)"
        let context = CLSContext(type: node!.contextType(), identifier: identifier, title: title)
        context.topic = .artsAndMusic
        // summary is only available since 13.4
        if #available(iOS 13.4, *) {
            context.summary = summary;
        }
        if #available(iOS 14, *) {
            context.isAssignable = context.type == .task
        }

        if #available(iOS 13.4, *) {
            let thnMap = [
                "notes": "TaskIcon_Notes",
                "rests": "TaskIcon_Rests",
                "rests-easy": "TaskIcon_GClefRests",
                "rests-diff": "TaskIcon_GClefRests2",
                "notes-gclef-easy": "TaskIcon_GClefNotes",
                "notes-gclef-diff": "TaskIcon_GClefNotes2",
                "notes-fclef-easy": "TaskIcon_FClefNotes",
                "notes-fclef-diff": "TaskIcon_FClefNotes2",
                "scales": "TaskIcon_Scales",
                "scales-easy": "TaskIcon_Scales",
                "scales-diff": "TaskIcon_Scales",
                "scale-*": "TaskIcon_Scales",
            ]
            var thnStr = thnMap[identifier]
            if identifier.hasPrefix("scale-") {
                thnStr = thnMap["scale-*"]
            }
            if let thnS = thnStr {
                context.thumbnail = UIImage(named: thnS)!.cgImage
            } else {

            }
        } else {
            // nothing to be done without the thumbnail property
        }

        let url = node?.url()
        context.universalLinkURL = url

        return context
    }

    public func core_updateContext(context: CLSContext) -> Bool {
        var updated = false
        if context.type != contextType() {
            if #available(iOS 14, *) {
                context.setType(contextType())
                updated = true
            }
        }
        if context.title != localizedTitle() {
            context.title = localizedTitle() ?? ""
            updated = true
        }
        if #available(iOS 13.4, *) {
            if context.summary != localizedSummary() {
                context.summary = localizedSummary() ?? ""
                updated = true
            }
        }
        if context.universalLinkURL == url() {
            context.universalLinkURL = url()
            updated = true
        }
        if context.identifier != identifier {
            Log.log("\(#function): identifiers do not match (context \(context.identifier) vs node \(identifier ?? "")")
        }
        // FIXME: update thumbnail if necessary (how to detect that?, update always?)
        return updated
    }

    public func setupContext() {
        let _root = root()
        CLSDataStore.shared.delegate = _root
        _root.createContexts()
    }

    public func createContexts() {
        // Don't create contexts for root
        if parent != nil {
            ADEduGenericModel.createContextForNode(node: self)
        }
        let children = children()
        for chNode in children {
            chNode.createContexts()
        }
    }

    static func createContextForNode(node: ADEduGenericModel) {
        let path = node.identifierPath()
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: path) { context, error in
            Log.log("\(#function): CLSDataStore - path \(path) - error \(String(describing: error))")
        }
    }

    public static func startActivityForNode(node: ADEduGenericModel) {
        let path = node.identifierPath()
        startActivityForPath(path: path)
    }

    public static func startActivityForPath(path: [String]) {
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

    public static func stopActivityForNode(node: ADEduGenericModel) {
        let path = node.identifierPath()
        stopActivityForPath(path: path)
    }

    public static func stopActivityForPath(path: [String]) {
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

    public static func updateActivityForNode(node: ADEduGenericModel, progress: Double, score: Int, maxScore: Int) {
        let path = node.identifierPath()
        updateActivityForPath(path: path, progress: progress, score: score, maxScore: maxScore)
    }

    public static func updateActivityForPath(path: [String], progress: Double, score: Int, maxScore: Int) {
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: path) { context, error in
            guard let act = context?.currentActivity else {
                Log.log("\(#function): context has no activity to update. path=\(path)")
                return
            }
            if progress > act.progress {
                act.addProgressRange(fromStart: 0.0, toEnd: progress)
            }
            var scoreItem: CLSScoreItem?
            let scoreIsPrimary: Bool = true
            if scoreIsPrimary {
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
                if scoreIsPrimary {
                    act.primaryActivityItem = scoreItem
                } else {
                    act.addAdditionalActivityItem(scoreItem!)
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
