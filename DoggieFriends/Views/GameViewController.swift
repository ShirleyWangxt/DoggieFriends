import UIKit

@MainActor
final class GameViewController: UIViewController {
    private let viewModel: GameViewModel

    // UI
    private let imageView = UIImageView()
    private let stackView = UIStackView()
    private var optionButtons: [UIButton] = []
    private let feedbackLabel = UILabel()
    private let scoreLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let retryButton = UIButton(type: .system)

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
        feedbackLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        feedbackLabel.textAlignment = .center

        scoreLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = .secondaryLabel

        retryButton.setTitle("Retry", for: .normal)
        retryButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        retryButton.tintColor = view.tintColor
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
        let isCorrect = viewModel.selectAnswer(selected)

        // Feedback UI
        let text = isCorrect ? "Correct!" : "Try again!"
        feedbackLabel.text = text
        feedbackLabel.textColor = isCorrect ? .systemGreen : .systemRed
        UIView.animate(withDuration: 0.2, animations: {
            self.feedbackLabel.alpha = 1
            self.feedbackLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.feedbackLabel.alpha = 0
                self.feedbackLabel.transform = .identity
            }
        })

        updateScore()

        // When correct, disable taps and load next after delay
        if isCorrect {
            optionButtons.forEach { $0.isEnabled = false }
            Task {
                // try? await Task.sleep(nanoseconds: 900_000_000)
                await self.viewModel.loadNextQuestion()
                await self.refreshUI()
            }
        }
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
        case .error:
            activityIndicator.stopAnimating()
            retryButton.isHidden = false
            optionButtons.forEach { $0.isEnabled = false }
        case .loaded(let question):
            activityIndicator.stopAnimating()
            retryButton.isHidden = true
            await imageView.setImage(from: question.imageURL)
            for (idx, option) in question.options.enumerated() {
                if idx < optionButtons.count {
                    optionButtons[idx].setTitle(option.displayName, for: .normal)
                    optionButtons[idx].isEnabled = true
                }
            }
        }

        updateScore()
    }

    private func updateScore() {
        scoreLabel.text = "Score: \(viewModel.score)"
    }
}


