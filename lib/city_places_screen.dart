import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';

class CityPlacesScreen extends StatefulWidget {
  final String cityName;

  const CityPlacesScreen({super.key, required this.cityName});

  @override
  State<CityPlacesScreen> createState() => _CityPlacesScreenState();
}

class _CityPlacesScreenState extends State<CityPlacesScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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

  Future<void> _togglePlaceLike(String placeId, bool isLiked) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    if (isLiked) {
      await userRef.update({
        'likedPlaces': FieldValue.arrayRemove([placeId])
      });
    } else {
      await userRef.update({
        'likedPlaces': FieldValue.arrayUnion([placeId])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Places in ${widget.cityName}",
          style: AppTextStyles.heading3(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppCorners.rounded16,
                  boxShadow: AppShadows.soft,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: "Search places...",
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnap) {
              List<dynamic> likedPlaces = [];
              if (userSnap.hasData && userSnap.data!.exists) {
                var data = userSnap.data!.data() as Map<String, dynamic>;
                likedPlaces = data['likedPlaces'] ?? [];
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('cityName', isEqualTo: widget.cityName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }

                  var places = snapshot.data?.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['name'].toString().toLowerCase().contains(_searchQuery);
                  }).toList() ?? [];

                  if (places.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text("No places found in ${widget.cityName}", style: AppTextStyles.body()),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          var doc = places[index];
                          var data = doc.data() as Map<String, dynamic>;
                          String placeId = doc.id;
                          bool isLiked = likedPlaces.contains(placeId);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                            child: TravelCard(
                              padding: EdgeInsets.zero,
                              onTap: () {
                                // Detail page functionality later
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppCorners.r20)),
                                        child: Image.network(
                                          data['image'],
                                          height: 220,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 220,
                                            color: AppColors.border,
                                            child: const Icon(Icons.image_not_supported_outlined),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              color: isLiked ? Colors.redAccent : AppColors.secondaryText,
                                            ),
                                            onPressed: () => _togglePlaceLike(placeId, isLiked),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.s16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['name'], style: AppTextStyles.heading3()),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () => _openGoogleMaps(data['location']),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    data['location'],
                                                    style: AppTextStyles.bodySmall(color: AppColors.primary).copyWith(
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 14),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: places.length,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
