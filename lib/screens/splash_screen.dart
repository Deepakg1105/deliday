import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'webpage_initial_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    CheckUserConnection();
    Timer(
      Duration(seconds: 3),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WebpageInitialScreen(
            isInternet: isInternet,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  bool isInternet = true;
  Future CheckUserConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          isInternet = true;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        isInternet = false;
      });
    }
    print(isInternet.toString() + "splash status");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
    );
  }
}
