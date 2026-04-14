import 'dart:async';
import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'login_form_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int currentIndex = 0;

  final List<OnboardingData> pages = const [
    OnboardingData(
      title: 'Own your streets.',
      backgroundImage: 'assets/onboarding/bg1.jpg',
      floatingImage: 'assets/onboarding/float1.jpg',
    ),
    OnboardingData(
      title: 'Close loops that never run out.',
      backgroundImage: 'assets/onboarding/bg2.jpg',
      floatingImage: 'assets/onboarding/float2.jpg',
    ),
    OnboardingData(
      title: 'Get motivation from your people.',
      backgroundImage: 'assets/onboarding/bg3.jpg',
      floatingImage: 'assets/onboarding/float3.jpg',
    ),
    OnboardingData(
      title: 'Run your world.',
      backgroundImage: 'assets/onboarding/bg4.jpg',
      floatingImage: 'assets/onboarding/float4.jpg',
    ),
  ];

  static const accentColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!_pageController.hasClients) return;

      final nextIndex = (currentIndex + 1) % pages.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _goToApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget buildBrandLogo() {
    return Transform(
      transform: Matrix4.skewX(-0.18),
      alignment: Alignment.center,
      child: const Text(
        'TERRARUN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height - media.padding.top;
    final topSectionHeight = screenHeight * 0.58;

    final cardTop = topSectionHeight * 0.40;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipRect(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final item = pages[index];

                return Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: topSectionHeight,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                item.backgroundImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF0F0E47),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.backgroundImage,
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.12),
                                      Colors.black.withOpacity(0.12),
                                      Colors.black.withOpacity(0.32),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: SafeArea(
                                  bottom: false,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 18),
                                    child: Center(
                                      child: buildBrandLogo(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.black,
                            padding: const EdgeInsets.fromLTRB(28, 110, 28, 18),
                            child: Column(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: Text(
                                    item.title,
                                    key: ValueKey(item.title),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      height: 1.18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    pages.length,
                                    (dotIndex) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 260),
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: currentIndex == dotIndex
                                            ? accentColor
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: cardTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.97,
                                  end: 1.0,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _FloatingPreviewCard(
                            key: ValueKey(item.floatingImage),
                            imagePath: item.floatingImage,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: media.size.width * 0.88,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SignupPage(),
    ),
  );
},
                        child: const Text('Join for free'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginFormPage(),
    ),
  );
},
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String backgroundImage;
  final String floatingImage;

  const OnboardingData({
    required this.title,
    required this.backgroundImage,
    required this.floatingImage,
  });
}

class _FloatingPreviewCard extends StatelessWidget {
  final String imagePath;

  const _FloatingPreviewCard({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 0.56,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
alignment: Alignment.centerLeft,

              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Text(
                    imagePath,
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}