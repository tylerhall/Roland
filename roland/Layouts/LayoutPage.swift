//
//  LayoutPage.swift
//  roland
//

import Foundation

class LayoutPage: Layout {

    var page: Page

    var fileURL: URL {
        return page.website.outputDirURL.appendingPathComponent(page.path)
    }

    var directoryURL: URL {
        return fileURL.deletingLastPathComponent()
    }

    init(page: Page) {
        self.page = page
    }
    
    func writeToDisk() {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("WARNING: Could not create post directory \(directoryURL)")
            return
        }
        
        var templateContext = [String: Any?]()
        templateContext["meta"] = ["layout": "page", "microtime": "\(startTime)"]
        templateContext["page"] = page.context
        templateContext["site"] = page.website.context

        let template = Template(templateName: page.templateName, website: page.website)
        if let output = template.render(context: templateContext) {
            do {
                try output.write(to: fileURL, atomically: true, encoding: .utf8)
                totalPagesRendered += 1
            } catch {
                print("WARNING: Could not write page to \(fileURL.path)")
            }
        }
    }
}
