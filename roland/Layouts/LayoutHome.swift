//
//  LayoutBlog.swift
//  roland
//

import Foundation

class LayoutHome: Layout {
    
    var archive: Archive
    var template: Template?

    var fileURL: URL {
        return archive.directoryURL.appendingPathComponent("index.html")
    }
    
    init(archive: Archive) {
        self.archive = archive
    }

    func writeToDiskOperation() -> Operation? {
        let outDirURL = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Could not create archive directory \(outDirURL.path)")
            return nil
        }

        template = Template(templateName: archive.templateName, website: archive.website)
        template?.context["meta"] = ["layout": "home", "microtime": "\(startTime)"]
        template?.context["archive"] = archive.context
        template?.context["site"] = archive.website.context

        let op = LayoutOperation()
        op.layout = self

        return op
    }
}
