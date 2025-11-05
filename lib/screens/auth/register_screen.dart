import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();

  final _workOrgController = TextEditingController();
  final _volAddressController = TextEditingController();
  final _careOrgController = TextEditingController();
  final _careAddressController = TextEditingController();
  final _donorAddressController = TextEditingController();

  String? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;
  late AnimationController _loginButtonController;
  late Animation<double> _loginButtonAnimation;

  final Logger logger = Logger();

  double? _latitude;
  double? _longitude;
  bool _obscurePassword = true;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(_animationController);

    _loginButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _loginButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_loginButtonController);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _workOrgController.dispose();
    _volAddressController.dispose();
    _careOrgController.dispose();
    _careAddressController.dispose();
    _donorAddressController.dispose();
    _animationController.dispose();
    _loginButtonController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (!mounted) return;
    _latitude = position.latitude;
    _longitude = position.longitude;
    _locationController.text =
        "Lat: ${position.latitude}, Lng: ${position.longitude}";
    logger.i(
      "Latitude: ${position.latitude}, Longitude: ${position.longitude}",
    );
  }

  Future<bool> _emailExists(String email) async {
    final firestore = FirebaseFirestore.instance;

    final donors = await firestore
        .collection("donors")
        .where("email", isEqualTo: email)
        .get();
    if (donors.docs.isNotEmpty) return true;

    final volunteers = await firestore
        .collection("volunteers")
        .where("email", isEqualTo: email)
        .get();
    if (volunteers.docs.isNotEmpty) return true;

    final caretakers = await firestore
        .collection("caretakers")
        .where("email", isEqualTo: email)
        .get();
    if (caretakers.docs.isNotEmpty) return true;

    return false;
  }

  Future<void> _registerUser() async {
    try {
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _selectedRole == null ||
          _locationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields")),
        );
        return;
      }
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fetch your location before registering"),
          ),
        );
        return;
      }

      if (_selectedRole == "Donor" && _donorAddressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter Donor Address")),
        );
        return;
      }
      if (_selectedRole == "CareTaker" &&
          (_careOrgController.text.isEmpty ||
              _careAddressController.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all Caretaker fields")),
        );
        return;
      }

      bool exists = await _emailExists(_emailController.text.trim());
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email already registered")),
        );
        return;
      }

      final firestore = FirebaseFirestore.instance;

      if (_selectedRole == "Donor") {
        await firestore.collection("donors").add({
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": int.tryParse(_phoneController.text) ?? 0,
          "password": _passwordController.text.trim(),
          "donor_address": _donorAddressController.text.trim(),
          "location": _latitude != null && _longitude != null
              ? GeoPoint(_latitude!, _longitude!)
              : null,
        });
      } else if (_selectedRole == "Volunteer") {
        await firestore.collection("volunteers").add({
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": int.tryParse(_phoneController.text) ?? 0,
          "password": _passwordController.text.trim(),
          "work_org": _workOrgController.text.trim(),
          "vol_address": _volAddressController.text.trim(),
          "vol_location": _latitude != null && _longitude != null
              ? GeoPoint(_latitude!, _longitude!)
              : null,
        });
      } else if (_selectedRole == "CareTaker") {
        final caretakerRef = await firestore.collection("caretakers").add({
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": int.tryParse(_phoneController.text) ?? 0,
          "password": _passwordController.text.trim(),
          "care_org": _careOrgController.text.trim(),
          "care_address": _careAddressController.text.trim(),
          "care_location": _latitude != null && _longitude != null
              ? GeoPoint(_latitude!, _longitude!)
              : null,
        });

        // ✅ Add to Global "Organisations" collection
        await firestore.collection("Organisations").add({
          "caretaker_name": _nameController.text.trim(),
          "caretaker_email": _emailController.text.trim(),
          "caretaker_phone": int.tryParse(_phoneController.text) ?? 0,
          "caretaker_org": _careOrgController.text.trim(),
          "org_address": _careAddressController.text.trim(),
          "org_location": _latitude != null && _longitude != null
              ? GeoPoint(_latitude!, _longitude!)
              : null,
          "caretakerId": caretakerRef.id,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful")));
      logger.i("User registered in $_selectedRole collection");

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      logger.e("Error registering user: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "MedCluster",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: 1.5,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Registration",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 30),
              // Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  hintText: 'Select role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Donor', 'Volunteer', 'CareTaker']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              if (_selectedRole == "Volunteer") ...[
                TextField(
                  controller: _workOrgController,
                  decoration: InputDecoration(
                    hintText: 'Enter volunteer organization',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _volAddressController,
                  decoration: InputDecoration(
                    hintText: 'Enter volunteer address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_selectedRole == "CareTaker") ...[
                TextField(
                  controller: _careOrgController,
                  decoration: InputDecoration(
                    hintText: 'Enter Organisation Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _careAddressController,
                  decoration: InputDecoration(
                    hintText: 'Enter Organisation address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Location
              TextFormField(
                controller: _locationController,
                readOnly: false, // ✅ Editable
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide your location';
                  }

                  // ✅ Check if input matches a lat,long pattern (basic validation)
                  final latLongRegex = RegExp(
                    r'^-?\d{1,2}\.\d+,\s*-?\d{1,3}\.\d+$',
                  );
                  if (!latLongRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid latitude,longitude format';
                  }

                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter or view current location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(
                    Icons.location_on,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ "Get Location" Button
              ElevatedButton(
                onPressed: _isFetchingLocation
                    ? null
                    : () async {
                        setState(() => _isFetchingLocation = true);
                        await _getLocation();
                        setState(() => _isFetchingLocation = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                ),
                child: Text(
                  _isFetchingLocation ? "Fetching Location..." : "Get Location",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Donor Address (below location)
              if (_selectedRole == "Donor")
                TextField(
                  controller: _donorAddressController,
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: 'Enter Donor Address (max 50 chars)',
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (_selectedRole == "Donor") const SizedBox(height: 10),

              const SizedBox(height: 30),

              // Register Button
              ScaleTransition(
                scale: _buttonAnimation,
                child: GestureDetector(
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) => _animationController.reverse(),
                  onTapCancel: () => _animationController.reverse(),
                  onTap: _registerUser,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Already User? Login Button
              ScaleTransition(
                scale: _loginButtonAnimation,
                child: GestureDetector(
                  onTapDown: (_) => _loginButtonController.forward(),
                  onTapUp: (_) => _loginButtonController.reverse(),
                  onTapCancel: () => _loginButtonController.reverse(),
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Already user? Login",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
