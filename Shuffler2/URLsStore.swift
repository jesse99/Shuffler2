//  Created by Jesse Vorisek on 5/19/22.
//  Copyright © 2022 MushinApps. All rights reserved.
import Foundation
import Cocoa

extension Tags {
    func makeName2(_ weight: Weight) -> String {
        var dirName = ""
        switch weight {
        case .weight(let weight):
            dirName = "\(weight)"
        case .notShown:
            // Note that we can land here if the pic is in not-shown and the user adds a tag.
            dirName = "1"
        }
        
        let tags = self.tags.sorted()
        if !tags.isEmpty {
            dirName += "-" + tags.joined(separator: "-")
        }
        return dirName
    }
}

//// Concrete store class based on a file system URL.
class UrlSystemKey: Key {
    fileprivate init(_ url: URL) {
        self.url = url
    }

    // We need to do this so that the UI reflects changes the user makes. Note that
    // URL is a struct so this won't change the entry in directories (which is good
    // because that'll force a reload at some point and we'll then use the proper
    // weight and tags).
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
            data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Void in
//                let buffer = UnsafeRawPointer(ptr)
                let result = setxattr(url.path, name, ptr.baseAddress, data.count, 0, 0)
                if result < 0 {
                    print("failed to set \(name) to \(value)")
                }
            }

//            data.withUnsafeBytes {(ptr: UnsafePointer<UInt8>) -> Void in
//                let buffer = UnsafeRawPointer(ptr)
//                let result = setxattr(url.path, name, buffer, data.count, 0, 0)
//                if result < 0 {
//                    print("failed to set \(name) to \(value)")
//                }
//            }
        }
    }

    public var description: String {get {return url.path}}

    fileprivate var url: URL
}

// Concrete store class based on a file system URL.
class UrlsKey: Key {
    fileprivate init(_ url: URL) {
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
            data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Void in
//                let buffer = UnsafeRawPointer(ptr)
                let result = setxattr(url.path, name, ptr.baseAddress, data.count, 0, 0)
                if result < 0 {
                    print("failed to set \(name) to \(value)")
                }
            }
            
//            data.withUnsafeBytes {(ptr: UnsafePointer<UInt8>) -> Void in
//                let buffer = UnsafeRawPointer(ptr)
//                let result = setxattr(url.path, name, buffer, data.count, 0, 0)
//                if result < 0 {
//                    print("failed to set \(name) to \(value)")
//                }
//            }
        }
    }
    
    public var description: String {get {return url.path}}
    
    fileprivate var url: URL
}

// Concrete store class fetching images from a local directory.
class UrlsStore: Store {
    init(_ root: String) {
        self.root = URL.init(fileURLWithPath: root)
    }
    
    func postInit() {
        let upcoming = self.root.appendingPathComponent("upcoming")
        cleanup(dir: upcoming)  // TODO: do we want to do this?
        self.reloadDirectories()
    }
    
    func randomImage(_ min_weight: Int) -> Key? {
        let maxTries = 20
        for _ in 0..<maxTries {
            if let file = self.findImage(min_weight) {
                return file
            }
        }
        let app = NSApp.delegate as! AppDelegate
        app.error("Failed to find a random image in \(maxTries) tries")
        self.recentFiles.removeAll()
        return nil
    }
    
    func loadImage(_ key: Key) -> Data? {
        let fsKey = key as! UrlSystemKey
        return try? Data.init(contentsOf: fsKey.url)
    }
    
    func openImage(_ key: Key) {
        let fsKey = key as! UrlSystemKey
        if !NSWorkspace.shared.openFile(fsKey.url.path) {
            NSSound.beep()
        }
    }
    
    func showImage(_ key: Key) {
        let fsKey = key as! UrlSystemKey
        if !NSWorkspace.shared.selectFile(fsKey.url.path, inFileViewerRootedAtPath: "") {
            NSSound.beep()
        }
    }

    func trashImage(_ key: Key) {
        let fsKey = key as! UrlSystemKey
        do {
            try FileManager.default.trashItem(at: fsKey.url, resultingItemURL: nil)
        } catch {
            NSSound.beep()
        }
    }
    
    func getName(_ key: Key) -> String {
        let fsKey = key as! UrlSystemKey
        return fsKey.url.deletingPathExtension().lastPathComponent
    }
    
    func getWeight(_ key: Key) -> Weight {
        let fsKey = key as! UrlSystemKey
        if let (weight, _) = getWeightAndTags(fsKey.url) {
            return weight
        }
        return .weight(1)
    }
    
    func setWeight(_ key: Key, _ weight: Int) {
        let fsKey = key as! UrlSystemKey

        var dirName = "\(weight)"
        if let (_, tags) = getWeightAndTags(fsKey.url) {
            dirName = tags.makeName2(.weight(weight))
            if let newUrl = self.moveFileTo(dirName, fsKey.url) {
                fsKey.updateUrl(newUrl)
            }
        }
    }
    
    func getScaling(_ key: Key) -> Int {
        let fsKey = key as! UrlSystemKey
        return fsKey.getInt("scaling") ?? 0
    }
    
    func setScaling(_ key: Key, _ scaling: Int) {
        let fsKey = key as! UrlSystemKey
        fsKey.setInt("scaling", scaling)
    }
    
    func getAlignment(_ key: Key) -> NSImageAlignment {
        let fsKey = key as! UrlSystemKey
        let value = fsKey.getInt("alignment") ?? 0
        return NSImageAlignment.init(rawValue: UInt(value)) ?? .alignCenter
    }
    
    func setAlignment(_ key: Key, _ align: NSImageAlignment) {
        let fsKey = key as! UrlSystemKey
        fsKey.setInt("alignment", Int(align.rawValue))
    }
    
    func getTags(_ key: Key) -> Tags {
        let fsKey = key as! UrlSystemKey

        if let (_, tags) = getWeightAndTags(fsKey.url) {
            return tags
        }
        return Tags.init()
    }
    
    func addTag(_ key: Key, _ inTag: String) {
        let fsKey = key as! UrlSystemKey

        if let (weight, tags) = getWeightAndTags(fsKey.url) {
            let tag = inTag.trimmingCharacters(in: .whitespaces)
            if tag != "" && !tags.contains(tag) {
                tags.add(tag)
                allTags.add(tag)

                let dirName = tags.makeName2(weight)
                if let newUrl = moveFileTo(dirName, fsKey.url) {
                    fsKey.updateUrl(newUrl)
                }
            }
        }
    }
    
    func removeTag(_ key: Key, _ inTag: String) {
        let fsKey = key as! UrlSystemKey

        if let (weight, tags) = getWeightAndTags(fsKey.url) {
            let tag = inTag.trimmingCharacters(in: .whitespaces)
            if tags.remove(tag) {
                let dirName = tags.makeName2(weight)
                if let newUrl = moveFileTo(dirName, fsKey.url) {
                    fsKey.updateUrl(newUrl)
                }
            }
        }
    }
    
    func availableTags() -> Tags {
        return allTags
    }
    
    public var showTags = Tags.init()
    
    public var includeNotShown: Bool = true
    
    private func moveFileTo(_ dirName: String, _ originalFile: URL) -> URL? {
        let fs = FileManager.default
        let newDir = root.appendingPathComponent(dirName)
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
//            print("moved file from \(originalFile) to \(newFile)")
        } catch let error as NSError {
            let app = NSApp.delegate as! AppDelegate
            app.error("Couldn't move \(originalFile) to \(newFile): \(error.localizedDescription)")
            return nil
        }
        
        return newFile
    }
    
    private func addTags(_ tags: Tags) {
        for tag in tags.tags {
            if !allTags.contains(tag) {
                allTags.add(tag)
            }
        }
    }
    
    private func findImage(_ min_weight: Int) -> Key? {
        var candidate: URL? = nil
        if includeNotShown && arc4random_uniform(3) == 0 {
            candidate = self.findNotShownFile()
        }

        if candidate == nil {
            candidate = self.findWeightedFile(min_weight);
        }

        if candidate == nil && includeNotShown {
            candidate = self.findNotShownFile()
        }

        if let file = candidate {
            if self.fileExists(file) {
                if self.canShow(file) {
                    if !self.isRecent(file) {
                        self.addRecent(file)
                        return UrlSystemKey.init(file)
                    }
                } else {
                    let app = NSApp.delegate as! AppDelegate
                    app.error("Can't show \(file)")
                }
            } else {
                // We're trying to use a file which no longer exists. It's likely that the
                // user has either deleted it or it has moved (e.g. because tags changed).
                // So we'll reload all the files (the user can change the file system themselves
                // so we need to handle this case here regardless, and handling it only here
                // will minimize the number of reloads).
                //
                // Note that additions are handled by watching the not-shown directory (if the
                // user directly adds to another directory then we'll eventually pick that up).
                // TODO: do that
                print("reloading because file no longer exists")
                self.reloadDirectories()
            }
        }
        return nil
    }
    
    private func findNotShownFile() -> URL? {
        for dir in self.directories {
            if case .notShown = dir.weight, dir.files.count > 0 {
                let index = Int(arc4random_uniform(UInt32(dir.files.count)))
                return dir.files[index]
            }
        }
        return nil
    }
    
    private func findWeightedFile(_ minWeight: Int) -> URL? {
        let totalFiles = self.getWeightedTotal(minWeight)
        if totalFiles > 0 {
            var index = Int(arc4random_uniform(UInt32(totalFiles)))
            for dir in self.directories {
                if case .weight(let weight) = dir.weight, weight >= minWeight {
                    if self.tagsMatch(dir) && index < weight*dir.files.count {
                        return dir.files[index / weight]
                    } else {
                        index -= weight*dir.files.count
                        assert(index >= 0)
                    }
                }
            }
            assert(false)
        } else {
            let app = NSApp.delegate as! AppDelegate
            app.warn("no files with minWeight \(minWeight) and tags \(self.showTags)")
            return nil
        }
    }
    
    private func getWeightedTotal(_ minWeight: Int) -> Int {
        var count = 0
        
        for dir in self.directories {
            if case .weight(let weight) = dir.weight, weight >= minWeight {
                if self.tagsMatch(dir) {
                    count += weight*dir.files.count
                }
            }
        }
        return count
    }
    
    private func addRecent(_ file: URL) {
        self.recentFiles.append(file)
        while self.recentFiles.count > self.maxRecents {
            self.recentFiles.remove(at: 0)
        }
    }
    
    private func isRecent(_ file: URL) -> Bool {
        return self.recentFiles.firstIndex(of: file) != nil
    }

    private func tagsMatch(_ dir: Directory) -> Bool {
        switch dir.weight {
        case .weight(_):
            for required in self.showTags.tags {
                if !dir.tags.contains(required) {
                    return false
                }
            }
            return true
        case .notShown:
            return self.includeNotShown
        }
    }

    private let regex = try! NSRegularExpression(pattern: "-\\d+$", options: [])

    private func generateNewName(_ newDir: URL, _ originalFile: URL) -> URL {
        var i = 2
        let fs = FileManager.default

        var newFile = newDir.appendingPathComponent(originalFile.lastPathComponent)

        let newExt = NSMutableString.init(string: newFile.pathExtension)
        _ = regex.replaceMatches(in: newExt, options: [], range: NSRange(location: 0, length: newFile.pathExtension.utf16.count), withTemplate: "")
        
        let baseName = newFile.deletingPathExtension().lastPathComponent
        let baseURL = newFile.deletingLastPathComponent()

        while fs.fileExists(atPath: newFile.path) { // note that this also returns true for directories
            newFile = baseURL.appendingPathComponent("\(baseName)-\(i)")
            newFile = newFile.appendingPathExtension(String(newExt))
            i += 1
        }
        
        return newFile
    }
    
    private func fileExists(_ file: URL) -> Bool {
        let fs = FileManager.default
        return fs.fileExists(atPath: file.path)
    }

    private func canShow(_ file: URL) -> Bool {
        if !file.hasDirectoryPath {
            let ext = file.pathExtension as CFString
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil) {
//                print("\(NSBitmapImageRep.imageTypes)")
                let fileType = uti.takeRetainedValue()
                for case let type in NSBitmapImageRep.imageTypes {
                    if UTTypeConformsTo(fileType, type as CFString) {
                        return true
                    }
                }
            }
        }
        return false
    }

    // The UI forces users to gradually build up tags and ratings for each image. This means that it's fairly
    // common for directories like "good" to be created which will hardly ever be populated. This is kind of
    // annoying so we'll blow them away here.
    private func cleanup(dir: URL) {
        let fs = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        if let enumerator = fs.enumerator(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: options, errorHandler: nil) {
            for case let dir as URL in enumerator {
                if dir.hasDirectoryPath {
                    if isEmptyDir(dir) {
                        let app = NSApp.delegate as! AppDelegate
                        do {
                            try FileManager.default.trashItem(at: dir, resultingItemURL: nil)
                            app.info("trashed empty \(dir)")
                        } catch let error as NSError {
                            app.error("couldn't trash \(dir): \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    // There doesn't appear to be a good way to get the number of directory items in Cocoa. AFAICT this is the most
    // efficient way to do this w/o dropping down to low level calls.
    private func isEmptyDir(_ url: URL) -> Bool {
        let fs = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        if fs.enumerator(at: url, includingPropertiesForKeys: [], options: options, errorHandler: nil) != nil {
            return false
        }
        return true
    }
    
    // TODO: time how long this takes
    private func reloadDirectories() {
        self.directories.removeAll()

        let fs = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles, .skipsSubdirectoryDescendants]
        var count = 0
        if let enumerator = fs.enumerator(at: self.root, includingPropertiesForKeys: [], options: options, errorHandler: nil) {
            for case let dir as URL in enumerator {
                if dir.hasDirectoryPath {
                    if let (weight, tags) = getWeightAndTags(dir) {
//                        print("found dir \(dir) with \(weight) and \(tags)")
                        self.addTags(tags)
                        let files: [URL] = self.loadFiles(dir)
                        self.directories.append(Directory(url: dir, weight: weight, tags: tags, files: files))
                        count += files.count
                    } else {
                        let app = NSApp.delegate as! AppDelegate
                        app.warn("\(dir) isn't formatted correctly")
                    }
                }
            }
        }
        
        if count < 2*4*60 {
            self.maxRecents = count/2
        } else {
            self.maxRecents = 4*60  // 4 hours worth at the default 1 min display interval
        }
    }
    
    private func loadFiles(_ dir: URL) -> [URL] {
        var files: [URL] = []
        files.reserveCapacity(512)

        let fs = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]
        if let enumerator = fs.enumerator(at: dir, includingPropertiesForKeys: [], options: options, errorHandler: nil) {
            for case let file as URL in enumerator {
                if !file.hasDirectoryPath {
                    files.append(file)
                }
            }
        }
        
        return files
    }
    
    // This will return nil if the file no longer exists. Most often this will be because
    // the user changed the weight or tags and Shuffler moved the file.
    private func getWeightAndTags(_ item: URL) -> (Weight, Tags)? {
        var dir = item
        while dir != self.root.appendingPathComponent(dir.lastPathComponent) {
            dir = dir.deletingLastPathComponent()
        }
        
        let name = dir.lastPathComponent
        if name == "not-shown" {
            return (.notShown, tags: Tags.init())
        } else {
            var tags = name.components(separatedBy: "-")
            if let weight = Int.init(tags[0]) {
                tags.remove(at: 0)
                return (.weight(weight), Tags.init(from: tags))
            }
        }
        return nil
    }
    
    private struct Directory: CustomStringConvertible {
        let url: URL
        let weight: Weight
        let tags: Tags
        let files: [URL]
        
        var description: String {
            return url.description
        }
    }
    
    private let root: URL
    private var allTags = Tags.init()
    private var directories: [Directory] = []
    
    private var maxRecents = 0
    private var recentFiles: [URL] = []
}
