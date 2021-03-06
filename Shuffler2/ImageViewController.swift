//  Created by Jesse Jones on 7/1/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Cocoa
import AppKit

class ImageViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app = NSApp.delegate as! AppDelegate
        app.imageView = self
    }
    
    public func startedUp() {
        setupWindow(1)
        nextImage()
    }
    
    public func setupWindow(_ screenIndex: Int) {
        self.screenIndex = screenIndex
        let screen = NSScreen.screens[screenIndex]
        
        // Not sure why but couldn't get positioning to work in the ImageWindow.init method.
        let window = view.window
        window!.setFrame(screen.visibleFrame, display: true)

        // Probably related: somehow the window height creeps up as images are made large.
        windowSize = view.window!.frame.size
    }
    
    public func useRating(_ rating: Rating) {
        self.rating = rating
    }
    
    public private(set) var currentScaling: CGFloat = 1.0

    public func refresh() {
        _ = selectCurrent()
    }
    
    public func nextImage() {
        assert(currentIndex >= 0)
        assert(images.isEmpty || currentIndex <= images.count)
        
        while true {
            if images.isEmpty || currentIndex >= images.count - 1 {
                let app = NSApp.delegate as! AppDelegate
                if let key = app.store.randomImage(rating) {
                    images.append(key)
                    if images.count > 100 {     // we only allow the user to go backwards 100x
                        images.remove(at: 0)
                    }
                    currentIndex = images.count - 1
                } else {
                    NSSound.beep()
                    return
                }

            } else {
                currentIndex += 1
            }

            if selectCurrent() {
                break
            } else {
                images.remove(at: currentIndex)
            }
        }
    }
    
    public func previousImage() {
        while true {
            if currentIndex > 0 {
                currentIndex -= 1
                if selectCurrent() {
                    let app = NSApp.delegate as! AppDelegate
                    app.resetTimer()
                    break
                } else {
                    images.remove(at: currentIndex)
                }
            } else {
                NSSound.beep()
                break
            }
        }
    }
    
    public func openImage(_ store: Store) {
        if currentIndex >= 0 && currentIndex < images.count {
            let app = NSApp.delegate as! AppDelegate
            app.store.openImage(images[currentIndex])
            app.resetTimer()
        } else {
            NSSound.beep()
        }
    }
    
    public func showImage(_ store: Store) {
        if currentIndex >= 0 && currentIndex < images.count {
            let app = NSApp.delegate as! AppDelegate
            app.store.showImage(images[currentIndex])
            app.resetTimer()
        } else {
            NSSound.beep()
        }
    }
    
    public func trashImage(_ store: Store) {
        if currentIndex >= 0 && currentIndex < images.count {
            let app = NSApp.delegate as! AppDelegate
            app.store.trashImage(images[currentIndex])
            app.resetTimer()

            images.remove(at: currentIndex)
            nextImage()
        } else {
            NSSound.beep()
        }
    }
    
    // This can return false if the user has deleted or moved the image.
    private func selectCurrent() -> Bool {
        let key = images[currentIndex]
        let app = NSApp.delegate as! AppDelegate
        if let data = app.store.loadImage(key) {
            _ = setImage(data, scaling: getScaling(), align: getAlignment())
            app.settingsView.update(app.store, key)
            return true
        } else {
            print("failed to load \(key)")
            return false
        }
    }
    
    private func getScaling() -> CGFloat {
        let key = images[currentIndex]
        let app = NSApp.delegate as! AppDelegate
        let scaling = app.store.getScaling(key)
        switch scaling {
        case 0: return 1.0
        case -1: return 1000.0
        default: return CGFloat(scaling)/100.0
        }
    }
    
    private func getAlignment() -> NSImageAlignment {
        let key = images[currentIndex]
        let app = NSApp.delegate as! AppDelegate
        return app.store.getAlignment(key)
    }
    
    private func setImage(_ data: Data, scaling: CGFloat, align: NSImageAlignment) -> Bool {
        // TODO: setupWindow also seems to be too early for this
        let screen = NSScreen.screens[screenIndex]
        let window = view.window
        window!.setFrame(screen.visibleFrame, display: true)
        windowSize = view.window!.frame.size

        if let rep = NSBitmapImageRep.init(data: data) {
            var imageSize = NSSize.init(width: rep.pixelsWide, height: rep.pixelsHigh)
            let maxScaling = min(windowSize.width/imageSize.width, windowSize.height/imageSize.height)
//            print("windowSize = \(windowSize)")
//            print("   maxScaling = \(maxScaling)")
//            print("   imageSize = \(imageSize)")
            
            currentScaling = min(scaling, maxScaling)
            imageSize.width *= currentScaling
            imageSize.height *= currentScaling
            rep.size = imageSize
//            print("   imageSize = \(imageSize)")

            let image = NSImage.init(size: imageSize)
            image.addRepresentation(rep)
            imageView.image = image
            imageView.imageAlignment = align
            return true
        }
        return false
    }
    
    @IBOutlet private var imageView: NSImageView!
    
    private var images: [Key] = []
    private var currentIndex: Int = 0
    private var rating = Rating.normal      // if this is changed then we'll also need to ensure that the menu is synced up
    private var windowSize: CGSize = CGSize.init()
    private var screenIndex = 0
}

