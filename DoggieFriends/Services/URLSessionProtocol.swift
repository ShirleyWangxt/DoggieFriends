import Foundation

// Protocol for URLSession to enable testing
protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

// Make URLSession conform to our protocol
extension URLSession: URLSessionProtocol {}
