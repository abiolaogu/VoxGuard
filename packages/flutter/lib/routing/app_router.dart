import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/anti_masking/presentation/pages/call_verification_page.dart';
import '../features/anti_masking/presentation/pages/masking_report_page.dart';
import '../features/remittance/presentation/pages/send_money_page.dart';
import '../features/remittance/presentation/pages/recipient_selection_page.dart';
import '../features/remittance/presentation/pages/transaction_status_page.dart';
import '../features/marketplace/presentation/pages/marketplace_home_page.dart';
import '../features/marketplace/presentation/pages/listing_detail_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/dashboard_page.dart';

part 'app_router.g.dart';

/// App router provider
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Watch auth state for redirects
  // final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    // Global redirect for authentication
    redirect: (context, state) {
      // final isLoggedIn = authState.valueOrNull?.isLoggedIn ?? false;
      // final isLoggingIn = state.matchedLocation == '/login';
      
      // if (!isLoggedIn && !isLoggingIn) {
      //   return '/login';
      // }
      // if (isLoggedIn && isLoggingIn) {
      //   return '/';
      // }
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
          
          // Anti-Masking routes
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
          
          // Remittance routes
          GoRoute(
            path: '/remittance',
            name: 'remittance',
            builder: (context, state) => const RemittancePage(),
            routes: [
              GoRoute(
                path: 'send',
                name: 'send-money',
                builder: (context, state) => const SendMoneyPage(),
              ),
              GoRoute(
                path: 'recipients',
                name: 'recipients',
                builder: (context, state) => const RecipientSelectionPage(),
              ),
              GoRoute(
                path: 'transaction/:id',
                name: 'transaction-status',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TransactionStatusPage(transactionId: id);
                },
              ),
            ],
          ),
          
          // Marketplace routes
          GoRoute(
            path: '/marketplace',
            name: 'marketplace',
            builder: (context, state) => const MarketplaceHomePage(),
            routes: [
              GoRoute(
                path: 'listing/:id',
                name: 'listing-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ListingDetailPage(listingId: id);
                },
              ),
              GoRoute(
                path: 'create',
                name: 'create-listing',
                builder: (context, state) => const CreateListingPage(),
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

/// Bottom navigation bar
class MainBottomNavigation extends ConsumerWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/anti-masking')) {
      currentIndex = 1;
    } else if (location.startsWith('/remittance')) {
      currentIndex = 2;
    } else if (location.startsWith('/marketplace')) {
      currentIndex = 3;
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
            context.go('/remittance');
            break;
          case 3:
            context.go('/marketplace');
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
          label: 'Security',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.send_outlined),
          activeIcon: Icon(Icons.send),
          label: 'Send',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'Market',
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

// Placeholder pages (to be implemented in features)
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

class RemittancePage extends StatelessWidget {
  const RemittancePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Remittance')));
}

class CreateListingPage extends StatelessWidget {
  const CreateListingPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Create Listing')));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Settings')));
}
