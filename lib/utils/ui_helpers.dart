import 'package:flutter/material.dart';
import 'package:audoria/utils/constants.dart';

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(backgroundColor: iconsColor, content: Text(message)));
}

void navigatePushReplacement(BuildContext context, String routeName) {
  Navigator.pushReplacementNamed(context, routeName);
}

void navigatePush(BuildContext context, String routeName) {
  Navigator.pushNamed(context, routeName);
}
