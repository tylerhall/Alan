//
//  HighlightWindow.swift
//  Alan
//
//  Created by Tyler Hall on 11/26/25.
//

import AppKit

class HighlightWindow: NSWindow {

    init() {
        super.init(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        self.isReleasedWhenClosed = false
        
        self.contentView = HighlightView(frame: .zero)
    }
    
    static let shadowMargin: CGFloat = 25

    func updateFrame(to rect: CGRect) {
        let margin = HighlightWindow.shadowMargin
        let newRect = rect.insetBy(dx: -margin, dy: -margin)
        setFrame(newRect, display: true)
        self.contentView?.setNeedsDisplay(.infinite)
        orderFrontRegardless()
    }
}

class HighlightView: NSView {
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSGraphicsContext.current?.saveGraphicsState()
        defer { NSGraphicsContext.current?.restoreGraphicsState() }

        var inset = UserDefaults.standard.integer(forKey: Key.inset)
        inset = max(1, min(20, inset))

        var width = UserDefaults.standard.integer(forKey: Key.width)
        width = max(1, min(20, width))

        var cornerRadius = UserDefaults.standard.integer(forKey: Key.cornerRadius)
        cornerRadius = max(0, min(50, cornerRadius))

        // Account for the shadow margin - the actual border should be inset by the margin
        let margin = HighlightWindow.shadowMargin
        let borderBounds = bounds.insetBy(dx: margin + CGFloat(inset), dy: margin + CGFloat(inset))
        let path: NSBezierPath
        if cornerRadius > 0 {
            path = NSBezierPath(roundedRect: borderBounds, xRadius: CGFloat(cornerRadius), yRadius: CGFloat(cornerRadius))
        } else {
            path = NSBezierPath(rect: borderBounds)
        }
        path.lineWidth = CGFloat(width)

        let color: NSColor
        if NSAppearance.isLightMode {
            color = UserDefaults.standard.color(forKey: Key.lightMode) ?? Defaults.lightModeColor
        } else {
            color = UserDefaults.standard.color(forKey: Key.darkMode) ?? Defaults.darkModeColor
        }

        // Draw stronger shadow if enabled (outer shadow only)
        let strongerShadow = UserDefaults.standard.bool(forKey: Key.strongerShadow)

        if strongerShadow {
            NSGraphicsContext.current?.saveGraphicsState()

            // Create a clipping path that excludes the interior of the border
            // This ensures the shadow only appears outside
            let outerClipRect = bounds.insetBy(dx: -50, dy: -50)
            let outerClipPath = NSBezierPath(rect: outerClipRect)

            let innerExcludePath: NSBezierPath
            let halfWidth = CGFloat(width) / 2.0
            let innerBounds = borderBounds.insetBy(dx: -halfWidth, dy: -halfWidth)
            if cornerRadius > 0 {
                let innerRadius = CGFloat(cornerRadius) + halfWidth
                innerExcludePath = NSBezierPath(roundedRect: innerBounds, xRadius: innerRadius, yRadius: innerRadius)
            } else {
                innerExcludePath = NSBezierPath(rect: innerBounds)
            }

            // Use even-odd winding to clip out the interior
            outerClipPath.append(innerExcludePath)
            outerClipPath.windingRule = .evenOdd
            outerClipPath.addClip()

            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.99)
            shadow.shadowBlurRadius = 25
            shadow.shadowOffset = NSSize(width: 0, height: -3)
            shadow.set()

            color.setStroke()
            path.stroke()
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        // Draw glow if enabled
        let glowingBorder = UserDefaults.standard.bool(forKey: Key.glowingBorder)

        if glowingBorder {
            NSGraphicsContext.current?.saveGraphicsState()
            let glowShadow = NSShadow()
            glowShadow.shadowColor = color.withAlphaComponent(0.8)
            glowShadow.shadowBlurRadius = 12
            glowShadow.shadowOffset = NSSize(width: 0, height: 0)
            glowShadow.set()
            color.setStroke()
            path.stroke()
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        // Draw the main border stroke
        color.setStroke()

        path.stroke()
    }
}
