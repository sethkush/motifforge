import 'dart:typed_data';

Uint8List readFileBytes(String path) =>
    throw UnsupportedError('Loading files by path is not supported on the web; '
        'load the bytes yourself and use fromByteData.');
