//
//  LayoutPost.swift
//  roland
//

import Foundation

class LayoutPost: Layout {
    
    var post: Post
    var template: Template?

    init(post: Post) {
        self.post = post
    }

    var fileURL: URL {
        return post.directoryURL.appendingPathComponent("index.html")
    }

    func writeToDiskOperation() -> Operation? {
        do {
            try FileManager.default.createDirectory(at: post.directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Could not create post directory \(post.directoryURL)")
            return nil
        }

        template = Template(templateName: post.templateName, website: post.website)
        template?.context["meta"] = ["layout": "post", "microtime": "\(startTime)"]
        template?.context["post"] = post.context

        let op = LayoutOperation()
        op.layout = self

        return op
    }
}

class LayoutOperation: Operation {
    
    var layout: Layout?

    override func main() {
        guard let layout = layout else { return }
        if let output = layout.template?.render(context: layout.template?.context) {
            do {
                try output.write(to: layout.fileURL, atomically: true, encoding: .utf8)
                totalPagesRendered += 1
                print("CREATED #\(totalPagesRendered) (\(operationQueue.operationCount) remaining): \(layout.fileURL.path)")
            } catch {
                print("ERROR: Could not write to \(layout.fileURL.path)")
            }
        }
    }
}
