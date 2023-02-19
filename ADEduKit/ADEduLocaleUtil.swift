//
//  ADEduLocaleUtil.swift
//  ADEduKit
//
//  Created by Schwarze on 08.12.21.
//

import Foundation

// FIXME: put this into an instance getter in Facade instead of static methods?
@available(*, deprecated, message: "This will be changed, a new class is not yet defined.")
@objc
public class ADEduLocaleUtil: NSObject {
    public static let UnknownLocale = "??"
    static let EN = "en"
    
    public static let sharedInstance = ADEduLocaleUtil()
    var extensionMode : Bool = false

    public func activateExtensionMode() {
        extensionMode = true
    }

    public func langCode() -> String {
        if (extensionMode) {
            return langCodeInExtension()
        }
        let ls = Bundle.main.preferredLocalizations
        return defaultLangCodeFrom(list: ls)
    }

    public func langCodeInExtension() -> String {
        let ls = Locale.preferredLanguages
        return defaultLangCodeFrom(list: ls)
    }

    func defaultLangCodeFrom(list: [String]) -> String {
        if let lc = list.first {
            let index = lc.index(lc.startIndex, offsetBy: 2)
            return String(lc[..<index])
        }
        return Self.EN
    }

    func currentLocale() -> String {
        if let langCode = Locale.current.languageCode {
            return langCode
        } else {
            return Self.UnknownLocale
        }
    }
}
