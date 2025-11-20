//
//  LocalizationProviding.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol LocalizationProviding {
    var currentLanguage: String { get }
    
    func setLanguage(_ language: String)
    func localizedString(for key: String) -> String
}

