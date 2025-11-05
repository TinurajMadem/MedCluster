import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class VolunteerProfileScreen extends StatefulWidget {
  final String volunteerId;
  final Function(String name, String phone)? onProfileUpdated;

  const VolunteerProfileScreen({
    Key? key,
    required this.volunteerId,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  _VolunteerProfileScreenState createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? volunteerName;
  String? volunteerEmail;
  String? volunteerPhone;
  String? volunteerOrg;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVolunteerDetails();
  }

  Future<void> fetchVolunteerDetails() async {
    try {
      final docSnapshot = await _firestore
          .collection('volunteers')
          .doc(widget.volunteerId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        setState(() {
          volunteerName = data?['name'];
          volunteerEmail = data?['email'];
          volunteerPhone = data?['phone']?.toString();
          volunteerOrg = data?['work_org'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Volunteer not found for ID: ${widget.volunteerId}");
      }
    } catch (e) {
      print("Error fetching volunteer details: $e");
      setState(() => isLoading = false);
    }
  }

  void logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Show Edit Popup
  Future<Map<String, String>?> _showEditPopup() async {
    final nameController = TextEditingController(text: volunteerName ?? '');
    final phoneController = TextEditingController(text: volunteerPhone ?? '');

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "Phone (10 digits)",
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        final newPhone = phoneController.text.trim();

                        // Validation
                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Name cannot be empty"),
                            ),
                          );
                          return;
                        }
                        if (newPhone.length != 10 ||
                            int.tryParse(newPhone) == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Phone must be exactly 10 digits long",
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          // Update Firestore
                          await _firestore
                              .collection('volunteers')
                              .doc(widget.volunteerId)
                              .update({'name': newName, 'phone': newPhone});

                          // Update local state
                          setState(() {
                            volunteerName = newName;
                            volunteerPhone = newPhone;
                          });

                          // Propagate update to parent (VolunteerDashboard)
                          if (widget.onProfileUpdated != null) {
                            widget.onProfileUpdated!(newName, newPhone);
                          }

                          Navigator.pop(context, {
                            'name': newName,
                            'phone': newPhone,
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Profile updated successfully ✅"),
                            ),
                          );
                        } catch (e) {
                          print("Error updating profile: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to update profile"),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        "Apply Changes",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Loading...",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Volunteer Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Volunteer Info
                  buildInfoRow("Volunteer Name:", volunteerName),
                  buildInfoRow("Volunteer Phone Number:", volunteerPhone),
                  buildInfoRow("Volunteer Email:", volunteerEmail),
                  buildInfoRow("Working for:", volunteerOrg),

                  const SizedBox(height: 40),

                  // Edit Profile Button
                  ElevatedButton(
                    onPressed: () async {
                      await _showEditPopup();
                      // After popup closes, setState already updates local info
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      backgroundColor: Colors.teal.shade600,
                      elevation: 4,
                    ),
                    child: const Text(
                      "Edit Profile",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: () => logout(context),
                    icon: const Icon(
                      Icons.power_settings_new,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      backgroundColor: Colors.redAccent.shade200,
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
