// lib/screens/caretaker/caretaker_dashboard.dart
import 'package:flutter/material.dart';

class CaretakerDashboard extends StatefulWidget {
  final String caretakerName;
  final String caretakerId;
  const CaretakerDashboard({
    Key? key,
    required this.caretakerName,
    required this.caretakerId,
  }) : super(key: key);

  @override
  _CaretakerDashboardState createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<CaretakerDashboard> {
  int _selectedIndex = 0;

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 36, bottom: 22),
      decoration: const BoxDecoration(
        color: Color(0xFF6A9C78), // header green shade for caretakers
      ),
      child: Column(
        children: [
          const Text(
            'MedCluster Caretaker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome!! ${widget.caretakerName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Caring hearts, stronger communities',
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

  Widget _buildVerifyPlaceholder() {
    return const Center(
      child: Text(
        'Verification tasks will appear here',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildReceivedPlaceholder() {
    return const Center(
      child: Text(
        'Received items will appear here',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return const Center(
      child: Text(
        'Profile will appear here',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _bodyForIndex() {
    switch (_selectedIndex) {
      case 0:
        return _buildVerifyPlaceholder();
      case 1:
        return _buildReceivedPlaceholder();
      case 2:
        return _buildProfilePlaceholder();
      default:
        return _buildVerifyPlaceholder();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4E7A57),
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
          _navItem(icon: Icons.verified, label: 'Verify', index: 0),
          _navItem(icon: Icons.inbox, label: 'Received', index: 1),
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
    // simple validity check: show message if caretakerId missing
    if (widget.caretakerId.trim().isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Invalid caretaker. Please login with a Caretaker account.',
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
