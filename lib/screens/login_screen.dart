import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/firebase_helpers.dart';
import 'package:audoria/utils/ui_helpers.dart';
import 'package:audoria/widgets/custom_button.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await login(
        context,
        emailController.text.trim(),
        passwordController.text.trim(),
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
                  CustomText.username("Login"),
                  SizedBox(height: 70),
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
                      return null;
                    },
                  ),
                  SizedBox(height: 40),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(
                          text: "Login",
                          radius: 20,
                          color: textColor.value,
                          textColor: Colors.white.value,
                          onClick: _handleLogin,
                        ),
                  SizedBox(height: 25),

                  TextButton(
                    onPressed: () {
                      navigatePush(context, "register");
                    },
                    child: Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
