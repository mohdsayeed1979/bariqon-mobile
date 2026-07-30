import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_sizes.dart';
import '../core/widgets/brand_logo.dart';

/// Brief branded splash shown after the native launch screen (see
/// flutter_native_splash config in pubspec.yaml) and before the app shell
/// — a simple, premium fade-in on the logo, then an automatic hand-off to
/// the Home tab. No bootstrap/session logic lives here; that already
/// happened in app/bootstrap.dart before this widget is even built.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _fadeDuration = AppMotion.splashFade;
  static const _holdDuration = AppMotion.splashHold;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _fadeDuration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(_fadeDuration + _holdDuration, () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: const BrandLogo(size: BrandLogoSize.large, padding: EdgeInsets.zero),
        ),
      ),
    );
  }
}
