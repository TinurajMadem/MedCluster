import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = "user"; // default role

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

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Enter the password",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Role selection using SegmentedButton
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
                        value: "user", label: Text("Donor"), icon: Icon(Icons.person)),
                    ButtonSegment<String>(
                        value: "volunteer", label: Text("Volunteer"), icon: Icon(Icons.volunteer_activism)),
                    ButtonSegment<String>(
                        value: "doctor", label: Text("CareTaker"), icon: Icon(Icons.medical_services)),
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
                    onPressed: () {
                      debugPrint(
                          "Email: ${_emailController.text}, Role: $_selectedRole");
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Forgot Password Button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ForgotPasswordScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ));
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
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

// Dummy Forgot Password Screen
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: const Center(
        child: Text(
          "Forgot Password Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
