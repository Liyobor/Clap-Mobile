

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
      final dir = await getApplicationSupportDirectory();
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);

      // 如果檔案已存在，就不要每次重寫
      if (!await file.exists()) {
        final bd = await rootBundle.load(assetPath);
        if (bd.lengthInBytes == 0) {
          throw Exception('Asset $assetPath is empty!');
        }

        // 不做 deep copy，直接取 view
        final bytes = bd.buffer.asUint8List(
          bd.offsetInBytes,
          bd.lengthInBytes,
        );

        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: false);

        final fileSize = await file.length();
        if (fileSize != bd.lengthInBytes) {
          throw Exception(
            'File wrote $fileSize bytes, expected ${bd.lengthInBytes}',
          );
        }
      }

      customDebugPrint('Loading model from: $filePath');
      _module = await FlutterPytorchLite.load(filePath);
      return _module!;
    } catch (e) {
      customDebugPrint('Error loading model $assetPath: $e');
      rethrow;
    }
  }


  @override
  void onClose() {
    _module?.destroy();
    super.onClose();
  }
}