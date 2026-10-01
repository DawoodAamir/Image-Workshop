import XCTest
import AppKit

@MainActor final class WorkflowTests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }
  override func tearDown() async throws { await MainActor.run { XCUIApplication().terminate() } }
  private func screenshot(_ app: XCUIApplication, _ name: String) {
    let attachment=XCTAttachment(screenshot:app.windows.firstMatch.screenshot())
    attachment.name=name;attachment.lifetime = .keepAlways;add(attachment)
  }
  func testProjectImportLayoutAndPersistence() throws {
    let folder=URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    defer { try? FileManager.default.removeItem(at:folder) }
    let image=NSImage(size:NSSize(width:720,height:480),flipped:false) { rect in
      NSColor(calibratedRed:0.88,green:0.85,blue:0.77,alpha:1).setFill();rect.fill()
      NSColor(calibratedRed:0.18,green:0.35,blue:0.42,alpha:1).setFill()
      NSBezierPath(roundedRect:NSRect(x:210,y:80,width:300,height:320),xRadius:100,yRadius:100).fill()
      return true
    }
    let rep=try XCTUnwrap(NSBitmapImageRep(data:try XCTUnwrap(image.tiffRepresentation)))
    let fixture=folder.appendingPathComponent("fixture.png")
    try XCTUnwrap(rep.representation(using:.png,properties:[:])).write(to:fixture)
    let app=XCUIApplication();app.launchEnvironment["WORKSHOP_TEST_FOLDER"]=folder.path
    app.launch();app.activate()
    XCTAssertTrue(app.buttons["New project"].firstMatch.waitForExistence(timeout:10))
    app.buttons["New project"].firstMatch.click()
    XCTAssertTrue(app.buttons["Import"].waitForExistence(timeout:5))
    app.buttons["Import"].click()
    app.typeKey("g",modifierFlags:[.command,.shift])
    let go=app.dialogs.textFields.firstMatch
    XCTAssertTrue(go.waitForExistence(timeout:5),app.debugDescription)
    go.click();go.typeText(fixture.path);app.typeKey(.return,modifierFlags:[])
    let open=app.dialogs.buttons["Open"]
    XCTAssertTrue(open.waitForExistence(timeout:5),app.debugDescription)
    open.click()
    XCTAssertTrue(app.staticTexts["720 × 480"].waitForExistence(timeout:10),app.debugDescription)
    let title=app.textFields["Name"];title.click();title.typeKey("a",modifierFlags:.command);title.typeText("Coastal campaign")
    let caption=app.textFields["Caption"];caption.click();caption.typeText("A quieter kind of summer")
    app.buttons["Save edits"].click()
    XCTAssertTrue(app.staticTexts["Coastal campaign"].firstMatch.waitForExistence(timeout:5))
    screenshot(app,"workspace")
    app.buttons["Add favourite"].click()
    app.terminate();app.launch();app.activate()
    app.staticTexts["Coastal campaign"].firstMatch.click()
    XCTAssertTrue(app.buttons["Remove favourite"].waitForExistence(timeout:10))
    XCTAssertEqual(app.textFields["Caption"].value as? String,"A quieter kind of summer")
    XCTAssertTrue(app.buttons["Export"].isEnabled)
  }
}
