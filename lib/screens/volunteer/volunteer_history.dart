// volunteer_history.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:ui';

class VolunteerHistory extends StatefulWidget {
  final String volunteerId;

  const VolunteerHistory({Key? key, required this.volunteerId})
    : super(key: key);

  @override
  _VolunteerHistoryState createState() => _VolunteerHistoryState();
}

class _VolunteerHistoryState extends State<VolunteerHistory> {
  String _filter = 'All'; // All, Collected, Delivered

  String _displayFilterText() {
    switch (_filter) {
      case 'Collected':
        return 'Filter: Collected';
      case 'Delivered':
        return 'Filter: Delivered';
      default:
        return 'Filter: All';
    }
  }

  Color _statusColor(bool isCollected, bool isDelivered) {
    if (isCollected && !isDelivered) {
      return Colors.amber.shade700;
    } else if (isCollected && isDelivered) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _statusText(bool isCollected, bool isDelivered) {
    if (isCollected && !isDelivered) return 'Collected';
    if (isCollected && isDelivered) return 'Delivered';
    return '';
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                  letterSpacing: 0.2,
                  shadows: const [
                    Shadow(
                      color: Colors.black12,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              setState(() => _filter = val);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Collected', child: Text('Collected')),
              PopupMenuItem(value: 'Delivered', child: Text('Delivered')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
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
                    _displayFilterText(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFullImagePopup(String imageUrl) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black54,
                      child: const Icon(Icons.close, color: Colors.white),
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

  Future<void> _showMedicinePopup(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final medQuantity =
        data['MedQuantity']?.toString() ??
        data['MedQunatity']?.toString() ??
        'N/A';
    final isDelivered = data['isDelivered'] == true;

    await showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 48,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data['MedImgUrl'] != null)
                      GestureDetector(
                        onTap: () =>
                            _showFullImagePopup(data['MedImgUrl'].toString()),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['MedImgUrl'],
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _popupTextRow('Medicine Name', data['MedName']),
                    _popupTextRow('Expiry Date', data['MedExpiry']),
                    _popupTextRow('Quantity', medQuantity),
                    _popupTextRow('Donor Name', data['DonorName']),
                    _popupTextRow('Donor Phone', data['DonorPhone']),
                    _popupTextRow('Donor Email', data['DonorEmail']),
                    _popupTextRow('Donation Address', data['MedicineAddr']),
                    _popupTextRow(
                      'Collected Date',
                      data['CollectedDate'] != null
                          ? (data['CollectedDate'] is Timestamp
                                ? DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(data['CollectedDate'].toDate())
                                : data['CollectedDate'].toString())
                          : '',
                    ),
                    _popupTextRow('Deliver To', data['DeliverTo']),
                    _popupTextRow(
                      'Delivered Date',
                      data['DeliverDate'] != null
                          ? (data['DeliverDate'] is Timestamp
                                ? DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(data['DeliverDate'].toDate())
                                : data['DeliverDate'].toString())
                          : '',
                    ),
                    const SizedBox(height: 16),
                    // REPLACE the existing Deliver button with this:
                    if (!isDelivered)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          // Open organisations list popup to choose where to deliver
                          Navigator.of(
                            context,
                          ).pop(); // close the medicine popup (so organisations popup sits on clean background)
                          await _showOrganisationsPicker(doc);
                        },
                        child: const Text('Deliver Medicine'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showOrganisationsPicker(DocumentSnapshot historyDoc) async {
    final historyData = historyDoc.data() as Map<String, dynamic>? ?? {};
    // Get medicine fields from history doc
    final medName = historyData['MedName'] ?? '';
    final medExpiry = historyData['MedExpiry'] ?? '';
    final medImg = historyData['MedImgUrl'] ?? '';
    final medAddr = historyData['MedicineAddr'] ?? '';
    final medQty =
        historyData['MedQuantity'] ?? historyData['MedQunatity'] ?? 0;
    final collectedDate = historyData['CollectedDate'] ?? '';
    final donorName = historyData['DonorName'] ?? '';
    final donorPhone = historyData['DonorPhone'] ?? '';
    final donorEmail = historyData['DonorEmail'] ?? '';
    final donorLoc = historyData['DonorLoc'];
    final subColId =
        historyData['subCollectionDocID'] ??
        historyData['subCollectionDocId'] ??
        '';

    // Fetch volunteer info once (we'll need to write volunteer details into Recieved doc)
    final volunteerSnap = await FirebaseFirestore.instance
        .collection('volunteers')
        .doc(widget.volunteerId)
        .get();
    final volunteerData = volunteerSnap.exists
        ? (volunteerSnap.data() as Map<String, dynamic>)
        : {};
    final volunteerName = volunteerData['name'] ?? '';
    final volunteerPhone = volunteerData['phone'] ?? '';
    final volunteerOrg = volunteerData['work_org'] ?? '';
    final volunteerEmail = volunteerData['email'] ?? '';
    final volunteerDocId = widget.volunteerId;
    // ✅ Get volunteer’s live location
    Position volunteerPosition;
    try {
      volunteerPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to get location: $e")));
      return;
    }

    final volunteerLat = volunteerPosition.latitude;
    final volunteerLng = volunteerPosition.longitude;
    // Show organisations selection dialog (stateful inside)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? selectedOrgDocId;
        Map<String, dynamic>? selectedOrgData;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top row: close icon
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 12.0,
                          right: 12.0,
                          left: 12.0,
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.close,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Heading
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text(
                            'Available Organisations to Delivery',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Organisations list (scrollable)
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Organisations')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final orgDocs = snapshot.data!.docs;
                            if (orgDocs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No organisations available.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              );
                            }

                            // ✅ Compute distance for each org
                            List<Map<String, dynamic>> orgList = orgDocs.map((
                              doc,
                            ) {
                              final data =
                                  doc.data() as Map<String, dynamic>? ?? {};
                              final orgLoc = data['org_location'];
                              double? distance;
                              if (orgLoc != null) {
                                distance = Geolocator.distanceBetween(
                                  volunteerLat,
                                  volunteerLng,
                                  orgLoc.latitude,
                                  orgLoc.longitude,
                                );
                              }
                              return {
                                'doc': doc,
                                'data': data,
                                'distance': distance ?? double.infinity,
                              };
                            }).toList();

                            // ✅ Sort by distance
                            orgList.sort(
                              (a, b) => a['distance'].compareTo(b['distance']),
                            );

                            // ✅ Mark top 3 as nearer
                            for (int i = 0; i < orgList.length; i++) {
                              orgList[i]['isNearer'] = i < 3;
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: orgList.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final doc =
                                    orgList[i]['doc'] as DocumentSnapshot;
                                final d =
                                    orgList[i]['data'] as Map<String, dynamic>;
                                final isNearer = orgList[i]['isNearer'] == true;

                                final orgName = d['caretaker_org'] ?? 'N/A';
                                final caretakerName =
                                    d['caretaker_name'] ?? 'N/A';
                                final caretakerPhone =
                                    d['caretaker_phone']?.toString() ?? 'N/A';
                                final orgAddress = d['org_address'] ?? 'N/A';
                                final docId = doc.id;
                                final isSelected = selectedOrgDocId == docId;

                                return GestureDetector(
                                  onTap: () {
                                    setStateSB(() {
                                      if (isSelected) {
                                        selectedOrgDocId = null;
                                        selectedOrgData = null;
                                      } else {
                                        selectedOrgDocId = docId;
                                        selectedOrgData = d;
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.teal.shade50
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.teal
                                            : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // circle
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.teal
                                                  : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? Colors.teal
                                                : Colors.white,
                                          ),
                                          child: isSelected
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Organisation Name: $orgName',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isNearer)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 2.0,
                                                  ),
                                                  child: Text(
                                                    "Nearer to you",
                                                    style: TextStyle(
                                                      color: Colors.teal,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Caretaker Name: $caretakerName',
                                              ),
                                              Text(
                                                'Caretaker Phone No.: $caretakerPhone',
                                              ),
                                              Text(
                                                'Organisation Address: $orgAddress',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Deliver Here button area (only show when one selected)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: selectedOrgDocId == null
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      key: ValueKey(selectedOrgDocId),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ), // full width, taller button
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        elevation: 6,
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor:
                                            Colors.white, // text color white
                                      ),
                                      onPressed: () async {
                                        // confirmation dialog
                                        final orgDisplayName =
                                            selectedOrgData?['caretaker_org'] ??
                                            'the organisation';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) {
                                            return BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 6,
                                                sigmaY: 6,
                                              ),
                                              child: Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                insetPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 40,
                                                      vertical: 80,
                                                    ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Align(
                                                        alignment:
                                                            Alignment.topRight,
                                                        child: InkWell(
                                                          onTap: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(false),
                                                          child: CircleAvatar(
                                                            radius: 16,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: Icon(
                                                              Icons.close,
                                                              color: Colors
                                                                  .red
                                                                  .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Do you want to Deliver this medicine at $orgDisplayName?',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 18,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .red
                                                                      .shade200,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              elevation: 4,
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        12,
                                                                  ),
                                                            ),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(false),
                                                            child: const Text(
                                                              'No',
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .green
                                                                      .shade300,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              elevation: 4,
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        12,
                                                                  ),
                                                            ),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(true),
                                                            child: const Text(
                                                              'Deliver',
                                                            ),
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

                                        if (confirm != true) {
                                          // cancelled
                                          return;
                                        }

                                        // Proceed with writes:
                                        try {
                                          // 1) Add to caretaker's Recieved subcollection
                                          final caretakerId =
                                              selectedOrgData?['caretakerId'];
                                          if (caretakerId != null &&
                                              caretakerId
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty) {
                                            final receivedRef =
                                                FirebaseFirestore.instance
                                                    .collection('caretakers')
                                                    .doc(
                                                      caretakerId
                                                          .toString()
                                                          .trim(),
                                                    )
                                                    .collection('Recieved');

                                            final now = DateTime.now();
                                            final deliveredDate =
                                                "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

                                            await receivedRef.add({
                                              "MedicineName": medName,
                                              "MedicineExpiry": medExpiry,
                                              "MedicineImage": medImg,
                                              "MedicineAddress": medAddr,
                                              "MedicineQuantity": medQty,
                                              "CollectedDt": collectedDate,
                                              "DonorIdentity": donorName,
                                              "DonorPhoneNum": donorPhone,
                                              "DonorEmailID": donorEmail,
                                              "MedicineLoc": donorLoc,
                                              "DeliveredDate": deliveredDate,
                                              "subCollecId": subColId,
                                              "volunteerName": volunteerName,
                                              "volunteerPhone": volunteerPhone,
                                              "volunteerOrg": volunteerOrg,
                                              "volunteerEmail": volunteerEmail,
                                              "volunteerDocId": volunteerDocId,
                                              "isVerified": false,
                                              "isSafe": false,
                                              "isDanger": false,
                                            });

                                            // 2) Update the history doc of volunteer (deliver fields + caretaker info)
                                            final volHistoryRef =
                                                FirebaseFirestore.instance
                                                    .collection('volunteers')
                                                    .doc(widget.volunteerId)
                                                    .collection('history')
                                                    .doc(historyDoc.id);

                                            await volHistoryRef.update({
                                              "DeliverDate": deliveredDate,
                                              "DeliverTo":
                                                  selectedOrgData?['caretaker_org'] ??
                                                  '',
                                              "isDelivered": true,

                                              // ✅ newly added caretaker details
                                              "care_name":
                                                  selectedOrgData?['caretaker_name'] ??
                                                  '',
                                              "caretaker_phone_no":
                                                  selectedOrgData?['caretaker_phone'] ??
                                                  '',
                                              "care_email":
                                                  selectedOrgData?['caretaker_email'] ??
                                                  '',
                                            });

                                            // 2.5) Update in Global Medicines + Donor's subcollection
                                            try {
                                              final currentHistorySnap =
                                                  await volHistoryRef.get();
                                              final rawSubCol = currentHistorySnap
                                                  .data()?['subCollectionDocID'];
                                              final subColId = rawSubCol
                                                  ?.toString()
                                                  .trim();

                                              if (subColId != null &&
                                                  subColId.isNotEmpty) {
                                                final medQuery =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('Medicines')
                                                        .where(
                                                          'subcollectionDocid',
                                                          isEqualTo: subColId,
                                                        )
                                                        .get();

                                                if (medQuery.docs.isNotEmpty) {
                                                  final medDoc =
                                                      medQuery.docs.first;
                                                  final donorIdRaw = medDoc
                                                      .data()['DonorId'];
                                                  final donorId = donorIdRaw
                                                      ?.toString()
                                                      .trim();

                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('Medicines')
                                                      .doc(medDoc.id)
                                                      .update({
                                                        "isDelivered": true,
                                                        "organisation_name":
                                                            selectedOrgData?['caretaker_org'] ??
                                                            '',
                                                        "caretaker_identity":
                                                            selectedOrgData?['caretaker_name'] ??
                                                            '',
                                                        "caretaker_doc_Id":
                                                            selectedOrgData?['caretakerId'] ??
                                                            '',
                                                      });

                                                  if (donorId != null &&
                                                      donorId.isNotEmpty) {
                                                    final donorMedDocRef =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'donors',
                                                            )
                                                            .doc(donorId)
                                                            .collection(
                                                              'medicines',
                                                            )
                                                            .doc(subColId);

                                                    final donorMedSnap =
                                                        await donorMedDocRef
                                                            .get();
                                                    if (donorMedSnap.exists) {
                                                      await donorMedDocRef.update({
                                                        "delivered_status":
                                                            true,
                                                        "isDelivered": true,
                                                        "delivered_to_org_name":
                                                            selectedOrgData?['caretaker_org'] ??
                                                            '',
                                                        "organisation_caretaker_name":
                                                            selectedOrgData?['caretaker_name'] ??
                                                            '',
                                                        "caretaker_phone_no":
                                                            selectedOrgData?['caretaker_phone'] ??
                                                            '',
                                                        "caretaker_mail":
                                                            selectedOrgData?['caretaker_email'] ??
                                                            '',
                                                        "organisation_address":
                                                            selectedOrgData?['org_address'] ??
                                                            '',
                                                      });
                                                    }
                                                  }
                                                }
                                              }
                                            } catch (e) {
                                              print(
                                                "⚠️ Error updating donor's medicine doc: $e",
                                              );
                                            }

                                            Navigator.of(context).pop();

                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (BuildContext dialogContext) {
                                                Future.delayed(
                                                  const Duration(
                                                    milliseconds: 2500,
                                                  ),
                                                  () {
                                                    if (Navigator.canPop(
                                                      dialogContext,
                                                    )) {
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop();
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
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    insetPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 60,
                                                          vertical: 150,
                                                        ),
                                                    child: SizedBox(
                                                      height: 160,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 36,
                                                            backgroundColor:
                                                                Colors.green,
                                                            child: const Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.white,
                                                              size: 36,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          const Text(
                                                            "Medicine Has been Delivered",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );

                                            await Future.delayed(
                                              const Duration(
                                                milliseconds: 2500,
                                              ),
                                            );
                                            if (Navigator.canPop(context))
                                              Navigator.of(context).pop();
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Caretaker id missing for selected organisation',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error during deliver: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        "Deliver Here",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // 🔵 Locate Organisation button (newly added)
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.navigation_outlined,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        "Locate Organisation",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          // ✅ Fetch volunteer’s current live location
                                          final position =
                                              await Geolocator.getCurrentPosition(
                                                locationSettings:
                                                    const LocationSettings(
                                                      accuracy:
                                                          LocationAccuracy.high,
                                                    ),
                                              );

                                          // ✅ Get organisation’s stored location
                                          final GeoPoint? orgLoc =
                                              selectedOrgData?['org_location'];
                                          if (orgLoc == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Organisation location unavailable",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final startLat = position.latitude;
                                          final startLng = position.longitude;
                                          final destLat = orgLoc.latitude;
                                          final destLng = orgLoc.longitude;

                                          // ✅ Open Google Maps directions
                                          final url =
                                              'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$destLat,$destLng&travelmode=driving';

                                          if (await canLaunchUrl(
                                            Uri.parse(url),
                                          )) {
                                            await launchUrl(
                                              Uri.parse(url),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Could not open Google Maps",
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
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

  Widget _popupTextRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final medName = data['MedName']?.toString() ?? 'Unknown';
    final medExpiry = data['MedExpiry']?.toString() ?? 'N/A';
    final medQuantity =
        data['MedQuantity']?.toString() ??
        data['MedQunatity']?.toString() ??
        'N/A';
    final isCollected = data['isCollected'] == true;
    final isDelivered = data['isDelivered'] == true;
    final status = _statusText(isCollected, isDelivered);
    final statusColor = _statusColor(isCollected, isDelivered);

    return InkWell(
      onTap: () => _showMedicinePopup(doc),
      child: Card(
        elevation: 6,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                medName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Expiry Date:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                medExpiry,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Medicine Quantity:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                medQuantity,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Spacer(),
                  if (status.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('volunteers')
                .doc(widget.volunteerId)
                .collection('history')
                .orderBy('CollectedDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final isCollected = data['isCollected'] == true;
                final isDelivered = data['isDelivered'] == true;

                if (_filter == 'Collected') {
                  return isCollected && !isDelivered;
                } else if (_filter == 'Delivered') {
                  return isCollected && isDelivered;
                }
                return true;
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No history items.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  return _buildCard(filteredDocs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
