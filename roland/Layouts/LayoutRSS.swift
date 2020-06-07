//
//  RSS.swift
//  roland
//

import Foundation

class LayoutRSS: Layout {

    var website: Website
    var template: Template?
    
    var fileURL: URL {
        return website.outputDirURL.appendingPathComponent("feed").appendingPathComponent("index.html")
    }
    
    init(website: Website) {
        self.website = website
    }

    func writeToDiskOperation() -> Operation? {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Could not create feed directory \(outDirURL.path)")
            return nil
        }

        template = Template(templateName: "RSS", website: website)
        template?.context = [String: Any?]()
        template?.context["meta"] = ["layout": "rss", "microtime": "\(startTime)"]
        template?.context["site"] = website.context

        let postIDs = website.newestPostIDs[0..<min(10, website.newestPostIDs.count)]
        var postContexts = [[String: Any?]]()
        for id in postIDs {
            if let post = website.allPosts[id] {
                postContexts.append(post.context)
            }
        }
        template?.context["posts"] = ["posts": postContexts] // This is dumb. Need a cleaner solution to push to PHP-land.

        let op = LayoutOperation()
        op.layout = self

        return op
    }
}
