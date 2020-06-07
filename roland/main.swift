//
//  main.swift
//  roland
//

import Foundation
import ArgumentParser

struct RolandOptions: ParsableArguments {
    @Option(name: .shortAndLong, help: ArgumentHelp("The build configuration .plist to use.", discussion: "If omitted, \"config.plist\" in the current directory will be used.", valueName: "file"))
    var config: String?

    @Option(name: .shortAndLong, help: ArgumentHelp("The build output directory.", discussion: "If omitted, \"_www\" in the current directory will be used.\nIf the output directory does not exist, it will be created.", valueName: "directory"))
    var output: String?

    @Option(name: .shortAndLong, help: ArgumentHelp("Number of threads to use.", discussion: "Default is twice the number of CPU cores.", valueName: "integer"))
    var threads: Int?

    @Flag(help: "Only build posts.")
    var posts: Bool

    @Flag(help: "Only build pages.")
    var pages: Bool

    @Flag(help: "Only build home archives.")
    var home: Bool

    @Flag(help: "Only build date archives.")
    var dates: Bool

    @Flag(help: "Only build category archives.")
    var categories: Bool

    @Flag(help: "Only build RSS feed.")
    var rss: Bool

    @Flag(help: ArgumentHelp("Don't copy \"_public\" directory.", discussion: "If set, the contents of the \"_public\" directory will not be copied into the output directory."))
    var noPublic: Bool

    @Flag(help: ArgumentHelp("Don't clean the output directory.", discussion: "If set, the contents of the outpupt directory will not be deleted prior to building."))
    var noClean: Bool
}

let startTime = CFAbsoluteTimeGetCurrent()

let options = RolandOptions.parseOrExit()

let plistPath = options.config
let outputPath = options.output

let plistURL = (plistPath == nil) ? URL(fileURLWithPath: "config.plist") : URL(fileURLWithPath: plistPath!)
let projectURL = plistURL.deletingLastPathComponent()
let outputURL = (outputPath == nil) ? projectURL.appendingPathComponent("_www") : URL(fileURLWithPath: outputPath!)

let website = Website(plistURL: plistURL, projectDirURL: projectURL, outputDirURL: outputURL)
let operationQueue = OperationQueue()
operationQueue.isSuspended = true

print("Config: \(website.plistURL.path)")
print("Project: \(website.projectDirURL.path)")
print("Output: \(website.outputDirURL.path)")
print("----------------")

website.loadAllCategories()
website.loadAllPages()
website.loadAllPosts()
website.loadAllArchives()

if website.calculateRelatedPosts {
    website.loadVocabularies()
}

if !options.noClean {
    website.cleanWebsiteOutputDirectory()
}

website.createWebsiteOutputDirectories()

if !options.noPublic {
    website.copyPublicAssets()
}

var totalPagesRendered = 0

var buildEverything = true
if options.posts || options.pages || options.home || options.categories || options.dates || options.rss {
    buildEverything = false
}

if options.posts || buildEverything {
    website.buildPosts()
}

if options.pages || buildEverything {
    website.buildPages()
}

if options.home || buildEverything {
    website.buildHomeArchives()
}

if options.categories || buildEverything {
    website.buildCateogryArchives()
}

if options.dates || buildEverything {
    website.buildDateArchives()
}

if options.rss || buildEverything {
    website.buildRSSFeed()
}

operationQueue.maxConcurrentOperationCount = options.threads ?? (ProcessInfo().processorCount * 2)
operationQueue.isSuspended = false
operationQueue.waitUntilAllOperationsAreFinished()

let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
print("---------")
print("Finished!")
print("---------")
print("Rendered \(totalPagesRendered) pages in \(timeElapsed) seconds.")
