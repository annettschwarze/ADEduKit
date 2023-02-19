//
//  ADEduKitAPI.swift
//  ADEduKit
//
//  Created by Schwarze on 17.12.21.
//

import Foundation
import ClassKit
import OSLog
import UIKit // for UIImage

/**
 Matches a ClassKit context.
 */
@objc @objcMembers
public class ModelNode: NSObject {
    public func url(scheme: String) -> URL? { return nil }
    public func parent() -> ModelNode? { return nil }
    public func children() -> [ModelNode] { return [] }
    public func identifier() -> String { return "" }
    public func root() -> ModelNode { return self }
    public func identifierPath() -> [String] { return [] }

    public func title() -> String { return "" }
    public func summary() -> String { return "" }
    public func type() -> String { return "" }
    public func topic() -> String { return "" }
    public func localizedTitle() -> String { return "" }
    public func localizedSummary() -> String { return "" }

    public func modelAt(path: [String], absolute: Bool = false) -> ModelNode? { return nil }
    public func rootRelativeIdentifierPath() -> [String] { return [] }

    public func deepList() -> [ModelNode] { return [] }

    public func allLangs() -> [String] { return [] }
    public func allKeys() -> [String] { return [] }

    public func localStringValueForKey(key: String, lang: String) -> String? { return nil }
    public func remoteStringValueForKey(key: String, lang: String) -> String? { return nil }
    public func setRemoteStringValue(value: String, key: String, lang: String) { }

    public func localValueForKey(key: String, lang: String) -> Any? { return nil }
}
/**
 Meta information about a set of model objects.
 */
@objc @objcMembers
public class Metadata: NSObject {
    public func identifier() -> String { return "" }
    public func scheme() -> String { return "" }
    public func keywords() -> [String] { return [] }
    public func allLangs() -> [String] { return [] }
    public func allKeys() -> [String] { return [] }

    public func thumbnailFor(thumbnailId: String?, identifier: String) -> String? { return nil }
}
/**
 Represents a set of model objects and the meta data for it.
 */
@objc @objcMembers
public class Container: NSObject {
    public func modelName() -> String { return "" }
    public func rootModelNode() -> ModelNode? { return nil }
    public func metadata() -> Metadata? { return nil }
    public func classKitUtil() -> ClassKitUtil? { return nil }

    public func setDefaultLang(lang: String) { }
    public func getDefaultLang() -> String? { return nil }
}
/**
 A repository of registered containers.
 */
@objc @objcMembers
public class ContainerRepo: NSObject {
    public func containerNames() -> [String] { return [] }
    public func containerForName(name: String) -> Container? { return nil }
    public func registerContainerName(name: String) -> Bool { return false }
}

/**
 Keys for provider info dictionary.
 */
// Rawtype Int only for @objc use
@objc
public enum ContainerProviderKeys: Int {
    case modelURL
    case metaURL
    case json
}

@objc @objcMembers
public class ContainerProvider: NSObject {
    public func containerNames() -> [String] { return [] }
    public func containerSpecFor(name: String) -> [ContainerProviderKeys: Any] { return [:] }
}

@objc
protocol ClassKitUtilThumbnailProvider: AnyObject {
    @objc func classKitUtilThumbnailImage(identifier: String, parentIdentifierPath: [String]) -> UIImage?
}

@objc @objcMembers
public class ClassKitUtil: NSObject, CLSDataStoreDelegate {
    weak var thumbnailProvider: ClassKitUtilThumbnailProvider?
    
    public func createContext(forIdentifier identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? { return nil }
    public func core_createContextFor(identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? { return nil }
    public func contextTypeForModel(model: ModelNode) -> CLSContextType { return .chapter }

    // Main initializer from within apps:
    public func setupContext(model: ModelNode) { }


    // FIXME: select a proper default topic:
    public func contextTopicForModel(model: ModelNode) -> CLSContextTopic { return .artsAndMusic }
    public func core_updateContext(context: CLSContext, model: ModelNode) -> Bool { return false }

    // MARK: - context update methods
    public func updateActivityForModel(model: ModelNode, progress: Double, score: Int, maxScore: Int) { }
    public func stopActivityForModel(model: ModelNode) { }
    public func startActivityForModel(model: ModelNode) { }
}

// FIXME: check whether AppConfig could be renamed to Config
// FIXME: although AppConfig is marked as objc etc., it cannot be used in objc projects. Check that.
@objc @objcMembers
open class AppConfig: NSObject {
    /** A default scheme used, if no other is specified */
    static let ADEduKitScheme = "adedukit"
    override public init() { }
    open func standardContainerName() -> String { return AppConfig.ADEduKitScheme }
    open func standardScheme() -> String { return AppConfig.ADEduKitScheme }
}

@objc @objcMembers
public class ProgressState: NSObject {
    public private(set) var taskIndex: Int = 0
    public private(set) var taskCount: Int = 0
    public private(set) var taskCorrect: Int = 0

    public private(set) var tasksInitial: Bool = false
    public private(set) var tasksDone: Bool = false

    public var progress : Double {
        get {
            return (taskCount > 0) ? Double(max(taskIndex, 0)) / Double(taskCount) : 0.0
        }
    }

    public var score : Int {
        get {
            return (taskCorrect >= 0) ? taskCorrect : 0;
        }
    }

    public var maxScore : Int {
        get {
            return taskCount;
        }
    }

    override public init() {
        os_log(.info, "\(#function)")
        self.taskIndex = -1
        self.taskCount = 0
        self.taskCount = 0
    }

    public init(taskIndex: Int, taskCount: Int, taskCorrect: Int) {
        os_log(.info, "\(#function)")
        self.taskIndex = taskIndex
        self.taskCount = taskCount
        self.taskCorrect = taskCorrect
    }

    public func isValid(index: Int) -> Bool {
        if index >= 0 && index < taskCount {
            return true
        } else {
            return false
        }
    }

    public func hasNext() -> Bool {
        if taskCount == 0 {
            return false
        }
        if taskIndex == -1 {
            return true
        } else if taskIndex < taskCount {
            return true
        }
        return false
    }

    public func hasPrev() -> Bool {
        if taskCount == 0 {
            return false
        }
        if taskIndex > 0 {
            return true
        }
        return false
    }

    public func selectNext() -> Bool {
        if taskIndex == -1 {
            tasksInitial = true
            taskIndex = 0
            return true
        } else if taskIndex < taskCount {
            taskIndex += 1
            if taskIndex == taskCount {
                tasksDone = true
            }
            return true
        }
        return false
    }

    public func selectPrev() -> Bool {
        if taskIndex > 0 {
            taskIndex -= 1
            return true
        }
        return false
    }
}

@objc @objcMembers
public class DefaultCLSContextProvider: NSObject, CLSContextProvider {
    public func updateDescendants(of context: CLSContext, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}
