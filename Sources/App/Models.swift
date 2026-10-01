import Foundation
import SwiftData

@Model final class Artwork {
  @Attribute(.unique) var id: UUID
  var title: String
  var collection: String
  var tags: String
  var favorite: Bool
  var createdAt: Date
  @Relationship(deleteRule: .cascade) var versions: [ArtworkVersion]
  init(title: String) {
    id = UUID()
    self.title = title
    collection = "Personal"
    tags = ""
    favorite = false
    createdAt = .now
    versions = []
  }
}
@Model final class ArtworkVersion {
  @Attribute(.unique) var id: UUID
  var assetID: UUID
  var createdAt: Date
  var prompt: String
  var origin: String
  var width: Int
  var height: Int
  var format: String
  var longestEdge: Int
  var headline: String
  init(asset: StoredAsset, prompt: String, origin: String) {
    id = UUID()
    assetID = asset.id
    createdAt = .now
    self.prompt = prompt
    self.origin = origin
    width = asset.width
    height = asset.height
    format = "original"
    longestEdge = 2048
    headline = ""
  }
  var recipe: ExportRecipe {
    ExportRecipe(
      format: CanvasFormat(rawValue: format) ?? .original, longestEdge: longestEdge,
      headline: headline)
  }
}
