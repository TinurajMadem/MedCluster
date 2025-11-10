// caretaker_validated.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CaretakerValidated extends StatefulWidget {
  // Pass the caretaker's document id from callers
  final String caretakerId;

  const CaretakerValidated({Key? key, required this.caretakerId})
    : super(key: key);

  @override
  State<CaretakerValidated> createState() => _CaretakerValidatedState();
}

class _CaretakerValidatedState extends State<CaretakerValidated> {
  String _filter = 'All'; // All | Safe | Unsafe

  String get _filterDisplayText {
    switch (_filter) {
      case 'Safe':
        return 'Filter: Safe';
      case 'Unsafe':
        return 'Filter: Unsafe';
      default:
        return 'Filter: All';
    }
  }

  Query _buildQuery() {
    final base = FirebaseFirestore.instance
        .collection('caretakers')
        .doc(widget.caretakerId)
        .collection('Recieved')
        .where('isVerified', isEqualTo: true);

    if (_filter == 'Safe') {
      return base.where('isSafe', isEqualTo: true);
    } else if (_filter == 'Unsafe') {
      return base.where('isDanger', isEqualTo: true);
    } else {
      return base;
    }
  }

  String _formatPossibleTimestamp(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      final dt = value.toDate();
      return DateFormat('dd/MM/yyyy').format(dt);
    }
    // might be a string already
    try {
      final parsed = DateTime.parse(value.toString());
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      // fallback to raw string
      return value.toString();
    }
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Validated Medicines',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          // Filter button at right
          PopupMenuButton<String>(
            onSelected: (val) {
              setState(() {
                _filter = val;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Safe', child: Text('Safe')),
              PopupMenuItem(value: 'Unsafe', child: Text('Unsafe')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _filterDisplayText,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingCard(Map<String, dynamic> data, DocumentSnapshot doc) {
    final medName = data['MedicineName']?.toString() ?? 'Unknown';
    final medQty = data['MedicineQuantity']?.toString() ?? 'N/A';
    final medExpiry = _formatPossibleTimestamp(data['MedicineExpiry'] ?? '');

    final bool isSafe = data['isSafe'] == true;
    final bool isDanger = data['isDanger'] == true;

    // ✅ Dynamic background color logic
    final Color bgColor = isSafe
        ? Colors.green.shade50
        : (isDanger ? Colors.red.shade50 : Colors.white);

    return InkWell(
      onTap: () => _openDetailPopup(data, doc),
      child: Card(
        elevation: 6,
        color: bgColor, // ✅ Set the background color dynamically
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medicine Name:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                medName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Medicine Quantity:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                medQty,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Medicine Expiry Date:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                medExpiry.isNotEmpty ? medExpiry : 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openImageFull(String imageUrl) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                // image container
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.black,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 300,
                          height: 300,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                ),
                // close button top-right
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, color: Colors.red.shade700),
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

  void _openDetailPopup(Map<String, dynamic> data, DocumentSnapshot doc) {
    final imageUrl = data['MedicineImage']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 40.0,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // close cross
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.close, color: Colors.red.shade700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // image (clickable)
                    if (imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openImageFull(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 180,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text(
                          'Medicine Name: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          data['MedicineName'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Medicine Expiry Date: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          data['MedicineExpiry'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    _detailRow(
                      'Medicine Quantity',
                      data['MedicineQuantity']?.toString() ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _detailRow(
                      'Donor Name',
                      data['DonorIdentity'] ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _detailRow(
                      'Donor Email',
                      data['DonorEmailID'] ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    _detailRow(
                      'Donor Phone',
                      data['DonorPhoneNum']?.toString() ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    _detailRow(
                      'Received Date',
                      _formatPossibleTimestamp(
                        data['DeliveredDate'] ?? data['CollectedDt'],
                      ),
                      valueStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    _detailRow(
                      'Medicine Address',
                      data['MedicineAddress'] ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    _detailRow(
                      'Volunteer Name',
                      data['volunteerName'] ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _detailRow(
                      'Volunteer Email',
                      data['volunteerEmail'] ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    _detailRow(
                      'Volunteer Organisation',
                      data['volunteerOrg'] ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    _detailRow(
                      'Volunteer Phone',
                      data['volunteerPhone']?.toString() ?? 'N/A',
                      valueStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().trim().isNotEmpty == true
                  ? value.toString()
                  : 'N/A',
              style:
                  valueStyle ??
                  const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Scaffold(
      body: Column(
        children: [
          _topBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Colors.grey.shade300, thickness: 1),
          ),
          const SizedBox(height: 8),

          // Expanded area with stream builder (cards scrollable)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  // Show an empty state but keep list scrollable (SingleChildScrollView)
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Trigger StreamBuilder refresh by setState (no-op)
                      setState(() {});
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 40),
                        Center(
                          child: Text(
                            'No validated medicines.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 300),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // refresh by setState, stream will deliver latest snapshot
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      return _floatingCard(data, doc);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
