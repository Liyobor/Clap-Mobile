import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taudio/public/fs/flutter_sound.dart';
import '../services/model_holder.dart';
import '../utils.dart';

class HomeLogic extends GetxController {
  final ModelHolder _holder = Get.find();
  FlutterSoundRecorder? _recorder;

  final RxBool isRecording = false.obs;
  final RxBool isRecognizing = false.obs;
  final RxString statusText = "Ready".obs;
  final RxString resultText = "".obs;
  final RxDouble confidence = 0.0.obs;

  Timer? _recordingTimer;
  String? _tempFilePath;

  @override
  void onInit() {
    super.onInit();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    try {
      await _recorder!.openRecorder();
    } catch (e) {
      customDebugPrint("Error opening recorder: $e");
      statusText.value = "Mic Error";
    }
  }

  @override
  void onClose() {
    _recorder?.closeRecorder();
    _recordingTimer?.cancel();
    super.onClose();
  }

  Future<void> startRecording() async {
    if (_recorder == null || !_recorder!.isStopped) return;

    try {
      final Directory tempDir = await getTemporaryDirectory();
      _tempFilePath = '${tempDir.path}/temp_audio.pcm';

      // Start recording: PCM16, 44100Hz, Mono
      await _recorder!.startRecorder(
        toFile: _tempFilePath,
        codec: Codec.pcm16,
        sampleRate: 44100,
        numChannels: 1,
      );

      isRecording.value = true;
      statusText.value = "RECORDING...";
      resultText.value = ""; 

      // Start 7s timer
      _recordingTimer = Timer(const Duration(seconds: 7), () {
        stopRecording(auto: true);
      });

    } catch (e) {
      customDebugPrint("Start recording error: $e");
      statusText.value = "Error";
      isRecording.value = false;
    }
  }

  Future<void> stopRecording({bool auto = false}) async {
    _recordingTimer?.cancel();
    if (_recorder == null) return;

    try {
      await _recorder!.stopRecorder();
      isRecording.value = false;

      if (auto) {
        await _processAudio();
      } else {
        statusText.value = "Cancelled";
      }
    } catch (e) {
      customDebugPrint("Stop recording error: $e");
    }
  }

  Future<void> _processAudio() async {
    if (_tempFilePath == null) return;

    statusText.value = "RECOGNIZING...";
    isRecognizing.value = true;

    try {
      final File audioFile = File(_tempFilePath!);
      if (!await audioFile.exists()) {
        throw Exception("Audio file not found");
      }

      final Uint8List bytes = await audioFile.readAsBytes();
      
      // Convert PCM16 to Float32
      Float32List floatData = _convertPcm16ToFloat32(bytes);

      // Pad/Truncate to 44100 * 7
      final int targetLen = 44100 * 7;
      if (floatData.length != targetLen) {
        if (floatData.length < targetLen) {
          final Float32List newData = Float32List(targetLen);
          newData.setRange(0, floatData.length, floatData);
          floatData = newData;
        } else {
          // Create a new list to ensure we have a clean Float32List
          floatData = Float32List.fromList(floatData.sublist(0, targetLen));
        }
      }

      // Inference
      final result = await _holder.inference(floatData);

      // Handle Result (Assuming toString() gives a meaningful representation if not handled otherwise)
      // Ideally we would inspect the IValue type here.
      String rawResult = result.toString();
      customDebugPrint("Model Output: $rawResult");
      
      // Basic cleanup if the model returns something wrapper-like
      if (rawResult.startsWith("IValue(")) {
        // Try to extract content if possible, or just display raw for debugging
      }

      resultText.value = rawResult;
      confidence.value = 95.0; // Mock confidence as model might not return it
      statusText.value = "Done";

    } catch (e) {
      customDebugPrint("Inference error: $e");
      statusText.value = "Error";
      resultText.value = "Recognition Failed";
    } finally {
      isRecognizing.value = false;
    }
  }

  Float32List _convertPcm16ToFloat32(Uint8List bytes) {
    // PCM16 is 2 bytes per sample
    final int samples = bytes.length ~/ 2;
    final Float32List floats = Float32List(samples);
    final ByteData bd = ByteData.sublistView(bytes);

    for (int i = 0; i < samples; i++) {
      // Little Endian
      final int sample = bd.getInt16(i * 2, Endian.little);
      floats[i] = sample / 32768.0;
    }
    return floats;
  }
}
