class DeepLinkingData {
  final String? _link;
  bool _isAccessed = false;

  DeepLinkingData({required String? link}) : _link = link;
  factory DeepLinkingData.empty() => DeepLinkingData(link: null);

  String? get getLinkAndMarkAsAccessed {
    if (_isAccessed) return null;
    _isAccessed = true;
    return _link;
  }
}
