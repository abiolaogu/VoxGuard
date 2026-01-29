import ComposableArchitecture
import SwiftUI

// MARK: - Anti-Masking View

public struct AntiMaskingView: View {
    @Bindable var store: StoreOf<AntiMaskingFeature>
    
    public init(store: StoreOf<AntiMaskingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Verification Form
                    verificationFormCard
                    
                    // Latest Result
                    if let verification = store.latestVerification {
                        latestVerificationCard(verification)
                    }
                    
                    // Fraud Alerts Banner
                    if store.unacknowledgedAlertCount > 0 {
                        fraudAlertsBanner
                    }
                    
                    // History Section
                    historySection
                }
                .padding()
            }
            .navigationTitle("Call Verification")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.loadHistory)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .task {
                await store.send(.loadHistory).finish()
                await store.send(.loadAlerts).finish()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .font(.system(size: 32))
                .foregroundStyle(Color.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Call Verification")
                    .font(.headline)
                
                Text("Detect CLI masking and protect your calls 🇳🇬")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Verification Form
    
    private var verificationFormCard: some View {
        VStack(spacing: 16) {
            // Caller Number
            NigerianPhoneField(
                text: $store.callerNumber.sending(\.callerNumberChanged),
                label: "Caller Number",
                mno: store.callerMNO,
                isEnabled: !store.isVerifying
            )
            
            // Callee Number
            NigerianPhoneField(
                text: $store.calleeNumber.sending(\.calleeNumberChanged),
                label: "Callee Number",
                mno: store.calleeMNO,
                isEnabled: !store.isVerifying
            )
            
            // Verify Button
            Button {
                store.send(.verifyCall)
            } label: {
                HStack {
                    if store.isVerifying {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Verifying...")
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Verify Call")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(store.canVerify ? Color.accentColor : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!store.canVerify)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Latest Verification Card
    
    @ViewBuilder
    private func latestVerificationCard(_ verification: CallVerification) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Status Icon
                Circle()
                    .fill(verification.maskingDetected ? Color.red : Color.green)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: verification.maskingDetected ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .pulseAnimation(isActive: verification.maskingDetected)
                
                VStack(alignment: .leading) {
                    Text(verification.maskingDetected ? "Masking Detected!" : "Verification Complete")
                        .font(.headline)
                        .foregroundStyle(verification.maskingDetected ? .red : .primary)
                    
                    Text("Confidence: \(Int(verification.confidenceScore * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                RiskLevelBadge(level: verification.riskLevel)
            }
            
            if verification.maskingDetected {
                HStack(spacing: 12) {
                    Button {
                        // Block action
                    } label: {
                        Label("Block", systemImage: "hand.raised.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        store.send(.reportToNCC(verification.id))
                    } label: {
                        Label("Report", systemImage: "exclamationmark.bubble.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .padding()
        .background(
            verification.maskingDetected
                ? Color.red.opacity(0.1)
                : Color.green.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Fraud Alerts Banner
    
    private var fraudAlertsBanner: some View {
        HStack {
            Text("\(store.unacknowledgedAlertCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .clipShape(Capsule())
            
            VStack(alignment: .leading) {
                Text("Fraud Alerts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(store.unacknowledgedAlertCount) unacknowledged alerts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Verification History")
                    .font(.headline)
                
                Spacer()
                
                Toggle(isOn: $store.showMaskingDetectedOnly.sending(\.toggleMaskingFilter)) {
                    Text("Masking Only")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
            }
            
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if store.verifications.isEmpty {
                EmptyHistoryView()
            } else {
                ForEach(store.verifications) { verification in
                    VerificationRow(verification: verification) {
                        store.send(.verificationTapped(verification.id))
                    }
                }
            }
        }
    }
}

// MARK: - Nigerian Phone Field

struct NigerianPhoneField: View {
    @Binding var text: String
    let label: String
    let mno: NigerianMNO
    var isEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                // Nigerian flag and prefix
                HStack(spacing: 8) {
                    Text("🇳🇬")
                        .font(.title2)
                    
                    Text("+234")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Divider()
                        .frame(height: 24)
                }
                
                // Phone number input
                TextField("0803 XXX XXXX", text: $text)
                    .keyboardType(.phonePad)
                    .disabled(!isEnabled)
                
                // MNO Badge
                if mno != .unknown {
                    MNOBadge(mno: mno)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - MNO Badge

struct MNOBadge: View {
    let mno: NigerianMNO
    
    var body: some View {
        Text(mno.displayName.components(separatedBy: " ").first ?? mno.rawValue)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var backgroundColor: Color {
        switch mno {
        case .mtn: return Color.yellow
        case .glo: return Color.green
        case .airtel: return Color.red
        case .nineMobile: return Color.green.opacity(0.7)
        case .unknown: return Color.gray
        }
    }
    
    private var textColor: Color {
        switch mno {
        case .mtn: return .black
        default: return .white
        }
    }
}

// MARK: - Risk Level Badge

struct RiskLevelBadge: View {
    let level: RiskLevel
    
    var body: some View {
        Text(level.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var backgroundColor: Color {
        switch level {
        case .low: return Color.green.opacity(0.2)
        case .medium: return Color.yellow.opacity(0.2)
        case .high: return Color.orange.opacity(0.2)
        case .critical: return Color.red.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Verification Row

struct VerificationRow: View {
    let verification: CallVerification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(verification.maskingDetected ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: verification.maskingDetected ? "exclamationmark.triangle" : "checkmark.circle")
                            .foregroundStyle(verification.maskingDetected ? .red : .green)
                    }
                
                VStack(alignment: .leading) {
                    Text(verification.callerNumber)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(verification.verifiedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                RiskLevelBadge(level: verification.riskLevel)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty History View

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No verifications yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Verify a call to see history")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Pulse Animation Modifier

extension View {
    func pulseAnimation(isActive: Bool) -> some View {
        modifier(PulseAnimationModifier(isActive: isActive))
    }
}

struct PulseAnimationModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive && isPulsing ? 1.1 : 1.0)
            .animation(
                isActive
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onAppear {
                isPulsing = isActive
            }
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    AntiMaskingView(
        store: Store(initialState: AntiMaskingFeature.State()) {
            AntiMaskingFeature()
        }
    )
}
