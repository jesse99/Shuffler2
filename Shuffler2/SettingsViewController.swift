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
        view.window?.title = store.getName(key)
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
        
        let app = NSApp.delegate as! AppDelegate
        let scaling = store.getScaling(key)
        for item in scalingPopup.itemArray {
            if item.tag == scaling {
                scalingPopup.select(item)
                
                if scaling == -1 {
                    let amount = Int(app.imageView.currentScaling*100.0)
                    scalingPopup.itemArray.last?.title = "Max (\(amount)%)"
                } else {
                    scalingPopup.itemArray.last?.title = "Max"
                }
                break
            }
        }
        
        for title in store.availableTags().titles() {
            insertTag(title)
        }
        
        let tags = app.store.getTags(key)
        let text = tags.titles().joined(separator: " • ")
        tagsLabel.stringValue = text

        for item in tagsPopup.menu!.items {
            if item.isSeparatorItem {
                break
            }
            item.state = tags.contains(item.title) ? .on : .off
        }
    }
    
    @IBAction func noScaling(_ sender: Any) {
        if let key = currentKey {
            let app = NSApp.delegate as! AppDelegate
            app.store.setScaling(key, 0)
            app.imageView.refresh()
        }
    }
    
    @IBAction func maxScaling(_ sender: Any) {
        if let key = currentKey {
            let app = NSApp.delegate as! AppDelegate
            app.store.setScaling(key, -1)
            app.imageView.refresh()
        }
    }
    
    @IBAction func scaleUsing(_ sender: Any) {
        let item = sender as! NSMenuItem
        if let key = currentKey {
            let app = NSApp.delegate as! AppDelegate
            app.store.setScaling(key, item.tag)
            app.imageView.refresh()
        }
    }
    
    @IBAction func setRating(_ sender: Any) {
        let item = sender as! NSMenuItem
        if let key = currentKey {
            let app = NSApp.delegate as! AppDelegate
            if let rating = Rating.init(fromString: item.title) {
                app.store.setRating(key, rating)
            } else {
                update(app.store, key)
            }
        }
    }
    
    @IBAction func newTag(_ sender: Any) {
        if let key = currentKey {
            let app = NSApp.delegate as! AppDelegate
            if let tag = getString(title: "New Tag", defaultValue: ""), tag != "" {
                app.store.addTag(key, tag)
                tagsPopup.selectItem(at: -1)
                update(app.store, key)
            }
        }
    }
    
    @objc func toggleTag(_ sender: Any) {
        if let key = currentKey {
            let app = NSApp.delegate as! AppDelegate
            let item = sender as! NSMenuItem

            if app.store.getTags(key).contains(item.title) {
                app.store.removeTag(key, item.title)
                tagsPopup.selectItem(at: -1)
                update(app.store, key)
            } else {
                app.store.addTag(key, item.title)
                tagsPopup.selectItem(at: -1)
                update(app.store, key)
            }
        }
    }
    
    private func insertTag(_ title: String) {
        for (index, item) in tagsPopup.menu!.items.enumerated() {
            if item.title == title {
                break
            } else if item.isSeparatorItem || item.title >= title {
                tagsPopup.menu!.insertItem(withTitle: title, action: #selector(toggleTag(_:)), keyEquivalent: "", at: index)
                break
            }
        }
    }
    
    @IBOutlet var ratingsPopup: NSPopUpButton!
    @IBOutlet var scalingPopup: NSPopUpButton!
    @IBOutlet var tagsPopup: NSPopUpButton!
    @IBOutlet var tagsLabel: NSTextField!
    
    private var currentKey: Key? = nil
}

