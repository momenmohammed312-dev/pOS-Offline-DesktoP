class LicenseConfig {
  // SECURITY: Production-secure key - CHANGE BEFORE DEPLOYMENT!
  static const String secretKey = 'POS-SaaS-2026-PROD-SECURE-K3Y-F0R-L1C3NS3!';

  // License duration types
  static const Map<String, Map<String, dynamic>> licenseDurations = {
    'monthly': {'name': 'شهري', 'days': 30, 'price_multiplier': 1.0},
    'yearly': {
      'name': 'سنوي',
      'days': 365,
      'price_multiplier': 10.0, // 10 months for 12 = 2 months free
    },
    'lifetime': {
      'name': 'مدى الحياة',
      'days': 36500, // 100 years
      'price_multiplier': 20.0, // 20x monthly for lifetime
    },
  };

  // License duration in days
  static const int defaultLicenseDays = 365;

  // Available features
  static const List<String> availableFeatures = [
    'pos', // Point of Sale
    'inventory', // Inventory Management
    'customers', // Customer Management
    'suppliers', // Supplier Management
    'reports', // Reports & Analytics
    'accounting', // Accounting Module
    'users', // User Management
    'backup', // Backup & Restore
    'export', // Data Export
    'admin', // Administrator privileges
  ];

  // License types with user limits
  static const Map<String, Map<String, dynamic>> licenseTypes = {
    'basic': {
      'name': 'Basic',
      'max_users': 1,
      'features': ['pos', 'inventory', 'customers', 'reports', 'backup'],
      'price': 500,
    },
    'standard': {
      'name': 'Standard',
      'max_users': 3,
      'features': [
        'pos',
        'inventory',
        'customers',
        'suppliers',
        'reports',
        'backup',
        'export',
      ],
      'price': 1500,
    },
    'professional': {
      'name': 'Professional',
      'max_users': 5,
      'features': [
        'pos',
        'inventory',
        'customers',
        'suppliers',
        'reports',
        'accounting',
        'users',
        'backup',
        'export',
      ],
      'price': 3000,
    },
    'enterprise': {
      'name': 'Enterprise',
      'max_users': 10,
      'features': [
        'pos',
        'inventory',
        'customers',
        'suppliers',
        'reports',
        'accounting',
        'users',
        'backup',
        'export',
      ],
      'price': 7000,
    },
    'admin': {
      'name': 'Administrator',
      'max_users': 999,
      'features': [
        'pos',
        'inventory',
        'customers',
        'suppliers',
        'reports',
        'accounting',
        'users',
        'backup',
        'export',
        'admin',
      ],
      'price': 0, // Free for administrators
      'lifetime': true,
    },
  };

  // App version
  static const String appVersion = '2.0.0';
  static const String appName = 'Professional POS System';

  // Support contact
  static const String supportEmail = 'support@yourcompany.com';
  static const String supportPhone = '+20 XXX XXX XXXX';
}
