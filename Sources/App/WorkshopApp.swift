import SwiftUI
import SwiftData
import AppKit

@main struct WorkshopApp: App {
  private let container: ModelContainer?
  private let failure: String?
  init() {
    do {
      let test = ProcessInfo.processInfo.environment["WORKSHOP_TEST_FOLDER"]
      let url = test.map { URL(fileURLWithPath:$0).appendingPathComponent("library.store") }
      if let url { try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true) }
      let config = url.map { ModelConfiguration(url:$0) } ?? ModelConfiguration()
      container = try ModelContainer(for:Artwork.self,ArtworkVersion.self,configurations:config)
      failure = nil
    } catch { container = nil;failure = error.localizedDescription }
  }
  var body: some Scene {
    WindowGroup {
      if let container { WorkshopView().modelContainer(container) }
      else { ContentUnavailableView("Library couldn’t open",systemImage:"externaldrive.badge.exclamationmark",description:Text(failure ?? "Restart the app to try again. Your saved files have not been replaced.")) }
    }.defaultSize(width:1180,height:780)
    .commands { CommandGroup(replacing:.newItem) {
      Button("New project") { NotificationCenter.default.post(name:Notification.Name("WorkshopNewProject"),object:nil) }.keyboardShortcut("n")
    } }
  }
}
