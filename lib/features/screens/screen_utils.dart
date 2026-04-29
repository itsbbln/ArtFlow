import '../auth/presentation/auth_state.dart';
import '../chat/domain/chat_models.dart';
import '../entities/models/artwork.dart';

String categoryLabel(String value) {
  return value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

List<Artwork> filterArtworksByCategory(List<Artwork> artworks, String category) {
  if (category == 'all') {
    return artworks;
  }
  return artworks.where((item) => item.category == category).toList();
}

String roleLabel(AuthState auth) {
  if (auth.isAdmin) {
    return 'Admin';
  }
  if (auth.isArtist) {
    return 'Artist';
  }
  return 'Buyer';
}

String chatUserIdFor(AuthState auth) {
  return auth.currentUserId ?? ChatContact.aliasUserIdForName(auth.displayName);
}

String buildCommissionRoute({
  required String artistName,
  String artistId = '',
  String artworkId = '',
  String artworkTitle = '',
}) {
  final artist = Uri.encodeComponent(artistName);
  final artistUserId = Uri.encodeComponent(artistId);
  final artId = Uri.encodeComponent(artworkId);
  final title = Uri.encodeComponent(artworkTitle);
  return '/commission?artist=$artist&artistId=$artistUserId&artworkId=$artId&artworkTitle=$title';
}
