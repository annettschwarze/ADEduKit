//
//  ADEduGenericModelState.swift
//  ADEduKitTool
//
//  Created by Schwarze on 19.09.21.
//

import Foundation

@available(*, deprecated, message: "This will be removed, a new class is not yet defined.")
public class ADEduGenericModelState {
    var url: URL? = nil
    var payload: Data? = nil
    var statusCode : Int = 0
    var error : Error? = nil
    var data : Data? = nil {
        willSet {
            _dataParsedCached = nil
        }
    }
    var _dataParsedCached : [String: Any]? = nil
    var dataParsed : [String: Any]? {
        get {
            if _dataParsedCached == nil {
                _dataParsedCached = parseData()
            }
            return _dataParsedCached
        }
    }

    public init(url: URL?, payload: Data?, statusCode: Int, error: Error?, data: Data?) {
        self.url = url
        self.payload = payload
        self.statusCode = statusCode;
        self.error = error;
        self.data = data;
    }

    public init(url: URL?, statusCode: Int, error: Error?, data: Data?) {
        self.url = url
        self.statusCode = statusCode;
        self.error = error;
        self.data = data;
    }

    fileprivate func parseData() -> [String: Any]? {
        if let d = data {
            if let json = try? JSONSerialization.jsonObject(with: d) {
                return json as? [String : Any]
            }
        }
        return nil
    }

    public func info() -> String {
        var info = ""
        if let u = url {
            info += "URL: " + u.absoluteString + "\n"
        }
        if let e = error {
            info += "Error: " + e.localizedDescription + "\n"
        }
        info += "HTTP-Status: \(statusCode)\n"
        if let data = data {
            info += "Data:\n" + (String(data: data, encoding: .utf8) ?? "(Error decoding data for UTF-8") + "\n"
        } else {
            info += "No Data.\n"
        }
        return info
    }

    func ok() -> Bool {
        // 200 = ok
        // 201 = created
        // 202 = accepted
        return error == nil && (statusCode == 200 || statusCode == 0 || statusCode == 201 || statusCode == 202)
    }
}
