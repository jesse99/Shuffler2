//  Created by Jesse Jones on 7/2/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Foundation

// Concrete store class based on a file system URL.
struct FileSystemKey: Key {
    fileprivate init(_ url: URL) {
        self.url = url
    }
    
    public var description: String {get {return url.path}}
    
    fileprivate var url: URL
}

// Concrete store class fetching images from a local directory.
class FileSystemStore: Store {
    init(_ root: String) {
        self.root = root
    }
    
    func randomImage() -> Key {
        // TODO: maybe this could return a random image from the first 100?
        // TODO: could time how long it takes to iterate over 1K
        let path = "/Users/jessejones/Downloads/Screen Shot.png"
        let url = URL.init(fileURLWithPath: path)
        return FileSystemKey.init(url)
    }
    
    func loadImage(_ key: Key) -> Data? {
        let fsKey = key as! FileSystemKey
        return try? Data.init(contentsOf: fsKey.url)
    }
    
    private let root: String
}
