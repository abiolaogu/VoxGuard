import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/currency_formatter.dart';

/// Beautiful remittance flow stepper widget
class RemittanceFlowStepper extends StatefulWidget {
  final int currentStep;
  final double? sendAmount;
  final String sendCurrency;
  final double? receiveAmount;
  final String receiveCurrency;
  final double? exchangeRate;
  final double? fee;
  final String? recipientName;
  final ValueChanged<int>? onStepChanged;

  const RemittanceFlowStepper({
    super.key,
    required this.currentStep,
    this.sendAmount,
    this.sendCurrency = 'USD',
    this.receiveAmount,
    this.receiveCurrency = 'NGN',
    this.exchangeRate,
    this.fee,
    this.recipientName,
    this.onStepChanged,
  });

  @override
  State<RemittanceFlowStepper> createState() => _RemittanceFlowStepperState();
}

class _RemittanceFlowStepperState extends State<RemittanceFlowStepper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<_StepInfo> _steps = const [
    _StepInfo(title: 'Amount', icon: Icons.attach_money),
    _StepInfo(title: 'Recipient', icon: Icons.person),
    _StepInfo(title: 'Review', icon: Icons.fact_check),
    _StepInfo(title: 'Confirm', icon: Icons.check_circle),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step indicators
        _buildStepIndicators(),
        const SizedBox(height: 24),

        // Current step content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildStepContent(),
        ),
      ],
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < widget.currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        // Step indicator
        final stepIndex = index ~/ 2;
        final step = _steps[stepIndex];
        final isActive = stepIndex == widget.currentStep;
        final isCompleted = stepIndex < widget.currentStep;

        return GestureDetector(
          onTap: () {
            if (stepIndex < widget.currentStep) {
              HapticFeedback.lightImpact();
              widget.onStepChanged?.call(stepIndex);
            }
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 48 : 40,
                height: isActive ? 48 : 40,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? AppColors.primary
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check : step.icon,
                  color: isCompleted || isActive
                      ? Colors.white
                      : AppColors.textTertiary,
                  size: isActive ? 24 : 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.title,
                style: AppTypography.labelSmall.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (widget.currentStep) {
      case 0:
        return _buildAmountStep();
      case 1:
        return _buildRecipientStep();
      case 2:
        return _buildReviewStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAmountStep() {
    return Container(
      key: const ValueKey('amount'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Currency conversion preview
          if (widget.sendAmount != null && widget.receiveAmount != null)
            _buildConversionPreview(),
        ],
      ),
    );
  }

  Widget _buildConversionPreview() {
    return Column(
      children: [
        // Send amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You send',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              CurrencyFormatter.formatCurrency(
                widget.sendAmount!,
                widget.sendCurrency,
              ),
              style: AppTypography.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Exchange rate indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_vert, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '1 ${widget.sendCurrency} = ${CurrencyFormatter.formatNaira(widget.exchangeRate ?? 0)}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Receive amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recipient gets',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              CurrencyFormatter.formatNaira(widget.receiveAmount!, decimals: 0),
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        // Fee breakdown
        if (widget.fee != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildFeeRow('Transfer fee', widget.fee!),
          const SizedBox(height: 8),
          _buildFeeRow(
            'Total',
            widget.sendAmount! + widget.fee!,
            isTotal: true,
          ),
        ],
      ],
    );
  }

  Widget _buildFeeRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? AppTypography.labelLarge : AppTypography.bodySmall)
              .copyWith(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.formatCurrency(amount, widget.sendCurrency),
          style: (isTotal ? AppTypography.titleSmall : AppTypography.bodySmall)
              .copyWith(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientStep() {
    return Container(
      key: const ValueKey('recipient'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Select Recipient',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose who will receive this transfer',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Container(
      key: const ValueKey('review'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fact_check,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Review Transfer',
            style: AppTypography.titleMedium,
          ),
          if (widget.recipientName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Sending to ${widget.recipientName}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    return Container(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.success.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Send',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirm to complete your transfer',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final String title;
  final IconData icon;

  const _StepInfo({
    required this.title,
    required this.icon,
  });
}
