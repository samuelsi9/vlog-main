import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _primary = Color(0xFF7B1919);
const Color _textDark = Color(0xFF2D3436);
const Color _textGrey = Color(0xFF636E72);

const String _keyHomeTourSeen = 'home_tour_seen';

/// First-time tour that explains each tab and the cart. Shown once when user reaches the main screen.
class HomeTourOverlay {
  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHomeTourSeen) ?? false;
  }

  static Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHomeTourSeen, true);
  }

  static const List<({IconData icon, String name, String action})> steps = [
    (icon: Icons.home_rounded, name: 'Home', action: 'Browse products and see the cart icon in the top bar'),
    (icon: Icons.search_rounded, name: 'Search', action: 'Find items by name or category'),
    (icon: Icons.favorite_border_rounded, name: 'Wishlist', action: 'View and manage your saved items'),
    (icon: Icons.help_outline_rounded, name: 'Support', action: 'Get help and read the FAQ'),
    (icon: Icons.person_outline_rounded, name: 'Profile', action: 'Manage your account and orders'),
    (icon: Icons.shopping_cart_outlined, name: 'Cart', action: 'Tap the cart icon on the Home screen to see your basket'),
  ];
}

/// Full-screen overlay with step-by-step tutorial. Use [show] to present it.
void showHomeTour(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _HomeTourSheet(),
  );
}

class _HomeTourSheet extends StatefulWidget {
  @override
  State<_HomeTourSheet> createState() => _HomeTourSheetState();
}

class _HomeTourSheetState extends State<_HomeTourSheet> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < HomeTourOverlay.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
    } else {
      HomeTourOverlay.markTourSeen();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = HomeTourOverlay.steps[_currentStep];
    final isLast = _currentStep == HomeTourOverlay.steps.length - 1;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Quick tour',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_currentStep + 1} of ${HomeTourOverlay.steps.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Current step content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Row(
                      key: ValueKey(_currentStep),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(step.icon, color: _primary, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.action,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _textGrey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      HomeTourOverlay.steps.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentStep == i ? 20 : 6,
                        decoration: BoxDecoration(
                          color: _currentStep == i
                              ? _primary
                              : _primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Got it' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
