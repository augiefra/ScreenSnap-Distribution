#if canImport(TipKit)
import TipKit
import SwiftUI

@available(macOS 14.0, *)
struct QuickCaptureTip: Tip {
    var title: Text {
        Text("Astuce PastScreen")
    }

    var message: Text? {
        Text("Utilisez ⌥⌘S ou les Raccourcis Apple pour lancer une capture instantanée.")
    }

    var image: Image? {
        Image(systemName: "command.circle")
    }
}
#endif
