import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DonorHistory extends StatelessWidget {
  final String donorId;

  const DonorHistory({super.key, required this.donorId});

  String _formatDate(dynamic donatedDate) {
    if (donatedDate == null) return "-";
    try {
      if (donatedDate is Timestamp) {
        DateTime date = donatedDate.toDate();
        return DateFormat("dd MMM yyyy").format(date);
      } else if (donatedDate is DateTime) {
        return DateFormat("dd MMM yyyy").format(donatedDate);
      } else if (donatedDate is String) {
        return donatedDate;
      }
    } catch (e) {
      return donatedDate.toString();
    }
    return "-";
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text("Failed to load image"));
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const CircleAvatar(
                    radius: 20,
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

  Widget _infoText(String label, String value) {
    Color? valueColor;
    if (label.toLowerCase().contains("status")) {
      if (value.toLowerCase() == "delivered") {
        valueColor = Colors.green;
      } else if (value.toLowerCase() == "pending") {
        valueColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor ?? Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _showDonationDetails(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Donation Details",
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donors')
                  .doc(donorId)
                  .collection('medicines')
                  .doc(docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  });
                  return const SizedBox.shrink();
                }

                final docData = snapshot.data!.data() as Map<String, dynamic>;
                String? globalDocId = docData['globalMedicineDocId'];

                return FutureBuilder<DocumentSnapshot>(
                  future: globalDocId != null
                      ? FirebaseFirestore.instance
                            .collection('Medicines')
                            .doc(globalDocId)
                            .get()
                      : Future.value(null),
                  builder: (context, globalSnapshot) {
                    bool isAssigned = false;
                    if (globalSnapshot.hasData &&
                        globalSnapshot.data != null &&
                        globalSnapshot.data!.exists) {
                      final globalData =
                          globalSnapshot.data!.data() as Map<String, dynamic>;
                      isAssigned = globalData['isAssigned'] == true;
                    }

                    return Dialog(
                      insetPadding: const EdgeInsets.all(20),
                      backgroundColor: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (docData['image_url'] != null)
                                  InkWell(
                                    onTap: () => _showFullImage(
                                      context,
                                      docData['image_url'],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        docData['image_url'],
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Medicine Details",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                _infoText(
                                  "Medicine Name",
                                  docData['medicine_name'] ?? '-',
                                ),
                                _infoText(
                                  "Medicine Quantity",
                                  docData['quantity']?.toString() ?? '-',
                                ),
                                _infoText(
                                  "Donor Name",
                                  docData['donor_name'] ?? '-',
                                ),
                                _infoText(
                                  "Donation Address",
                                  docData['MedicineAddr'] ?? '-',
                                ),
                                _infoText(
                                  "Donated Date",
                                  _formatDate(docData['donated_date']),
                                ),
                                _infoText(
                                  "Medicine Expiry Date",
                                  _formatDate(docData['medicine_expiry_date']),
                                ),
                                _infoText(
                                  "Delivery Status",
                                  docData['delivered_status'] == true
                                      ? "Delivered"
                                      : "Pending",
                                ),
                                _infoText(
                                  "Is Delivered",
                                  docData['isDelivered'] == true ? "Yes" : "No",
                                ),
                                _infoText(
                                  "Is Collected",
                                  docData['isCollected'] == true ? "Yes" : "No",
                                ),
                                _infoText(
                                  "Assigned Volunteer",
                                  docData['volunteer_collected'] ?? '-',
                                ),
                                _infoText(
                                  "Delivered to",
                                  docData['organisation_caretaker_name'] ?? '-',
                                ),
                                _infoText(
                                  "Caretaker Organisation",
                                  docData['delivered_to_org_name'] ?? '-',
                                ),
                                _infoText(
                                  "Caretaker Email",
                                  docData['caretaker_mail'] ?? '-',
                                ),
                                _infoText(
                                  "Organisation Address",
                                  docData['organisation_address'] ?? '-',
                                ),
                                const SizedBox(height: 16),

                                // Delete button + message
                                Center(
                                  child: Column(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.red.shade200,
                                          disabledForegroundColor:
                                              Colors.white70,
                                        ),
                                        icon: const Icon(Icons.delete),
                                        label: const Text("Delete Donation"),
                                        onPressed: isAssigned
                                            ? null
                                            : () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                            "Confirm Delete",
                                                          ),
                                                          content: const Text(
                                                            "This donation will be deleted from both donor and global collections and cannot be undone.",
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(false),
                                                              child: const Text(
                                                                "No",
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(true),
                                                              child: const Text(
                                                                "Yes",
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );

                                                if (confirm == true) {
                                                  final firestore =
                                                      FirebaseFirestore
                                                          .instance;

                                                  final donorDocRef = firestore
                                                      .collection('donors')
                                                      .doc(donorId)
                                                      .collection('medicines')
                                                      .doc(docId);

                                                  await donorDocRef.delete();

                                                  if (globalDocId != null) {
                                                    await firestore
                                                        .collection('Medicines')
                                                        .doc(globalDocId)
                                                        .delete();
                                                  }

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Donation deleted successfully.",
                                                      ),
                                                      backgroundColor:
                                                          Colors.orange,
                                                    ),
                                                  );
                                                }
                                              },
                                      ),
                                      if (isAssigned)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            "This donation has been assigned and cannot be deleted.",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: InkWell(
                              onTap: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(),
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
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                "Previous Donations",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey[800],
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
              Positioned(
                bottom: -4,
                child: CustomPaint(
                  size: const Size(220, 6),
                  painter: WavyUnderlinePainter(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donors')
                  .doc(donorId)
                  .collection('medicines')
                  .orderBy('donated_date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No donations yet.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                final donations = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final doc = donations[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return InkWell(
                      onTap: () => _showDonationDetails(context, doc.id, data),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoText(
                                "Medicine Name",
                                data['medicine_name'] ?? '-',
                              ),
                              _infoText(
                                "Medicine Quantity",
                                data['quantity']?.toString() ?? '-',
                              ),
                              _infoText(
                                "Expiry Date",
                                _formatDate(data['medicine_expiry_date']),
                              ),
                              _infoText(
                                "Status",
                                data['delivered_status'] == true
                                    ? "Delivered"
                                    : "Pending",
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

class WavyUnderlinePainter extends CustomPainter {
  final Color color;
  WavyUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    const waveHeight = 4.0;
    const waveLength = 12.0;

    path.moveTo(0, 0);
    for (double i = 0; i < size.width; i += waveLength) {
      path.relativeQuadraticBezierTo(
        waveLength / 4,
        waveHeight,
        waveLength / 2,
        0,
      );
      path.relativeQuadraticBezierTo(
        waveLength / 4,
        -waveHeight,
        waveLength / 2,
        0,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
