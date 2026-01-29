/// Application Constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'ACM Platform';

  /// App description
  static const String appDescription = 'Anti-Call Masking Platform';

  /// Nigerian country code
  static const String nigeriaCountryCode = '+234';

  /// Nigerian currency code
  static const String nigerianCurrencyCode = 'NGN';

  /// Nigerian currency symbol
  static const String nairaSymbol = '₦';

  /// Supported currencies for remittance
  static const List<String> supportedCurrencies = [
    'NGN',
    'USD',
    'GBP',
    'EUR',
    'CAD',
    'AUD',
  ];

  /// Currency symbols
  static const Map<String, String> currencySymbols = {
    'NGN': '₦',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'CAD': 'CA\$',
    'AUD': 'A\$',
  };

  /// Nigerian Mobile Network Operators
  static const Map<String, List<String>> mnoPatterns = {
    'MTN': [
      '0703', '0706', '0803', '0806', '0810', '0813',
      '0814', '0816', '0903', '0906', '0913', '0916',
    ],
    'Glo': ['0805', '0807', '0811', '0815', '0905', '0915'],
    'Airtel': [
      '0701', '0708', '0802', '0808', '0812',
      '0902', '0901', '0904', '0907', '0912',
    ],
    '9mobile': ['0809', '0817', '0818', '0909', '0908'],
  };

  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Cache durations
  static const Duration cacheShort = Duration(minutes: 5);
  static const Duration cacheMedium = Duration(hours: 1);
  static const Duration cacheLong = Duration(days: 1);
}

/// Nigerian states
class NigerianStates {
  NigerianStates._();

  static const List<Map<String, String>> states = [
    {'code': 'AB', 'name': 'Abia', 'region': 'South East'},
    {'code': 'AD', 'name': 'Adamawa', 'region': 'North East'},
    {'code': 'AK', 'name': 'Akwa Ibom', 'region': 'South South'},
    {'code': 'AN', 'name': 'Anambra', 'region': 'South East'},
    {'code': 'BA', 'name': 'Bauchi', 'region': 'North East'},
    {'code': 'BY', 'name': 'Bayelsa', 'region': 'South South'},
    {'code': 'BE', 'name': 'Benue', 'region': 'North Central'},
    {'code': 'BO', 'name': 'Borno', 'region': 'North East'},
    {'code': 'CR', 'name': 'Cross River', 'region': 'South South'},
    {'code': 'DE', 'name': 'Delta', 'region': 'South South'},
    {'code': 'EB', 'name': 'Ebonyi', 'region': 'South East'},
    {'code': 'ED', 'name': 'Edo', 'region': 'South South'},
    {'code': 'EK', 'name': 'Ekiti', 'region': 'South West'},
    {'code': 'EN', 'name': 'Enugu', 'region': 'South East'},
    {'code': 'FC', 'name': 'Abuja FCT', 'region': 'North Central'},
    {'code': 'GO', 'name': 'Gombe', 'region': 'North East'},
    {'code': 'IM', 'name': 'Imo', 'region': 'South East'},
    {'code': 'JI', 'name': 'Jigawa', 'region': 'North West'},
    {'code': 'KD', 'name': 'Kaduna', 'region': 'North West'},
    {'code': 'KN', 'name': 'Kano', 'region': 'North West'},
    {'code': 'KT', 'name': 'Katsina', 'region': 'North West'},
    {'code': 'KE', 'name': 'Kebbi', 'region': 'North West'},
    {'code': 'KO', 'name': 'Kogi', 'region': 'North Central'},
    {'code': 'KW', 'name': 'Kwara', 'region': 'North Central'},
    {'code': 'LA', 'name': 'Lagos', 'region': 'South West'},
    {'code': 'NA', 'name': 'Nasarawa', 'region': 'North Central'},
    {'code': 'NI', 'name': 'Niger', 'region': 'North Central'},
    {'code': 'OG', 'name': 'Ogun', 'region': 'South West'},
    {'code': 'ON', 'name': 'Ondo', 'region': 'South West'},
    {'code': 'OS', 'name': 'Osun', 'region': 'South West'},
    {'code': 'OY', 'name': 'Oyo', 'region': 'South West'},
    {'code': 'PL', 'name': 'Plateau', 'region': 'North Central'},
    {'code': 'RI', 'name': 'Rivers', 'region': 'South South'},
    {'code': 'SO', 'name': 'Sokoto', 'region': 'North West'},
    {'code': 'TA', 'name': 'Taraba', 'region': 'North East'},
    {'code': 'YO', 'name': 'Yobe', 'region': 'North East'},
    {'code': 'ZA', 'name': 'Zamfara', 'region': 'North West'},
  ];
}

/// Nigerian banks
class NigerianBanks {
  NigerianBanks._();

  static const List<Map<String, String>> banks = [
    {'code': '044', 'name': 'Access Bank', 'short': 'Access'},
    {'code': '023', 'name': 'Citibank Nigeria', 'short': 'Citibank'},
    {'code': '050', 'name': 'Ecobank Nigeria', 'short': 'Ecobank'},
    {'code': '070', 'name': 'Fidelity Bank', 'short': 'Fidelity'},
    {'code': '011', 'name': 'First Bank of Nigeria', 'short': 'First Bank'},
    {'code': '214', 'name': 'First City Monument Bank', 'short': 'FCMB'},
    {'code': '058', 'name': 'Guaranty Trust Bank', 'short': 'GTBank'},
    {'code': '030', 'name': 'Heritage Bank', 'short': 'Heritage'},
    {'code': '301', 'name': 'Jaiz Bank', 'short': 'Jaiz'},
    {'code': '082', 'name': 'Keystone Bank', 'short': 'Keystone'},
    {'code': '101', 'name': 'Providus Bank', 'short': 'Providus'},
    {'code': '076', 'name': 'Polaris Bank', 'short': 'Polaris'},
    {'code': '039', 'name': 'Stanbic IBTC Bank', 'short': 'Stanbic'},
    {'code': '232', 'name': 'Sterling Bank', 'short': 'Sterling'},
    {'code': '032', 'name': 'Union Bank of Nigeria', 'short': 'Union Bank'},
    {'code': '033', 'name': 'United Bank for Africa', 'short': 'UBA'},
    {'code': '215', 'name': 'Unity Bank', 'short': 'Unity'},
    {'code': '035', 'name': 'Wema Bank', 'short': 'Wema'},
    {'code': '057', 'name': 'Zenith Bank', 'short': 'Zenith'},
    {'code': '100', 'name': 'Kuda Bank', 'short': 'Kuda'},
    {'code': '303', 'name': 'OPay', 'short': 'OPay'},
    {'code': '304', 'name': 'PalmPay', 'short': 'PalmPay'},
    {'code': '305', 'name': 'Moniepoint', 'short': 'Moniepoint'},
  ];
}
