import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSSearchFieldDelegate {
    var displayingNumber = 100
    var rememberingNumber = 1000
    
    let recordInterval = 0.5
    let menuItemMaxWidth = 300.0
    
    var statusItem: NSStatusItem! = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var searchField: NSSearchField! = NSSearchField()
    var statusMenu: NSMenu! = NSMenu()

    var clipboardHistory: [String] = []
    var displayingHistory: [String] = []
    
    var lastChangeCount: Int = NSPasteboard.general.changeCount

    var timer: Timer?
    
    let fileManager = FileManager.default
    var historyFileURL: URL {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.copyboard"
        let appFolderURL = appSupportURL.appendingPathComponent(bundleID)
        return appFolderURL.appendingPathComponent("clipboard_history.txt")
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        createApplicationSupportDirectory()
        
        // set menu button
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
            button.action = #selector(showMenu)
            button.target = self
        }
        
        // set search field
        searchField.frame = NSRect(x: 10, y: 0, width: 330 - 2 * 10, height: 27)
        searchField.placeholderString = "Search history..."
        searchField.target = self
        searchField.delegate = self
        
        // add search field into Menu
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 330, height: 27))
        containerView.addSubview(searchField)
        let searchMenuItem = NSMenuItem()
        searchMenuItem.view = containerView
        
        statusMenu.addItem(searchMenuItem)
        statusMenu.addItem(NSMenuItem.separator())
        
        startMonitoringClipboard()
    }
    
    func createApplicationSupportDirectory() {
        let fileURL = historyFileURL
        let directoryURL = fileURL.deletingLastPathComponent()
        
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            print("Error creating directory: \(error)")
        }
    }
    
    func loadHistoryFromFile() {
        do {
            let data = try Data(contentsOf: historyFileURL)
            if let history = try JSONSerialization.jsonObject(with: data) as? [String] {
                clipboardHistory = history
            }
        } catch {
            print("Error loading history: \(error)")
            clipboardHistory = []
        }
    }
    
    func saveHistoryToFile() {
        do {
            let data = try JSONSerialization.data(withJSONObject: clipboardHistory)
            try data.write(to: historyFileURL)
        } catch {
            print("Error saving history: \(error)")
        }
    }
    
    func updateMenu() {
        while statusMenu.items.count > 2 {
            statusMenu.removeItem(at: 2)
        }

        if searchField.stringValue != "" {
            displayingHistory = clipboardHistory.filter { $0.lowercased().contains(searchField.stringValue.lowercased()) }
        }else{
            displayingHistory = Array(clipboardHistory.prefix(displayingNumber))
        }
        
        for (index, Word) in displayingHistory.enumerated() {
            let word = truncateString(input: Word)
            
            let menuItem = NSMenuItem(title: word, action: #selector(copyToClipboard(_:)), keyEquivalent: "")
            menuItem.tag = index
            statusMenu.addItem(menuItem)
        }
        
        if displayingHistory.count != 0 { statusMenu.addItem(NSMenuItem.separator()) }
        statusMenu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearClipboardHistory), keyEquivalent: "c"))
        statusMenu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        statusMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    

    func truncateString(input: String) -> String {
        let font = NSFont.systemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        var truncatedString = ""
        var currentWidth: CGFloat = 0
        let ellipsisWidth = (" ..." as NSString).size(withAttributes: attributes).width

        for character in input {
            let charStr = String(character) as NSString
            let charWidth = charStr.size(withAttributes: attributes).width

            if currentWidth + charWidth + ellipsisWidth > menuItemMaxWidth {
                truncatedString += " ..."
                break
            }

            if character == "\n" || character == "\r" || character == "\t" {
                truncatedString.append(" ")
                currentWidth += (" " as NSString).size(withAttributes: attributes).width
            } else {
                truncatedString.append(character)
                currentWidth += charWidth
            }
        }

        return truncatedString
    }
    
    @objc func pasteBoardMonitor() { // new copied string
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let copiedString = pasteboard.string(forType: .string) {
                loadHistoryFromFile()
                
                clipboardHistory.insert(copiedString, at: 0)
                checkClipBoardMaximum()
                
                saveHistoryToFile()
                clipboardHistory.removeAll()
            }
        }
    }

    func checkClipBoardMaximum(){
        while(clipboardHistory.count > rememberingNumber){
            clipboardHistory.removeLast()
        }
    }
    
    @objc func copyToClipboard(_ sender: NSMenuItem) {
        let index = sender.tag
        let itemToCopy = displayingHistory[index]
        clipboardHistory.removeAll { $0 == itemToCopy }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(itemToCopy, forType: .string)
    }
    
    @objc func clearClipboardHistory() {
        clipboardHistory.removeAll()
    }
    
    @objc func showPreferences() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let preferencesWindowController = storyboard.instantiateController(withIdentifier: "PreferencesWindowController") as? NSWindowController
        preferencesWindowController?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showMenu() {
        if let button = statusItem.button {
            loadHistoryFromFile()
            
            searchField.stringValue = ""
            updateMenu()
            
            statusItem.menu = statusMenu
            button.performClick(nil)
            statusItem.menu = nil
            
            saveHistoryToFile()

            while statusMenu.items.count > 2 {
                statusMenu.removeItem(at: 2)
            }
            clipboardHistory.removeAll()
            displayingHistory.removeAll()
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateMenu()
    }
    
    func startMonitoringClipboard() {
        timer = Timer.scheduledTimer(timeInterval: recordInterval, target: self, selector: #selector(pasteBoardMonitor), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        timer?.invalidate()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
