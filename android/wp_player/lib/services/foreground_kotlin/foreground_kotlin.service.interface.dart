/// Implementation should be thread safe for start/end or construction/destruction
abstract class IForegroundKotlinService {
  Future<void> start();
  Future<void> dispose();
}
