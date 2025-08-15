import UIKit

extension UIImageView {
    func setImage(from url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            if let image = UIImage(data: data) {
                await MainActor.run { self.image = image }
            }
        } catch {
            // Silently ignore; the view model will show error state if needed
        }
    }
}


