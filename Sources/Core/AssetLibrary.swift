import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import CoreText

public struct StoredAsset: Sendable {
  public let id: UUID
  public let width: Int
  public let height: Int
}

/// Owns immutable original files. Callers store only IDs, never arbitrary relative paths.
public actor AssetLibrary {
  private let folder: URL
  public init(folder: URL) { self.folder = folder }
  private func url(_ id: UUID, thumbnail: Bool = false) -> URL {
    folder.appendingPathComponent(id.uuidString + (thumbnail ? ".preview.png" : ".source"))
  }
  private func decode(_ data: Data, edge: Int) throws -> CGImage {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [String: Any],
      let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
      let height = properties[kCGImagePropertyPixelHeight as String] as? Int,
      width > 0, height > 0, Double(width)*Double(height) <= 50_000_000,
      let image = CGImageSourceCreateThumbnailAtIndex(source,0,[
        kCGImageSourceCreateThumbnailFromImageAlways:true,
        kCGImageSourceCreateThumbnailWithTransform:true,
        kCGImageSourceThumbnailMaxPixelSize:edge,
        kCGImageSourceShouldCacheImmediately:true] as CFDictionary)
    else { throw ImageFailure.invalidImage }
    return image
  }
  public func store(_ data: Data) throws -> StoredAsset {
    guard data.count <= 25_000_000 else { throw ImageFailure.oversized }
    let image = try decode(data,edge: 8192)
    let preview = try decode(data,edge: 1600)
    let id = UUID()
    try FileManager.default.createDirectory(at: folder,withIntermediateDirectories: true)
    try data.write(to:url(id),options:.atomic)
    do { try encode(preview,jpeg:false).write(to:url(id,thumbnail:true),options:.atomic) }
    catch { try? FileManager.default.removeItem(at:url(id)); throw error }
    return StoredAsset(id:id,width:image.width,height:image.height)
  }
  public func preview(_ id: UUID) throws -> Data { try Data(contentsOf:url(id,thumbnail:true)) }
  public func remove(_ id: UUID) { try? FileManager.default.removeItem(at:url(id)); try? FileManager.default.removeItem(at:url(id,thumbnail:true)) }
  private func encode(_ image: CGImage, jpeg: Bool) throws -> Data {
    let output = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(output, (jpeg ? UTType.jpeg.identifier : UTType.png.identifier) as CFString,1,nil) else { throw ImageFailure.invalidImage }
    CGImageDestinationAddImage(destination,image,[kCGImageDestinationLossyCompressionQuality:0.92] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw ImageFailure.invalidImage }
    return output as Data
  }
  public func render(_ id: UUID, recipe: ExportRecipe, jpeg: Bool = false, previewOnly: Bool = false) throws -> Data {
    let recipe = try recipe.validated()
    let data = try Data(contentsOf:url(id,thumbnail:previewOnly))
    let original = try decode(data,edge: previewOnly ? 1600 : 8192)
    let size = CGSize(width:original.width,height:original.height)
    guard let cropped = original.cropping(to:recipe.crop(for:size).integral) else { throw ImageFailure.invalidImage }
    var output = recipe.outputSize(for:size)
    if previewOnly {
      let scale = min(1,1600/max(output.width,output.height)); output.width *= scale; output.height *= scale
    }
    guard let context = CGContext(data:nil,width:Int(output.width),height:Int(output.height),bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { throw ImageFailure.invalidImage }
    context.setFillColor(CGColor(gray:1,alpha:1)); context.fill(CGRect(origin:.zero,size:output))
    context.interpolationQuality = .high
    context.draw(cropped,in:CGRect(origin:.zero,size:output))
    if !recipe.headline.isEmpty {
      let band = output.height*0.23
      context.setFillColor(CGColor(gray:0,alpha:0.72));context.fill(CGRect(x:0,y:0,width:output.width,height:band))
      let font = CTFontCreateWithName("HelveticaNeue-Medium" as CFString,output.width*0.042,nil)
      let text = NSAttributedString(string:recipe.headline,attributes:[
        NSAttributedString.Key(kCTFontAttributeName as String):font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String):CGColor(gray:1,alpha:1)])
      let frame = CTFramesetterCreateWithAttributedString(text)
      let path = CGPath(rect:CGRect(x:output.width*0.06,y:band*0.15,width:output.width*0.88,height:band*0.72),transform:nil)
      CTFrameDraw(CTFramesetterCreateFrame(frame,CFRange(),path,nil),context)
    }
    guard let result = context.makeImage() else { throw ImageFailure.invalidImage }
    return try encode(result,jpeg:jpeg)
  }
  public func contactSheet(_ ids: [UUID]) throws -> Data {
    guard !ids.isEmpty else { throw ImageFailure.missingAsset }
    let data = NSMutableData()
    guard let consumer = CGDataConsumer(data:data),let context = CGContext(consumer:consumer,mediaBox:nil,nil) else { throw ImageFailure.invalidImage }
    for start in stride(from:0,to:ids.count,by:9) {
      context.beginPDFPage([kCGPDFContextMediaBox: CGRect(x:0,y:0,width:612,height:792)] as CFDictionary)
      for (offset,id) in ids[start..<min(start+9,ids.count)].enumerated() {
        let image = try decode(Data(contentsOf:url(id,thumbnail:true)),edge:512)
        let cell = CGRect(x:30+Double(offset%3)*190,y:550-Double(offset/3)*240,width:172,height:202)
        let factor = min(cell.width/Double(image.width),cell.height/Double(image.height))
        let rect = CGRect(x:cell.midX-Double(image.width)*factor/2,y:cell.midY-Double(image.height)*factor/2,width:Double(image.width)*factor,height:Double(image.height)*factor)
        context.draw(image,in:rect)
      }
      context.endPDFPage()
    }
    context.closePDF(); return data as Data
  }
}
