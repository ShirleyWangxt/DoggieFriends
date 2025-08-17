# DoggieFriends

DoggieFriends is a small UIKit iOS app that helps users learn dog breeds. It shows a dog image from the Dog API and four multiple-choice options. Users get immediate feedback, an auto-advance to the next question, and a running score persisted via UserDefaults.

## Build & Run

1. Open `DoggieFriends.xcworkspace` in Xcode 15+.
2. Select an iPhone simulator (iOS 16+ recommended).
3. Run.

No additional setup is required. The app uses URLSession (async/await) and has no external networking dependencies.

## Architecture

- MVVM with a small service layer.
- `DogAPIService` handles networking using Swift Concurrency and `URLSession`.
- `GameViewModel` holds game state, generates options, requests data from the service via DI, and exposes a simple state enum to the view.
- `GameViewController` is a UIKit view controller that binds to the view model, renders UI, and handles user interactions.
- Folders: `Models`, `Services`, `ViewModels`, `Views`, `Utilities`.

## Design & UI

- Programmatic Auto Layout (no storyboards).
- Adaptive layout for all iPhones, supports Dark Mode via system colors.
- Animated feedback label for correct/incorrect answers.
- Friendly, light palette using system colors; SF Symbols for the retry icon.

## Error Handling

- When a request fails, the UI shows a Retry button overlay on the image.
- Loading state shows a large activity indicator and disables buttons.
