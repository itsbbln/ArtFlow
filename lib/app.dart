import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_state.dart';

class ArtflowApp extends StatefulWidget {
  const ArtflowApp({super.key});

  @override
  State<ArtflowApp> createState() => _ArtflowAppState();
}

class _ArtflowAppState extends State<ArtflowApp> {
  late final AuthState _authState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authState = AuthState()..initialize();
    _router = createRouter(_authState);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authState,
      child: MaterialApp.router(
        title: 'Artflow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
