//  Created by Jesse Jones on 7/1/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func error(_ text: String) {
        print(text)
    }
    
    // It'd be nicer to put these on the ImageViewController but that's a background sort of
    // window so it's not really part of the responder chain.
    @IBAction func nextImage(_ sender: Any) {
        imageView.nextImage()
    }
    
    @IBAction func previousImage(_ sender: Any) {
        imageView.previousImage()
    }
    
    var imageView: ImageViewController! = nil
    let store = FileSystemStore.init("/Users/jessejones/Source/Shuffler2/pictures")
}

