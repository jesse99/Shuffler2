//  Created by Jesse Jones on 7/1/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Cocoa

class ImageViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear() {
        setupWindow()
        
        let path = "/Users/jessejones/Downloads/Screen Shot.png"
        _ = setImage(path, scaling: 1.0, align: .alignCenter)
    }
    
    func setImage(_ path: String, scaling: CGFloat, align: NSImageAlignment) -> Bool {
        if let rep = NSImageRep.init(contentsOfFile: path) {
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
}

