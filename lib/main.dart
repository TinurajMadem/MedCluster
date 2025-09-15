import 'package:flutter/material.dart';
import 'screens/volunteer/volunteer_dashboard.dart';

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
      home: const HomeScreen(), // default landing page
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
        child: ElevatedButton(
          onPressed: () {
            // Navigate to VolunteerDashboard
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VolunteerDashboard(
                  volunteerId: 'vol_001',
                  volunteerName: 'Siva',
                ),
              ),
            );
          },
          child: const Text('Go to Volunteer Dashboard'),
        ),
      ),
    );
  }
}
