import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/items/items_screen.dart';
import '../../screens/items/add_item_screen.dart';
import '../../screens/items/item_detail_screen.dart';
import '../../screens/customers/customers_screen.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth provider to re-trigger redirect whenever state changes
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Don't redirect until the splash screen completes checkAuthStatus
      if (!authState.isInitialized) {
        return null;
      }

      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/register';

      // If user is not authenticated and trying to access a protected page, force login
      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      // If user is authenticated and trying to access auth pages, redirect to home
      if (isAuth && isAuthRoute) {
        return '/home';
      }

      // Auth guard — runs on every navigation event
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/items',
        builder: (context, state) => const ItemsScreen(),
      ),
      GoRoute(
        path: '/items/new',
        builder: (context, state) => const AddItemScreen(),
      ),
      GoRoute(
        path: '/items/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ItemDetailScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/items/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AddItemScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/customers/new',
        builder: (context, state) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AddCustomerScreen(customerId: id);
        },
      ),
    ],
  );
});
