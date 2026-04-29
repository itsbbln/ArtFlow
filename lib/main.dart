import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/dotenv');
  } catch (e) {
    debugPrint('Environment file was not loaded: $e');
  }
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue running the app even if Firebase fails
  }
  if (EnvConfig.hasSupabaseConfig) {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  }
  runApp(const ArtflowApp());
}
