import 'package:audoria/utils/firebase_helpers.dart';
import 'package:flutter/material.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF030303),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, size: 30, color: Colors.white),
        ),

        backgroundColor: Colors.transparent,
        title: Text(
          'Audoria',
          style: TextStyle(color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () => logout(context),
              icon: Icon(Icons.logout, size: 30, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
