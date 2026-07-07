import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../theme/app_theme.dart';
import '../../../../main.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/landing/landing_bloc.dart';
import '../../bloc/landing/landing_event.dart';
import '../../bloc/landing/landing_state.dart';
import 'onboarding_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LandingBloc>(
      create: (context) => LandingBloc(),
      child: BlocConsumer<LandingBloc, LandingState>(
        listener: (context, state) {
          if (state.status == LandingStatus.failureLogin) {
            _showSnackbar(
              state.errorMessage ?? 'Gagal login',
              AppTheme.accentOrange,
              icon: Icons.person_add_alt_1_rounded,
            );
          } else if (state.status == LandingStatus.failureRegister) {
            _showSnackbar(
              state.errorMessage ?? 'Gagal register',
              AppTheme.electricBlue,
              icon: Icons.login_rounded,
            );
          } else if (state.status == LandingStatus.successLogin) {
            // Signal AuthBloc that user is logged in
            context.read<AuthBloc>().add(AuthLoggedIn());
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigation()),
            );
          } else if (state.status == LandingStatus.successRegister) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        },
        builder: (context, state) {
          final isLoadingLogin = state.status == LandingStatus.loadingLogin;
          final isLoadingRegister = state.status == LandingStatus.loadingRegister;
          final isAnyLoading = isLoadingLogin || isLoadingRegister;

          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ScrollConfiguration(
                    behavior: const _GlowScrollBehavior(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 32),
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(26),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accent.withOpacity(0.15),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(26),
                                        child: Image.asset('assets/icons/logo.png', fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Capai Target ',
                                            style: TextStyle(
                                              color: AppTheme.accent,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              height: 1.2,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'bersama Kora',
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Asisten Digital untuk Atlet\nLacak latihan, nutrisi, dan jadwalmu',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: isAnyLoading
                                            ? null
                                            : () => context.read<LandingBloc>().add(RegisterSubmitted()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(26),
                                          ),
                                        ),
                                        child: isLoadingRegister
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  _GoogleGIcon(),
                                                  const SizedBox(width: 16),
                                                  const Text(
                                                    'Daftar dengan Google',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: OutlinedButton(
                                        onPressed: isAnyLoading
                                            ? null
                                            : () => context.read<LandingBloc>().add(LoginSubmitted()),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppTheme.surfaceVariant,
                                          foregroundColor: AppTheme.textPrimary,
                                          elevation: 0,
                                          side: BorderSide.none,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(26),
                                          ),
                                        ),
                                        child: isLoadingLogin
                                            ? SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2.5),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  _GoogleGIcon(),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    'Masuk dengan Google',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Dengan mendaftar, Anda menyetujui\nKetentuan Layanan & Kebijakan Privasi',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/google_logo.svg',
      width: 22,
      height: 22,
    );
  }
}

class _GlowScrollBehavior extends ScrollBehavior {
  const _GlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: AppTheme.accent.withOpacity(0.3),
      child: child,
    );
  }
}
