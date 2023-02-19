//
//  ADLogTests.swift
//  ADEduKitTests
//
//  Created by Schwarze on 03.02.22.
//

import XCTest
@testable import ADEduKit

class ADLogTests: XCTestCase {
    func testLogMem() async throws {
        let log = ADLog.create()
        let memw = ADLogWriterMemory()
        log.add(writer: memw)
        log.open()

        let logger = log.logger(for: "test")
        print("\(#function): add msg1")
        logger.log("test message")
        let logger2 = log.logger(for: "test2")
        print("\(#function): add msg2")
        logger2.log("test2 message")
        log.close()
        log.open()

        let exp = XCTestExpectation(description: "exp1")

        let memwdata = await memw.fetchMsgs()
        XCTAssertEqual(memwdata.joined(separator: "\n"), "test message\ntest2 message")
        exp.fulfill()
        self.wait(for: [exp], timeout: 5)
    }

    func testLogList() async throws {
        let log = ADLog.create()
        let memw1 = ADLogWriterMemory()
        let memw2 = ADLogWriterMemory()
        // log.configure(logWriter: memw)
        log.add(writer: memw1)
        log.add(writer: memw2)
        log.open()

        let logger = log.logger(for: "test")
        print("\(#function): add msg1")
        logger.log("test message")
        let logger2 = log.logger(for: "test2")
        print("\(#function): add msg2")
        logger2.log("test2 message")
        log.close()
        log.removeAllWriters()
        log.open()

        let exp = XCTestExpectation(description: "exp1")

        let memw1data = await memw1.fetchMsgs()
        let memw2data = await memw2.fetchMsgs()
        XCTAssertEqual(memw1data.joined(separator: "\n"), "test message\ntest2 message")
        XCTAssertEqual(memw2data.joined(separator: "\n"), "test message\ntest2 message")
        exp.fulfill()
        self.wait(for: [exp], timeout: 5)
    }

    func testLogFile() async throws {
        Swift.print("\(#function): test start")
        let tmp = FileManager.default.temporaryDirectory
        let url = tmp.appendingPathComponent("adlogtests.txt")
        // clear the file first
        let d = Data()
        try? d.write(to: url)
        let log = ADLog.create()
        let filew = ADLogWriterFile(url: url)
        log.add(writer: filew)
        log.open()

        let exp = XCTestExpectation(description: "exp1")
        let expRL = XCTestExpectation(description: "expRunLoop")

        Swift.print("\(#function): logging some messages")
        let logger = log.logger(for: "test")
        logger.log("test message")
        let logger2 = log.logger(for: "test2")
        logger2.log("test2 message")

        Swift.print("\(#function): closing logs")
        log.close()
        // Detach the file writer from the log system
        // log.configure(logWriter: memw)
        Swift.print("\(#function): removing all writers")
        log.removeAllWriters()
        log.open()

        Swift.print("\(#function): queueing check for log content written to file")
        let q = DispatchQueue(label: "dummyq")
        q.asyncAfter(deadline: .now() + .seconds(3)) {
            Swift.print("\(#function): performing check for log content written to file")
            guard let d = try? Data(contentsOf: url) else {
                XCTFail("error reading test log file")
                return
            }
            guard let s = String(data: d, encoding: .utf8) else {
                XCTFail("error creating string from test log data")
                return
            }
            XCTAssertEqual(s, "test message\ntest2 message\n")
            exp.fulfill()
        }
        
        // This is needed, otherwise the log file writer won't flush
        // And it is in an async call, because Swift 6 does not allow access to RunLoop.current in an async context.
        Swift.print("\(#function): queueing RunLoop op")
        DispatchQueue.main.async {
            Swift.print("\(#function): RunLoop op begin")
            RunLoop.current.run(until: Date())
            Swift.print("\(#function): RunLoop op end")
            expRL.fulfill()
        }

        Swift.print("\(#function): waiting for expectations")
        self.wait(for: [exp, expRL], timeout: 5)
    }
}
