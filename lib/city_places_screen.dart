import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';
import 'place_details_screen.dart';
import 'visiting_order_screen.dart';

class CityPlacesScreen extends StatefulWidget {
  final String cityName;

  const CityPlacesScreen({super.key, required this.cityName});

  @override
  State<CityPlacesScreen> createState() => _CityPlacesScreenState();
}

class _CityPlacesScreenState extends State<CityPlacesScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
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
                  color: Theme.of(context).colorScheme.surface,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: TravelCard(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.only(bottom: AppSpacing.s24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisitingOrderScreen(cityName: widget.cityName),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.route_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Recommended Visiting Order", style: AppTextStyles.subheading()),
                          const SizedBox(height: 4),
                          Text("See the best sequence to explore.", style: AppTextStyles.bodySmall()),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                  ],
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaceDetailsScreen(
                                      placeData: data,
                                      placeId: placeId,
                                    ),
                                  ),
                                );
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
                                            color: Theme.of(context).colorScheme.outline,
                                            child: const Icon(Icons.image_not_supported_outlined),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              color: isLiked ? Colors.redAccent : Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () => _togglePlaceLike(placeId, isLiked),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.s16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(data['name'], style: AppTextStyles.heading3(), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PlaceDetailsScreen(
                                                  placeData: data,
                                                  placeId: placeId,
                                                ),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: const Size(0, 32),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text("More", style: TextStyle(fontWeight: FontWeight.w600)),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_rounded, size: 16),
                                            ],
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
