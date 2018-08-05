//  Created by Jesse Jones on 7/2/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Foundation
import Cocoa

/// Values are used to weight pictures so that they are shown more often.
public enum Rating: Int, Comparable, CustomStringConvertible {
    case normal = 1
    case good = 4
    case great = 16
    case fantastic = 64
    case notShown = 65

    init?(fromString: String) {
        switch fromString.lowercased() {
        case "normal":
            self = .normal
        case "good":
            self = .good
        case "great":
            self = .great
        case "fantastic":
            self = .fantastic
        case "not-shown":
            self = .notShown
        default:
            return nil
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .normal: return "normal"
            case .good: return "good"
            case .great: return "great"
            case .fantastic: return "fantastic"
            case .notShown: return "not-shown"
            }
        }
    }

    public static func <(lhs: Rating, rhs: Rating) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

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
        if let index = tags.index(of: tag.lowercased()) {
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

/// Interface used to access images.
protocol Store {
    func postInit()
    
    func randomImage(_ rating: Rating) -> Key?
    func loadImage(_ key: Key) -> Data?

    func openImage(_ key: Key)
    func showImage(_ key: Key)
    func trashImage(_ key: Key)

    func getName(_ key: Key) -> String

    func getRating(_ key: Key) -> Rating?
    func setRating(_ key: Key, _ rating: Rating)

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
