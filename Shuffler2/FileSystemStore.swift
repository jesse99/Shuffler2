//  Created by Jesse Jones on 7/2/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Foundation
import Cocoa

extension Tags {
    func makeName(_ rating: Rating) -> String {
        var dirName = rating.description
        
        let tags = self.tags.sorted()
        if !tags.isEmpty {
            dirName += "-" + tags.joined(separator: "-")
        }
        return dirName
    }
}

// Concrete store class based on a file system URL.
class FileSystemKey: Key {
    fileprivate init(_ url: URL) {
        self.url = url
    }
    
    public func updateUrl(_ url: URL) {
        self.url = url
    }
    
    public func getInt(_ name: String) -> Int? {
        if let text = getString(name) {
            return Int(text)
        } else {
            return nil
        }
    }
    
    public func setInt(_ name: String, _ value: Int) {
        let text = "\(value)"
        setString(name, text)
    }
    
    // These can be viewed using the command line like so:
    // xattr -p scaling <path to file>
    public func getString(_ name: String) -> String? {
        let bytes = getxattr(url.path, name, nil, 0, 0, 0)
        if bytes > 0 {
            let buffer = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: MemoryLayout<Int8>.alignment)
            defer {
                buffer.deallocate()
            }
            _ = getxattr(url.path, name, buffer, bytes, 0, 0)

            let data = Data(bytes: buffer, count: bytes)
//            print("loading \(data as NSData)")
            return String.init(data: data, encoding: .utf8)
        }
        return nil
    }
    
    public func setString(_ name: String, _ value: String) {
        if let data = value.data(using: .utf8) {
//            print("saving \(data as NSData)")
            data.withUnsafeBytes {(ptr: UnsafePointer<UInt8>) -> Void in
                let buffer = UnsafeRawPointer(ptr)
                let result = setxattr(url.path, name, buffer, data.count, 0, 0)
                if result < 0 {
                    print("failed to set \(name) to \(value)")
                }
            }
        }
    }
    
    public var description: String {get {return url.path}}
    
    fileprivate var url: URL
}

// Concrete store class fetching images from a local directory.
class FileSystemStore: Store {
    init(_ root: String) {
        self.root = URL.init(fileURLWithPath: root)
    }
    
    func randomImage(_ rating: Rating) -> Key? {
        var directories = findInUseDirectories(rating)
        if directories.isEmpty {
            flipDirectories()
            directories = findInUseDirectories(rating)
        }

        if let directory = randomDirectory(directories), let originalFile = randomFile(directory) {
            if let newFile = moveFile(directory, originalFile) {
                return FileSystemKey.init(newFile)
            } else {
                return FileSystemKey.init(originalFile) // not ideal but shouldn't actually cause a problem
            }
        } else {
            return nil
        }
    }
    
    func loadImage(_ key: Key) -> Data? {
        let fsKey = key as! FileSystemKey
        return try? Data.init(contentsOf: fsKey.url)
    }
    
    func openImage(_ key: Key) {
        let fsKey = key as! FileSystemKey
        if !NSWorkspace.shared.openFile(fsKey.url.path) {
            NSSound.beep()
        }
    }
    
    func showImage(_ key: Key) {
        let fsKey = key as! FileSystemKey
        if !NSWorkspace.shared.selectFile(fsKey.url.path, inFileViewerRootedAtPath: "") {
            NSSound.beep()
        }
    }
    
    func trashImage(_ key: Key) {
        let fsKey = key as! FileSystemKey
        do {
            try FileManager.default.trashItem(at: fsKey.url, resultingItemURL: nil)
        } catch {
            NSSound.beep()
        }
    }
    
    func getName(_ key: Key) -> String {
        let fsKey = key as! FileSystemKey
        return fsKey.url.deletingPathExtension().lastPathComponent
    }
    
    func getRating(_ key: Key) -> Rating? {
        let fsKey = key as! FileSystemKey
        let dir = fsKey.url.deletingLastPathComponent()
        if let (rating, _) = getRatingAndTags(dir) {
            return rating
        }
        return nil
    }
    
    func setRating(_ key: Key, _ rating: Rating) {
        let fsKey = key as! FileSystemKey
        let dir = fsKey.url.deletingLastPathComponent()

        var dirName = rating.description
        if let (_, tags) = getRatingAndTags(dir) {
            dirName = tags.makeName(rating)
        }
        if let newUrl = moveFileTo(dirName, fsKey.url) {
            fsKey.updateUrl(newUrl)
        }
    }
    
    func getScaling(_ key: Key) -> Int {
        let fsKey = key as! FileSystemKey
        return fsKey.getInt("scaling") ?? 0
    }
    
    func setScaling(_ key: Key, _ scaling: Int) {
        let fsKey = key as! FileSystemKey
        fsKey.setInt("scaling", scaling)
    }
    
    func getTags(_ key: Key) -> Tags {
        let fsKey = key as! FileSystemKey
        let dir = fsKey.url.deletingLastPathComponent()

        if let (_, tags) = getRatingAndTags(dir) {
            return tags
        }
        return Tags.init()
    }
    
    func addTag(_ key: Key, _ inTag: String) {
        let fsKey = key as! FileSystemKey
        let dir = fsKey.url.deletingLastPathComponent()
        
        var (rating, tags) = getRatingAndTags(dir) ?? (Rating.normal, Tags.init())
        if rating == .notShown {
            rating = .normal
        }
        
        let tag = inTag.trimmingCharacters(in: .whitespaces)
        if tag != "" && !tags.contains(tag) {
            tags.add(tag)
            allTags.add(tag)

            let dirName = tags.makeName(rating)
            if let newUrl = moveFileTo(dirName, fsKey.url) {
                fsKey.updateUrl(newUrl)
            }
        }
    }
    
    func removeTag(_ key: Key, _ inTag: String) {
        let fsKey = key as! FileSystemKey
        let dir = fsKey.url.deletingLastPathComponent()
        
        var (rating, tags) = getRatingAndTags(dir) ?? (Rating.normal, Tags.init())
        if rating == .notShown {
            rating = .normal
        }
        
        let tag = inTag.trimmingCharacters(in: .whitespaces)
        if tags.remove(tag) {
            let dirName = tags.makeName(rating)
            if let newUrl = moveFileTo(dirName, fsKey.url) {
                fsKey.updateUrl(newUrl)
            }
        }
    }
    
    func availableTags() -> Tags {
        return allTags
    }
    
    public var showTags = Tags.init()
    
    public var includeNotShown: Bool = true

    private func flipDirectories() {
        let newDir = root.appendingPathComponent("shown")
        let app = NSApp.delegate as! AppDelegate

        // Move directories that still contain images into shown.
        let fs = FileManager.default
        let directories = findUpcomingDirectories()
        for dir in directories {
            if hasImage(dir) {
                var newUrl = newDir.appendingPathComponent(dir.url.lastPathComponent)
                do {
                    var index = 1
                    while fs.fileExists(atPath: newUrl.path) {
                        newUrl = newUrl.appendingPathComponent("\(index)")
                        index += 1
                    }
                    try fs.moveItem(at: dir.url, to: newUrl)
                    app.info("moved \(dir.url) to \(newUrl)")
                } catch let error as NSError {
                    app.error("couldn't move \(dir.url) to \(newUrl): \(error.localizedDescription)")
                }
            }
        }

        // Flip the shown and upcoming directories.
        var srcDir = root.appendingPathComponent("shown")
        var dstDir = root.appendingPathComponent("new-upcoming")
        do {
            try fs.moveItem(at: srcDir, to: dstDir)
            app.info("moved \(srcDir) to \(dstDir)")

            srcDir = root.appendingPathComponent("upcoming")
            dstDir = root.appendingPathComponent("shown")
            try fs.moveItem(at: srcDir, to: dstDir)
            app.info("moved \(srcDir) to \(dstDir)")

            srcDir = root.appendingPathComponent("new-upcoming")
            dstDir = root.appendingPathComponent("upcoming")
            try fs.moveItem(at: srcDir, to: dstDir)
            app.info("moved \(srcDir) to \(dstDir)")
        } catch let error as NSError {
            app.error("couldn't move \(srcDir) to \(dstDir): \(error.localizedDescription)")
        }
    }
    
    private func moveFile(_ originalDir: Directory, _ originalFile: URL) -> URL? {
        let dirName = originalDir.tags.makeName(originalDir.rating)
        return moveFileTo(dirName, originalFile)
    }
    
    private func moveFileTo(_ dirName: String, _ originalFile: URL) -> URL? {
        var newDir = root.appendingPathComponent("shown")
        newDir = newDir.appendingPathComponent(dirName)

        let fs = FileManager.default
        do {
            try fs.createDirectory(at: newDir, withIntermediateDirectories: true, attributes: [:])
        } catch let error as NSError {
            let app = NSApp.delegate as! AppDelegate
            app.error("Couldn't create \(newDir): \(error.localizedDescription)")
            return nil
        }

        let newFile = generateNewName(newDir, originalFile)
        do {
            try fs.moveItem(at: originalFile, to: newFile)
        } catch let error as NSError {
            let app = NSApp.delegate as! AppDelegate
            app.error("Couldn't move \(originalFile) to \(newFile): \(error.localizedDescription)")
            return nil
        }

        return newFile
    }
    
    private func findInUseDirectories(_ rating: Rating) -> [Directory] {
        var directories = findUpcomingDirectories()
        directories = directories.filter {$0.rating >= rating}
        directories = directories.filter {self.tagsMatch($0)}
        directories = directories.filter {self.hasImage($0)}
        return directories
    }
    
    private func tagsMatch(_ dir: Directory) -> Bool {
        if includeNotShown && dir.rating == .notShown {
            return true
        }
        for required in showTags.tags {
            if !dir.tags.contains(required) {
                return false
            }
        }
        return true
    }
    
    private func findUpcomingDirectories() -> [Directory] {
        var directories: [Directory] = []
        allTags.removeAll()
        
        let upcoming = root.appendingPathComponent("upcoming")
        let app = NSApp.delegate as! AppDelegate
        
        let fs = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles, .skipsSubdirectoryDescendants]
        if let enumerator = fs.enumerator(at: upcoming, includingPropertiesForKeys: [.isDirectoryKey, .nameKey], options: options, errorHandler: nil) {
            for case let dir as URL in enumerator {
                if dir.hasDirectoryPath {
                    if let (rating, tags) = getRatingAndTags(dir) {
                        addTags(tags)
                        directories.append(Directory(url: dir, rating: rating, tags: tags))
                    } else {
                        app.error("directory \(dir) has an invalid rating")
                    }
                }
            }
        }
        
        return directories
    }
    
    private func addTags(_ tags: Tags) {
        for tag in tags.tags {
            if !allTags.contains(tag) {
                allTags.add(tag)
            }
        }
    }
    
    private func randomDirectory(_ directories: [Directory]) -> Directory? {
        let maxWeight = directories.reduce(0) {$0 + $1.rating.rawValue}
        if maxWeight > 0 {
            var n = Int(arc4random_uniform(UInt32(maxWeight)))
            for candidate in directories {
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

    private func generateNewName(_ newDir: URL, _ originalFile: URL) -> URL {
        var i = 2
        let fs = FileManager.default
        var newFile = newDir.appendingPathComponent(originalFile.lastPathComponent)
        while fs.fileExists(atPath: newFile.path) { // note that this also returns true for directories
            newFile = newDir.appendingPathComponent("\(originalFile.lastPathComponent)-\(i)")
            i += 1
        }
        
        return newFile
    }
    
    private func getRatingAndTags(_ dir: URL) -> (Rating, Tags)? {
        let name = dir.lastPathComponent
        if name == "not-shown" {
            return (Rating.init(fromString: name)!, tags: Tags.init())
        } else {
            var tags = name.components(separatedBy: "-")
            if let rating = Rating.init(fromString: tags[0]) {
                tags.remove(at: 0)
                return (rating, Tags.init(from: tags))
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
        let tags: Tags
        
        var description: String {
            return url.description
        }
    }
    
    private let root: URL
    private var allTags = Tags.init()
}
