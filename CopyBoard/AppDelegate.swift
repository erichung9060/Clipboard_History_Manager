import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSSearchFieldDelegate {
    var displayingNumber = 100
    var rememberingNumber = 1000
    
    let recordInterval = 0.5
    let menuItemMaxWidth = 280.0
    
    var statusItem: NSStatusItem! = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var searchField: NSSearchField! = NSSearchField()
    var statusMenu: NSMenu! = NSMenu()
    
    var clipboardHistory: [String] = []
    var displayingHistory: [String] = []
    
    var lastChangeCount: Int = NSPasteboard.general.changeCount

    var timer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
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
        
        updateMenu()
        startMonitoringClipboard()
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
            statusMenu?.addItem(menuItem)
        }
        
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        statusMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    func truncateString(input: String) -> String {
        var truncatedString = ""

        for character in input {
            if calculateStringWidth(truncatedString) > menuItemMaxWidth {
                truncatedString += "..."
                break
            }

            if character == "\n"{
                truncatedString.append(" ")
            }else{
                truncatedString.append(character)
            }
        }

        return truncatedString
    }
    
    func calculateStringWidth(_ string: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 16)

        let attributes = [NSAttributedString.Key.font: font]
        let size = (string as NSString).size(withAttributes: attributes)
        return size.width
    }
    
    @objc func pasteBoardMonitor() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let copiedString = pasteboard.string(forType: .string) {
                clipboardHistory.insert(copiedString, at: 0)
                checkClipBoardMaximum()
                updateMenu()
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

        updateMenu()
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(itemToCopy, forType: .string)
    }
    
    @objc func showPreferences() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let preferencesWindowController = storyboard.instantiateController(withIdentifier: "PreferencesWindowController") as? NSWindowController
        preferencesWindowController?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showMenu() {
        if let button = statusItem.button {
            searchField.stringValue = ""
            updateMenu()
            
            statusItem.menu = statusMenu
            button.performClick(nil)
            statusItem.menu = nil
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
