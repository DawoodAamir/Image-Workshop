import Testing
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import WorkshopCore

@Test func centeredCropAndDimensions() throws {
  let recipe=ExportRecipe(format:.portrait,longestEdge:2048)
  #expect(recipe.crop(for:CGSize(width:2400,height:1200)) == CGRect(x:750,y:0,width:900,height:1200))
  #expect(recipe.outputSize(for:CGSize(width:2400,height:1200)) == CGSize(width:1536,height:2048))
  #expect(throws:ImageFailure.self) { try ExportRecipe(longestEdge:100_000).validated() }
}
@Test func immutableAssetsAndExport() async throws {
  let folder=URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at:folder) }
  let context=try #require(CGContext(data:nil,width:100,height:60,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
  context.setFillColor(CGColor(red:0.1,green:0.4,blue:0.6,alpha:1));context.fill(CGRect(x:0,y:0,width:100,height:60))
  let data=NSMutableData();let destination=try #require(CGImageDestinationCreateWithData(data,UTType.png.identifier as CFString,1,nil))
  CGImageDestinationAddImage(destination,try #require(context.makeImage()),nil);#expect(CGImageDestinationFinalize(destination))
  let library=AssetLibrary(folder:folder);let first=try await library.store(data as Data);let second=try await library.store(data as Data)
  #expect(first.id != second.id)
  let output=try await library.render(first.id,recipe:ExportRecipe(format:.square,longestEdge:256,headline:"Preview"))
  let source=try #require(CGImageSourceCreateWithData(output as CFData,nil));let image=try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
  #expect(image.width == 256 && image.height == 256)
  let pdf=try await library.contactSheet([first.id,second.id]);#expect(pdf.starts(with:Data("%PDF".utf8)))
  await library.remove(first.id);#expect(try await library.preview(second.id).count > 0)
  await #expect(throws:ImageFailure.self) { try await library.store(Data("not an image".utf8)) }
}
