//
//  GModel.swift
//  ADEduKitTool
//
//  Created by Schwarze on 24.08.21.
//

import UIKit

public protocol ADEduGenericModelDelegate: AnyObject {
    func gmodelDidUpdate(_ model: ADEduGenericModel)
}

@available(*, deprecated, message: "Use ModelNode instead")
public class ADEduGenericModel: ADEduGenericData {
    static let titleKey = "title"
    static let typeKey = "type"
    static let summaryKey = "summary"
    static let idKey = "id"
    static let childrenKey = "children"

    public weak var delegate: ADEduGenericModelDelegate? = nil
    public var opState: ADEduGenericModelOpState = .idle {
        didSet {
            notifyUpdated()
        }
    }

    private(set) public var identifier: String? = nil
    private(set) public var type: String? = nil

    var cached_identifierPath: [String]? = nil
    var cached_rootRelativeIdentifierPath: [String]? = nil
    var parent: ADEduGenericModel? = nil
    var _children: [ADEduGenericModel] = []
    var cached_deepList: [ADEduGenericModel]? = nil

    fileprivate var states = ADEduGenericModelStates()

    public func localizedTitle() -> String? {
        let locale = ADEduLocaleUtil.sharedInstance.currentLocale()
        return localValueStringFor(key: Self.titleKey, locale: locale)
    }

    public func localizedSummary() -> String? {
        let locale = ADEduLocaleUtil.sharedInstance.currentLocale()
        return localValueStringFor(key: Self.summaryKey, locale: locale)
    }

    public func url() -> URL? {
        let path = identifierPath()
        let pathStr = path.joined(separator: "/")
        let scheme = "FIXME-scheme"
        let urlStr = "\(scheme)://\(pathStr)"
        return URL(string: urlStr)
    }

    public func root() -> ADEduGenericModel {
        return parent?.root() ?? self
    }

    public func children() -> [ADEduGenericModel] {
        return _children
    }

    func notifyUpdated() {
        if let d = delegate {
            d.gmodelDidUpdate(self)
        }
    }

    public func add(state: ADEduGenericModelState, locale: String, op: String) {
        states.add(locale: locale, op: op, state: state)
        opState = state.ok() ? .ok : .failed
    }

    public func stateInfoFor(locale: String, op: String) -> ADEduGenericModelState? {
        return states.infoFor(locale: locale, op: op)
    }

    func fill(deepList: inout [ADEduGenericModel]) {
        deepList.append(self)
        for m in _children {
            m.fill(deepList: &deepList)
        }
    }

    public override func remoteValueStringFor(key: String, locale: String) -> String? {
        return nil
    }

    public func deepChildList() -> [ADEduGenericModel] {
        if cached_deepList == nil {
            var deepList = [ADEduGenericModel]()
            fill(deepList: &deepList)
            cached_deepList = deepList
        }
        return cached_deepList!
    }

    public func identifierPath() -> [String] {
        if cached_identifierPath == nil {
            var tmp : [String] = []
            if let p = parent {
                tmp.append(contentsOf: p.identifierPath())
            }
            tmp.append(identifier!)
            cached_identifierPath = tmp
        }
        return cached_identifierPath!
    }

    public func rootRelativeIdentifierPath() -> [String] {
        if cached_rootRelativeIdentifierPath == nil {
            var tmp : [String] = []
            if let p = parent {
                tmp.append(contentsOf: p.rootRelativeIdentifierPath())
            }
            tmp.append(identifier!)
            cached_rootRelativeIdentifierPath = tmp
        }
        return cached_rootRelativeIdentifierPath!
    }

    public func collapsedIdentifierPath() -> String {
        let ip = identifierPath()
        var cip = ip.map( { (el: String) -> String in
            return String(el.prefix(1))
        })
        _ = cip.popLast()
        cip.append(identifier!)
        return cip.joined(separator: ".")
    }

    public func modelAt(path: [String]) -> ADEduGenericModel? {
        if path.count == 0 {
            return self
        }
        let key = path.first
        let rem = path[1...]
        let _index = _children.firstIndex(where: { $0.identifier == key })
        guard let index = _index else { return nil }
        let del = _children[index]
        return del.modelAt(path: Array(rem))
    }

    public static func load(name: String) -> ADEduGenericModel? {
        let jsonName = name // + "_model"
        let dict = loadJson(name: jsonName)
        if let d = dict {
            let m = ADEduGenericModel()
            m.parse(dict: d)
            m.parseDone()
            return m
        } else {
            return nil
        }
    }

    public static func load(url: URL) -> ADEduGenericModel? {
        let dict = loadJson(url: url)
        if let d = dict {
            let m = ADEduGenericModel()
            m.parse(dict: d)
            m.parseDone()
            return m
        } else {
            return nil
        }
    }

    override func parse(key: String, value: Any) -> Bool {
        switch value {
        case let a as NSArray:
            if key != Self.childrenKey {
                return true
            }
            for _el in a {
                guard let el = _el as? [String: Any] else { continue }
                let child = ADEduGenericModel()
                self._children.append(child)
                child.parent = self
                child.parse(dict: el)
            }
            return false
        default:
            if key == Self.idKey {
                if let str = value as? String {
                    self.identifier = str
                }
            }
            if key == Self.typeKey {
                if let str = value as? String {
                    self.type = str
                }
            }
        }
        return true
    }

    override func parseItemDone() {
        
    }

    override func parseDone() {
        // parent relations are established prepare identifierPath
        _ = identifierPath()
    }
}
