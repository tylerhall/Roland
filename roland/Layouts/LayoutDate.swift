//
//  LayoutDate.swift
//  roland
//

import Foundation

// This entire class is effed up. Need to think this through when time allows.
class LayoutDate: Layout {
    
    var startDate: Date
    var endDate: Date
    var website: Website
    var posts: [Post]
    var template: Template?

    var fileURL: URL {
        let df = DateFormatter()
        df.dateFormat = "YYYY/MM"
        return website.outputDirURL.appendingPathComponent(df.string(from: startDate)).appendingPathComponent("index.html")
    }

    init(startDate: Date, endDate: Date, posts: [Post], website: Website) {
        self.startDate = startDate
        self.endDate = endDate
        self.posts = posts
        self.website = website
    }

    func writeToDiskOperation() -> Operation? {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Could not create date directory \(outDirURL.path)")
            return nil
        }

        template = Template(templateName: "date", website: website)
        template?.context["meta"] = ["layout": "date", "microtime": "\(startTime)"]
        template?.context["date"] = ["start": startDate.timeIntervalSince1970, "end": endDate.timeIntervalSince1970]
        template?.context["site"] = website.context

        let postContexts = posts.compactMap { $0.context }
        template?.context["posts"] = ["posts": postContexts] // This is dumb. Need a cleaner solution to push to PHP-land.
        
        let op = LayoutOperation()
        op.layout = self

        return op
    }
}
