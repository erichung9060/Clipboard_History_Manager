import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSSearchFieldDelegate {
    var displayingNumber = 10
    var rememberingNumber = 100
    
    let recordInterval = 0.5
    let menuItemMaxWidth:Double = 280
    
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?
    var searchField = NSSearchField(frame: NSRect(x: 0, y: 0, width: 330, height: 28))
    
    var clipboardHistory: [String] = []
    
    var lastChangeCount: Int = NSPasteboard.general.changeCount

    var timer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
            button.action = #selector(showMenu)
            button.target = self
        }
        
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
    
    @objc func showPreferences() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let preferencesWindowController = storyboard.instantiateController(withIdentifier: "PreferencesWindowController") as? NSWindowController
        preferencesWindowController?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateMenu()
    }

    func updateMenu() {
        while statusMenu?.items.count ?? 0 > 2 {
            statusMenu?.removeItem(at: 2)
        }
        
        var displayingHistory: [String] = []
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
        
        statusMenu?.addItem(NSMenuItem.separator())
        statusMenu?.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        statusMenu?.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
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
        let itemToCopy = clipboardHistory[index]
        clipboardHistory.removeAll { $0 == itemToCopy }

        updateMenu()
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(itemToCopy, forType: .string)
    }
    
    @objc func showMenu() {
        if let button = statusItem?.button {
            searchField.stringValue = ""
            updateMenu()
            
            statusItem?.menu = statusMenu
            button.performClick(nil)
            statusItem?.menu = nil
        }
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
