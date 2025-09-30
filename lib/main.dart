// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/volunteer/volunteer_dashboard.dart';
import 'screens/caretaker/caretaker_dashboard.dart';
import 'screens/donor/donor_dashboard.dart'; // ✅ Added Donor import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedCluster',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MedCluster Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Volunteer
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VolunteerDashboard(
                      volunteerId: 'VOL001',
                      volunteerName: 'Siva',
                    ),
                  ),
                );
              },
              child: const Text('Go to Volunteer Dashboard'),
            ),
            const SizedBox(height: 20),

            // Caretaker
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaretakerDashboard(
                      caretakerId: 'CT001',
                      caretakerName: 'Lisa',
                    ),
                  ),
                );
              },
              child: const Text('Go to Caretaker Dashboard'),
            ),
            const SizedBox(height: 20),

            // Donor ✅
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DonorDashboard(
                      donorId: 'DON001',
                      donorName: 'Ramesh',
                    ),
                  ),
                );
              },
              child: const Text('Go to Donor Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
