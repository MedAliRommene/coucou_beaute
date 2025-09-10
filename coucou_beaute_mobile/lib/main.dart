import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'screens/pro_dashboard_screen.dart';
import 'screens/client_dashboard_screen.dart';

void main() {
  runApp(const CoucouBeauteApp());
}

class CoucouBeauteApp extends StatelessWidget {
  const CoucouBeauteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadFromStorage(),
      child: MaterialApp(
        title: 'COUCOU BEAUTÉ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, _) {
      Widget child;
      if (auth.accessToken != null && auth.me != null) {
        final role = auth.role;
        if (role == 'professional') {
          child = const ProDashboardScreen();
        } else if (role == 'client') {
          child = const ClientDashboardScreen();
        } else {
          child = const OnboardingScreen();
        }
      } else {
        child = const OnboardingScreen();
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (w, anim) {
          final offset = Tween<Offset>(
                  begin: const Offset(0.05, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: offset, child: w),
          );
        },
        child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
      );
    });
  }
}
