//
//  ModelNodeDataImpl.swift
//  ADEduKit
//
//  Created by Schwarze on 19.12.21.
//

import Foundation

protocol ModelNodeDataImplDelegate {
    func parse(key: String, value: Any) -> Bool
    func parseItemDone()
    func parseDone()
}

/**
 Generic data base class for json based model.
 - Author:
    no author
 - Important:
    Use ADEduGenericModel for the actual data model.
 - Version:
    0.1

 Detailed description TODO.
 A GenericData instance holds a map of key-value-pairs. It supports localized
 variants, which are represented as keys with a dash. The primary key name is
 the part before the dash and the locale follows after the dash. It is expected
 that only the first dash is interpreted as the locale separator. Subsequent
 dashes are part of the locale name. For instance
 */
class ModelNodeDataImpl {
    /**
     The values map for the data object.
     */
    var _values = [String: Any]()
    var _cached_locales: [String]? = nil
    var _cached_keys: [String]? = nil
    var _delegate: ModelNodeDataImplDelegate?

    //MARK: - public API

    /**
     Returns an array of all locales extracted from the values map.
     - returns:
        A `[String]` with all locale names.
     */
    public func _allLocales() -> [String] {
        if _cached_locales == nil {
            (_cached_keys, _cached_locales) = ADEduGenericLocaleUtil.scanKeyAndLocales(values: _values)
        }
        return _cached_locales!
    }

    /**
     Returns an array of keys extracted from the values map.
     - returns:
        A `[String]` with all key names.
     */
    public func _allKeys() -> [String] {
        if _cached_keys == nil {
            (_cached_keys, _cached_locales) = ADEduGenericLocaleUtil.scanKeyAndLocales(values: _values)
        }
        return _cached_keys!
    }

    /**
     Returns a value string for the given key and locale with fallback for the
     key alone.
     - parameters:
        - key: A `String` specifying the value name
        - locale: A `String` specifying the locale name

     Key and locale are concatenated with a dash character. If a
     value exists for that combined key, it is returned. Otherwise the value
     for the key without the locale is returned.
     */
    public func _localValueStringFor(key: String, locale: String) -> String? {
        var rv : String? = nil
        let locKey = [key, "-", locale].joined()
        var rvtmp : Any? = nil
        rvtmp = _values[locKey] ?? _values[key]
        rv = rvtmp as? String ?? String(describing: rvtmp)
        return rv
    }

    public func _localValueStringFor(key: String) -> String? {
        let rv : String? = _values[key] as? String
        return rv
    }

    /**
     Default implementation returns an empty string. Subclasses should
     override to handle request response states.
     */
    public func _remoteValueStringFor(key: String, locale: String) -> String? {
        let rv : String? = nil
        return rv
    }

    //MARK: - Implementation

    /**
     Add the given value for the given key.
     - parameters:
        - value: A value to be stored
        - key: A `String` specifiying the name under which to store the value

     The key may or may not contain a locale name. If a dash is included in the
     key, it will later be interpreted as a separator for basic key name
     and locale name.
     */
    func add(value: Any, for key: String) {
        _values[key] = value
    }

    func dataValueFor(key: String, locale: String? = nil) -> Any? {
        var k = key
        if let l = locale {
            k = [key, "-", l].joined()
            if let v = _values[k] {
                return v
            }
        }
        return _values[k]
    }

    func valuesFor(locale: String) -> [String: Any] {
        var res = [String: Any]()
        let keys = _allKeys()
        for k in keys {
            let kloc = [k, "-", locale].joined()
            res[k] = _values[kloc] ?? _values[k]
        }
        return res
    }

    static func loadJson(name: String) -> [String: Any]? {
        let bundles = [Bundle(for: Self.self), Bundle.main]
        for b in bundles {
            guard let url = b.url(forResource: name, withExtension: "json") else {
                continue
            }
            if let json = loadJson(url: url) {
                return json
            }
        }
        return nil
    }

    static func loadJson(url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url, options: .uncached) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return nil }
        guard let dict = obj as? [String: Any] else { return nil }
        return dict
    }

    /** Return false, if that key shall be ignored by the general parser */
    func parse(key: String, value: Any) -> Bool {
        if let d = _delegate {
            return d.parse(key: key, value: value)
        }
        return true
    }

    /** Parsing item finished, give subclasses a chance to update their state. */
    func parseItemDone() {
        if let d = _delegate {
            return d.parseItemDone()
        }
    }

    /** Parsing finished, give subclasses a chance to update their state. */
    func parseDone() {
        if let d = _delegate {
            return d.parseDone()
        }
    }

    func parse(dict: [String: Any]) {
        let model : ModelNodeDataImpl = self
        for (key, value) in dict {
            if !parse(key: key, value: value) {
                // should not handle this key
                continue
            }
            switch value {
            case _ as NSDictionary:
                Log.log("\(#function): Error: arbitrary dictionaries not supported")
                break
            case _ as NSArray:
                Log.log("\(#function): Error: arbitrary arrays not supported")
                break
            case _ as NSNull:
                // ignore
                break
            default:
                model.add(value: value, for: key)
            }
        }
        parseItemDone();
    }
}
