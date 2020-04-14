//
//  LayoutPost.swift
//  roland
//

import Foundation

class LayoutPost: Layout {
    
    var post: Post

    init(post: Post) {
        self.post = post
    }

    var fileURL: URL {
        return post.directoryURL.appendingPathComponent("index.html")
    }

    func writeToDisk() {
        do {
            try FileManager.default.createDirectory(at: post.directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("WARNING: Could not create post directory \(post.directoryURL)")
            return
        }

        var templateContext = [String: Any?]()
        templateContext["meta"] = ["layout": "post", "microtime": "\(startTime)"]
        templateContext["post"] = post.context
        templateContext["site"] = post.website.context

        let template = Template(templateName: post.templateName, website: post.website)
        if let output = template.render(context: templateContext) {
            do {
                try output.write(to: fileURL, atomically: true, encoding: .utf8)
                totalPagesRendered += 1
            } catch {
                print("WARNING: Could not write post to \(fileURL.path)")
            }
        }
    }
}
