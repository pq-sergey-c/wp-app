enum ExternalLinks {
  registerAccount(stringLink: 'https://guide.wavepaths.com/login'),
  startNewSessionFromTemplates(stringLink: 'https://guide.wavepaths.com/templates'),
  currentUserSessions(stringLink: 'https://guide.wavepaths.com/sessions'),
  subscriptionsPage(stringLink: 'https://guide.wavepaths.com/subscriptions');

  final String stringLink;

  const ExternalLinks({required this.stringLink});

  Uri get uri {
    final result = _externalLinkToUriMap[this];
    if (result == null) {
      throw StateError(
        "Error in ExternalLinks (for $stringLink): hasn't found a URI corresponding to stringLink (shouldn't happen)",
      );
    }
    return result;
  }
}

final Map<ExternalLinks, Uri> _externalLinkToUriMap = Map.fromEntries(
  ExternalLinks.values.map((entry) => MapEntry(entry, Uri.parse(entry.stringLink))),
);
