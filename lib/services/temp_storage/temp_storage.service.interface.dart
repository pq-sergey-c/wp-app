/// A service responsible for writing and managing temporary files
///
/// On each instantiation of the singleton, this service is expected to
/// clean up old temporary files, or otherwise ensure that the
/// temporary directory remains clean
abstract class ITempStorageService {
  /// [Future<String>] - returns absolute path to file
  /// fileName - is end fileName of file (if you need provide extension as part of name)
  Future<String> writeFileToTempDir(List<int> data, {required String fileName});
}
