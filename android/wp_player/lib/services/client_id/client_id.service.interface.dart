abstract class IClientId {
  /// [String] - persistent UUID (promised to be consistent while app is running)
  String get clientIdentifier;
}
