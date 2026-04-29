import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';

class SupabaseImageService {
  const SupabaseImageService();

  bool get isConfigured => EnvConfig.hasSupabaseConfig;

  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) {
    final safeUserId = _sanitize(userId);
    final path =
        '${EnvConfig.supabaseProfileFolder}/$safeUserId/profile-${DateTime.now().millisecondsSinceEpoch}.${_normalizeExtension(fileExtension)}';
    return _uploadImage(path: path, bytes: bytes, fileExtension: fileExtension);
  }

  Future<String> uploadArtworkImage({
    required String userId,
    required String artworkId,
    required Uint8List bytes,
    required String fileExtension,
  }) {
    final safeUserId = _sanitize(userId);
    final safeArtworkId = _sanitize(artworkId);
    final path =
        '${EnvConfig.supabaseArtworkFolder}/$safeUserId/$safeArtworkId-${DateTime.now().millisecondsSinceEpoch}.${_normalizeExtension(fileExtension)}';
    return _uploadImage(path: path, bytes: bytes, fileExtension: fileExtension);
  }

  Future<String> uploadArtistApplicationImage({
    required String userId,
    required String assetId,
    required Uint8List bytes,
    required String fileExtension,
  }) {
    final safeUserId = _sanitize(userId);
    final safeAssetId = _sanitize(assetId);
    final path =
        '${EnvConfig.supabaseArtistApplicationFolder}/$safeUserId/$safeAssetId-${DateTime.now().millisecondsSinceEpoch}.${_normalizeExtension(fileExtension)}';
    return _uploadImage(path: path, bytes: bytes, fileExtension: fileExtension);
  }

  Future<String> uploadScholarVerificationImage({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) {
    final safeUserId = _sanitize(userId);
    final path =
        '${EnvConfig.supabaseScholarFolder}/$safeUserId/scholar-${DateTime.now().millisecondsSinceEpoch}.${_normalizeExtension(fileExtension)}';
    return _uploadImage(path: path, bytes: bytes, fileExtension: fileExtension);
  }

  Future<String> _uploadImage({
    required String path,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured yet. Fill the Supabase values in .env first.',
      );
    }

    final bucket = EnvConfig.supabaseStorageBucket;
    final client = Supabase.instance.client;
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentTypeForExtension(fileExtension),
          ),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _normalizeExtension(String extension) {
    final normalized = extension.toLowerCase().replaceAll('.', '');
    if (normalized.isEmpty) {
      return 'jpg';
    }
    return normalized;
  }

  String _contentTypeForExtension(String extension) {
    switch (_normalizeExtension(extension)) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
