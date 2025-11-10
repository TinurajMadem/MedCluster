import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'dart:ui';

class CaretakerProfileScreen extends StatefulWidget {
  final String caretakerId;
  const CaretakerProfileScreen({Key? key, required this.caretakerId})
    : super(key: key);

  @override
  State<CaretakerProfileScreen> createState() => _CaretakerProfileScreenState();
}

class _CaretakerProfileScreenState extends State<CaretakerProfileScreen> {
  Map<String, dynamic>? caretakerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCaretakerData();
  }

  Future<void> _fetchCaretakerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('caretakers')
          .doc(widget.caretakerId)
          .get();

      if (doc.exists) {
        setState(() {
          caretakerData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          caretakerData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching caretaker data: $e");
      setState(() {
        caretakerData = null;
        isLoading = false;
      });
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(
      text: caretakerData?['name'] ?? '',
    );
    final phoneController = TextEditingController(
      text: caretakerData?['phone']?.toString() ?? '',
    );
    final orgController = TextEditingController(
      text: caretakerData?['care_org'] ?? '',
    );
    final addressController = TextEditingController(
      text: caretakerData?['care_address'] ?? '',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isUpdating = false;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.close,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Edit Caretaker Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C6E49),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🟢 Name
                      TextField(
                        controller: nameController,
                        maxLength: 15,
                        decoration: InputDecoration(
                          labelText: "Enter Caretaker Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 🟢 Phone
                      TextField(
                        controller: phoneController,
                        maxLength: 10,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Enter Caretaker Phone Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 🟢 Organisation Name
                      TextField(
                        controller: orgController,
                        decoration: InputDecoration(
                          labelText: "Enter Organisation Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 🟢 Organisation Address
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: "Enter Organisation Address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🟢 Update Button
                      ElevatedButton(
                        onPressed: isUpdating
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final phone = phoneController.text.trim();
                                final org = orgController.text.trim();
                                final address = addressController.text.trim();

                                if (name.isEmpty ||
                                    phone.isEmpty ||
                                    org.isEmpty ||
                                    address.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please fill all required fields",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (phone.length != 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Phone must be 10 digits"),
                                    ),
                                  );
                                  return;
                                }

                                setStateSB(() => isUpdating = true);

                                try {
                                  // ✅ Step 1: Update caretaker document
                                  await FirebaseFirestore.instance
                                      .collection('caretakers')
                                      .doc(widget.caretakerId)
                                      .update({
                                        'name': name,
                                        'phone': int.tryParse(phone) ?? 0,
                                        'care_org': org,
                                        'care_address': address,
                                      });

                                  // ✅ Step 2: Update Organisation document
                                  final orgQuery = await FirebaseFirestore
                                      .instance
                                      .collection('Organisations')
                                      .where(
                                        'caretakerId',
                                        isEqualTo: widget.caretakerId,
                                      )
                                      .get();

                                  for (final doc in orgQuery.docs) {
                                    await doc.reference.update({
                                      'caretaker_name': name,
                                      'caretaker_phone':
                                          int.tryParse(phone) ?? 0,
                                      'caretaker_org': org,
                                      'org_address': address,
                                    });
                                  }

                                  // ✅ Step 3: Process 1 - Update Volunteers’ history
                                  final receivedSnap = await FirebaseFirestore
                                      .instance
                                      .collection('caretakers')
                                      .doc(widget.caretakerId)
                                      .collection('Recieved')
                                      .get();

                                  for (final medDoc in receivedSnap.docs) {
                                    final medData =
                                        medDoc.data() as Map<String, dynamic>;
                                    final volunteerId =
                                        medData['volunteerDocId'];

                                    if (volunteerId != null &&
                                        volunteerId.toString().isNotEmpty) {
                                      final historySnap =
                                          await FirebaseFirestore.instance
                                              .collection('volunteers')
                                              .doc(volunteerId)
                                              .collection('history')
                                              .where(
                                                'organisation_ID',
                                                isEqualTo: widget.caretakerId,
                                              )
                                              .get();

                                      for (final histDoc in historySnap.docs) {
                                        await histDoc.reference.update({
                                          'care_name': name,
                                          'caretaker_phone_no': phone,
                                          'DeliverTo': org,
                                        });
                                      }
                                    }
                                  }

                                  // ✅ Step 4: Process 2 - Update Donors’ medicine subcollection
                                  for (final medDoc in receivedSnap.docs) {
                                    final medData =
                                        medDoc.data() as Map<String, dynamic>;
                                    final subColId = medData['subCollecId']
                                        ?.toString();

                                    if (subColId == null ||
                                        subColId.trim().isEmpty)
                                      continue;

                                    final medQuery = await FirebaseFirestore
                                        .instance
                                        .collection('Medicines')
                                        .where(
                                          'subcollectionDocid',
                                          isEqualTo: subColId,
                                        )
                                        .get();

                                    if (medQuery.docs.isNotEmpty) {
                                      final medGlobalDoc = medQuery.docs.first;
                                      final donorId = medGlobalDoc['DonorId']
                                          ?.toString();

                                      if (donorId != null &&
                                          donorId.isNotEmpty) {
                                        final donorMedRef = FirebaseFirestore
                                            .instance
                                            .collection('donors')
                                            .doc(donorId)
                                            .collection('medicines')
                                            .doc(subColId);

                                        final donorMedSnap = await donorMedRef
                                            .get();

                                        if (donorMedSnap.exists) {
                                          await donorMedRef.update({
                                            'organisation_caretaker_name': name,
                                            'caretaker_phone_no': phone,
                                            'delivered_to_org_name': org,
                                            'organisation_address': address,
                                          });
                                        }
                                      }
                                    }
                                  }

                                  if (mounted) {
                                    Navigator.of(ctx).pop();
                                    await _fetchCaretakerData(); // refresh
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Profile and related data updated successfully!",
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint(
                                    "⚠️ Error updating profile and related docs: $e",
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error: ${e.toString()}"),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setStateSB(() => isUpdating = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Update Profile",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : caretakerData == null
            ? const Center(
                child: Text(
                  "Caretaker data not found.",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Caretaker Profile",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C6E49),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildDetailRow('Name', caretakerData?['name'] ?? ''),
                    _buildDetailRow('Email ID', caretakerData?['email'] ?? ''),
                    _buildDetailRow(
                      'Phone Number',
                      caretakerData?['phone']?.toString() ?? '',
                    ),
                    _buildDetailRow(
                      'Organisation Name',
                      caretakerData?['care_org'] ?? '',
                    ),
                    _buildDetailRow(
                      'Organisation Address',
                      caretakerData?['care_address'] ?? '',
                    ),
                    const SizedBox(height: 40),

                    // 🟢 Edit Profile Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        onPressed: _showEditProfileDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔴 Logout Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(
                          Icons.power_settings_new_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
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
