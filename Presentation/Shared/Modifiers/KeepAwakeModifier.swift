//
//  KeepAwakeModifier.swift

import SwiftUI

struct KeepAwakeModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .onChange(of: scenePhase) { _, phase in
                UIApplication.shared.isIdleTimerDisabled = (phase == .active)
            }
    }
}

extension View {
    func keepScreenAwake() -> some View {
        modifier(KeepAwakeModifier())
    }
}
