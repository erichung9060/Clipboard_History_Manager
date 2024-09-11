import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var RememberingNumberTextField: NSTextField!
    @IBOutlet weak var DisplayingNumberTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = NSApp.delegate as? AppDelegate {
            RememberingNumberTextField.stringValue = "\(appDelegate.rememberingNumber)"
            DisplayingNumberTextField.stringValue = "\(appDelegate.displayingNumber)"
        }
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    
    @IBAction func UpdateRememberingNumber(_ sender: Any) {
        if let number = Int(RememberingNumberTextField.stringValue){
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.rememberingNumber = number
                appDelegate.checkClipBoardMaximum()
            }
        }
    }
    
    @IBAction func UpdateDisplayingNumber(_ sender: Any) {
        if let number = Int(DisplayingNumberTextField.stringValue){
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.displayingNumber = number
            }
        }
    }
}

