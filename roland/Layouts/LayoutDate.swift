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

    func writeToDisk() {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("WARNING: Could not create date directory \(outDirURL.path)")
            return
        }

        var templateContext = [String: Any?]()
        templateContext["meta"] = ["layout": "date", "microtime": "\(startTime)"]
        templateContext["date"] = ["start": startDate.timeIntervalSince1970, "end": endDate.timeIntervalSince1970]
        templateContext["site"] = website.context

        let postContexts = posts.compactMap { $0.context }
        templateContext["posts"] = ["posts": postContexts] // This is dumb. Need a cleaner solution to push to PHP-land.

        let template = Template(templateName: "date", website: website)
        if let output = template.render(context: templateContext) {
            do {
                try output.write(to: fileURL, atomically: true, encoding: .utf8)
                totalPagesRendered += 1
            } catch {
                print("WARNING: Could not write date to \(fileURL.path)")
            }
        }
    }
}
