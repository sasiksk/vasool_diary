import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key});

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  bool _isChanging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isChanging
          ? null
          : () async {
              setState(() {
                _isChanging = true;
              });

              try {
                // Toggle between Tamil and English
                if (context.locale.languageCode == 'ta') {
                  await context.setLocale(const Locale('en'));
                } else {
                  await context.setLocale(const Locale('ta'));
                }

                // Wait a bit for the change to take effect
                await Future.delayed(const Duration(milliseconds: 100));

                if (mounted) {
                  // Show feedback in the new language
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.locale.languageCode == 'ta'
                          ? 'மொழி தமிழுக்கு மாற்றப்பட்டது'
                          : 'Language changed to English'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isChanging = false;
                  });
                }
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_isChanging ? 0.1 : 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isChanging
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 18,
                  ),
            const SizedBox(width: 6),
            Text(
              _isChanging
                  ? '...'
                  : (context.locale.languageCode == 'ta' ? 'தமிழ்' : 'English'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
