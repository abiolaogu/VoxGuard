import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Currency converter widget
class CurrencyConverter extends StatefulWidget {
  final double sendAmount;
  final double receiveAmount;
  final String sendCurrency;
  final String receiveCurrency;
  final double exchangeRate;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<String> onCurrencyChanged;

  const CurrencyConverter({
    super.key,
    required this.sendAmount,
    required this.receiveAmount,
    required this.sendCurrency,
    required this.receiveCurrency,
    required this.exchangeRate,
    required this.onAmountChanged,
    required this.onCurrencyChanged,
  });

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final _sendController = TextEditingController();
  final _sendFocusNode = FocusNode();

  final List<String> _currencies = ['USD', 'GBP', 'EUR', 'CAD', 'AUD'];

  @override
  void initState() {
    super.initState();
    if (widget.sendAmount > 0) {
      _sendController.text = widget.sendAmount.toString();
    }
  }

  @override
  void dispose() {
    _sendController.dispose();
    _sendFocusNode.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0;
    widget.onAmountChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Send amount
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You send',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _sendController,
                        focusNode: _sendFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTypography.currencyMedium,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        onChanged: _onAmountChanged,
                      ),
                    ],
                  ),
                ),
                // Currency selector
                _buildCurrencySelector(
                  currency: widget.sendCurrency,
                  onTap: () => _showCurrencyPicker(),
                ),
              ],
            ),
          ),

          // Exchange rate indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_vert,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '1 ${widget.sendCurrency} = ${CurrencyFormatter.formatNaira(widget.exchangeRate)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Live rate',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Receive amount
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient gets',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.receiveAmount > 0
                            ? CurrencyFormatter.formatNaira(widget.receiveAmount, showSymbol: false, decimals: 0)
                            : '0.00',
                        style: AppTypography.currencyMedium.copyWith(
                          color: widget.receiveAmount > 0 ? AppColors.success : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // NGN indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.nairaGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '🇳🇬',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NGN',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.nairaGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String currency,
    required VoidCallback onTap,
  }) {
    final flagMap = {
      'USD': '🇺🇸',
      'GBP': '🇬🇧',
      'EUR': '🇪🇺',
      'CAD': '🇨🇦',
      'AUD': '🇦🇺',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              flagMap[currency] ?? '🌍',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              currency,
              style: AppTypography.labelLarge,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Currency',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._currencies.map((currency) {
              final flagMap = {
                'USD': '🇺🇸',
                'GBP': '🇬🇧',
                'EUR': '🇪🇺',
                'CAD': '🇨🇦',
                'AUD': '🇦🇺',
              };
              final nameMap = {
                'USD': 'US Dollar',
                'GBP': 'British Pound',
                'EUR': 'Euro',
                'CAD': 'Canadian Dollar',
                'AUD': 'Australian Dollar',
              };

              return ListTile(
                leading: Text(flagMap[currency] ?? '🌍', style: const TextStyle(fontSize: 24)),
                title: Text(currency),
                subtitle: Text(nameMap[currency] ?? ''),
                trailing: widget.sendCurrency == currency
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  widget.onCurrencyChanged(currency);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
