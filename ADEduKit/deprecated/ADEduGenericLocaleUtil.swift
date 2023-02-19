//
//  ADEduGenericLocaleUtil.swift
//  ADEduKitTool
//
//  Created by Schwarze on 19.09.21.
//

import Foundation

// FIXME: ADEduGenericLocaleUtil -> (Data)LocaleUtil
@available(*, deprecated, message: "This will be removed, a new class is not yet defined.")
class ADEduGenericLocaleUtil {
    static func scanKeyAndLocales(values: [String: Any]) -> ([String], [String]) {
        var _locs = [String: Bool]()
        var _keys = [String: Bool]()
        for (k, _) in values {
            let (k2, l2) = extractLocale(k: k)
            if l2 == nil {
                _keys[k] = true
                continue
            }
            _keys[k2] = true
            // Support en and en_US etc.
            if let loc = l2 {
                if loc.count < 2 { continue }
                _locs[loc] = true
            }
        }
        return (Array(_keys.keys).sorted(), Array(_locs.keys).sorted())
    }

    static func extractLocale(k: String) -> (String, String?) {
        if let i = k.firstIndex(of: "-") {
            let j = k.index(after: i)
            return (String(k.prefix(upTo: i)), String(k[j...]))
        } else {
            return (k, nil)
        }
    }
}
