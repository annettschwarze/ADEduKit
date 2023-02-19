//
//  ADEduGenericData.swift
//  ADEduKitTool
//
//  Created by Schwarze on 19.09.21.
//

import Foundation

// NSObject base class for easy description
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

@available(*, deprecated, message: "Use ModelNodeData instead")
@objc
public class ADEduGenericData: NSObject {
    /**
     The values map for the data object.
     */
    var values = [String: Any]()
    var cached_locales: [String]? = nil
    var cached_keys: [String]? = nil

    //MARK: - public API

    /**
     Returns an array of all locales extracted from the values map.
     - returns:
        A `[String]` with all locale names.
     */
    public func allLocales() -> [String] {
        if cached_locales == nil {
            (cached_keys, cached_locales) = ADEduGenericLocaleUtil.scanKeyAndLocales(values: values)
        }
        return cached_locales!
    }

    /**
     Returns an array of keys extracted from the values map.
     - returns:
        A `[String]` with all key names.
     */
    public func allKeys() -> [String] {
        if cached_keys == nil {
            (cached_keys, cached_locales) = ADEduGenericLocaleUtil.scanKeyAndLocales(values: values)
        }
        return cached_keys!
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
    public func localValueStringFor(key: String, locale: String) -> String? {
        var rv : String? = nil
        let locKey = [key, "-", locale].joined()
        var rvtmp : Any? = nil
        rvtmp = values[locKey] ?? values[key]
        rv = rvtmp as? String ?? String(describing: rvtmp)
        return rv
    }

    public func localValueStringFor(key: String) -> String? {
        let rv : String? = values[key] as? String
        return rv
    }

    /**
     Default implementation returns an empty string. Subclasses should
     override to handle request response states.
     */
    public func remoteValueStringFor(key: String, locale: String) -> String? {
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
        values[key] = value
    }

    func dataValueFor(key: String, locale: String? = nil) -> Any? {
        var k = key
        if let l = locale {
            k = [key, "-", l].joined()
            if let v = values[k] {
                return v
            }
        }
        return values[k]
    }

    func valuesFor(locale: String) -> [String: Any] {
        var res = [String: Any]()
        let keys = allKeys()
        for k in keys {
            let kloc = [k, "-", locale].joined()
            res[k] = values[kloc] ?? values[k]
        }
        return res
    }

    static func loadJson(name: String) -> [String: Any]? {
        let b = Bundle.main
        guard let url = b.url(forResource: name, withExtension: "json") else { return nil }
        return loadJson(url: url)
    }

    static func loadJson(url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url, options: .uncached) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return nil }
        guard let dict = obj as? [String: Any] else { return nil }
        return dict
    }

    /** Return false, if that key shall be ignored by the general parser */
    func parse(key: String, value: Any) -> Bool {
        return true
    }

    /** Parsing item finished, give subclasses a chance to update their state. */
    func parseItemDone() {

    }

    /** Parsing finished, give subclasses a chance to update their state. */
    func parseDone() {

    }

    func parse(dict: [String: Any]) {
        let model : ADEduGenericData = self
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
