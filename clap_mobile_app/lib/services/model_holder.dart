

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_pytorch_lite/flutter_pytorch_lite.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clap_mobile_app/utils.dart';


class ModelHolder extends ModelCore {

  Future<void> _initModel() async {
    _module = await _loadPtlModelFromAsset("assets/model/clap_caption_mobile.ptl","ptl_model_clap_caption_mobile.ptl");
  }


  Future<IValue> inference(Float32List input) async {
    if (_module == null){
      throw Exception('Encoder inference error! module is null!');
    }
    try {
      final shape = Int64List.fromList([1, (44100 * 7).toInt()]);
      final tensor = Tensor.fromBlobFloat32(input, shape);
      final listIValue = IValue.listFrom(<Tensor>[tensor]);
      return await _module!.forward([listIValue]);
    } catch(e){
      print("error : $e");
      rethrow;
    }

  }

  @override
  void onInit() {
    _initModel();
    super.onInit();
  }
}



class ModelCore extends GetxService {
  Module? _module;



  Future<Module> _loadPtlModelFromAsset(String assetPath, String filename) async {
    try {
      final ByteData bd = await rootBundle.load(assetPath);
      if (bd.lengthInBytes == 0) {
        throw Exception("Asset $assetPath is empty!");
      }

      // Create a deep copy of the bytes to ensure we have a clean buffer and not a view into the APK
      final Uint8List bytes = Uint8List.fromList(bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes));

      // Use ApplicationSupportDirectory which is more reliable for internal app files
      final Directory dir = await getTemporaryDirectory();
      final String filePath = '${dir.path}/$filename';
      final File file = File(filePath);

      // Write to file
      await file.writeAsBytes(bytes, flush: true);

      // Verify file integrity
      if (!file.existsSync()) {
        throw Exception("File failed to write to $filePath");
      }
      final int fileSize = await file.length();
      if (fileSize != bytes.length) {
        throw Exception("File wrote $fileSize bytes, expected ${bytes.length}");
      }

      customDebugPrint("Model loaded: $assetPath, size: ${bytes.length}, saved to: $filePath");
      return await FlutterPytorchLite.load(filePath);
    } catch (e) {
      customDebugPrint("Error loading model $assetPath: $e");
      rethrow;
    }
  }


  @override
  void onClose() {
    _module?.destroy();
    super.onClose();
  }
}