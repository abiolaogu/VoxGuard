import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

/// Masking report page for submitting to NCC
class MaskingReportPage extends ConsumerStatefulWidget {
  final String? verificationId;

  const MaskingReportPage({
    super.key,
    this.verificationId,
  });

  @override
  ConsumerState<MaskingReportPage> createState() => _MaskingReportPageState();
}

class _MaskingReportPageState extends ConsumerState<MaskingReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _selectedCategory;

  final List<Map<String, String>> _categories = [
    {'value': 'cli_spoofing', 'label': 'CLI Spoofing'},
    {'value': 'number_masking', 'label': 'Number Masking'},
    {'value': 'illegal_routing', 'label': 'Illegal Routing'},
    {'value': 'fraud_attempt', 'label': 'Fraud Attempt'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // TODO: Submit report via provider
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report to NCC'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.warning, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Masking Incident',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This report will be submitted to the Nigerian Communications Commission (NCC).',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Verification ID
                if (widget.verificationId != null) ...[
                  TextFormField(
                    initialValue: widget.verificationId,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Verification Reference',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Incident Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the masking incident in detail...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a description';
                    }
                    if (value.length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Additional notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText: 'Any additional information...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Evidence section
                Text(
                  'Evidence (Optional)',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Add evidence attachment
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach Evidence'),
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Report to NCC'),
                  ),
                ),
                const SizedBox(height: 16),

                // Disclaimer
                Text(
                  'By submitting this report, you confirm that the information provided is accurate to the best of your knowledge.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
