import Foundation
import UIKit
import Vision

struct RecognizedLine: Hashable {
    let text: String
    /// Height of the text box, as a fraction of the image height. Bigger text = bigger number.
    let height: CGFloat
    /// Vertical position (Vision uses 0 at the bottom, 1 at the top).
    let minY: CGFloat
}

enum OfferCheckError: LocalizedError {
    case unreadableImage

    var errorDescription: String? {
        switch self {
        case .unreadableImage: return "Couldn't read that image."
        }
    }
}

enum TextRecognizer {
    static func recognize(imageData: Data) throws -> [RecognizedLine] {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw OfferCheckError.unreadableImage
        }
        return try recognize(cgImage)
    }

    static func recognize(_ image: CGImage) throws -> [RecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        return observations
            .compactMap { observation -> RecognizedLine? in
                guard let best = observation.topCandidates(1).first else { return nil }
                return RecognizedLine(
                    text: best.string,
                    height: observation.boundingBox.height,
                    minY: observation.boundingBox.minY
                )
            }
            .sorted { $0.minY > $1.minY } // top of screen first
    }
}
