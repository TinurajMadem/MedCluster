import 'package:flutter/material.dart';
import 'volunteer_pickup.dart';
import 'volunteer_profile.dart';
import 'volunteer_history.dart';

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

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  int _selectedIndex = 1;
  late String currentVolunteerName;

  @override
  void initState() {
    super.initState();
    currentVolunteerName = widget.volunteerName;
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 36, bottom: 22),
      decoration: const BoxDecoration(color: Color(0xFF4EA1D3)),
      child: Column(
        children: [
          const Text(
            'MedCluster Volunteer',
            style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome!! $currentVolunteerName',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Helping hands for a healthier community',
            style: TextStyle(
              color: Colors.black,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupsScreen() {
    return VolunteerPickup(
      volunteerId: widget.volunteerId,
      volunteerName: currentVolunteerName,
    );
  }

  Widget _bodyForIndex() {
    switch (_selectedIndex) {
      case 0:
        return _buildPickupsScreen();
      case 1:
        return VolunteerHistory(volunteerId: widget.volunteerId);
      case 2:
        return VolunteerProfileScreen(
          volunteerId: widget.volunteerId,
          onProfileUpdated: (updatedName, _) {
            setState(() {
              currentVolunteerName = updatedName;
            });
          },
        );
      default:
        return _buildPickupsScreen();
    }
  }

  Widget _buildBottomNav() {
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
    final selected = _selectedIndex == index;
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
                color: selected ? Colors.black : Colors.black54,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.black54,
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
    if (widget.volunteerId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Invalid volunteer. Please login again.')),
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
