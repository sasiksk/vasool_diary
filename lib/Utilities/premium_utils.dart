import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Services/premium_service.dart';
import '../Screens/premium_screen.dart';

class PremiumUtils {
  /// Check premium status and show appropriate dialogs
  /// Returns true if operation should continue, false if blocked
  static Future<bool> checkPremiumForOperation(
    BuildContext context, {
    required String operationName,
  }) async {
    final premiumService = PremiumService();
    await premiumService.refreshStatus();

    // If user has premium access, allow operation
    if (premiumService.hasPremiumAccess) {
      // Check if expiring soon (5 days or less)
      final remainingDays = premiumService.remainingDays;

      if (remainingDays <= 5 && remainingDays > 0) {
        _showExpiryWarning(context, remainingDays, operationName);
        return true; // Allow operation but show warning
      }

      return true; // Allow operation
    }

    // Premium expired - block operation
    _showPremiumExpiredDialog(context, operationName);
    return false;
  }

  /// Show warning when premium is expiring soon (5 days or less)
  static void _showExpiryWarning(
      BuildContext context, int remainingDays, String operationName) {
    String message;
    Color warningColor;
    IconData warningIcon;

    if (remainingDays == 1) {
      message = "⚠️ Your premium access expires in 1 day!";
      warningColor = Colors.red;
      warningIcon = Icons.warning;
    } else if (remainingDays == 2) {
      message = "⚠️ Your premium access expires in 2 days!";
      warningColor = Colors.orange;
      warningIcon = Icons.warning;
    } else {
      message = "⚠️ Your premium access expires in $remainingDays days!";
      warningColor = Colors.orange;
      warningIcon = Icons.info;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(warningIcon, color: warningColor, size: 28),
              const SizedBox(width: 8),
              Text(
                'Premium Expiring',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: warningColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Consider renewing your premium subscription to continue enjoying all features without interruption.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Continue $operationName',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPremiumScreen(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Renew Premium',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog when premium has expired - blocks operation
  static void _showPremiumExpiredDialog(
      BuildContext context, String operationName) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text(
                'Premium Expired',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚫 Your premium access has expired!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To continue using "$operationName" feature, please upgrade to premium.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ Premium Features:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Unlimited bulk operations\n• Advanced SMS features\n• Priority support\n• No advertisements',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPremiumScreen(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upgrade to Premium',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to premium screen
  static void _navigateToPremiumScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    );
  }

  /// Quick method to show a simple snackbar for premium features
  static void showPremiumSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.star, color: Colors.yellow[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$feature is a premium feature. Upgrade to unlock!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Upgrade',
          textColor: Colors.yellow[700],
          onPressed: () => _navigateToPremiumScreen(context),
        ),
      ),
    );
  }

  /// Get premium status text for UI display
  static Future<String> getPremiumStatusText() async {
    final premiumService = PremiumService();
    await premiumService.refreshStatus();
    return premiumService.statusText;
  }

  /// Check if premium is expiring within specified days
  static Future<bool> isExpiringWithin(int days) async {
    final premiumService = PremiumService();
    await premiumService.refreshStatus();

    if (!premiumService.hasPremiumAccess) return false;

    return premiumService.remainingDays <= days;
  }

  /// Get remaining days for premium access
  static Future<int> getRemainingDays() async {
    final premiumService = PremiumService();
    await premiumService.refreshStatus();
    return premiumService.remainingDays;
  }
}
