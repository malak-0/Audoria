import 'package:audoria/utils.dart';
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
                                  // border: Border.all(color: const Color.fromARGB(255, 252, 251, 251), width: 2),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTextField("Name"),
                                    const SizedBox(height: 10),
                                    _buildTextField("Age", isNumber: true),
                                    const SizedBox(height: 10),
                                    _buildTextField("Grade", isNumber: true),
                                    const SizedBox(height: 10),
                                    _buildTextField("School"),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

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
                                  onPressed: () {},
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
                                        'assets/animations/AddChildScreen.json',
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
                    // : ElevatedButton(
                    //     onPressed: () {
                    //       setState(() {
                    //         _showBox = true;
                    //       });
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: textColor.withValues(alpha: 0.01),

                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(35),
                    //       ),
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 50,
                    //         vertical: 50,
                    //       ),
                    //     ),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.center,
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         CircleAvatar(
                    //           backgroundColor: Colors.white,
                    //           child: Lottie.asset(
                    //             'assets/animations/AddChildScreen.json',
                    //             width: 50,
                    //           ),
                    //         ),
                    //         const SizedBox(height: 10),
                    //         CustomText.subtitle('Add Child'),
                    //       ],
                    //     ),
                    //   ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {bool isNumber = false}) {
    return TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
