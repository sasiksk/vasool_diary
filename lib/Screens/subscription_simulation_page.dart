import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/premium_service.dart';

class SubscriptionSimulationPage extends StatefulWidget {
  const SubscriptionSimulationPage({super.key});

  @override
  State<SubscriptionSimulationPage> createState() =>
      _SubscriptionSimulationPageState();
}

class _SubscriptionSimulationPageState
    extends State<SubscriptionSimulationPage> {
  final PremiumService _premiumService = PremiumService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    setState(() => _isLoading = true);
    await _premiumService.initialize();

    // Debug: Print current SharedPreferences values
    final prefs = await SharedPreferences.getInstance();
    print('=== Debug: Current SharedPreferences ===');
    print('first_launch_date: ${prefs.getString('first_launch_date')}');
    print('trial_start_date: ${prefs.getString('trial_start_date')}');
    print('premium_purchase_date: ${prefs.getString('premium_purchase_date')}');
    print('is_premium_user: ${prefs.getBool('is_premium_user')}');
    print('Current DateTime: ${DateTime.now()}');
    print('=========================================');

    setState(() => _isLoading = false);
  }

  Future<void> _simulateStartTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear existing data first
      await prefs.remove('first_launch_date');
      await prefs.remove('trial_start_date');
      await prefs.remove('premium_purchase_date');
      await prefs.remove('is_premium_user');

      // Reinitialize premium service to trigger trial
      await _premiumService.initialize();
      await _loadPremiumStatus();

      _showSnackBar('✅ Trial started successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error starting trial: $e', Colors.red);
    }
  }

  Future<void> _simulatePremiumPurchase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Set premium purchase data manually
      await prefs.setString('premium_purchase_date', now.toIso8601String());
      await prefs.setBool('is_premium_user', true);

      // Refresh premium service
      await _premiumService.refreshStatus();
      await _loadPremiumStatus();

      _showSnackBar('✅ Premium activated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error activating premium: $e', Colors.red);
    }
  }

  Future<void> _simulateExpiredTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldDate = DateTime.now()
          .subtract(const Duration(days: 95)); // 90 days + 5 for expired

      // Clear premium data first
      await prefs.remove('premium_purchase_date');
      await prefs.remove('is_premium_user');

      // Set trial as started 95 days ago (so it's expired now)
      await prefs.setString('first_launch_date', oldDate.toIso8601String());
      await prefs.setString('trial_start_date', oldDate.toIso8601String());

      // Refresh premium service
      await _premiumService.refreshStatus();
      await _loadPremiumStatus();

      _showSnackBar('⏰ Trial expired simulation complete!', Colors.orange);
    } catch (e) {
      _showSnackBar('❌ Error simulating expired trial: $e', Colors.red);
    }
  }

  Future<void> _simulateExpiredPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldDate = DateTime.now().subtract(const Duration(days: 35));

      // Clear trial data first
      await prefs.remove('first_launch_date');
      await prefs.remove('trial_start_date');

      // Set premium as purchased 35 days ago (so it's expired now)
      await prefs.setString('premium_purchase_date', oldDate.toIso8601String());
      await prefs.setBool('is_premium_user', true);

      // Refresh premium service
      await _premiumService.refreshStatus();
      await _loadPremiumStatus();

      _showSnackBar('⏰ Premium expired simulation complete!', Colors.orange);
    } catch (e) {
      _showSnackBar('❌ Error simulating expired premium: $e', Colors.red);
    }
  }

  Future<void> _simulateExpiringSoon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentDate = DateTime.now()
          .subtract(const Duration(days: 88)); // 2 days left in 90-day trial

      // Clear premium data first
      await prefs.remove('premium_purchase_date');
      await prefs.remove('is_premium_user');

      // Set trial as started 88 days ago (2 days left in 90-day trial)
      await prefs.setString('first_launch_date', recentDate.toIso8601String());
      await prefs.setString('trial_start_date', recentDate.toIso8601String());

      // Refresh premium service
      await _premiumService.refreshStatus();
      await _loadPremiumStatus();

      _showSnackBar(
          '⚠️ Trial expiring soon simulation complete!', Colors.orange);
    } catch (e) {
      _showSnackBar('❌ Error simulating expiring trial: $e', Colors.red);
    }
  }

  Future<void> _clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all premium-related data
      await prefs.remove('first_launch_date');
      await prefs.remove('trial_start_date');
      await prefs.remove('premium_purchase_date');
      await prefs.remove('is_premium_user');

      // Refresh premium service
      await _premiumService.refreshStatus();
      await _loadPremiumStatus();

      _showSnackBar('🗑️ All premium data cleared!', Colors.blue);
    } catch (e) {
      _showSnackBar('❌ Error clearing data: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Premium Simulation',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStatusCard(),
                  const SizedBox(height: 24),
                  _buildSimulationOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStatusCard() {
    Color statusColor =
        _premiumService.hasPremiumAccess ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _premiumService.hasPremiumAccess ? Icons.verified : Icons.schedule,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Current Status',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _premiumService.statusText,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (_premiumService.getDateRangeText().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _premiumService.getDateRangeText(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Access: ${_premiumService.hasPremiumAccess ? "YES" : "NO"} | Days: ${_premiumService.remainingDays}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulation Options',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Test different premium states by simulating various scenarios:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),
        _buildSimulationButton(
          'Start New Trial',
          'Simulate first-time user with fresh 90-day trial',
          Icons.play_circle_outline,
          Colors.blue,
          _simulateStartTrial,
        ),
        const SizedBox(height: 12),
        _buildSimulationButton(
          'Activate Premium',
          'Simulate successful premium purchase (30 days)',
          Icons.star,
          Colors.green,
          _simulatePremiumPurchase,
        ),
        const SizedBox(height: 12),
        _buildSimulationButton(
          'Trial Expiring Soon',
          'Simulate trial with only 2 days remaining (88 days completed)',
          Icons.timer,
          Colors.orange,
          _simulateExpiringSoon,
        ),
        const SizedBox(height: 12),
        _buildSimulationButton(
          'Expired Trial',
          'Simulate trial that expired 5 days ago',
          Icons.timer_off,
          Colors.red,
          _simulateExpiredTrial,
        ),
        const SizedBox(height: 12),
        _buildSimulationButton(
          'Expired Premium',
          'Simulate premium that expired 5 days ago',
          Icons.star_border,
          Colors.red,
          _simulateExpiredPremium,
        ),
        const SizedBox(height: 12),
        _buildSimulationButton(
          'Clear All Data',
          'Reset all premium data (like fresh install)',
          Icons.clear_all,
          Colors.grey,
          _clearAllData,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'How to Test:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Use simulation buttons to test different states\n'
                '2. Go to Premium Screen to see UI changes\n'
                '3. Check drawer navigation for status updates\n'
                '4. Test purchase button functionality\n'
                '5. Use "Clear All Data" to reset for fresh testing',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
