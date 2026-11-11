import Foundation

struct AppSelection: Codable, Equatable, Sendable {
    let encodedSelection: Data

    static let empty = AppSelection(encodedSelection: Data())
}
