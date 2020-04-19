//
//  Post.swift
//  roland
//

import Foundation
import Down
import NaturalLanguage

class Post {

    weak var website: Website!

    var id: Int
    var date = Date.distantPast
    var title: String?
    var slug: String?
    var categories = [String]()
    var other = [String: String]()
    var templateName = "post"
    
    var rawBodyHash: String?
    private var rawBody = ""
    private var rawExcerpt = ""

    var previousPostID: Int?
    var nextPostID: Int?
    
    var body: String = ""
    var excerpt: String = ""
    
    var highlightWithPygments = false

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
        context["related_posts"] = relatedPosts

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
        rawBodyHash = rawBody.md5

        if highlightWithPygments {
            body = rawBody.pygmentizeDown(identifier: "Body for \"" + (title ?? "Unkown") + "\"")
            excerpt = rawExcerpt.pygmentizeDown(identifier: "Excerpt for \"" + (title ?? "Unkown") + "\"")
        } else {
            body = rawBody.down(identifier: "Body for \"" + (title ?? "Unkown") + "\"")
            excerpt = rawExcerpt.down(identifier: "Excerpt for \"" + (title ?? "Unkown") + "\"")
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

            if key == "pygments", let val = keyVal.1 {
                highlightWithPygments = (val.trimmingCharacters(in: .whitespacesAndNewlines) == "true")
                return
            }

            if key == "categories", let val = keyVal.1 {
                categories.removeAll()
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

    func generateVocabulary() -> Set<String> {
        var vocab = Set<String>()
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = body
        
        let range = NSRange(location: 0, length: body.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { _, tokenRange, _ in
            let word = (body as NSString).substring(with: tokenRange).lowercased()
            let lemmas = word.lemmatize()
            for lemma in lemmas {
                vocab.insert(lemma)
            }
        }

        return vocab
    }

    lazy var relatedPosts: [[String: Any]] = {
        guard let hash = rawBodyHash, let vocab = website.vocabularies[hash], vocab.count > 0 else {
            return []
        }

        var counts = [Int: Int]()
        for (index, postToCompare) in website.allPosts {
            if id == postToCompare.id {
                continue
            }

            var vocabToCompare: Set<String>?
            if let hash = postToCompare.rawBodyHash, let v = website.vocabularies[hash] {
                vocabToCompare = v
            }

            if let vocabToCompare = vocabToCompare, vocabToCompare.count > 0 {
                let intersection = vocab.intersection(vocabToCompare)
                counts[index] = intersection.count
            }
        }
        
        let sorted = counts.sorted { (a, b) -> Bool in
            return a.value > b.value
        }

        var relatedPosts = [[String: Any]]()
        for (index, count) in sorted.prefix(3) {
            relatedPosts.append(["id": index, "score": Double(count) / Double(vocab.count)])
        }

        return relatedPosts
    }()
}

extension String {
    func lemmatize() -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
        tagger.string = self
        let range = NSMakeRange(0, self.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation]

        var results = [String]()
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { (tag, tokenRange, stop) in
            if let lemma = tag?.rawValue {
                results.append(lemma)
            }
        }

        return (results.count > 0) ? [self] : results
    }
}
