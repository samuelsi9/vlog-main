import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _red = Color(0xFFE53E3E);
const Color _redLight = Color(0xFFFDE8E8);
const Color _white = Colors.white;
const String _appName = 'Koliago';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  static const String _keyOnboardingSeen = 'onboarding_seen';

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Welcome to $_appName',
      subtitle: '$_appName is your grocery delivery app. We help you buy and deliver to your home.',
      icon: Icons.shopping_basket_rounded,
    ),
    _OnboardingSlide(
      title: 'We help you buy\nand deliver to your home',
      subtitle: 'Groceries from your favourite supermarkets, brought to your door.',
      icon: Icons.local_shipping_rounded,
    ),
    _OnboardingSlide(
      title: 'Fresh & convenient',
      subtitle: 'Order what you need. $_appName picks, packs and delivers to you.',
      icon: Icons.storefront_rounded,
    ),
    _OnboardingSlide(
      title: 'Get started',
      subtitle: 'Sign in or create an account to start ordering with $_appName.',
      icon: Icons.rocket_launch_rounded,
    ),
  ];

  Future<void> _finish() async {
    await OnboardingPage.markOnboardingSeen();
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _appName,
                    style: const TextStyle(
                      color: _red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _SlideWidget(slide: _slides[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? _red : _red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: _white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'Next' : 'Get started',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _SlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: _redLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _red.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              slide.icon,
              size: 72,
              color: _red,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
