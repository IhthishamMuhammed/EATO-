import 'dart:typed_data';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/provider/AddFoodPage.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StoreDetailsPage extends StatefulWidget {
  final CustomUser currentUser;

  const StoreDetailsPage({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _StoreDetailsPageState createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopContactController = TextEditingController();
  bool isPickup = true;
  Uint8List? _webImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    storeProvider.fetchUserStore(widget.currentUser);
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedImage != null) {
        final bytes = await pickedImage.readAsBytes();

        setState(() {
          _webImageBytes = bytes;
        });

        print("Image picked successfully (Web-safe)");
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: $e")),
      );
    }
  }

  Widget _buildImageWidget() {
    if (_webImageBytes == null) {
      return Center(
        child: Icon(
          Icons.add,
          size: 40,
          color: Colors.purple,
        ),
      );
    } else {
      return ClipOval(
        child: Image.memory(
          _webImageBytes!,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.currentUser == null) {
      userProvider.setCurrentUser(widget.currentUser);
    }

    if (!storeProvider.isLoading && storeProvider.userStore != null) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProviderHomePage(currentUser: widget.currentUser),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Welcome!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: storeProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple))
          : _buildShopDetailsForm(storeProvider,
              userProvider.currentUser?.id ?? widget.currentUser.id),
    );
  }

  Widget _buildShopDetailsForm(StoreProvider storeProvider, String userId) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Enter your shop details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 20),
            Text("Shop Name", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _shopNameController,
                decoration: InputDecoration(
                  hintText: "Enter your shop name",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text("Shop Contact Number",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _shopContactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Enter your shop contact number",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isPickup = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isPickup ? Colors.purple : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(30)),
                        ),
                        child: Center(
                          child: Text(
                            'Pickup',
                            style: TextStyle(
                              color: isPickup ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isPickup = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isPickup ? Colors.purple : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(30)),
                        ),
                        child: Center(
                          child: Text(
                            'Delivery',
                            style: TextStyle(
                              color: !isPickup ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text("Profile Picture",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _buildImageWidget(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_shopNameController.text.isEmpty ||
                            _shopContactController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Please fill all required fields')),
                          );
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          String imageUrl = '';
                          if (_webImageBytes != null) {
                            final fileName = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                            final reference = FirebaseStorage.instance
                                .ref()
                                .child('store_images')
                                .child('$fileName.jpg');

                            await reference.putData(_webImageBytes!);
                            imageUrl = await reference.getDownloadURL();
                          }

                          final store = Store(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: _shopNameController.text,
                            contact: _shopContactController.text,
                            isPickup: isPickup,
                            imageUrl: imageUrl,
                            foods: [],
                          );

                          await storeProvider.createOrUpdateStore(
                              store, userId);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Shop created successfully')),
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddFoodPage(storeId: store.id),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creating shop: $e')),
                          );
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(120, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
