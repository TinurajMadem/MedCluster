import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerPickup extends StatefulWidget {
  final String volunteerId;
  final String volunteerName;

  const VolunteerPickup({
    Key? key,
    required this.volunteerId,
    required this.volunteerName,
  }) : super(key: key);

  @override
  State<VolunteerPickup> createState() => _VolunteerPickupState();
}

class _VolunteerPickupState extends State<VolunteerPickup> {
  Position? _currentPosition;
  String? _errorMessage;
  bool _showLocationBar = false;
  String? _savedClusterId; // stores previously assigned cluster
  bool _isLoadingSavedCluster = true; // to show loading when restoring

  // Track whether user clicked fetch (so we can show initial message)
  bool _hasFetchedOnce = false;
  bool _hasUncollectedMedicines =
      false; // ✅ Track if any medicines left to collect

  Future<void> _fetchLocation() async {
    if (_hasUncollectedMedicines) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already have assigned medicines. Collect them first.",
          ),
        ),
      );
      return;
    }
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = "Location permissions are denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              "Location permissions are permanently denied. Please enable them in settings.";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _errorMessage = null;
        _showLocationBar = true;
        _hasFetchedOnce = true; // user has fetched at least once
      });

      // Run clustering & assignment after obtaining location
      await _clusterAndAssign(position);

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showLocationBar = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch location: $e";
      });
    }
  }

  Future<void> _clusterAndAssign(Position volunteerPos) async {
    try {
      final medicinesQuery = await FirebaseFirestore.instance
          .collection('Medicines')
          .where('isCollected', isEqualTo: false)
          .where('isAssigned', isEqualTo: false)
          .get();

      final docs = medicinesQuery.docs;
      final nearby = <QueryDocumentSnapshot>[];

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final donorLoc = data['DonorLocation'];
        if (donorLoc is GeoPoint) {
          final double d = Geolocator.distanceBetween(
            volunteerPos.latitude,
            volunteerPos.longitude,
            donorLoc.latitude,
            donorLoc.longitude,
          );
          if (d <= 1500.0) {
            nearby.add(doc);
          }
        }
      }

      if (nearby.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No nearby medicines within 1.5 km.")),
        );
        return;
      }

      final clusterId =
          "cluster_${widget.volunteerId}_${DateTime.now().millisecondsSinceEpoch}";

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final doc in nearby) {
        final ref = FirebaseFirestore.instance
            .collection('Medicines')
            .doc(doc.id);
        batch.update(ref, {
          'isAssigned': true,
          'assignedTo': widget.volunteerId,
          'clusterId': clusterId,
        });
      }

      final volunteerRef = FirebaseFirestore.instance
          .collection('volunteers')
          .doc(widget.volunteerId);
      batch.set(volunteerRef, {
        'assignedClusterId': clusterId,
      }, SetOptions(merge: true));

      await batch.commit();
      // ✅ Save cluster ID locally for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'assignedClusterId_${widget.volunteerId}',
        clusterId,
      );

      setState(() {
        _savedClusterId = clusterId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${nearby.length} medicine(s) assigned to you."),
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during clustering/assignment: $e")),
      );
    }
  }

  Future<void> _openGoogleMaps(GeoPoint donorLocation) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final double startLat = position.latitude;
      final double startLng = position.longitude;
      final double destLat = donorLocation.latitude;
      final double destLng = donorLocation.longitude;

      final Uri googleMapsAppUrl = Uri.parse(
        "google.navigation:q=$destLat,$destLng&mode=d",
      );
      final Uri googleMapsWebUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$destLat,$destLng&travelmode=driving",
      );

      if (await canLaunchUrl(googleMapsAppUrl)) {
        await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsWebUrl)) {
        await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening Google Maps: $e")));
    }
  }

  void _showMedicineDetails(Map<String, dynamic> medicine) {
    String donatedDate = "N/A";
    if (medicine['DateofDonation'] != null) {
      final timestamp = medicine['DateofDonation'];
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        donatedDate =
            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      }
    }

    GeoPoint? donorLoc = medicine['DonorLocation'];
    String medicineAddr =
        medicine['MedicineAddr'] ?? "Not provided"; // 👈 ADDED

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: InteractiveViewer(
                                            child: Image.network(
                                              medicine['MedicineImageURL'] ??
                                                  '',
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.image_not_supported,
                                                    size: 100,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 40,
                                          right: 20,
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.white,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.black87,
                                                size: 22,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Image.network(
                              medicine['MedicineImageURL'] ?? '',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          medicine['MedicineName'] ?? "Unknown Medicine",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Quantity: ${medicine['MedicineQuantity'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Expiry: ${medicine['MedicineExpiry'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Donor: ${medicine['DonorName'] ?? 'Anonymous'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Donated Date: $donatedDate",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Donor Email: ${medicine['DonorEmail'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Donor Phone: ${medicine['DonorPhoneNumber'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (donorLoc != null)
                          Text(
                            "Donor Location: (${donorLoc.latitude}, ${donorLoc.longitude})",
                            style: const TextStyle(fontSize: 16),
                          ),
                        // 👇 ADDED Donation Address DISPLAY
                        Text(
                          "Donation Address: $medicineAddr",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final medicineId = medicine['id'];
                                    final donorId = medicine['DonorId'];
                                    final subcollectionDocId =
                                        medicine['subcollectionDocid'];

                                    await FirebaseFirestore.instance
                                        .collection('Medicines')
                                        .doc(medicineId)
                                        .update({
                                          'isAssigned': true,
                                          'isCollected': true,
                                        });

                                    if (donorId != null &&
                                        subcollectionDocId != null) {
                                      final donorDocRef = FirebaseFirestore
                                          .instance
                                          .collection('donors')
                                          .doc(donorId.toString().trim())
                                          .collection('medicines')
                                          .doc(
                                            subcollectionDocId
                                                .toString()
                                                .trim(),
                                          );

                                      final donorDocSnap = await donorDocRef
                                          .get();
                                      if (donorDocSnap.exists) {
                                        await donorDocRef.update({
                                          'volunteer_collected':
                                              widget.volunteerName,
                                          'isCollected': true,
                                        });
                                      }
                                    }

                                    final medSnap = await FirebaseFirestore
                                        .instance
                                        .collection('Medicines')
                                        .doc(medicineId)
                                        .get();

                                    if (medSnap.exists) {
                                      final medData =
                                          medSnap.data()
                                              as Map<String, dynamic>;
                                      final now = DateTime.now();
                                      final formattedDate =
                                          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

                                      await FirebaseFirestore.instance
                                          .collection('volunteers')
                                          .doc(widget.volunteerId)
                                          .collection('history')
                                          .add({
                                            'MedImgUrl':
                                                medData['MedicineImageURL'] ??
                                                '',
                                            'MedName':
                                                medData['MedicineName'] ?? '',
                                            'MedExpiry':
                                                medData['MedicineExpiry'] ?? '',
                                            'MedQuantity':
                                                medData['MedicineQuantity'] ??
                                                0,
                                            'DonorName':
                                                medData['DonorName'] ?? '',
                                            'DonorPhone':
                                                medData['DonorPhoneNumber'] ??
                                                '',
                                            'DonorEmail':
                                                medData['DonorEmail'] ?? '',
                                            'DonorLoc':
                                                medData['DonorLocation'],
                                            'MedicineAddr':
                                                medData['MedicineAddr'] ??
                                                '', // 👈 ADDED storing in history
                                            'CollectedDate': formattedDate,
                                            'isDelivered': false,
                                            'isCollected': true,
                                            'DeliverTo': "",
                                            'DeliverDate': "",
                                            'subCollectionDocID':
                                                medData['subcollectionDocid'] ??
                                                '',
                                          });
                                    }
                                    setState(() {});
                                    final remaining = await FirebaseFirestore
                                        .instance
                                        .collection('Medicines')
                                        .where(
                                          'clusterId',
                                          isEqualTo: _savedClusterId,
                                        )
                                        .where('isCollected', isEqualTo: false)
                                        .get();

                                    if (remaining.docs.isEmpty) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.remove(
                                        'assignedClusterId',
                                      ); // ✅ Clear cluster since all done

                                      setState(() {
                                        _savedClusterId = null;
                                        _hasFetchedOnce = false;
                                        _hasUncollectedMedicines = false;
                                      });
                                    }

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        Future.delayed(
                                          const Duration(seconds: 4),
                                          () {
                                            if (Navigator.canPop(context)) {
                                              Navigator.pop(context);
                                            }
                                          },
                                        );

                                        return BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 6,
                                            sigmaY: 6,
                                          ),
                                          child: Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            insetPadding: const EdgeInsets.all(
                                              40,
                                            ),
                                            child: Container(
                                              width: 200,
                                              height: 200,
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  CircleAvatar(
                                                    radius: 36,
                                                    backgroundColor:
                                                        Colors.green,
                                                    child: Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 50,
                                                    ),
                                                  ),
                                                  SizedBox(height: 20),
                                                  Text(
                                                    "Thank you, Medicine Collected\nand will be reflected in History Tab after some time",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ).then((_) {
                                      if (Navigator.canPop(context))
                                        Navigator.pop(context);
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Error collecting medicine: $e",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 30,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 6,
                                ),
                                child: const Text(
                                  "Collect Medicine",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: donorLoc == null
                                    ? null
                                    : () => _openGoogleMaps(donorLoc),
                                icon: const Icon(Icons.location_on_outlined),
                                label: const Text(
                                  "Locate",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  backgroundColor: Colors.teal.shade600,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 30,
                                  ),
                                  elevation: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color.fromRGBO(188, 49, 49, 1),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close,
                        color: Color.fromARGB(221, 0, 0, 0),
                        size: 25,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCluster();
  }

  Future<void> _loadSavedCluster() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCluster = prefs.getString(
      'assignedClusterId_${widget.volunteerId}',
    );

    if (savedCluster != null) {
      final medsSnap = await FirebaseFirestore.instance
          .collection('Medicines')
          .where('clusterId', isEqualTo: savedCluster)
          .where('assignedTo', isEqualTo: widget.volunteerId)
          .where('isCollected', isEqualTo: false)
          .get();

      setState(() {
        _savedClusterId = savedCluster;
        _hasUncollectedMedicines = medsSnap.docs.isNotEmpty;
        _hasFetchedOnce = medsSnap.docs.isNotEmpty;
        _isLoadingSavedCluster = false;
      });
    } else {
      setState(() {
        _isLoadingSavedCluster = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch medicines based on stored or current assigned cluster
    final assignedQuery = FirebaseFirestore.instance
        .collection('Medicines')
        .where('assignedTo', isEqualTo: widget.volunteerId)
        .where('isCollected', isEqualTo: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Volunteer Pickup",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _hasUncollectedMedicines ? null : _fetchLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 24.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 6,
              ),
              child: const Text(
                "Fetch Medicines",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 100, 86, 255),
                ),
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          else if (_showLocationBar)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Medicines fetched successfully",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // If user hasn't fetched yet, don't attach assignedQuery; show initial message
              stream: _hasFetchedOnce ? assignedQuery : null,
              builder: (context, snapshot) {
                // If not fetched yet, prompt user (initial state)
                if (!_hasFetchedOnce) {
                  return const Center(
                    child: Text(
                      "Click Fetch Medcines Button to see the available medicines for pickup",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error fetching medicines"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final medicines = snapshot.data!.docs;

                if (medicines.isEmpty) {
                  return const Center(
                    child: Text(
                      "No medicines available for pickup.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicineData =
                        medicines[index].data() as Map<String, dynamic>;
                    final medicine = {
                      'id': medicines[index].id,
                      'DonorId': medicineData['DonorId'],
                      ...medicineData,
                    };

                    return GestureDetector(
                      onTap: () => _showMedicineDetails(medicine),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Medicine: ${medicine['MedicineName'] ?? 'Unknown'}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Quantity: ${medicine['MedicineQuantity'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Donor: ${medicine['DonorName'] ?? 'Anonymous'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
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
            ),
          ),
        ],
      ),
    );
  }
}
