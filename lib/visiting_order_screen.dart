import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'place_details_screen.dart';

class VisitingOrderScreen extends StatefulWidget {
  final String cityName;

  const VisitingOrderScreen({super.key, required this.cityName});

  @override
  State<VisitingOrderScreen> createState() => _VisitingOrderScreenState();
}

class _VisitingOrderScreenState extends State<VisitingOrderScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _places = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVisitOrder();
  }

  void _fetchVisitOrder() async {
    try {
      var placesSnap = await FirebaseFirestore.instance.collection('places').where('cityName', isEqualTo: widget.cityName).get();
      var orderSnap = await FirebaseFirestore.instance.collection('visit_orders').doc(widget.cityName).get();

      List<Map<String, dynamic>> fetchedPlaces = placesSnap.docs.map((doc) => {
        'id': doc.id,
        ...doc.data()
      }).toList();

      if (orderSnap.exists) {
        List<dynamic> orderedIds = orderSnap.data()?['orderedPlaces'] ?? [];
        fetchedPlaces.sort((a, b) {
          int indexA = orderedIds.indexOf(a['id']);
          int indexB = orderedIds.indexOf(b['id']);
          if (indexA == -1 && indexB == -1) return 0;
          if (indexA == -1) return 1;
          if (indexB == -1) return -1;
          return indexA.compareTo(indexB);
        });
      }

      if (mounted) {
        setState(() {
          _places = fetchedPlaces;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Recommended Visit Order",
          style: AppTextStyles.heading3(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error", style: AppTextStyles.body()))
              : _places.isEmpty
                  ? Center(child: Text("No places found.", style: AppTextStyles.body()))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s16),
                      itemCount: _places.length + 1,
                      itemBuilder: (context, index) {
                        bool isFlag = index == _places.length;
                        bool isFirst = index == 0;
                        
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Timeline Graphic
                              SizedBox(
                                width: 32,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Vertical Line
                                    Positioned.fill(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: 3,
                                              color: isFirst ? Colors.transparent : AppColors.primary.withAlpha(128),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              width: 3,
                                              color: isFlag ? Colors.transparent : AppColors.primary.withAlpha(128),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Dot or Flag
                                    if (isFlag)
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.primary.withAlpha(128), width: 2),
                                        ),
                                        child: const Icon(Icons.flag_rounded, color: AppColors.primary, size: 16),
                                      )
                                    else
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withAlpha(76),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Content
                              Expanded(
                                child: isFlag
                                    ? Padding(
                                        padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 32.0),
                                        child: Text(
                                          "Trip Complete",
                                          style: AppTextStyles.subheading(color: AppColors.primary),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.only(left: 16.0, bottom: 24.0),
                                        child: TravelCard(
                                          padding: const EdgeInsets.all(12),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PlaceDetailsScreen(
                                                  placeData: _places[index],
                                                  placeId: _places[index]['id'],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  _places[index]['image'] ?? '',
                                                  width: 64,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 64,
                                                    height: 64,
                                                    color: Theme.of(context).colorScheme.outline,
                                                    child: const Icon(Icons.image_not_supported_outlined, size: 24),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Stop ${index + 1}",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _places[index]['name'] ?? 'Unknown',
                                                      style: AppTextStyles.subheading(),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withAlpha(25),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
