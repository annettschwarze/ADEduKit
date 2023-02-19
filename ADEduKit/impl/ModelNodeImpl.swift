//
//  ModelNodeImpl.swift
//  ADEduKit
//
//  Created by Schwarze on 18.12.21.
//

import Foundation

class ModelNodeImpl: ModelNode, ModelNodeDataImplDelegate {
    let _data: ModelNodeDataImpl
    let _remoteData: ModelNodeDataImpl
    // Keys to use for the main properties:
    static let titleKey = "title"
    static let typeKey = "type"
    static let topicKey = "topic"
    static let summaryKey = "summary"
    static let idKey = "id"
    static let childrenKey = "children"

    static let typeMetagroup = "metagroup"
    static let typeGroup = "group"
    static let typeTask = "task"

    static let topicMusic = "music"
    static let topicMath = "math"
    static let topicPhysics = "physics"

    var _children: [ModelNodeImpl] = []
    var _parent: ModelNodeImpl? = nil
    var _identifier: String? = nil
    var _type: String? = nil
    var _topic: String? = nil
    var _identifierPath: [String]? = nil
    var _rootRelativeIdentifierPath: [String]? = nil
    var _title: String? = nil
    var _summary: String? = nil

    var _defaultLang: String? = nil

    init(data: ModelNodeDataImpl) {
        _data = data
        _remoteData = ModelNodeDataImpl()
        super.init()
        _data._delegate = self
    }

    override public func url(scheme: String) -> URL? {
        // FIXME: url from components?
        let path = identifierPath()
        let pathStr = path.joined(separator: "/")
        let urlStr = "\(scheme)://\(pathStr)"
        return URL(string: urlStr)
    }

    override func parent() -> ModelNode? {
        return _parent
    }

    override func children() -> [ModelNode] {
        return _children
    }

    override func identifier() -> String {
        return _identifier ?? ""
    }

    override func root() -> ModelNode {
        return _parent?.root() ?? self
    }

    override func identifierPath() -> [String] {
        if let p = _identifierPath {
            return p
        }
        let parentPath = _parent?.identifierPath() ?? []
        let idp = parentPath + [identifier()]
        _identifierPath = idp
        return idp
    }

    override public func deepList() -> [ModelNode] {
        var result = [ModelNode]()

        func walk(node: ModelNodeImpl) {
            // Log.log("\(#function): walk: id=\(node.identifier())")
            result.append(node)
            for childNode in node._children {
                walk(node: childNode)
            }
        }

        walk(node: self)

        return result
    }

    override func title() -> String {
        return _title ?? ""
    }

    override func summary() -> String {
        return _summary ?? ""
    }

    override public func type() -> String {
        return _type ?? ""
    }

    override public func topic() -> String {
        return _topic ?? ""
    }

    override public func localizedTitle() -> String {
        return _data._localValueStringFor(key: Self.titleKey, locale: getRootDefaultLang() ?? "") ?? ""
    }

    override public func localizedSummary() -> String {
        return _data._localValueStringFor(key: Self.summaryKey, locale: getRootDefaultLang() ?? "") ?? ""
    }

    func setDefaultLang(lang: String) {
        _defaultLang = lang
    }

    func getDefaultLang() -> String? {
        return _defaultLang
    }

    func getRootDefaultLang() -> String? {
        return (root() as! ModelNodeImpl).getDefaultLang()
    }

    override func allLangs() -> [String] {
        return _data._allLocales()
    }

    override func allKeys() -> [String] {
        return _data._allKeys()
    }

    // MARK: - value access

    override func localStringValueForKey(key: String, lang: String) -> String? {
        return _data._localValueStringFor(key: key, locale: lang)
    }

    override func remoteStringValueForKey(key: String, lang: String) -> String? {
        return _remoteData._localValueStringFor(key: key, locale: lang)
    }

    override func setRemoteStringValue(value: String, key: String, lang: String) {
        // FIXME: implement setting value in remoteData store
    }

    override func localValueForKey(key: String, lang: String) -> Any? {
        return _data.dataValueFor(key: key, locale: lang)
    }

    // MARK: - parse delegates

    func parse(key: String, value: Any) -> Bool {
        switch value {
        case let a as NSArray:
            if key != Self.childrenKey {
                return true
            }
            for _el in a {
                guard let el = _el as? [String: Any] else { continue }
                let child = ModelNodeImpl(data: ModelNodeDataImpl())
                self._children.append(child)
                child._parent = self
                child._data.parse(dict: el)
            }
            return false
        default:
            if key == Self.idKey, let str = value as? String {
                self._identifier = str
            }
            if key == Self.typeKey, let str = value as? String {
                self._type = str
            }
            if key == Self.topicKey, let str = value as? String {
                self._topic = str
            }
            if key == Self.titleKey, let str = value as? String {
                self._title = str
            }
            if key == Self.summaryKey, let str = value as? String {
                self._summary = str
            }
        }
        return true
    }

    func parseItemDone() {

    }

    func parseDone() {
        // parent relations are established, prepare identifierPath
        _ = identifierPath()
    }

    // MARK: - Node tree API

    override public func modelAt(path: [String], absolute: Bool = false) -> ModelNode? {
        var path = path
        // path may contain a leading "/" - if it does, remove it
        if let f = path.first {
            if f == "/" {
                path = Array(path.suffix(from: 1))
            }
        }
        if absolute {
            let root = root()
            guard let first = path.first else {
                return self
            }
            if first != root.identifier() {
                Log.log("\(#function): root id of path does not match, ignoring (first=\(first), root.identifier=\(root.identifier())")
            } else {
                // remove root id
                path = Array(path.suffix(from: 1))
            }
            return root.modelAt(path: path)
        }
        if path.count == 0 {
            return self
        }
        let key = path.first
        let rem = path[1...]
        let _index = _children.firstIndex(where: { $0.identifier() == key })
        guard let index = _index else { return nil }
        let del = _children[index]
        return del.modelAt(path: Array(rem))
    }

    override public func rootRelativeIdentifierPath() -> [String] {
        if let p = _rootRelativeIdentifierPath {
            return p
        }
        guard let par = _parent else {
            let p : [String] = []
            _rootRelativeIdentifierPath = p
            return p
        }
        let p = par.rootRelativeIdentifierPath() + [identifier()]
        _rootRelativeIdentifierPath = p
        return p
    }
}
