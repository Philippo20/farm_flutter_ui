import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_background/animated_background.dart';
import 'package:lottie/lottie.dart';
import '../../constants/colors.dart';
// ignore: unused_import
import '../admin/admin_dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isDark;
  const OnboardingScreen({super.key, required this.isDark});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    // ignore: unused_local_variable
    final textColor = widget.isDark ? AppColors.darkText : AppColors.text;
    final cardBg = widget.isDark
        ? AppColors.darkCard.withOpacity(0.88)
        : Colors.white.withOpacity(0.92);

    final pageBg = widget.isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF151515), Color(0xFF1E293B)])
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4FFF4), Color(0xFFE0F2E9)]);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBackground(
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: primary.withOpacity(0.09),
                spawnMinRadius: 7,
                spawnMaxRadius: 16,
                particleCount: 18,
                minOpacity: 0.08,
                maxOpacity: 0.13,
                spawnMaxSpeed: 18,
                spawnMinSpeed: 7,
              ),
            ),
            vsync: this,
            child: Container(), // Layer
          ),
          Container(
            decoration: BoxDecoration(gradient: pageBg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Card height is at most 85% of available space or 520px, whichever is smaller
                double maxCardHeight = constraints.maxHeight * 0.85;
                if (maxCardHeight > 520) maxCardHeight = 520;

                // Image is max 32% of card, but no more than 150px
                double maxImgHeight = (maxCardHeight * 0.32).clamp(90.0, 150.0);

                return Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      maxHeight: maxCardHeight,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.14),
                          blurRadius: 32,
                          spreadRadius: 5,
                          offset: Offset(0, 9),
                        ),
                      ],
                      border: Border.all(
                        color: primary.withOpacity(0.10),
                        width: 1.2,
                      ),
                    ),
                    child: IntroductionScreen(
                      globalBackgroundColor: Colors.transparent,
                      pages: [
                        _proPage(
                          title: "Grow Smarter, Not Harder",
                          body: "AI-powered tools and beautiful dashboards help you achieve more from every square meter.",
                          asset: 'assets/onboarding/plant(2).json',
                          context: context,
                          isDark: widget.isDark,
                          maxImgHeight: maxImgHeight,
                        ),
                        _proPage(
                          title: "See Everything In Real Time",
                          body: "Sensors track every key metric. Our app sends instant alerts and keeps your operation in perfect balance.",
                          asset: 'assets/onboarding/sensor.json',
                          context: context,
                          isDark: widget.isDark,
                          maxImgHeight: maxImgHeight,
                        ),
                        _proPage(
                          title: "Harvest Data, Maximize Yield",
                          body: "Machine learning helps you plan and predict with confidence. Less waste, more harvest.",
                          asset: 'assets/onboarding/analytics.json',
                          context: context,
                          isDark: widget.isDark,
                          maxImgHeight: maxImgHeight,
                        ),
                      ],
                      onDone: () => Navigator.pushReplacementNamed(context, '/dashboard'), 
                      onSkip: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                      showSkipButton: true,
                      skip: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.poppins(
                            color: primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      next: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withOpacity(0.13),
                        ),
                        child: Icon(Icons.arrow_forward, color: primary),
                      ),
                      done: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: primary,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.26),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Text(
                          "Get Started",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      dotsDecorator: DotsDecorator(
                        activeColor: primary,
                        color: primary.withOpacity(0.16),
                        size: Size(8, 8),
                        activeSize: Size(24, 8),
                        activeShape: StadiumBorder(),
                        spacing: EdgeInsets.symmetric(horizontal: 4),
                      ),
                      curve: Curves.easeInOutCubic,
                      animationDuration: 700,
                      isProgressTap: false,
                      isProgress: true,
                      freeze: false,
                      nextFlex: 0,
                      dotsContainerDecorator: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PageViewModel _proPage({
    required String title,
    required String body,
    required String asset,
    required BuildContext context,
    required bool isDark,
    required double maxImgHeight,
  }) {
    final primary = AppColors.primary;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    return PageViewModel(
      titleWidget: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: primary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          body,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: textColor.withOpacity(0.92),
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      image: Container(
          height: MediaQuery.of(context).size.height * 0.28,
          margin: EdgeInsets.only(top: 12, bottom: 2),
          child: Lottie.asset(
            asset, 
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
          ),
        ),
      decoration: PageDecoration(
        contentMargin: const EdgeInsets.symmetric(horizontal: 32),
        imagePadding: const EdgeInsets.only(bottom: 16),
        titlePadding: EdgeInsets.zero,
        bodyPadding: const EdgeInsets.symmetric(horizontal: 16),
        boxDecoration: BoxDecoration(
          color: Colors.transparent,
        ),
      ),
    );
  }
}
