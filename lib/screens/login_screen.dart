import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'main_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  String? emailError;
  String? passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (emailController.text.trim().isEmpty) {
      setState(() => emailError = "Email is required");
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      setState(() => passwordError = "Password is required");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DBHelper.getUser(
        emailController.text.trim().toLowerCase(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user == null) {
        setState(() {
          emailError = "Email does not exist";
          _isLoading = false;
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(user: user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.toString().contains("wrong_password")) {
        setState(() => passwordError = "Wrong password");
      } else {
        setState(() => emailError = "Login failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Welcome Back",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to manage your tasks",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: emailError,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading 
                          ? const SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            ) 
                          : const Text("Login", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          "Register",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}