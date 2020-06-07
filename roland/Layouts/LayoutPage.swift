//
//  LayoutPage.swift
//  roland
//

import Foundation

class LayoutPage: Layout {

    var page: Page
    var template: Template?

    var fileURL: URL {
        return page.website.outputDirURL.appendingPathComponent(page.path)
    }

    var directoryURL: URL {
        return fileURL.deletingLastPathComponent()
    }

    init(page: Page) {
        self.page = page
    }
    
    func writeToDiskOperation() -> Operation? {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Could not create post directory \(directoryURL)")
            return nil
        }
        
        template = Template(templateName: page.templateName, website: page.website)
        template?.context["meta"] = ["layout": "page", "microtime": "\(startTime)"]
        template?.context["page"] = page.context
        template?.context["site"] = page.website.context
        
        let op = LayoutOperation()
        op.layout = self

        return op
    }
}
