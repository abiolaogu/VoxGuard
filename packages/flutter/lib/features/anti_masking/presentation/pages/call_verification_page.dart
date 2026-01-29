import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../providers/anti_masking_provider.dart';
import '../widgets/verification_status_card.dart';
import '../widgets/masking_alert_banner.dart';

/// Call verification page
class CallVerificationPage extends ConsumerStatefulWidget {
  const CallVerificationPage({super.key});

  @override
  ConsumerState<CallVerificationPage> createState() => _CallVerificationPageState();
}

class _CallVerificationPageState extends ConsumerState<CallVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _callerController = TextEditingController();
  final _calleeController = TextEditingController();
  
  String? _callerMno;
  String? _calleeMno;

  @override
  void dispose() {
    _callerController.dispose();
    _calleeController.dispose();
    super.dispose();
  }

  void _onCallerChanged(String value) {
    setState(() {
      _callerMno = PhoneFormatter.detectMNO(value);
    });
  }

  void _onCalleeChanged(String value) {
    setState(() {
      _calleeMno = PhoneFormatter.detectMNO(value);
    });
  }

  Future<void> _verifyCall() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(callVerificationNotifierProvider.notifier).verifyCall(
      _callerController.text,
      _calleeController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callVerificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Call'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to history
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'CLI Masking Detection',
                style: AppTypography.headlineSmall,
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 8),
              Text(
                'Enter the caller and callee numbers to verify if CLI masking is present.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 24),

              // Show last verification result
              if (state.lastVerification != null) ...[
                VerificationStatusCard(
                  verification: state.lastVerification!,
                  onDismiss: () {
                    ref.read(callVerificationNotifierProvider.notifier)
                        .clearLastVerification();
                  },
                ).animate().slideY(begin: -0.1, end: 0).fadeIn(),
                const SizedBox(height: 24),
              ],

              // Show masking alert if detected
              if (state.lastVerification?.maskingDetected == true) ...[
                MaskingAlertBanner(
                  verification: state.lastVerification!,
                  onReport: () {
                    // Navigate to report page
                  },
                ).animate().shake(),
                const SizedBox(height: 24),
              ],

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Caller number input
                    _buildPhoneInput(
                      controller: _callerController,
                      label: 'Caller Number (A-Number)',
                      hint: '0803 123 4567',
                      mno: _callerMno,
                      onChanged: _onCallerChanged,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),

                    // Arrow indicator
                    Icon(
                      Icons.arrow_downward,
                      color: AppColors.textTertiary,
                      size: 32,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 16),

                    // Callee number input
                    _buildPhoneInput(
                      controller: _calleeController,
                      label: 'Callee Number (B-Number)',
                      hint: '0805 987 6543',
                      mno: _calleeMno,
                      onChanged: _onCalleeChanged,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                    const SizedBox(height: 32),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: state.isLoading ? null : _verifyCall,
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_user),
                        label: Text(
                          state.isLoading ? 'Verifying...' : 'Verify Call',
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),
                  ],
                ),
              ),

              // Error message
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? mno,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.phone),
        suffixIcon: mno != null
            ? Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getMnoColor(mno).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  mno,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.getMnoColor(mno),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        if (!PhoneFormatter.isValid(value)) {
          return 'Please enter a valid Nigerian phone number';
        }
        return null;
      },
    );
  }
}
