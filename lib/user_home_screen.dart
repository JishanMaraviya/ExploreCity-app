import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'city_places_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeTab(),
            LikesTab(),
            ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Like',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---- HOME TAB ----
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  Future<void> _toggleCityLike(String cityName, bool isLiked) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    if (isLiked) {
      await userRef.update({
        'likedCities': FieldValue.arrayRemove([cityName])
      });
    } else {
      await userRef.update({
        'likedCities': FieldValue.arrayUnion([cityName])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Explore the world", style: AppTextStyles.bodySmall()),
                Text("Ready for your\nnext adventure?", style: AppTextStyles.heading1()),
                const SizedBox(height: AppSpacing.s32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppCorners.rounded16,
                    boxShadow: AppShadows.soft,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: "Search cities...",
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            List<dynamic> likedCities = [];
            if (userSnap.hasData && userSnap.data!.exists) {
              var data = userSnap.data!.data() as Map<String, dynamic>;
              likedCities = data['likedCities'] ?? [];
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cities').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                
                var cities = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['name'].toString().toLowerCase().contains(_searchQuery);
                }).toList();

                if (cities.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Text("No cities found", style: AppTextStyles.body())),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var data = cities[index].data() as Map<String, dynamic>;
                        String cityName = data['name'];
                        bool isLiked = likedCities.contains(cityName);
                        
                        return CityCard(
                          cityName: cityName,
                          isLiked: isLiked,
                          onLikeToggled: () => _toggleCityLike(cityName, isLiked),
                        );
                      },
                      childCount: cities.length,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.s24)),
      ],
    );
  }
}

// ---- LIKES TAB ----
class LikesTab extends StatelessWidget {
  const LikesTab({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const Center(child: Text("No user data found"));
        }

        var data = userSnap.data!.data() as Map<String, dynamic>;
        List<dynamic> likedCities = data['likedCities'] ?? [];
        List<dynamic> likedPlaces = data['likedPlaces'] ?? [];

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Row(
                  children: [
                    Text("Your Favorites", style: AppTextStyles.heading2()),
                  ],
                ),
              ),
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.secondaryText,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: "Cities"),
                  Tab(text: "Places"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Liked Cities
                    likedCities.isEmpty
                        ? Center(child: Text("No liked cities", style: AppTextStyles.body()))
                        : GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.s24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: likedCities.length,
                            itemBuilder: (context, index) {
                              String cityName = likedCities[index];
                              return CityCard(
                                cityName: cityName,
                                isLiked: true,
                                onLikeToggled: () {
                                  FirebaseFirestore.instance.collection('users').doc(uid).update({
                                    'likedCities': FieldValue.arrayRemove([cityName])
                                  });
                                },
                              );
                            },
                          ),
                    // Liked Places
                    likedPlaces.isEmpty
                        ? Center(child: Text("No liked places", style: AppTextStyles.body()))
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('places').snapshots(),
                            builder: (context, placesSnap) {
                              if (placesSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              var places = placesSnap.data!.docs.where((doc) => likedPlaces.contains(doc.id)).toList();
                              
                              if (places.isEmpty) {
                                return Center(child: Text("No liked places", style: AppTextStyles.body()));
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.all(AppSpacing.s24),
                                itemCount: places.length,
                                itemBuilder: (context, index) {
                                  var doc = places[index];
                                  var data = doc.data() as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                                    child: TravelCard(
                                      padding: EdgeInsets.zero,
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
                                                    icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                                                    onPressed: () {
                                                      FirebaseFirestore.instance.collection('users').doc(uid).update({
                                                        'likedPlaces': FieldValue.arrayRemove([doc.id])
                                                      });
                                                    },
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
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_rounded, color: AppColors.secondaryText, size: 14),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        data['location'],
                                                        style: AppTextStyles.bodySmall(color: AppColors.secondaryText),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---- PROFILE TAB ----
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        String name = "User";
        String email = FirebaseAuth.instance.currentUser!.email ?? "";
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(name, style: AppTextStyles.heading2()),
              const SizedBox(height: 4),
              Text(email, style: AppTextStyles.body(color: AppColors.secondaryText)),
              const SizedBox(height: 40),
              TravelCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                onTap: _logout,
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error),
                    SizedBox(width: 16),
                    Text("Log Out", style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---- REUSABLE CITY CARD ----
class CityCard extends StatelessWidget {
  final String cityName;
  final bool isLiked;
  final VoidCallback onLikeToggled;

  const CityCard({
    super.key,
    required this.cityName,
    required this.isLiked,
    required this.onLikeToggled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CityPlacesScreen(cityName: cityName),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppCorners.rounded16,
          boxShadow: AppShadows.soft,
        ),
        child: ClipRRect(
          borderRadius: AppCorners.rounded16,
          child: Stack(
            fit: StackFit.expand,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('cityName', isEqualTo: cityName)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    var placeData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    String imageUrl = placeData['image'] ?? '';
                    if (imageUrl.isNotEmpty) {
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: AppColors.primary),
                      );
                    }
                  }
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                  );
                },
              ),
              Container(
                color: Colors.black.withOpacity(0.4),
              ),
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.location_city_rounded,
                  size: 100,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: onLikeToggled,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      cityName,
                      style: AppTextStyles.heading3(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text(
                          "Explore places",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
