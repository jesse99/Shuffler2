//  Created by Jesse Jones on 7/1/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Cocoa

class ImageWindow: NSWindow {
    public override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        self.level = NSWindow.Level.init(Int(CGWindowLevelForKey(.desktopWindow)))    // note that the normal Level enums don't have an enum for behind Finder icons
        self.backgroundColor = NSColor.clear
        self.isExcludedFromWindowsMenu = true
        self.ignoresMouseEvents = true
        self.isOpaque = false
    }
    
    override var canBecomeMain: Bool {
        get {return false}
    }

    override var canBecomeKey: Bool {
        get {return false}
    }
}
