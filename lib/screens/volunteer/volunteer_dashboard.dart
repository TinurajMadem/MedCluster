// lib/screens/volunteer/volunteer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // optional (for time display). Add to pubspec if not present.

class VolunteerDashboard extends StatefulWidget {
  final String volunteerName;
  final String volunteerId;
  const VolunteerDashboard({
    Key? key,
    required this.volunteerName,
    required this.volunteerId,
  }) : super(key: key);

  @override
  _VolunteerDashboardState createState() => _VolunteerDashboardState();
}

class Pickup {
  final String id;
  final String donorName;
  final String medicine;
  final String address;
  final DateTime scheduledAt;
  String status; // Pending, Collected, Verified, Delivered

  Pickup({
    required this.id,
    required this.donorName,
    required this.medicine,
    required this.address,
    required this.scheduledAt,
    this.status = 'Pending',
  });
}

class _VolunteerDashboardState extends State<VolunteerDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _loading = true;
  List<Pickup> _pickups = [];

  @override
  void initState() {
    super.initState();
    // simulate loading from backend
    _loadMockPickups();
  }

  Future<void> _loadMockPickups() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _pickups = [
        Pickup(
          id: 'p1',
          donorName: 'Srinivas Rao',
          medicine: 'Paracetamol — 2 strips',
          address: 'Tadigadapa, Near Temple',
          scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        ),
        Pickup(
          id: 'p2',
          donorName: 'Anita',
          medicine: 'ORS — 1 bottle',
          address: 'Kanuru Main Road',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
        ),
        Pickup(
          id: 'p3',
          donorName: 'Ravi',
          medicine: 'Cough Syrup 100ml',
          address: 'Senior Citizens Forum, Kanuru',
          scheduledAt: DateTime.now().add(const Duration(hours: 5)),
        ),
      ];
      _loading = false;
    });
  }

  // Example: mark pickup collected
  void _updatePickupStatus(String id, String newStatus) {
    setState(() {
      final idx = _pickups.indexWhere((p) => p.id == id);
      if (idx != -1) _pickups[idx].status = newStatus;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
  }

  // show pickup details modal
  void _openPickupDetails(Pickup p) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pickup Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(p.donorName),
                subtitle: const Text('Donor'),
              ),
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: Text(p.medicine),
                subtitle: const Text('Medicine'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(p.address),
                subtitle: Text(
                  'Scheduled at: ${DateFormat.yMMMd().add_jm().format(p.scheduledAt)}',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: p.status == 'Pending'
                          ? () => _updatePickupStatus(p.id, 'Collected')
                          : null,
                      icon: const Icon(Icons.check),
                      label: Text(
                        p.status == 'Pending' ? 'Mark Collected' : 'Collected',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: p.status == 'Collected'
                          ? () => _updatePickupStatus(p.id, 'Verified')
                          : null,
                      icon: const Icon(Icons.verified),
                      label: const Text('Verify'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 36, bottom: 22),
      decoration: const BoxDecoration(
        color: Color(0xFF4EA1D3), // header blue
      ),
      child: Column(
        children: [
          Text(
            'MedCluster Volunteer',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome!! ${widget.volunteerName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Helping hands for a healthier community',
            style: TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inbox, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No assigned pickups yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupsList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pickups.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _pickups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final p = _pickups[idx];
        final statusColor = p.status == 'Pending'
            ? Colors.orange
            : (p.status == 'Collected' ? Colors.blue : Colors.green);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () => _openPickupDetails(p),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue[50],
                    child: const Icon(Icons.local_shipping, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.donorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(p.medicine, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          p.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: p.status == 'Pending'
                            ? () => _updatePickupStatus(p.id, 'Collected')
                            : null,
                        child: const Text('Collect'),
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
  }

  Widget _buildHistoryPlaceholder() {
    return const Center(
      child: Text(
        'History will appear here',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 36,
                child: Icon(Icons.person, size: 36),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.volunteerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Volunteer ID: ${widget.volunteerId}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Assigned clusters'),
              subtitle: const Text('3 clusters'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Availability'),
              subtitle: const Text('Mon - Sat, 9AM - 6PM'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyForIndex() {
    switch (_selectedIndex) {
      case 0:
        return _buildPickupsList();
      case 1:
        return _buildHistoryPlaceholder();
      case 2:
        return _buildProfilePlaceholder();
      default:
        return _buildPickupsList();
    }
  }

  Widget _buildBottomNav() {
    // 3 items: Pickups, History, Profile
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7CB3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.local_shipping, label: 'Pickups', index: 0),
          _navItem(icon: Icons.history, label: 'History', index: 1),
          _navItem(icon: Icons.person, label: 'Profile', index: 2),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 260),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.white70,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // simple validity check: show message if volunteerId missing
    if (widget.volunteerId.trim().isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'Invalid volunteer. Please login with a Volunteer account.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _bodyForIndex()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
