//
//  Pygments.swift
//  roland
//
//  Created by Tyler Hall on 4/15/20.
//  Copyright © 2020 Tyler Hall. All rights reserved.
//

import Foundation

extension String {

    func pygmentize() -> String {
        let pattern = #"\{\{code\|([a-z]+)\}\}(.*?)\{\{code\}\}"#
        let results = self.matchingStrings(regex: pattern)

        if results.count == 0 {
            return self
        }
        
        var haystack = self
        
        for result in results {
            let needle = result[0]
            let language = result[1]
            let code = result[2]

            let highlightedText = code.highlightString(language: language)
            haystack = haystack.replacingOccurrences(of: needle, with: highlightedText)
        }

        return haystack
    }
    
    func highlightString(language: String) -> String {
        let task = Process()

        let stdin = Pipe()
        let stdout = Pipe()

        // TODO: We need to auto-detect where pygmentize is in the user's $PATH,
        // or maybe allow them to explicitly define the location themselves.
        task.launchPath = "/usr/local/bin/pygmentize"
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
