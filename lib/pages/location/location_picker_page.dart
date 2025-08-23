// File: lib/pages/LocationPickerPage.dart (Complete with current location & search)

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final GeoPoint geoPoint;
  final String formattedAddress;
  final String? streetName;
  final String? city;
  final String? postalCode;

  LocationData({
    required this.geoPoint,
    required this.formattedAddress,
    this.streetName,
    this.city,
    this.postalCode,
  });
}

class LocationPickerPage extends StatefulWidget {
  final GeoPoint? initialLocation;
  final String? initialAddress;

  const LocationPickerPage({
    Key? key,
    this.initialLocation,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _isGettingCurrentLocation = false;
  bool _showSearchResults = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  bool _isSearching = false;

  // Default center on Colombo, Sri Lanka
  final LatLng _defaultCenter = const LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeLocation() {
    // Initialize from props if provided
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedAddress = widget.initialAddress ?? '';
      _updateMarker(_selectedLocation!);
    }
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _selectedAddress.isNotEmpty
                ? _selectedAddress
                : 'Tap to select',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  Future<void> _handleMapTap(LatLng location) async {
    _updateMarker(location);
    await _getAddressFromLocation(location);
    // Hide search results when user taps on map
    if (_showSearchResults) {
      setState(() => _showSearchResults = false);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() => _isLoading = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Address lookup timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);

        setState(() {
          _selectedAddress = address;
          _markers = {
            Marker(
              markerId: const MarkerId('selected_location'),
              position: location,
              infoWindow: InfoWindow(
                title: 'Selected Location',
                snippet: address,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          };
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      // Use coordinates as fallback
      setState(() {
        _selectedAddress =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get address, using coordinates'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }

    return addressParts.join(', ');
  }

  // ✅ FIXED: Proper current location with better error handling
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingCurrentLocation = true);

    try {
      print('📍 Checking location permissions...');

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 Requested permission: $permission');

        if (permission == LocationPermission.denied) {
          throw Exception(
              'Location permissions are denied. Please enable location access in your device settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable them in device settings.');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable GPS/Location in your device settings.');
      }

      print('📍 Getting current position...');

      // Get current position with proper settings
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30), // Increased timeout
      );

      print('📍 Got position: ${position.latitude}, ${position.longitude}');

      final currentLocation = LatLng(position.latitude, position.longitude);

      // Move camera to current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, 16),
        );
        print('📍 Camera moved to current location');
      }

      // Update marker and get address
      _updateMarker(currentLocation);
      await _getAddressFromLocation(currentLocation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Current location selected'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error getting current location: $e');

      String errorMessage = 'Could not get current location';

      if (e.toString().contains('permission')) {
        errorMessage =
            'Location permission required. Please enable in settings.';
      } else if (e.toString().contains('service')) {
        errorMessage = 'Please enable GPS/Location services.';
      } else if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        errorMessage = 'Location request timed out. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isGettingCurrentLocation = false);
    }
  }

  // ✅ NEW: Search functionality
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      print('🔍 Searching for: $query');

      List<Location> locations = await locationFromAddress(
        '$query, Sri Lanka', // Add country for better results
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Search timed out');
        },
      );

      print('🔍 Found ${locations.length} results');

      setState(() {
        _searchResults = locations.take(5).toList(); // Limit to 5 results
        _showSearchResults = true;
      });
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No locations found for "$query"'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Location location) async {
    final selectedLocation = LatLng(location.latitude, location.longitude);

    // Move camera to selected location
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(selectedLocation, 16),
      );
    }

    // Update marker and get address
    _updateMarker(selectedLocation);
    await _getAddressFromLocation(selectedLocation);

    // Hide search results
    setState(() {
      _showSearchResults = false;
    });

    // Clear search
    _searchController.clear();
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      final geoPoint =
          GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude);

      final locationData = LocationData(
        geoPoint: geoPoint,
        formattedAddress: _selectedAddress.isNotEmpty
            ? _selectedAddress
            : 'Selected location',
      );

      Navigator.pop(context, locationData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Your Location'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedLocation != null ? _confirmLocation : null,
            child: Text(
              'Confirm',
              style: TextStyle(
                color:
                    _selectedLocation != null ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _defaultCenter,
              zoom: _selectedLocation != null ? 16 : 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _handleMapTap,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll use custom button
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Search bar and results
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      prefixIcon: Icon(Icons.search, color: Colors.purple),
                      suffixIcon: _isSearching
                          ? Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.purple),
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults.clear();
                                      _showSearchResults = false;
                                    });
                                  },
                                  icon: Icon(Icons.clear, color: Colors.grey),
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      // Debounce search
                      Future.delayed(Duration(milliseconds: 500), () {
                        if (value == _searchController.text) {
                          _searchLocation(value);
                        }
                      });
                    },
                    onSubmitted: _searchLocation,
                  ),
                ),

                // Search results
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        return ListTile(
                          leading:
                              Icon(Icons.location_on, color: Colors.purple),
                          title: Text(
                            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () => _selectSearchResult(location),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Helper text (only show if no search results)
          if (!_showSearchResults)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.purple, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap on the map to select your location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedAddress.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Divider(height: 1),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.place, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Bottom buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current location button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isGettingCurrentLocation ? null : _getCurrentLocation,
                    icon: _isGettingCurrentLocation
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.purple),
                            ),
                          )
                        : Icon(Icons.my_location, size: 20),
                    label: Text(_isGettingCurrentLocation
                        ? 'Getting location...'
                        : 'Use Current Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.purple),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay for address lookup
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 12),
                        Text('Getting address...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
