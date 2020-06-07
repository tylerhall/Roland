//
//  LayoutCategoryArchive.swift
//  roland
//

import Foundation

class LayoutCategory: Layout {

    var category: Category
    var template: Template?

    var fileURL: URL {
        return category.directoryURL.appendingPathComponent("index.html")
    }

    init(category: Category) {
        self.category = category
    }

    func writeToDiskOperation() -> Operation? {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Could not create category directory \(outDirURL.path)")
            return nil
        }

        template = Template(templateName: category.templateName, website: category.website)
        template?.context["meta"] = ["layout": "category", "microtime": "\(startTime)"]
        template?.context["category"] = category.context
        template?.context["site"] = category.website.context

        // We're gonna sort the category's posts and child category posts
        // right here rather than within the .context call to save duplicating
        // work a bunch of times.
        let postIDs = category.allPostIDsIncludingChildren()
        var posts = postIDs.compactMap { category.website.allPosts[$0] }
        posts.sort { (a, b) -> Bool in
            return a.date > b.date
        }
        let postContexts = posts.compactMap { $0.context }
        template?.context["posts"] = ["posts": postContexts] // This is dumb. Need a cleaner solution to push to PHP-land.
 
        let op = LayoutOperation()
        op.layout = self

        return op
    }
}
