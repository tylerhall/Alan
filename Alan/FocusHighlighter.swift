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
    guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(axRect) }) ?? NSScreen.main else {
        return axRect
    }

    // AX origin is top-left; AppKit expects bottom-left.
    // So we flip:
    //
    // y_appkit = screenMaxY - (y_axTop + height)
    //
    let screenFrame = screen.frame
    var rect = axRect
    rect.origin.y = screenFrame.maxY - (axRect.origin.y + axRect.height)

    return rect
}
