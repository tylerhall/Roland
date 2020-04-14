//
//  Category.swift
//  roland
//

import Foundation

class Category: Hashable {

    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    var name = ""
    var website: Website!
    var templateName = "category"

    var postsIDs = [Int]()
    var oldestPostIDs = [Int]()
    var newestPostIDs = [Int]()

    var permalink: String {
        return website.baseURLStr + website.categoryURLPrefix + "/" + name.slug + "/"
    }

    var directoryURL: URL {
        return website.outputDirURL.appendingPathComponent(website.categoryURLPrefix).appendingPathComponent(name.slug)
    }

    var parent: Category?
    
    var context: [String: Any?] {
        var context = [String: Any?]()

        context["name"] = name
        context["slug"] = name.slug
        context["permalink"] = permalink

        context["post_ids"] = postsIDs
        context["posts_count"] = postsIDs.count

        let allPostIDs = allPostIDsIncludingChildren().compactMap { $0 }
        context["all_post_ids"] = allPostIDs
        context["all_posts_count"] = allPostIDs.count

        let sortedChildren = children.sorted { (a, b) -> Bool in
            return a.name < b.name
        }
        context["children"] = sortedChildren.compactMap { $0.context }

        return context
    }
    
    private var _children = Set<Category>()
    var children: Set<Category> {
        return _children
    }
    
    func addChild(category: Category) {
        _children.insert(category)
    }
    
    func allPostIDsIncludingChildren() -> Set<Int> {
        var allIDs = Set<Int>(postsIDs)
        for child in children {
            for childPostID in child.allPostIDsIncludingChildren() {
                allIDs.insert(childPostID)
            }
        }
        return allIDs
    }
}
