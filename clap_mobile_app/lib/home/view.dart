import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeLogic logic = Get.put(HomeLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff1a2a3a), Color(0xff0d141d)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Circular Visualizer
              Obx(() => Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: logic.isRecording.value ? Colors.cyan.withOpacity(0.5) : Colors.cyan.withAlpha(50),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: logic.isRecording.value ? Colors.cyan.withAlpha(40) : Colors.transparent,
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Center(
                  child: logic.isRecording.value 
                      ? const Icon(Icons.graphic_eq, size: 100, color: Colors.cyan)
                      : const Icon(Icons.mic, size: 80, color: Colors.cyan),
                ),
              )),
              const SizedBox(height: 40),
              // Action Button
              Obx(() => logic.isRecording.value || logic.isRecognizing.value
                  ? _buildActionButton(
                      label: logic.isRecognizing.value ? "RECOGNIZING..." : "Stop Recording",
                      onPressed: logic.isRecognizing.value ? null : logic.stopRecording,
                      color: Colors.redAccent,
                      isGlow: true,
                    )
                  : _buildActionButton(
                      label: "Start Recording",
                      onPressed: logic.startRecording,
                      color: Colors.cyan,
                      isGlow: false,
                    )),
              const SizedBox(height: 30),
              // Status Text
              Obx(() => Text(
                logic.statusText.value.toUpperCase(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 16),
              )),
              const Spacer(),
              // Result Card
              Obx(() => logic.resultText.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              logic.resultText.value,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 18, color: Colors.white54),
                                const SizedBox(width: 8),
                                const Icon(Icons.directions_walk, size: 18, color: Colors.white54),
                                const Spacer(),
                                Text(
                                  "Confidence: ${logic.confidence.value}%",
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(height: 150)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    required bool isGlow,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isGlow && onPressed != null
            ? [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          side: BorderSide(color: color.withAlpha(200), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == "Stop Recording") Container(
              width: 12, height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
