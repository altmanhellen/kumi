import SwiftUI

@main
struct KumiApp: App {
    @State private var model = AppModel()
    @State private var store = Store()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(store)
                .task {
                    VoiceCatalog.shared.load()
                    store.start(model: model)
                }
                // Text grows with the system setting up to the largest standard size; the accessibility
                // sizes beyond that would break the hand-drawn cards.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .preferredColorScheme(model.prefs.theme == .system ? nil : (model.prefs.theme == .dark ? .dark : .light))
                .tint(Palette.blue)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.refreshDay()
                // Re-register the daily reminder so its text follows the current app name.
                if model.prefs.reminderEnabled { Reminders.schedule(hour: model.prefs.reminderHour, minute: model.prefs.reminderMinute) }
            case .background: model.persistSession()
            default: break
            }
        }
    }
}

enum MainTab: Hashable { case today, catalog, progress, settings }

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var tab: MainTab = .today

    var body: some View {
        @Bindable var model = model
        Group {
            if model.prefs.onboarded {
                MainTabs(tab: $tab)
            } else {
                OnboardingFlow { tab = $0 }
            }
        }
        #if DEBUG
        .onAppear {
            model.applyDebugArguments()
            if let t = AppModel.debugTab { tab = t }
        }
        #endif
        .sheet(isPresented: $model.showPaywall) {
            PaywallView()
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $model.showingSession) {
            SessionView()
                .environment(model)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}

struct MainTabs: View {
    @Environment(AppModel.self) private var model
    @Binding var tab: MainTab
    /// Tapping the open tab again returns it to its first screen, as in other iOS apps.
    @State private var resets: [MainTab: Int] = [:]

    var body: some View {
        VStack(spacing: 0) {
        TabView(selection: $tab) {
            TodayView(openCatalog: { tab = .catalog }, openTopic: { t in
                model.pendingCatalog = .topic(t)
                tab = .catalog
            })
                .toolbar(.hidden, for: .tabBar)
                .tag(MainTab.today)
            CatalogView()
                .id(resets[.catalog, default: 0])
                .toolbar(.hidden, for: .tabBar)
                .tag(MainTab.catalog)
            ProgressScreen()
                .toolbar(.hidden, for: .tabBar)
                .tag(MainTab.progress)
            NavigationStack { SettingsView() }
                .id(resets[.settings, default: 0])
                .toolbar(.hidden, for: .tabBar)
                .tag(MainTab.settings)
        }
        TabBar(tab: $tab) { resets[$0, default: 0] += 1 }
        }
        .ignoresSafeArea(.keyboard)
    }
}

/// Bottom bar from the designs: flat, a line on top, icons with labels.
struct TabBar: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var tab: MainTab
    var reselect: (MainTab) -> Void = { _ in }
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            item(.today, "Сегодня", "calendar", Palette.teal)
            item(.catalog, "Каталог", "rectangle.stack", Palette.peach)
            item(.progress, "Прогресс", "chart.bar", Palette.lilac)
            item(.settings, "Настройки", "gearshape", Palette.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.top, 7)
        .dynamicTypeSize(...DynamicTypeSize.large)
        .background(Palette.background.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Palette.navBorder).frame(height: scheme == .dark ? 1 : 1.5) }
    }

    private func item(_ t: MainTab, _ title: String, _ icon: String, _ fill: Color) -> some View {
        let on = tab == t
        return Button {
            if tab == t { reselect(t) } else { tab = t }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if on {
                        Image(systemName: icon + ".fill").font(.system(size: 22, weight: .regular)).foregroundStyle(fill)
                    }
                    Image(systemName: icon).font(.system(size: 22, weight: .medium))
                }
                .frame(height: 26)
                Text(title).font(WPFont.nunito(11, on ? .heavy : .bold, relativeTo: .caption2))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(on ? Palette.text : Palette.muted)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }
}
