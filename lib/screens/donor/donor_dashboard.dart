import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'donor_history.dart';
import 'donor_profile.dart';

class DonorDashboard extends StatefulWidget {
  final String donorId;

  const DonorDashboard({super.key, required this.donorId});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  int _selectedIndex = 0;
  String? donorName;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _medicineAddrController =
      TextEditingController(); // ✅ NEW FIELD

  // Image picker fields
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  String? _tempMedicineDocId;
  bool _isUploading = false;
  bool _isFetchingLocation = false; // ✅ NEW STATE for location button

  late Stream<DocumentSnapshot> _donorStream;

  @override
  void initState() {
    super.initState();

    _donorStream = FirebaseFirestore.instance
        .collection('donors')
        .doc(widget.donorId)
        .snapshots();

    _donorStream.listen((doc) {
      if (doc.exists) {
        setState(() {
          donorName = doc['name'] ?? 'Donor';
          _nameController.text = doc['name'] ?? '';
          _phoneController.text = doc['phone']?.toString() ?? '';
          _emailController.text = doc['email'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _medicineController.dispose();
    _quantityController.dispose();
    _expiryController.dispose();
    _locationController.dispose();
    _medicineAddrController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enable location services."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location permission denied."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permissions are permanently denied. Please enable them in settings.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      setState(() {
        _locationController.text =
            "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching location: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () async {
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                Navigator.pop(context, picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () async {
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                );
                Navigator.pop(context, picked);
              },
            ),
          ],
        ),
      ),
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _uploadedImageUrl = null;
        _isUploading = true;
      });

      String? url = await _uploadImage();
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (url != null) {
          _uploadedImageUrl = url;
          final donorRef = FirebaseFirestore.instance
              .collection('donors')
              .doc(widget.donorId);
          final medicinesRef = donorRef.collection('medicines');
          final tempDoc = await medicinesRef.add({
            'image_url': _uploadedImageUrl,
            'created_at': FieldValue.serverTimestamp(),
            'isCollected': false,
            'isDelivered': false,
          });
          _tempMedicineDocId = tempDoc.id;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image uploaded successfully! ✅"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _selectedImage = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image upload failed!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dq7lbzajo/image/upload'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );
      request.fields['upload_preset'] = 'medcluster_unsigned';
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      if (response.statusCode == 200) {
        var data = jsonDecode(responseData.body);
        return data['secure_url'];
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload failed: $e');
      return null;
    }
  }

  Future<void> _deleteImage() async {
    if (_tempMedicineDocId != null) {
      final donorRef = FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId);
      final medicinesRef = donorRef.collection('medicines');

      await medicinesRef.doc(_tempMedicineDocId).delete();

      setState(() {
        _uploadedImageUrl = null;
        _selectedImage = null;
        _tempMedicineDocId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image deleted successfully."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildDonationForm() {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFEAF6FB),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Donation Form",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2874A6),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration("Enter the donor name"),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDecoration(
                      "Enter donor phone number",
                    ).copyWith(counterText: ""),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";
                      if (value.length != 10) return "Must be 10 digits";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration("Enter Email of Donor"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _medicineController,
                    decoration: _inputDecoration("Enter Medicine name"),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("Enter quantity of medicine"),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";
                      if (int.tryParse(value) == null)
                        return "Enter a valid number";
                      if (int.parse(value) <= 0)
                        return "Must be greater than 0";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expiryController,
                    readOnly: true,
                    onTap: _pickExpiryDate,
                    decoration:
                        _inputDecoration(
                          "Enter the expiry of above medicine",
                        ).copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_month,
                            color: Colors.blue,
                          ),
                        ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    readOnly: false,
                    decoration:
                        _inputDecoration(
                          "Enter the Location (Lat, Lon) of donor",
                        ).copyWith(
                          suffixIcon: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                          ),
                        ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return "Required";
                      final parts = value.split(",");
                      if (parts.length != 2) return "Enter in format: lat, lon";
                      final lat = double.tryParse(parts[0].trim());
                      final lon = double.tryParse(parts[1].trim());
                      if (lat == null || lon == null)
                        return "Latitude and Longitude must be numbers";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // ✅ NEW Get Location Button
                  ElevatedButton(
                    onPressed: _isFetchingLocation ? null : _fetchLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2874A6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                    ),
                    child: Text(
                      _isFetchingLocation
                          ? "Fetching Location..."
                          : "Get Location",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _medicineAddrController,
                    maxLength: 120,
                    decoration: _inputDecoration(
                      "Enter Medicine Address",
                    ).copyWith(counterText: ""),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return "Required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerBox(),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _donateMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2874A6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                    ),
                    icon: const Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Donate",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // (Remaining donate logic, image upload, and bottom navigation code stay unchanged)
  // ——— OMITTED FOR LENGTH ———
  // ✅ You can keep your same rest of the file content exactly as before.

  Future<void> _donateMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedImageUrl == null || _tempMedicineDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload an image first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final donorRef = FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId);
      final medicinesRef = donorRef.collection('medicines');

      DateTime expiryDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(_expiryController.text);
      List<String> latLon = _locationController.text.split(',');
      double latitude = double.parse(latLon[0].trim());
      double longitude = double.parse(latLon[1].trim());

      final medicineData = {
        'medicine_name': _medicineController.text.trim(),
        'medicine_expiry_date': Timestamp.fromDate(expiryDate),
        'donor_name': _nameController.text.trim(),
        'donated_date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'donor_phone_number': _phoneController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'location': GeoPoint(latitude, longitude),
        'MedicineAddr': _medicineAddrController.text.trim(), // ✅ NEW FIELD
        'volunteer_collected': '',
        'delivered_to_org_name': '',
        'organisation_caretaker_name': '',
        'delivered_status': false,
        'image_url': _uploadedImageUrl,
        'isCollected': false,
        'isDelivered': false,
      };

      // 1️⃣ Update donor's subcollection
      await medicinesRef.doc(_tempMedicineDocId).update(medicineData);

      // 2️⃣ Add into global Medicines collection and save globalDocId
      final globalMedicineData = {
        'DateofDonation': FieldValue.serverTimestamp(),
        'DonorId': widget.donorId,
        'DonorName': _nameController.text.trim(),
        'DonorPhoneNumber': _phoneController.text.trim(),
        'DonorEmail': _emailController.text.trim(),
        'MedicineName': _medicineController.text.trim(),
        'MedicineQuantity': int.parse(_quantityController.text.trim()),
        'MedicineImageURL': _uploadedImageUrl,
        'DonorLocation': GeoPoint(latitude, longitude),
        'MedicineAddr': _medicineAddrController.text.trim(), // ✅ NEW FIELD
        'MedicineExpiry': DateFormat('dd/MM/yyyy').format(expiryDate),
        'isDelivered': false,
        'isCollected': false,
        'isAssigned': false,
        'subcollectionDocid': _tempMedicineDocId,
      };

      final globalDocRef = await FirebaseFirestore.instance
          .collection('Medicines')
          .add(globalMedicineData);

      // 3️⃣ Save globalDocId in donor subcollection for later deletion
      await medicinesRef.doc(_tempMedicineDocId).update({
        'globalMedicineDocId': globalDocRef.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donation submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _medicineController.clear();
      _quantityController.clear();
      _expiryController.clear();
      _locationController.clear();
      _medicineAddrController.clear(); // ✅ NEW FIELD CLEAR
      setState(() {
        _selectedImage = null;
        _uploadedImageUrl = null;
        _tempMedicineDocId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildImagePreview() {
    if (_uploadedImageUrl != null) {
      return Column(
        children: [
          const SizedBox(height: 10),
          Image.network(_uploadedImageUrl!, height: 150, fit: BoxFit.cover),
          const SizedBox(height: 6),
          const Text(
            "Image uploaded ✅",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else if (_selectedImage != null) {
      return Column(
        children: [
          const SizedBox(height: 10),
          Image.file(
            File(_selectedImage!.path),
            height: 150,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 6),
          const Text(
            "Uploading...",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildImagePickerBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload Medicine Image",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton(
              onPressed: _isUploading || _uploadedImageUrl != null
                  ? null
                  : _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2874A6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Select", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            if (_uploadedImageUrl != null)
              ElevatedButton(
                onPressed: _deleteImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildImagePreview(),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDonationForm();
      case 1:
        return DonorHistory(donorId: widget.donorId);
      case 2:
        return DonorProfile(donorId: widget.donorId);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 30,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(color: Color(0xFF5DADE2)),
            child: Column(
              children: [
                const Text(
                  'MedCluster Donor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  donorName == null ? "Welcome!! ..." : "Welcome!! $donorName",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "A pill unused is a life refused — donate it.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2874A6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Donate"),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
