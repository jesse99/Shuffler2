//  Created by Jesse Jones on 7/2/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Foundation
import Cocoa

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
        self.root = URL.init(fileURLWithPath: root)
        self.images = enumerateDirectory()
    }
    
    func randomImage() -> Key {
        // TODO: maybe this could return a random image from the first 100?
        // TODO: could time how long it takes to iterate over 1K
        // TODO: probably need to return something like a Result
        let index = Int(arc4random_uniform(UInt32(images.count)))
        return FileSystemKey.init(images[index])
    }
    
    func loadImage(_ key: Key) -> Data? {
        let fsKey = key as! FileSystemKey
        return try? Data.init(contentsOf: fsKey.url)
    }
    
    private func enumerateDirectory() -> [URL] {
        var files: [URL] = []
        files.reserveCapacity(1000)
        
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]
        let fs = FileManager.default
        if let enumerator = fs.enumerator(at: root, includingPropertiesForKeys: [], options: options, errorHandler: nil) {
            for case let file as URL in enumerator {
                if !file.hasDirectoryPath {
                    files.append(file)
                }
            }
        }
        
        return files
    }
    
    private let root: URL
    private var images: [URL] = []
}
