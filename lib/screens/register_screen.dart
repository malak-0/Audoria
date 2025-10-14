import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/firebase_helpers.dart';
import 'package:audoria/widgets/custom_button.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await register(
        context,
        emailController.text.trim(),
        passwordController.text.trim(),
        usernameController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 50),
                  CustomText.username("Register"),
                  SizedBox(height: 70),
                  CustomTextField(
                    controller: usernameController,
                    hintText: "Username",
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),

                  CustomTextField(
                    controller: emailController,
                    hintText: "Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),

                  CustomTextField(
                    controller: passwordController,
                    hintText: "Password",
                    icon: Icons.lock,
                    isObscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 40),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(
                          text: "Register as a parent",
                          radius: 20,
                          color: textColor.value,
                          textColor: Colors.white.value,
                          onClick: _handleRegister,
                        ),
                  SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.black87)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "Or as a child",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.black87)),
                    ],
                  ),
                  SizedBox(height: 25),
                  CustomButton(
                    text: "Scan QR Code",
                    radius: 20,
                    color: Colors.white.value,
                    textColor: textColor.value,
                    onClick: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
