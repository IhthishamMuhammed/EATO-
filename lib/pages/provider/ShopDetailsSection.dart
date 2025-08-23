// File: lib/pages/provider/ShopDetailsSection.dart
// Enhanced Shop details management component with modern UI

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;

import '../../Model/Food&Store.dart';
import 'package:eato/pages/location/location_picker_page.dart';

class ShopDetailsSection extends StatefulWidget {
  final CustomUser currentUser;
  final Function(bool) onLoadingChanged;
  final Function(String, Color) onShowSnackBar;

  const ShopDetailsSection({
    Key? key,
    required this.currentUser,
    required this.onLoadingChanged,
    required this.onShowSnackBar,
  }) : super(key: key);

  @override
  _ShopDetailsSectionState createState() => _ShopDetailsSectionState();
}

class _ShopDetailsSectionState extends State<ShopDetailsSection> {
  bool _isEditingShop = false;
  XFile? _pickedShopImage;
  Uint8List? _webShopImageData;

  // Store controllers
  late TextEditingController _shopNameController;
  late TextEditingController _shopContactController;
  late TextEditingController _shopLocationController;

  final GlobalKey<FormState> _shopFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _shopContactController = TextEditingController();
    _shopLocationController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoreDataSilently();
    });
  }

  Future<void> _loadStoreDataSilently() async {
    if (!mounted) return;

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      await storeProvider.fetchUserStore(widget.currentUser);

      if (mounted) {
        final store = storeProvider.userStore;
        setState(() {
          if (store != null) {
            _shopNameController.text = store.name;
            _shopContactController.text = store.contact;
            _shopLocationController.text = store.location ?? '';
          }
        });
      }
    } catch (e) {
      print('ShopDetailsSection: Error loading store data: $e');
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopContactController.dispose();
    _shopLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickShopImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _pickedShopImage = image;
        });

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webShopImageData = bytes;
          });
        }
      }
    } catch (e) {
      widget.onShowSnackBar('Error picking image: $e', EatoTheme.errorColor);
    }
  }

  Future<String?> _uploadShopImage() async {
    if (_pickedShopImage == null) return null;

    try {
      final fileName =
          'shop_${widget.currentUser.id}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = FirebaseStorage.instance.ref().child('shop_images/$fileName');

      if (kIsWeb) {
        await ref.putData(_webShopImageData!);
      } else {
        await ref.putFile(io.File(_pickedShopImage!.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading shop image: $e');
      return null;
    }
  }

  Future<void> _saveShopChanges() async {
    if (!_shopFormKey.currentState!.validate()) return;

    if (!mounted) return;

    widget.onLoadingChanged(true);

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final currentStore = storeProvider.userStore;

      String? shopImageUrl;
      if (_pickedShopImage != null) {
        shopImageUrl = await _uploadShopImage();
      }

      if (currentStore != null) {
        final Store updatedStore = Store(
          id: currentStore.id,
          name: _shopNameController.text.trim(),
          contact: _shopContactController.text.trim(),
          deliveryMode: currentStore.deliveryMode,
          imageUrl: shopImageUrl ?? currentStore.imageUrl,
          foods: currentStore.foods,
          location: _shopLocationController.text.trim().isEmpty
              ? null
              : _shopLocationController.text.trim(),
          latitude: currentStore.latitude,
          longitude: currentStore.longitude,
          ownerUid: widget.currentUser.id,
          isActive: currentStore.isActive,
          isAvailable: currentStore.isAvailable,
          rating: currentStore.rating,
        );

        await storeProvider.createOrUpdateStore(
            updatedStore, widget.currentUser.id);
      } else {
        final Store newStore = Store(
          id: '',
          name: _shopNameController.text.trim(),
          contact: _shopContactController.text.trim(),
          deliveryMode: DeliveryMode.pickup,
          imageUrl: shopImageUrl ?? '',
          foods: [],
          location: _shopLocationController.text.trim().isEmpty
              ? null
              : _shopLocationController.text.trim(),
          ownerUid: widget.currentUser.id,
          isActive: true,
          isAvailable: true,
          rating: null,
        );

        await storeProvider.createOrUpdateStore(
            newStore, widget.currentUser.id);
      }

      await storeProvider.fetchUserStore(widget.currentUser);

      if (mounted) {
        setState(() {
          _isEditingShop = false;
        });
        widget.onLoadingChanged(false);
        widget.onShowSnackBar(
            'Shop details updated successfully', EatoTheme.successColor);
      }
    } catch (e) {
      print('Error saving shop changes: $e');
      if (mounted) {
        widget.onLoadingChanged(false);
        widget.onShowSnackBar(
            'Failed to update shop details: $e', EatoTheme.errorColor);
      }
    }
  }

  void _cancelShopEditing() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final store = storeProvider.userStore;

    setState(() {
      _isEditingShop = false;

      if (store != null) {
        _shopNameController.text = store.name;
        _shopContactController.text = store.contact;
        _shopLocationController.text = store.location ?? '';
      }

      _pickedShopImage = null;
      _webShopImageData = null;
    });
  }

  // Show edit shop dialog (Customer style)
  void _showEditShopDialog(Store? store) {
    if (store != null) {
      _shopNameController.text = store.name;
      _shopContactController.text = store.contact;
      _shopLocationController.text = store.location ?? '';
    } else {
      _shopNameController.text = '';
      _shopContactController.text = '';
      _shopLocationController.text = '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _shopFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.store,
                              color: EatoTheme.primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Text('Edit Shop Details',
                              style: EatoTheme.headingSmall),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Shop Image Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: EatoTheme.primaryColor.withOpacity(0.1),
                                border: Border.all(
                                  color:
                                      EatoTheme.primaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildShopImage(store),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  await _pickShopImage();
                                  setDialogState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: EatoTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Shop Name Field
                      TextFormField(
                        controller: _shopNameController,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'Shop Name',
                          hintText: 'Enter shop name',
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter shop name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(width: 16),

                      const SizedBox(height: 16),

                      // Contact Field
                      TextFormField(
                        controller: _shopContactController,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'Contact Number',
                          hintText: 'Enter contact number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location Field
                      GestureDetector(
                        onTap: () async {
                          try {
                            final result = await Navigator.push<LocationData>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationPickerPage(
                                  initialLocation: store?.latitude != null &&
                                          store?.longitude != null
                                      ? GeoPoint(
                                          store!.latitude!, store.longitude!)
                                      : null,
                                  initialAddress: store?.location,
                                ),
                              ),
                            );

                            if (result != null) {
                              setDialogState(() {
                                _shopLocationController.text =
                                    result.formattedAddress;
                              });

                              if (store != null) {
                                final updatedStore = store.copyWith(
                                  location: result.formattedAddress,
                                  latitude: result.geoPoint.latitude,
                                  longitude: result.geoPoint.longitude,
                                );
                                Provider.of<StoreProvider>(context,
                                        listen: false)
                                    .setStore(updatedStore);
                              }
                            }
                          } catch (e) {
                            widget.onShowSnackBar(
                                'Error selecting location: $e',
                                EatoTheme.errorColor);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  color: EatoTheme.primaryColor),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _shopLocationController.text.isEmpty
                                      ? 'Tap to select location from map'
                                      : _shopLocationController.text,
                                  style: TextStyle(
                                    color: _shopLocationController.text.isEmpty
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Delivery Mode Selector
                      _buildDeliveryModeSelector(store),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: EatoTheme.outlinedButtonStyle,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_shopFormKey.currentState!.validate()) {
                                  Navigator.of(context).pop();
                                  await _saveShopChanges();
                                }
                              },
                              style: EatoTheme.primaryButtonStyle,
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryModeSelector(Store? store) {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        final currentStore = storeProvider.userStore ?? store;
        final currentDeliveryMode =
            currentStore?.deliveryMode ?? DeliveryMode.pickup;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Options', style: EatoTheme.labelLarge),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  _buildDeliveryOption('Pickup', DeliveryMode.pickup,
                      currentDeliveryMode, currentStore, storeProvider),
                  _buildDeliveryOption('Delivery', DeliveryMode.delivery,
                      currentDeliveryMode, currentStore, storeProvider),
                  _buildDeliveryOption('Both', DeliveryMode.both,
                      currentDeliveryMode, currentStore, storeProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeliveryOption(
      String title,
      DeliveryMode mode,
      DeliveryMode currentMode,
      Store? currentStore,
      StoreProvider storeProvider) {
    final isSelected = currentMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (currentStore != null) {
            final updatedStore = currentStore.copyWith(deliveryMode: mode);
            storeProvider.setStore(updatedStore);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? EatoTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: mode == DeliveryMode.pickup
                  ? Radius.circular(11)
                  : Radius.zero,
              right:
                  mode == DeliveryMode.both ? Radius.circular(11) : Radius.zero,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopImage(Store? store) {
    if (_pickedShopImage != null) {
      if (kIsWeb) {
        return Image.memory(
          _webShopImageData!,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
        );
      } else {
        return Image.file(
          io.File(_pickedShopImage!.path),
          fit: BoxFit.cover,
          width: 80,
          height: 80,
        );
      }
    } else if (store != null && store.imageUrl.isNotEmpty) {
      return Image.network(
        store.imageUrl,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: EatoTheme.primaryColor,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.store, size: 40, color: EatoTheme.primaryColor);
        },
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EatoTheme.primaryColor.withOpacity(0.1),
              EatoTheme.accentColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Icon(Icons.store, size: 40, color: EatoTheme.primaryColor),
      );
    }
  }

  Widget _buildShopViewDetails(Store? store) {
    if (store == null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.store_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No shop details available',
              style: EatoTheme.bodyMedium
                  .copyWith(color: EatoTheme.textSecondaryColor),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showEditShopDialog(null),
              style: EatoTheme.primaryButtonStyle,
              child: Text('Add Shop Details'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (store.imageUrl.isNotEmpty)
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: EatoTheme.primaryColor.withOpacity(0.3), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  store.imageUrl,
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.store,
                        size: 40, color: EatoTheme.primaryColor);
                  },
                ),
              ),
            ),
          ),
        if (store.imageUrl.isNotEmpty) SizedBox(height: 16),
        _buildInfoTile(
          icon: Icons.store_outlined,
          title: 'Shop Name',
          value: store.name,
        ),
        SizedBox(height: 8),
        _buildInfoTile(
          icon: Icons.phone_outlined,
          title: 'Contact',
          value: store.contact,
        ),
        SizedBox(height: 8),
        _buildInfoTile(
          icon: _getDeliveryModeIcon(store.deliveryMode),
          title: 'Delivery Mode',
          value: store.deliveryMode.displayName,
        ),
        if (store.location != null && store.location!.isNotEmpty) ...[
          SizedBox(height: 8),
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: store.location!,
          ),
        ],
      ],
    );
  }

  IconData _getDeliveryModeIcon(DeliveryMode mode) {
    switch (mode) {
      case DeliveryMode.pickup:
        return Icons.local_shipping_outlined;
      case DeliveryMode.delivery:
        return Icons.delivery_dining;
      case DeliveryMode.both:
        return Icons.compare_arrows;
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: EatoTheme.primaryColor, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: EatoTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(value, style: EatoTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: backgroundColor,
                radius: 22,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final store = storeProvider.userStore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shop Details',
              style:
                  EatoTheme.headingSmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Shop Details Card with action button style
        _buildActionButton(
          store?.name ?? 'Shop Details',
          store != null
              ? '${store.contact} • ${store.deliveryMode.displayName}'
              : 'Add your shop information',
          Icons.store_outlined,
          Colors.green.shade100,
          Colors.green.shade700,
          () => _showEditShopDialog(store),
        ),
      ],
    );
  }
}
