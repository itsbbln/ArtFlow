import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_state.dart';

class ArtflowApp extends StatelessWidget {
  const ArtflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState()..initialize(),
      child: Consumer<AuthState>(
        builder: (context, authState, _) {
          return MaterialApp.router(
            title: 'Artflow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            routerConfig: createRouter(authState),
          );
        },
      ),
    );
  }
}
