//  Created by Jesse Jones on 7/14/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Cocoa
import AppKit

class SettingsViewController: NSViewController {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let app = NSApp.delegate as! AppDelegate
        app.settingsView = self
    }
    
    public func update(_ store: Store, _ key: Key) {
        currentKey = key
        if let rating = store.getRating(key) {
            switch rating {
            case .notShown: ratingsPopup.selectItem(at: 0)
            case .normal: ratingsPopup.selectItem(at: 1)
            case .good: ratingsPopup.selectItem(at: 2)
            case .great: ratingsPopup.selectItem(at: 3)
            case .fantastic: ratingsPopup.selectItem(at: 4)
            }
        } else {
            ratingsPopup.selectItem(at: 0)
        }
    }
    
    @IBAction func noScaling(_ sender: Any) {
    }
    
    @IBAction func maxScaling(_ sender: Any) {
    }
    
    @IBAction func scaleUsing(_ sender: Any) {
    }
    
    @IBAction func setRating(_ sender: Any) {
        let item = sender as! NSMenuItem
        if let rating = Rating.init(fromString: item.title), let key = currentKey {
            let app = NSApp.delegate as! AppDelegate
            app.store.setRating(key, rating)
        }
    }
    
    @IBAction func newTag(_ sender: Any) {
    }
    
    @IBOutlet var ratingsPopup: NSPopUpButton!
    @IBOutlet var scalingPopup: NSPopUpButton!
    @IBOutlet var tagsPopup: NSPopUpButton!
    @IBOutlet var tagsLabel: NSTextField!
    
    private var currentKey: Key? = nil
}

