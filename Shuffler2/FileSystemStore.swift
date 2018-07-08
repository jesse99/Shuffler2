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
    }
    
    func start() {
        self.images = enumerateDirectory()
    }

    func randomImage() -> Key? {
        // TODO: maybe this could return a random image from the first 100?
        // TODO: could time how long it takes to iterate over 1K
        // TODO: probably need to return something like a Result
        if images.count > 0 {
            let index = Int(arc4random_uniform(UInt32(images.count)))
            return FileSystemKey.init(images[index])
        } else {
            return nil
        }
    }
    
    func loadImage(_ key: Key) -> Data? {
        let fsKey = key as! FileSystemKey
        return try? Data.init(contentsOf: fsKey.url)
    }
    
    // TODO:
    // random should prefer better rating
    // set properties for keys we use?
    // preflight for images
    // use a thread to grab the first N files
    // have the thread keep going to grab the next M files
    //     could just use a mutex and directly mutate the image lists
    // re-run if the directory changes? or just re-schedule when get close to running out of files?
    private func enumerateDirectory() -> [URL] {
        var files: [URL] = []
        files.reserveCapacity(1000)
        
        // add N files from each directory to images
        let dirs = findUpcomingDirectories()
        print("dirs = \(dirs)")
        
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]
        let fs = FileManager.default
        if let enumerator = fs.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: options, errorHandler: nil) {
            for case let file as URL in enumerator {
                if !file.hasDirectoryPath {
                    files.append(file)      // TODO: need to store these in [Rating: [URL]]
                }
            }
        }
        
        return files
    }
    
    private func findUpcomingDirectories() -> [Directory] {
        var directories: [Directory] = []
        
        let upcoming = root.appendingPathComponent("upcoming")
        let app = NSApp.delegate as! AppDelegate

        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles, .skipsSubdirectoryDescendants]
        let fs = FileManager.default
        if let enumerator = fs.enumerator(at: upcoming, includingPropertiesForKeys: [.isDirectoryKey], options: options, errorHandler: nil) {
            for case let dir as URL in enumerator {
                if dir.hasDirectoryPath {
                    let name = dir.lastPathComponent
                    if name == "not-shown" {
                        directories.append(Directory(url: dir, rating: Rating.init(fromString: name)!, tags: []))
                    } else {
                        var tags = name.components(separatedBy: "-")
                        if let rating = Rating.init(fromString: tags[0]) {
                            tags.remove(at: 0)
                            directories.append(Directory(url: dir, rating: rating, tags: tags))
                        } else {
                            app.error("directory \(dir) has an invalid rating")
                        }
                    }
                }
            }
        }

        return directories
    }
    
    private struct Directory: CustomStringConvertible {
        let url: URL
        let rating: Rating
        let tags: [String]  // TODO: make this a type?
        
        var description: String {
            return url.description
        }
    }
    
    private let root: URL
    private var images: [URL] = []
//    private var images: [Rating: [URL]] = [:]
}
