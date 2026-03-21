import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pytorch_lite/flutter_pytorch_lite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:clap_mobile_app/main.dart';
import 'package:clap_mobile_app/home/logic.dart';
import 'package:clap_mobile_app/services/model_holder.dart';

// Mocks
class MockModelHolder extends ModelHolder {
  @override
  void onInit() {
    // Do not call super.onInit() to avoid loading model
  }
  @override
  Future<IValue> inference(Float32List input) async {
    throw UnimplementedError();
  }
}

class MockHomeLogic extends HomeLogic {
  @override
  void onInit() {
    // Skip initialization of recorder
  }
  
  @override
  Future<void> startRecording() async {
    isRecording.value = true;
    statusText.value = "RECORDING...";
  }
  
  @override
  Future<void> stopRecording({bool auto = false}) async {
    isRecording.value = false;
    statusText.value = "Cancelled";
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Home page smoke test', (WidgetTester tester) async {
    // 1. Inject Mock ModelHolder (required by HomeLogic constructor)
    Get.put<ModelHolder>(MockModelHolder());

    // 2. Inject Mock HomeLogic
    // When HomePage calls Get.put(HomeLogic()), it should find this instance or we override it.
    // Get.put checks if registered.
    final logic = MockHomeLogic();
    Get.put<HomeLogic>(logic);

    // 3. Pump App
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 4. Verify Initial State
    expect(find.text('Start Recording'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.text('READY'), findsOneWidget); // UpperCase in view

    // 5. Test Interaction (Mocked)
    await tester.tap(find.text('Start Recording'));
    await tester.pump(); // Rebuild for Obx

    expect(find.text('Stop Recording'), findsOneWidget);
    expect(find.text('RECORDING...'), findsOneWidget);
  });
}
