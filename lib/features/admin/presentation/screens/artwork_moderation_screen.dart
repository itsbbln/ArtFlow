import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../widgets/admin_widgets.dart';

/// Artwork Moderation Screen
class ArtworkModerationScreen extends StatefulWidget {
  const ArtworkModerationScreen({super.key});

  @override
  State<ArtworkModerationScreen> createState() => _ArtworkModerationScreenState();
}

class _ArtworkModerationScreenState extends State<ArtworkModerationScreen> {
  final _adminRepository = AdminRepository();
  String _filterType = 'All'; // All, Flagged, Pending

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Flagged'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending'),
              ],
            ),
          ),
        ),
        // Artworks list
        Expanded(
          child: StreamBuilder<List<ArtworkForModeration>>(
            stream: _filterType == 'Flagged'
                ? _adminRepository.getFlaggedArtworks()
                : _adminRepository.getAllArtworks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              var artworks = snapshot.data ?? [];

              // Apply filter for pending
              if (_filterType == 'Pending') {
                artworks = artworks
                    .where((art) => art.status == ModerationStatus.pending)
                    .toList();
              }

              if (artworks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 12),
                      const Text('No artworks to moderate'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: artworks.length,
                itemBuilder: (context, index) {
                  final artwork = artworks[index];
                  return ArtworkModerationCard(
                    title: artwork.title,
                    artistName: artwork.artistName,
                    imageUrl: artwork.imageUrl,
                    reportCount: artwork.reportCount,
                    reportedIssues: artwork.reportedIssues,
                    onApprove: () => _approveArtwork(artwork.artworkId),
                    onHide: () => _hideArtwork(artwork.artworkId),
                    onRemove: () => _removeArtwork(artwork.artworkId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _filterType == label,
      onSelected: (selected) {
        setState(() {
          _filterType = selected ? label : 'All';
        });
      },
    );
  }

  Future<void> _approveArtwork(String artworkId) async {
    try {
      await _adminRepository.approveArtwork(artworkId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _hideArtwork(String artworkId) async {
    try {
      await _adminRepository.hideArtwork(artworkId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork hidden')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeArtwork(String artworkId) async {
    try {
      await _adminRepository.removeArtwork(artworkId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
