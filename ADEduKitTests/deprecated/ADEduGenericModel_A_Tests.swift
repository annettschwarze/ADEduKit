//
//  ADEduGenericModel_A_Tests.swift
//  ADEduKitTests
//
//  Created by Schwarze on 15.12.21.
//

import XCTest
import ADEduKit

class ADEduGenericModel_A_Tests: XCTestCase {
    func testModelA_Basics() throws {
        let b : Bundle = Bundle(for: type(of: self))
        guard let jsonUrl = b.url(forResource: "model_a_model", withExtension: "json") else {
            XCTFail("failed to load json model")
            return
        }
        guard let m = ADEduGenericModel.load(url: jsonUrl) else {
            XCTFail("failed to load generic model instance")
            return
        }
        // root id
        let locales = m.allLocales().sorted()
        XCTAssertEqual(locales, ["de", "en"])
        XCTAssertEqual(m.identifier, "com.admadic.ueben.model_a")
        XCTAssertEqual(m.localValueStringFor(key: "title", locale: "en"), "Model-A-Root(en)")
        XCTAssertEqual(m.localValueStringFor(key: "title", locale: "de"), "Model-A-Root(de)")
        XCTAssertEqual(m.localValueStringFor(key: "title", locale: "xx"), "Model-A-Root")

        let level1Children = m.children()
        for (level1Index, level1Child) in level1Children.enumerated() {
            do { // Separate scope from nested for loop
                guard let childId = level1Child.identifier else {
                    XCTFail("child identifier missing")
                    continue
                }
                if let tmp = m.modelAt(path: [childId]) {
                    XCTAssertEqual(tmp.identifierPath(), level1Child.identifierPath(), "child id failed")
                }
                let baseTitle = "Child-\(level1Index + 1)"
                let baseSummary = "Summary-\(level1Index + 1)"
                XCTAssertEqual(level1Child.localValueStringFor(key: "title"), baseTitle)
                XCTAssertEqual(level1Child.localValueStringFor(key: "summary"), baseSummary)
                for loc in locales {
                    XCTAssertEqual(level1Child.localValueStringFor(key: "title", locale: loc), "\(baseTitle)(\(loc))")
                    XCTAssertEqual(level1Child.localValueStringFor(key: "summary", locale: loc), "\(baseSummary)(\(loc))")
                }
            }

            let level2Children = level1Child.children()
            for (level2Index, level2Child) in level2Children.enumerated() {
                guard let child2Id = level2Child.identifier else {
                    XCTFail("child identifier missing")
                    continue
                }
                if let tmp = level1Child.modelAt(path: [child2Id]) {
                    XCTAssertEqual(tmp.identifierPath(), level2Child.identifierPath(), "child id failed")
                }
                let baseTitle = "Child-\(level1Index + 1)-\(level2Index + 1)"
                let baseSummary = "Summary-\(level1Index + 1)-\(level2Index + 1)"
                XCTAssertEqual(level2Child.localValueStringFor(key: "title"), baseTitle)
                XCTAssertEqual(level2Child.localValueStringFor(key: "summary"), baseSummary)
                for loc in locales {
                    XCTAssertEqual(level2Child.localValueStringFor(key: "title", locale: loc), "\(baseTitle)(\(loc))")
                    XCTAssertEqual(level2Child.localValueStringFor(key: "summary", locale: loc), "\(baseSummary)(\(loc))")
                }

                // check paths
                let fullPath = [
                    "com.admadic.ueben.model_a",
                    "child-\(level1Index + 1)",
                    "child-\(level1Index + 1)-\(level2Index + 1)"
                ]
                XCTAssertEqual(level2Child.identifierPath(), fullPath, "identifierPath failed")
            }
        }
    }
}
