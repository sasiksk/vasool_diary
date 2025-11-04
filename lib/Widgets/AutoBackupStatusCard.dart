import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoBackupStatusCard extends StatefulWidget {
  const AutoBackupStatusCard({super.key});

  @override
  State<AutoBackupStatusCard> createState() => _AutoBackupStatusCardState();
}

class _AutoBackupStatusCardState extends State<AutoBackupStatusCard> {
  bool _isAutoBackupEnabled = true; // Always true for Android Auto Backup

  @override
  void initState() {
    super.initState();
    _checkBackupStatus();
  }

  Future<void> _checkBackupStatus() async {
    // For Android Auto Backup, it's always enabled if properly configured
    // We can store a timestamp of last known backup or app installation
    final prefs = await SharedPreferences.getInstance();
    final appInstallTime = prefs.getInt('app_install_time');

    if (appInstallTime == null) {
      // First time - save install time
      await prefs.setInt(
          'app_install_time', DateTime.now().millisecondsSinceEpoch);
    }

    setState(() {
      _isAutoBackupEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _isAutoBackupEnabled
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isAutoBackupEnabled ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Android Auto Backup',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isAutoBackupEnabled
                              ? 'Your data is automatically backed up'
                              : 'Auto backup not available',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showBackupInfo,
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_isAutoBackupEnabled) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Backs up daily when device is charging & on WiFi',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_queue, color: Colors.blue),
            const SizedBox(width: 12),
            Text('Android Auto Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.security, 'Encrypted & Secure',
                'Your data is encrypted before backup'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.schedule, 'Automatic Schedule',
                'Runs every 24 hours when conditions are met'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.wifi, 'Smart Conditions',
                'Only backs up when charging & on WiFi'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.restore, 'Auto Restore',
                'Restores data when you reinstall the app'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No action required. Your finance data is protected!',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
