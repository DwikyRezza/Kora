import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../main.dart';
import '../../../../theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import 'landing_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimationComplete = true;
        _checkAndNavigate(context.read<AuthBloc>().state);
      }
    });

    context.read<AuthBloc>().add(AppStarted());
    _animController.forward();
  }

  void _checkAndNavigate(AuthState state) {
    if (_isAnimationComplete && mounted) {
      if (state.status == AuthStatus.loading || state.status == AuthStatus.initial) {
        return; // Masih loading
      }

      Widget nextScreen;
      if (state.status == AuthStatus.unauthenticated || state.status == AuthStatus.error) {
        nextScreen = const LandingScreen();
      } else if (state.status == AuthStatus.needsOnboarding) {
        nextScreen = const OnboardingScreen();
      } else {
        nextScreen = const MainNavigation();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode;
    final logoPath = isDark
        ? 'assets/icons/logo_splash_screen_dark_mode.png'
        : 'assets/icons/logo_splash_screen.png';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _checkAndNavigate(state);
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final currentScale = _scaleAnimation.value;

              return Transform.scale(
                scale: currentScale,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Image.asset(
                    logoPath,
                    width: 280,
                    height: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.sports_score_rounded,
                        size: 80,
                        color: AppTheme.accent,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
