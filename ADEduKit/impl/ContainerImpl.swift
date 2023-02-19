//
//  ContainerImpl.swift
//  ADEduKit
//
//  Created by Schwarze on 18.12.21.
//

import Foundation

class ContainerImpl: Container {
    let _name: String
    var _rootModel: ModelNodeImpl?
    var _meta: MetadataImpl?
    var _util: ClassKitUtil?

    var _defaultLang: String? = nil

    init(name: String) {
        _name = name
    }

    override func modelName() -> String {
        return _name
    }

    override func rootModelNode() -> ModelNode? {
        if let rm = _rootModel {
            return rm
        }
        let rm = ModelNodeImpl(data: ModelNodeDataImpl())
        if let lang = _defaultLang {
            rm.setDefaultLang(lang: lang)
        }
        if let dict = ModelNodeDataImpl.loadJson(name: _name + "_model") {
            rm._data.parse(dict: dict)
        } else {
            Log.log("\(#function): error loading model json file")
        }
        _rootModel = rm
        return rm
    }

    override func metadata() -> Metadata? {
        if let m = _meta {
            return m
        }
        let m = MetadataImpl(data: ModelNodeDataImpl())
        if let lang = _defaultLang {
            m.setDefaultLang(lang: lang)
        }
        if let dict = ModelNodeDataImpl.loadJson(name: _name + "_meta") {
            m._data.parse(dict: dict)
        } else {
            Log.log("\(#function): error loading meta json file")
        }
        _meta = m
        return m
    }

    override func classKitUtil() -> ClassKitUtil? {
        if let u = _util {
            return u
        }
        let u = ClassKitUtilImpl(container: self)
        _util = u
        return u
    }

    override func setDefaultLang(lang: String) {
        _defaultLang = lang
        if let m = _rootModel {
            m.setDefaultLang(lang: lang)
        }
        if let m = _meta {
            m.setDefaultLang(lang: lang)
        }
    }

    override func getDefaultLang() -> String? {
        return _defaultLang
    }
}
