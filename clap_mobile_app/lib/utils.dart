
import 'package:flutter/foundation.dart';

void customPrint(dynamic input){
  final now = DateTime.now();
  final formattedTime = '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';
  print('[$formattedTime] $input');
}

void customDebugPrint(dynamic input) {
  if (kDebugMode) {
    final now = DateTime.now();
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    print('[$formattedTime] $input');
  }
}