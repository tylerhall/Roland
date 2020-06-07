//
//  Layout.swift
//  roland
//

import Foundation

protocol Layout {
    
    var fileURL: URL { get }
    var template: Template? { get set }

    func writeToDiskOperation() -> Operation?
}
