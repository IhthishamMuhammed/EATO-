// File: lib/pages/LocationPickerPage.dart (Enhanced with current location & search)

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Default center on Colombo, Sri Lanka
  final LatLng _defaultCenter = const LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() => _isLoading = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get address for this location'),
          backgroundColor: Colors.orange,
        ),
      );
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
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      addressParts.add(placemark.postalCode!);
    }

    return addressParts.join(', ');
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingCurrentLocation = true);

    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);

      // Move camera to current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, 16),
        );
      }

      // Update marker and get address
      _updateMarker(currentLocation);
      await _getAddressFromLocation(currentLocation);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current location selected'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get current location: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isGettingCurrentLocation = false);
    }
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

          // Helper text at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                SizedBox(height: 12),

                // Search location button (placeholder for future enhancement)
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Search functionality coming soon! For now, you can tap on the map or use current location.'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text('Search for a location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
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
