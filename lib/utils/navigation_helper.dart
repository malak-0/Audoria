import 'package:flutter/material.dart';

class NavigationHelper {
  static void goTo(
    BuildContext context, 
    String routeName, 
    {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void replaceWith(
    BuildContext context, 
    String routeName, 
    {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void goToAndRemoveAll(
    BuildContext context, 
    String routeName, 
    {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false, arguments: arguments);
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
