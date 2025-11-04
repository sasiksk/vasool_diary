import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PurchaseService.dart';

class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  // Keys for SharedPreferences
  static const String _firstLaunchKey = 'first_launch_date';
  static const String _trialStartDateKey = 'trial_start_date';
  static const String _premiumPurchaseDateKey = 'premium_purchase_date';
  static const String _premiumStatusKey = 'is_premium_user';
  static const String _hasPremiumKey = 'hasPremium'; // Used by PurchaseService

  bool _isPremium = false;
  bool _isTrialActive = false;
  DateTime? _trialStartDate;
  DateTime? _trialEndDate;
  DateTime? _premiumStartDate;
  DateTime? _premiumEndDate;

  // Purchase service instance
  final PurchaseService _purchaseService = PurchaseService();

  // Getters
  bool get isPremium => _isPremium;
  bool get isTrialActive => _isTrialActive;
  bool get hasPremiumAccess => _isPremium || _isTrialActive;
  DateTime? get trialStartDate => _trialStartDate;
  DateTime? get trialEndDate => _trialEndDate;
  DateTime? get premiumStartDate => _premiumStartDate;
  DateTime? get premiumEndDate => _premiumEndDate;

  int get remainingDays {
    if (_isPremium && _premiumEndDate != null) {
      final now = DateTime.now();
      final difference = _premiumEndDate!.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } else if (_isTrialActive && _trialEndDate != null) {
      final now = DateTime.now();
      final difference = _trialEndDate!.difference(now).inDays;
      return difference > 0 ? difference : 0;
    }
    return 0;
  }

  String get statusText {
    if (_isPremium) {
      return 'Premium Active (${remainingDays} days left)';
    } else if (_isTrialActive) {
      return 'Free Trial (${remainingDays} days left)';
    } else if (_premiumEndDate != null) {
      // Had premium but it's expired
      final expiredDays = DateTime.now().difference(_premiumEndDate!).inDays;
      return 'Premium Expired (${expiredDays} days ago)';
    } else if (_trialEndDate != null) {
      // Had trial but it's expired
      final expiredDays = DateTime.now().difference(_trialEndDate!).inDays;
      return 'Trial Expired (${expiredDays} days ago)';
    } else {
      return 'No Active Subscription';
    }
  }

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Initialize purchase service first
      await _purchaseService.initialize();
      if (kDebugMode) {
        print('PurchaseService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize PurchaseService: $e');
      }
    }

    await _loadPremiumStatus();
    notifyListeners();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Check if this is first app launch
    final firstLaunchString = prefs.getString(_firstLaunchKey);
    if (firstLaunchString == null) {
      // First launch - start 30-day free trial
      await _startFreeTrial();
      return;
    }

    // First check for Google Play purchases (higher priority)
    final hasGooglePlayPremium = prefs.getBool(_hasPremiumKey) ?? false;
    final googlePlayActivatedDate = prefs.getString('premiumActivatedDate');

    if (hasGooglePlayPremium && googlePlayActivatedDate != null) {
      // User has an active Google Play purchase
      _premiumStartDate = DateTime.parse(googlePlayActivatedDate);
      _premiumEndDate = _premiumStartDate!.add(const Duration(days: 30));

      if (now.isBefore(_premiumEndDate!)) {
        _isPremium = true;
        _isTrialActive = false; // Google Play premium overrides everything

        if (kDebugMode) {
          print('Google Play Premium Active until: $_premiumEndDate');
        }
        return;
      } else {
        // Google Play premium expired
        _isPremium = false;
      }
    }

    // Load existing trial data
    final trialStartString = prefs.getString(_trialStartDateKey);
    if (trialStartString != null) {
      _trialStartDate = DateTime.parse(trialStartString);
      _trialEndDate = _trialStartDate!.add(const Duration(days: 90));

      if (now.isBefore(_trialEndDate!)) {
        _isTrialActive = true;
      } else {
        _isTrialActive = false;
      }
    }

    // Load premium purchase data (simulation/legacy)
    final premiumPurchaseString = prefs.getString(_premiumPurchaseDateKey);
    final isPremiumUser = prefs.getBool(_premiumStatusKey) ?? false;

    if (premiumPurchaseString != null &&
        isPremiumUser &&
        !hasGooglePlayPremium) {
      // Only use simulation premium if no Google Play premium exists
      _premiumStartDate = DateTime.parse(premiumPurchaseString);
      _premiumEndDate = _premiumStartDate!.add(const Duration(days: 30));

      if (now.isBefore(_premiumEndDate!)) {
        _isPremium = true;
        _isTrialActive = false; // Premium overrides trial
      } else {
        _isPremium = false;
        // Don't clear expired premium data for simulation purposes
        // Keep the dates for display in UI
      }
    }

    if (kDebugMode) {
      print('Premium Status Loaded:');
      print('  Google Play Premium: $hasGooglePlayPremium');
      print('  Trial Active: $_isTrialActive');
      print('  Premium Active: $_isPremium');
      print('  Trial End: $_trialEndDate');
      print('  Premium End: $_premiumEndDate');
      print('  Has Access: $hasPremiumAccess');
      print('  Remaining Days: $remainingDays');
    }
  }

  Future<void> _startFreeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Set first launch date
    await prefs.setString(_firstLaunchKey, now.toIso8601String());

    // Start 90-day free trial
    await prefs.setString(_trialStartDateKey, now.toIso8601String());
    _trialStartDate = now;
    _trialEndDate = now.add(const Duration(days: 90));
    _isTrialActive = true;

    if (kDebugMode) {
      print('Free trial started! Trial ends on: $_trialEndDate');
    }
  }

  // Purchase premium using Google Play Store
  Future<bool> purchasePremium() async {
    try {
      if (kDebugMode) {
        print('Initiating Google Play purchase...');
      }

      // Use PurchaseService for real Google Play purchase
      final success = await _purchaseService.purchasePremium();

      if (success) {
        // Purchase initiated successfully
        // The actual activation will happen in PurchaseService
        // when the purchase completes via the purchase stream
        if (kDebugMode) {
          print('Google Play purchase initiated successfully');
        }

        // Refresh status after a short delay to pick up any changes
        Future.delayed(const Duration(seconds: 2), () {
          refreshStatus();
        });

        return true;
      } else {
        if (kDebugMode) {
          print('Google Play purchase failed to initiate');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Purchase error: $e');
      }
      return false;
    }
  }

  // Simulate premium purchase (for testing only)
  Future<bool> simulatePremiumPurchase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Set premium purchase data
      await prefs.setString(_premiumPurchaseDateKey, now.toIso8601String());
      await prefs.setBool(_premiumStatusKey, true);

      // Update local state
      _premiumStartDate = now;
      _premiumEndDate = now.add(const Duration(days: 30));
      _isPremium = true;
      _isTrialActive = false; // Premium overrides trial

      notifyListeners();

      if (kDebugMode) {
        print('Premium simulated! Premium ends on: $_premiumEndDate');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Simulation error: $e');
      }
      return false;
    }
  }

  // Refresh the status (useful for UI updates)
  Future<void> refreshStatus() async {
    await _loadPremiumStatus();
    notifyListeners();
  }

  // Check if trial/premium is expiring soon (last 3 days)
  bool get isExpiringSoon {
    final days = remainingDays;
    return days <= 3 && days > 0;
  }

  // Format date for display
  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get date range text for UI
  String getDateRangeText() {
    if (_isPremium && _premiumStartDate != null && _premiumEndDate != null) {
      return 'Premium: ${formatDate(_premiumStartDate)} to ${formatDate(_premiumEndDate)}';
    } else if (_isTrialActive &&
        _trialStartDate != null &&
        _trialEndDate != null) {
      return 'Trial: ${formatDate(_trialStartDate)} to ${formatDate(_trialEndDate)}';
    } else if (_premiumStartDate != null && _premiumEndDate != null) {
      // Show expired premium dates
      return 'Premium (Expired): ${formatDate(_premiumStartDate)} to ${formatDate(_premiumEndDate)}';
    } else if (_trialStartDate != null && _trialEndDate != null) {
      // Show expired trial dates
      return 'Trial (Expired): ${formatDate(_trialStartDate)} to ${formatDate(_trialEndDate)}';
    }
    return '';
  }

  // Restore Google Play purchases
  Future<bool> restorePurchases() async {
    try {
      if (kDebugMode) {
        print('Restoring Google Play purchases...');
      }

      final success = await _purchaseService.restorePurchases();

      if (success) {
        // Refresh status to pick up restored purchases
        await refreshStatus();
        if (kDebugMode) {
          print('Purchases restored and status refreshed');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Restore purchases error: $e');
      }
      return false;
    }
  }

  // Check if Google Play purchase is pending
  bool get isPurchasePending => _purchaseService.purchasePending;

  // Check if Google Play is available
  bool get isGooglePlayAvailable => _purchaseService.isAvailable;

  // Get premium product price from Google Play
  String get premiumPrice => _purchaseService.getPremiumPrice();

  // Get purchase service error message
  String? get purchaseError => _purchaseService.queryProductError;

  // Dispose resources
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}
