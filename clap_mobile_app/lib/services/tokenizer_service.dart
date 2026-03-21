import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../utils.dart';

class TokenizerService extends GetxService {
  Map<int, String> _idToToken = {};
  static const int eosTokenId = 50256;

  // GPT-2 byte-to-unicode mapping (simplified for common use)
  // In a full implementation, this maps the 256 bytes to specific unicode characters.
  late final Map<String, int> _byteDecoder;

  Future<TokenizerService> init() async {
    await _loadVocab();
    _initByteDecoder();
    return this;
  }

  void _initByteDecoder() {
    // GPT-2 uses a specific mapping for bytes 0-255 to printable unicode characters.
    // This is the inverse of the mapping used during encoding.
    _byteDecoder = {};
    
    // Standard printable ASCII
    for (int i = 33; i <= 126; i++) {
      _byteDecoder[String.fromCharCode(i)] = i;
    }
    for (int i = 161; i <= 172; i++) {
      _byteDecoder[String.fromCharCode(i)] = i;
    }
    for (int i = 174; i <= 255; i++) {
      _byteDecoder[String.fromCharCode(i)] = i;
    }

    // The remaining "gap" characters
    int n = 0;
    for (int i = 0; i < 256; i++) {
      String char = String.fromCharCode(i);
      if (!_byteDecoder.containsKey(char)) {
        _byteDecoder[String.fromCharCode(256 + n)] = i;
        n++;
      }
    }
    
    // Common GPT-2 space character mapping
    // Usually 'Ġ' is mapped to ' ' (32)
    _byteDecoder['Ġ'] = 32;
    _byteDecoder['Ċ'] = 10; // Newline
    _byteDecoder['ĉ'] = 13; // Carriage return
  }

  Future<void> _loadVocab() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/tokenizer_files/vocab.json');
      final Map<String, dynamic> vocab = jsonDecode(jsonString);
      
      _idToToken = vocab.map((key, value) => MapEntry(value as int, key));
      customDebugPrint("Tokenizer vocab loaded: ${_idToToken.length} tokens");
    } catch (e) {
      customDebugPrint("Error loading vocab: $e");
    }
  }

  String decode(List<int> ids) {
    if (_idToToken.isEmpty) return "Error: vocab not loaded";

    // 1. Filter out EOS and other special tokens (like 0 padding)
    final List<int> cleanIds = [];
    for (var id in ids) {
      if (id == eosTokenId || id == 0) break;
      cleanIds.add(id);
    }

    if (cleanIds.isEmpty) return "";
    final List<String> tokens = cleanIds.map((id) => _idToToken[id] ?? "").toList();
    
    // 3. Convert Token strings to Bytes
    List<int> allBytes = [];
    for (var token in tokens) {
      for (int i = 0; i < token.length; i++) {
        String char = token[i];
        // Use the byte decoder to get the original byte value
        int? byte = _byteDecoder[char];
        if (byte != null) {
          allBytes.add(byte);
        } else {
          // Fallback for characters not in special mapping (mostly ASCII)
          allBytes.add(char.codeUnitAt(0));
        }
      }
    }

    // 4. Decode bytes as UTF-8
    try {
      String result = utf8.decode(allBytes);
      return result.trim();
    } catch (e) {
      customDebugPrint("UTF-8 Decode error: $e");
      // Fallback: simple join if UTF-8 fails
      return tokens.join('').replaceAll('Ġ', ' ').trim();
    }
  }
}
