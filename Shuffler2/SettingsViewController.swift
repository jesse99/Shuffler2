//  Created by Jesse Jones on 7/14/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Cocoa
import AppKit

class SettingsViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let app = NSApp.delegate as! AppDelegate
//        app.imageView = self
    }
    
    override func viewWillAppear() {
    }
    
    @IBAction func noScaling(_ sender: Any) {
    }
    
    @IBAction func maxScaling(_ sender: Any) {
    }
    
    @IBAction func scaleUsing(_ sender: Any) {
    }
    
    @IBAction func setRating(_ sender: Any) {
    }
    
    @IBAction func newTag(_ sender: Any) {
    }
    
    @IBOutlet var ratingsPopup: NSPopUpButton!
    @IBOutlet var scalingPopup: NSPopUpButton!
    @IBOutlet var tagsPopup: NSPopUpButton!
    @IBOutlet var tagsLabel: NSTextField!
}

