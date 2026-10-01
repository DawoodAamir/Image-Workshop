import CoreGraphics
import Foundation

public enum CanvasFormat: String, CaseIterable, Codable, Sendable {
  case original, square, portrait, landscape
  public var label: String { rawValue.capitalized }
  public var ratio: Double? {
    switch self {
    case .original: nil
    case .square: 1
    case .portrait: 0.75
    case .landscape: 16.0 / 9.0
    }
  }
  public var requestedSize: CGSize {
    switch self {
    case .original, .square: CGSize(width: 1024, height: 1024)
    case .portrait: CGSize(width: 768, height: 1024)
    case .landscape: CGSize(width: 1536, height: 864)
    }
  }
}

public struct ExportRecipe: Codable, Equatable, Sendable {
  public var format: CanvasFormat
  public var longestEdge: Int
  public var headline: String
  public init(format: CanvasFormat = .original, longestEdge: Int = 2048, headline: String = "") {
    self.format = format
    self.longestEdge = longestEdge
    self.headline = headline
  }
  public func validated() throws -> Self {
    guard (256...4096).contains(longestEdge), headline.count <= 160 else {
      throw ImageFailure.invalidRecipe
    }
    return self
  }
  public func crop(for size: CGSize) -> CGRect {
    guard let ratio = format.ratio, size.width > 0, size.height > 0 else {
      return CGRect(origin: .zero, size: size)
    }
    if size.width / size.height > ratio {
      let width = size.height * ratio
      return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
    }
    let height = size.width / ratio
    return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
  }
  public func outputSize(for size: CGSize) -> CGSize {
    let crop = crop(for: size).size
    let factor = Double(longestEdge) / max(crop.width, crop.height)
    return CGSize(
      width: max(1, (crop.width * factor).rounded()),
      height: max(1, (crop.height * factor).rounded()))
  }
}

public enum ImageFailure: LocalizedError {
  case invalidImage, oversized, invalidRecipe, missingAsset
  public var errorDescription: String? {
    switch self {
    case .invalidImage: "Choose a readable PNG, JPEG, or HEIF image."
    case .oversized: "Use an image under 25 MB and 50 megapixels."
    case .invalidRecipe:
      "Choose an export size from 256 to 4096 pixels and a caption under 160 characters."
    case .missingAsset: "The saved image is missing. Import another version to continue."
    }
  }
}
