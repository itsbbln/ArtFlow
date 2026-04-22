import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_status.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../widgets/app_scaffold.dart';
import '../../features/screens/screens.dart';

GoRouter createRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authState,
    redirect: (context, state) {
      final path = state.uri.path;
      final authPaths = {
        '/splash',
        '/register',
        '/onboarding/buyer',
        '/onboarding/artist',
      };

      if (authState.status == AuthStatus.checking && path != '/splash') {
        return '/splash';
      }

      if (authState.status == AuthStatus.unauthenticated &&
          !authPaths.contains(path)) {
        return '/register';
      }

      if (authState.status == AuthStatus.authenticated &&
          authPaths.contains(path)) {
        return '/';
      }

      if (path == '/admin' && !authState.isAdmin) {
        return '/';
      }

      if ((path == '/create' || path.startsWith('/create/')) &&
          !authState.isArtist) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/onboarding/buyer',
        builder: (_, _) => const BuyerOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/artist',
        builder: (_, _) => const ArtistOnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/artist-dashboard',
            builder: (_, _) => const ArtistDashboardScreen(),
          ),
          GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
          GoRoute(
            path: '/artwork/:id',
            builder: (_, state) {
              return ArtworkDetailScreen(id: state.pathParameters['id']!);
            },
          ),
          GoRoute(
            path: '/create',
            builder: (_, _) => const CreateArtworkScreen(),
          ),
          GoRoute(
            path: '/create/:id',
            builder: (_, state) {
              return CreateArtworkScreen(artworkId: state.pathParameters['id']);
            },
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: '/edit-profile',
            builder: (_, _) => const EditProfileScreen(),
          ),
          GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen()),
          GoRoute(
            path: '/chat/:conversationId',
            builder: (_, state) {
              return ChatScreen(
                conversationId: state.pathParameters['conversationId']!,
              );
            },
          ),
          GoRoute(
            path: '/commission',
            builder: (_, _) => const CommissionRequestScreen(),
          ),
          GoRoute(
            path: '/commissions',
            builder: (_, _) => const CommissionsScreen(),
          ),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/artist/:artistId',
            builder: (_, state) {
              return ArtistProfileScreen(
                artistId: state.pathParameters['artistId']!,
              );
            },
          ),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
        ],
      ),
    ],
    errorBuilder: (_, _) => const NotFoundScreen(),
  );
}
