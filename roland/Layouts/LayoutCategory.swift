//
//  LayoutCategoryArchive.swift
//  roland
//

import Foundation

class LayoutCategory: Layout {

    var category: Category

    var fileURL: URL {
        return category.directoryURL.appendingPathComponent("index.html")
    }

    init(category: Category) {
        self.category = category
    }

    func writeToDisk() {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("WARNING: Could not create category directory \(outDirURL.path)")
            return
        }

        var templateContext = [String: Any?]()
        templateContext["meta"] = ["layout": "category", "microtime": "\(startTime)"]
        templateContext["category"] = category.context
        templateContext["site"] = category.website.context

        // We're gonna sort the category's posts and child category posts
        // right here rather than within the .context call to save duplicating
        // work a bunch of times.
        let postIDs = category.allPostIDsIncludingChildren()
        var posts = postIDs.compactMap { category.website.allPosts[$0] }
        posts.sort { (a, b) -> Bool in
            return a.date > b.date
        }
        let postContexts = posts.compactMap { $0.context }
        templateContext["posts"] = ["posts": postContexts] // This is dumb. Need a cleaner solution to push to PHP-land.

        let template = Template(templateName: category.templateName, website: category.website)
        if let output = template.render(context: templateContext) {
            do {
                try output.write(to: fileURL, atomically: true, encoding: .utf8)
                totalPagesRendered += 1
            } catch {
                print("WARNING: Could not write catgegory to \(fileURL.path)")
            }
        }
    }
}
