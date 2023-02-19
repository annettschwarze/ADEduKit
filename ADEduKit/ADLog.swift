//
//  ADLog.swift
//  ADEduKit
//
//  Created by Schwarze on 24.01.22.
//

import Foundation
import OSLog

/*
 ADLog
 +- loggers
 +- writers (meta)
 */

@objc @objcMembers
public class ADLog : NSObject {
    public static let sharedInstance = ADLog()

    var loggers: [String: ADLogger] = [:]
    var metaWriter = ADLogWriterList()

    override init() {
        super.init()
    }

    /*
    func fileWriter(url: URL?) -> ADLogWriterFile? {
        if let url = url {
            let w = ADLogWriterFile(url: url)
            return w
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let d = docs.first {
            let logUrl = d.appendingPathComponent("adlogger.log")
            let w = ADLogWriterFile(url: logUrl)
            return w
        }
        return nil
    }
     */

    public static func create() -> ADLog {
        return ADLog()
    }

    public func add(writer: ADLogWriter) {
        metaWriter.append(writer: writer)
    }

    public func removeAllWriters() {
        metaWriter.removeAll()
    }

    /*
    public func configure(logWriter: ADLogWriter?) {
        // close old writers?
        if let w = logWriter {
            metaWriter.append(writer: w)
            //w.open()
        }
    }
     */

    func close() {
        metaWriter.close()
    }

    func open() {
        metaWriter.open()
    }

    func typeName(_ some: Any) -> String {
        return (some is Any.Type) ? "\(some)" : "\(type(of: some))"
    }

    public func logger(for obj: Any) -> ADLogger {
        let name = typeName(obj)
        return logger(named: name)
    }

    public func logger(named scope: String) -> ADLogger {
        if let l = loggers[scope] {
            return l
        }
        let l = ADLoggerWithWriter(writer: metaWriter)
        loggers[scope] = l
        return l
    }
}

/**
 Dummy no-op logger.
 */
@objc @objcMembers
public class ADLogger: NSObject {
    override init() {
        super.init()
    }

    open func log(_ msg: String) {
        // no-op
    }

    /*
    func update(writer: ADLogWriter) {
        // no-op
    }
     */
}

/**
 Logger with writer.
 */
@objc @objcMembers
class ADLoggerWithWriter: ADLogger {
    let writer: ADLogWriter
    init(writer: ADLogWriter) {
        self.writer = writer
        super.init()
    }

    override func log(_ msg: String) {
        // for now always dump the log output to the console
        os_log(.default, "log: \(msg)")

        writer.append(str: msg)
    }

//    override func update(writer: ADLogWriter) {
//        self.writer = writer
//    }
}

/**
 No op log writer.
 */
@objc @objcMembers
public class ADLogWriter : NSObject {
    func open() { }
    func close() { }
    func append(str: String) { }
}

@objc @objcMembers
public class ADLogWriterList : ADLogWriter {
    var writers: [ADLogWriter] = []

    func append(writer: ADLogWriter) { writers.append(writer) }
    func removeAll() { writers.removeAll() }

    override func open() {
        writers.forEach {
            Log.log("\(#function): opening writer from list...")
            $0.open()
        }
    }
    override func close() {
        writers.forEach {
            Log.log("\(#function): closing writer from list...")
            $0.close()
        }
    }
    override func append(str: String) {
        writers.forEach {
            Log.log("\(#function): appending to writer from list...")
            $0.append(str: str)
        }
    }
}

@objc @objcMembers
class ADLogWriterMemory : ADLogWriter {
    let q = DispatchQueue(label: "adlogwritermem_q")
    var msgs: [String] = []

    override init() {
        super.init()
    }

    override func append(str: String) {
        q.async {
            os_log("\(#function): adding log message")
            self.msgs.append(str)
        }
    }

    func fetchMsgs() async -> [String] {
        q.sync {
            os_log("\(#function): returning log messages")
            let m = Array(msgs)
            return m
        }
    }
}

@objc @objcMembers
class ADLogWriterConsole : ADLogWriter {
    override init() {
        super.init()
    }

    override func append(str: String) {
        os_log("log: \(str)")
    }
}

@objc @objcMembers
public class ADLogWriterFile : ADLogWriter {
    let url: URL
    let q = DispatchQueue(label: "adlogwriter_q")
    var fh: FileHandle?
    var msgs: [String] = []
    var ds: DispatchSourceTimer?
    var dsActive: Bool = false

    public init(url: URL) {
        self.url = url
        super.init()
        let ds = DispatchSource.makeTimerSource(flags: [], queue: q)
        ds.schedule(deadline: .now(), repeating: .seconds(1))
        ds.setEventHandler(handler: { [weak self] in
            self?.tryFlush()
        })
        self.open()
        ds.resume()
        self.ds = ds
        dsActive = true
    }

    deinit {
        ds?.setEventHandler(handler: {})
        ds?.cancel()
        // need to resume after cancel, otherwise crash
        // (https://forums.developer.apple.com/thread/15902)
        if dsActive {
            // maybe not...
            // ds?.resume()
        }
        dsActive = false
    }

    override func open() {
        Log.log("\(#function): opening file \(url)")
        guard fh == nil else {
            Log.log("\(#function): file handle already there")
            return
        }
        var ok: Bool = false
        do {
            ok = try url.checkResourceIsReachable()
        } catch {
            Log.log("\(#function): checkResourceIsReachable: error=\(error.localizedDescription)")
            ok = false
        }
        if ok != true {
            do {
                try "".write(to: url, atomically: true, encoding: .utf8)
                ok = true
            } catch {
                Log.log("\(#function): error creating log file: error=\(error.localizedDescription)")
                os_log("error creating log file")
            }
        }
        if ok == true {
            do {
                let fh = try FileHandle(forWritingTo: url)
                self.fh = fh
                let pos = try fh.seekToEnd()
                Log.log("\(#function): log file seek to end at pos \(pos)")
            } catch {
                Log.log("\(#function): error getting file handle: error=\(error.localizedDescription)")
                os_log("error creating log file")
                try? fh?.close()
            }
        }
        Log.log("\(#function): done opening file")
    }

    override func close() {
        Log.log("\(#function): closing")
        q.async {
            Log.log("\(#function): closing -> tryFlush")
            self.tryFlush()

            Log.log("\(#function): closing -> close")
            // Defer actual close after the scheduled flush:
            try? self.fh?.close()
            self.fh = nil
        }
    }

    override func append(str: String) {
        Log.log("\(#function): appending str \(str)...")
        guard fh != nil else {
            Log.log("\(#function): cannot append, because file handle is nil")
            return
        }
        q.async {
            // self.ds?.resume()
            Log.log("\(#function): aysnc: appending str > \(str)")
            self.msgs.append(str)
        }
    }

    func tryFlush() {
        guard !msgs.isEmpty else {
            Log.log("\(#function): checking for data, nothing there")
            return
        }
        guard let fh = fh else {
            Log.log("\(#function): data exists for writing but file handle is nil")
            return
        }
        var m = msgs
        msgs.removeAll()

        // FIXME: add support for simple log rotation - at least a maximum log size

        m.append("")
        let s = m.joined(separator: "\n")
        if let d = s.data(using: .utf8) {
            Log.log("\(#function): appending new data to log file")
            do {
                let pos = try fh.seekToEnd()
                try fh.write(contentsOf: d)
            } catch {
                Log.log("\(#function): error seeking to end or appending to log file: error=\(error.localizedDescription)")
            }
        }
    }
}
