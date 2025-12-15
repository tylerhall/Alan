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
    
    func updateFrame(to rect: CGRect) {
        let newRect = rect.insetBy(dx: -2, dy: -2)
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

        let cornerRadius = UserDefaults.standard.integer(forKey: Key.radius)
        
        let roundedRect = bounds.insetBy(dx: CGFloat(inset), dy: CGFloat(inset))
        let path = NSBezierPath(
            roundedRect: roundedRect,
            xRadius: CGFloat(cornerRadius),
            yRadius: CGFloat(cornerRadius)
        )
        path.lineWidth = CGFloat(width)

        let color: NSColor
        if NSAppearance.isLightMode {
            color = UserDefaults.standard.color(forKey: Key.lightMode) ?? Defaults.lightModeColor
        } else {
            color = UserDefaults.standard.color(forKey: Key.darkMode) ?? Defaults.darkModeColor
        }
        color.setStroke()

        path.stroke()
    }
}
