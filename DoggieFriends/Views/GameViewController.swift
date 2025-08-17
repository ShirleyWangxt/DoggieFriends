import UIKit

@MainActor
final class GameViewController: UIViewController {
    private let viewModel: GameViewModel

    // UI
    let imageView = UIImageView()
    let stackView = UIStackView()
    var optionButtons: [UIButton] = []
    let feedbackLabel = UILabel()
    let scoreLabel = UILabel()
    let activityIndicator = UIActivityIndicatorView(style: .large)
    let retryButton = UIButton(type: .system)

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        configureUI()
        Task { await viewModel.loadBreedsIfNeeded(); await refreshUI() }
    }

    private func configureUI() {
        // Image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12

        // Stack for options
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually

        for idx in 0..<4 {
            let button = UIButton(type: .system)
            button.tag = idx
            button.setTitle("Option", for: .normal)
            button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            button.backgroundColor = UIColor.secondarySystemBackground
            button.layer.cornerRadius = 10
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.separator.cgColor
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            optionButtons.append(button)
            stackView.addArrangedSubview(button)
        }

        feedbackLabel.alpha = 0
        feedbackLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        feedbackLabel.textAlignment = .center

        scoreLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = .secondaryLabel

        retryButton.setTitle("Retry", for: .normal)
        retryButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        retryButton.tintColor = view.tintColor
        retryButton.backgroundColor = UIColor.white
        retryButton.layer.cornerRadius = 12
        retryButton.layer.shadowColor = UIColor.black.cgColor
        retryButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        retryButton.layer.shadowRadius = 4
        retryButton.layer.shadowOpacity = 0.3
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.isHidden = true

        activityIndicator.hidesWhenStopped = true

        [imageView, stackView, feedbackLabel, scoreLabel, activityIndicator, retryButton].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.75),

            stackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            feedbackLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
            feedbackLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            feedbackLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            scoreLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            retryButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }

    @objc private func optionTapped(_ sender: UIButton) {
        guard case let .loaded(question) = viewModel.state else { return }
        let index = sender.tag
        guard index < question.options.count else { return }
        let selected = question.options[index]
        let answerResult = viewModel.selectAnswer(selected)

        switch answerResult {
        case .correct:
            // Correct answer - show success feedback
            showFeedback("Correct!", color: .systemGreen)
            updateScore()
            
            // Disable all buttons and proceed to next question after delay
            optionButtons.forEach { $0.isEnabled = false }
            Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                await self.viewModel.loadNextQuestion()
                await self.refreshUI()
            }
            
        case .incorrectRetryAllowed:
            // First wrong attempt - show feedback and allow retry
            showFeedback("Try again!", color: .systemOrange)
            updateScore()
            
        case .incorrectFinal(let correctBreed):
            // Second wrong attempt - show correct answer and proceed
            // Highlight the correct answer
            highlightCorrectAnswer(correctBreed, in: question.options)
            
            // Disable all buttons and proceed to next question after delay
            optionButtons.forEach { $0.isEnabled = false }
            Task {
                try? await Task.sleep(nanoseconds: 2000_000_000) // 2 seconds to show correct answer
                await self.viewModel.loadNextQuestion()
                await self.refreshUI()
            }
            
        case .invalid:
            // Invalid state - do nothing
            break
        }
    }
    
    private func showFeedback(_ message: String, color: UIColor) {
        feedbackLabel.text = message
        feedbackLabel.textColor = color
        feedbackLabel.numberOfLines = 0
        feedbackLabel.lineBreakMode = .byWordWrapping
        feedbackLabel.textAlignment = .center
        feedbackLabel.alpha = 1
    }
    
    private func highlightCorrectAnswer(_ correctBreed: Breed, in options: [Breed]) {
        // Find and highlight the correct answer button
        for (index, option) in options.enumerated() {
            if option == correctBreed {
                let button = optionButtons[index]
                button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
                button.setTitle("\(option.displayName) ✓", for: .normal)
                button.setTitleColor(.systemGreen, for: .normal)
                break
            }
        }
        
        // Show a friendly message about the correct answer
        let message = "Awwww it is: \(correctBreed.displayName)"
        feedbackLabel.text = message
        feedbackLabel.textColor = .systemGreen
        feedbackLabel.numberOfLines = 0
        feedbackLabel.lineBreakMode = .byWordWrapping
        feedbackLabel.textAlignment = .center
        feedbackLabel.alpha = 1
        
        // This message will stay visible until the next question loads
    }

    @objc private func retryTapped() {
        Task {
            await viewModel.loadBreedsIfNeeded()
            await viewModel.loadNextQuestion()
            await refreshUI()
        }
    }

    private func refreshUI() async {
        switch viewModel.state {
        case .idle:
            activityIndicator.stopAnimating()
            retryButton.isHidden = true
        case .loading:
            activityIndicator.startAnimating()
            retryButton.isHidden = true
            imageView.image = nil
            optionButtons.forEach { $0.setTitle("…", for: .normal); $0.isEnabled = false }
            // Clear feedback label when loading new question
            feedbackLabel.text = ""
            feedbackLabel.alpha = 0
        case .error:
            activityIndicator.stopAnimating()
            retryButton.isHidden = false
            optionButtons.forEach { $0.isEnabled = false }
        case .loaded(let question):
            activityIndicator.stopAnimating()
            retryButton.isHidden = true
            await imageView.setImage(from: question.imageURL)
            // Clear feedback label for new question
            feedbackLabel.text = ""
            feedbackLabel.alpha = 0
            for (idx, option) in question.options.enumerated() {
                if idx < optionButtons.count {
                    optionButtons[idx].setTitle(question.options[idx].displayName, for: .normal)
                    optionButtons[idx].isEnabled = true
                    // Reset button appearance for new question
                    optionButtons[idx].backgroundColor = UIColor.secondarySystemBackground
                    optionButtons[idx].setTitleColor(.label, for: .normal)
                }
            }
        }

        updateScore()
    }

    private func updateScore() {
        scoreLabel.text = "Score: \(viewModel.score)"
    }
}


