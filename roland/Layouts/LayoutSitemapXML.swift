//
//  RSS.swift
//  roland
//

import Foundation

class LayoutSitemapXML: Layout {

    var website: Website
    var template: Template?

    var fileURL: URL {
        return website.outputDirURL.appendingPathComponent("sitemap").appendingPathExtension("xml")
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

        template = Template(templateName: "sitemapxml", website: website)
        template?.context = [String: Any?]()
        template?.context["meta"] = ["layout": "sitemapxml", "microtime": "\(startTime)"]
        template?.context["site"] = website.context

        var postContexts = [[String: Any?]]()
        for id in website.newestPostIDs {
            if let post = website.allPosts[id] {
                let context = ["permalink": post.permalink, "lastmod": post.date.timeIntervalSince1970] as [String: Any]
                postContexts.append(context)
            }
        }
        template?.context["posts"] = ["posts": postContexts] // This is dumb. Need a cleaner solution to push to PHP-land.

        let op = LayoutOperation()
        op.layout = self

        return op
    }
}
