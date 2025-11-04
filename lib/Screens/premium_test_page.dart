import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Services/premium_service.dart';

class PremiumTestPage extends StatefulWidget {
  const PremiumTestPage({super.key});

  @override
  State<PremiumTestPage> createState() => _PremiumTestPageState();
}

class _PremiumTestPageState extends State<PremiumTestPage> {
  final PremiumService _premiumService = PremiumService();
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    await _premiumService.initialize();
    setState(() {
      _debugInfo = '''
Current Status: ${_premiumService.statusText}
Has Premium Access: ${_premiumService.hasPremiumAccess}
Is Premium: ${_premiumService.isPremium}
Is Trial Active: ${_premiumService.isTrialActive}
Remaining Days: ${_premiumService.remainingDays}
Date Range: ${_premiumService.getDateRangeText()}
Trial Start: ${_premiumService.formatDate(_premiumService.trialStartDate)}
Trial End: ${_premiumService.formatDate(_premiumService.trialEndDate)}
Premium Start: ${_premiumService.formatDate(_premiumService.premiumStartDate)}
Premium End: ${_premiumService.formatDate(_premiumService.premiumEndDate)}
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Status Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Information:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _debugInfo,
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatus,
              child: Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
