//
//  Page.swift
//  roland
//

import Foundation

class Page {

    weak var website: Website!

    var title: String?
    var path = ""
    var body = ""
    var other = [String: String]()
    var templateName = "page"

    private var rawBody = ""

    var highlightWithPygments = false

    var context: [String: Any?] {
        var context = [String: Any?]()
        context["title"] = title
        context["path"] = path
        context["permalink"] = permalink
        context["content"] = body

        for (key, value) in other {
            context[key] = value
        }

        return context
    }
    
    var permalink: String {
        let trimmedPath = path.replacingOccurrences(of: "index.html", with: "").replacingOccurrences(of: "index.php", with: "")
        if let baseURL = URL(string: website.baseURLStr) {
            return baseURL.appendingPathComponent(trimmedPath).absoluteString
        } else {
            fatalError("nil baseURLStr not yet supported")
        }
    }

    init(fileContents: String, website: Website) {
        self.website = website

        var lines = fileContents.components(separatedBy: "\n")
        var foundEndOfFrontMatter = false
        while !foundEndOfFrontMatter {
            if lines.count == 0 {
                foundEndOfFrontMatter = true
            }
            
            let line = lines.remove(at: 0)
            if line.hasPrefix("---") {
                foundEndOfFrontMatter = true
            } else {
                let keyVal = line.frontMatterKeyVal()
                assignFrontMatterKeyVal(keyVal: keyVal)
            }
        }

        while lines.count > 0 {
            let line = lines.remove(at: 0)
            rawBody = "\(rawBody)\n\(line)"
        }
        
        if path.count == 0 {
            fatalError("Page missing path key")
        }
        
        if highlightWithPygments {
            body = rawBody.pygmentizeDown(identifier: "Body for \"" + (title ?? "Unkown") + "\"")
        } else {
            body = rawBody.down(identifier: "Body for \"" + (title ?? "Unkown") + "\"")
        }

    }
    
    func assignFrontMatterKeyVal(keyVal: (String?, String?)) {
        if let key = keyVal.0 {
            if key == "title", let val = keyVal.1 {
                title = val.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }

            if key == "path", let val = keyVal.1 {
                path = val.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }

            if key == "template", let val = keyVal.1 {
                templateName = val.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }
            
            if key == "pygments", let val = keyVal.1 {
                highlightWithPygments = (val.trimmingCharacters(in: .whitespacesAndNewlines) == "true")
                return
            }

            other[key] = keyVal.1?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
