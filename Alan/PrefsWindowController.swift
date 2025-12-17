//
//  PrefsWindowController.swift
//  Alan
//
//  Created by Tyler Hall on 11/26/25.
//

import AppKit
import UniformTypeIdentifiers

class PrefsWindowController: NSWindowController {
    
    @IBOutlet weak var lightModeColorWell: NSColorWell!
    @IBOutlet weak var darkModeColorWell: NSColorWell!
    @IBOutlet weak var showFrameWhileDraggingCheckbox: NSButton!
    @IBOutlet weak var glowingBorderCheckbox: NSButton!
    @IBOutlet weak var strongerShadowCheckbox: NSButton!
    @IBOutlet weak var excludedAppsTableView: NSTableView!

    private var excludedApps: [String] = []

    override func windowDidLoad() {
        super.windowDidLoad()

        lightModeColorWell.color = UserDefaults.standard.color(forKey: Key.lightMode) ?? Defaults.lightModeColor
        darkModeColorWell.color = UserDefaults.standard.color(forKey: Key.darkMode) ?? Defaults.darkModeColor

        let showFrameWhileDragging = UserDefaults.standard.object(forKey: Key.showFrameWhileDragging) as? Bool ?? true
        showFrameWhileDraggingCheckbox.state = showFrameWhileDragging ? .on : .off

        let glowingBorder = UserDefaults.standard.bool(forKey: Key.glowingBorder)
        glowingBorderCheckbox.state = glowingBorder ? .on : .off

        let strongerShadow = UserDefaults.standard.bool(forKey: Key.strongerShadow)
        strongerShadowCheckbox.state = strongerShadow ? .on : .off

        excludedApps = UserDefaults.standard.stringArray(forKey: Key.excludedApps) ?? []
        excludedAppsTableView?.delegate = self
        excludedAppsTableView?.dataSource = self

        NotificationCenter.default.addObserver(self, selector: #selector(PrefsWindowController.userDefaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @IBAction func lightModeChanged(_ sender: NSColorWell) {
        UserDefaults.standard.setColor(sender.color, forKey: Key.lightMode)
    }
    
    @IBAction func darkModeChanged(_ sender: NSColorWell) {
        UserDefaults.standard.setColor(sender.color, forKey: Key.darkMode)
    }

    @IBAction func showFrameWhileDraggingChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Key.showFrameWhileDragging)
    }

    @IBAction func glowingBorderChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Key.glowingBorder)
    }

    @IBAction func strongerShadowChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Key.strongerShadow)
    }

    @IBAction func addExcludedApp(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.application]
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")

        openPanel.beginSheetModal(for: window!) { [weak self] response in
            guard response == .OK, let url = openPanel.url else { return }
            if let bundle = Bundle(url: url), let bundleIdentifier = bundle.bundleIdentifier {
                self?.addExcludedAppWithBundleId(bundleIdentifier)
            }
        }
    }


    @IBAction func removeExcludedApp(_ sender: Any) {
        let selectedRow = excludedAppsTableView.selectedRow
        guard selectedRow >= 0 && selectedRow < excludedApps.count else { return }

        excludedApps.remove(at: selectedRow)
        UserDefaults.standard.set(excludedApps, forKey: Key.excludedApps)
        excludedAppsTableView.reloadData()
    }

    private func addExcludedAppWithBundleId(_ bundleIdentifier: String) {
        guard !excludedApps.contains(bundleIdentifier) else { return }
        excludedApps.append(bundleIdentifier)
        UserDefaults.standard.set(excludedApps, forKey: Key.excludedApps)
        excludedAppsTableView.reloadData()
    }

    @objc func userDefaultsChanged() {
        FocusHighlighter.shared.forceUpdate()
    }
}

extension PrefsWindowController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return excludedApps.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let bundleIdentifier = excludedApps[row]

        let cellIdentifier = NSUserInterfaceItemIdentifier("ExcludedAppCell")
        var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellIdentifier

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            cellView?.addSubview(textField)
            cellView?.textField = textField

            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cellView?.addSubview(imageView)
            cellView?.imageView = imageView

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 2),
                imageView.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -2),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }

        // Get app name and icon from bundle identifier
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let appName = FileManager.default.displayName(atPath: appURL.path)
            cellView?.textField?.stringValue = appName
            cellView?.imageView?.image = NSWorkspace.shared.icon(forFile: appURL.path)
        } else {
            cellView?.textField?.stringValue = bundleIdentifier
            cellView?.imageView?.image = nil
        }

        return cellView
    }
}

