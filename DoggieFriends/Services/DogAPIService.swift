import Foundation

/// Abstraction for the Dog API networking.
protocol DogAPIServiceProtocol {
    func fetchAllBreeds() async throws -> [Breed]
    func fetchRandomImageURL(for breed: Breed) async throws -> URL
}

final class DogAPIService: DogAPIServiceProtocol {
    private let baseURL = URL(string: "https://dog.ceo/api")!
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func fetchAllBreeds() async throws -> [Breed] {
        // Endpoint: https://dog.ceo/api/breeds/list/all
        let url = baseURL.appendingPathComponent("breeds/list/all")
        let (data, response) = try await urlSession.data(from: url)
        try Self.validate(response: response)

        struct BreedsResponse: Decodable { let message: [String: [String]] }
        let decoded = try JSONDecoder().decode(BreedsResponse.self, from: data)
        var results: [Breed] = []
        for (parent, subs) in decoded.message {
            if subs.isEmpty {
                results.append(Breed(parent: parent, name: nil))
            } else {
                for sub in subs {
                    results.append(Breed(parent: parent, name: sub))
                }
            }
        }
        return results.sorted { $0.displayName < $1.displayName }
    }

    func fetchRandomImageURL(for breed: Breed) async throws -> URL {
        // Endpoint: https://dog.ceo/api/breed/{breed}/images/random
        let path = "breed/\(breed.apiPathComponent)/images/random"
        let url = baseURL.appendingPathComponent(path)
        let (data, response) = try await urlSession.data(from: url)
        try Self.validate(response: response)

        struct ImageResponse: Decodable { let message: String }
        let decoded = try JSONDecoder().decode(ImageResponse.self, from: data)
        guard let imageURL = URL(string: decoded.message) else {
            throw URLError(.badURL)
        }
        return imageURL
    }

    private static func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}


