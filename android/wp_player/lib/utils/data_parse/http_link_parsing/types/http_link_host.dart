enum HTTPLinkHost {
  production("guide.wavepaths.com"),
  development("guide-dev.wavepaths.com"),
  developmentLocal("localhost");

  final String href;

  const HTTPLinkHost(this.href);

  String get playerLinkPathEntry {
    final String? result = _playerLinkPathEntryByQrLinkHosts[this];
    if (result == null) throw StateError('No Player link path entry is found for the current HTTPLinkHost: $href');
    return result;
  }

  static HTTPLinkHost? fromString(final String href) {
    try {
      return HTTPLinkHost.values.firstWhere((e) => e.href == href);
    } catch (e) {
      return null;
    }
  }
}

const Map<HTTPLinkHost, String> _playerLinkPathEntryByQrLinkHosts = {
  HTTPLinkHost.developmentLocal: 'dev-local',
  HTTPLinkHost.development: 'dev',
  HTTPLinkHost.production: 'prod',
};
