import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart'; // Import RegistrationScreen
import '../donor/donor_dashboard.dart'; // Import DonorDashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = "user"; // default role
  bool _obscurePassword = true; // For password toggle

  late AnimationController _registerButtonController;
  late Animation<double> _registerButtonAnimation;

  @override
  void initState() {
    super.initState();
    _registerButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _registerButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_registerButtonController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Name
                Text(
                  "MedCluster",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Login text
                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Enter Email Address",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password with toggle
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Enter the password",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Role selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Role:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: "user",
                      label: Text("Donor"),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment<String>(
                      value: "volunteer",
                      label: Text("Volunteer"),
                      icon: Icon(Icons.volunteer_activism),
                    ),
                    ButtonSegment<String>(
                      value: "doctor",
                      label: Text("CareTaker"),
                      icon: Icon(Icons.medical_services),
                    ),
                  ],
                  selected: <String>{_selectedRole},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      String email = _emailController.text.trim();
                      String password = _passwordController.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter email and password"),
                          ),
                        );
                        return;
                      }

                      String collection = '';
                      if (_selectedRole == 'user') collection = 'donors';
                      if (_selectedRole == 'volunteer')
                        collection = 'volunteers';
                      if (_selectedRole == 'doctor') collection = 'caretakers';

                      try {
                        final querySnapshot = await FirebaseFirestore.instance
                            .collection(collection)
                            .where('email', isEqualTo: email)
                            .where('password', isEqualTo: password)
                            .get();

                        if (!mounted) return;

                        if (querySnapshot.docs.isNotEmpty) {
                          final doc = querySnapshot.docs.first;
                          final donorId = doc.id;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Login successful as $_selectedRole",
                              ),
                            ),
                          );

                          // Navigate to DonorDashboard with donorId
                          if (_selectedRole == 'user') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DonorDashboard(donorId: donorId),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Invalid credentials for selected role",
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot Password
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New User? Register Button with animation
                ScaleTransition(
                  scale: _registerButtonAnimation,
                  child: GestureDetector(
                    onTapDown: (_) => _registerButtonController.forward(),
                    onTapUp: (_) => _registerButtonController.reverse(),
                    onTapCancel: () => _registerButtonController.reverse(),
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const RegistrationScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade700),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade700.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        "New User? Register",
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
