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
        textTheme: const TextTheme(
            displayLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xff3e3a39)),
            bodyLarge: TextStyle(fontSize: 18, color: Color(0xff3e3a39))
        ),
        fontFamily: 'Inter',
        brightness: Brightness.light,
        fontFamilyFallback: const ['NotoSansTC'],
      ),
      home: HomePage(),
    );
  }
}
