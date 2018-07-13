//  Created by Jesse Jones on 7/2/18.
//  Copyright © 2018 MushinApps. All rights reserved.
import Foundation

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

/// Used by stores to identify an image.
protocol Key: CustomStringConvertible {
}

/// Interface used to access images.
protocol Store {
    func randomImage(_ rating: Rating) -> Key?
    
    func loadImage(_ key: Key) -> Data?

    func openImage(_ key: Key)
    func showImage(_ key: Key)
    func trashImage(_ key: Key)
}
