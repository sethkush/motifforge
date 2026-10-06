import 'dart:io';
import 'dart:typed_data';

Uint8List readFileBytes(String path) => File(path).readAsBytesSync();
