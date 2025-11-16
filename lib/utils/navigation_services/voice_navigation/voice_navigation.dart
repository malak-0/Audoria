import 'package:audoria/routes.dart';
import 'package:flutter/material.dart';

void navigateTo(BuildContext context, String routeName, {Object? arguments}){
  final routeBuilder = appRoutes[routeName];
  if (routeBuilder != null) {
    Navigator.push(context, MaterialPageRoute(builder: routeBuilder));
  } else {
    print('Route not found: $routeName');
  }
}
