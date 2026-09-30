/// LONE LINK — Splash Screen
///
/// Initialization screen shown on app launch.
/// Checks for existing identity, initializes services,
/// then navigates to either identity setup or home.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lone_link/presentation/router.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)),
    );

    _animController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Give the animation time to play
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    // Check if identity exists
    try {
      final identityDao = ref.read(identityDaoProvider);
      final hasIdentity = await identityDao.hasIdentity();

      if (!mounted) return;

      if (hasIdentity) {
        // Load identity and go home
        final identity = await identityDao.getIdentity();
        if (identity != null && mounted) {
          ref.read(isSetupCompleteProvider.notifier).state = true;
          context.go(AppRoutes.conversations);
        }
      } else {
        // First launch — set up identity
        context.go(AppRoutes.identitySetup);
      }
    } catch (e) {
      // Database might not be generated yet — go to setup
      if (mounted) {
        context.go(AppRoutes.identitySetup);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoneLinkColors.darkBg,
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo / Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            LoneLinkColors.primary,
                            LoneLinkColors.primaryDark,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: LoneLinkColors.primary.withValues(alpha: 0.3 * _pulseAnim.value),
                            blurRadius: 30 + (10 * _pulseAnim.value),
                            spreadRadius: 5 * _pulseAnim.value,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.link,
                        size: 48,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App name
                    Text(
                      'LONE LINK',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: LoneLinkColors.darkTextPrimary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Opacity(
                      opacity: _pulseAnim.value,
                      child: Text(
                        'Decentralized Messaging',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: LoneLinkColors.darkTextTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Loading indicator
                    Opacity(
                      opacity: _pulseAnim.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            LoneLinkColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
