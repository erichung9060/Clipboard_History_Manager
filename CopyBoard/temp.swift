//
//  AppDelegate.swift
//  CopyClip2
//
//  Created by 洪睿廷 on 2024/8/18.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSSearchFieldDelegate {
    let HistoryMaximum = 10
    let recordInterval = 0.5
    let MenuItemMaxWidth:Double = 280
    
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?
    var searchField = NSSearchField(frame: NSRect(x: 0, y: 0, width: 330, height: 28))
    
    var clipboardHistory: [String] = []
    var showingHistory: [String] = []
    var timer: Timer?
    var lastChangeCount: Int = NSPasteboard.general.changeCount
    var eventMonitor: Any?
    var searchingTarget = ""
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Insert code here to initialize your application
        
        
        statusMenu = NSMenu()
        
        
        searchField.placeholderString = "Search history..."
        searchField.target = self
        searchField.delegate = self

        let searchMenuItem = NSMenuItem()
        searchMenuItem.view = searchField
        statusMenu?.addItem(searchMenuItem)
        updateMenu()
        
        startMonitoringClipboard()
        
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let searchField = obj.object as? NSSearchField {
            searchFieldChanged(searchField)
        }
    }
    
    @objc func searchFieldChanged(_ sender: NSSearchField) {
        searchingTarget = sender.stringValue
        updateMenu()
    }
    
    func startMonitoringClipboard() {
        timer = Timer.scheduledTimer(timeInterval: recordInterval, target: self, selector: #selector(checkClipboard), userInfo: nil, repeats: true)
    }

    @objc func checkClipboard() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let copiedString = pasteboard.string(forType: .string) {
                addClipboardItem(copiedString)
            }
        }
    }

    func addClipboardItem(_ item: String) {
        clipboardHistory.insert(item, at: 0)
        if clipboardHistory.count > HistoryMaximum {  // 限制最大记录数为 10
            clipboardHistory.removeLast()
        }
        showingHistory = clipboardHistory
        updateMenu()
    }

    func updateMenu() {
        guard let menuItems = statusMenu?.items else { return }
            
        if menuItems.count > 2 {
            for index in (2..<menuItems.count).reversed() {
                statusMenu?.removeItem(at: index)
            }
        }
        if searchingTarget != "" {
            showingHistory = clipboardHistory.filter { $0.lowercased().contains(searchingTarget.lowercased()) }
        }else{
            showingHistory = clipboardHistory
        }
        
        for (index, Word) in showingHistory.enumerated() {
            let word = truncateString(input: Word)
            
            let menuItem = NSMenuItem(title: word, action: #selector(copyToClipboard(_:)), keyEquivalent: "")
            menuItem.tag = index
            statusMenu?.addItem(menuItem)
        }
        
        statusMenu?.addItem(NSMenuItem.separator())
        statusMenu?.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        statusMenu?.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    @objc func showPreferences() {
//        let preferencesWindowController = PreferencesWindowController(windowNibName: "PreferencesWindowController")
//        preferencesWindowController.showWindow(self)
    }
    
    func truncateString(input: String) -> String {
        var truncatedString = ""

        for character in input {
            if calculateStringWidth(truncatedString) > MenuItemMaxWidth {
                break
            }

            truncatedString.append(character)
        }

        if truncatedString != input {
            truncatedString += "..."
        }
        return truncatedString
    }
    func calculateStringWidth(_ string: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 16)

        let attributes = [NSAttributedString.Key.font: font]
        let size = (string as NSString).size(withAttributes: attributes)
        return size.width
    }
    
    @objc func copyToClipboard(_ sender: NSMenuItem) {
        let index = sender.tag
        let itemToCopy = showingHistory[index]
        clipboardHistory.removeAll { $0 == itemToCopy }

        updateMenu()
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(itemToCopy, forType: .string)
    }
    
    @objc func showMenu() {
        if let button = statusItem?.button {
            searchField.stringValue = ""
            searchFieldChanged(searchField)
            
            statusItem?.menu = statusMenu
            button.performClick(nil)
            statusItem?.menu = nil
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        timer?.invalidate()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

