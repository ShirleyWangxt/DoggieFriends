import XCTest
@testable import DoggieFriends

/*
 Test Categories:
 1. Core Game Logic (GameViewModel)
 2. UI Behavior (GameViewController) 
 3. Data Model (Breed)
 
 Each test focuses on one specific behavior and has clear pass/fail criteria.
 */

// MARK: - Test Utilities

class MockDogAPIService: DogAPIServiceProtocol {
    var shouldFail = false
    var breeds: [Breed] = [
        Breed(parent: "bulldog", name: nil),
        Breed(parent: "bulldog", name: "french"),
        Breed(parent: "retriever", name: "golden"),
        Breed(parent: "shepherd", name: "german")
    ]
    
    func fetchAllBreeds() async throws -> [Breed] {
        if shouldFail {
            throw URLError(.badServerResponse)
        }
        return breeds
    }
    
    func fetchRandomImageURL(for breed: Breed) async throws -> URL {
        if shouldFail {
            throw URLError(.badServerResponse)
        }
        return URL(string: "https://example.com/dog.jpg")!
    }
}

// MARK: - Core Game Logic Tests

@MainActor
final class GameViewModelTests: XCTestCase {
    
    func testInitialState() throws {
        // Test: App starts in correct initial state
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    func testLoadBreedsSuccess() async throws {
        // Test: Successfully loading breeds
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        
        await viewModel.loadBreedsIfNeeded()
        
        // After loading breeds, it should load the first question
        guard case .loaded = viewModel.state else {
            XCTFail("Expected loaded state after loading breeds")
            return
        }
    }
    
    func testLoadBreedsFailure() async throws {
        // Test: Handling breed loading failure
        let mockService = MockDogAPIService()
        mockService.shouldFail = true
        let viewModel = GameViewModel(apiService: mockService)
        
        await viewModel.loadBreedsIfNeeded()
        
        guard case .error = viewModel.state else {
            XCTFail("Expected error state after failed breed loading")
            return
        }
    }
    
    func testAnswerSelection() async throws {
        // Test: Answer selection and scoring
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        
        await viewModel.loadBreedsIfNeeded()
        
        guard case let .loaded(question) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }
        
        let initialScore = viewModel.score
        let result = viewModel.selectAnswer(question.correctBreed)
        
        XCTAssertEqual(result, .correct)
        XCTAssertEqual(viewModel.score, initialScore + 1)
    }
    
    func testRetryLogic() async throws {
        // Test: Retry logic for wrong answers
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        
        await viewModel.loadBreedsIfNeeded()
        
        guard case let .loaded(question) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }
        
        // Get a wrong answer
        let wrongAnswer = question.options.first { $0 != question.correctBreed }!
        let result1 = viewModel.selectAnswer(wrongAnswer)
        
        XCTAssertEqual(result1, .incorrectRetryAllowed)
        
        // Try wrong answer again
        let result2 = viewModel.selectAnswer(wrongAnswer)
        
        guard case let .incorrectFinal(correctBreed) = result2 else {
            XCTFail("Expected incorrectFinal result")
            return
        }
        
        XCTAssertEqual(correctBreed, question.correctBreed)
    }
    
    func testScorePersistence() throws {
        // Test: Score persistence
        let mockService = MockDogAPIService()
        let userDefaults = UserDefaults(suiteName: "test")!
        let viewModel = GameViewModel(apiService: mockService, userDefaults: userDefaults)
        
        // Set initial score
        viewModel.resetScore()
        XCTAssertEqual(viewModel.score, 0)
        
        // Change score and verify persistence
        viewModel.resetScore()
        XCTAssertEqual(userDefaults.integer(forKey: "DoggieFriends.score"), 0)
        
        // Clean up
        userDefaults.removeSuite(named: "test")
    }
}

// MARK: - Data Model Tests

final class BreedModelTests: XCTestCase {
    
    func testBreedDisplayName() throws {
        // Test: Breed display name formatting
        let parentBreed = Breed(parent: "bulldog", name: nil)
        let subBreed = Breed(parent: "bulldog", name: "french")
        
        XCTAssertEqual(parentBreed.displayName, "Bulldog")
        XCTAssertEqual(subBreed.displayName, "Bulldog (French)")
    }
    
    func testBreedAPIPath() throws {
        // Test: Breed API path generation
        let parentBreed = Breed(parent: "bulldog", name: nil)
        let subBreed = Breed(parent: "bulldog", name: "french")
        
        XCTAssertEqual(parentBreed.apiPathComponent, "bulldog")
        XCTAssertEqual(subBreed.apiPathComponent, "bulldog/french")
    }
    
    func testBreedEquality() throws {
        // Test: Breed equality and hashing
        let breed1 = Breed(parent: "bulldog", name: nil)
        let breed2 = Breed(parent: "bulldog", name: nil)
        let breed3 = Breed(parent: "retriever", name: nil)
        
        XCTAssertEqual(breed1, breed2)
        XCTAssertNotEqual(breed1, breed3)
        
        let set: Set<Breed> = [breed1, breed2, breed3]
        XCTAssertEqual(set.count, 2) // breed1 and breed2 are equal
    }
}

// MARK: - UI Behavior Tests

@MainActor
final class GameViewControllerTests: XCTestCase {
    
    func testViewControllerInitialization() throws {
        // Test: View controller can be initialized
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        let viewController = GameViewController(viewModel: viewModel)
        
        XCTAssertNotNil(viewController)
    }
    
    func testUIElementsExist() throws {
        // Test: UI elements are properly configured
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        let viewController = GameViewController(viewModel: viewModel)
        
        // Load view to trigger viewDidLoad
        viewController.loadViewIfNeeded()
        
        XCTAssertNotNil(viewController.imageView)
        XCTAssertNotNil(viewController.stackView)
        XCTAssertNotNil(viewController.feedbackLabel)
        XCTAssertNotNil(viewController.scoreLabel)
        XCTAssertNotNil(viewController.activityIndicator)
        XCTAssertNotNil(viewController.retryButton)
        XCTAssertEqual(viewController.optionButtons.count, 4)
    }
}
