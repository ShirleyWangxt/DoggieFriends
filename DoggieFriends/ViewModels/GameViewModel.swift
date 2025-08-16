import Foundation

@MainActor
final class GameViewModel {
    // Data model
    struct Question {
        let imageURL: URL
        let correctBreed: Breed
        let options: [Breed]
    }

    // UI state
    enum State {
        case idle
        case loading
        case loaded(Question)
        case error(String)
    }

    private let apiService: DogAPIServiceProtocol
    // Cache: Loaded once, reused across questions to avoid repeated API calls.
    private var allBreeds: [Breed] = []

    // Publicly observable state. Readable from outside; only the view model can mutate. 
    private(set) var state: State = .idle
    private(set) var score: Int {
        didSet { persistScore() }
    }

    // Persistence
    private let userDefaults: UserDefaults
    private let scoreKey = "DoggieFriends.score"

    init(apiService: DogAPIServiceProtocol, userDefaults: UserDefaults = .standard) {
        self.apiService = apiService
        self.userDefaults = userDefaults
        self.score = userDefaults.integer(forKey: scoreKey)
    }

    func loadBreedsIfNeeded() async {
        if !allBreeds.isEmpty { return }
        state = .loading
        do {
            let breeds = try await apiService.fetchAllBreeds()
            self.allBreeds = breeds
            await loadNextQuestion()
        } catch {
            state = .error("Failed to load breeds. Please try again.")
        }
    }

    func loadNextQuestion() async {
        guard !allBreeds.isEmpty else { 
            state = .error("Failed to load breeds. Please try again.")
            return 
        }
        state = .loading

        // Select correct breed
        guard let correct = allBreeds.randomElement() else {
            state = .error("No breeds available.")
            return
        }

        // Generate up to 3 distinct incorrect options
        let candidates = allBreeds.filter { $0 != correct }
        let incorrect = Array(candidates.shuffled().prefix(3))
        var options = incorrect
        options.append(correct)
        options.shuffle()

        do {
            let imageURL = try await apiService.fetchRandomImageURL(for: correct)
            let question = Question(imageURL: imageURL, correctBreed: correct, options: options)
            state = .loaded(question)
        } catch {
            state = .error("Failed to load image. Please try again.")
        }
    }

    func selectAnswer(_ breed: Breed) -> Bool {
        guard case let .loaded(question) = state else { return false }
        let isCorrect = breed == question.correctBreed
        if isCorrect {
            score += 1
        }
        return isCorrect
    }

    func resetScore() {
        score = 0
    }

    private func persistScore() {
        userDefaults.set(score, forKey: scoreKey)
    }
}


