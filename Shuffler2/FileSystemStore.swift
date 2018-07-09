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
    
    func randomImage() -> Key? {
        let directories = findUpcomingDirectories()
        // TODO: prune directories using selected tags and rating
        if let directory = randomDirectory(directories), let originalFile = randomFile(directory) {
            if let newFile = moveFile(directory, originalFile) {
                return FileSystemKey.init(newFile)
            } else {
                return FileSystemKey.init(originalFile) // not ideal but shouldn't actually cause a problem
            }
        } else {
            // TODO: flip the directories (but only if randomDirectory failed)
            return nil
        }
    }
    
    func loadImage(_ key: Key) -> Data? {
        let fsKey = key as! FileSystemKey
        return try? Data.init(contentsOf: fsKey.url)
    }
    
    private func moveFile(_ originalDir: Directory, _ originalFile: URL) -> URL? {
        var dirName = ""
        if originalDir.rating == .notShown {
            dirName += "normal"
        } else {
            dirName += originalDir.rating.description
        }
        if !originalDir.tags.isEmpty {
            dirName += "-" + originalDir.tags.joined(separator: "-")
        }

        var newFile = root.appendingPathComponent("shown")
        newFile = newFile.appendingPathComponent(dirName)

        let fs = FileManager.default
        do {
            try fs.createDirectory(at: newFile, withIntermediateDirectories: true, attributes: [:])
        } catch let error as NSError {
            let app = NSApp.delegate as! AppDelegate
            app.error("Couldn't create \(newFile): \(error.localizedDescription)")
            return nil
        }

        newFile = newFile.appendingPathComponent(originalFile.lastPathComponent)
        do {
            try fs.moveItem(at: originalFile, to: newFile)
        } catch let error as NSError {
            let app = NSApp.delegate as! AppDelegate
            app.error("Couldn't move \(originalFile) to \(newFile): \(error.localizedDescription)")
            return nil
        }

        return newFile
    }
    
    private func findUpcomingDirectories() -> [Directory] {
        var directories: [Directory] = []
        
        let upcoming = root.appendingPathComponent("upcoming")
        let app = NSApp.delegate as! AppDelegate
        
        let fs = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles, .skipsSubdirectoryDescendants]
        if let enumerator = fs.enumerator(at: upcoming, includingPropertiesForKeys: [.isDirectoryKey, .nameKey], options: options, errorHandler: nil) {
            for case let dir as URL in enumerator {
                if dir.hasDirectoryPath {
                    if let (rating, tags) = getRatingAndTags(dir) {
                        directories.append(Directory(url: dir, rating: rating, tags: tags))
                    } else {
                        app.error("directory \(dir) has an invalid rating")
                    }
                }
            }
        }
        
        return directories
    }
    
    private func randomDirectory(_ directories: [Directory]) -> Directory? {
        let dirs = directories.filter {self.hasImage($0)}
        let maxWeight = dirs.reduce(0) {$0 + $1.rating.rawValue}
        if maxWeight > 0 {
            var n = Int(arc4random_uniform(UInt32(maxWeight)))
            for candidate in dirs {
                n -= candidate.rating.rawValue
                if n <= 0 {
                    return candidate
                }
            }
            assert(false)
        } else {
            // This is expected once we show all the pictures in incoming.
            let app = NSApp.delegate as! AppDelegate
            app.info("couldn't find a directory with an image")
        }
        return nil
    }
    
    // It's a lot easier to just do the enumeration on demand: we don't have to deal with thread coordination,
    // or the file system changing out from underneath us (as much), or weird special cases as we empty out
    // the upcoming directory.
    private func randomFile(_ directory: Directory) -> URL? {
        var n = Int(arc4random_uniform(100))    // to avoid spending too much time enumerating we'll use a 1 in 100 chance of picking each file
        var result: URL? = nil
        
        let start = DispatchTime.now()  // takes well under 10 ms to process 100 files
        var count = 0
        
        // It would be a bit nicer to start at a random spot in the directory (and maybe cycle around if need be).
        // But the high level APIs don't support that sort of random access iteration. Documentation is scarce
        // on the low level APIs but Darwin is derived from FreeBSD which has functions like seekdir which
        // supports resuming iteration which could be made to work.
        let fs = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]
        if let enumerator = fs.enumerator(at: directory.url, includingPropertiesForKeys: [.isDirectoryKey, .nameKey], options: options, errorHandler: nil) {
            for case let candidate as URL in enumerator {
                if canShow(candidate) {
                    count += 1
                    n -= 1
                    result = candidate
                    if n <= 0 {
                        break
                    }
                } else if !candidate.hasDirectoryPath {
                    let app = NSApp.delegate as! AppDelegate
                    app.error("can't show \(candidate)")
                }
            }
        }
        
        if result == nil {
            let app = NSApp.delegate as! AppDelegate
            app.warn("couldn't find an image in \(directory)")
        }
        
        // "0.1 second is about the limit for having the user feel that the system is reacting instantaneously"
        // see https://psychology.stackexchange.com/questions/1664/what-is-the-threshold-where-actions-are-perceived-as-instant
        let end = DispatchTime.now()
        let ns = end.uptimeNanoseconds - start.uptimeNanoseconds
        let us = ns/1000
        let ms = us/1000
        if ms > 100 {
            let app = NSApp.delegate as! AppDelegate
            app.warn("took \(ms) ms to enumerate \(count) files")
        }

        return result
    }
    
    private func getRatingAndTags(_ dir: URL) -> (Rating, [String])? {
        let name = dir.lastPathComponent
        if name == "not-shown" {
            return (Rating.init(fromString: name)!, tags: [])
        } else {
            var tags = name.components(separatedBy: "-")
            if let rating = Rating.init(fromString: tags[0]) {
                tags.remove(at: 0)
                return (rating, tags)
            }
        }
        return nil
    }
    
    private func hasImage(_ dir: Directory) -> Bool {
        let fs = FileManager.default
        
        // TODO: might want to special case aliases
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]
        if let enumerator = fs.enumerator(at: dir.url, includingPropertiesForKeys: [.isDirectoryKey, .nameKey], options: options, errorHandler: nil) {
            for case let file as URL in enumerator {
                if canShow(file) {
                    return true
                }
            }
        }
        return false
    }
    
    private func canShow(_ file: URL) -> Bool {
        if !file.hasDirectoryPath {
            let ext = file.pathExtension as CFString
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil) {
//                print("\(NSBitmapImageRep.imageTypes)")
                for case let type as CFString in NSBitmapImageRep.imageTypes {
                    if UTTypeConformsTo((uti.takeRetainedValue()), type) {
                        return true
                    }
                }
            }
        }
        return false
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
}
