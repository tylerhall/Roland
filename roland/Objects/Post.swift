//
//  Post.swift
//  roland
//

import Foundation

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

    var manuallyRelatedURLs = [String]()

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
        
        if let id = previousPostID, let post = website.allPosts[id] {
            context["previous_post"] = RelatedPost.fromPost(post: post, score: 0).context
        }

        if let id = nextPostID, let post = website.allPosts[id] {
            context["next_post"] = RelatedPost.fromPost(post: post, score: 0).context
        }

        context["content"] = body
        context["categories"] = categories

        var related = [[String: Any?]]()
        for post in manuallyRelatedPosts {
            related.append(["id": post.id, "score": 10000])
        }
        if website.calculateRelatedPosts {
            for post in relatedPosts {
                related.append(post.context)
            }
        }
        context["related_posts"] = related

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
        rawBodyHash = rawBody.sha256

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
            
            if key == "related_post", let val = keyVal.1 {
                let url = val.trimmingCharacters(in: .whitespacesAndNewlines)
                manuallyRelatedURLs.append(url)
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

    lazy var manuallyRelatedPosts: [Post] = {
        var relatedPosts = [Post]()
        
        for urlStr in manuallyRelatedURLs {
            var theURL = urlStr
            if !theURL.hasPrefix("http://") && !theURL.hasPrefix("https://") {
                theURL = website.baseURLStr + urlStr
            }
            
            _ = website.allPosts.first(where: { (el) -> Bool in
                if el.value.permalink == theURL {
                    relatedPosts.append(el.value)
                    return true
                }
                return false
            })
        }

        return relatedPosts
    }()

    lazy var relatedPosts: [RelatedPost] = {
        
        // Play with these numbers to figure out what works best for your content.
        let commonWordMultiplier: Double = 2
        let commonCategoryMultiplier = 75
        // NOTE: This has a *gigantic* impact on run time. 3 is currently my maximum.
        // I haven't yet looked into what stupid Big-Oh thing I'm doing to cause this.
        let maxRelatedPostsToReturn = 3

        guard let hash = rawBodyHash, let vocab = website.vocabularies[hash], vocab.count > 0 else {
            return []
        }

        var relatedPosts = [RelatedPost]()
        for (index, postToCompare) in website.allPosts {
            if id == postToCompare.id {
                continue
            }
            
            var scoreSum: Double = 0

            if let hash = postToCompare.rawBodyHash, let vocabToCompare = website.vocabularies[hash], vocabToCompare.count > 0 {
                let commonWordsCount = vocab.intersection(vocabToCompare).count
                let scoreRatio = Double(commonWordsCount) / max(Double(vocabToCompare.count), Double(vocab.count))
                let commonScore = Double(vocab.count + vocabToCompare.count) * scoreRatio * commonWordMultiplier
                scoreSum += commonScore
            }

            let setA = Set(categories)
            let setB = Set(postToCompare.categories)
            let commonCategoryCount = setA.intersection(setB).count

            scoreSum += Double(commonCategoryCount * commonCategoryMultiplier)

            var relatedPost = RelatedPost.fromPost(post: postToCompare, score: scoreSum)
            relatedPosts.append(relatedPost)
        }

        // Calculate standard deviation of scores...
        let scores = relatedPosts.compactMap { return $0.score }
        let length = Double(scores.count)
        let avg = scores.reduce(0, {$0 + $1}) / length
        let sumOfSquaredAvgDiff = scores.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        let stdDev = sqrt(sumOfSquaredAvgDiff / length)

        // Calculate how each score compares to stddev...
        for i in 0..<relatedPosts.count {
            relatedPosts[i].stdDevRatio = relatedPosts[i].score / stdDev
        }

        // Sore by that ratio...
        relatedPosts.sort { (a, b) -> Bool in
            return a.stdDevRatio! > b.stdDevRatio!
        }

        // Normalize those scores between 0 and 1.
        // This gives the PHP template side of things a way to enforce
        // a relevancy cutoff...
        if let max = relatedPosts.first?.stdDevRatio {
            for i in 0..<relatedPosts.count {
                relatedPosts[i].normalizedScore = relatedPosts[i].stdDevRatio! / max
            }
        }

        return Array(relatedPosts.prefix(maxRelatedPostsToReturn))
    }()
}

struct RelatedPost {
    var postID: Int
    var score: Double
    var stdDevRatio: Double?
    var normalizedScore: Double?
    var isManual = false
    var title: String?
    var permalink: String = ""

    var context: [String: Any?] {
        return ["id": postID, "score": normalizedScore, "title": title, "permalink": permalink]
    }
    
    static func fromPost(post: Post, score: Double) -> RelatedPost {
        var relatedPost = RelatedPost(postID: post.id, score: score)
        relatedPost.title = post.title
        relatedPost.permalink = post.permalink
        return relatedPost
    }
}
