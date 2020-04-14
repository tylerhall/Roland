//
//  Layout.swift
//  roland
//

import Foundation

protocol Layout {
    
    var fileURL: URL { get }

    func writeToDisk()
}
