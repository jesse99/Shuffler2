//  Created by Jesse Jones on 7/15/18.
//  Copyright © 2018 MushinApps. All rights reserved.
//
import Foundation
import Cocoa
import AppKit

func getString(title: String, defaultValue: String) -> String? {
    let alert = NSAlert()
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    alert.messageText = title
    //alert.informativeText = question
    
    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.stringValue = defaultValue
    
    alert.accessoryView = textField
    //alert.window.makeFirstResponder(textField)
    let response = alert.runModal()
    
    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
        return textField.stringValue
    } else {
        return nil
    }
}
