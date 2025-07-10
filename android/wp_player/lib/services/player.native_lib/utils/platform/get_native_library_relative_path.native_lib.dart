import 'dart:io';

const String _nativeLibraryNameAndroid = 'libWpPlayerLibShared.so';
const String _nativeLibraryNameWindows = 'libWpPlayerLibShared.dll';

String getNativeLibraryRelativePath() {
  if (Platform.isAndroid) return _nativeLibraryNameAndroid;
  if (Platform.isWindows) return _nativeLibraryNameWindows;

  return _nativeLibraryNameAndroid;
}
