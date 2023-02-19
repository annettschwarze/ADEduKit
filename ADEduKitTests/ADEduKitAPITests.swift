//
//  ADEduKitAPITests.swift
//  ADEduKitTests
//
//  Created by Schwarze on 19.12.21.
//

import XCTest
@testable import ADEduKit

class ADEduKitAPITests: XCTestCase {
    /**
     Test the main API
     */
    func testADEduKit() throws {
        let repo = Facade.sharedInstance.repo()
        let names = repo.containerNames()
        XCTAssertEqual(names, ["dummy"])
        guard let container = repo.containerForName(name: "dummy") else {
            XCTFail("error retrieving dummy container")
            return
        }
        XCTAssertEqual(container.modelName(), "dummy")
        guard let model = container.rootModelNode() else {
            XCTFail("error retrieving dummy model")
            return
        }

        let model_langs = model.allLangs()
        XCTAssertEqual(model_langs, ["de", "en"])

        XCTAssertEqual(model.title(), "Dummy-Root")
        XCTAssertEqual(model.summary(), "Dummy-Summary")
        XCTAssertEqual(model.identifier(), "com.admadic.adedukit.dummy")
        XCTAssertEqual(model.identifierPath(), ["com.admadic.adedukit.dummy"])
        XCTAssertNil(model.parent())
        XCTAssertTrue(model.root() === model)

        let children1 = model.children()
        for (index1, child1) in children1.enumerated() {
            do { // test scope
                let idPath = [model.identifier(), child1.identifier()]
                XCTAssertEqual(idPath, child1.identifierPath())
                let idPathRootRel = [child1.identifier()]
                XCTAssertEqual(idPathRootRel, child1.rootRelativeIdentifierPath())
                XCTAssertTrue(child1.parent() === model)
                let idValue = "child-\(index1+1)"
                XCTAssertEqual(idValue, child1.identifier())
                let titleValue = "Child-\(index1+1)"
                XCTAssertEqual(titleValue, child1.title())
            }

            let children2 = child1.children()
            for (index2, child2) in children2.enumerated() {
                let idPath = [model.identifier(), child1.identifier(), child2.identifier()]
                XCTAssertEqual(idPath, child2.identifierPath())
                let idPathRootRel = [child1.identifier(), child2.identifier()]
                XCTAssertEqual(idPathRootRel, child2.rootRelativeIdentifierPath())
                XCTAssertTrue(child2.parent() === child1)
                let idValue = "child-\(index1+1)-\(index2+1)"
                XCTAssertEqual(idValue, child2.identifier())
                let titleValue = "Child-\(index1+1)-\(index2+1)"
                XCTAssertEqual(titleValue, child2.title())
            }
        }

        guard let meta = container.metadata() else {
            XCTFail("error retrieving dummy meta")
            return
        }

        let meta_langs = meta.allLangs()
        XCTAssertEqual(meta_langs, ["de", "en"])

        XCTAssertEqual(meta.identifier(), "com.admadic.adedukit.dummy")
        XCTAssertEqual(meta.scheme(), "com.admadic.adedukit.dummy")
        // XCTAssertEqual(meta.keywords(), ["DummyKeyword1", "DummyKeyword2"])
        // TODO: thumbnail spec
    }
}
