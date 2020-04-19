//
//  Extensions.swift
//  roland
//

import Foundation
import CommonCrypto

extension String {
    var md5: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

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
    
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: [.dotMatchesLineSeparators]) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [.withoutAnchoringBounds], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
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
