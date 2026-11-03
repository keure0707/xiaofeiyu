import SwiftUI

@main
struct XiaofeiyuApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @State private var tab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("本月", systemImage: "house.fill") }
                .tag(0)

            RecordsView()
                .tabItem { Label("记录", systemImage: "list.bullet") }
                .tag(1)

            StatsView()
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }
                .tag(2)
        }
        .tint(Color.brand)
    }
}
