import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final String subTitle;
  final Widget filePage;

  const CustomListTile({
    super.key,
    required this.title,
    required this.subTitle,
    required this.filePage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => filePage),
      ),
      child: ListTile(
        leading: Image.asset('assets/images/file.png', width: 50, height: 50),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xff030303),
            fontSize: 24,
            fontWeight: FontWeight.w500,
            fontFamily: 'inter',
          ),
        ),
        subtitle: Text(
          subTitle,
          style: TextStyle(
            color: const Color.fromARGB(255, 112, 112, 112),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'inter',
          ),
        ),
      ),
    );
  }
}
