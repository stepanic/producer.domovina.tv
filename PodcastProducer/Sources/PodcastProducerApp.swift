import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        DispatchQueue.main.async {
            NSApp.windows.first?.zoom(nil)
        }
    }
}

@main
struct PodcastProducerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Podcast Producer") {
            ContentView()
        }
        .defaultSize(width: 720, height: 700)
    }
}
