//
//  Post.swift
//  roland
//

import Foundation
import Down

class Post {

    weak var website: Website!

    var id: Int
    var date = Date.distantPast
    var title: String?
    var slug: String?
    var categories = [String]()
    var other = [String: String]()
    var templateName = "post"
    
    private var rawBody = ""
    private var rawExcerpt = ""

    var previousPostID: Int?
    var nextPostID: Int?
    
    var body: String = ""
    var excerpt: String = ""

    var permalink: String {
        let df = DateFormatter()
        df.dateFormat = website.postURLPrefix
        let postURLPrefix = df.string(from: date)

        var trimmedSlug = slug?.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmedSlug = trimmedSlug?.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if let baseURL = URL(string: website.baseURLStr) {
            return baseURL.appendingPathComponent(postURLPrefix).appendingPathComponent(slug ?? "").absoluteString + "/"
        } else {
            fatalError("nil baseURLStr not yet supported")
        }
    }
    
    var context: [String: Any?] {
        var context = [String: Any?]()
        context["date"] = date.timeIntervalSince1970
        context["title"] = title
        context["slug"] = slug
        context["excerpt"] = excerpt
        context["permalink"] = permalink
        context["previous_post_id"] = previousPostID
        context["next_post_id"] = nextPostID
        context["content"] = body
        context["categories"] = categories

        for (key, value) in other {
            context[key] = value
        }

        return context
    }

    var directoryURL: URL {
        let df = DateFormatter()
        df.dateFormat = website.postURLPrefix
        let basePath = df.string(from: date)
        return website.outputDirURL.appendingPathComponent(basePath).appendingPathComponent(slug ?? "")
    }

    init(fileContents: String, id: Int, website: Website) {
        self.id = id
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
        
        var foundEndOfExcerpt = false
        while !foundEndOfExcerpt {
            if lines.count == 0 {
                foundEndOfExcerpt = true
            }

            let line = lines.remove(at: 0)
            if line.hasPrefix("---") {
                foundEndOfExcerpt = true
            } else {
                if rawExcerpt == "" {
                    rawExcerpt = line
                } else {
                    rawExcerpt = "\(rawExcerpt)\n\(line)"
                }
            }
        }
        
        while lines.count > 0 {
            let line = lines.remove(at: 0)
            if rawBody == "" {
                rawBody = line
            } else {
                rawBody = "\(rawBody)\n\(line)"
            }
        }

        do {
            body = try Down(markdownString: rawBody).toHTML(.unsafe)
        } catch {
            fatalError("Could not parse markdown body for \(title ?? "")")
        }
        
        do {
            excerpt = try Down(markdownString: rawExcerpt).toHTML(.unsafe)
        } catch {
            fatalError("Could not parse markdown excerpt for \(title ?? "")")
        }
    }
    
    func assignFrontMatterKeyVal(keyVal: (String?, String?)) {
        if let key = keyVal.0 {
            if key == "date", let val = keyVal.1 {
                let df = DateFormatter()
                df.dateFormat = Website.frontMatterDateFormat
                date = df.date(from: val.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Date.distantPast
                return
            }

            if key == "title", let val = keyVal.1 {
                title = val.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }
            
            if key == "slug", let val = keyVal.1 {
                slug = val.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }

            if key == "template", let val = keyVal.1 {
                templateName = val.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }

            categories.removeAll()
            if key == "categories", let val = keyVal.1 {
                let categoriesStr = val.trimmingCharacters(in: .whitespacesAndNewlines)
                let categoryNamesArray = categoriesStr.components(separatedBy: ",")
                for name in categoryNamesArray {
                    let category = website.categoryNamed(name: name)
                    category.postsIDs.append(id)
                    categories.append(category.name)
                }
                return
            }

            other[key] = keyVal.1?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
