//
//  Extensions.swift
//  roland
//

import Foundation

extension String {
    func frontMatterKeyVal() -> (String, String?) {
        if let colonIndex = self.firstIndex(of: ":") {
            let key = self[..<colonIndex]
            let val = self[self.index(colonIndex, offsetBy: 1)...]
            return (String(key), String(val))
        } else {
            return (self, nil)
        }
    }
    
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    // Sorry, this is horribly specific to my blog's categories.
    // Need to revist and use NSScanner or something to do it correctly.
    var slug: String {
        var slug = self.lowercased()
        slug = slug.replacingOccurrences(of: " ", with: "-")
        slug = slug.replacingOccurrences(of: ".", with: "-")
        slug = slug.replacingOccurrences(of: "/", with: "")
        slug = slug.replacingOccurrences(of: "--", with: "-")
        return slug
    }
}

extension URL {
    var isAccessibleFile: Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir)
        if !exists || isDir.boolValue {
            return false
        }
        return FileManager.default.isReadableFile(atPath: self.path)
    }

    var isAccessibleDirectory: Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir)
        if !exists || !isDir.boolValue {
            return false
        }
        return FileManager.default.isReadableFile(atPath: self.path)
    }
}

extension Double {

    // It's dumb, but I swear I end up having to dump a number into some type
    // of storage that only accepts a String way more often than I care to think about.
    func stringValue() -> String {
        return String(format:"%f", self)
    }
}

extension Date {
    
    // let d = Date() -> Mar 12, 2020 at 1:51 PM
    // d.stringify() -> "1584039099.486827"
    func stringify() -> String {
        return timeIntervalSince1970.stringValue()
    }

    // Date.unstringify("1584039099.486827") -> Mar 12, 2020 at 1:51 PM
    static func unstringify(_ ts: String) -> Date {
        let dbl = Double(ts) ?? 0
        return Date(timeIntervalSince1970: dbl)
    }
}
