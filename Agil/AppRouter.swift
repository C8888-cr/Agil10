import SwiftUI

struct AppRouter: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var session: SessionManager

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if session.isAuthenticated && !session.requiresBiometricUnlock {
                ContentView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: session.isAuthenticated)
        .animation(.easeInOut, value: session.requiresBiometricUnlock)
    }
}
