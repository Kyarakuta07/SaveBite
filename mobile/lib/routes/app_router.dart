import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/colors.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/browse/presentation/screens/home_screen.dart';
import '../features/browse/presentation/screens/search_screen.dart';
import '../features/order/presentation/screens/orders_screen.dart';
import '../features/order/presentation/screens/order_detail_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/wallet/presentation/screens/wallet_screen.dart';
import '../features/address/presentation/screens/address_screen.dart';
import '../features/address/presentation/screens/address_form_screen.dart';
import '../features/address/presentation/screens/location_picker_screen.dart';
import '../features/social/presentation/screens/notification_screen.dart';
import '../features/order/presentation/screens/dispute_form_screen.dart';
import '../features/order/presentation/screens/checkout_screen.dart';
import '../features/browse/presentation/screens/food_item_detail_screen.dart';
import '../features/browse/presentation/screens/merchant_profile_screen.dart';
import '../features/social/presentation/screens/followed_stores_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../shared/models/food_item.dart';
import '../shared/models/user_address.dart';
import '../shared/services/notification_service.dart';

/// GoRouter provider with auth-based redirect.
///
/// Uses [StatefulShellRoute.indexedStack] per flutter-setup-declarative-routing
/// skill to preserve each tab branch's state across navigation switches.
///
/// [refreshListenable] bridges Riverpod → GoRouter: when authProvider changes
/// (login/logout), the router re-evaluates its redirect and navigates.
final routerProvider = Provider<GoRouter>((ref) {
  // Bridge: Riverpod StateNotifier → ChangeNotifier for GoRouter
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isOnAuth = state.uri.path == '/login' ||
          state.uri.path == '/register' ||
          state.uri.path == '/splash';

      if (authState is AuthInitial || authState is AuthLoading) {
        return state.uri.path == '/splash' ? null : '/splash';
      }
      if (authState is Unauthenticated) {
        return isOnAuth ? null : '/login';
      }
      if (authState is Authenticated && isOnAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // StatefulShellRoute — 4 tabs per stitch PRD design.
      // Each branch maintains independent navigation state via indexedStack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home (Browse)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Tab 2: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id'] ?? '0');
                      return OrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes (push, not tab switch)
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: '/addresses/add',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/addresses/edit',
        builder: (context, state) {
          final addr = state.extra as UserAddress?;
          return AddressFormScreen(existing: addr);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/dispute/:orderId',
        builder: (context, state) {
          final orderId =
              int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
          return DisputeFormScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/food-items/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return FoodItemDetailScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final item = state.extra as FoodItem;
          return CheckoutScreen(item: item);
        },
      ),
      GoRoute(
        path: '/merchants/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return MerchantProfileScreen(merchantId: id);
        },
      ),
      GoRoute(
        path: '/follows',
        builder: (context, state) => const FollowedStoresScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/location-picker',
        builder: (context, state) {
          final coords = state.extra as Map<String, double>?;
          return LocationPickerScreen(
            initialLat: coords?['lat'],
            initialLng: coords?['lng'],
          );
        },
      ),
    ],
  );
});

// ─── Main Shell (StatefulNavigationShell — 4 tabs per design) ──

/// Consumes [StatefulNavigationShell] to handle branch switching
/// while preserving each tab's independent widget tree & scroll state.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Switch branch. When tapping the already-active tab, navigate to
  /// that branch's initial location (scroll-to-top / reset behaviour).
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: idx == 0,
                  onTap: () => _goBranch(0),
                ),
                _NavItem(
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  label: 'Search',
                  isActive: idx == 1,
                  onTap: () => _goBranch(1),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag,
                  label: 'Orders',
                  isActive: idx == 2,
                  onTap: () => _goBranch(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: idx == 3,
                  onTap: () => _goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom nav item styled to match stitch PRD design.
/// Active state uses primaryContainer pill with filled icon.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Splash Screen ───────────────────────────

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is! AuthInitial && next is! AuthLoading) {
        if (next is Authenticated) {
          // Initialize FCM after auth succeeds.
          // WHY here: the backend requires a valid auth token to store
          // the FCM token, so we can't do this before login.
          _initNotifications(context);
        }
        context.go(next is Authenticated ? '/' : '/login');
      }
    });

    return const Scaffold(
      backgroundColor: AppColors.primary, // #006D37
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text('SaveBite',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// Initialize FCM notification service after successful auth.
  void _initNotifications(BuildContext ctx) {
    final notifService = ref.read(notificationServiceProvider);

    // Set up deep-link routing for notification taps.
    notifService.onNotificationTap = (data) {
      final type = data['type'] as String?;
      final id = data['id'] as String?;
      if (type == null || id == null) return;

      // Route based on notification type.
      switch (type) {
        case 'order_status':
          ctx.push('/orders/$id');
        case 'new_food_item' || 'flash_sale':
          ctx.push('/food-items/$id');
        case 'merchant_update':
          ctx.push('/merchants/$id');
        default:
          ctx.push('/notifications');
      }
    };

    notifService.initialize();
  }
}

// ─── Auth ↔ GoRouter Bridge ──────────────────

/// Bridges Riverpod [authProvider] to GoRouter's [refreshListenable].
///
/// GoRouter only re-evaluates its `redirect` on navigation events. This
/// [ChangeNotifier] listens to authProvider and calls [notifyListeners]
/// whenever auth state changes (login → Authenticated, logout →
/// Unauthenticated), forcing GoRouter to re-run its redirect logic.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (prev, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
