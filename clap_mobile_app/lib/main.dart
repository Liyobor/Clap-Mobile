import 'package:clap_mobile_app/home/view.dart';
import 'package:clap_mobile_app/services/model_holder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {

  Get.put(ModelHolder());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff121b28),
        textTheme: const TextTheme(
            displayLarge: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white),
            bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
            labelLarge: TextStyle(fontSize: 14, color: Colors.white70)
        ),
        fontFamily: 'Inter',
        fontFamilyFallback: const ['NotoSansTC'],
      ),
      home: HomePage(),
    );
  }
}
