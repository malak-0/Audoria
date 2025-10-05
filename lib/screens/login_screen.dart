import 'package:audoria/custom_widgets/custom_button.dart';
import 'package:audoria/custom_widgets/custom_text.dart';
import 'package:audoria/custom_widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            SizedBox(height: 40),
            CustomText.username("Sign Up"),
            Form(
              child: Column(
                children: [
                  SizedBox(height: 60),
                  CustomTextField(
                    controller: usernameController,
                    hintText: "Username",
                    icon: Icons.person,
                  ),
                  SizedBox(height: 20),

                  CustomTextField(
                    controller: emailController,
                    hintText: "Email",
                    icon: Icons.email,
                  ),
                  SizedBox(height: 20),

                  CustomTextField(
                    controller: passwordController,
                    hintText: "Password",
                    icon: Icons.lock,
                    isObscureText: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            CustomButton(
              destinationPage: Placeholder(),
              text: "Sign up as a parent",
              radius: 20,
              color: Colors.black.value,
              textColor: Colors.white.value,
            ),
            SizedBox(height: 15),
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
            SizedBox(height: 15),
            CustomButton(
              destinationPage: Placeholder(),
              text: "Scan QR Code",
              radius: 20,
              color: Colors.white.value,
              textColor: Colors.black.value,
            ),
          ],
        ),
      ),
    );
  }
}
