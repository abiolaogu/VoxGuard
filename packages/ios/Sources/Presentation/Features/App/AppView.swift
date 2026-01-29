import ComposableArchitecture
import SwiftUI

// MARK: - App View (Root)

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            // Anti-Masking Tab
            AntiMaskingView(
                store: store.scope(state: \.antiMasking, action: \.antiMasking)
            )
            .tabItem {
                Label(AppFeature.Tab.antiMasking.rawValue, systemImage: AppFeature.Tab.antiMasking.icon)
            }
            .tag(AppFeature.Tab.antiMasking)
            
            // Remittance Tab
            RemittanceView(
                store: store.scope(state: \.remittance, action: \.remittance)
            )
            .tabItem {
                Label(AppFeature.Tab.remittance.rawValue, systemImage: AppFeature.Tab.remittance.icon)
            }
            .tag(AppFeature.Tab.remittance)
            
            // Marketplace Tab
            MarketplaceView(
                store: store.scope(state: \.marketplace, action: \.marketplace)
            )
            .tabItem {
                Label(AppFeature.Tab.marketplace.rawValue, systemImage: AppFeature.Tab.marketplace.icon)
            }
            .tag(AppFeature.Tab.marketplace)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label(AppFeature.Tab.settings.rawValue, systemImage: AppFeature.Tab.settings.icon)
                }
                .tag(AppFeature.Tab.settings)
        }
        .tint(Color.accentColor)
    }
}

// MARK: - Settings View (Placeholder)

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Label("Profile", systemImage: "person.circle")
                    Label("Security", systemImage: "lock.shield")
                    Label("Notifications", systemImage: "bell.badge")
                }
                
                Section("Preferences") {
                    Label("Appearance", systemImage: "paintbrush")
                    Label("Language", systemImage: "globe")
                }
                
                Section("About") {
                    Label("Help & Support", systemImage: "questionmark.circle")
                    Label("Terms of Service", systemImage: "doc.text")
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                Section {
                    Button(role: .destructive) {
                        // Sign out
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
