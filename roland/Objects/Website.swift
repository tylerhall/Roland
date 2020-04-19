//
//  Website.swift
//  roland
//

import Foundation

class Website {
    
    // These string values are ugly on purpose so they fit
    // better with PHP's naming conventions.
    enum ConfigKey: String {
        case BaseURL = "base_url"

        case PostURLPrefix = "post_url_prefix"
        case ArchiveURLPrefix = "archive_url_prefix"
        case CategoryURLPrefix = "category_url_prefix"
        
        case ShowPostExcerpts = "show_post_excerpts"
        case PostsPerPage = "posts_per_page"
        
        case Categories = "categories"
        case CategoriesByName = "categories_by_name"

        case DateGroups = "date_groups"

        case Posts = "posts"
    }

    // Making this lazy because it's too expensive to otherwise call very frequently.
    // (That could likely be fixed, but it something to look into on another day.)
    lazy var context: [String: Any?] = {
        var context = [String: Any?]()
        
        for k in plistContext.keys {
            context[k] = plistContext[k]
        }
 
        context[ConfigKey.BaseURL.rawValue] = baseURLStr
        context[ConfigKey.ShowPostExcerpts.rawValue] = usePostExcerpts
        context[ConfigKey.PostsPerPage.rawValue] = postsPerPage
        context[ConfigKey.PostURLPrefix.rawValue] = postURLPrefix
        context[ConfigKey.CategoryURLPrefix.rawValue] = categoryURLPrefix
        context[ConfigKey.DateGroups.rawValue] = dateGroups
        context[ConfigKey.ArchiveURLPrefix.rawValue] = archiveURLPrefix

        var postContexts = [String: [String: Any?]]()
        for p in allPosts.values {
            postContexts["\(p.id)"] = p.context
        }
        context[ConfigKey.Posts.rawValue] = postContexts

        var categoryContexts = [[String: Any?]]()
        for c in topLevelCategories {
            categoryContexts.append(c.context)
        }
        context[ConfigKey.Categories.rawValue] = categoryContexts
        
        var categoriesByName = [String: [String: Any?]]()
        for c in categories.values {
            categoriesByName[c.name] = c.context
        }
        context[ConfigKey.CategoriesByName.rawValue] = categoriesByName

        return context
    }()
    
    static let frontMatterDateFormat = "yyyy-MM-dd HH:mm:ss"

    var plistURL: URL!
    var projectDirURL: URL!
    var outputDirURL: URL!

    var postURLPrefix = ""
    var categoryURLPrefix = "category"
    var archiveURLPrefix = "page"
    var baseURLStr = "/"
    var usePostExcerpts = true
    var postsPerPage = 10
    var plistContext = [String: String]()

    var templateDirURL: URL {
        return projectDirURL.appendingPathComponent("_templates")
    }

    var postsDirURL: URL {
        return projectDirURL.appendingPathComponent("_posts")
    }

    var pagesDirURL: URL {
        return projectDirURL.appendingPathComponent("_pages")
    }

    var publicDirURL: URL {
        return projectDirURL.appendingPathComponent("_public")
    }
    
    var categoryTextFileURL: URL {
        return projectDirURL.appendingPathComponent("categories.txt")
    }

    var allPosts = [Int: Post]()
    var oldestPostIDs = [Int]()
    var newestPostIDs = [Int]()
    
    var archives = [Archive]()
    
    var vocabularies = [String: Set<String>]()

    // TODO: This needs to be refactored to allow grouping by timeframes other than months.
    lazy var dateGroups: [[String: Any]] = {
        var dates = [TimeInterval: Int]()
        for p in allPosts.values {
            let components = Calendar.current.dateComponents([.year, .month], from: p.date)
            let startOfMonth = Calendar.current.date(from: components)
            if dates[startOfMonth!.timeIntervalSince1970] == nil {
               dates[startOfMonth!.timeIntervalSince1970] = 0
            }
            dates[startOfMonth!.timeIntervalSince1970] = dates[startOfMonth!.timeIntervalSince1970]! + 1
        }

        let sortedKeys = Array(dates.keys).sorted(by: >)

        var arr = [[String: Any]]()
        for key in sortedKeys {
            let ts = TimeInterval(key)
            var dict = [String: Any]()
            dict["ts"] = String(Int(ts))
            dict["count"] = dates[ts]
            arr.append(dict)
        }

        return arr
    }()

    var pages = [Page]()
    
    var categories = [String: Category]()

    func categoryNamed(name: String) -> Category {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let category = categories[trimmedName] {
            return category
        }
        
        let category = Category()
        category.name = trimmedName
        category.website = self
        categories[trimmedName] = category

        return category
    }

    var topLevelCategories: [Category] {
        return categories.values.filter { (c) -> Bool in
            return (c.parent == nil)
        }.sorted { (a, b) -> Bool in
            return a.name < b.name
        }
    }

    init(plistURL: URL, projectDirURL: URL? = nil, outputDirURL: URL? = nil) {
        guard plistURL.isAccessibleFile else { print("ERROR: plist is not accessible: \(plistURL.path)"); exit(EXIT_FAILURE) }
        self.plistURL = plistURL

        if let projectDirURL = projectDirURL {
            self.projectDirURL = projectDirURL
        } else {
            self.projectDirURL = plistURL.deletingLastPathComponent()
        }

        if let outputDirURL = outputDirURL {
            self.outputDirURL = outputDirURL
        } else {
            self.outputDirURL = self.projectDirURL.appendingPathComponent("_www")
        }

        loadConfig()
    }

    func loadConfig() {
        guard let dict = NSDictionary(contentsOf: plistURL) else { print("ERROR: Could not parse plist: \(plistURL.path)"); exit(EXIT_FAILURE) }

        plistContext = (dict["Context"] as? [String: String]) ?? [String: String]()

        if let val = dict[ConfigKey.PostURLPrefix.rawValue] as? String {
            postURLPrefix = val
        }

        if let val = dict[ConfigKey.CategoryURLPrefix.rawValue] as? String {
            categoryURLPrefix = val
        }

        if let val = dict[ConfigKey.ArchiveURLPrefix.rawValue] as? String {
            archiveURLPrefix = val
        }

        if let val = dict[ConfigKey.BaseURL.rawValue] as? String {
            baseURLStr = val.hasSuffix("/") ? val : "\(val)/"
        }

        if let val = dict[ConfigKey.ShowPostExcerpts.rawValue] as? Bool {
            usePostExcerpts = val
        }

        if let val = dict[ConfigKey.PostsPerPage.rawValue] as? NSNumber {
            postsPerPage = val.intValue
        }
    }

    func loadAllPosts() {
        guard postsDirURL.isAccessibleDirectory else { print("WARNING: Posts directory is not readable: \(postsDirURL.path)"); return }

        allPosts.removeAll()

        var postID = 0
        let files = try! FileManager.default.contentsOfDirectory(at: postsDirURL, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles])
        for fileURL in files {
            if !fileURL.isAccessibleFile {
                fatalError("WARNING: \(fileURL.path) is not accessible")
                continue
            }

            do {
                let fileContents = try String(contentsOf: fileURL)
                let post = Post(fileContents: fileContents, id: postID, website: self)
                allPosts[postID] = post
            } catch {
                fatalError("WARNING: Could not read \(fileURL.path)")
            }

            postID += 1
        }

        var sortedPosts = allPosts.values.sorted { (a, b) -> Bool in
            return a.date < b.date
        }
        oldestPostIDs = sortedPosts.compactMap { $0.id }

        sortedPosts = allPosts.values.sorted { (a, b) -> Bool in
            return a.date > b.date
        }
        newestPostIDs = sortedPosts.compactMap { $0.id }

        for i in 0..<oldestPostIDs.count {
            let currentID = oldestPostIDs[i]
            if let current = allPosts[currentID] {
                let previousPostIndex = sortedPosts.indices.contains(i - 1) ? (i - 1) : nil
                let nextPostIndex = sortedPosts.indices.contains(i + 1) ? (i + 1) : nil
                
                if let index = previousPostIndex {
                    current.previousPostID = allPosts[oldestPostIDs[index]]?.id
                }

                if let index = nextPostIndex {
                    current.nextPostID = allPosts[oldestPostIDs[index]]?.id
                }
            }
        }
    }

    func loadAllPages() {
        guard pagesDirURL.isAccessibleDirectory else { print("WARNING: Pages directory is not readable: \(pagesDirURL.path)"); return }

        let files = try! FileManager.default.contentsOfDirectory(at: pagesDirURL, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles])
        for fileURL in files {
            if !fileURL.isAccessibleFile {
                continue
            }

            do {
                let fileContents = try String(contentsOf: fileURL)
                let page = Page(fileContents: fileContents, website: self)
                pages.append(page)
            } catch {
                
            }
        }
    }
    
    func loadAllCategories() {
        guard categoryTextFileURL.isAccessibleFile else { return }
        do {
            let lines = try String(contentsOf: categoryTextFileURL).components(separatedBy: "\n")
            for line in lines {
                let components = line.components(separatedBy: "|")
                if let parentName = components.first {
                    let parent = categoryNamed(name: parentName)
                    if (components.count == 2), let childrenNames = components.last?.components(separatedBy: ",") {
                        for childName in childrenNames {
                            let child = categoryNamed(name: childName)
                            child.parent = parent
                            parent.addChild(category: child)
                        }
                    }
                }
            }
        } catch {
            
        }
    }

    func loadAllArchives() {
        archives.removeAll()
        var currentPageNum = 1
        var currentPostNum = 0
        while currentPostNum < allPosts.count {
            let archive = Archive(pageNumber: currentPageNum, website: self)
            archives.append(archive)
            currentPageNum += 1
            currentPostNum += postsPerPage
        }
    }

    func loadVocabularies() {
        let vocabURL = URL(fileURLWithPath: "vocab.json")

        var vocabulariesDict = [String: [String]]()
        if let vocabFileData = try? Data(contentsOf: vocabURL) {
            if let dict = try? JSONSerialization.jsonObject(with: vocabFileData, options: []) as? [String: [String]] {
                vocabulariesDict = dict
            }
        }

        vocabularies = [String: Set<String>]()
        for (hash, words) in vocabulariesDict {
            let wordSet = Set(words.map { $0 })
            vocabularies[hash] = wordSet
        }

        for (_, post) in allPosts {
            if let hash = post.rawBodyHash, vocabulariesDict[hash] == nil {
                print("Generating vocabulary for: \(post.title ?? "Unitled Post")")
                vocabularies[hash] = post.generateVocabulary()
            }
        }
        
        var jsonOut = [String: Any]()
        for (hash, vocab) in vocabularies {
            jsonOut[hash] = Array(vocab)
        }

        let jsonDataOut = try? JSONSerialization.data(withJSONObject: jsonOut, options: .prettyPrinted)
        try? jsonDataOut?.write(to: vocabURL)
    }

    func cleanWebsiteOutputDirectory() {
        guard outputDirURL.isAccessibleDirectory else { return }
        
        print("Cleaning output directory")

        let files = try! FileManager.default.contentsOfDirectory(at: outputDirURL, includingPropertiesForKeys: nil, options: [])
        for fileURL in files {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("WARNING: Could not clean item from output directory \(fileURL.path)")
            }
        }
    }

    func createWebsiteOutputDirectories() {
        print("Creating output directory if it does not exist")
        
        do {
            try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Could not created output directory at \(outputDirURL.path)")
            exit(EXIT_FAILURE)
        }
    }

    func copyPublicAssets() {
        guard publicDirURL.isAccessibleDirectory else { print("WARNING: Public assets directory is not accessible \(publicDirURL.path)"); return }
        
        print("Copying public assets")

        let files = try! FileManager.default.contentsOfDirectory(at: publicDirURL, includingPropertiesForKeys: nil, options: [])
        for fileURL in files {
            let destURL = outputDirURL.appendingPathComponent(fileURL.lastPathComponent)
            do {
                try FileManager.default.copyItem(at: fileURL, to: destURL)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func buildPosts() {
        print("-----------------")
        print("Building posts...")
        print("-----------------")
        
        var i = 1
        for postID in oldestPostIDs {
            let soFar = "(\(i) of \(allPosts.count))"

            if let post = allPosts[postID] {
                print("Post \(soFar): \(post.date) - \(post.title ?? "Untitled")")

                let layout = LayoutPost(post: post)
                layout.writeToDisk()
            }

            i += 1
        }
    }

    func buildPages() {
        print("-----------------")
        print("Building pages...")
        print("-----------------")

        var i = 1
        for p in pages {
            let soFar = "(\(i) of \(pages.count))"
            print("Page \(soFar): \(p.title ?? "Untitled")")

            let layout = LayoutPage(page: p)
            layout.writeToDisk()

            i += 1
        }
    }

    func buildHomeArchives() {
        print("--------------------")
        print("Building home archives...")
        print("\(postsPerPage) posts per page")
        print("--------------------")
        
        for a in archives {
            let soFar = "(\(a.pageNumber) of \(archives.count))"
            let soFar2 = "Posts \(a.startPostIndex + 1) - \(a.endPostIndex)"
            print("Archive \(soFar): \(soFar2)")

            let layout = LayoutHome(archive: a)
            layout.writeToDisk()
        }
    }

    func buildCateogryArchives() {
        print("-----------------------------")
        print("Building category archives...")
        print("-----------------------------")

        var i = 1
        for c in categories.values {
            let soFar = "(\(i) of \(categories.count))"
            print("Category \(soFar): \(c.name)")

            let layout = LayoutCategory(category: c)
            layout.writeToDisk()

            i += 1
        }
    }

    func buildDateArchives() {
        print("-----------------------------")
        print("Building date archives...")
        print("-----------------------------")
        
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd HH:mm:ss"

        var i = 1
        for pd in dateGroups {
            let soFar = "(\(i) of \(dateGroups.count))"
            
            let date = Date.unstringify(pd["ts"] as! String)
            
            let startComponents = Calendar.current.dateComponents([.year, .month], from: date)
            let startOfMonth = Calendar.current.date(from: startComponents)!
            
            var endComponents = DateComponents()
            endComponents.month = 1
            endComponents.second = -1
            let endOfMonth = Calendar.current.date(byAdding: endComponents, to: startOfMonth)!

            let startDateStr = df.string(from: startOfMonth)
            let endDateStr = df.string(from: endOfMonth)
            print("Date \(soFar): \(startDateStr) - \(endDateStr)")
            
            var posts = [Post]()
            for p in website.allPosts.values {
                if (startOfMonth <= p.date) && (p.date <= endOfMonth) {
                    posts.append(p)
                }
            }
            posts.sort { (a, b) -> Bool in
                return a.date > b.date
            }

            let layout = LayoutDate(startDate: startOfMonth, endDate: endOfMonth, posts: posts, website: website)
            layout.writeToDisk()

            i += 1
        }
    }
    
    func buildRSSFeed() {
        print("-----------------------------")
        print("Building RSS feed...")
        print("-----------------------------")

        let layout = LayoutRSS(website: self)
        layout.writeToDisk()
    }
}
