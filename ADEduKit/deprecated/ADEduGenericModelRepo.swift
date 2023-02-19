//
//  ADEduGenericModelRepo.swift
//  ADEduKit
//
//  Created by Schwarze on 11.12.21.
//

import Foundation

@available(*, deprecated, message: "Use ContainerRepo instead")
@objc
public class ADEduGenericModelRepo : NSObject {
    public static let sharedInstance = ADEduGenericModelRepo()
    var repo: [String: ADEduGenericModel] = [:]

    public func loadModel(name: String) -> ADEduGenericModel? {
        if let m = repo[name] {
            return m
        }
        if let m = ADEduGenericModel.load(name: name) {
            repo[name] = m
            return m
        }
        return nil
    }
}
