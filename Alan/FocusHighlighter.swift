//
//  FocusHighlighter.swift
//  Alan
//
//  Created by Tyler Hall on 11/26/25.
//

import AppKit
import ApplicationServices

class FocusHighlighter {
    
    static let shared = FocusHighlighter()

    private let systemWideElement = AXUIElementCreateSystemWide()
    private let highlightWindow = HighlightWindow()
    private var timer: Timer?
    private var lastFrame: CGRect?

    func start() {
        handleFocusChange()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.handleFocusChange()
        }

        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func forceUpdate() {
        guard let lastFrame else { return }
        highlightWindow.updateFrame(to: lastFrame)
    }
    
    private func handleFocusChange() {
        guard let axFrame = currentFocusedWindowFrame() else {
            if highlightWindow.isVisible {
                highlightWindow.orderOut(nil)
                lastFrame = nil
            }
            return
        }

        let cocoaFrame = cocoaRect(fromAXRect: axFrame)

        if lastFrame != cocoaFrame {
            lastFrame = cocoaFrame
            highlightWindow.updateFrame(to: cocoaFrame)
        }
    }

    // Hello, darkness, my old friend. I'm still really bad at this API.
    private func currentFocusedWindowFrame() -> CGRect? {
        // Get the active application
        guard let activeApp = NSWorkspace.shared.frontmostApplication,
              let activeAppName = activeApp.localizedName else {
            return nil
        }
        
        // Get list of all on-screen windows
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }
        
        // Find the frontmost window of the active application
        for window in windowList {
            guard let ownerName = window[kCGWindowOwnerName as String] as? String,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  ownerName == activeAppName,
                  layer == 0 else { // Normal windows only
                continue
            }
            
            guard let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }
            
            let x = boundsDict["X"] ?? 0
            let y = boundsDict["Y"] ?? 0
            let width = boundsDict["Width"] ?? 0
            let height = boundsDict["Height"] ?? 0
            
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        return nil
    }
}

private func cocoaRect(fromAXRect axRect: CGRect) -> CGRect {
    // The coordinate space starts at the primary display
    // The primary display is at index zero of the NSScreen.screens array, this
    // is not the same as NSScreen.main which is the window with the current focus
    var rect = axRect
    rect.origin.y = NSScreen.screens[0].frame.maxY - axRect.maxY
    return rect
}
