import 'package:audoria/utils/routes.dart';
import 'package:flutter/material.dart';

void navigateTo(BuildContext context, String routeName) {
  final routeBuilder = appRoutes[routeName];
  if (routeBuilder != null) {
    Navigator.push(context, MaterialPageRoute(builder: routeBuilder));
  } else {
    print('Route not found: $routeName');
  }
}
