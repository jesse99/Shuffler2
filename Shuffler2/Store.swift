//  Created by Jesse Jones on 7/2/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Foundation

// Used by stores to identify an image.
protocol Key: CustomStringConvertible {
}

// Interface used to access images.
protocol Store {
    func randomImage() -> Key
    
    func loadImage(_ key: Key) -> Data?
}
