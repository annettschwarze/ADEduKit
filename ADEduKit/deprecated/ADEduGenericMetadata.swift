//
//  ADEduGenericMetadata.swift
//  ADEduKitTool
//
//  Created by Schwarze on 19.09.21.
//

import Foundation

@available(*, deprecated, message: "Use Metadata instead")
public class ADEduGenericMetadata: ADEduGenericData {
    public var identifier: String?
    public var thumbnail_spec: [String: String]?
    public var scheme: String?

    public static func load(name: String) -> ADEduGenericMetadata? {
        let dict = loadJson(name: name)
        return load(dict: dict)
    }

    public static func load(url: URL) -> ADEduGenericMetadata? {
        let dict = loadJson(url: url)
        return load(dict: dict)
    }

    static func load(dict: [String: Any]?) -> ADEduGenericMetadata? {
        if let d = dict {
            let m = ADEduGenericMetadata()
            m.parse(dict: d)
            m.parseDone()
            return m
        } else {
            return nil
        }
    }

    override func parse(key: String, value: Any) -> Bool {
        switch key {
        case "id": identifier = value as? String ?? nil
        case "scheme": scheme = value as? String ?? nil
        case "thumbnail_spec": thumbnail_spec = value as? [String: String] ?? nil
        default:
            return true
        }
        return false
    }
}
