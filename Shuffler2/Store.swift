//  Created by Jesse Jones on 7/2/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Foundation
import Cocoa

public class Tags: CustomStringConvertible {
    init() {
        self.tags = []
    }

    init(from: [String]) {
        self.tags = from
    }
    
    public func removeAll() {
        tags.removeAll()
    }
    
    public func contains(_ tag: String) -> Bool {
        return tags.contains(tag.lowercased())
    }
    
    public func add(_ tag: String) {
        if !contains(tag) {
            tags.append(tag.lowercased())
        }
    }
    
    public func remove(_ tag: String) -> Bool {
        if let index = tags.firstIndex(of: tag.lowercased()) {
            tags.remove(at: index)
            return true
        }
        return false
    }
    
    // Returns the tags as lower case strings in no particular order.
    public private(set) var tags: [String]

    // Sorted user friendly names.
    public func titles() -> [String] {
        let titles = tags.map {$0.capitalized}
        return titles.sorted()
    }
    
    public var description: String {
        get {return tags.joined(separator: ", ")}
    }
}

/// Used by stores to identify an image.
protocol Key: CustomStringConvertible {
}

public enum Weight {
    case weight(Int)
    case notShown
}

/// Interface used to access images.
protocol Store {
    func postInit()
    
    func randomImage(_ min_weight: Int) -> Key?
    func loadImage(_ key: Key) -> Data?

    func openImage(_ key: Key)
    func showImage(_ key: Key)
    func trashImage(_ key: Key)

    func getName(_ key: Key) -> String

    func getWeight(_ key: Key, _ minWeight: Int) -> (Weight, String)
    func setWeight(_ key: Key, _ weight: Int)

    func getTags(_ key: Key) -> Tags
    func addTag(_ key: Key, _ tag: String)
    func removeTag(_ key: Key, _ tag: String)

    // 0 => no scaling
    // -1 => max scaling
    // else scale by value/100.0
    func getScaling(_ key: Key) -> Int
    func setScaling(_ key: Key, _ scaling: Int)
    
    func getAlignment(_ key: Key) -> NSImageAlignment
    func setAlignment(_ key: Key, _ align: NSImageAlignment)
    
    // Unsorted list of tags.
    func availableTags() -> Tags
    
    // If any tags are set then only images that match all of those tags are used.
    var showTags: Tags {get set}

    var includeNotShown: Bool {get set}
}
