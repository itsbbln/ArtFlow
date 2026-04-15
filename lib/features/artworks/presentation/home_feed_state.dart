import 'package:flutter/foundation.dart';

import '../../entities/models/artwork.dart';
import '../data/artwork_repository.dart';

class HomeFeedState extends ChangeNotifier {
  HomeFeedState(this._repository);

  final ArtworkRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Artwork> _artworks = const [];
  List<Artwork> get artworks => _artworks;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _artworks = await _repository.getFeaturedArtworks();
    _isLoading = false;
    notifyListeners();
  }
}
