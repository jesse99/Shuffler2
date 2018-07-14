//  Created by Jesse Jones on 7/1/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Cocoa

let picturesDir = "/Users/jessejones/Source/Shuffler2/pictures"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    override init() {
        let logPath = "\(picturesDir)/shuffler2.log"
        
        let fm = FileManager.default
        fm.createFile(atPath: logPath, contents: nil, attributes: nil)
        logFile = FileHandle.init(forWritingAtPath: logPath)!
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        toggleItem(normalItem)

        let newTags = store.availableTags()
        addNewTags(newTags)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func info(_ text: String) {
        logLine(text)
    }
    
    func warn(_ text: String) {
        logLine("warning: " + text)
    }
    
    func error(_ text: String) {
        logLine("error: " + text)
        logFile.synchronizeFile()
        
        notifyUser(text)
    }
    
    // It'd be nicer to put these on the ImageViewController but that's a background sort of
    // window so it's not really part of the responder chain.
    @IBAction func nextImage(_ sender: Any) {
        imageView.nextImage()
        
        let newTags = store.availableTags()
        removeMissingTags(newTags)
        addNewTags(newTags)
    }
    
    @IBAction func previousImage(_ sender: Any) {
        imageView.previousImage()
    }
    
    @IBAction func open(_ sender: Any) {
        imageView.openImage(store)
    }
    
    @IBAction func show(_ sender: Any) {
        imageView.showImage(store)
    }
    
    @IBAction func trash(_ sender: Any) {
        imageView.trashImage(store)
    }
    
    @IBAction func showRating(_ sender: Any) {
        let item = sender as! NSMenuItem
        if let rating = Rating.init(fromString: item.title) {
            imageView.useRating(rating)
            toggleItem(item)
        } else {
            error("unknown rating: \(item.title)")
        }
    }
    
    @objc func toggleTag(_ sender: Any) {
        let item = sender as! NSMenuItem
        toggleShown(item.title)
    }
    
    @IBAction func toggleIncludeNotShown(_ sender: Any) {
        if store.includeNotShown {
            store.includeNotShown = false
            notShownItem.state = .off

        } else {
            store.includeNotShown = true
            notShownItem.state = .on
        }
    }
    
    var imageView: ImageViewController! = nil
    let store = FileSystemStore.init(picturesDir)
    
    private func toggleShown(_ title: String) {
        if store.showTags.remove(title) {
            checkShown(title, false)
        } else {
            store.showTags.add(title)
            checkShown(title, true)
        }
    }
    
    private func logLine(_ text: String) {
        print(text)
        
        let data = text.data(using: .utf8)
        logFile.write(data!)
        
        let data2 = "\n".data(using: .utf8)
        logFile.write(data2!)
    }

    private func notifyUser(_ text: String) {
        let notification = NSUserNotification()
        notification.identifier = "shuffler-error2" // 2 because the OS seems to get confused and stop showinng alerts if you fiddle around with prefs
        notification.title = "Shuffler2 Error"
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.hasActionButton = false    // this will give us just a Close button

        let center = NSUserNotificationCenter.default
        center.delegate = self
        center.deliver(notification)
    }
    
    private func toggleItem(_ item: NSMenuItem) {
        normalItem.state = .off
        goodItem.state = .off
        greatItem.state = .off
        fantasticItem.state = .off

        item.state = .on
    }
    
    private func removeMissingTags(_ newTags: Tags) {
        var deadpool: [NSMenuItem] = []
        
        for item in showTagsMenu.items {
            if item.isSeparatorItem {
                break
            }
            if !newTags.contains(item.title) {
                deadpool.append(item)
            }
        }
        
        for item in deadpool {
            showTagsMenu.removeItem(item)
        }
    }
    
    private func addNewTags(_ newTags: Tags) {
        let titles = newTags.titles()
        for title in titles {
            insertTag(title)
        }
    }
    
    private func insertTag(_ title: String) {
        for (index, item) in showTagsMenu.items.enumerated() {
            if item.title == title {
                break
            } else if item.isSeparatorItem || item.title >= title {
                showTagsMenu.insertItem(withTitle: title, action: #selector(toggleTag(_:)), keyEquivalent: "", at: index)
                break
            }
        }
    }
    
    private func checkShown(_ title: String, _ on: Bool) {
        for item in showTagsMenu.items {
            if item.title == title {
                item.state = on ? .on : .off
                return
            }
        }
        assert(false)
    }
    
    @IBOutlet weak var normalItem: NSMenuItem!
    @IBOutlet weak var goodItem: NSMenuItem!
    @IBOutlet weak var greatItem: NSMenuItem!
    @IBOutlet weak var fantasticItem: NSMenuItem!
    @IBOutlet weak var showTagsMenu: NSMenu!
    @IBOutlet weak var notShownItem: NSMenuItem!
    
    private var logFile: FileHandle
}

