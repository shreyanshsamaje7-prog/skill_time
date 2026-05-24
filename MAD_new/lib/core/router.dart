import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/login_screen.dart';
import '../main.dart'; // To access MainNavigation
import '../providers/auth_provider.dart';

import '../screens/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isOnboarding = state.uri.toString() == '/onboarding';

      if (authState.isLoading) return null;

      if (!isAuth && !isLoggingIn) return '/login';
      
      if (isAuth) {
        if (profileState.isLoading) return null;
        
        final profile = profileState.value;
        if (profile != null) {
          if (!profile.onboardingCompleted && !isOnboarding) {
            return '/onboarding';
          }
          if (profile.onboardingCompleted && (isLoggingIn || isOnboarding)) {
            return '/';
          }
        } else if (isLoggingIn) {
            // Profile is null but we are authenticated, wait for profile stream
            return null;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigation(),
      ),
    ],
  );
});
