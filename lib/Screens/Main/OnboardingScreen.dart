import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kskfinance/Screens/Main/IntroductionDcreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  int _currentPage = 0;
  bool _isAnimating = false;
  String _selectedLanguage = 'en'; // Default to English

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      isLanguageSelection: true,
      title: "",
      description: "",
      icon: Icons.language,
      color: const Color(0xFF6366F1), // Premium indigo
      secondaryColor: const Color(0xFF8B5CF6), // Premium violet
    ),
    OnboardingSlide(
      title: "onboarding.slide1Title",
      description: "onboarding.slide1Description",
      icon: Icons.account_balance_wallet,
      color: const Color(0xFFDC2626), // Premium red
      secondaryColor: const Color(0xFFEA580C), // Premium orange
    ),
    OnboardingSlide(
      title: "onboarding.slide2Title",
      description: "onboarding.slide2Description",
      icon: Icons.people,
      color: const Color(0xFF7C3AED), // Premium purple
      secondaryColor: const Color(0xFFA855F7), // Premium fuchsia
    ),
    OnboardingSlide(
      title: "onboarding.slide3Title",
      description: "onboarding.slide3Description",
      icon: Icons.picture_as_pdf,
      color: const Color(0xFF0EA5E9), // Premium sky
      secondaryColor: const Color(0xFF3B82F6), // Premium blue
    ),
    OnboardingSlide(
      title: "onboarding.slide4Title",
      description: "onboarding.slide4Description",
      icon: Icons.sms,
      color: const Color(0xFFEAB308), // Premium amber
      secondaryColor: const Color(0xFFF59E0B), // Premium yellow
    ),
    OnboardingSlide(
      title: "onboarding.dataSafetyTitle",
      description: "onboarding.dataSafetyDescription",
      icon: Icons.security,
      color: const Color(0xFF059669), // Premium emerald
      secondaryColor: const Color(0xFF10B981), // Premium green
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _setDefaultLanguage();
  }

  void _initializeAnimations() {
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimationController.forward();
    _fadeAnimationController.forward();
  }

  void _setDefaultLanguage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        // Set English as default if no language is selected
        if (context.locale.languageCode.isEmpty) {
          context.setLocale(const Locale('en'));
          setState(() {
            _selectedLanguage = 'en';
          });
        } else {
          setState(() {
            _selectedLanguage = context.locale.languageCode;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_isAnimating) return;

    if (_currentPage < _slides.length - 1) {
      _isAnimating = true;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _isAnimating = false;
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _previousPage() async {
    if (_isAnimating || _currentPage == 0) return;

    _isAnimating = true;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _isAnimating = false;
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);
      await prefs.setInt(
          'onboardingDate', DateTime.now().millisecondsSinceEpoch);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const IntroductionScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      debugPrint('Onboarding completion error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroductionScreen()),
        );
      }
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _resetAndPlayAnimations();
  }

  void _resetAndPlayAnimations() {
    _slideAnimationController.reset();
    _fadeAnimationController.reset();
    _slideAnimationController.forward();
    _fadeAnimationController.forward();
  }

  void _selectLanguage(String code) {
    setState(() {
      _selectedLanguage = code;
    });
    context.setLocale(Locale(code));
    Future.delayed(const Duration(milliseconds: 300), _nextPage);
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: _buildGradient(currentSlide),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              if (_currentPage > 0) _buildProgressIndicator(),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _buildPageContent(_slides[index], index);
                  },
                ),
              ),

              // Bottom navigation
              _buildBottomNavigation(currentSlide),
            ],
          ),
        ),
      ),
    );
  }

  Gradient _buildGradient(OnboardingSlide slide) {
    return LinearGradient(
      colors: [
        slide.color,
        slide.secondaryColor,
        slide.secondaryColor.withOpacity(0.9),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.6, 1.0],
      tileMode: TileMode.clamp,
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_slides.length, (index) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: index <= _currentPage
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                boxShadow: index <= _currentPage
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPageContent(OnboardingSlide slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (slide.isLanguageSelection) ...[
            _buildLanguageSelection(),
          ] else ...[
            _buildIntroductionSlide(slide),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.language,
                size: 70,
                color: Colors.white.withOpacity(0.9),
              ),
            ),

            const SizedBox(height: 48),

            // Title
            Text(
              'onboarding.selectLanguage'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'onboarding.chooseLanguage'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Language buttons
            _buildLanguageButton(
              label: 'English',
              code: 'en',
              icon: Icons.language,
              isSelected: _selectedLanguage == 'en',
            ),

            const SizedBox(height: 16),

            _buildLanguageButton(
              label: 'தமிழ்',
              code: 'ta',
              icon: Icons.translate,
              isSelected: _selectedLanguage == 'ta',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton({
    required String label,
    required String code,
    required IconData icon,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _selectLanguage(code),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            width: double.infinity,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? _slides[_currentPage].color.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? _slides[_currentPage].color
                        : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? _slides[_currentPage].color
                        : Colors.grey[700],
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _slides[_currentPage].color,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionSlide(OnboardingSlide slide) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                slide.icon,
                size: 70,
                color: Colors.white.withOpacity(0.95),
              ),
            ),

            const SizedBox(height: 48),

            // Title with better typography
            Text(
              slide.title.tr(),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Description with improved readability
            Text(
              slide.description.tr(),
              style: GoogleFonts.poppins(
                fontSize: 17,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(OnboardingSlide currentSlide) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentPage > 0 && _currentPage < _slides.length - 1)
            _buildBackButton()
          else
            const SizedBox(width: 48),

          // Page indicators for introduction slides
          if (_currentPage > 0 && _currentPage < _slides.length - 1)
            _buildDotIndicators()
          else
            const Spacer(),

          // Next/Get Started button
          _buildNextButton(currentSlide),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      onPressed: _previousPage,
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back,
          color: Colors.white.withOpacity(0.9),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final slideIndex = index + 1;
        final isActive = _currentPage == slideIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNextButton(OnboardingSlide currentSlide) {
    final isLastPage = _currentPage == _slides.length - 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isLastPage ? 25 : 30),
          onTap: _nextPage,
          child: Container(
            padding: isLastPage
                ? const EdgeInsets.symmetric(horizontal: 32, vertical: 16)
                : const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isLastPage ? 25 : 30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLastPage ? 'onboarding.getStarted'.tr() : '',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: currentSlide.color,
                  ),
                ),
                if (!isLastPage)
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: currentSlide.color,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final bool isLanguageSelection;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.secondaryColor,
    this.isLanguageSelection = false,
  });
}
