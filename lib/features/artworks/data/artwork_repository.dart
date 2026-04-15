import '../../entities/models/artwork.dart';
import '../../shared/data/api_client.dart';

class ArtworkRepository {
  ArtworkRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Artwork>> getFeaturedArtworks() async {
    await _apiClient.get('/artworks/featured');
    return [
      Artwork(
        id: '1',
        title: 'Golden Dusk',
        artistName: 'M. Reyes',
        price: 420,
      ),
      Artwork(id: '2', title: 'Metro Pulse', artistName: 'A. Cruz', price: 320),
      Artwork(
        id: '3',
        title: 'Quiet Harbor',
        artistName: 'L. Santos',
        price: 510,
      ),
    ];
  }
}
