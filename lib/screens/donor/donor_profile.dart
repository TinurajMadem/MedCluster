import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- for input formatters
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcluster/screens/auth/login_screen.dart';

class DonorProfile extends StatefulWidget {
  final String donorId; // pass donorId from dashboard
  const DonorProfile({super.key, required this.donorId});

  @override
  State<DonorProfile> createState() => _DonorProfileState();
}

class _DonorProfileState extends State<DonorProfile> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Show edit profile popup
  void _showEditProfilePopup(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _phoneController.text = (data['phone'] != null)
        ? data['phone'].toString()
        : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Phone Number (10 digits)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = _nameController.text.trim();
                        final newPhone = _phoneController.text.trim();

                        if (newName.isEmpty || newPhone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Name and Phone cannot be empty"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (newPhone.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Phone number must be 10 digits"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          await FirebaseFirestore.instance
                              .collection('donors')
                              .doc(widget.donorId)
                              .update({
                                'name': newName,
                                'phone': int.tryParse(newPhone) ?? 0,
                              });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Profile updated successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.of(context).pop(); // close popup
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text("Apply Changes"),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black26,
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No data found"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Heading with dark blue color and dotted underline
              CustomPaint(
                painter: DottedUnderlinePainter(),
                child: const Text(
                  "Donor Profile",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 29, 97, 165), // Dark Blue
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text("Name"),
                subtitle: Text(
                  data['name'] ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              ListTile(
                title: const Text("Email Address"),
                subtitle: Text(
                  data['email'] ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              ListTile(
                title: const Text("Phone Number"),
                subtitle: Text(
                  (data['phone'] != null) ? data['phone'].toString() : '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showEditProfilePopup(data),
                child: const Text("Edit Profile"),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _logout,
                icon: const Icon(Icons.power_settings_new),
                label: const Text("Logout"),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for dotted underline
class DottedUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 4;
    const double dashSpace = 4;
    final paint = Paint()
      ..color = Color(0xFF003366)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height + 4; // 4px below text
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
