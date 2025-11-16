import 'package:audoria/utils/backend_services/firebase_helpers.dart';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25), // subtle shadow
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4), // shadow below the appbar
          ),
        ],
      ),
      child: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, size: 30, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        title: Text(
          'Audoria',
          style: TextStyle(color: textColor, fontSize: 30),
        ),
        centerTitle: true,
        elevation: 0, // keep AppBar itself shadowless
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () => logout(context),
              icon: Icon(Icons.logout, size: 30, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
