import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatSessionManager: ChatSessionManager
    
    var body: some View {
        ChatView()
            .environmentObject(appState)
            .environmentObject(chatSessionManager)
            .frame(minWidth: 1024, minHeight: 768)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(ChatSessionManager.shared)
}
