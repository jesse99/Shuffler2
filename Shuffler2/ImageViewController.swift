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
    
    override func viewWillAppear() {
        setupWindow()
        nextImage()
    }
    
    func nextImage() {
        assert(currentIndex >= 0)
        assert(images.isEmpty || currentIndex < images.count)
        
        while true {
            if images.isEmpty || currentIndex >= images.count - 1 {
                let app = NSApp.delegate as! AppDelegate
                let key = app.store.randomImage()
                
                images.append(key)
                if images.count > 100 {     // we only allow the user to go backwards 100x
                    images.remove(at: 0)
                }
                currentIndex = images.count - 1

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
    
    func previousImage() {
        while true {
            if currentIndex > 0 {
                currentIndex -= 1
                if selectCurrent() {
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
    
    // This can return false if the user has deleted or moved the image.
    private func selectCurrent() -> Bool {
        let key = images[currentIndex]
        let app = NSApp.delegate as! AppDelegate
        if let data = app.store.loadImage(key) {
            _ = setImage(data, scaling: 1.0, align: .alignCenter)
            return true
        } else {
            print("failed to load \(key)")
            return false
        }
    }
    
    private func setImage(_ data: Data, scaling: CGFloat, align: NSImageAlignment) -> Bool {
        if let rep = NSBitmapImageRep.init(data: data) {
            var imageSize = rep.size
            let windowSize = view.window!.frame.size
            let maxScaling = min(windowSize.width/imageSize.width, windowSize.height/imageSize.height)
            
            if scaling == CGFloat.infinity {
                if maxScaling > 1.0 {
                    imageSize.width *= maxScaling
                    imageSize.height *= maxScaling
                    rep.size = imageSize
                }
            } else if (scaling != 1.0) {
                imageSize.width *= scaling
                imageSize.height *= scaling
                rep.size = imageSize
            }
            
            let image = NSImage.init(size: imageSize)
            image.addRepresentation(rep)
            imageView.image = image
            imageView.imageAlignment = align
            return true
        }
        return false
    }
    
    private func setupWindow() {
        let screen = NSScreen.screens[2]

        // Not sure why but couldn't get positioning to work in the ImageWindow.init method.
        let window = view.window
        window!.setFrame(screen.visibleFrame, display: true)
    }
    
    @IBOutlet private var imageView: NSImageView!
    
    private var images: [Key] = []
    private var currentIndex: Int = 0
}

