//
//  ADEduGenericModelState.swift
//  ADEduKitTool
//
//  Created by Schwarze on 19.09.21.
//

import Foundation

// FIXME: ADEduGenericModelOpState -> OpState?
@available(*, deprecated, message: "This will be removed, a new class is not yet defined.")
public enum ADEduGenericModelOpState {
    case idle
    case busy
    case ok
    case failed
}
