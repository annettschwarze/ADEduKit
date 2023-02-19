//
//  GCtx.swift
//  ADEduKitTool
//
//  Created by Schwarze on 26.08.21.
//

import Foundation

/*
 Summary of selected data types for ClassKit Catalog API
 
 Context {
         Data { == CLSContext in app
             customTypeName [string]
             displayOrder [number] (0)
             identifierPath! [string] (max 8 entries, max 256 total characters) (catalog api: must include appcontext)
             isAssignable [bool] (true)
             suggestedAge [number] (array of two numbers; [n1,n2] 2^64-2 = no max, 0 = no min
             suggestedCompletionTime [number] (array of two numbers) minutes, [n1,n2] 2^64-2 = no max, 0 = no min
             summary [string] max 4000
             thumbnailId [string] (provide an id and upload one)
             title! [string] (1..256)
             topic [string] (artsAndMusic, computerScienceAndEngineering, healthAndFitness, literacyAndWriting, math, science, socialScience, worldLanguage)
             type [string] (app, audio, book, challenge, chapter, course, custom, document, exercise, game, lesson, level, none, page, quiz, section, task, video)
             universalLinkURL [string]
             progressReportingCapabilities {
                 details [string] Description for teachers
                 kind [string] (duration, percent, binary, quantity, score)
             }
         }
         Metadata { == implicit in app
             keywords [string] list of tags
             locale! [string] (unsure about valid values: https://developer.apple.com/documentation/foundation/locale)
             minimumBundleVersion [string]
             presentableLocales [string] (set to "mul" to indicate any locale, otherwise list of locale ids)
                     Note that presentableLocales should not overlap. So if en and de exist and one mentions
                     mul and the other de, then they will overlap and appear twice
             standardsAlignments [string] (list of standards, ?)
             presentablePaths [string] (array of strings?, represent parent contexts for this context)
         }
     }
 */

@available(*, deprecated, message: "Use ModelNode instead")
public class ADEduGenericContext : NSObject {
    public static func configureFrom(model: ADEduGenericModel, meta: ADEduGenericMetadata, locale: String) -> [String: Any] {
        var dict = [String: Any]()
        var data = [String: Any]()
        var metadata = [String: Any]()

        // fill data object:
        data["identifierPath"] = model.identifierPath()
        let mtype = model.dataValueFor(key: "type", locale: nil)
        data["isAssignable"] = false
        let mtype2 : String = mtype as? String ?? "?"
        data["isAssignable"] = mtype2 == "task"
        data["summary"] = model.dataValueFor(key:"summary", locale: nil)
        data["title"] = model.dataValueFor(key:"title", locale: nil)
        var ctxType = "chapter" // default
        switch (mtype2) {
        case "metagroup": ctxType = "app"
        case "group": ctxType = "chapter"
        case "task": ctxType = "task"
        default:
            ctxType = "chapter"
        }
        data["type"] = ctxType
        let scheme = meta.scheme!
        data["universalLinkURL"] = [scheme, "://", model.identifierPath().joined(separator: "/")].joined()

        // fill metadata object:
        if let kw = meta.dataValueFor(key: "keywords", locale: locale) as? [String] {
            metadata["keywords"] = kw
        }
        metadata["locale"] = locale
        // metadata["minimumBundleVersion"] = ""
        // metadata["presentableLocales"] = ""
        var parentIdPath = [[String:[String]]]()
        if let p = model.parent {
            parentIdPath = [["path": p.identifierPath()]]
        }
        metadata["presentablePaths"] = parentIdPath

        dict["data"] = data
        dict["metadata"] = metadata

        return dict
    }
}
