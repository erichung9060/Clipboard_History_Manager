//
//  ViewController.swift
//  CopyBoard
//
//  Created by 洪睿廷 on 2024/9/6.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var RememberingNumberTextField: NSTextField!
    @IBOutlet weak var DisplayingNumberTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("here")
        if let appDelegate = NSApp.delegate as? AppDelegate {
            RememberingNumberTextField.stringValue = "\(appDelegate.RememberingNumber)"
            DisplayingNumberTextField.stringValue = "\(appDelegate.DisplayingNumber)"
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    @IBAction func UpdateRememberingNumber(_ sender: Any) {
        if let number = Int(RememberingNumberTextField.stringValue){
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.RememberingNumber = number
                appDelegate.CheckClipboarMaximum()
            }
        }
    }
    
    @IBAction func UpdateDisplayingNumber(_ sender: Any) {
        if let number = Int(DisplayingNumberTextField.stringValue){
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.DisplayingNumber = number
            }
        }
    }
}

