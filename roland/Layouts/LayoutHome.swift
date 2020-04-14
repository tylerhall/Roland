//
//  LayoutBlog.swift
//  roland
//

import Foundation

class LayoutHome: Layout {
    
    var archive: Archive

    var fileURL: URL {
        return archive.directoryURL.appendingPathComponent("index.html")
    }
    
    init(archive: Archive) {
        self.archive = archive
    }

    func writeToDisk() {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("WARNING: Could not create archive directory \(outDirURL.path)")
            return
        }

        var templateContext = [String: Any?]()
        templateContext["meta"] = ["layout": "home", "microtime": "\(startTime)"]
        templateContext["archive"] = archive.context
        templateContext["site"] = archive.website.context

        let template = Template(templateName: archive.templateName, website: archive.website)
        if let output = template.render(context: templateContext) {
            do {
                try output.write(to: fileURL, atomically: true, encoding: .utf8)
                totalPagesRendered += 1
            } catch {
                print("WARNING: Could not write home archive to \(fileURL.path)")
            }
        }
    }
}
