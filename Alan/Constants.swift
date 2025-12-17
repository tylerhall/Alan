//
//  Constants.swift
//  Alan
//
//  Created by Tyler Hall on 11/26/25.
//

import Cocoa

struct Defaults {
    static let lightModeColor = NSColor.black
    static let darkModeColor = NSColor.white
    static let frameDrawingDisableTimeout: TimeInterval = 0.25
}

struct Key {
    static let width = "width"
    static let inset = "inset"
    static let cornerRadius = "cornerRadius"
    static let glowingBorder = "glowingBorder"
    static let strongerShadow = "strongerShadow"
    static let hideDock = "hideDock"
    static let lightMode = "lightMode"
    static let darkMode = "darkMode"
    static let showFrameWhileDragging = "showFrameWhileDragging"
    static let excludedApps = "excludedApps"
}
