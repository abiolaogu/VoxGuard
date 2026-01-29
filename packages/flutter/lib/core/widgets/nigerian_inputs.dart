import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../constants/app_constants.dart';

/// Nigerian phone number input field with +234 prefix and MNO detection
class NigerianPhoneInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onMNODetected;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool enabled;
  final bool showMNOBadge;

  const NigerianPhoneInput({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onMNODetected,
    this.labelText,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.showMNOBadge = true,
  });

  @override
  State<NigerianPhoneInput> createState() => _NigerianPhoneInputState();
}

class _NigerianPhoneInputState extends State<NigerianPhoneInput> {
  late TextEditingController _controller;
  String? _detectedMNO;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _detectMNO(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _detectMNO(String value) {
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length >= 4) {
      final prefix = cleanNumber.startsWith('234')
          ? cleanNumber.substring(3, 7)
          : cleanNumber.substring(0, 4);
      final mno = AppConstants.detectMNO(prefix);
      if (mno != _detectedMNO) {
        setState(() => _detectedMNO = mno);
        widget.onMNODetected?.call(mno);
      }
    } else {
      if (_detectedMNO != null) {
        setState(() => _detectedMNO = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
            _NigerianPhoneFormatter(),
          ],
          decoration: InputDecoration(
            hintText: widget.hintText ?? '803 XXX XXXX',
            errorText: widget.errorText,
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nigerian flag
                  const Text('🇳🇬', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  // +234 prefix
                  Text(
                    '+234',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Divider
                  Container(
                    height: 24,
                    width: 1,
                    color: AppColors.border,
                  ),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: widget.showMNOBadge && _detectedMNO != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildMNOBadge(_detectedMNO!),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
          onChanged: (value) {
            _detectMNO(value);
            widget.onChanged?.call('+234${value.replaceAll(' ', '')}');
          },
        ),
      ],
    );
  }

  Widget _buildMNOBadge(String mno) {
    return Container(
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
    );
  }
}

class _NigerianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// State/LGA cascading dropdown
class StateLGADropdown extends StatefulWidget {
  final String? selectedState;
  final String? selectedLGA;
  final ValueChanged<String>? onStateChanged;
  final ValueChanged<String>? onLGAChanged;
  final bool showStateOnly;

  const StateLGADropdown({
    super.key,
    this.selectedState,
    this.selectedLGA,
    this.onStateChanged,
    this.onLGAChanged,
    this.showStateOnly = false,
  });

  @override
  State<StateLGADropdown> createState() => _StateLGADropdownState();
}

class _StateLGADropdownState extends State<StateLGADropdown> {
  String? _selectedState;
  String? _selectedLGA;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.selectedState;
    _selectedLGA = widget.selectedLGA;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State dropdown
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: const InputDecoration(
            labelText: 'State',
            prefixIcon: Icon(Icons.location_city),
          ),
          items: AppConstants.nigerianStates.map((state) {
            final region = _getRegion(state);
            return DropdownMenuItem(
              value: state,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getRegionColor(region),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(state),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedLGA = null;
            });
            widget.onStateChanged?.call(value!);
          },
        ),

        // LGA dropdown (mocked for now - would need real data)
        if (!widget.showStateOnly && _selectedState != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedLGA,
            decoration: const InputDecoration(
              labelText: 'Local Government Area',
              prefixIcon: Icon(Icons.location_on),
            ),
            items: _getLGAs(_selectedState!).map((lga) {
              return DropdownMenuItem(
                value: lga,
                child: Text(lga),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedLGA = value);
              widget.onLGAChanged?.call(value!);
            },
          ),
        ],
      ],
    );
  }

  String _getRegion(String state) {
    if (['Lagos', 'Ogun', 'Oyo', 'Osun', 'Ondo', 'Ekiti'].contains(state)) {
      return 'South West';
    } else if (['Anambra', 'Enugu', 'Imo', 'Abia', 'Ebonyi'].contains(state)) {
      return 'South East';
    } else if (['Rivers', 'Bayelsa', 'Delta', 'Edo', 'Akwa Ibom', 'Cross River']
        .contains(state)) {
      return 'South South';
    } else if (['Kano', 'Kaduna', 'Katsina', 'Sokoto', 'Kebbi', 'Zamfara', 'Jigawa']
        .contains(state)) {
      return 'North West';
    } else if (['Borno', 'Yobe', 'Adamawa', 'Bauchi', 'Gombe', 'Taraba']
        .contains(state)) {
      return 'North East';
    }
    return 'North Central';
  }

  Color _getRegionColor(String region) {
    switch (region) {
      case 'South West':
        return AppColors.southWest;
      case 'South East':
        return AppColors.southEast;
      case 'South South':
        return AppColors.southSouth;
      case 'North West':
        return AppColors.northWest;
      case 'North East':
        return AppColors.northEast;
      case 'North Central':
        return AppColors.northCentral;
      default:
        return AppColors.textTertiary;
    }
  }

  List<String> _getLGAs(String state) {
    // Mock LGAs - would need real data
    return [
      '$state Central',
      '$state East',
      '$state West',
      '$state North',
      '$state South',
    ];
  }
}

/// Nigerian bank selector
class NigerianBankSelector extends StatelessWidget {
  final String? selectedBankCode;
  final ValueChanged<String>? onBankSelected;
  final bool showLogos;

  const NigerianBankSelector({
    super.key,
    this.selectedBankCode,
    this.onBankSelected,
    this.showLogos = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedBankCode,
      decoration: const InputDecoration(
        labelText: 'Select Bank',
        prefixIcon: Icon(Icons.account_balance),
      ),
      isExpanded: true,
      items: AppConstants.nigerianBanks.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              // Bank icon/logo placeholder
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getBankColor(entry.value).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    entry.value.substring(0, 2).toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: _getBankColor(entry.value),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        HapticFeedback.selectionClick();
        onBankSelected?.call(value!);
      },
    );
  }

  Color _getBankColor(String bankName) {
    // Color coding for popular banks
    final lowerName = bankName.toLowerCase();
    if (lowerName.contains('gtbank') || lowerName.contains('guaranty')) {
      return const Color(0xFFE6590D); // GTBank orange
    } else if (lowerName.contains('access')) {
      return const Color(0xFF0056A2); // Access blue
    } else if (lowerName.contains('zenith')) {
      return const Color(0xFFCE0A24); // Zenith red
    } else if (lowerName.contains('first bank')) {
      return const Color(0xFF003399); // First Bank blue
    } else if (lowerName.contains('uba')) {
      return const Color(0xFFCE0A24); // UBA red
    } else if (lowerName.contains('kuda')) {
      return const Color(0xFF40196D); // Kuda purple
    } else if (lowerName.contains('opay')) {
      return const Color(0xFF1DCE59); // OPay green
    }
    return AppColors.primary;
  }
}

/// Nigerian flag accent toggle
class NigeriaFlagToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const NigeriaFlagToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.bodyMedium,
          ),
          const Spacer(),
        ],
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged?.call(!value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: value
                  ? LinearGradient(
                      colors: [
                        AppColors.nigeriaGreen,
                        AppColors.nigeriaGreen.withOpacity(0.8),
                      ],
                    )
                  : null,
              color: value ? null : AppColors.chipBackground,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: value
                    ? const Center(
                        child: Text('🇳🇬', style: TextStyle(fontSize: 16)),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
