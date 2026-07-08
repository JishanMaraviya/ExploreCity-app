import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> placeData;
  final String placeId;

  const PlaceDetailsScreen({
    super.key,
    required this.placeData,
    required this.placeId,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  Future<void> _togglePlaceLike(bool isLiked) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    if (isLiked) {
      await userRef.update({
        'likedPlaces': FieldValue.arrayRemove([widget.placeId])
      });
    } else {
      await userRef.update({
        'likedPlaces': FieldValue.arrayUnion([widget.placeId])
      });
    }
  }

  Future<void> _openGoogleMaps(String location) async {
    final String encodedLocation = Uri.encodeComponent(location);
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedLocation");
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.placeData['image'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.outline,
                  child: const Icon(Icons.image_not_supported_outlined, size: 50),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.placeData['name'] ?? 'Unknown Place',
                          style: AppTextStyles.heading1(),
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                        builder: (context, snapshot) {
                          bool isLiked = false;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            var data = snapshot.data!.data() as Map<String, dynamic>;
                            List<dynamic> likedPlaces = data['likedPlaces'] ?? [];
                            isLiked = likedPlaces.contains(widget.placeId);
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: Theme.of(context).brightness == Brightness.light ? AppShadows.soft : null,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? Colors.redAccent : Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 28,
                              ),
                              onPressed: () => _togglePlaceLike(isLiked),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      String loc = widget.placeData['location'] ?? '';
                      if (loc.isNotEmpty) {
                        _openGoogleMaps(loc);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "View on Map",
                            style: AppTextStyles.body(color: AppColors.primary).copyWith(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Description", style: AppTextStyles.heading3()),
                  const SizedBox(height: 12),
                  Text(
                    widget.placeData['description'] ?? 'No description available for this place.',
                    style: AppTextStyles.body().copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
