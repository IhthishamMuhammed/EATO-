import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart' as location;
import 'package:permission_handler/permission_handler.dart';

class LocationResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPickerPage({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  }) : super(key: key);

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectedAddress = widget.initialAddress ?? '';
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      final permission = await Permission.location.request();
      if (permission != location.PermissionStatus.granted) {
        throw Exception('Location permission denied');
      }

      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service disabled');
        }
      }

      // Get current location
      final locationData = await _location.getLocation();

      if (locationData.latitude != null && locationData.longitude != null) {
        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        setState(() {
          _selectedLocation = latLng;
        });

        await _getAddressFromLatLng(latLng);

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(latLng),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Default to Colombo, Sri Lanka if location fails
      const defaultLocation = LatLng(6.9271, 79.8612);
      setState(() {
        _selectedLocation = defaultLocation;
        _selectedAddress = 'Colombo, Sri Lanka';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _selectedAddress = _formatAddress(placemark);
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Selected location';
      });
    }
  }

  String _formatAddress(geocoding.Placemark placemark) {
    List<String> parts = [];

    if (placemark.street?.isNotEmpty == true) parts.add(placemark.street!);
    if (placemark.subLocality?.isNotEmpty == true)
      parts.add(placemark.subLocality!);
    if (placemark.locality?.isNotEmpty == true) parts.add(placemark.locality!);
    if (placemark.administrativeArea?.isNotEmpty == true)
      parts.add(placemark.administrativeArea!);

    return parts.join(', ');
  }

  void _onMapTapped(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _isLoading = true;
    });

    _getAddressFromLatLng(latLng).then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      final result = LocationResult(
        address: _selectedAddress,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          _selectedLocation == null
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                    zoom: 15.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTapped,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId('selected_location'),
                            position: _selectedLocation!,
                            infoWindow: InfoWindow(
                              title: 'Selected Location',
                              snippet: _selectedAddress,
                            ),
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ),
            ),

          // Address display and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _selectedAddress.isEmpty
                          ? 'Tap on map to select location'
                          : _selectedAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedAddress.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedLocation != null &&
                              _selectedAddress.isNotEmpty
                          ? _confirmLocation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
