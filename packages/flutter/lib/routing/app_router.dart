import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/anti_masking/presentation/pages/call_verification_page.dart';
import '../features/anti_masking/presentation/pages/masking_report_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/dashboard_page.dart';

part 'app_router.g.dart';

/// App router provider - Anti-Call Masking Only
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    // Global redirect for authentication
    redirect: (context, state) {
      return null;
    },
    
    // Error page
    errorBuilder: (context, state) => ErrorPage(error: state.error),
    
    routes: [
      // Login route
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      
      // Main app shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          
          // Anti-Masking routes (core feature)
          GoRoute(
            path: '/anti-masking',
            name: 'anti-masking',
            builder: (context, state) => const AntiMaskingPage(),
            routes: [
              GoRoute(
                path: 'verify',
                name: 'verify-call',
                builder: (context, state) => const CallVerificationPage(),
              ),
              GoRoute(
                path: 'report',
                name: 'report-masking',
                builder: (context, state) => const MaskingReportPage(),
              ),
              GoRoute(
                path: 'history',
                name: 'verification-history',
                builder: (context, state) => const VerificationHistoryPage(),
              ),
            ],
          ),
          
          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

/// Main app shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

/// Bottom navigation bar - Anti-Masking focused
class MainBottomNavigation extends ConsumerWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/anti-masking')) {
      currentIndex = 1;
    } else if (location.startsWith('/settings')) {
      currentIndex = 2;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/anti-masking');
            break;
          case 2:
            context.go('/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.security_outlined),
          activeIcon: Icon(Icons.security),
          label: 'Verify',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

/// Error page
class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder pages
class AntiMaskingPage extends StatelessWidget {
  const AntiMaskingPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Anti-Masking')));
}

class VerificationHistoryPage extends StatelessWidget {
  const VerificationHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('History')));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Settings')));
}

