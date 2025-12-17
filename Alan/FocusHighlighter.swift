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
    private var frameIsDrawn = false;
    private var drawFrame = true
    private var disableFrameTimer: Timer?

    func start() {
        handleFocusChange()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
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
        // Check if the frontmost app is excluded
        if let frontmostApp = NSWorkspace.shared.frontmostApplication,
           let bundleIdentifier = frontmostApp.bundleIdentifier {

            let excludedApps = UserDefaults.standard.stringArray(forKey: Key.excludedApps) ?? []
            if excludedApps.contains(bundleIdentifier) {
                if highlightWindow.isVisible {
                    highlightWindow.orderOut(nil)
                    lastFrame = nil
                }
                return
            }
        }

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
            frameIsDrawn = false;

            let showFrameWhileDragging = UserDefaults.standard.object(forKey: Key.showFrameWhileDragging) as? Bool ?? true
            if !showFrameWhileDragging {
                temporarilyDisableFrameDrawing()
                return;
            }
        }
        if !frameIsDrawn && drawFrame {
            frameIsDrawn = true;
            highlightWindow.updateFrame(to: cocoaFrame)
        }
    }

    private func temporarilyDisableFrameDrawing() {
        drawFrame = false
        highlightWindow.orderOut(nil)
        disableFrameTimer?.invalidate()
        disableFrameTimer = Timer.scheduledTimer(withTimeInterval: Defaults.frameDrawingDisableTimeout, repeats: false) { [weak self] _ in
            self?.drawFrame = true
        }
    }

    // Hello, darkness, my old friend. I'm still really bad at this API.
    private func currentFocusedWindowFrame() -> CGRect? {
        var focusedElement: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard err == .success, let element = focusedElement as! AXUIElement? else {
            return nil
        }

        // If focus is a child, ask for its window
        var windowElement: CFTypeRef?
        let windowErr = AXUIElementCopyAttributeValue(
            element,
            kAXWindowAttribute as CFString,
            &windowElement
        )

        let targetElement: AXUIElement
        if windowErr == .success, let w = windowElement as! AXUIElement? {
            targetElement = w
        } else {
            targetElement = element
        }

        var frameValue: CFTypeRef?
        let frameErr = AXUIElementCopyAttributeValue(
            targetElement,
            "AXFrame" as CFString,
            &frameValue
        )

        guard frameErr == .success,
              let cfValue = frameValue,
              CFGetTypeID(cfValue) == AXValueGetTypeID()
        else {
            return nil
        }

        var rect = CGRect.zero
        if AXValueGetType(cfValue as! AXValue) == .cgRect {
            AXValueGetValue(cfValue as! AXValue, .cgRect, &rect)
            return rect
        }

        return nil
    }
}

private func cocoaRect(fromAXRect axRect: CGRect) -> CGRect {
    // Find the maximum Y coordinate across all screens in Cocoa space
    // This represents the total height of the entire screen arrangement
    // AX coordinates start from y=0 at the top of the topmost screen
    // Cocoa coordinates start from y=0 at the bottom of the bottommost screen
    // So we need the total height to properly flip the Y coordinate
    let maxY = NSScreen.screens.map { $0.frame.maxY }.max() ?? 0

    var rect = axRect
    rect.origin.y = maxY - (axRect.origin.y + axRect.height)

    return rect
}
