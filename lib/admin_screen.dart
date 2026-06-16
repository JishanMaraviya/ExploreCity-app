import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'api_service.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedCity;
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _addCity() async {
    if (_cityController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('cities').add({
        'name': _cityController.text.trim(),
      });
      if (!mounted) return;
      _cityController.clear();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text("City Added Successfully!", style: AppTextStyles.body(color: Colors.white)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("Error: $e", style: AppTextStyles.body(color: Colors.white))),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
        ),
      );
    }
  }

  void _addPlace() async {
    if (_selectedCity == null ||
        _placeNameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text("Please fill all fields & choose an image", style: AppTextStyles.body(color: Colors.white)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl = await ApiService.uploadImage(_image!);
      if (!mounted) return;
      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection('places').add({
          'cityName': _selectedCity,
          'name': _placeNameController.text.trim(),
          'location': _locationController.text.trim(),
          'image': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        _placeNameController.clear();
        _locationController.clear();
        setState(() {
          _image = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text("Place Added Successfully!", style: AppTextStyles.body(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text("Image upload failed", style: AppTextStyles.body(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("Error: $e", style: AppTextStyles.body(color: Colors.white))),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Place"),
        content: Text("Are you sure you want to delete '${doc['name']}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                await FirebaseFirestore.instance.collection('places').doc(doc.id).delete();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text("Place Deleted Successfully!", style: AppTextStyles.body(color: Colors.white)),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text("Error: $e", style: AppTextStyles.body(color: Colors.white))),
                      ],
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
                  ),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(DocumentSnapshot doc) {
    final TextEditingController editName = TextEditingController(text: doc['name']);
    final TextEditingController editLocation = TextEditingController(text: doc['location']);
    File? newEditImage;
    String currentImageUrl = doc['image'];
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Destination"),
            content: isUpdating
                ? const SizedBox(
                    height: 120,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Updating destination..."),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setDialogState(() {
                                newEditImage = File(pickedFile.path);
                              });
                            }
                          },
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: AppCorners.rounded16,
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: AppCorners.rounded16,
                              child: newEditImage != null
                                  ? Image.file(newEditImage!, fit: BoxFit.cover)
                                  : Image.network(
                                      currentImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 48,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap photo to change",
                          style: AppTextStyles.bodySmall(color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: editName,
                          style: AppTextStyles.body(),
                          decoration: const InputDecoration(
                            labelText: "Place Name",
                            prefixIcon: Icon(Icons.tour_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: editLocation,
                          style: AppTextStyles.body(),
                          decoration: const InputDecoration(
                            labelText: "Location",
                            prefixIcon: Icon(Icons.pin_drop_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        if (editName.text.trim().isEmpty || editLocation.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Please fill all fields"),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isUpdating = true);
                        try {
                          String finalUrl = currentImageUrl;
                          if (newEditImage != null) {
                            String? uploaded = await ApiService.uploadImage(newEditImage!);
                            if (uploaded != null) finalUrl = uploaded;
                          }
                          await FirebaseFirestore.instance.collection('places').doc(doc.id).update({
                            'name': editName.text.trim(),
                            'location': editLocation.text.trim(),
                            'image': finalUrl,
                          });
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text("Destination Updated!", style: AppTextStyles.body(color: Colors.white)),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Update Failed: $e"),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: AppCorners.rounded12),
                            ),
                          );
                        } finally {
                          setDialogState(() => isUpdating = false);
                        }
                      },
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppCorners.rounded16,
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: _image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppCorners.rounded16,
                    child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error),
                        onPressed: () => setState(() => _image = null),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.secondaryText),
                  const SizedBox(height: 8),
                  Text(
                    "Select Destination Photo",
                    style: AppTextStyles.body(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "PNG, JPG up to 10MB",
                    style: AppTextStyles.bodySmall(color: AppColors.secondaryText.withOpacity(0.7)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add City Card
          TravelCard(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_city_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text("Add New City", style: AppTextStyles.subheading()),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityController,
                  style: AppTextStyles.body(),
                  decoration: const InputDecoration(
                    labelText: "City Name",
                    hintText: "e.g., Paris, Tokyo",
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addCity,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Add City"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          // Add Place Card
          TravelCard(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.landscape_rounded, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text("Add Tourist Place", style: AppTextStyles.subheading()),
                  ],
                ),
                const SizedBox(height: 16),
                // Dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('cities').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: LinearProgressIndicator());
                    }
                    var items = snapshot.data!.docs
                        .map((doc) => DropdownMenuItem(
                              value: doc['name'].toString(),
                              child: Text(
                                doc['name'].toString(),
                                style: AppTextStyles.body(),
                              ),
                            ))
                        .toList();
                    return DropdownButtonFormField<String>(
                      value: _selectedCity,
                      style: AppTextStyles.body(),
                      hint: Text("Select City", style: AppTextStyles.body(color: AppColors.secondaryText)),
                      items: items,
                      onChanged: (v) => setState(() => _selectedCity = v),
                      decoration: const InputDecoration(
                        labelText: "City",
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _placeNameController,
                  style: AppTextStyles.body(),
                  decoration: const InputDecoration(
                    labelText: "Place Name",
                    hintText: "e.g., Eiffel Tower",
                    prefixIcon: Icon(Icons.tour_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  style: AppTextStyles.body(),
                  decoration: const InputDecoration(
                    labelText: "Location/Address",
                    hintText: "e.g., Champ de Mars, Paris",
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                _buildImagePicker(),
                const SizedBox(height: 24),
                PremiumGradientButton(
                  onPressed: _addPlace,
                  text: "Upload Place",
                  icon: Icons.cloud_upload_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: AppColors.secondaryText.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No places discovered yet",
                    style: AppTextStyles.subheading(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Go to the 'Add New' tab to create destinations.",
                    style: AppTextStyles.bodySmall(color: AppColors.secondaryText.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        var docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.s20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.s16),
              child: TravelCard(
                padding: EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppCorners.r20),
                        bottomLeft: Radius.circular(AppCorners.r20),
                      ),
                      child: Image.network(
                        doc['image'],
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 110,
                          height: 110,
                          color: AppColors.background,
                          child: const Icon(Icons.broken_image_outlined, color: AppColors.secondaryText),
                        ),
                      ),
                    ),
                    // Details & Actions
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    doc['cityName'].toString().toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                      onPressed: () => _showEditDialog(doc),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                      onPressed: () => _showDeleteConfirmation(doc),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doc['name'],
                              style: AppTextStyles.subheading(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    doc['location'],
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
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Panel", style: AppTextStyles.heading3()),
              Text("Manage destinations & cities", style: AppTextStyles.bodySmall()),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: AppColors.error),
                tooltip: "Logout",
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.subheading(),
            unselectedLabelStyle: AppTextStyles.body(),
            tabs: const [
              Tab(text: "Add New"),
              Tab(text: "Manage Places"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAddTab(),
                  _buildManageTab(),
                ],
              ),
      ),
    );
  }
}
