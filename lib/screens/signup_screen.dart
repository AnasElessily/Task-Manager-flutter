import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final studentIdController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? gender;
  String? level;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    studentIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = User(
        fullName: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        studentId: studentIdController.text.trim(),
        gender: gender ?? "Not specified",
        level: level != null ? int.parse(level!) : null,
        password: passwordController.text.trim(),
      );

      await DBHelper.insertUser(user);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Success")),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email already exists")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Join Us",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign up to start managing your tasks",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Full Name is required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "University Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Email is required";
                      if (!RegExp(r'^\d+@stud\.fci-cu\.edu\.eg$').hasMatch(value.trim())) {
                        return "Invalid FCI email format";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: studentIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Student ID",
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Student ID is required";
                      final email = emailController.text.trim();
                      final emailId = email.split("@").first;
                      if (emailId != value.trim()) return "Student ID must match email ID";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Academic Level",
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    value: level,
                    items: ["1", "2", "3", "4"].map((lvl) => DropdownMenuItem(value: lvl, child: Text("Level $lvl"))).toList(),
                    onChanged: (value) => setState(() => level = value),
                    validator: (value) => value == null ? "Academic level is required" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: RadioListTile<String>(
                          title: const Text("Male"),
                          value: "Male",
                          groupValue: gender,
                          onChanged: (value) => setState(() => gender = value),
                          contentPadding: EdgeInsets.zero,
                        )),
                        Expanded(child: RadioListTile<String>(
                          title: const Text("Female"),
                          value: "Female",
                          groupValue: gender,
                          onChanged: (value) => setState(() => gender = value),
                          contentPadding: EdgeInsets.zero,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Password is required";
                      if (value.length < 8) return "Password must be at least 8 characters";
                      if (!RegExp(r'\d').hasMatch(value)) return "Password must contain a number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Confirm Password is required";
                      if (value != passwordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      child: _isLoading 
                          ? const SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            ) 
                          : const Text("Sign Up", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
