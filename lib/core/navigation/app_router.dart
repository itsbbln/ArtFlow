import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_status.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../widgets/app_scaffold.dart';
import '../../features/screens/screens.dart';
import '../../features/screens/welcome_screen.dart';
import '../../features/screens/become_artist_screen.dart';
import '../../features/screens/scholar_verification_screen.dart';

GoRouter createRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/register',
    refreshListenable: authState,
    redirect: (context, state) {
      final path = state.uri.path;
      final authPaths = {
        '/splash',
        '/welcome',
        '/register',
        '/onboarding/buyer',
        '/onboarding/artist',
        '/verification',
      };

      if (authState.status == AuthStatus.checking &&
          path != '/register' &&
          path != '/splash' &&
          path != '/welcome') {
        return '/register';
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (!authPaths.contains(path)) {
          return '/register';
        }
      }

      if (authState.status == AuthStatus.authenticated) {
        // If they are an admin, redirect them to the admin dashboard if they are on entry pages
        if (authState.isAdmin &&
            (path == '/register' ||
                path == '/welcome' ||
                path == '/splash' ||
                path == '/')) {
          return '/admin';
        }

        // Only redirect from register/welcome if authenticated
        if (path == '/register' || path == '/welcome' || path == '/splash') {
          return '/';
        }

        // If they are already a verified artist, don't let them go to onboarding again
        if (authState.isVerifiedArtist &&
            (path == '/onboarding/artist' || path == '/become-artist')) {
          return '/artist-dashboard';
        }
      }

      if (path == '/admin' && !authState.isAdmin) {
        return '/';
      }

      if ((path == '/create' || path.startsWith('/create/')) &&
          !authState.isVerified &&
          !authState.isAdmin) {
        return '/';
      }

      if (path == '/verification' && !authState.verificationSubmitted) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/onboarding/buyer',
        builder: (_, _) => const BuyerOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/artist',
        builder: (_, _) => const ArtistOnboardingScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (_, _) => const VerificationPage(),
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
          GoRoute(
            path: '/become-artist',
            builder: (_, _) => const BecomeArtistScreen(),
          ),
          GoRoute(
            path: '/scholar-verification',
            builder: (_, _) => const ScholarVerificationScreen(),
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
          GoRoute(
            path: '/portfolio-management',
            builder: (_, _) => const PortfolioManagementScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, _) => const WalletScreen(),
          ),
          GoRoute(
            path: '/artist-orders',
            builder: (_, _) => const ArtistOrdersScreen(),
          ),
          GoRoute(
            path: '/pricing-guidance',
            builder: (_, _) => const PricingGuidanceScreen(),
          ),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/auctions', builder: (_, _) => const AuctionsScreen()),
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
