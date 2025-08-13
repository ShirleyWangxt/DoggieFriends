import Foundation

/// Represents a breed or a sub-breed from the Dog API.
/// For sub-breeds, `parent` is the main breed and `name` is the sub-breed name.
struct Breed: Hashable, Codable {
    let parent: String
    let name: String?

    /// Display name for UI, e.g. "Bulldog (French)" or "Akita"
    var displayName: String {
        if let name = name, !name.isEmpty {
            let parentCapitalized = parent.capitalized
            let subCapitalized = name.capitalized
            return "\(parentCapitalized) (\(subCapitalized))"
        } else {
            return parent.capitalized
        }
    }

    /// API path piece for endpoints like /api/breed/{path}/images/random
    /// For sub-breeds, this becomes "{parent}/{sub}".
    var apiPathComponent: String {
        if let name = name, !name.isEmpty {
            return "\(parent)/\(name)"
        } else {
            return parent
        }
    }
}


