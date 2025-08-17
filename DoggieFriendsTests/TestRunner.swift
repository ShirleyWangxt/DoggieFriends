import XCTest
@testable import DoggieFriends

/*
 This test runner provides a simple way to run specific test categories
 and get a quick overview of what's working and what's not.
 */

@MainActor
final class TestRunner: XCTestCase {
    
    // MARK: - Quick Test Categories
    
    func testQuickGameLogic() async throws {
        // Run a quick test of core game functionality
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        
        // Test initial state
        XCTAssertEqual(viewModel.state, .idle)
        
        // Test loading breeds
        await viewModel.loadBreedsIfNeeded()
        
        // After loading breeds, it should be in loaded state
        guard case .loaded = viewModel.state else {
            XCTFail("Expected loaded state after loading breeds")
            return
        }
        
        // Test score persistence
        viewModel.resetScore()
        XCTAssertEqual(viewModel.score, 0)
    }
    
    func testQuickUIValidation() async throws {
        // Quick UI validation
        let mockService = MockDogAPIService()
        let viewModel = GameViewModel(apiService: mockService)
        let viewController = GameViewController(viewModel: viewModel)
        
        // Load view
        viewController.loadViewIfNeeded()
        
        // Check UI elements exist
        XCTAssertNotNil(viewController.activityIndicator)
        XCTAssertNotNil(viewController.retryButton)
        XCTAssertEqual(viewController.optionButtons.count, 4)
    }
}
