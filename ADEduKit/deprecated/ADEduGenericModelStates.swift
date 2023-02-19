//
//  ADEduGenericModelStates.swift
//  ADEduKitTool
//
//  Created by Schwarze on 19.09.21.
//

import Foundation

@available(*, deprecated, message: "This will be removed, a new class is not yet defined.")
class ADEduGenericModelStates {
    var responses = [String: ADEduGenericModelState]()
    func add(locale: String, op: String, state: ADEduGenericModelState) {
        let key = locale + ":" + op
        responses[key] = state
    }
    func infoFor(locale: String, op: String) -> ADEduGenericModelState? {
        let key = locale + ":" + op
        if let d = responses[key] {
            return d
        } else {
            return nil
        }
    }
}
