//
//  MetadataImpl.swift
//  ADEduKit
//
//  Created by Schwarze on 18.12.21.
//

import Foundation

class MetadataImpl: Metadata, ModelNodeDataImplDelegate {
    let _data: ModelNodeDataImpl

    var _identifier: String? = nil
    var _scheme: String? = nil
    var _keywords: [String] = []
    var _thumbnail_spec: [String: String] = [:]

    var _defaultLang: String? = nil

    init(data: ModelNodeDataImpl) {
        _data = data
        super.init()
        _data._delegate = self
    }

    override func identifier() -> String {
        return _identifier ?? ""
    }

    override func scheme() -> String {
        return _scheme ?? ""
    }

    override func keywords() -> [String] {
        return _keywords
    }

    func parse(key: String, value: Any) -> Bool {
        switch key {
        case "id": _identifier = value as? String ?? nil
        case "scheme": _scheme = value as? String ?? nil
        case "thumbnail_spec": _thumbnail_spec = value as? [String: String] ?? [:]
        case let k where k.hasPrefix("keywords"):
            _data.add(value: value, for: key)
            return false
        default:
            return true
        }
        return false
    }

    func parseItemDone() {
    }

    func parseDone() {
    }

    func setDefaultLang(lang: String) {
        _defaultLang = lang
    }

    func getDefaultLang() -> String? {
        return _defaultLang
    }

    override func allLangs() -> [String] {
        return _data._allLocales()
    }

    override func allKeys() -> [String] {
        return _data._allKeys()
    }

    override public func thumbnailFor(thumbnailId: String?, identifier: String) -> String? {
        // 1. if no spec, return nil
        // 2. check if exact entry exists
        // 3. check whether wildcard entry exists
        if _thumbnail_spec.count == 0 {
            return nil
        }
        if let thnid = thumbnailId, let thnres = _thumbnail_spec[thnid] {
            return thnres
        }
        for (k,v) in _thumbnail_spec {
            if k.contains("${identifier}") {
                let vres = v.replacingOccurrences(of: "${identifier}", with: identifier)
                return vres
            }
        }
        return nil
    }
}
