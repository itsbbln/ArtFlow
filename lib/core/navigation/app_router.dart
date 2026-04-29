import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_status.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/payments/presentation/checkout_screen.dart';
import '../../features/payments/presentation/payment_success_screen.dart';
import '../widgets/app_scaffold.dart';
import '../../features/screens/screens.dart';
import '../../features/screens/welcome_screen.dart';
import '../../features/screens/become_artist_screen.dart';
import '../../features/screens/scholar_verification_screen.dart';

GoRouter createRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/splash',
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

      if (authState.status == AuthStatus.checking) {
        if (path != '/splash') {
          return '/splash';
        }
        return null;
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (path == '/splash') {
          return authState.welcomeCompleted ? '/register' : '/welcome';
        }

        if (!authPaths.contains(path)) {
          return '/register';
        }
      }

      if (authState.status == AuthStatus.authenticated) {
        if (path == '/splash') {
          if (authState.isAdmin) {
            return '/admin';
          }
          if (authState.isVerifiedArtist) {
            return '/artist-dashboard';
          }
          return '/';
        }

        // If they are an admin, redirect them to the admin dashboard if they are on entry pages
        if (authState.isAdmin &&
            (path == '/register' || path == '/welcome' || path == '/')) {
          return '/admin';
        }

        // Only redirect from register/welcome if authenticated
        if (path == '/register' || path == '/welcome') {
          if (authState.isVerifiedArtist) {
            return '/artist-dashboard';
          }
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
          !authState.isVerifiedArtist &&
          !authState.isAdmin) {
        return '/';
      }

      if (path == '/verification' &&
          !authState.verificationSubmitted &&
          !authState.hasArtistApplication &&
          !authState.isVerifiedArtist) {
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
      GoRoute(
        path: '/checkout/:artworkId',
        builder: (_, state) {
          return CheckoutScreen(artworkId: state.pathParameters['artworkId']!);
        },
      ),
      GoRoute(
        path: '/checkout/success',
        builder: (_, state) {
          return PaymentSuccessScreen(
            orderId: state.uri.queryParameters['orderId'] ?? '',
            artworkTitle: state.uri.queryParameters['artwork'] ?? 'Artwork',
            reference: state.uri.queryParameters['reference'] ?? '',
          );
        },
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
                participantId: state.uri.queryParameters['userId'],
                participantName: state.uri.queryParameters['name'],
                participantRole: state.uri.queryParameters['role'],
              );
            },
          ),
          GoRoute(
            path: '/commission',
            builder: (_, state) => CommissionRequestScreen(
              artistName: state.uri.queryParameters['artist'],
              artistId: state.uri.queryParameters['artistId'],
              artworkId: state.uri.queryParameters['artworkId'],
              artworkTitle: state.uri.queryParameters['artworkTitle'],
            ),
          ),
          GoRoute(
            path: '/commissions',
            builder: (_, _) => const CommissionsScreen(),
          ),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/payments', builder: (_, _) => const PaymentsScreen()),
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
