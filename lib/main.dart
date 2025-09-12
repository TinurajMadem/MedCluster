import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase Core
import 'screens/auth/register_screen.dart'; // ✅ Ensure correct path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ Initialize Firebase before running app

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedCluster',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RegistrationScreen(), // ✅ Start with Registration
    );
  }
}
