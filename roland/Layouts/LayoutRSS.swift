//
//  RSS.swift
//  roland
//

import Foundation

class LayoutRSS: Layout {

    var website: Website
    
    var fileURL: URL {
        return website.outputDirURL.appendingPathComponent("feed").appendingPathComponent("index.html")
    }
    
    init(website: Website) {
        self.website = website
    }

    func writeToDisk() {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("WARNING: Could not create feed directory \(outDirURL.path)")
            return
        }

        var templateContext = [String: Any?]()
        templateContext["meta"] = ["layout": "rss", "microtime": "\(startTime)"]
        templateContext["site"] = website.context

        let postIDs = website.newestPostIDs[0..<min(10, website.newestPostIDs.count)]
        var postContexts = [[String: Any?]]()
        for id in postIDs {
            if let post = website.allPosts[id] {
                postContexts.append(post.context)
            }
        }
        templateContext["posts"] = ["posts": postContexts] // This is dumb. Need a cleaner solution to push to PHP-land.

        let template = Template(templateName: "RSS", website: website)
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
