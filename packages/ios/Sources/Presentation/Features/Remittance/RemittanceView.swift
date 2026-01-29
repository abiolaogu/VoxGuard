import ComposableArchitecture
import SwiftUI

// MARK: - Remittance View

public struct RemittanceView: View {
    @Bindable var store: StoreOf<RemittanceFeature>
    
    public init(store: StoreOf<RemittanceFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exchange Rate Banner
                    exchangeRateBanner
                    
                    // Amount Input
                    amountInputSection
                    
                    // Recipient Selection
                    recipientSection
                    
                    // Fee Summary
                    feeSummary
                    
                    // Send Button
                    sendButton
                    
                    // Recent Transactions
                    transactionsSection
                }
                .padding()
            }
            .navigationTitle("Send Money")
            .task {
                await store.send(.fetchExchangeRate).finish()
                await store.send(.loadRecipients).finish()
                await store.send(.loadTransactions).finish()
            }
        }
    }
    
    // MARK: - Exchange Rate Banner
    
    private var exchangeRateBanner: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Today's Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let rate = store.exchangeRate {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("1 \(rate.sourceCurrency.symbol)")
                            .font(.headline)
                        
                        Text("=")
                            .foregroundStyle(.secondary)
                        
                        Text("\(rate.rate, format: .number) \(rate.targetCurrency.symbol)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }
                } else if store.isLoadingRate {
                    ProgressView()
                } else {
                    Text("--")
                        .font(.title2)
                }
            }
            
            Spacer()
            
            Text("🇺🇸 → 🇳🇬")
                .font(.title)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Amount Input Section
    
    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("You Send")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text(store.sourceCurrency.symbol)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                
                TextField("0.00", text: $store.amountString.sending(\.amountChanged))
                    .font(.system(size: 32, weight: .bold))
                    .keyboardType(.decimalPad)
                
                Menu {
                    ForEach([Currency.usd, .gbp, .eur, .cad], id: \.self) { currency in
                        Button("\(currency.flag) \(currency.rawValue)") {
                            store.send(.sourceCurrencySelected(currency))
                        }
                    }
                } label: {
                    HStack {
                        Text(store.sourceCurrency.flag)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
            }
            
            Divider()
            
            Text("They Receive")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text(store.targetCurrency.symbol)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                
                if let received = store.receivedAmount {
                    Text("\(received, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 32, weight: .bold))
                } else {
                    Text("0.00")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Text("🇳🇬")
                    Text("NGN")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Recipient Section
    
    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Send To")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("+ Add New") {
                    store.send(.addRecipient)
                }
                .font(.caption)
            }
            
            if store.isLoadingRecipients {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if store.recipients.isEmpty {
                ContentUnavailableView(
                    "No Recipients",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("Add a recipient to send money")
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.recipients) { recipient in
                            RecipientCard(
                                recipient: recipient,
                                isSelected: store.selectedRecipient?.id == recipient.id
                            ) {
                                store.send(.recipientSelected(recipient))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Fee Summary
    
    private var feeSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Transfer Fee")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.sourceCurrency.symbol)\(store.fee, format: .number.precision(.fractionLength(2)))")
            }
            
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                if let total = store.totalCost {
                    Text("\(store.sourceCurrency.symbol)\(total, format: .number.precision(.fractionLength(2)))")
                        .fontWeight(.bold)
                } else {
                    Text("--")
                }
            }
        }
        .font(.subheadline)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button {
            store.send(.sendMoney)
        } label: {
            HStack {
                if store.isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("Processing...")
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Send Money")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(store.canSend ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!store.canSend)
    }
    
    // MARK: - Transactions Section
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transfers")
                .font(.headline)
            
            if store.isLoadingTransactions {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if store.transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.transactions.prefix(5)) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
}

// MARK: - Recipient Card

struct RecipientCard: View {
    let recipient: Recipient
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text(recipient.fullName.prefix(2).uppercased())
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                
                Text(recipient.fullName.components(separatedBy: " ").first ?? "")
                    .font(.caption)
                    .foregroundStyle(.primary)
                
                if let bank = recipient.bankName {
                    Text(bank)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: RemittanceTransaction
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: statusIcon)
                        .foregroundStyle(statusColor)
                }
            
            VStack(alignment: .leading) {
                Text(transaction.recipientName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(transaction.currencySent.symbol)\(transaction.amountSent, format: .number.precision(.fractionLength(2)))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusColor: Color {
        switch transaction.status {
        case .completed: return .green
        case .processing: return .orange
        case .pending: return .blue
        case .failed, .cancelled: return .red
        }
    }
    
    private var statusIcon: String {
        switch transaction.status {
        case .completed: return "checkmark.circle.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        case .pending: return "clock.fill"
        case .failed, .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    RemittanceView(
        store: Store(initialState: RemittanceFeature.State()) {
            RemittanceFeature()
        }
    )
}
