import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // Product IDs (must match Google Play Console)
  static const String premiumProductId = 'vasool_premium_basic';
  static const Set<String> _productIds = {premiumProductId};

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  List<ProductDetails> get products => _products;
  String? get queryProductError => _queryProductError;

  /// Initialize the purchase service
  Future<void> initialize() async {
    debugPrint('🛒 PurchaseService: Initializing...');

    try {
      // Check if in-app purchase is available
      _isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('🛒 InAppPurchase available: $_isAvailable');

      if (!_isAvailable) {
        debugPrint('❌ InAppPurchase not available on this device');
        return;
      }

      // Listen to purchase updates
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: () => debugPrint('🛒 Purchase stream closed'),
        onError: (error) => debugPrint('❌ Purchase stream error: $error'),
      );

      // Load products
      await _loadProducts();

      // Handle any pending transactions
      await _handlePendingTransactions();

      debugPrint('✅ PurchaseService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize PurchaseService: $e');
      _isAvailable = false;
    }
  }

  /// Load products from Google Play Store
  Future<void> _loadProducts() async {
    debugPrint('🛒 Loading products: $_productIds');

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_productIds);

      if (response.error != null) {
        _queryProductError = response.error!.message;
        debugPrint('❌ Error loading products: ${response.error!.message}');
        return;
      }

      if (response.productDetails.isEmpty) {
        _queryProductError =
            'No products found. Check product IDs in Google Play Console.';
        debugPrint('❌ No products found for IDs: $_productIds');
        return;
      }

      _products = response.productDetails;
      _queryProductError = null;

      debugPrint('✅ Loaded ${_products.length} products:');
      for (var product in _products) {
        debugPrint('   - ${product.id}: ${product.title} - ${product.price}');
      }
    } catch (e) {
      _queryProductError = 'Failed to load products: $e';
      debugPrint('❌ Exception loading products: $e');
    }
  }

  /// Handle pending transactions (important for app restart scenarios)
  Future<void> _handlePendingTransactions() async {
    debugPrint('🛒 Checking for pending transactions...');

    try {
      // Purchase stream is already set up in initialize()
      // Any pending transactions will be handled through the stream
      debugPrint('✅ Purchase stream listener ready for pending transactions');
    } catch (e) {
      debugPrint('❌ Exception handling pending transactions: $e');
    }
  }

  /// Purchase premium subscription
  Future<bool> purchasePremium() async {
    if (!_isAvailable) {
      debugPrint('❌ Purchase failed: InAppPurchase not available');
      return false;
    }

    final ProductDetails? productDetails = _products.firstWhere(
      (product) => product.id == premiumProductId,
      orElse: () => throw Exception('Premium product not found'),
    );

    if (productDetails == null) {
      debugPrint('❌ Premium product not found');
      return false;
    }

    try {
      _purchasePending = true;
      debugPrint('🛒 Starting purchase for: ${productDetails.id}');

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);
      final bool success =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        _purchasePending = false;
        debugPrint('❌ Purchase initiation failed');
        return false;
      }

      debugPrint('🔄 Purchase initiated, waiting for completion...');
      return true; // Actual result will come through purchase stream
    } catch (e) {
      _purchasePending = false;
      debugPrint('❌ Purchase exception: $e');
      return false;
    }
  }

  /// Handle purchase updates from the stream
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint(
        '🛒 Purchase update received: ${purchaseDetailsList.length} purchases');

    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint(
          '🔄 Processing purchase: ${purchaseDetails.productID} - ${purchaseDetails.status}');
      _handlePurchase(purchaseDetails);
    }
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      debugPrint('✅ Purchase successful: ${purchaseDetails.productID}');

      // Verify purchase and activate premium
      final bool valid = await _verifyPurchase(purchaseDetails);
      if (valid) {
        await _activatePremium(purchaseDetails);
        debugPrint('🎉 Premium activated successfully!');
      } else {
        debugPrint('❌ Purchase verification failed');
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint(
          '❌ Purchase error: ${purchaseDetails.error?.message ?? 'Unknown error'}');
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      debugPrint('❌ Purchase canceled by user');
    } else if (purchaseDetails.status == PurchaseStatus.pending) {
      debugPrint('🔄 Purchase pending...');
    }

    // Always complete the transaction
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
      debugPrint('✅ Purchase transaction completed');
    }

    _purchasePending = false;
  }

  /// Verify purchase (basic verification - enhance for production)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Basic verification
    if (purchaseDetails.productID != premiumProductId) {
      debugPrint('❌ Invalid product ID: ${purchaseDetails.productID}');
      return false;
    }

    // For production, implement server-side verification
    // For now, trust Google Play's verification
    debugPrint('✅ Purchase verification passed (basic)');
    return true;
  }

  /// Activate premium features
  Future<void> _activatePremium(PurchaseDetails purchaseDetails) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store purchase information
      await prefs.setBool('hasPremium', true);
      await prefs.setString(
          'premiumActivatedDate', DateTime.now().toIso8601String());
      await prefs.setString('purchaseId', purchaseDetails.purchaseID ?? '');
      await prefs.setString('productId', purchaseDetails.productID);

      // Clear trial information since user has purchased
      await prefs.remove('trialStartDate');

      debugPrint('✅ Premium activated and stored locally');
    } catch (e) {
      debugPrint('❌ Failed to activate premium: $e');
    }
  }

  /// Restore purchases (for users who reinstall the app)
  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('❌ Restore failed: InAppPurchase not available');
      return false;
    }

    try {
      debugPrint('🔄 Restoring purchases...');
      await _inAppPurchase.restorePurchases();
      debugPrint('✅ Restore purchases completed');
      return true;
    } catch (e) {
      debugPrint('❌ Restore purchases failed: $e');
      return false;
    }
  }

  /// Check if user has active premium subscription
  Future<bool> hasActivePremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPremium = prefs.getBool('hasPremium') ?? false;

      if (!hasPremium) return false;

      // For subscription products, you might want to verify with Google Play
      // For now, trust local storage
      debugPrint('📱 User has active premium: $hasPremium');
      return hasPremium;
    } catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Get premium product details
  ProductDetails? getPremiumProduct() {
    try {
      return _products.firstWhere((product) => product.id == premiumProductId);
    } catch (e) {
      debugPrint('❌ Premium product not found: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🛒 Disposing PurchaseService...');
    _subscription?.cancel();
    _subscription = null;
  }

  /// Get formatted price for premium product
  String getPremiumPrice() {
    final product = getPremiumProduct();
    return product?.price ?? '₹99'; // Fallback price
  }

  /// Check if the device supports in-app purchases
  static Future<bool> isSupported() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await InAppPurchase.instance.isAvailable();
    }
    return false;
  }
}
