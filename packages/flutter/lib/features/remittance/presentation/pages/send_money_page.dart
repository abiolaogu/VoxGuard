import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/currency_converter.dart';
import '../widgets/recipient_card.dart';

/// Send money page
class SendMoneyPage extends ConsumerStatefulWidget {
  const SendMoneyPage({super.key});

  @override
  ConsumerState<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends ConsumerState<SendMoneyPage> {
  final _amountController = TextEditingController();
  double _sendAmount = 0;
  double _receiveAmount = 0;
  double _exchangeRate = 1650.00; // Mock rate
  String _selectedCurrency = 'USD';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmounts(double amount) {
    setState(() {
      _sendAmount = amount;
      _receiveAmount = amount * _exchangeRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to transaction history
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Currency converter
                    CurrencyConverter(
                      sendAmount: _sendAmount,
                      receiveAmount: _receiveAmount,
                      sendCurrency: _selectedCurrency,
                      receiveCurrency: 'NGN',
                      exchangeRate: _exchangeRate,
                      onAmountChanged: _updateAmounts,
                      onCurrencyChanged: (currency) {
                        setState(() => _selectedCurrency = currency);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Recipient selection
                    Text(
                      'Select Recipient',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    // Add new recipient button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to add recipient
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add New Recipient'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent recipients
                    Text(
                      'Recent Recipients',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Recipient list (mock data)
                    _buildRecipientCard(
                      name: 'Adebayo Ogunlade',
                      bank: 'GTBank',
                      accountNumber: '0123456789',
                      isSelected: true,
                    ),
                    const SizedBox(height: 8),
                    _buildRecipientCard(
                      name: 'Chioma Nwosu',
                      bank: 'Access Bank',
                      accountNumber: '9876543210',
                      isSelected: false,
                    ),
                    const SizedBox(height: 24),

                    // Transfer details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('You send', CurrencyFormatter.formatCurrency(_sendAmount, _selectedCurrency)),
                          const SizedBox(height: 8),
                          _buildDetailRow('Exchange rate', '1 $_selectedCurrency = ${CurrencyFormatter.formatNaira(_exchangeRate, decimals: 2)}'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Fee', CurrencyFormatter.formatCurrency(_sendAmount * 0.01, _selectedCurrency)),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Recipient gets',
                            CurrencyFormatter.formatNaira(_receiveAmount, decimals: 0),
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _sendAmount > 0 ? () {
                    // Proceed to confirmation
                  } : null,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard({
    required String name,
    required String bank,
    required String accountNumber,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBackground,
            child: Text(
              name.substring(0, 1),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall,
                ),
                Text(
                  '$bank • •••• ${accountNumber.substring(accountNumber.length - 4)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: (isHighlighted ? AppTypography.titleMedium : AppTypography.bodyMedium).copyWith(
            color: isHighlighted ? AppColors.success : AppColors.textPrimary,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
