import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/shared/data/app_data_state.dart';

class ArtflowApp extends StatefulWidget {
  const ArtflowApp({super.key});

  @override
  State<ArtflowApp> createState() => _ArtflowAppState();
}

class _ArtflowAppState extends State<ArtflowApp> {
  late final AuthState _authState;
  late final AppDataState _appDataState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authState = AuthState()..initialize();
    _appDataState = AppDataState()..initialize();
    _authState.addListener(_syncAppData);
    _router = createRouter(_authState);
  }

  Future<void> _syncAppData() async {
    await _appDataState.bindForUser(
      userId: _authState.currentUserId ?? '',
      displayName: _authState.displayName,
      artistView: _authState.isArtist || _authState.isAdmin,
    );
  }

  @override
  void dispose() {
    _authState.removeListener(_syncAppData);
    _appDataState.dispose();
    _authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authState),
        ChangeNotifierProvider.value(value: _appDataState),
      ],
      child: MaterialApp.router(
        title: 'Artflow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
