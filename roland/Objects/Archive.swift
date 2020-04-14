//
//  Archive.swift
//  roland
//

import Foundation

class Archive {
    
    var postIDs: [Int]
    var pageNumber: Int
    var website: Website!
    var templateName = "home"

    var startPostIndex: Int
    var endPostIndex: Int

    var context: [String: Any?] {
        var context = [String: Any?]()
        
        context["page_number"] = pageNumber
        context["total_pages"] = website.archives.count

        if let previousArchive = previousArchive {
            context["previous_archive_permalink"] = previousArchive.permalink
        }

        if let nextArchive = nextArchive {
            context["next_archive_permalink"] = nextArchive.permalink
        }

        context["post_ids"] = postIDs

        return context
    }
    
    var previousArchive: Archive? {
        if pageNumber > 1 {
            return Archive(pageNumber: pageNumber - 1, website: website)
        } else {
            return nil
        }
    }

    var nextArchive: Archive? {
        if (pageNumber * website.postsPerPage) < website.allPosts.count {
            return Archive(pageNumber: pageNumber + 1, website: website)
        } else {
            return nil
        }
    }

    var directoryURL: URL {
        if pageNumber > 1 {
            return website.outputDirURL.appendingPathComponent(website.archiveURLPrefix).appendingPathComponent("\(pageNumber)")
        } else {
            return website.outputDirURL
        }
    }

    var permalink: String {
        if let baseURL = URL(string: website.baseURLStr) {
            if pageNumber > 1 {
                return baseURL.appendingPathComponent(website.archiveURLPrefix).appendingPathComponent("\(pageNumber)").path + "/"
            } else {
                return baseURL.path
            }
        } else {
            fatalError("nil baseURLStr not yet supported")
        }
    }
    
    init(pageNumber: Int, website: Website) {
        self.pageNumber = pageNumber
        self.website = website
        self.startPostIndex = (pageNumber - 1) * website.postsPerPage
        self.endPostIndex = min(website.allPosts.count, startPostIndex + website.postsPerPage)
        self.postIDs = Array(website.newestPostIDs[self.startPostIndex..<self.endPostIndex])
    }
}
