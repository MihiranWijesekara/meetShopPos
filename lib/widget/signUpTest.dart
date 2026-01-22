import 'package:chicken_dilivery/service/auth_service.dart';
import 'package:flutter/material.dart';

class SignUpPageTest extends StatefulWidget {
  const SignUpPageTest({super.key});

  @override
  State<SignUpPageTest> createState() => _SignUpPageTestState();
}

class _SignUpPageTestState extends State<SignUpPageTest> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Username
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Full Name
            TextField(
              controller: fullNameCtrl,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Password
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 50,
              // child: ElevatedButton(
              //   // onPressed: isLoading ? null : signUp,
              //   child: isLoading
              //       ? const CircularProgressIndicator(color: Colors.white)
              //       : const Text("Sign Up"),
              // ),
            ),
          ],
        ),
      ),
    );
  }

  // void signUp() async {
  //   if (usernameCtrl.text.isEmpty ||
  //       fullNameCtrl.text.isEmpty ||
  //       passwordCtrl.text.isEmpty) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("⚠️ All fields required")));
  //     return;
  //   }

  //   setState(() => isLoading = true);
  //   // bool success = await AuthService.signUp(
  //   //   usernameCtrl.text.trim(),
  //   //   fullNameCtrl.text.trim(),
  //   //   passwordCtrl.text.trim(),
  //   // );

  //   if (!mounted) return; // Prevent errors if user leaves screen during loading
  //   setState(() => isLoading = false);

  //   if (success) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("✅ Registered!")));
  //     Navigator.pop(context);
  //   } else {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("❌ Registration Failed")));
  //   }
  // }
}
