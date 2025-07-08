enum NetworkUrlPrefixes {
  localFile("asset:"),
  httpRequest("url:");

  final String value;

  const NetworkUrlPrefixes(this.value);

  static ({NetworkUrlPrefixes? type, String? clearedString}) resolveString(String url) {
    for (final prefix in NetworkUrlPrefixes.values) {
      if (!url.startsWith(prefix.value)) continue;
      return (type: prefix, clearedString: url.substring(prefix.value.length));
    }
    return (type: null, clearedString: null);
  }

  String addPrefix(String url) {
    return "$value$url";
  }
}
