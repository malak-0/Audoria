import 'package:audoria/custom_widgets/custom_text.dart';
import 'package:audoria/utils.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrParent extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25),
            Row(children: [Image.asset('assets/images/profile.png',width: 50,height: 50),SizedBox(width: 10,),CustomText.username('username')],),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center ,
                children: [
                SizedBox(height: 45),
              CustomText.body('Now you‘ve successfully created your \nfirst child account , scan the QR code \non Audoria in your child phone to let \nhim start learning journy !'),
              SizedBox(height: 45),
              CustomText.subtitle('scan QR code from  child phone'),
              SizedBox(height: 20),
              Container(width: 300,height: 300,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: textColor.withValues(alpha: 0.1),),
                  child: Center(
                    child: QrImageView(
                      data: '',
                      size: 260,
                      version: QrVersions.auto,
                      eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ), 
                      ),
                  ),
                          
                ),
              
              ],),
            )
            ],
        ),
      ),
    );
  }}