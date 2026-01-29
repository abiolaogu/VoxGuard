import SwiftUI
import ComposableArchitecture

// MARK: - Fraud Dashboard View

struct FraudDashboardView: View {
    let store: StoreOf<FraudDashboardFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Summary Section
                        Text("Fraud Summary")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if viewStore.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if let error = viewStore.errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                        } else {
                            SummaryCardsView(summary: viewStore.summary)
                            RevenueProtectedCard(amount: viewStore.summary.totalRevenueProtected)
                        }
                        
                        // Quick Actions
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        ActionTile(
                            icon: "shield.fill",
                            title: "CLI Verifications",
                            subtitle: "View spoofing detections",
                            color: .red
                        )
                        
                        ActionTile(
                            icon: "globe",
                            title: "IRSF Incidents",
                            subtitle: "International revenue share fraud",
                            color: .orange
                        )
                        
                        ActionTile(
                            icon: "phone.arrow.down.left",
                            title: "Wangiri Detection",
                            subtitle: "One-ring fraud tracking",
                            color: .blue
                        )
                    }
                    .padding()
                }
                .navigationTitle("Fraud Prevention")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { viewStore.send(.refresh) }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .refreshable {
                    viewStore.send(.refresh)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

// MARK: - Summary Cards

struct SummaryCardsView: View {
    let summary: FraudSummary
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "CLI Spoofing",
                    count: summary.cliSpoofingCount,
                    icon: "shield.fill",
                    color: .red
                )
                SummaryCard(
                    title: "IRSF",
                    count: summary.irsfCount,
                    icon: "globe",
                    color: .orange
                )
            }
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Wangiri",
                    count: summary.wangiriCount,
                    icon: "phone.arrow.down.left",
                    color: .blue
                )
                SummaryCard(
                    title: "Callback",
                    count: summary.callbackFraudCount,
                    icon: "phone.arrow.right",
                    color: .purple
                )
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
            }
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct RevenueProtectedCard: View {
    let amount: Double
    
    var body: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Revenue Protected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("₦\(Int(amount).formatted())")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Risk Score View

struct RiskScoreView: View {
    let score: Double
    
    var color: Color {
        if score >= 0.7 { return .red }
        if score >= 0.4 { return .orange }
        return .green
    }
    
    var label: String {
        if score >= 0.7 { return "HIGH" }
        if score >= 0.4 { return "MEDIUM" }
        return "LOW"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(color, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            .frame(width: 48, height: 48)
            
            Text(label)
                .font(.system(size: 10))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    FraudDashboardView(
        store: Store(initialState: FraudDashboardFeature.State(
            summary: FraudSummary(
                cliSpoofingCount: 47,
                irsfCount: 23,
                wangiriCount: 156,
                callbackFraudCount: 12,
                totalRevenueProtected: 15420000
            )
        )) {
            FraudDashboardFeature()
        }
    )
}
