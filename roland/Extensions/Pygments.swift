//
//  Pygments.swift
//  roland
//
//  Created by Tyler Hall on 4/15/20.
//  Copyright © 2020 Tyler Hall. All rights reserved.
//

import Foundation
import Down

extension String {

    func down(identifier: String? = nil) -> String {
        do {
            return try Down(markdownString: self).toHTML(.unsafe)
        } catch {
            fatalError("Could not parse markdown for: \(identifier ?? "unkown")")
        }
    }
    
    // This is silly, but it works for now. Was having the problem where even in .unsafe mode, CommonMark
    // would still incorrectly parse characters in code blocks as Markdown syntax. (It's a tough problem, I know.)
    // So, the pygmentize() will return text with code blocked removed entirely, which allows us to run the
    // remaining text through Markdown and *then* put the raw highlighted HTML back in where it belongs.
    func pygmentizeDown(identifier: String? = nil) -> String {
        let pygmentResults = self.pygmentize()

        do {
            var text = try Down(markdownString: pygmentResults.0).toHTML(.unsafe)

            if let replacements = pygmentResults.1 {
                for key in replacements.keys {
                    text = text.replacingOccurrences(of: key, with: replacements[key]!)
                }
            }

            return text
        } catch {
            fatalError("Could not parse markdown for: \(identifier ?? "unkown")")
        }
    }

    func pygmentize() -> (String, [String: String]?) {
        let pattern = #"\{\{code\|([a-zA-Z-]+)\}\}(.*?)\{\{code\}\}"#
        let results = self.matchingStrings(regex: pattern)

        if results.count == 0 {
            return (self, nil)
        }

        var haystack = self
        var replacements = [String: String]()

        for result in results {
            let needle = result[0]
            let language = result[1]
            let code = result[2]

            let highlightedText = code.highlightString(language: language)
            
            let uuidString = UUID().uuidString

            haystack = haystack.replacingOccurrences(of: needle, with: uuidString)

            replacements[uuidString] = highlightedText
        }

        return (haystack, replacements)
    }
    
    func highlightString(language: String) -> String {
        let task = Process()

        let stdin = Pipe()
        let stdout = Pipe()

        task.launchPath = Website.pygmentizePath
        task.arguments = ["-f", "html", "-O", "style=colorful", "-l", language]
        task.standardInput = stdin
        task.standardOutput = stdout
        task.launch()

        let writeHandle = stdin.fileHandleForWriting
        if let data = self.data(using: .utf8) {
            writeHandle.write(data)
            writeHandle.closeFile()
        } else {
            return self
        }

        let readHandle = stdout.fileHandleForReading
        let data = readHandle.readDataToEndOfFile()
        readHandle.closeFile()

        return String(data: data, encoding: .utf8) ?? self
    }
}
