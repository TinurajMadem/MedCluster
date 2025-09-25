import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DonorHistory extends StatelessWidget {
  final String donorId; // pass donorId from dashboard

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
        return donatedDate; // fallback if stored as plain string
      }
    } catch (e) {
      return donatedDate.toString();
    }
    return "-";
  }

  // Function to show full image popup with zoom and pan
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
                  panEnabled: true, // allow panning
                  scaleEnabled: true, // allow zooming
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
                            Text(
                              "Medicine Name: ${docData['medicine_name'] ?? '-'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Text(
                              "Medicine Quantity: ${docData['quantity'] ?? '-'}",
                            ),
                            Text("Donor Name: ${docData['donor_name'] ?? '-'}"),
                            Text(
                              "Donated Date: ${_formatDate(docData['donated_date'])}",
                            ),
                            Text(
                              "Medicine Expiry Date: ${_formatDate(docData['medicine_expiry_date'])}",
                            ),
                            Text(
                              "Delivery Status: "
                              "${docData['delivered_status'] == true ? "Delivered" : "Pending"}",
                            ),
                            Text(
                              "Assigned Volunteer: ${docData['volunteer_collected'] ?? '-'}",
                            ),
                            Text(
                              "Delivered to Caretaker: ${docData['organisation_caretaker_name'] ?? '-'}",
                            ),
                            Text(
                              "Caretaker Organisation: ${docData['delivered_to_org_name'] ?? '-'}",
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.delete),
                              label: const Text("Delete Donation"),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: const Text(
                                        "This Donation will be deleted and cannot be undone.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('donors')
                                      .doc(donorId)
                                      .collection('medicines')
                                      .doc(docId)
                                      .delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: InkWell(
                          onTap: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
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
                              Text(
                                "Medicine Name: ${data['medicine_name'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Medicine Quantity: ${data['quantity'] ?? '-'}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Donor Name: ${data['donor_name'] ?? '-'}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Donated Date: ${_formatDate(data['donated_date'])}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text(
                                    "Delivery Status: ",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Icon(
                                    (data['delivered_status'] == true)
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: (data['delivered_status'] == true)
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ],
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

// Custom painter for wavy underline
class WavyUnderlinePainter extends CustomPainter {
  final Color color;
  WavyUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    const waveHeight = 4.0;
    const waveLength = 20.0;
    path.moveTo(0, 0);
    for (double x = 0; x <= size.width; x += waveLength) {
      path.quadraticBezierTo(
        x + waveLength / 4,
        waveHeight,
        x + waveLength / 2,
        0,
      );
      path.quadraticBezierTo(
        x + 3 * waveLength / 4,
        -waveHeight,
        x + waveLength,
        0,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
