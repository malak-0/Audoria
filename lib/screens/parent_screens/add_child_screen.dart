import 'package:audoria/utils/child_signup_helper.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:lottie/lottie.dart';

class AddChildScreen extends StatefulWidget {
  final String username;

  const AddChildScreen({super.key, this.username = "username"});

  @override
  _AddChildScreenState createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  bool _showBox = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ChildSignupHelper _childSignupHelper = ChildSignupHelper();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

    Future<void> _createChildAccount() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      return;
    }

    if (_passwordController.text.length < 6) {
      print('Password must be at least 6 characters long');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final childUid = await _childSignupHelper.createChildAccount(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      age: _ageController.text.isEmpty ? null : _ageController.text,
      grade: _gradeController.text.isEmpty ? null : _gradeController.text,
      school: _schoolController.text.isEmpty ? null : _schoolController.text,
      );
    print('Child account created successfully, navigating to QR screen...');
    
    NavigationHelper.replaceWith(context, "parent_qr", arguments:{'childUid': childUid});

    } catch (e) {
      print('Failed to create child account: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _gradeController.clear();
    _schoolController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👤 Username
              Row(
                children: [
                  const Icon(Icons.person_pin, size: 50),
                  const SizedBox(width: 8),
                  CustomText.username(widget.username),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  CustomText.username("Welcome from Audoria!"),
                  const SizedBox(height: 10),
                  CustomText.body(
                    "Now you’ve got a parent account,\ngreat role ! you have to add at least \none child to start.",
                  ),
                  const SizedBox(height: 25),

                  Center(
                    child: _showBox
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Lottie.asset(
                                    'assets/animations/childInfo.json',
                                    width: 70,
                                  ),
                                  const SizedBox(width: 8),
                                  CustomText.subtitle('Child Info'),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTextField("Child Name*", controller: _nameController),
                                    const SizedBox(height: 5),
                                    _buildTextField("Email*", controller: _emailController, keyboardType: TextInputType.emailAddress),
                                    const SizedBox(height: 5),
                                    _buildTextField("Password*", controller: _passwordController, isPassword: true),
                                    const SizedBox(height: 5),
                                    _buildTextField("Age", controller: _ageController, isNumber: true),
                                    const SizedBox(height: 5),
                                    _buildTextField("Grade", controller: _gradeController, isNumber: true),
                                    const SizedBox(height: 5),
                                    _buildTextField("School", controller: _schoolController),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              Center(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: textColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 25,
                                      horizontal: 100,
                                    ),
                                  ),
                                  onPressed: _createChildAccount,
                                  child: const Text('Create Child Account'),
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: () {
                                setState(() {
                                    _showBox = true;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 50.0),
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  color: textColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Lottie.asset(
                                        'assets/animations/addChild.json',
                                        width: 50,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    CustomText.subtitle('Add Child'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label,{
    TextEditingController? controller,
    bool isNumber = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number :keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: bgColor, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
